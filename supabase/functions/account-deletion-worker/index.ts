// Candidate deployment only. No secrets/default-enabled runtime in this repository.
import { createPorts } from "./server.ts";
import { createHttp } from "./http.ts";
import { createAuthBoundaries, emailChallenge } from "./auth-boundaries.ts";
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
  const p = createPorts({
    url,
    publicKey,
    workerJwt: env("ACCOUNT_WORKER_JWT"),
    authAdminKey: env("SUPABASE_SERVICE_ROLE_KEY"),
    benefitKeys: keys,
    restoreKey: decode(env("ACCOUNT_RESTORE_KEY")),
    restoreVersion: env("ACCOUNT_RESTORE_KEY_VERSION"),
    mathStorageEnabled: Deno.env.get("MATH_STORAGE_ENABLED") === "true",
    financeReviewed: env("ACCOUNT_FINANCE_REVIEWED") === "true",
    checkpoint: (m) => webhook(checkpoint, m),
    notification: (e) => webhook(notification, e),
    provider: async () => false,
  });
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
