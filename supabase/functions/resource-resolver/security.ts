import type { ResolverResponse } from "./contract.ts";
export const SOURCE_TIMEOUT_MS = 10_000;
export const SOURCE_MAX_BYTES = 1_000_000;
export const SOURCE_MAX_REDIRECTS = 0;
export const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

// Literal IPs are not required by this resolver. Reject all IPv6 (including
// normalized mapped IPv4) and all numeric IPv4, including public literals.
// This deliberately conservative primitive is not a DNS resolution guarantee.
export function isPrivateOrSpecialHost(value: string): boolean {
  try {
    const raw = value.replace(/^\[/, "").replace(/\]$/, "");
    const host = new URL(`https://${raw.includes(":") ? `[${raw}]` : raw}/`)
      .hostname.toLowerCase();
    return host.includes(":") || /^\d+\.\d+\.\d+\.\d+$/.test(host) ||
      host === "localhost" || host.endsWith(".localhost") ||
      host === "metadata.google.internal" || host === "metadata.google.com";
  } catch {
    return true;
  }
}
export function strictHttps(value: string): URL | null {
  try {
    if (/[\x00-\x20\\]/.test(value)) return null;
    const url = new URL(value);
    if (
      url.protocol !== "https:" || url.port || url.username || url.password ||
      url.hash || isPrivateOrSpecialHost(url.hostname)
    ) return null;
    return url;
  } catch {
    return null;
  }
}
export function canonicalSource(source: unknown, id: unknown): string | null {
  return source === "legendstudy" && typeof id === "string" &&
      /^[1-9][0-9]{0,11}$/.test(id)
    ? `https://legendstudy.com/${id}`
    : null;
}
export function trustedSourceUrl(value: string): URL | null {
  const url = strictHttps(value);
  return url && url.hostname === "legendstudy.com" && !url.search &&
      /^\/[1-9][0-9]{0,11}$/.test(url.pathname)
    ? url
    : null;
}
export function kakaoIdentity(value: string): string | null {
  const url = strictHttps(value);
  if (!url || url.hostname !== "blog.kakaocdn.net") return null;
  const parts = /^\/dna\/([A-Za-z0-9_-]+)\/([A-Za-z0-9_-]+)\//.exec(
    url.pathname,
  );
  return parts ? `${parts[1]}/${parts[2]}` : null;
}
export function trustedCurrentTarget(
  value: string,
  provider: string,
): URL | null {
  const url = strictHttps(value);
  return provider === "kakaocdn" && url && kakaoIdentity(value) && url.search &&
      ["credential", "signature", "expires"].every((k) =>
        url.searchParams.getAll(k).length === 1 && !!url.searchParams.get(k)
      ) && /^[0-9]{10,11}$/.test(url.searchParams.get("expires") ?? "") &&
      Number(url.searchParams.get("expires")) * 1000 > Date.now() + 5000
    ? url
    : null;
}
// No redirect destination, even same-host, is authorized by this observer.
export function isAllowedRedirect(_value: string): null {
  return null;
}

export async function readBoundedText(
  response: Response,
  maxBytes = SOURCE_MAX_BYTES,
  signal?: AbortSignal,
  onRejected: (reason: string) => void = () => {},
): Promise<string | null> {
  const reject = (reason: string) => {
    try {
      onRejected(reason);
    } catch { /* logging only */ }
  };
  const declared = response.headers.get("content-length");
  if (declared && Number(declared) > maxBytes) {
    reject("size");
    await response.body?.cancel();
    return null;
  }
  if (!response.body) {
    reject("empty");
    return null;
  }
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  let phase = "read_error";
  const cancel = () => {
    void reader.cancel().catch(() => {});
  };
  signal?.addEventListener("abort", cancel, { once: true });
  if (signal?.aborted) cancel();
  try {
    while (true) {
      const part = await reader.read();
      if (signal?.aborted) {
        reject("aborted");
        return null;
      }
      if (part.done) break;
      total += part.value.byteLength;
      if (total > maxBytes) {
        reject("size");
        await reader.cancel();
        return null;
      }
      chunks.push(part.value);
    }
    const bytes = new Uint8Array(total);
    let offset = 0;
    for (const c of chunks) {
      bytes.set(c, offset);
      offset += c.byteLength;
    }
    phase = "decode_error";
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    reject(phase);
    try {
      await reader.cancel();
    } catch { /* no raw errors */ }
    return null;
  } finally {
    signal?.removeEventListener("abort", cancel);
    reader.releaseLock();
  }
}
export function safeOperationalLog(
  resourceId: string,
  provider: string,
  result: ResolverResponse,
  durationMs: number,
) {
  return {
    event: "resource_resolver",
    resource_id: UUID.test(resourceId) ? resourceId : "invalid",
    provider: provider === "kakaocdn" ? "kakaocdn" : "unsupported",
    status: result.status,
    reason: result.status === "fallback" ? result.reason : undefined,
    duration_ms: Number.isFinite(durationMs)
      ? Math.max(0, Math.round(durationMs))
      : 0,
  };
}
