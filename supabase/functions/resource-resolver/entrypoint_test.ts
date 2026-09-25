import { createEntrypoint, startResourceResolver } from "./index.ts";
import fixture from "./fixtures/kakao.json" with { type: "json" };

const id = "11111111-1111-4111-8111-111111111111";
const parent = "22222222-2222-4222-8222-222222222222";
const source = "33333333-3333-4333-8333-333333333333";
const credential = "offline-fixture-only";
const env = (name: string) =>
  ({
    SUPABASE_URL: "https://fixture.supabase.co",
    SUPABASE_SERVICE_ROLE_KEY: credential,
  })[name];
function assert(value: unknown) {
  if (!value) throw new Error("entrypoint contract failed");
}
const request = (headers?: HeadersInit) =>
  new Request("https://example.invalid", {
    method: "POST",
    headers,
    body: JSON.stringify({ resource_id: id }),
  });

Deno.test("entrypoint registers real B2 handler; Guest needs no Authorization; secret stays on DB", async () => {
  const original = globalThis.fetch;
  const calls: string[] = [];
  globalThis.fetch = (async (input, init) => {
    const url = new URL(String(input));
    const headers = new Headers(init?.headers);
    calls.push(url.pathname);
    if (url.host === "fixture.supabase.co") {
      assert(
        headers.get("apikey") === credential &&
          headers.get("authorization") === `Bearer ${credential}`,
      );
      if (url.pathname.endsWith("/consume_resource_resolver_quota")) {
        assert(
          init?.method === "POST" &&
            init.body === JSON.stringify({ p_resource_id: id }),
        );
        return Response.json(true);
      }
      assert(init?.method === "GET");
      const rows: Record<string, unknown> = {
        "/rest/v1/resources": {
          id,
          content_item_id: parent,
          source_post_id: source,
          is_active: true,
          source_resource_key: fixture.expected_key,
          source_url:
            "https://blog.kakaocdn.net/dna/cXNYPE/dJMcadW9IkW/AAAA/file.pdf",
          resource_type: "question",
        },
        "/rest/v1/content_items": {
          id: parent,
          source_post_id: source,
          is_active: true,
        },
        "/rest/v1/source_posts": {
          id: source,
          source: "legendstudy",
          external_post_id: "1705",
          source_status: "available",
        },
      };
      assert(rows[url.pathname]);
      return Response.json([rows[url.pathname]]);
    }
    assert(
      url.href === "https://legendstudy.com/1705" &&
        init?.redirect === "manual",
    );
    assert(
      !headers.has("authorization") && !headers.has("apikey") &&
        !headers.has("cookie"),
    );
    return new Response(fixture.html, {
      headers: { "content-type": "text/html" },
    });
  }) as typeof fetch;
  try {
    let handler: ReturnType<typeof createEntrypoint> | undefined;
    const keys: string[] = [];
    startResourceResolver((name) => {
      keys.push(name);
      return env(name);
    }, (value) => {
      handler = value;
    });
    assert(handler && calls.length === 0);
    assert(keys.join(",") === "SUPABASE_URL,SUPABASE_SERVICE_ROLE_KEY");
    for (
      const headers of [undefined, {
        authorization: "Bearer caller-not-authority",
        apikey: "caller-public-key",
      }]
    ) {
      calls.length = 0;
      const response = await handler!(request(headers));
      const text = await response.text();
      const body = JSON.parse(text);
      assert(
        body.status === "resolved" && body.kind === "pdf" &&
          body.resource_id === id,
      );
      assert(
        !text.includes(credential) &&
          response.headers.get("cache-control") === "no-store",
      );
      assert(
        calls.length === 5 &&
          calls[0].endsWith("/consume_resource_resolver_quota") &&
          calls[4] === "/1705",
      );
    }
  } finally {
    globalThis.fetch = original;
  }
});

Deno.test("real entrypoint quota deny/error fail closed before reads or HTML", async () => {
  const original = globalThis.fetch;
  try {
    for (const mode of ["denied", "error"]) {
      let calls = 0;
      globalThis.fetch = (async (input) => {
        calls++;
        assert(String(input).endsWith("/rpc/consume_resource_resolver_quota"));
        if (mode === "error") throw new Error(credential);
        return Response.json(false);
      }) as typeof fetch;
      const response = await createEntrypoint(env)(request());
      const text = await response.text();
      const body = JSON.parse(text);
      assert(
        calls === 1 && body.status === "fallback" && !text.includes(credential),
      );
      assert(
        body.reason ===
          (mode === "denied" ? "rate_limited" : "source_unavailable"),
      );
    }
  } finally {
    globalThis.fetch = original;
  }
});

Deno.test("missing/invalid environment returns safe fallback with no network; preflight and input guards remain", async () => {
  const original = globalThis.fetch;
  let calls = 0;
  globalThis.fetch = (() => {
    calls++;
    throw new Error("must not fetch");
  }) as typeof fetch;
  try {
    for (
      const read of [
        () => undefined,
        (name: string) => name === "SUPABASE_URL" ? undefined : credential,
        (name: string) =>
          name === "SUPABASE_URL" ? "https://fixture.supabase.co" : undefined,
        () => credential,
        () => {
          throw new Error(credential);
        },
      ]
    ) {
      const handler = createEntrypoint(read);
      const response = await handler(request());
      const text = await response.text();
      assert(
        JSON.parse(text).reason === "source_unavailable" &&
          !text.includes(credential),
      );
      const preflight = await handler(
        new Request("https://example.invalid", { method: "OPTIONS" }),
      );
      assert(
        preflight.status === 204 &&
          preflight.headers.get("access-control-allow-origin") === "*",
      );
    }
    const handler = createEntrypoint(env);
    assert(
      (await handler(
        new Request("https://example.invalid", {
          method: "POST",
          body: JSON.stringify({
            resource_id: id,
            url: "https://evil.invalid",
          }),
        }),
      )).status === 400,
    );
    assert(
      (await handler(new Request("https://example.invalid"))).status === 405,
    );
    assert(calls === 0);
  } finally {
    globalThis.fetch = original;
  }
});

Deno.test("checked-in function config explicitly permits Guests only for intended endpoint", async () => {
  const config = await Deno.readTextFile(
    new URL("../../config.toml", import.meta.url),
  );
  const section = /^\[functions\.resource-resolver\]\s*\n([^\[]*)/m.exec(config)
    ?.[1];
  assert(section && /^verify_jwt\s*=\s*false\s*$/m.test(section));
  assert(
    (config.match(/^\[functions\.resource-resolver\]/gm) ?? []).length === 1,
  );
  const source = await Deno.readTextFile(
    new URL("./index.ts", import.meta.url),
  );
  assert(
    source.includes("if (import.meta.main)") &&
      source.includes("Deno.serve(handler)"),
  );
});
