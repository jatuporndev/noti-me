/**
 * POST /api/dispatch
 *
 * Called by Google Apps Script three times per day (08:30, 12:00, 17:30
 * Asia/Bangkok). The server derives the current slot from wall-clock time —
 * no slot is passed in the body.
 *
 * Required header:
 *   x-dispatch-secret: <DISPATCH_SECRET env var>
 *
 * Optional overrides for testing (only allowed when NODE_ENV !== "production"):
 *   body JSON: { "slotOverride": "morning" | "noon" | "evening" }
 *              { "forceSend": true }   — bypasses slot window, date gate,
 *                                        one-shot gate, AND dedupe; sends every
 *                                        channel that has reminders regardless
 *                                        of time. Use for manual testing only.
 *
 * Dispatch logic per run:
 *   1. Determine current Bangkok slot.
 *   2. Query channels where notifySlots array-contains that slot.
 *   3. For each channel:
 *        a. Date gate: skip if today < notifyStartDateBangkok.
 *        b. One-shot gate: if repeatDaily=false, skip if today != start date.
 *        c. Dedupe: skip if sendRecords/{today}_{slot} already exists.
 *        d. Load all reminders; skip channel if none.
 *        e. Build merged FCM notification and send to fcmTopicName.
 *        f. Write sendRecord.
 *   4. Return JSON summary.
 */

import { db, messaging } from "../lib/firebase.js";
import {
  bangkokNow,
  currentSlot,
  assertValidSlot,
  formatYmd,
  compareYmd,
} from "../lib/bangkok.js";

const LEGACY_START = "1970-01-01";

function setCors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, x-dispatch-secret");
}

function buildNotificationBody(reminders) {
  const titles = reminders.map((r) => r.title).filter(Boolean);
  if (titles.length === 0) return "";
  if (titles.length === 1) {
    const body = reminders[0].body;
    return body ? `${titles[0]}\n${body}` : titles[0];
  }
  const [first, ...rest] = titles;
  return rest.length === 1
    ? `${first}\n+1 more reminder`
    : `${first}\n+${rest.length} more reminders`;
}

export default async function handler(req, res) {
  setCors(res);

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // --- Auth ---
  const secret = process.env.DISPATCH_SECRET;
  if (!secret) {
    return res.status(500).json({ error: "DISPATCH_SECRET not configured" });
  }
  if (req.headers["x-dispatch-secret"] !== secret) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // --- Slot + forceSend ---
  const now = bangkokNow();
  const todayYmd = formatYmd(now);

  const body = req.body ?? {};
  const isTestEnv = process.env.NODE_ENV !== "production";

  const forceSend = isTestEnv && body.forceSend === true;
  const slotOverride = typeof body.slotOverride === "string" ? body.slotOverride : null;

  let slot;
  if (slotOverride && isTestEnv) {
    assertValidSlot(slotOverride);
    slot = slotOverride;
  } else if (forceSend) {
    slot = currentSlot(now) ?? "force";
  } else {
    slot = currentSlot(now);
  }

  if (!slot && !forceSend) {
    return res.status(200).json({
      ok: true,
      slot: null,
      forceSend: false,
      skipped: "No dispatch window active right now",
      todayYmd,
    });
  }

  // --- Query channels ---
  // forceSend: all channels that have any notifySlots set.
  // Normal:    only channels matching the current slot.
  const channelsSnap = forceSend
    ? await db.collection("channels").where("notifySlots", "!=", []).get()
    : await db
        .collection("channels")
        .where("notifySlots", "array-contains", slot)
        .get();

  const results = { sent: [], skipped: [] };

  await Promise.all(
    channelsSnap.docs.map(async (channelDoc) => {
      const channelId = channelDoc.id;
      const data = channelDoc.data();
      const topicName = data.fcmTopicName;
      const channelName = data.name ?? "notiMe";
      const startYmd = data.notifyStartDateBangkok ?? LEGACY_START;
      const repeatDaily = data.repeatDaily !== false; // default true for legacy

      if (!forceSend) {
        // --- Date gate ---
        if (startYmd !== LEGACY_START && compareYmd(todayYmd, startYmd) < 0) {
          results.skipped.push({ channelId, reason: "before_start_date" });
          return;
        }

        // --- One-shot gate ---
        if (!repeatDaily && todayYmd !== startYmd) {
          results.skipped.push({ channelId, reason: "one_shot_already_fired" });
          return;
        }

        // --- Dedupe ---
        const sendRecordId = `${todayYmd}_${slot}`;
        const sendRecordRef = db
          .collection("channels")
          .doc(channelId)
          .collection("sendRecords")
          .doc(sendRecordId);

        const existing = await sendRecordRef.get();
        if (existing.exists) {
          results.skipped.push({ channelId, reason: "already_sent" });
          return;
        }
      }

      // --- Load reminders ---
      const remindersSnap = await db
        .collection("channels")
        .doc(channelId)
        .collection("reminders")
        .get();

      const reminders = remindersSnap.docs.map((d) => d.data());

      if (reminders.length === 0) {
        results.skipped.push({ channelId, reason: "no_reminders" });
        return;
      }

      // --- Build & send FCM message ---
      const notifBody = buildNotificationBody(reminders);

      const message = {
        topic: topicName,
        notification: {
          title: channelName,
          body: notifBody || "You have reminders",
        },
        data: {
          route: `channel/${channelId}`,
          slot,
          channelId,
        },
        android: {
          notification: {
            channelId: "noti_me_default",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      try {
        const messageId = await messaging.send(message);

        // --- Write dedupe record (skipped for forceSend runs) ---
        if (!forceSend) {
          const sendRecordId = `${todayYmd}_${slot}`;
          await db
            .collection("channels")
            .doc(channelId)
            .collection("sendRecords")
            .doc(sendRecordId)
            .set({
              slot,
              sentAt: new Date().toISOString(),
              messageId,
              reminderCount: reminders.length,
            });
        }

        results.sent.push({ channelId, messageId, reminderCount: reminders.length });
      } catch (err) {
        results.skipped.push({ channelId, reason: "fcm_error", error: err.message });
      }
    })
  );

  return res.status(200).json({
    ok: true,
    slot,
    todayYmd,
    forceSend,
    sent: results.sent.length,
    skipped: results.skipped.length,
    details: results,
  });
}
