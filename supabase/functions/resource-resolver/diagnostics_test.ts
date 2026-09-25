import { createDiagnostic, type DiagnosticSink } from "./diagnostics.ts";
import { createHandler } from "./handler.ts";
import { createBoundedSourceObserver } from "./observer.ts";
import { createEntrypoint } from "./index.ts";
import fixture from "./fixtures/kakao.json" with { type: "json" };
const id = "11111111-1111-4111-8111-111111111111";
const secret = "DO_NOT_LOG_CREDENTIAL_COOKIE_HTML";
const resource = {
  id,
  isActive: true,
  parent: { isActive: true, sourceUrl: "https://legendstudy.com/1709" },
  provider: "kakaocdn",
  sourceResourceKey: fixture.expected_key,
  resourceType: "question",
};
const repo = { findById: async () => resource };
const quota = { allow: async () => true };
const req = () =>
  new Request("https://example.invalid", {
    method: "POST",
    headers: { authorization: secret, cookie: secret },
    body: JSON.stringify({ resource_id: id }),
  });
function assert(v: unknown) {
  if (!v) throw new Error("diagnostic contract failed");
}
function capture() {
  const records: Readonly<Record<string, string | number>>[] = [];
  const sink: DiagnosticSink = (event) => records.push(event);
  const has = (stage: string, reason?: string) =>
    records.some((e) =>
      e.resolver_stage === stage && (!reason || e.reason === reason)
    );
  const safe = () => {
    const text = JSON.stringify(records);
    for (
      const forbidden of [
        secret,
        fixture.expected_key,
        "signature=",
        "credential=",
        "kakaocdn",
        "<html",
        "authorization",
        "cookie",
        id,
      ]
    ) assert(!text.includes(forbidden));
  };
  return { records, sink, has, safe };
}
Deno.test("diagnostics allowlist drops arbitrary fields/stages/reasons and ignores sink failure", () => {
  const c = capture();
  const log = createDiagnostic(c.sink);
  log(secret, { reason: secret });
  log(
    "observer_ok",
    {
      attachment_count: 1,
      reason: secret,
      status: NaN,
      target: secret,
    } as never,
  );
  assert(
    c.records.length === 1 && c.records[0].attachment_count === 1 &&
      !("reason" in c.records[0]) && !("target" in c.records[0]),
  );
  c.safe();
  createDiagnostic(() => {
    throw new Error(secret);
  })("resolved");
});
Deno.test("resolved stages correlate without identity and do not change response", async () => {
  const c = capture();
  const observer = createBoundedSourceObserver(
    (async () =>
      new Response(fixture.html, {
        headers: { "content-type": "text/html" },
      })) as typeof fetch,
  );
  const baseline = await createHandler(repo, observer, quota)(req());
  const logged = await createHandler(repo, observer, quota, c.sink)(req());
  assert(await baseline.text() === await logged.text());
  for (
    const stage of [
      "quota_ok",
      "repository_ok",
      "source_fetch_start",
      "observer_ok",
      "resolved",
    ]
  ) assert(c.has(stage));
  assert(new Set(c.records.map((x) => x.trace_id)).size === 1);
  c.safe();
  const broken = await createHandler(repo, observer, quota, () => {
    throw new Error(secret);
  })(req());
  assert((await broken.json()).status === "resolved");
});
Deno.test("config, quota and repository exceptions are distinct and keep bounded fallback", async () => {
  const c = capture();
  let response = await createEntrypoint(() => {
    throw new Error(secret);
  }, c.sink)(req());
  assert(
    (await response.json()).reason === "source_unavailable" &&
      c.has("config_failed") && c.has("quota_failed"),
  );
  c.records.length = 0;
  response = await createHandler(
    {
      findById: async () => {
        throw new Error(secret);
      },
    },
    { observe: async () => null },
    quota,
    c.sink,
  )(req());
  assert(
    (await response.json()).reason === "source_unavailable" &&
      c.has("repository_failed") && !c.has("source_fetch_start"),
  );
  c.safe();
});
Deno.test("fetch status/type/body/parser rejection logs safe categories with unchanged fallback", async () => {
  const cases: Array<[() => Response, string, string?]> = [
    [
      () =>
        new Response(secret, {
          status: 302,
          headers: { location: "https://example.invalid/" + secret },
        }),
      "source_http_rejected",
    ],
    [
      () => new Response(secret, { headers: { "content-type": secret } }),
      "source_body_rejected",
      "type",
    ],
    [
      () =>
        new Response(secret, {
          headers: { "content-type": "text/html", "content-length": "1000001" },
        }),
      "source_body_rejected",
      "size",
    ],
    [
      () =>
        new Response("x".repeat(1000001), {
          headers: { "content-type": "text/html" },
        }),
      "source_body_rejected",
      "size",
    ],
    [
      () =>
        new Response(new Uint8Array([255]), {
          headers: { "content-type": "text/html" },
        }),
      "source_body_rejected",
      "decode_error",
    ],
    [
      () => new Response(null, { headers: { "content-type": "text/html" } }),
      "source_body_rejected",
      "empty",
    ],
    [
      () =>
        new Response(
          new ReadableStream({
            start(c) {
              c.error(new Error(secret));
            },
          }),
          { headers: { "content-type": "text/html" } },
        ),
      "source_body_rejected",
      "read_error",
    ],
    [
      () =>
        new Response('<div class="contents_style"><script>' + secret, {
          headers: { "content-type": "text/html" },
        }),
      "observer_failed",
      "raw_text",
    ],
    [
      () =>
        new Response(
          '<div class="contents_style"><a href="x" href="y">a</a></div>',
          { headers: { "content-type": "text/html" } },
        ),
      "observer_failed",
      "duplicate_attribute",
    ],
    [
      () =>
        new Response("<html>" + secret + "</html>", {
          headers: { "content-type": "text/html" },
        }),
      "observer_failed",
      "missing_article",
    ],
  ];
  for (const [make, stage, reason] of cases) {
    const c = capture();
    const observer = createBoundedSourceObserver(
      (async () => make()) as typeof fetch,
    );
    const response = await createHandler(repo, observer, quota, c.sink)(req());
    assert(
      JSON.stringify(await response.json()) ===
        JSON.stringify({ status: "fallback", reason: "source_unavailable" }),
    );
    assert(c.has(stage, reason));
    c.safe();
  }
});
Deno.test("fetch exception and deadline emit bounded diagnostic, never exception content", async () => {
  for (
    const fetcher of [
      (async () => {
        throw new Error(secret);
      }) as typeof fetch,
      (() => new Promise(() => {})) as typeof fetch,
    ]
  ) {
    const c = capture();
    const observer = createBoundedSourceObserver(fetcher, 5);
    const response = await createHandler(repo, observer, quota, c.sink)(req());
    assert((await response.json()).reason === "source_unavailable");
    assert(c.has("source_fetch_failed") || c.has("source_timeout", "fetch"));
    c.safe();
  }
});
Deno.test("match none/ambiguous remain distinct from source_unavailable", async () => {
  for (const duplicate of [false, true]) {
    const c = capture();
    const html = duplicate
      ? fixture.html + fixture.html
      : '<div class="contents_style"></div>';
    const observer = createBoundedSourceObserver(
      (async () =>
        new Response(html, {
          headers: { "content-type": "text/html" },
        })) as typeof fetch,
    );
    const response = await createHandler(repo, observer, quota, c.sink)(req());
    assert(
      (await response.json()).reason ===
        (duplicate ? "ambiguous" : "not_resolvable"),
    );
    assert(c.has(duplicate ? "match_ambiguous" : "match_none"));
    c.safe();
  }
});
