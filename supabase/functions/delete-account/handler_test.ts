import { bearerToken, createHandler } from "./handler.ts";
import type { AccountDeletionAdmin } from "./handler.ts";

function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Assertion failed: ${JSON.stringify(actual)}`);
  }
}

type Calls = { resolved: string[]; deleted: string[] };

const admin = (
  calls: Calls,
  options: {
    tokens?: Record<string, string>;
    admins?: string[];
    deleted?: Set<string>;
    throwOn?: "resolve" | "admin" | "delete";
  } = {},
): AccountDeletionAdmin => {
  const tokens = options.tokens ?? { "good-token": "user-a" };
  const gone = options.deleted ?? new Set<string>();
  return {
    async userIdFromToken(token) {
      if (options.throwOn === "resolve") throw new Error("boom");
      calls.resolved.push(token);
      return tokens[token] ?? null;
    },
    async isAdmin(userId) {
      if (options.throwOn === "admin") throw new Error("boom");
      return (options.admins ?? []).includes(userId);
    },
    async deleteUser(userId) {
      if (options.throwOn === "delete") throw new Error("boom");
      calls.deleted.push(userId);
      gone.add(userId);
      return true;
    },
  };
};

const post = (init: RequestInit = {}) =>
  new Request("https://example.invalid/delete-account", {
    method: "POST",
    ...init,
  });

const authed = (token = "good-token", body?: unknown) =>
  post({
    headers: { authorization: `Bearer ${token}` },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

Deno.test("a caller is identified only by the bearer token", () => {
  equal(bearerToken(post()), null);
  equal(bearerToken(post({ headers: { authorization: "Basic abc" } })), null);
  equal(bearerToken(post({ headers: { authorization: "Bearer  " } })), null);
  equal(
    bearerToken(post({ headers: { authorization: "Bearer abc.def" } })),
    "abc.def",
  );
});

Deno.test("no token is refused before anything else happens", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const response = await createHandler(admin(calls))(post());
  equal(response.status, 401);
  equal(await response.json(), { error: "unauthorized" });
  equal(calls.deleted, []);
});

Deno.test("an unknown token deletes nothing", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const response = await createHandler(admin(calls))(authed("stale-token"));
  equal(response.status, 401);
  equal(calls.deleted, []);
});

Deno.test("the body cannot name the account to delete", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const response = await createHandler(admin(calls))(
    authed("good-token", { user_id: "victim", email: "victim@example.com" }),
  );
  equal(response.status, 200);
  equal(await response.json(), { status: "deleted" });
  equal(calls.deleted, ["user-a"]);
});

Deno.test("an admin cannot delete themselves from the app", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const handler = createHandler(admin(calls, { admins: ["user-a"] }));
  const response = await handler(authed());
  equal(response.status, 403);
  equal(await response.json(), { error: "admin_blocked" });
  equal(calls.deleted, []);
});

Deno.test("repeating the request stays safe and says the same thing", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const handler = createHandler(admin(calls));
  const first = await handler(authed());
  const second = await handler(authed());
  equal(first.status, 200);
  equal(second.status, 200);
  equal(await second.json(), { status: "deleted" });
});

Deno.test("a failure is reported without leaking anything", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  for (const stage of ["resolve", "admin", "delete"] as const) {
    const handler = createHandler(admin(calls, { throwOn: stage }));
    const response = await handler(authed());
    equal(response.status, 500);
    equal(await response.json(), { error: "deletion_failed" });
  }
});

Deno.test("only POST deletes, and preflight carries no data", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const handler = createHandler(admin(calls));
  const get = await handler(
    new Request("https://example.invalid/delete-account", { method: "GET" }),
  );
  equal(get.status, 405);
  const preflight = await handler(
    new Request("https://example.invalid/delete-account", {
      method: "OPTIONS",
    }),
  );
  equal(preflight.status, 204);
  equal(await preflight.text(), "");
  equal(calls.deleted, []);
});

Deno.test("the response never carries schema or identifiers", async () => {
  const calls: Calls = { resolved: [], deleted: [] };
  const response = await createHandler(admin(calls))(authed());
  const body = await response.text();
  for (const leak of ["user-a", "good-token", "profiles", "bookmarks"]) {
    if (body.includes(leak)) throw new Error(`leaked ${leak}`);
  }
});
