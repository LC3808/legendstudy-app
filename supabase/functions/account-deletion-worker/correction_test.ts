import { type Obligation, restoreGate } from "./restore.ts";
import { createAuthBoundaries, emailChallenge } from "./auth-boundaries.ts";
const assert = (v: unknown) => {
  if (!v) throw Error("assertion");
};
const secret = new Uint8Array(32).fill(4), keys = new Map([["v1", secret]]);
async function sign(text: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    secret,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(text)),
  );
}
const subject = "00000000-0000-0000-0000-000000000101",
  session = "00000000-0000-0000-0000-000000000102";
const proof = { inventoryComplete: true, checkpointFresh: true };
async function obligation(state: Obligation["state"]): Promise<Obligation> {
  return {
    request_id: "request-1",
    state,
    requested_at: "2026-10-01T00:00:00Z",
    deadline: "2026-10-15T00:00:00Z",
    cancelled_at: state === "CANCELLED" ? "2026-10-02T00:00:00Z" : null,
    completed_at: state === "ERASED" ? "2026-10-15T00:00:00Z" : null,
    expires_at: state === "CANCELLED"
      ? "2026-11-01T00:00:00Z"
      : state === "ERASED"
      ? "2026-11-14T00:00:00Z"
      : null,
    key_version: "v1",
    restore_tag: Array.from(
      await sign("legendstudy/restore-only\0" + subject),
      (b) => b.toString(16).padStart(2, "0"),
    ).join(""),
  };
}
for (
  const [name, state, now, action] of [
    [
      "R1 snapshot before request",
      "DELETION_PENDING",
      "2026-10-02",
      "RESTORE_RESTRICTION",
    ],
    [
      "R2 pending not due",
      "DELETION_PENDING",
      "2026-10-14",
      "RESTORE_RESTRICTION",
    ],
    [
      "R3 cancellation defeats stale pending",
      "CANCELLED",
      "2026-10-03",
      "NEUTRALIZE_CANCELLED",
    ],
    ["R4 erasing resumes", "ERASING", "2026-10-16", "RESUME_ERASURE"],
    ["R5 erased reapplied", "ERASED", "2026-10-16", "REAPPLY_ERASURE"],
    ["R6 scheduler late", "DELETION_PENDING", "2026-10-16", "RESUME_ERASURE"],
  ] as const
) {
  Deno.test(name, async () => {
    const r = await restoreGate(
      [subject],
      [await obligation(state)],
      keys,
      new Date(now),
      168,
      proof,
    );
    assert(
      !r.reopen && r.actions.length === 1 && r.actions[0].action === action &&
        r.actions[0].deadline === "2026-10-15T00:00:00Z",
    );
  });
}
Deno.test("R7 stale/incomplete/missing binding fails closed", async () => {
  for (
    const [p, o] of [[
      { ...proof, checkpointFresh: false },
      await obligation("CANCELLED"),
    ], [proof, {
      ...await obligation("CANCELLED"),
      restore_tag: null,
    }]] as const
  ) {
    let denied = false;
    try {
      await restoreGate([subject], [o], keys, new Date("2026-10-03"), 168, p);
    } catch {
      denied = true;
    }
    assert(denied);
  }
});
Deno.test("R8 deterministic duplicate replay and independent request identities", async () => {
  const a = await obligation("CANCELLED"),
    b = { ...await obligation("DELETION_PENDING"), request_id: "request-2" };
  const r = await restoreGate(
    [subject, subject],
    [b, a, a],
    keys,
    new Date("2026-10-03"),
    168,
    proof,
  );
  const repeat = await restoreGate(
    [subject],
    [a, b],
    keys,
    new Date("2026-10-03"),
    168,
    proof,
  );
  assert(JSON.stringify(r) === JSON.stringify(repeat));
  assert(r.actions.length === 2);
  assert(
    r.actions[0].action === "NEUTRALIZE_CANCELLED" &&
      r.actions[1].action === "RESTORE_RESTRICTION",
  );
});
const jwt = (sub = subject, sid = session) =>
  "synthetic." + btoa(JSON.stringify({ sub, session_id: sid })) + ".synthetic";
