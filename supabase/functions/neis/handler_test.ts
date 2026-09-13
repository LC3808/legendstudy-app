import { createHandler } from "./handler.ts";
function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error("Assertion failed");
  }
}
const row = {
  ATPT_OFCDC_SC_CODE: "J10",
  SD_SCHUL_CODE: "7530932",
  SCHUL_NM: "테스트학교",
  SCHUL_KND_SC_NM: "고등학교",
  ORG_RDNMA: "테스트 주소",
};
const envelope = (endpoint: string, rows: unknown[]) => ({
  [endpoint]: [{ head: [{ RESULT: { CODE: "INFO-000" } }] }, { row: rows }],
});
const req = (query: string) =>
  new Request(`https://example.invalid/neis?${query}`);
const response = (body: unknown) =>
  Promise.resolve(new Response(JSON.stringify(body)));
Deno.test("only allowlisted school search is forwarded, credentials stay upstream", async () => {
  const handler = createHandler(
    () => "test-only-key",
    ((input: string | URL | Request, init?: RequestInit) => {
      const url = new URL(String(input));
      equal(url.origin, "https://open.neis.go.kr");
      equal(url.pathname, "/hub/schoolInfo");
      equal(url.searchParams.get("KEY"), "test-only-key");
      equal(url.searchParams.get("SCHUL_NM"), "테스트");
      equal(url.searchParams.get("pSize"), "100");
      equal(init?.redirect, "error");
      return response(envelope("schoolInfo", [{ ...row, PRIVATE: "omitted" }]));
    }) as typeof fetch,
  );
  const result = await handler(req("action=search&q=테스트"));
  equal(result.status, 200);
  equal(await result.json(), { rows: [row] });
});
Deno.test("unknown endpoint, arbitrary URLs, paging, duplicates and invalid codes denied before fetch", async () => {
  const handler = createHandler(
    () => "test-only-key",
    (() => {
      throw new Error("must not fetch");
    }) as typeof fetch,
  );
  for (
    const query of [
      "action=unknown",
      "action=search&q=a&url=https://evil.invalid",
      "action=search&q=a&pIndex=2",
      "action=search&q=a&q=b",
      "action=school&office=J10",
      "action=school&office=%20J10&school=7530932",
      "action=search&q=",
    ]
  ) {
    equal((await handler(req(query))).status, 400);
  }
});
Deno.test("invalid calendar date denied", async () => {
  const handler = createHandler(() => "test-only-key");
  for (const date of ["20260230", "20261301", "2026-09-13"]) {
    equal(
      (await handler(
        req(`action=meals&office=J10&school=7530932&date=${date}`),
      )).status,
      400,
    );
  }
});
Deno.test("meal date filters and projection", async () => {
  const meal = {
    ATPT_OFCDC_SC_CODE: "J10",
    SD_SCHUL_CODE: "7530932",
    MMEAL_SC_NM: "중식",
    MLSV_YMD: "20260911",
    DDISH_NM: "쌀밥<br/>국 (1.2)",
  };
  const handler = createHandler(
    () => "test-only-key",
    ((input: string | URL | Request) => {
      const url = new URL(String(input));
      equal(url.pathname, "/hub/mealServiceDietInfo");
      equal(url.searchParams.get("MLSV_YMD"), "20260911");
      return response(envelope("mealServiceDietInfo", [meal]));
    }) as typeof fetch,
  );
  equal(
    await (await handler(
      req("action=meals&office=J10&school=7530932&date=20260911"),
    )).json(),
    { rows: [meal] },
  );
});
Deno.test("INFO-200 is normal empty", async () => {
  const handler = createHandler(
    () => "test-only-key",
    (() => response({ RESULT: { CODE: "INFO-200" } })) as typeof fetch,
  );
  equal(await (await handler(req("action=search&q=없음"))).json(), {
    rows: [],
  });
});
Deno.test("upstream errors and malformed data never masquerade as empty", async () => {
  for (
    const body of [
      { RESULT: { CODE: "ERROR-290", MESSAGE: "sensitive-upstream-detail" } },
      {},
      envelope("schoolInfo", [null]),
      envelope("schoolInfo", [{ ...row, SCHUL_NM: 42 }]),
    ]
  ) {
    const handler = createHandler(
      () => "test-only-key",
      (() => response(body)) as typeof fetch,
    );
    const result = await handler(req("action=search&q=a"));
    equal(result.status, 502);
    equal(await result.json(), { error: "upstream_unavailable" });
  }
});
Deno.test("timeout/network failure is sanitized", async () => {
  const handler = createHandler(
    () => "test-only-key",
    (() => {
      throw new Error("URL-with-secret");
    }) as typeof fetch,
  );
  const result = await handler(req("action=search&q=a"));
  equal(result.status, 502);
  equal(await result.json(), { error: "upstream_unavailable" });
});
Deno.test("missing server key fails closed with no sample fallback", async () => {
  equal(
    (await createHandler(() => undefined)(req("action=search&q=a"))).status,
    503,
  );
});
Deno.test("guest GET and CORS supported; writes rejected", async () => {
  const handler = createHandler(() => undefined);
  equal(
    (await handler(
      new Request("https://example.invalid", { method: "OPTIONS" }),
    )).status,
    204,
  );
  equal(
    (await handler(new Request("https://example.invalid", { method: "POST" })))
      .status,
    405,
  );
});
