import { dispatch, type Job, markers, type Ports } from "./worker.ts";
import { eraseOwnedStorage } from "./storage.ts";
function assert(v: unknown) {
  if (!v) throw Error("assertion failed");
}
const job: Job = {
  request_id: "synthetic",
  subject_id: "00000000-0000-0000-0000-000000000001",
  lease_token: "lease",
  phase: "PERSONAL",
};
function fixture() {
  const calls: string[] = [];
  let retry: unknown;
  const p: Ports = {
    claimVerifiedBenefit: async () => {},
    captureBenefit: async () => "CAPTURED",
    rpc: async (name, args) => {
      calls.push(name);
      if (name === "account_deletion_claim") return [{ ...job }];
      if (
        name === "account_deletion_notifications" ||
        name === "account_deletion_unbound" ||
        name === "account_benefit_candidates"
      ) return [];
      if (name === "account_deletion_personal") return true;
      if (name === "account_deletion_retry") retry = args;
      return null;
    },
    bindAndCheckpoint: async () => {
      calls.push("bind");
    },
    storageEraseAndVerify: async () => {
      calls.push("storage");
    },
    providerEraseAndVerify: async () => {
      calls.push("provider");
      return true;
    },
    financePolicyReady: () => true,
    authDeleteAndVerify: async () => {
      calls.push("auth");
    },
    verifyErasure: async () => true,
    checkpointManifest: async () => {
      calls.push("checkpoint");
    },
    notify: async () => {},
  };
  return { p, calls, retry: () => retry };
}
Deno.test("worker: Auth follows personal/storage/provider/finance; finish follows verify", async () => {
  const { p, calls } = fixture();
  const r = await dispatch(p);
  assert(r.processed === 1);
  assert(calls.indexOf("auth") > calls.indexOf("storage"));
  assert(calls.indexOf("account_deletion_finish") > calls.indexOf("auth"));
});
Deno.test("storage failure retries sanitized, never Auth or ERASED", async () => {
  const f = fixture();
  f.p.storageEraseAndVerify = async () => {
    throw Error("private exception");
  };
  const r = await dispatch(f.p);
  assert(r.retryable === 1 && !f.calls.includes("auth"));
  assert(!JSON.stringify(f.retry()).includes("private exception"));
});
Deno.test("unsupported provider is external gate after local personal erase", async () => {
  const f = fixture();
  f.p.providerEraseAndVerify = async () => false;
  await dispatch(f.p);
  assert(
    f.calls.includes("account_deletion_personal") && f.calls.includes("auth"),
  );
  assert(f.calls.includes("account_deletion_finish"));
  assert(f.retry() === undefined);
});
Deno.test("failed postcondition cannot finish", async () => {
  const f = fixture();
  f.p.verifyErasure = async () => false;
  await dispatch(f.p);
  assert(!f.calls.includes("account_deletion_finish"));
});
Deno.test("notification failure independent of erasure", async () => {
  const f = fixture();
  const rpc = f.p.rpc;
  f.p.rpc = async (n, a) =>
    n === "account_deletion_notifications"
      ? [{ request_id: "synthetic" }]
      : rpc(n, a);
  f.p.notify = async () => {
    throw Error();
  };
  assert((await dispatch(f.p)).processed === 1);
});
Deno.test("Auth timeout retries; no success claimed", async () => {
  const f = fixture();
  f.p.authDeleteAndVerify = async () => {
    throw Error();
  };
  assert((await dispatch(f.p)).retryable === 1);
  assert(!f.calls.includes("account_deletion_finish"));
});
Deno.test("missing subject resumes only through independent verification", async () => {
  const f = fixture();
  const rpc = f.p.rpc;
  f.p.rpc = async (n, a) =>
    n === "account_deletion_claim"
      ? [{ ...job, subject_id: null, phase: "AUTH" }]
      : rpc(n, a);
  await dispatch(f.p);
  assert(!f.calls.includes("auth"));
  assert(f.calls.includes("account_deletion_finish"));
});
Deno.test("markers HMAC purpose separated, stable, no raw identity; old key version preserved", async () => {
  const k = new Map([["v1", new Uint8Array(32).fill(7)]]);
  const a = await markers(k, ["email:synthetic@example.invalid"]);
  k.set("v2", new Uint8Array(32).fill(8));
  const b = await markers(k, ["email:synthetic@example.invalid"]);
  assert(a[0].marker === b[0].marker && a[0].marker !== b[1].marker);
  assert(!JSON.stringify(b).includes("example"));
});
Deno.test("missing secret denies benefit computation", async () => {
  let denied = false;
  try {
    await markers(new Map(), ["synthetic"]);
  } catch {
    denied = true;
  }
  assert(denied);
});
Deno.test("storage API bounded owned inventory and idempotent empty", async () => {
  let rows = [{ id: "object", name: "avatar.png" }, {
    id: "other",
    name: "alternate.png",
  }];
  const api = {
    list: async () => rows,
    remove: async (_b: string, p: string[]) => {
      assert(p.every((x) => x.startsWith(job.subject_id! + "/")));
      rows = [];
    },
  };
  await eraseOwnedStorage(api, job.subject_id!);
  await eraseOwnedStorage(api, job.subject_id!);
  assert(rows.length === 0);
});

