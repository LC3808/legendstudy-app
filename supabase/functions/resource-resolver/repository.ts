import type { CanonicalResource, ResourceRepository } from "./contract.ts";
import {
  canonicalSource,
  kakaoIdentity,
  readBoundedText,
  UUID,
} from "./security.ts";

type Row = Record<string, unknown>;
export interface ResolverDatabase {
  one(
    table: "resources" | "content_items" | "source_posts",
    id: string,
    columns: string,
  ): Promise<Row | null>;
  consumeQuota(resourceId: string): Promise<boolean>;
}
export class CanonicalRepository implements ResourceRepository {
  constructor(private readonly db: ResolverDatabase) {}
  async findById(id: string): Promise<CanonicalResource | null> {
    if (!UUID.test(id)) return null;
    const resource = await this.db.one(
      "resources",
      id,
      "id,content_item_id,source_post_id,source_resource_key,source_url,resource_type,mime_type,file_extension,is_active",
    );
    if (!resource || resource.id !== id) return null;
    const parentId = resource.content_item_id;
    const sourceId = resource.source_post_id;
    if (
      typeof parentId !== "string" || typeof sourceId !== "string" ||
      !UUID.test(parentId) || !UUID.test(sourceId)
    ) return null;
    const parent = await this.db.one(
      "content_items",
      parentId,
      "id,source_post_id,is_active",
    );
    if (!parent || parent.id !== parentId) return null;
    // Schema allows cross-post attachments, but this minimum release explicitly
    // declines them rather than guessing which post owns the current target.
    if (parent.source_post_id !== sourceId) return null;
    const source = await this.db.one(
      "source_posts",
      sourceId,
      "id,source,external_post_id,source_status",
    );
    if (
      !source || source.id !== sourceId || source.source_status !== "available"
    ) return null;
    const sourceUrl = canonicalSource(source.source, source.external_post_id);
    if (!sourceUrl) return null;
    const locator = typeof resource.source_url === "string"
      ? resource.source_url
      : "";
    const key = typeof resource.source_resource_key === "string"
      ? resource.source_resource_key
      : "";
    // Persisted unsigned provenance + exact stable key, never filename/order.
    let cleanLocator = false;
    try {
      const u = new URL(locator);
      cleanLocator = !u.search && !u.hash;
    } catch { /* fail closed */ }
    const provider = cleanLocator && key && kakaoIdentity(locator) === key
      ? "kakaocdn"
      : "unsupported";
    return {
      id,
      isActive: resource.is_active === true,
      parent: { isActive: parent.is_active === true, sourceUrl },
      provider,
      sourceResourceKey: key,
      resourceType: String(resource.resource_type ?? ""),
      mimeType: typeof resource.mime_type === "string"
        ? resource.mime_type
        : null,
      fileExtension: typeof resource.file_extension === "string"
        ? resource.file_extension
        : null,
    };
  }
}
// Server-only service credential. Reads are fixed-table SELECTs; the only write
// surface is the narrowly granted quota RPC, never content/resource mutation.
export class RestResolverDatabase implements ResolverDatabase {
  private readonly base: URL;
  constructor(
    url: string,
    private readonly serviceKey: string,
    private readonly fetcher: typeof fetch = fetch,
  ) {
    this.base = new URL(url);
    if (
      this.base.protocol !== "https:" || this.base.username ||
      this.base.password || this.base.port ||
      this.base.pathname !== "/" || this.base.search || this.base.hash ||
      !/^[a-z0-9]+\.supabase\.co$/.test(this.base.hostname) || !serviceKey
    ) throw new Error("invalid backend configuration");
  }
  private async call(
    path: string,
    method: "GET" | "POST",
    body?: string,
  ): Promise<unknown> {
    const signal = AbortSignal.timeout(3000);
    const response = await this.fetcher(new URL(path, this.base), {
      method,
      redirect: "error",
      signal,
      headers: {
        apikey: this.serviceKey,
        Authorization: `Bearer ${this.serviceKey}`,
        "Content-Type": "application/json",
      },
      body,
    });
    if (!response.ok) {
      await response.body?.cancel();
      throw new Error("backend unavailable");
    }
    const text = await readBoundedText(
      response,
      16000,
      signal,
    );
    if (text === null) throw new Error("backend unavailable");
    return JSON.parse(text);
  }
  async one(
    table: "resources" | "content_items" | "source_posts",
    id: string,
    columns: string,
  ): Promise<Row | null> {
    if (!UUID.test(id)) return null;
    const query = new URLSearchParams({
      select: columns,
      id: `eq.${id}`,
      limit: "2",
    });
    const result = await this.call(`/rest/v1/${table}?${query}`, "GET");
    if (
      !Array.isArray(result) || result.length !== 1 || !result[0] ||
      typeof result[0] !== "object"
    ) return null;
    return result[0];
  }
  async consumeQuota(resourceId: string): Promise<boolean> {
    return await this.call(
      "/rest/v1/rpc/consume_resource_resolver_quota",
      "POST",
      JSON.stringify({ p_resource_id: resourceId }),
    ) === true;
  }
}
