/** Server entrypoint; no token, request body or remote error is logged. */
import { dispatch, markers, type Ports } from "./worker.ts";
export type VerifiedUser = {
  id: string;
  email?: string;
  email_confirmed_at?: string;
  identities?: { provider: string; identity_data?: { sub?: string } }[];
};
export function identityInputs(user: VerifiedUser): string[] {
  const inputs: string[] = [];
  // Auth's verified canonical email, no provider-specific Gmail alias folding.
  if (user.email_confirmed_at && user.email) {
    inputs.push("email:" + user.email.trim().toLowerCase());
  }
  for (const i of user.identities ?? []) {
    if (
      ["google", "apple", "kakao"].includes(i.provider) &&
      typeof i.identity_data?.sub === "string"
    ) inputs.push("provider:" + i.provider + ":" + i.identity_data.sub);
  }
  return [...new Set(inputs)];
}
export function createHttp(
  p: Ports,
  secret: string,
  keys: ReadonlyMap<string, Uint8Array>,
  verify: (jwt: string) => Promise<VerifiedUser>,
) {
  if (secret.length < 32) throw Error("ACTIVATION_GATE");
  return async (request: Request): Promise<Response> => {
    const reply = (status: number, state: unknown) =>
      Response.json(state, { status });
    if (request.method !== "POST") return reply(405, { state: "UNAVAILABLE" });
    const authorization = request.headers.get("authorization") ?? "";
    const token = authorization.startsWith("Bearer ")
      ? authorization.slice(7)
      : "";
    if (!token) return reply(401, { state: "UNAVAILABLE" });
    try {
      const path = new URL(request.url).pathname;
      if (path.endsWith("/dispatch")) {
        const digest = async (s: string) =>
          new Uint8Array(
            await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)),
          );
        const a = await digest(token), b = await digest(secret);
        let difference = 0;
        for (let i = 0; i < a.length; i++) difference |= a[i] ^ b[i];
        if (difference) return reply(403, { state: "DENIED" });
        return reply(200, await dispatch(p));
      }
      if (path.endsWith("/benefit")) {
        // Never accept a client-selected subject or marker; JWT is verified by Auth.
        const user = await verify(token);
        const health = await p.rpc("account_deletion_health", {}) as {
          enabled: boolean;
        };
        if (!health.enabled) return reply(503, { state: "BENEFIT_PENDING" });
        const result = await p.rpc("account_benefit_claim", {
          p_subject: user.id,
          p_markers: await markers(keys, identityInputs(user)),
        }) as { state: string };
        return reply(200, { state: result.state });
      }
      return reply(404, { state: "UNAVAILABLE" });
    } catch {
      return reply(503, { state: "UNAVAILABLE" });
    }
  };
}