function authFixture(challenge = true) {
  const calls: { name: string; args: Record<string, unknown> }[] = [];
  const handler = createAuthBoundaries({
    rpc: async (name, args) => {
      calls.push({ name, args });
      if (name === "account_deletion_health") return { enabled: true };
      if (name === "account_identity_blocked") return false;
    },
    verify: async () => ({
      id: subject,
      email: "synthetic@example.invalid",
      email_confirmed_at: "verified",
    }),
    challengeEmail: async () => challenge,
    hookSecret: secret,
    identityKeys: keys,
    now: () => Date.parse("2026-10-03"),
  });
  return { handler, calls };
}
function reauth(body: unknown, token = jwt()) {
  return new Request("https://example.invalid/reauth", {
    method: "POST",
    headers: { authorization: "Bearer " + token },
    body: JSON.stringify(body),
  });
}
Deno.test("reauth fresh synthetic challenge attests server subject/session only", async () => {
  const f = authFixture();
  assert(
    (await f.handler(reauth({ provider: "email", password: "synthetic-only" })))
      .status === 200,
  );
  assert(
    f.calls[0].name === "account_reauth_attest" &&
      f.calls[0].args.p_subject === subject &&
      f.calls[0].args.p_session === session,
  );
});
Deno.test("reauth unavailable/wrong subject/forged target/old token alone deny", async () => {
  for (
    const [available, body, token] of [
      [false, { provider: "email", password: "synthetic" }, jwt()],
      [true, { provider: "email", password: "synthetic" }, jwt("wrong")],
      [
        true,
        { provider: "email", password: "synthetic", subject: "forged" },
        jwt(),
      ],
      [true, {}, jwt()],
      [true, { provider: "google", password: "synthetic" }, jwt()],
    ] as const
  ) {
    const f = authFixture(available);
    assert(
      (await f.handler(reauth(body, token))).status === 403 &&
        f.calls.length === 0,
    );
  }
});
Deno.test("email adapter disabled never calls provider", async () => {
  assert(
    !await emailChallenge("https://example.invalid", "synthetic", false)({
      id: subject,
      email: "synthetic@example.invalid",
      email_confirmed_at: "yes",
    }, "synthetic"),
  );
});
async function hookRequest(
  body: string,
  ts = Date.parse("2026-10-03") / 1000,
  signature = true,
) {
  const sig = btoa(String.fromCharCode(...await sign(`test.${ts}.${body}`)));
  return new Request("https://example.invalid/admission", {
    method: "POST",
    headers: {
      "webhook-id": "test",
      "webhook-timestamp": String(ts),
      "webhook-signature": signature ? "v1," + sig : "v1,invalid",
    },
    body,
  });
}
const hookBody = JSON.stringify({
  metadata: { name: "before-user-created" },
  user: {
    email: "synthetic@example.invalid",
    user_metadata: { email: "forged@example.invalid" },
  },
});
Deno.test("Auth admission verifies signature and uses deny-only signed candidate", async () => {
  const f = authFixture();
  assert((await f.handler(await hookRequest(hookBody))).status === 200);
  assert(f.calls.some((x) => x.name === "account_identity_blocked"));
  assert(!JSON.stringify(f.calls).includes("example.invalid"));
});
Deno.test("Auth hook forged signature/stale/body tamper denied without SQL", async () => {
  for (
    const req of [
      await hookRequest(hookBody, 1),
      await hookRequest(hookBody, Date.parse("2026-10-03") / 1000, false),
    ]
  ) {
    const f = authFixture();
    assert((await f.handler(req)).status === 503 && f.calls.length === 0);
  }
});
Deno.test("Auth admission matching active identity denies without benefit mutation", async () => {
  const handler = createAuthBoundaries({
    rpc: async (name) =>
      name === "account_deletion_health" ? { enabled: true } : true,
    verify: async () => {
      throw Error();
    },
    challengeEmail: async () => false,
    hookSecret: secret,
    identityKeys: keys,
    now: () => Date.parse("2026-10-03"),
  });
  assert((await handler(await hookRequest(hookBody))).status === 403);
});

