import type { Diagnostic } from "./diagnostics.ts";
/** Offline contract for resolving a canonical resource to a current delivery target.
 *
 * This module deliberately has no Supabase client and no network access. The
 * candidate factory supplies repository/observer/quota; index stays disabled.
 */

export const RESOLVER_FAILURES = [
  "not_found",
  "inactive",
  "not_resolvable",
  "source_unavailable",
  "ambiguous",
  "unsupported",
  "rate_limited",
] as const;
export type ResolverFailure = typeof RESOLVER_FAILURES[number];

export type ResolverRequest = { resource_id: string };

export type CanonicalResource = {
  id: string;
  isActive: boolean;
  parent: {
    isActive: boolean;
    sourceUrl: string;
  };
  provider: string;
  sourceResourceKey: string;
  resourceType: string;
  mimeType?: string | null;
  fileExtension?: string | null;
};

export type SourceAttachment = {
  provider: string;
  sourceResourceKey: string;
  mimeType?: string | null;
  fileExtension?: string | null;
  currentTarget?: string | null;
};

export type SourceObservation = {
  attachments: SourceAttachment[];
};

export type ResolverSuccess = {
  status: "resolved";
  resource_id: string;
  kind: "pdf";
  target: string;
};

export type ResolverFallback = {
  status: "fallback";
  reason: ResolverFailure;
};

export type ResolverResponse = ResolverSuccess | ResolverFallback;

export interface ResourceRepository {
  findById(resourceId: string): Promise<CanonicalResource | null>;
}

export interface SourceObserver {
  observe(
    sourceUrl: string,
    diagnostic?: Diagnostic,
  ): Promise<SourceObservation | null>;
}

export const PDF_RESOURCE_TYPES = new Set([
  "question",
  "answer",
  "explanation",
  "answer_explanation",
]);

export function isPdfEvidence(
  resource: Pick<
    CanonicalResource,
    "resourceType" | "mimeType" | "fileExtension"
  >,
  attachment: Pick<SourceAttachment, "mimeType" | "fileExtension">,
): boolean {
  if (!PDF_RESOURCE_TYPES.has(resource.resourceType)) return false;
  const mimes = [resource.mimeType, attachment.mimeType].filter(Boolean)
    .map((v) => v!.trim().toLowerCase().split(";")[0]);
  const extensions = [resource.fileExtension, attachment.fileExtension].filter(
    Boolean,
  )
    .map((v) => v!.trim().toLowerCase().replace(/^\./, ""));
  if (
    mimes.some((v) =>
      v !== "application/pdf" && v !== "application/octet-stream"
    ) || extensions.some((v) => v !== "pdf")
  ) return false;
  // Current attachment metadata must independently provide PDF evidence.
  return attachment.mimeType?.split(";")[0].trim().toLowerCase() ===
      "application/pdf" || attachment.fileExtension === "pdf";
}
