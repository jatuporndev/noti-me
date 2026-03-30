export function setCors(res, options = {}) {
  const methods = options.methods ?? "GET, POST, OPTIONS";
  const headers = options.headers ?? "Content-Type, Authorization";
  const origin = options.origin ?? "*";

  res.setHeader("Access-Control-Allow-Origin", origin);
  res.setHeader("Access-Control-Allow-Methods", methods);
  res.setHeader("Access-Control-Allow-Headers", headers);
}

export function parseJsonBody(body) {
  if (typeof body === "string") {
    try {
      return JSON.parse(body);
    } catch {
      return {};
    }
  }
  return body ?? {};
}
