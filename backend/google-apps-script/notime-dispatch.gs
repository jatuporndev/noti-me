/**
 * notiMe Google Apps Script dispatcher
 *
 * Purpose:
 * - Call your backend endpoint: POST /api/dispatch
 * - Schedule 3 daily triggers in Bangkok time:
 *   08:30, 12:00, 17:30
 *
 * IMPORTANT:
 * 1) In Apps Script, set project timezone to "Asia/Bangkok"
 *    - Project Settings -> Time zone -> (GMT+07:00) Asia/Bangkok
 * 2) Save your API secret in Script Properties:
 *    - Key: DISPATCH_SECRET
 *    - Value: same value as backend DISPATCH_SECRET
 */

const DISPATCH_URL = "https://YOUR_DOMAIN/api/dispatch";

/**
 * Main scheduled job (normal mode).
 * Trigger this function at 08:30, 12:00, 17:30 (Bangkok).
 */
function dispatchScheduled() {
  return callDispatch(false);
}

/**
 * Manual test: force send mode.
 * This bypasses time-slot window in your backend.
 */
function dispatchForceSendForTest() {
  return callDispatch(true);
}

/**
 * Core HTTP request to /api/dispatch.
 */
function callDispatch(forceSend) {
  const secret = PropertiesService.getScriptProperties().getProperty("DISPATCH_SECRET");
  if (!secret) {
    throw new Error("Missing Script Property: DISPATCH_SECRET");
  }

  const payload = forceSend ? { forceSend: true } : {};

  const response = UrlFetchApp.fetch(DISPATCH_URL, {
    method: "post",
    muteHttpExceptions: true,
    contentType: "application/json",
    headers: {
      "x-dispatch-secret": secret,
    },
    payload: JSON.stringify(payload),
  });

  const code = response.getResponseCode();
  const body = response.getContentText();
  Logger.log("dispatch code=%s body=%s", code, body);

  if (code < 200 || code >= 300) {
    throw new Error("Dispatch failed. HTTP " + code + " body: " + body);
  }

  return body;
}

/**
 * Create exact daily triggers (Bangkok project timezone required).
 *
 * Note:
 * - Apps Script trigger timing is "best effort".
 * - nearMinute(30) means around minute 30.
 * - For 12:00, we use nearMinute(0).
 */
function createDispatchTriggers() {
  deleteDispatchTriggers();

  ScriptApp.newTrigger("dispatchScheduled")
    .timeBased()
    .everyDays(1)
    .atHour(8)
    .nearMinute(30)
    .create();

  ScriptApp.newTrigger("dispatchScheduled")
    .timeBased()
    .everyDays(1)
    .atHour(12)
    .nearMinute(0)
    .create();

  ScriptApp.newTrigger("dispatchScheduled")
    .timeBased()
    .everyDays(1)
    .atHour(17)
    .nearMinute(30)
    .create();
}

/**
 * Delete all triggers that run dispatchScheduled.
 */
function deleteDispatchTriggers() {
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach((t) => {
    if (t.getHandlerFunction() === "dispatchScheduled") {
      ScriptApp.deleteTrigger(t);
    }
  });
}

/**
 * Optional helper: log existing triggers.
 */
function listDispatchTriggers() {
  ScriptApp.getProjectTriggers().forEach((t) => {
    Logger.log("%s | %s", t.getHandlerFunction(), t.getEventType());
  });
}
