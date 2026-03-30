import { dispatchNotifications } from "../services/dispatchService.js";
import { parseJsonBody, setCors } from "../utils/http.js";

function validateSecret(req) {
  const secret = process.env.DISPATCH_SECRET;
  if (!secret) return { ok: false, status: 500, error: "DISPATCH_SECRET not configured" };
  if (req.headers["x-dispatch-secret"] !== secret) {
    return { ok: false, status: 401, error: "Unauthorized" };
  }
  return { ok: true };
}

export async function dispatchController(req, res) {
  setCors(res, {
    methods: "POST, OPTIONS",
    headers: "Content-Type, x-dispatch-secret",
  });

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const authResult = validateSecret(req);
  if (!authResult.ok) {
    return res.status(authResult.status).json({ error: authResult.error });
  }

  const body = parseJsonBody(req.body);
  const forceSend = body.forceSend === true;

  const result = await dispatchNotifications({ forceSend });
  return res.status(200).json(result);
}