Deno.test("benefit and lifecycle markers cannot be joined by equality", async () => {
  const k = new Map([["v1", new Uint8Array(32).fill(7)]]);
  const a = await markers(k, ["email:synthetic@example.invalid"]);
  const b = await markers(k, ["email:synthetic@example.invalid"], "lifecycle");
  assert(a[0].marker !== b[0].marker);
});

import { createHttp, identityInputs } from "./http.ts";
Deno.test("HTTP dispatcher denies ordinary JWT; benefit subject is server derived", async () => {
  const f = fixture();
  let subject: unknown;
  const rpc = f.p.rpc;
  f.p.rpc = async (n, a) => {
    if (n === "account_deletion_health") return { enabled: true };
    if (n === "account_benefit_claim") {
      subject = a.p_subject;
      return { state: "GRANTED", private: "hidden" };
    }
    return rpc(n, a);
  };
  const handler = createHttp(
    f.p,
    "s".repeat(32),
    new Map([["test", new Uint8Array(32).fill(1)]]),
    async () => ({
      id: "verified-subject",
      email: "Synthetic@Example.invalid",
      email_confirmed_at: "synthetic",
    }),
  );
  assert(
    (await handler(
      new Request("https://example.invalid/dispatch", {
        method: "POST",
        headers: { authorization: "Bearer ordinary" },
      }),
    )).status === 403,
  );
  const response = await handler(
    new Request("https://example.invalid/benefit", {
      method: "POST",
      headers: { authorization: "Bearer synthetic" },
      body: JSON.stringify({ p_subject: "forged" }),
    }),
  );
  assert(subject === "verified-subject");
  assert(JSON.stringify(await response.json()) === '{"state":"GRANTED"}');
  assert(
    identityInputs({ id: "x", email: "unverified@example.invalid" }).length ===
      0,
  );
});
Deno.test("benefit outage returns pending/unavailable without Auth creation mutation", async () => {
  const f = fixture();
  f.p.rpc = async () => {
    throw Error("private");
  };
  const handler = createHttp(
    f.p,
    "s".repeat(32),
    new Map(),
    async () => ({ id: "verified" }),
  );
  const response = await handler(
    new Request("https://example.invalid/benefit", {
      method: "POST",
      headers: { authorization: "Bearer synthetic" },
    }),
  );
  assert(response.status === 503);
  assert(!JSON.stringify(await response.json()).includes("private"));
});
Deno.test("unfinished bounded personal batch remains retryable before external cleanup", async () => {
  const f = fixture();
  const rpc = f.p.rpc;
  f.p.rpc = async (n, a) =>
    n === "account_deletion_personal" ? false : rpc(n, a);
  assert((await dispatch(f.p)).retryable === 1);
  assert(!f.calls.includes("storage"));
});

