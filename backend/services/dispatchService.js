import { db, messaging } from "../lib/firebase.js";
import { bangkokNow, currentSlot, formatYmd, compareYmd } from "../lib/bangkok.js";

const LEGACY_START = "1970-01-01";

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

async function getChannelsForSlot(forceSend, slot) {
  if (forceSend) {
    return db.collection("channels").get();
  }

  return db.collection("channels").where("notifySlots", "array-contains", slot).get();
}

async function shouldSkipChannel({ forceSend, channelId, startYmd, todayYmd, repeatDaily, slot }) {
  if (forceSend) return null;

  if (startYmd !== LEGACY_START && compareYmd(todayYmd, startYmd) < 0) {
    return { channelId, reason: "before_start_date" };
  }

  if (!repeatDaily && todayYmd !== startYmd) {
    return { channelId, reason: "one_shot_already_fired" };
  }

  const sendRecordId = `${todayYmd}_${slot}`;
  const sendRecordRef = db
    .collection("channels")
    .doc(channelId)
    .collection("sendRecords")
    .doc(sendRecordId);

  const existing = await sendRecordRef.get();
  if (existing.exists) {
    return { channelId, reason: "already_sent" };
  }

  return null;
}

async function fetchReminders(channelId) {
  const remindersSnap = await db.collection("channels").doc(channelId).collection("reminders").get();
  return remindersSnap.docs.map((d) => d.data());
}

function buildMessage({ topicName, channelName, notifBody, slot, channelId }) {
  return {
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
}

async function writeSendRecord({ channelId, todayYmd, slot, messageId, reminderCount }) {
  const sendRecordId = `${todayYmd}_${slot}`;
  await db.collection("channels").doc(channelId).collection("sendRecords").doc(sendRecordId).set({
    slot,
    sentAt: new Date().toISOString(),
    messageId,
    reminderCount,
  });
}

async function processChannel({ channelDoc, forceSend, todayYmd, slot }) {
  const channelId = channelDoc.id;
  const data = channelDoc.data();
  const topicName = data.fcmTopicName;
  const channelName = data.name ?? "notiMe";
  const startYmd = data.notifyStartDateBangkok ?? LEGACY_START;
  const repeatDaily = data.repeatDaily !== false;

  const skipReason = await shouldSkipChannel({
    forceSend,
    channelId,
    startYmd,
    todayYmd,
    repeatDaily,
    slot,
  });
  if (skipReason) return { sent: null, skipped: skipReason };

  const reminders = await fetchReminders(channelId);
  if (reminders.length === 0) {
    return { sent: null, skipped: { channelId, reason: "no_reminders" } };
  }

  const notifBody = buildNotificationBody(reminders);
  const message = buildMessage({ topicName, channelName, notifBody, slot, channelId });

  try {
    const messageId = await messaging.send(message);
    if (!forceSend) {
      await writeSendRecord({ channelId, todayYmd, slot, messageId, reminderCount: reminders.length });
    }
    return { sent: { channelId, messageId, reminderCount: reminders.length }, skipped: null };
  } catch (err) {
    return { sent: null, skipped: { channelId, reason: "fcm_error", error: err.message } };
  }
}

export async function dispatchNotifications({ forceSend }) {
  const now = bangkokNow();
  const todayYmd = formatYmd(now);
  const slot = forceSend ? currentSlot(now) ?? "force" : currentSlot(now);

  if (!slot && !forceSend) {
    return {
      ok: true,
      slot: null,
      forceSend: false,
      skipped: "No dispatch window active right now",
      todayYmd,
    };
  }

  const channelsSnap = await getChannelsForSlot(forceSend, slot);
  const results = { sent: [], skipped: [] };

  await Promise.all(
    channelsSnap.docs.map(async (channelDoc) => {
      const channelResult = await processChannel({ channelDoc, forceSend, todayYmd, slot });
      if (channelResult.sent) results.sent.push(channelResult.sent);
      if (channelResult.skipped) results.skipped.push(channelResult.skipped);
    })
  );

  return {
    ok: true,
    slot,
    todayYmd,
    forceSend,
    sent: results.sent.length,
    skipped: results.skipped.length,
    details: results,
  };
}
