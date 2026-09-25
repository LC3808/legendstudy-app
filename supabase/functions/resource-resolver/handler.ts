import {
  createDiagnostic,
  type Diagnostic,
  type DiagnosticSink,
  noDiagnostic,
} from "./diagnostics.ts";
import {
  CanonicalResource,
  isPdfEvidence,
  ResolverFallback,
  ResolverRequest,
  ResolverResponse,
  ResolverSuccess,
  ResourceRepository,
  SourceAttachment,
  SourceObserver,
} from "./contract.ts";
import {
  kakaoIdentity,
  readBoundedText,
  trustedCurrentTarget,
  trustedSourceUrl,
} from "./security.ts";

const headers = {
  "Content-Type": "application/json; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "apikey, content-type, authorization, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
};

const reply = (status: number, body: ResolverResponse | { error: string }) =>
  new Response(JSON.stringify(body), { status, headers });

function fallback(reason: ResolverFallback["reason"]): ResolverFallback {
  return { status: "fallback", reason };
}

export function parseRequest(body: unknown): ResolverRequest | null {
  if (!body || typeof body !== "object" || Array.isArray(body)) return null;
  const keys = Object.keys(body as Record<string, unknown>);
  if (keys.length !== 1 || keys[0] !== "resource_id") return null;
  const resourceId = (body as Record<string, unknown>).resource_id;
  if (
    typeof resourceId !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(resourceId)
  ) {
    return null;
  }
  return { resource_id: resourceId };
}

export function matchAttachment(
  resource: Pick<CanonicalResource, "provider" | "sourceResourceKey">,
  attachments: SourceAttachment[],
): { attachment: SourceAttachment | null; ambiguous: boolean } {
  const matches = attachments.filter((attachment) =>
    attachment.provider === resource.provider &&
    attachment.sourceResourceKey === resource.sourceResourceKey
  );
  return {
    attachment: matches.length === 1 ? matches[0] : null,
    ambiguous: matches.length > 1,
  };
}

export async function resolveResource(
  request: ResolverRequest,
  repository: ResourceRepository,
  observer: SourceObserver,
  log: Diagnostic = noDiagnostic,
): Promise<ResolverResponse> {
  log("repository_start");
  let resource: CanonicalResource | null;
  try {
    resource = await repository.findById(request.resource_id);
  } catch (error) {
    log("repository_failed");
    throw error;
  }
  if (!resource) {
    log("repository_missing");
    return fallback("not_found");
  }
  log("repository_ok");
  if (!resource.isActive || !resource.parent.isActive) {
    return fallback("inactive");
  }
  if (!trustedSourceUrl(resource.parent.sourceUrl)) {
    return fallback("not_resolvable");
  }
  if (resource.provider !== "kakaocdn") return fallback("unsupported");
  let observation: Awaited<ReturnType<SourceObserver["observe"]>>;
  try {
    observation = await observer.observe(resource.parent.sourceUrl, log);
  } catch (_) {
    log("observer_failed", { reason: "exception" });
    return fallback("source_unavailable");
  }
  if (!observation) {
    log("observer_unavailable");
    return fallback("source_unavailable");
  }
  const matched = matchAttachment(resource, observation.attachments);
  if (matched.ambiguous) {
    log("match_ambiguous");
    return fallback("ambiguous");
  }
  const attachment = matched.attachment;
  if (!attachment || !attachment.currentTarget) {
    log("match_none");
    return fallback("not_resolvable");
  }
  if (!isPdfEvidence(resource, attachment)) return fallback("unsupported");
  const target = trustedCurrentTarget(
    attachment.currentTarget,
    resource.provider,
  );
  if (
    !target || kakaoIdentity(target.toString()) !== resource.sourceResourceKey
  ) return fallback("not_resolvable");
  const result: ResolverSuccess = {
    status: "resolved",
    resource_id: resource.id,
    kind: "pdf",
    target: target.toString(),
  };
  log("resolved");
  return result;
}

export function createHandler(
  repository: ResourceRepository,
  observer: SourceObserver,
  quota: { allow(resourceId: string): Promise<boolean> } = {
    allow: async () => false,
  },
  diagnosticSink?: DiagnosticSink,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") {
      return reply(405, { error: "method_not_allowed" });
    }
    let body: unknown;
    try {
      const text = await readBoundedText(
        new Response(request.body, { headers: request.headers }),
        256,
        AbortSignal.timeout(3000),
      );
      body = text === null ? null : JSON.parse(text);
    } catch (_) {
      return reply(400, { error: "invalid_request" });
    }
    const parsed = parseRequest(body);
    if (!parsed) return reply(400, { error: "invalid_request" });
    const log = createDiagnostic(diagnosticSink);
    let phase = "quota";
    log("quota_start");
    try {
      if (!await quota.allow(parsed.resource_id)) {
        log("quota_denied");
        return reply(200, fallback("rate_limited"));
      }
      log("quota_ok");
      phase = "resolver";
      const result = await resolveResource(parsed, repository, observer, log);
      return reply(200, result);
    } catch {
      log(phase === "quota" ? "quota_failed" : "resolver_failed");
      return reply(200, fallback("source_unavailable"));
    }
  };
}

export { createBoundedSourceObserver } from "./observer.ts";