import { createPorts } from "./server.ts";
Deno.test("Auth timeout after successful delete reconciles by independent absence", async () => {
  const original = globalThis.fetch;
  let gone = false;
  let calls = 0;
  globalThis.fetch = async (_input, init) => {
    calls++;
    if (init?.method === "DELETE") {
      gone = true;
      throw Error("synthetic timeout");
    }
    return gone
      ? new Response("{}", { status: 404 })
      : Response.json({ id: "synthetic" });
  };
  try {
    const p = createPorts({
      url: "https://example.invalid",
      publicKey: "synthetic",
      workerJwt: "synthetic",
      authAdminKey: "synthetic",
      benefitKeys: new Map([["v1", new Uint8Array(32).fill(1)]]),
      restoreKey: new Uint8Array(32).fill(2),
      restoreVersion: "v1",
      financeReviewed: true,
      checkpoint: async () => {},
      notification: async () => {},
      provider: async () => false,
    });
    await p.authDeleteAndVerify("synthetic");
    assert(calls === 3);
  } finally {
    globalThis.fetch = original;
  }
});

import { restoreGate } from "./restore.ts";
Deno.test("restore gate fails closed for incompatible backup horizon or missing key", async () => {
  let denied = false;
  try {
    await restoreGate([], [], new Map(), new Date(), 721, {
      inventoryComplete: true,
      checkpointFresh: true,
    });
  } catch {
    denied = true;
  }
  assert(denied);
  const keys = new Map([["v1", new Uint8Array(32).fill(2)]]);
  const secret = await crypto.subtle.importKey(
    "raw",
    keys.get("v1")! as BufferSource,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const tag = Array.from(
    new Uint8Array(
      await crypto.subtle.sign(
        "HMAC",
        secret,
        new TextEncoder().encode("legendstudy/restore-only\0synthetic"),
      ),
    ),
    (b) => b.toString(16).padStart(2, "0"),
  ).join("");
  const result = await restoreGate(
    ["synthetic"],
    [{
      request_id: "request",
      state: "ERASED",
      requested_at: "2026-09-17T00:00:00Z",
      cancelled_at: null,
      completed_at: "2026-10-01T00:00:00Z",
      deadline: "2026-10-01T00:00:00Z",
      expires_at: "2026-10-31T00:00:00Z",
      key_version: "v1",
      restore_tag: tag,
    }],
    keys,
    new Date("2026-10-02"),
    168,
    { inventoryComplete: true, checkpointFresh: true },
  );
  assert(!result.reopen && result.actions.length === 1);
});

for (const state of ["NOT_AVAILABLE", "FAILED_SAFE"] as const) {
  Deno.test(
    "I3-I6/I11 " + state + " capture cannot stop personal/Auth erasure",
    async () => {
      const f = fixture();
      f.p.captureBenefit = async () => state;
      assert((await dispatch(f.p)).processed === 1);
      assert(
        f.calls.includes("account_deletion_personal") &&
          f.calls.includes("auth"),
      );
      assert(f.calls.includes("account_deletion_capture_result"));
    },
  );
}
Deno.test("unexpected marker exception also continues erasure", async () => {
  const f = fixture();
  f.p.captureBenefit = async () => {
    throw Error("synthetic failure");
  };
  assert((await dispatch(f.p)).processed === 1 && f.calls.includes("auth"));
});
Deno.test("cancelled unbound intent is checkpointed without an erasure claim", async () => {
  const f = fixture(), base = f.p.rpc;
  f.p.rpc = async (n, a) =>
    n === "account_deletion_unbound"
      ? [{ ...job, state: "CANCELLED" }]
      : n === "account_deletion_claim"
      ? []
      : base(n, a);
  await dispatch(f.p);
  assert(f.calls.includes("bind") && !f.calls.includes("auth"));
});
Deno.test("Math cleanup completes before provider/Auth and receives the fenced lease", async () => {
  const f = fixture();
  f.p.mathEraseAndVerify = async (actual) => {
    assert(actual.request_id === job.request_id && actual.lease_token === job.lease_token);
    f.calls.push("math");
  };
  assert((await dispatch(f.p)).processed === 1);
  assert(f.calls.indexOf("math") > f.calls.indexOf("storage"));
  assert(f.calls.indexOf("math") < f.calls.indexOf("auth"));
});
Deno.test("Math byte cleanup failure blocks Auth and retains retryable lifecycle", async () => {
  const f = fixture();
  f.p.mathEraseAndVerify = async () => { throw Error("private Math transport detail"); };
  assert((await dispatch(f.p)).retryable === 1);
  assert(!f.calls.includes("auth") && !f.calls.includes("account_deletion_finish"));
  assert(!JSON.stringify(f.retry()).includes("private Math transport detail"));
});
