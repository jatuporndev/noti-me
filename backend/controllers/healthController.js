import { setCors } from "../utils/http.js";

export function healthController(req, res) {
  setCors(res);

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "GET") return res.status(405).json({ error: "Method not allowed" });

  return res.status(200).json({
    ok: true,
    service: "noti-me-api",
    time: new Date().toISOString(),
  });
}
