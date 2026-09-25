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
  isAllowedRedirect,
  readBoundedText,
  SOURCE_MAX_REDIRECTS,
  SOURCE_TIMEOUT_MS,
  trustedCurrentTarget,
  trustedSourceUrl,
} from "./security.ts";

const headers = {
  "Content-Type": "application/json; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "apikey, content-type",
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
): Promise<ResolverResponse> {
  const resource = await repository.findById(request.resource_id);
  if (!resource) return fallback("not_found");
  if (!resource.isActive || !resource.parent.isActive) {
    return fallback("inactive");
  }
  if (!trustedSourceUrl(resource.parent.sourceUrl)) {
    return fallback("not_resolvable");
  }
  let observation: Awaited<ReturnType<SourceObserver["observe"]>>;
  try {
    observation = await observer.observe(resource.parent.sourceUrl);
  } catch (_) {
    return fallback("source_unavailable");
  }
  if (!observation) return fallback("source_unavailable");
  const matched = matchAttachment(resource, observation.attachments);
  if (matched.ambiguous) return fallback("ambiguous");
  const attachment = matched.attachment;
  if (!attachment || !attachment.currentTarget) {
    return fallback("not_resolvable");
  }
  if (!isPdfEvidence(resource, attachment)) return fallback("unsupported");
  const target = trustedCurrentTarget(
    attachment.currentTarget,
    resource.provider,
  );
  if (!target) return fallback("not_resolvable");
  const result: ResolverSuccess = {
    status: "resolved",
    resource_id: resource.id,
    kind: "pdf",
    target: target.toString(),
  };
  return result;
}

export function createHandler(
  repository: ResourceRepository,
  observer: SourceObserver,
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
      body = await request.json();
    } catch (_) {
      return reply(400, { error: "invalid_request" });
    }
    const parsed = parseRequest(body);
    if (!parsed) return reply(400, { error: "invalid_request" });
    const result = await resolveResource(parsed, repository, observer);
    return reply(result.status === "resolved" ? 200 : 200, result);
  };
}

export function createBoundedSourceObserver(
  fetcher: typeof fetch = fetch,
): SourceObserver {
  return {
    async observe(sourceUrl: string) {
      let target = trustedSourceUrl(sourceUrl);
      if (!target) return null;
      for (let hop = 0; hop <= SOURCE_MAX_REDIRECTS; hop++) {
        let response: Response;
        try {
          response = await fetcher(target, {
            method: "GET",
            redirect: "manual",
            signal: AbortSignal.timeout(SOURCE_TIMEOUT_MS),
          });
        } catch (_) {
          return null;
        }
        if (response.status >= 300 && response.status < 400) {
          if (hop === SOURCE_MAX_REDIRECTS) return null;
          const location: string | null = response.headers.get("location");
          target = location
            ? isAllowedRedirect(new URL(location, target).toString())
            : null;
          if (!target) return null;
          continue;
        }
        if (!response.ok) return null;
        const contentType =
          response.headers.get("content-type")?.toLowerCase() ?? "";
        if (
          contentType && !contentType.includes("text/html") &&
          !contentType.includes("application/xhtml+xml")
        ) {
          return null;
        }
        // The HTML parser is intentionally injected later. This bounded
        // observer proves transport policy without duplicating Python parser
        // behavior in B1.
        if (await readBoundedText(response) === null) return null;
        return { attachments: [] };
      }
      return null;
    },
  };
}
