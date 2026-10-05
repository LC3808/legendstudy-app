/** Trusted Auth integrations. No body/token/credential/error logging or persistence. */
import { identityInputs, type VerifiedUser } from "./http.ts";
import { markers } from "./worker.ts";
export type AuthBoundaries = {
  rpc(name: string, args: Record<string, unknown>): Promise<unknown>;
  verify(token: string): Promise<VerifiedUser>;
  challengeEmail(user: VerifiedUser, password: string): Promise<boolean>;
  /** Fresh social sign-in attestation (Google/Apple/Kakao). Optional until wired. */
  challengeOauth?(
    user: VerifiedUser,
    provider: string,
    idToken: string,
    nonce?: string,
  ): Promise<boolean>;
  /** Best-effort Apple revoke-material capture from a fresh authorization code. */
  captureAppleRevocation?(user: VerifiedUser, authorizationCode: string): Promise<void>;
  /** Kakao (browser/PKCE, no native id_token): attest from a recent same-owner session. */
  challengeKakao?(user: VerifiedUser, claims: Record<string, unknown>): boolean;
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
      if (!input || typeof input.provider !== "string") throw Error();
      const started = (p.now ?? Date.now)();
      let challenged = false;
      if (input.provider === "email") {
        if (
          Object.keys(input).sort().join(",") !== "password,provider" ||
          typeof input.password !== "string" || input.password.length < 1 ||
          input.password.length > 1024
        ) throw Error();
        challenged = await p.challengeEmail(user, input.password);
      } else if (input.provider === "google" || input.provider === "apple") {
        if (
          !p.challengeOauth ||
          typeof input.id_token !== "string" || input.id_token.length < 1 ||
          input.id_token.length > 8192 ||
          (input.nonce !== undefined && typeof input.nonce !== "string") ||
          (input.authorization_code !== undefined &&
            typeof input.authorization_code !== "string")
        ) throw Error();
        challenged = await p.challengeOauth(
          user,
          input.provider,
          input.id_token,
          typeof input.nonce === "string" ? input.nonce : undefined,
        );
        // Apple: capture revoke material from the fresh authorization code. Best-effort —
        // a capture failure never blocks reauth, and privacy erasure never depends on it.
        if (
          challenged && input.provider === "apple" &&
          typeof input.authorization_code === "string" &&
          input.authorization_code && p.captureAppleRevocation
        ) {
          try {
            await p.captureAppleRevocation(user, input.authorization_code);
          } catch { /* provider revoke stays best-effort; attest still proceeds */ }
        }
      } else if (input.provider === "kakao") {
        // Kakao has no native id_token. The client completes a fresh Kakao OAuth sign-in
        // (same owner, new session); we attest from a recent authentication in the caller's
        // own verified session claims (amr/auth_time, never access-token iat).
        if (!p.challengeKakao || Object.keys(input).join(",") !== "provider") {
          throw Error();
        }
        challenged = p.challengeKakao(user, claims);
      } else {
        throw Error();
      }
      if (!challenged) throw Error();
      if ((p.now ?? Date.now)() - started > 60000) throw Error();
      // No caller-selected subject/session or admin cancellation. A fresh challenge is required each time.
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

/** Real social adapter (Google/Apple/Kakao), disabled until Owner verifies provider
 * sign-in configuration. Mirrors emailChallenge: the client submits a FRESH provider
 * id_token it just obtained interactively; the server re-verifies it through Supabase's
 * id_token grant, confirms it resolves to the SAME owner, and immediately discards the
 * temporary session. The original caller session stays the attestation target. Freshness
 * is proven by server-side re-verification of a provider credential, not by access-token
 * iat. The provider must already be one of the user's linked identities. */
export function oauthChallenge(
  url: string,
  publicKey: string,
  enabled: boolean,
) {
  return async (
    user: VerifiedUser,
    provider: string,
    idToken: string,
    nonce?: string,
  ): Promise<boolean> => {
    if (!enabled) return false;
    if (!["google", "apple", "kakao"].includes(provider)) return false;
    // The claimed provider must be a verified identity of this owner.
    if (!(user.identities ?? []).some((i) => i.provider === provider)) return false;
    const response = await fetch(url + "/auth/v1/token?grant_type=id_token", {
      method: "POST",
      headers: { apikey: publicKey, "content-type": "application/json" },
      body: JSON.stringify({ provider, id_token: idToken, ...(nonce ? { nonce } : {}) }),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) return false;
    const fresh = await response.json();
    if (typeof fresh.access_token !== "string" || fresh.user?.id !== user.id) {
      return false;
    }
    // scope=local avoids revoking the caller's unrelated sessions.
    const logout = await fetch(url + "/auth/v1/logout?scope=local", {
      method: "POST",
      headers: {
        apikey: publicKey,
        authorization: "Bearer " + fresh.access_token,
      },
      signal: AbortSignal.timeout(10000),
    });
    return logout.ok;
  };
}

/** True when the verified session shows an interactive authentication within the window.
 * Uses `amr[].timestamp` (preferred) or `auth_time` — both reflect an actual sign-in and,
 * unlike access-token `iat`, do NOT advance on a silent token refresh. Fail-closed when no
 * authentication timestamp is present. */
export function recentAuthentication(
  claims: Record<string, unknown>,
  nowSeconds: number,
  maxAgeSeconds: number,
): boolean {
  const amr = Array.isArray(claims?.amr) ? claims.amr : [];
  const stamps = amr
    .map((entry) =>
      entry && typeof (entry as { timestamp?: unknown }).timestamp === "number"
        ? (entry as { timestamp: number }).timestamp
        : 0
    )
    .filter((t) => t > 0);
  const authTime = typeof claims?.auth_time === "number" ? claims.auth_time as number : 0;
  const latest = Math.max(0, ...stamps, authTime);
  if (!latest) return false;
  return latest <= nowSeconds + 60 && nowSeconds - latest <= maxAgeSeconds;
}

/** Kakao reauth adapter, disabled until Owner enables social reauth. Requires a linked
 * Kakao identity and a recent same-owner authentication. No provider HTTP call: the fresh
 * Kakao OAuth already produced the verified session the boundary checked. */
export function kakaoSessionChallenge(
  enabled: boolean,
  maxAgeSeconds = 300,
  now: () => number = () => Date.now(),
) {
  return (user: VerifiedUser, claims: Record<string, unknown>): boolean => {
    if (!enabled) return false;
    if (!(user.identities ?? []).some((i) => i.provider === "kakao")) return false;
    return recentAuthentication(claims, Math.floor(now() / 1000), maxAgeSeconds);
  };
}
