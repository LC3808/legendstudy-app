const TRUSTED_SOURCE_HOSTS = new Set([
  "legendstudy.com",
  "www.legendstudy.com",
]);
const TRUSTED_ATTACHMENT_HOSTS = new Set([
  "blog.kakaocdn.net",
  "t1.daumcdn.net",
  "app.box.com",
  "box.com",
  "drive.google.com",
  "docs.google.com",
]);
import type { ResolverResponse } from "./contract.ts";

export const SOURCE_TIMEOUT_MS = 10_000;
export const SOURCE_MAX_BYTES = 1_000_000;
export const SOURCE_MAX_REDIRECTS = 3;

export function isPrivateOrSpecialHost(hostname: string): boolean {
  const host = hostname.toLowerCase().replace(/^\[/, "").replace(/\]$/, "");
  if (
    host === "localhost" || host === "metadata.google.internal" ||
    host === "metadata.google.com" || host === "::1"
  ) return true;
  if (host.startsWith("127.") || host.startsWith("169.254.")) return true;
  if (host.includes(":")) {
    return host === "::1" || host.startsWith("fc") || host.startsWith("fd") ||
      host.startsWith("fe80:");
  }
  const octets = host.split(".").map(Number);
  if (octets.length !== 4 || octets.some((part) => !Number.isInteger(part))) {
    return false;
  }
  const [a, b] = octets;
  return a === 10 || a === 127 || a === 169 && b === 254 ||
    a === 172 && b >= 16 && b <= 31 || a === 192 && b === 168 ||
    a === 0;
}

function parsedHttpUrl(value: string): URL | null {
  try {
    const url = new URL(value);
    if (!(["http:", "https:"].includes(url.protocol))) return null;
    if (
      !url.hostname || url.username || url.password ||
      isPrivateOrSpecialHost(url.hostname)
    ) {
      return null;
    }
    return url;
  } catch (_) {
    return null;
  }
}

export function trustedSourceUrl(value: string): URL | null {
  const url = parsedHttpUrl(value);
  if (!url || !TRUSTED_SOURCE_HOSTS.has(url.hostname.toLowerCase())) {
    return null;
  }
  // Canonical source posts use the numeric LegendStudy path. This also keeps
  // the future resolver from becoming a general-purpose source proxy.
  if (url.search || url.hash || !/^\/\d+\/?$/.test(url.pathname)) return null;
  return url;
}

export function trustedCurrentTarget(
  value: string,
  provider: string,
): URL | null {
  const url = parsedHttpUrl(value);
  if (
    !url || !TRUSTED_ATTACHMENT_HOSTS.has(url.hostname.toLowerCase()) ||
    url.hash
  ) {
    return null;
  }
  if (provider === "kakaocdn" && !url.search) return null;
  return url;
}

export function isAllowedRedirect(value: string): URL | null {
  const url = parsedHttpUrl(value);
  if (!url) return null;
  return TRUSTED_SOURCE_HOSTS.has(url.hostname.toLowerCase()) ? url : null;
}

export async function readBoundedText(
  response: Response,
  maxBytes = SOURCE_MAX_BYTES,
): Promise<string | null> {
  const declared = response.headers.get("content-length");
  if (declared && Number(declared) > maxBytes) return null;
  if (!response.body) return null;
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    while (true) {
      const next = await reader.read();
      if (next.done) break;
      total += next.value.byteLength;
      if (total > maxBytes) {
        await reader.cancel();
        return null;
      }
      chunks.push(next.value);
    }
  } catch (_) {
    return null;
  }
  const merged = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    merged.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(merged);
}

export function safeOperationalLog(
  resourceId: string,
  provider: string,
  result: ResolverResponse,
  durationMs: number,
) {
  return {
    event: "resource_resolver",
    resource_id: resourceId,
    provider,
    status: result.status,
    reason: result.status === "fallback" ? result.reason : undefined,
    duration_ms: Math.max(0, Math.round(durationMs)),
  };
}
