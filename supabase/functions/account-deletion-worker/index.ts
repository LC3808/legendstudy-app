// Candidate deployment only. No secrets/default-enabled runtime in this repository.
import { createPorts } from "./server.ts";
import { createHttp } from "./http.ts";
import {
  createAuthBoundaries,
  emailChallenge,
  kakaoSessionChallenge,
  oauthChallenge,
} from "./auth-boundaries.ts";
import { createAppleProvider, type StoredProviderMaterial } from "./apple-provider.ts";
import { exchangeAppleAuthorizationCode } from "./apple-token-exchange.ts";
import type { AppleSigningConfig } from "./apple-client-secret.ts";
import type { Ports } from "./worker.ts";
const env = (key: string) => {
  const value = Deno.env.get(key);
  if (!value) throw Error("ACTIVATION_GATE");
  return value;
};
function configure() {
  if (env("ACCOUNT_LIFECYCLE_ENABLED") !== "true") {
    throw Error("ACTIVATION_GATE");
  }
  const url = env("SUPABASE_URL"), publicKey = env("SUPABASE_ANON_KEY");
  const decode = (v: string) =>
    Uint8Array.from(atob(v), (c) => c.charCodeAt(0));
  let keys = new Map<string, Uint8Array>();
  try {
    keys = new Map(
      Object.entries(
        JSON.parse(Deno.env.get("ACCOUNT_BENEFIT_KEYS") ?? "{}") as Record<
          string,
          string
        >,
      ).map(([v, k]) => [v, decode(k)]),
    );
  } catch {
    /* Promotional capture fails safely; privacy worker stays available. */
  }
  const webhook = async (endpoint: string, payload: unknown) => {
    if (!endpoint.startsWith("https://")) throw Error("ACTIVATION_GATE");
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        authorization: "Bearer " + env("ACCOUNT_OPERATIONS_TOKEN"),
        "content-type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw Error("REMOTE_UNAVAILABLE");
  };
  const checkpoint = env("ACCOUNT_RESTORE_CHECKPOINT_URL"),
    notification = env("ACCOUNT_NOTIFICATION_URL");
  // Apple revoke signing material (Owner secrets). Absent -> provider stays unknown/false
  // and privacy erasure is never blocked.
  const appleP8 = Deno.env.get("APPLE_SIGNIN_KEY_P8"),
    appleKeyId = Deno.env.get("APPLE_SIGNIN_KEY_ID"),
    appleTeamId = Deno.env.get("APPLE_TEAM_ID"),
    appleClientId = Deno.env.get("APPLE_SIGNIN_CLIENT_ID");
  const appleSigning: AppleSigningConfig | null =
    appleP8 && appleKeyId && appleTeamId && appleClientId
      ? { privateKeyPem: appleP8, keyId: appleKeyId, teamId: appleTeamId, clientId: appleClientId }
      : null;
  let portsRef: Ports | null = null;
  const provider = createAppleProvider({
    signing: appleSigning,
    readMaterial: async (job) =>
      (await portsRef!.rpc("account_provider_material", {
        p_id: job.request_id,
        p_token: job.lease_token,
      })) as StoredProviderMaterial,
  });
  const p = createPorts({
    url,
    publicKey,
    workerJwt: env("ACCOUNT_WORKER_JWT"),
    authAdminKey: env("SUPABASE_SERVICE_ROLE_KEY"),
    benefitKeys: keys,
    restoreKey: decode(env("ACCOUNT_RESTORE_KEY")),
    restoreVersion: env("ACCOUNT_RESTORE_KEY_VERSION"),
    financeReviewed: env("ACCOUNT_FINANCE_REVIEWED") === "true",
    checkpoint: (m) => webhook(checkpoint, m),
    notification: (e) => webhook(notification, e),
    provider,
  });
  portsRef = p;
  const verify = async (jwt: string) => {
    const response = await fetch(url + "/auth/v1/user", {
      headers: { apikey: publicKey, authorization: "Bearer " + jwt },
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw Error("DENIED");
    return await response.json();
  };
  const normal = createHttp(p, env("ACCOUNT_DISPATCH_SECRET"), keys, verify);
  const hook = Deno.env.get("ACCOUNT_AUTH_HOOK_SECRET");
  let hookSecret: Uint8Array | undefined;
  try {
    if (hook) {
      hookSecret = decode(
        hook.replace(/^v1,whsec_/, "").replace(/^whsec_/, ""),
      );
    }
  } catch { /* Only admission fails closed; erasure remains available. */ }
  const boundary = createAuthBoundaries({
    rpc: p.rpc,
    verify,
    challengeEmail: emailChallenge(
      url,
      publicKey,
      Deno.env.get("ACCOUNT_EMAIL_REAUTH_ENABLED") === "true",
    ),
    challengeOauth: oauthChallenge(
      url,
      publicKey,
      Deno.env.get("ACCOUNT_SOCIAL_REAUTH_ENABLED") === "true",
    ),
    challengeKakao: kakaoSessionChallenge(
      Deno.env.get("ACCOUNT_SOCIAL_REAUTH_ENABLED") === "true",
    ),
    captureAppleRevocation: async (user, code) => {
      if (!appleSigning) return;
      const exchanged = await exchangeAppleAuthorizationCode(appleSigning, code);
      if (!exchanged) return;
      await p.rpc("account_store_apple_revocation", {
        p_subject: user.id,
        p_token: exchanged.refreshToken,
        p_token_type: "refresh_token",
      });
    },
    hookSecret,
    identityKeys: new Map([[
      env("ACCOUNT_RESTORE_KEY_VERSION"),
      decode(env("ACCOUNT_RESTORE_KEY")),
    ]]),
  });
  return (request: Request) => {
    const path = new URL(request.url).pathname;
    return path.endsWith("/reauth") || path.endsWith("/admission")
      ? boundary(request)
      : normal(request);
  };
}
let handler: (r: Request) => Promise<Response>;
try {
  handler = configure();
} catch {
  handler = async () =>
    Response.json({ state: "UNAVAILABLE" }, { status: 503 });
}
Deno.serve(handler);
