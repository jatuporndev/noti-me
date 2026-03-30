/**
 * Minimal local HTTP server for testing API handlers.
 * Usage:  node server.mjs
 * Port:   3000  (override with PORT env var)
 */
import http from "http";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import path from "path";

// ── Load .env.local ──────────────────────────────────────────────────────────
const envPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), ".env.local");
try {
  for (const line of readFileSync(envPath, "utf8").split("\n")) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const eq = t.indexOf("=");
    if (eq === -1) continue;
    process.env[t.slice(0, eq).trim()] = t.slice(eq + 1).trim();
  }
  console.log("✓ Loaded .env.local");
} catch {
  console.warn("⚠ .env.local not found");
}

// ── Load handlers ────────────────────────────────────────────────────────────
const routes = {
  "/api/dispatch": (await import("./api/dispatch.js")).default,
  "/api/health":   (await import("./api/health.js")).default,
};

// ── Server ───────────────────────────────────────────────────────────────────
const PORT = process.env.PORT ?? 3000;

http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const handler = routes[url.pathname];

  if (!handler) {
    res.writeHead(404, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ error: `No handler for ${url.pathname}` }));
  }

  // Collect body
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", async () => {
    const raw = Buffer.concat(chunks).toString();
    if (raw) {
      try { req.body = JSON.parse(raw); } catch { req.body = raw; }
    } else {
      req.body = {};
    }

    // Wrap res to match Vercel's handler signature
    const wrapped = {
      _headers: {},
      status(code) { res.statusCode = code; return this; },
      json(data) {
        res.setHeader("Content-Type", "application/json");
        Object.entries(this._headers).forEach(([k, v]) => res.setHeader(k, v));
        res.end(JSON.stringify(data, null, 2));
        return this;
      },
      end() { res.end(); return this; },
      setHeader(k, v) { this._headers[k] = v; return this; },
    };

    try {
      await handler(req, wrapped);
    } catch (err) {
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: err.message }));
    }
  });
}).listen(PORT, () => {
  console.log(`\n🚀 Local API server running at http://localhost:${PORT}\n`);
  console.log("  Routes:");
  Object.keys(routes).forEach((r) => console.log(`    POST http://localhost:${PORT}${r}`));
  console.log();
});
