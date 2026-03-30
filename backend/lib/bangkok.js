/**
 * Bangkok (Asia/Bangkok) is UTC+7 with no DST.
 * All schedule logic runs in Bangkok wall-clock time.
 */

const OFFSET_HOURS = 7;

/** Returns the current UTC Date shifted to Bangkok wall-clock. */
export function bangkokNow() {
  const utc = new Date();
  return new Date(utc.getTime() + OFFSET_HOURS * 60 * 60 * 1000);
}

/**
 * Maps Bangkok wall-clock time to one of the three dispatch slots.
 * Returns null if the current hour doesn't match any window.
 *
 * Windows (Bangkok):
 *   morning : 08:00–09:59  (target trigger 08:30)
 *   noon    : 11:00–12:59  (target trigger 12:00)
 *   evening : 17:00–18:59  (target trigger 17:30)
 */
export function currentSlot(now = bangkokNow()) {
  const h = now.getUTCHours(); // shifted already, so UTCHours == Bangkok hours
  if (h >= 8 && h < 10) return "morning";
  if (h >= 11 && h < 13) return "noon";
  if (h >= 17 && h < 19) return "evening";
  return null;
}

/**
 * Forces a specific slot name for testing.
 * Valid values: "morning" | "noon" | "evening"
 */
export function assertValidSlot(slot) {
  if (!["morning", "noon", "evening"].includes(slot)) {
    throw new Error(`Invalid slot: ${slot}`);
  }
}

/** Returns "yyyy-MM-dd" for the given Bangkok Date. */
export function formatYmd(bangkokDate) {
  const y = bangkokDate.getUTCFullYear();
  const m = String(bangkokDate.getUTCMonth() + 1).padStart(2, "0");
  const d = String(bangkokDate.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Compares two "yyyy-MM-dd" strings.
 * Returns negative if a < b, 0 if equal, positive if a > b.
 */
export function compareYmd(a, b) {
  return a.localeCompare(b);
}
