import fixture from "./fixtures/kakao.json" with { type: "json" };
import { createBoundedSourceObserver, observeHtml } from "./observer.ts";
import {
  canonicalSource,
  isPrivateOrSpecialHost,
  readBoundedText,
  trustedSourceUrl,
} from "./security.ts";
import {
  CanonicalRepository,
  type ResolverDatabase,
  RestResolverDatabase,
} from "./repository.ts";
import { createHandler, resolveResource } from "./handler.ts";
const id = "11111111-1111-4111-8111-111111111111";
const parent = "22222222-2222-4222-8222-222222222222";
const source = "33333333-3333-4333-8333-333333333333";
function eq(a: unknown, b: unknown) {
  if (JSON.stringify(a) !== JSON.stringify(b)) {
    throw new Error("contract mismatch");
  }
}
const rows = () => ({
  resources: {
    id,
    content_item_id: parent,
    source_post_id: source,
    source_resource_key: fixture.expected_key,
    source_url:
      "https://blog.kakaocdn.net/dna/cXNYPE/dJMcadW9IkW/AAAA/file.pdf",
    resource_type: "question",
    is_active: true,
  },
  content_items: { id: parent, source_post_id: source, is_active: true },
  source_posts: {
    id: source,
    source: "legendstudy",
    external_post_id: "1705",
    source_status: "available",
  },
});
function repository(values: ReturnType<typeof rows>) {
  return new CanonicalRepository({
    one: async (table) => values[table],
    consumeQuota: async () => true,
  });
}
Deno.test("Gate A/C canonical numeric relationship and unsigned provider evidence", async () => {
  const r = await repository(rows()).findById(id);
  eq(r?.parent.sourceUrl, "https://legendstudy.com/1705");
  eq(r?.provider, fixture.expected_provider);
  eq(r?.sourceResourceKey, fixture.expected_key);
  for (
    const invalid of [
      "0",
      "01705",
      "../1705",
      "https://evil.test",
      "1705?x=1",
      1705,
      "1705/",
      "1705\n",
    ]
  ) eq(canonicalSource("legendstudy", invalid), null);
  eq(canonicalSource("other", "1705"), null);
  let v = rows();
  v.content_items.source_post_id = parent;
  eq(await repository(v).findById(id), null);
  v = rows();
  v.resources.source_resource_key = "wrong/key";
  eq((await repository(v).findById(id))?.provider, "unsupported");
  v = rows();
  v.resources.source_url += "?signature=fixture";
  eq((await repository(v).findById(id))?.provider, "unsupported");
  v = rows();
  v.source_posts.source_status = "missing";
  eq(await repository(v).findById(id), null);
});
Deno.test("inactive resource and parent never observe source", async () => {
  for (const target of ["resources", "content_items"] as const) {
    const v = rows();
    v[target].is_active = false;
    const result = await resolveResource({ resource_id: id }, repository(v), {
      observe: () => {
        throw new Error("must not fetch");
      },
    });
    eq(result, { status: "fallback", reason: "inactive" });
  }
});
Deno.test("fixture identity and signature rotation parity; PDF label from nested span", () => {
  for (
    const html of [
      fixture.html,
      fixture.html.replace("signature=xyz%3D", "signature=rotated"),
    ]
  ) {
    const found = observeHtml(html)?.attachments;
    eq(found?.length, 1);
    eq(found?.[0].provider, fixture.expected_provider);
    eq(found?.[0].sourceResourceKey, fixture.expected_key);
    eq(found?.[0].fileExtension, "pdf");
  }
});
Deno.test("full read-only lookup / source / matching / response flow and ambiguity", async () => {
  const observer = { observe: async () => observeHtml(fixture.html) };
  const ok = await resolveResource(
    { resource_id: id },
    repository(rows()),
    observer,
  );
  eq(ok.status, "resolved");
  const duplicate = {
    observe: async () => ({
      attachments: [
        ...observeHtml(fixture.html)!.attachments,
        ...observeHtml(fixture.html)!.attachments,
      ],
    }),
  };
  eq(
    await resolveResource({ resource_id: id }, repository(rows()), duplicate),
    { status: "fallback", reason: "ambiguous" },
  );
  eq(
    await resolveResource({ resource_id: id }, repository(rows()), {
      observe: async () => ({ attachments: [] }),
    }),
    { status: "fallback", reason: "not_resolvable" },
  );
});
Deno.test("IP normalization and source host/scheme adversarial matrix", () => {
  for (
    const host of [
      "127.0.0.1",
      "127.2.3.4",
      "2130706433",
      "0x7f000001",
      "0177.0.0.1",
      "127.1",
      "0.0.0.0",
      "10.0.0.1",
      "172.16.0.1",
      "192.168.1.1",
      "169.254.169.254",
      "localhost",
      "metadata.google.internal",
      "::1",
      "::ffff:127.0.0.1",
      "::ffff:7f00:1",
      "fc00::1",
      "fe80::1",
    ]
  ) eq(isPrivateOrSpecialHost(host), true);
  for (
    const url of [
      "http://legendstudy.com/1705",
      "https://evil.legendstudy.com/1705",
      "https://legendstudy.com.evil.com/1705",
      "https://legendstudy.com:8443/1705",
      "https://user@legendstudy.com/1705",
      "https://legendstudy.com/1705?q=x",
    ]
  ) eq(trustedSourceUrl(url), null);
});
Deno.test("all redirects including same host and downgrade are rejected after one request", async () => {
  for (
    const location of [
      "https://legendstudy.com/1706",
      "http://legendstudy.com/1705",
      "https://127.0.0.1/",
      "https://evil.test/",
      "https://169.254.169.254/",
    ]
  ) {
    let calls = 0;
    const observer = createBoundedSourceObserver(
      (async (_u, init) => {
        calls++;
        eq(init?.redirect, "manual");
        return new Response(null, { status: 302, headers: { location } });
      }) as typeof fetch,
    );
    eq(await observer.observe("https://legendstudy.com/1705"), null);
    eq(calls, 1);
  }
});
Deno.test("actual streamed body limit overrides absent and dishonest content length", async () => {
  for (
    const headers of [new Headers(), new Headers({ "content-length": "1" })]
  ) {
    const body = new Uint8Array(1000001);
    eq(await readBoundedText(new Response(body, { headers })), null);
  }
});
Deno.test("gzip decoded stream is bounded, not compressed length", async () => {
  const bytes = new TextEncoder().encode("x".repeat(1000001));
  const compressed = new Response(bytes).body!.pipeThrough(
    new CompressionStream("gzip"),
  );
  const decoded = compressed.pipeThrough(new DecompressionStream("gzip"));
  eq(
    await readBoundedText(
      new Response(decoded, {
        headers: { "content-length": "1000", "content-encoding": "gzip" },
      }),
    ),
    null,
  );
});
Deno.test("timeouts cover pending fetch and body; HTML errors fail closed", async () => {
  const pending = createBoundedSourceObserver(
    (() => new Promise(() => {})) as typeof fetch,
    5,
  );
  eq(await pending.observe("https://legendstudy.com/1705"), null);
  const stream = createBoundedSourceObserver(
    (async () =>
      new Response(new ReadableStream({ start() {} }), {
        headers: { "content-type": "text/html" },
      })) as typeof fetch,
    5,
  );
  eq(await stream.observe("https://legendstudy.com/1705"), null);
  eq(observeHtml("<html>broken"), null);
  eq(observeHtml('<div class="contents_style"><a href="x">broken'), null);
});
Deno.test("quota is mandatory, before lookup/fetch, unavailable quota fails closed", async () => {
  const forbidden = {
    findById: async () => {
      throw new Error("should not reach lookup");
    },
  };
  for (
    const quota of [{ allow: async () => false }, {
      allow: async () => {
        throw new Error("private backend error");
      },
    }]
  ) {
    const handler = createHandler(
      forbidden,
      { observe: async () => null },
      quota,
    );
    const response = await handler(
      new Request("https://example.invalid", {
        method: "POST",
        body: JSON.stringify({ resource_id: id }),
      }),
    );
    eq(response.headers.get("cache-control"), "no-store");
    const b = await response.json();
    eq(b.status, "fallback");
    if (!["rate_limited", "source_unavailable"].includes(b.reason)) {
      throw new Error("unsafe error");
    }
  }
});
Deno.test("production adapter fixed reads plus quota RPC; service credential stays on configured DB", async () => {
  const calls: string[] = [];
  const db = new RestResolverDatabase(
    "https://fixture.supabase.co",
    "fixture-only-not-a-secret",
    (async (u, init) => {
      const url = new URL(String(u));
      eq(url.host, "fixture.supabase.co");
      eq(init?.redirect, "error");
      calls.push(init!.method!);
      return new Response(
        url.pathname.includes("/rpc/") ? "true" : '[{"id":"fixture"}]',
      );
    }) as typeof fetch,
  );
  await db.one("resources", id, "id");
  eq(await db.consumeQuota(id), true);
  eq(calls, ["GET", "POST"]);
});

