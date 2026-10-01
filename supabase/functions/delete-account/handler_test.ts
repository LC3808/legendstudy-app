import { bearerToken, createHandler } from "./handler.ts";
function assert(v: unknown) {
  if (!v) throw Error("assertion failed");
}
const req = (body: unknown, token = true) =>
  new Request("https://example.invalid", {
    method: "POST",
    headers: token ? { authorization: "Bearer synthetic-token" } : {},
    body: JSON.stringify(body),
  });
Deno.test("caller target rejected, no privileged delete dependency", async () => {
  let calls = 0;
  const h = createHandler({
    call: async () => {
      calls++;
      return {};
    },
  });
  assert(
    (await h(req({ operation: "request", user_id: "forged" }))).status === 400,
  );
  assert(calls === 0);
});
Deno.test("request receipt is 202 pending, never deleted", async () => {
  const h = createHandler({
    call: async () => ({
      state: "DELETION_PENDING",
      scheduled_deletion_at: "2026-10-15T00:00:00Z",
      secret: "must-not-escape",
    }),
  });
  const r = await h(req({ operation: "request" }));
  assert(r.status === 202);
  const b = await r.text();
  assert(b.includes("DELETION_PENDING") && !b.includes("secret"));
});
Deno.test("anon denied before gateway", async () => {
  const h = createHandler({
    call: async () => {
      throw Error();
    },
  });
  assert((await h(req({ operation: "request" }, false))).status === 401);
  assert(bearerToken(req({})) === "synthetic-token");
});
Deno.test("reauth rejection remains sanitized", async () => {
  const h = createHandler({
    call: async () => {
      throw Error("sensitive");
    },
  });
  const r = await h(req({ operation: "cancel" }));
  assert(r.status === 403 && !(await r.text()).includes("sensitive"));
});
Deno.test("unknown old empty request cannot trigger deletion", async () => {
  const h = createHandler({
    call: async () => {
      throw Error();
    },
  });
  assert((await h(req({}))).status === 400);
});
