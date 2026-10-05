/** account-ops-sink — minimal durable receipt endpoint for the account-deletion worker's
 * restore-checkpoint and operational-notification webhooks (ADR-2P). Reuses the existing
 * Supabase project; adds no external service. Bearer-authenticated with ACCOUNT_OPERATIONS_TOKEN.
 *
 * Privacy: it NEVER stores or logs the raw manifest/notification payload, PII, secrets or tokens.
 * It records only a minimal durable receipt (kind + sha256 of the body + byte size + timestamp)
 * via the SECURITY DEFINER RPC account_ops_record, which is all the worker contract needs (the
 * worker only requires a 200 acknowledgement). */

const OPS = Deno.env.get("ACCOUNT_OPERATIONS_TOKEN");
const SB_URL = Deno.env.get("SUPABASE_URL");
const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return reply(405, { error: "method" });
  if (!OPS || !SB_URL || !SRK) return reply(503, { error: "unavailable" });
  const bearer = req.headers.get("authorization")?.match(/^Bearer (\S+)$/)?.[1];
  if (!bearer || !timingSafeEqual(bearer, OPS)) return reply(401, { error: "denied" });
  const path = new URL(req.url).pathname;
  const kind = path.endsWith("/checkpoint")
    ? "checkpoint"
    : path.endsWith("/notification")
    ? "notification"
    : null;
  if (!kind) return reply(404, { error: "path" });
  // Read the body only to derive a non-reversible receipt; the raw bytes are never persisted.
  const buf = new Uint8Array(await req.arrayBuffer());
  if (buf.byteLength > 1_000_000) return reply(413, { error: "too_large" });
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", buf));
  const sha = Array.from(digest, (b) => b.toString(16).padStart(2, "0")).join("");
  try {
    const res = await fetch(SB_URL + "/rest/v1/rpc/account_ops_record", {
      method: "POST",
      headers: {
        apikey: SRK,
        authorization: "Bearer " + SRK,
        "content-type": "application/json",
      },
      body: JSON.stringify({ p_kind: kind, p_sha256: sha, p_bytes: buf.byteLength }),
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) return reply(503, { error: "record" });
  } catch {
    return reply(503, { error: "record" });
  }
  return reply(200, { ok: true });
});
