/** Offline contract for resolving a canonical resource to a current delivery target.
 *
 * This module deliberately has no Supabase client and no network access. The
 * future Edge Function will provide the repository and source observer.
 */

export const RESOLVER_FAILURES = [
  "not_found",
  "inactive",
  "not_resolvable",
  "source_unavailable",
  "ambiguous",
  "unsupported",
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
  observe(sourceUrl: string): Promise<SourceObservation | null>;
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
  const mime = [resource.mimeType, attachment.mimeType]
    .find((value) => value?.trim())?.trim().toLowerCase().split(";")[0];
  const extension = [resource.fileExtension, attachment.fileExtension]
    .find((value) => value?.trim())?.trim().toLowerCase().replace(/^\./, "");
  return mime === "application/pdf" || extension === "pdf";
}
