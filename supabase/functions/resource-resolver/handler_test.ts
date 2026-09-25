import {
  createBoundedSourceObserver,
  createHandler,
  matchAttachment,
  parseRequest,
  resolveResource,
} from "./handler.ts";
import { ResourceRepository, SourceObserver } from "./contract.ts";
import {
  safeOperationalLog,
  trustedCurrentTarget,
  trustedSourceUrl,
} from "./security.ts";

const id = "11111111-1111-4111-8111-111111111111";
const parentUrl = "https://legendstudy.com/1705";
const resource = (overrides: Record<string, unknown> = {}) => ({
  id,
  isActive: true,
  parent: { isActive: true, sourceUrl: parentUrl },
  provider: "kakaocdn",
  sourceResourceKey: "s1/s2",
  resourceType: "question",
  mimeType: null,
  fileExtension: null,
  ...overrides,
});
const repo = (value: unknown): ResourceRepository => ({
  findById: async () => value as ReturnType<typeof resource> | null,
});
const observer = (attachments: unknown[]): SourceObserver => ({
  observe: async () => ({ attachments } as any),
});
const reasonOf = async (promise: ReturnType<typeof resolveResource>) => {
  const result = await promise;
  if (result.status !== "fallback") throw new Error("expected fallback");
  return result.reason;
};
const kakao = (overrides: Record<string, unknown> = {}) => ({
  provider: "kakaocdn",
  sourceResourceKey: "s1/s2",
  fileExtension: "pdf",
  currentTarget:
    "https://blog.kakaocdn.net/dna/s1/s2/file.pdf?credential=x&expires=1&signature=y",
  ...overrides,
});

Deno.test("client contract accepts only canonical resource_id", () => {
  if (
    !parseRequest({ resource_id: id }) ||
    parseRequest({ resource_id: id, url: parentUrl })
  ) throw new Error("contract");
  for (
    const body of [null, {}, { resource_id: "resource-1" }, {
      resource_id: id,
      host: "evil",
    }]
  ) {
    if (parseRequest(body) !== null) {
      throw new Error("arbitrary input accepted");
    }
  }
});

Deno.test("valid canonical Kakao PDF resolves without persisting target", async () => {
  const result = await resolveResource(
    { resource_id: id },
    repo(resource()),
    observer([kakao()]),
  );
  if (
    result.status !== "resolved" || result.kind !== "pdf" ||
    !result.target.includes("signature=y")
  ) throw new Error("not resolved");
});

Deno.test("unknown, inactive and invalid parent fail safely", async () => {
  if (
    await reasonOf(
      resolveResource({ resource_id: id }, repo(null), observer([])),
    ) !== "not_found"
  ) throw new Error("not found");
  if (
    await reasonOf(
      resolveResource(
        { resource_id: id },
        repo(resource({ isActive: false })),
        observer([]),
      ),
    ) !== "inactive"
  ) throw new Error("inactive");
  if (
    await reasonOf(
      resolveResource(
        { resource_id: id },
        repo(
          resource({
            parent: { isActive: true, sourceUrl: "https://evil.test/1705" },
          }),
        ),
        observer([]),
      ),
    ) !== "not_resolvable"
  ) throw new Error("parent");
});

Deno.test("identity matching uses provider and stable key, never filename or position", () => {
  const exact = matchAttachment({
    provider: "kakaocdn",
    sourceResourceKey: "s1/s2",
  }, [kakao({ displayName: "different.pdf" }) as any]);
  if (!exact.attachment || exact.ambiguous) throw new Error("identity");
  const wrongProvider = matchAttachment({
    provider: "kakaocdn",
    sourceResourceKey: "s1/s2",
  }, [kakao({ provider: "cfile" }) as any]);
  if (wrongProvider.attachment) throw new Error("provider");
  const ambiguous = matchAttachment({
    provider: "kakaocdn",
    sourceResourceKey: "s1/s2",
  }, [kakao() as any, kakao() as any]);
  if (!ambiguous.ambiguous) throw new Error("ambiguity");
});

Deno.test("no match, non-PDF and missing current target fall back", async () => {
  for (
    const attachment of [
      kakao({ sourceResourceKey: "other" }),
      kakao({ fileExtension: "zip" }),
      kakao({ currentTarget: null }),
    ]
  ) {
    const result = await resolveResource(
      { resource_id: id },
      repo(resource()),
      observer([attachment]),
    );
    if (result.status !== "fallback") throw new Error("unsafe success");
  }
});