import { createPorts } from "./server.ts";
const testJob = {
  request_id: "synthetic-request",
  subject_id: subject,
  phase: "PERSONAL",
  lease_token: "synthetic-lease",
};
for (
  const [name, user, benefitKeys, expected] of [
    [
      "I1 verified email",
      {
        id: subject,
        email: "synthetic@example.invalid",
        email_confirmed_at: "yes",
      },
      keys,
      "CAPTURED",
    ],
    [
      "I2 provider subject",
      {
        id: subject,
        identities: [{
          provider: "google",
          identity_data: { sub: "synthetic" },
        }],
      },
      keys,
      "CAPTURED",
    ],
    ["I3 no verified identity", { id: subject }, keys, "NOT_AVAILABLE"],
    [
      "I4 unsupported provider",
      {
        id: subject,
        identities: [{
          provider: "unsupported",
          identity_data: { sub: "synthetic" },
        }],
      },
      keys,
      "NOT_AVAILABLE",
    ],
    [
      "I5 missing marker key",
      {
        id: subject,
        email: "synthetic@example.invalid",
        email_confirmed_at: "yes",
      },
      new Map(),
      "FAILED_SAFE",
    ],
    [
      "I6 invalid key",
      {
        id: subject,
        email: "synthetic@example.invalid",
        email_confirmed_at: "yes",
      },
      new Map([["v1", new Uint8Array(1)]]),
      "FAILED_SAFE",
    ],
    [
      "I11 combinations bounded",
      {
        id: subject,
        email: "synthetic@example.invalid",
        email_confirmed_at: "yes",
      },
      new Map(Array.from({ length: 17 }, (_, i) => ["v" + i, secret])),
      "FAILED_SAFE",
    ],
  ] as const
) {
  Deno.test(name + " capture and independent restore binding", async () => {
    const old = globalThis.fetch, calls: { url: string; body: unknown }[] = [];
    globalThis.fetch = async (input, init) => {
      const url = String(input);
      const body = init?.body ? JSON.parse(String(init.body)) : null;
      calls.push({ url, body });
      return Response.json(
        url.includes("/auth/")
          ? user
          : url.endsWith("restore_manifest")
          ? []
          : null,
      );
    };
    try {
      const ports = createPorts({
        url: "https://example.invalid",
        publicKey: "synthetic",
        workerJwt: "synthetic",
        authAdminKey: "synthetic",
        benefitKeys,
        restoreKey: secret,
        restoreVersion: "v1",
        financeReviewed: true,
        checkpoint: async () => {},
        notification: async () => {},
        provider: async () => false,
      });
      assert(await ports.captureBenefit(testJob) === expected);
      await ports.bindAndCheckpoint(testJob);
      const bind = calls.find((c) => c.url.endsWith("account_deletion_bind"));
      assert(bind && !JSON.stringify(bind.body).includes("example.invalid"));
      assert(!calls.some((c) => c.url.includes("auth") && c.body)); // No account creation/deletion in capture.
    } finally {
      globalThis.fetch = old;
    }
  });
}
Deno.test("email challenge verifies same user and revokes only temporary session", async () => {
  const old = globalThis.fetch, paths: string[] = [];
  globalThis.fetch = async (input) => {
    paths.push(String(input));
    return paths.length === 1
      ? Response.json({
        access_token: "synthetic",
        user: { id: subject, email_confirmed_at: "yes" },
      })
      : new Response(null, { status: 204 });
  };
  try {
    assert(
      await emailChallenge("https://example.invalid", "synthetic", true)({
        id: subject,
        email: "synthetic@example.invalid",
        email_confirmed_at: "yes",
      }, "synthetic"),
    );
    assert(paths[1].endsWith("/logout?scope=local"));
  } finally {
    globalThis.fetch = old;
  }
});

Deno.test("R8 verified replay postconditions allow reopen without repeating effects", async () => {
  const o = await obligation("CANCELLED");
  const planned = await restoreGate(
    [subject],
    [o],
    keys,
    new Date("2026-10-03"),
    168,
    proof,
  );
  const applied = JSON.stringify(planned.actions[0]);
  const result = await restoreGate(
    [subject],
    [o],
    keys,
    new Date("2026-10-03"),
    168,
    {
      ...proof,
      verifyAction: async (action) => JSON.stringify(action) === applied,
    },
  );
  assert(result.reopen && result.actions.length === 0);
  const changed = {
    ...await obligation("DELETION_PENDING"),
    request_id: "later-request",
  };
  assert(
    !(await restoreGate(
      [subject],
      [changed],
      keys,
      new Date("2026-10-03"),
      168,
      {
        ...proof,
        verifyAction: async (action) => JSON.stringify(action) === applied,
      },
    )).reopen,
  );
});