Deno.test("allowed quota yields no-store resolved response; no source credentials forwarded", async () => {
  const observer = createBoundedSourceObserver(
    (async (url, init) => {
      eq(String(url), "https://legendstudy.com/1705");
      const h = new Headers(init?.headers);
      eq(h.has("authorization"), false);
      eq(h.has("cookie"), false);
      return new Response(fixture.html, {
        headers: { "content-type": "text/html" },
      });
    }) as typeof fetch,
  );
  const handler = createHandler(repository(rows()), observer, {
    allow: async (value) => {
      eq(value, id);
      return true;
    },
  });
  const response = await handler(
    new Request("https://example.invalid", {
      method: "POST",
      body: JSON.stringify({ resource_id: id }),
    }),
  );
  eq((await response.json()).status, "resolved");
  eq(response.headers.get("cache-control"), "no-store");
});
Deno.test("expired target and contradictory MIME decline; script-only attachment excluded", async () => {
  const expired = fixture.html.replace("expires=4102444800", "expires=1");
  eq(
    (await resolveResource({ resource_id: id }, repository(rows()), {
      observe: async () => observeHtml(expired),
    })).status,
    "fallback",
  );
  const audio = fixture.html.replaceAll(
    "<a href=",
    '<a type="audio/mpeg" href=',
  );
  eq(
    (await resolveResource({ resource_id: id }, repository(rows()), {
      observe: async () => observeHtml(audio),
    })).status,
    "fallback",
  );
  eq(observeHtml('<div class="contents_style"><script>' + fixture.html), null);
});