Deno.test("signed target rotation is accepted only as a current response target", async () => {
  const result = await resolveResource(
    { resource_id: id },
    repo(resource()),
    observer([
      kakao({
        currentTarget:
          "https://blog.kakaocdn.net/dna/s1/s2/file.pdf?credential=new&expires=2&signature=new",
      }),
    ]),
  );
  if (
    result.status !== "resolved" || !result.target.includes("signature=new")
  ) throw new Error("rotation");
  const log = safeOperationalLog(id, "kakaocdn", result, 12.4);
  if (
    JSON.stringify(log).includes("signature") ||
    JSON.stringify(log).includes("credential")
  ) throw new Error("leak");
});

Deno.test("SSRF and unsafe scheme targets are rejected", () => {
  for (
    const value of [
      "http://127.0.0.1/1705",
      "http://localhost/1705",
      "http://169.254.169.254/latest/meta-data",
      "http://10.0.0.1/1705",
      "ftp://legendstudy.com/1705",
      "file:///etc/passwd",
      "javascript:alert(1)",
    ]
  ) {
    if (trustedSourceUrl(value)) throw new Error(`source accepted ${value}`);
  }
  if (
    trustedCurrentTarget("https://evil.test/file.pdf?signature=x", "kakaocdn")
  ) throw new Error("target host");
  if (trustedCurrentTarget("https://blog.kakaocdn.net/file.pdf", "kakaocdn")) {
    throw new Error("unsigned target");
  }
});

Deno.test("bounded observer rejects unsafe redirects, loops and oversized source", async () => {
  const response = (
    status: number,
    headers: Record<string, string>,
    body = "<html></html>",
  ) => new Response(body, { status, headers });
  const redirectToPrivate = createBoundedSourceObserver(
    (async () =>
      response(302, {
        location: "http://127.0.0.1/admin",
      })) as unknown as typeof fetch,
  );
  if (await redirectToPrivate.observe(parentUrl)) {
    throw new Error("private redirect");
  }
  const loop = createBoundedSourceObserver(
    (async () =>
      response(302, { location: parentUrl })) as unknown as typeof fetch,
  );
  if (await loop.observe(parentUrl)) throw new Error("redirect loop");
  const oversized = createBoundedSourceObserver(
    (async () =>
      response(200, {
        "content-type": "text/html",
        "content-length": "1000001",
      })) as unknown as typeof fetch,
  );
  if (await oversized.observe(parentUrl)) throw new Error("oversized");
  const notFound = createBoundedSourceObserver(
    (async () =>
      response(404, {
        "content-type": "text/html",
      })) as unknown as typeof fetch,
  );
  if (await notFound.observe(parentUrl)) throw new Error("404");
  const malformed = createBoundedSourceObserver(
    (async () =>
      response(200, {
        "content-type": "application/pdf",
      })) as unknown as typeof fetch,
  );
  if (await malformed.observe(parentUrl)) throw new Error("non-html source");
  const timeout = createBoundedSourceObserver(
    (async () => {
      throw new DOMException("timeout", "TimeoutError");
    }) as unknown as typeof fetch,
  );
  if (await timeout.observe(parentUrl)) throw new Error("timeout");
});

Deno.test("non-PDF and audio resources never resolve as PDF", async () => {
  for (const resourceType of ["other", "listening_audio"]) {
    const result = await resolveResource(
      { resource_id: id },
      repo(resource({ resourceType, fileExtension: "pdf" })),
      observer([kakao()]),
    );
    if (result.status !== "fallback" || result.reason !== "unsupported") {
      throw new Error("non-PDF resolved");
    }
  }
});

Deno.test("handler maps malformed input and never exposes network errors", async () => {
  const handler = createHandler(repo(resource()), {
    observe: async () => {
      throw new Error("raw signed target");
    },
  });
  const bad = await handler(
    new Request("https://example.invalid", {
      method: "POST",
      body: '{"url":"https://evil"}',
    }),
  );
  if (bad.status !== 400 || JSON.stringify(await bad.json()).includes("evil")) {
    throw new Error("bad input");
  }
  const failed = await handler(
    new Request("https://example.invalid", {
      method: "POST",
      body: JSON.stringify({ resource_id: id }),
    }),
  );
  if (
    failed.status !== 200 ||
    JSON.stringify(await failed.json()).includes("signed")
  ) throw new Error("raw error");
});
