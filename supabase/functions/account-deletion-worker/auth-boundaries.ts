/** Trusted Auth integrations. No body/token/credential/error logging or persistence. */
import { identityInputs, type VerifiedUser } from "./http.ts";
import { markers } from "./worker.ts";
export type AuthBoundaries = {
  rpc(name: string, args: Record<string, unknown>): Promise<unknown>;
  verify(token: string): Promise<VerifiedUser>;
  challengeEmail(user: VerifiedUser, password: string): Promise<boolean>;
  hookSecret?: Uint8Array;
  identityKeys: ReadonlyMap<string, Uint8Array>;
  now?: () => number;
};
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export async function verifyHook(
  request: Request,
  body: string,
  secret: Uint8Array | undefined,
  now: number,
) {
  if (!secret || secret.length < 32 || body.length > 65536) {
    throw Error("HOOK_UNAVAILABLE");
  }
  const id = request.headers.get("webhook-id"),
    ts = request.headers.get("webhook-timestamp");
  if (
    !id || id.length > 200 || !ts?.match(/^\d{10}$/) ||
    Math.abs(now / 1000 - Number(ts)) > 300
  ) throw Error("HOOK_DENIED");
  const key = await crypto.subtle.importKey(
    "raw",
    secret as BufferSource,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  for (
    const entry of (request.headers.get("webhook-signature") ?? "").split(" ")
      .slice(0, 8)
  ) {
    const [version, sig] = entry.split(",");
    if (version !== "v1" || !sig) continue;
    try {
      if (
        await crypto.subtle.verify(
          "HMAC",
          key,
          Uint8Array.from(atob(sig), (c) => c.charCodeAt(0)),
          new TextEncoder().encode(`${id}.${ts}.${body}`),
        )
      ) return;
    } catch { /* fail closed */ }
  }
  throw Error("HOOK_DENIED");
}
export function createAuthBoundaries(p: AuthBoundaries) {
  const headers = {
    "cache-control": "no-store",
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "authorization,apikey,content-type",
    "access-control-allow-methods": "POST,OPTIONS",
  };
  const reply = (status: number, value: unknown) =>
    Response.json(value, { status, headers });
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") return reply(405, { error: "DENIED" });
    const path = new URL(request.url).pathname;
    try {
      const text = await request.text();
      if (text.length > 65536) throw Error();
      if (path.endsWith("/admission")) {
        await verifyHook(request, text, p.hookSecret, (p.now ?? Date.now)());
        const input = JSON.parse(text);
        if (
          input.metadata?.name !== "before-user-created" || !input.user ||
          typeof input.user !== "object"
        ) throw Error();
        const health = await p.rpc("account_deletion_health", {}) as {
          enabled: boolean;
        };
        if (!health.enabled) return reply(200, {});
        // Signed Auth candidate email is DENY-only, never evidence for benefit grants.
        // Ignore user_metadata/profile email and all client-supplied authority fields.
        const user = input.user as VerifiedUser;
        const inputs = identityInputs(user);
        if (typeof user.email === "string" && user.email.trim()) {
          inputs.push("email:" + user.email.trim().toLowerCase());
        }
        const values = await markers(
          p.identityKeys,
          [...new Set(inputs)],
          "lifecycle",
        );
        if (
          await p.rpc("account_identity_blocked", { p_markers: values }) !==
            false
        ) {
          return reply(403, {
            error: {
              http_code: 403,
              message: "Account lifecycle restricts registration.",
            },
          });
        }
        return reply(200, {});
      }
      if (!path.endsWith("/reauth")) return reply(404, { error: "DENIED" });
      const token = request.headers.get("authorization")?.match(
        /^Bearer (\S+)$/,
      )?.[1];
      if (!token) throw Error();
      const user = await p.verify(token); // Auth validates JWT before claim parsing.
      const raw = token.split(".")[1];
      if (!raw) throw Error();
      const claims = JSON.parse(
        atob(
          raw.replace(/-/g, "+").replace(/_/g, "/").padEnd(
            Math.ceil(raw.length / 4) * 4,
            "=",
          ),
        ),
      );
      if (claims.sub !== user.id || !uuid.test(claims.session_id ?? "")) {
        throw Error();
      }
      const input = JSON.parse(text);
      if (
        !input || Object.keys(input).sort().join(",") !== "password,provider" ||
        input.provider !== "email" ||
        typeof input.password !== "string" || input.password.length < 1 ||
        input.password.length > 1024
      ) throw Error();
      const started = (p.now ?? Date.now)();
      if (!await p.challengeEmail(user, input.password)) throw Error();
      if ((p.now ?? Date.now)() - started > 60000) throw Error();
      // No caller-selected subject/session or admin cancellation. A new password challenge is required each time.
      await p.rpc("account_reauth_attest", {
        p_subject: user.id,
        p_session: claims.session_id,
      });
      return reply(200, { state: "REAUTHENTICATED" });
    } catch {
      return path.endsWith("/admission")
        ? reply(503, {
          error: { http_code: 503, message: "Account admission unavailable." },
        })
        : reply(403, { error: "REAUTH_REQUIRED" });
    }
  };
}

/** Real email adapter, disabled until Owner verifies Auth rate-limit/CAPTCHA/session configuration.
 * Fresh temporary session is discarded/revoked; original session remains the ticket target.
 */
export function emailChallenge(
  url: string,
  publicKey: string,
  enabled: boolean,
) {
  return async (user: VerifiedUser, password: string): Promise<boolean> => {
    if (!enabled || !user.email || !user.email_confirmed_at) return false;
    const response = await fetch(url + "/auth/v1/token?grant_type=password", {
      method: "POST",
      headers: { apikey: publicKey, "content-type": "application/json" },
      body: JSON.stringify({ email: user.email, password }),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) return false;
    const fresh = await response.json();
    if (typeof fresh.access_token !== "string") return false;
    // scope=local avoids revoking the caller's unrelated sessions.
    const logout = await fetch(url + "/auth/v1/logout?scope=local", {
      method: "POST",
      headers: {
        apikey: publicKey,
        authorization: "Bearer " + fresh.access_token,
      },
      signal: AbortSignal.timeout(10000),
    });
    return logout.ok && fresh.user?.id === user.id &&
      typeof fresh.user?.email_confirmed_at === "string";
  };
}
