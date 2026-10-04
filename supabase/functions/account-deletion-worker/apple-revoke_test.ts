import { revokeAppleToken, type AppleRevocationMaterial } from "./apple-revoke.ts";
const material: AppleRevocationMaterial = { clientId: "com.legendstudy.app", clientSecret: "synthetic-secret", token: "synthetic-token", tokenType: "refresh_token" };
function check(value: boolean) { if (!value) throw Error("assertion failed"); }
Deno.test("Apple revoke posts form to fixed endpoint, no redirects or logs", async () => {
  check(await revokeAppleToken(material, ((url, init) => {
    check(url === "https://appleid.apple.com/auth/revoke" && init?.redirect === "error");
    const form = init?.body as URLSearchParams;
    check(form.get("client_id") === "com.legendstudy.app" && form.get("token_type_hint") === "refresh_token");
    return Promise.resolve(new Response(null, { status: 200 }));
  }) as typeof fetch));
});
Deno.test("Apple absent, wrong client, failure, timeout never claim verified", async () => {
  const reject = (() => { throw Error("synthetic transport error"); }) as typeof fetch;
  check(!await revokeAppleToken(null, reject));
  check(!await revokeAppleToken({ ...material, clientId: "wrong" }, reject));
  check(!await revokeAppleToken(material, reject));
  for (const status of [302, 400, 401, 429, 500]) {
    check(!await revokeAppleToken(material, (() => Promise.resolve(new Response(null, { status }))) as typeof fetch));
  }
});
