// ADR-2 candidate. Request/status/cancel only; no Auth Admin deletion capability.
export interface LifecycleGateway {
  call(
    token: string,
    operation: "request" | "status" | "cancel",
  ): Promise<unknown>;
}
export function bearerToken(request: Request): string | null {
  return /^Bearer\s+(\S+)$/i.exec(
    request.headers.get("authorization")?.trim() ?? "",
  )?.[1] ?? null;
}
const headers = {
  "content-type": "application/json",
  "cache-control": "no-store",
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization,apikey,content-type",
  "access-control-allow-methods": "POST,OPTIONS",
};
export function createHandler(gateway: LifecycleGateway) {
  return async (request: Request): Promise<Response> => {
    const reply = (status: number, body: unknown) =>
      new Response(JSON.stringify(body), { status, headers });
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") {
      return reply(405, { error: "method_not_allowed" });
    }
    const token = bearerToken(request);
    if (!token) return reply(401, { error: "unauthorized" });
    let input: unknown;
    try {
      input = await request.json();
    } catch {
      return reply(400, { error: "invalid_request" });
    }
    if (
      !input || typeof input !== "object" || Array.isArray(input) ||
      Object.keys(input).some((k) => k !== "operation")
    ) return reply(400, { error: "invalid_request" });
    const op = (input as { operation?: unknown }).operation;
    if (op !== "request" && op !== "status" && op !== "cancel") {
      return reply(400, { error: "invalid_request" });
    }
    try {
      const value = await gateway.call(token, op);
      // No student payload or server exception can escape the DTO whitelist.
      if (!value || typeof value !== "object") throw Error();
      const v = value as Record<string, unknown>;
      if (
        !["NORMAL", "DELETION_PENDING", "ERASING", "CANCELLED", "ERASED"]
          .includes(v.state as string)
      ) throw Error();
      return reply(op === "request" ? 202 : 200, {
        state: v.state,
        request_id: v.request_id ?? null,
        scheduled_deletion_at: v.scheduled_deletion_at ?? null,
        cancelled_at: v.cancelled_at ?? null,
      });
    } catch {
      return reply(403, { error: "lifecycle_request_denied" });
    }
  };
}
