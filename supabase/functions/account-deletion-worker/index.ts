// Candidate deployment only. No secrets/default-enabled runtime in this repository.
import { createPorts } from "./server.ts";
import { createHttp } from "./http.ts";
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
  const keys = new Map(
    Object.entries(
      JSON.parse(env("ACCOUNT_BENEFIT_KEYS")) as Record<string, string>,
    ).map(([v, k]) => [v, decode(k)]),
  );
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
    financeReviewed: env("ACCOUNT_FINANCE_REVIEWED") === "true",
    checkpoint: (m) => webhook(checkpoint, m),
    notification: (e) => webhook(notification, e),
    provider: async () => false,
  });
  return createHttp(p, env("ACCOUNT_DISPATCH_SECRET"), keys, async (jwt) => {
    const response = await fetch(url + "/auth/v1/user", {
      headers: { apikey: publicKey, authorization: "Bearer " + jwt },
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw Error("DENIED");
    return await response.json();
  });
}
let handler: (r: Request) => Promise<Response>;
try {
  handler = configure();
} catch {
  handler = async () =>
    Response.json({ state: "UNAVAILABLE" }, { status: 503 });
}
Deno.serve(handler);
