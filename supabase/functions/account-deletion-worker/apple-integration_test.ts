import { appleClientSecret, type AppleSigningConfig } from "./apple-client-secret.ts";
import { exchangeAppleAuthorizationCode } from "./apple-token-exchange.ts";
import { createAppleProvider } from "./apple-provider.ts";
import { oauthChallenge } from "./auth-boundaries.ts";
import type { Job } from "./worker.ts";

function check(value: boolean, message = "assertion failed") {
  if (!value) throw Error(message);
}
function b64urlToBytes(s: string): Uint8Array {
  return Uint8Array.from(
    atob(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "=")),
    (c) => c.charCodeAt(0),
  );
}
function jsonPart(s: string): Record<string, unknown> {
  return JSON.parse(new TextDecoder().decode(b64urlToBytes(s)));
}

async function syntheticSigning(): Promise<{ cfg: AppleSigningConfig; publicKey: CryptoKey }> {
  const kp = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", kp.privateKey));
  const b64 = btoa(String.fromCharCode(...pkcs8)).match(/.{1,64}/g)!.join("\n");
  const pem = `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`;
  return {
    cfg: { teamId: "TEAM123456", keyId: "KEY1234567", clientId: "com.legendstudy.app", privateKeyPem: pem },
    publicKey: kp.publicKey,
  };
}

const material = { provider: "apple", token: "refresh-xyz", token_type: "refresh_token" as const };
const job: Job = { request_id: "11111111-1111-1111-1111-111111111111", subject_id: "s1", phase: "PROVIDER", lease_token: "22222222-2222-2222-2222-222222222222" };

Deno.test("appleClientSecret produces a valid ES256 JWT with Apple claims", async () => {
  const { cfg, publicKey } = await syntheticSigning();
  const jwt = await appleClientSecret(cfg, 1_700_000_000_000);
  const [h, pl, sig] = jwt.split(".");
  check(!!h && !!pl && !!sig, "three parts");
  const header = jsonPart(h);
  check(header.alg === "ES256" && header.kid === "KEY1234567");
  const payload = jsonPart(pl);
  check(payload.iss === "TEAM123456" && payload.sub === "com.legendstudy.app");
  check(payload.aud === "https://appleid.apple.com");
  check((payload.exp as number) > (payload.iat as number));
  const ok = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    publicKey,
    b64urlToBytes(sig) as BufferSource,
    new TextEncoder().encode(`${h}.${pl}`),
  );
  check(ok, "signature verifies against the public key");
});

Deno.test("appleClientSecret fails closed on missing material", async () => {
  let threw = false;
  try {
    await appleClientSecret({ teamId: "", keyId: "", clientId: "", privateKeyPem: "" });
  } catch {
    threw = true;
  }
  check(threw);
});

Deno.test("exchangeAppleAuthorizationCode returns refresh token on 200, null otherwise", async () => {
  const { cfg } = await syntheticSigning();
  const ok = await exchangeAppleAuthorizationCode(cfg, "code-1", ((url, init) => {
    check(url === "https://appleid.apple.com/auth/token" && init?.redirect === "error");
    const form = init?.body as URLSearchParams;
    check(form.get("grant_type") === "authorization_code" && form.get("code") === "code-1");
    check((form.get("client_secret") ?? "").split(".").length === 3);
    return Promise.resolve(Response.json({ refresh_token: "rt-123" }));
  }) as typeof fetch);
  check(ok?.refreshToken === "rt-123");

  check(await exchangeAppleAuthorizationCode(cfg, "", (() => { throw Error(); }) as typeof fetch) === null);
  check(await exchangeAppleAuthorizationCode(cfg, "c", (() => Promise.resolve(new Response(null, { status: 400 }))) as typeof fetch) === null);
  check(await exchangeAppleAuthorizationCode(cfg, "c", (() => Promise.resolve(Response.json({}))) as typeof fetch) === null);
  check(await exchangeAppleAuthorizationCode(cfg, "c", (() => { throw Error("net"); }) as typeof fetch) === null);
});

Deno.test("createAppleProvider: no credential / no material / wrong provider never claim success", async () => {
  const reject = (() => { throw Error(); }) as typeof fetch;
  const { cfg } = await syntheticSigning();
  check(!await createAppleProvider({ signing: null, readMaterial: async () => material, transport: reject })(job));
  check(!await createAppleProvider({ signing: cfg, readMaterial: async () => null, transport: reject })(job));
  check(!await createAppleProvider({ signing: cfg, readMaterial: async () => ({ ...material, provider: "google" }), transport: reject })(job));
  check(!await createAppleProvider({ signing: cfg, readMaterial: async () => { throw Error("rpc"); }, transport: reject })(job));
});

Deno.test("createAppleProvider: verified material + accepted revoke returns true with a real client_secret", async () => {
  const { cfg } = await syntheticSigning();
  let sawSecret = false;
  const provider = createAppleProvider({
    signing: cfg,
    readMaterial: async () => material,
    transport: ((_url, init) => {
      const form = init?.body as URLSearchParams;
      sawSecret = (form.get("client_secret") ?? "").split(".").length === 3 &&
        form.get("token") === "refresh-xyz" && form.get("client_id") === "com.legendstudy.app";
      return Promise.resolve(new Response(null, { status: 200 }));
    }) as typeof fetch,
  });
  check(await provider(job));
  check(sawSecret, "revoke received a freshly signed client_secret and the stored token");
});

Deno.test("oauthChallenge: disabled / unlinked provider / wrong owner deny; fresh same-owner accepts", async () => {
  const user = { id: "owner-1", identities: [{ provider: "apple", identity_data: { sub: "apple-sub" } }] };
  check(!await oauthChallenge("https://x.invalid", "pk", false)(user, "apple", "idtok"));
  // provider not among the user's identities
  check(!await oauthChallenge("https://x.invalid", "pk", true)(
    { id: "owner-1", identities: [{ provider: "google" }] }, "apple", "idtok",
  ));

  const old = globalThis.fetch;
  try {
    const paths: string[] = [];
    globalThis.fetch = ((input: string | URL | Request) => {
      paths.push(String(input));
      return Promise.resolve(
        paths.length === 1
          ? Response.json({ access_token: "fresh", user: { id: "owner-1" } })
          : new Response(null, { status: 204 }),
      );
    }) as typeof fetch;
    check(await oauthChallenge("https://x.invalid", "pk", true)(user, "apple", "idtok"));
    check(paths[0].includes("/auth/v1/token?grant_type=id_token"));
    check(paths[1].endsWith("/logout?scope=local"));

    // fresh session resolves to a DIFFERENT owner -> deny
    globalThis.fetch = (() =>
      Promise.resolve(Response.json({ access_token: "fresh", user: { id: "intruder" } }))) as typeof fetch;
    check(!await oauthChallenge("https://x.invalid", "pk", true)(user, "apple", "idtok"));
  } finally {
    globalThis.fetch = old;
  }
});
