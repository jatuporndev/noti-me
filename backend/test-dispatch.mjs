/**
 * Quick local test for the dispatch handler.
 * Usage:  node test-dispatch.mjs
 *         node test-dispatch.mjs forceSend
 */
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import path from "path";

// ── Load .env.local manually ────────────────────────────────────────────────
const envPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), ".env.local");
try {
  const lines = readFileSync(envPath, "utf8").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    process.env[key] = value;
  }
  console.log("✓ Loaded .env.local");
} catch {
  console.warn("⚠ .env.local not found — using existing env vars");
}

// ── Import handler ───────────────────────────────────────────────────────────
const { default: handler } = await import("./api/dispatch.js");

// ── Mock req / res ───────────────────────────────────────────────────────────
const forceSend = process.argv.includes("forceSend");

const req = {
  method: "POST",
  headers: { "x-dispatch-secret": process.env.DISPATCH_SECRET },
  body: forceSend ? { forceSend: true } : {},
};

const res = {
  _status: 200,
  _body: null,
  status(code) { this._status = code; return this; },
  json(data) { this._body = data; return this; },
  end() { return this; },
  setHeader() { return this; },
};

// ── Run ──────────────────────────────────────────────────────────────────────
console.log(`\nCalling dispatch — forceSend=${forceSend}\n`);
await handler(req, res);

console.log(`\nHTTP ${res._status}`);
console.log(JSON.stringify(res._body, null, 2));
