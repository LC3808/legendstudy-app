// Closed vocabulary: never serialize inputs, exceptions, headers or URLs.
const stages = new Set([
  "config_failed",
  "quota_start",
  "quota_ok",
  "quota_denied",
  "quota_failed",
  "repository_start",
  "repository_ok",
  "repository_missing",
  "repository_failed",
  "source_fetch_start",
  "source_fetch_failed",
  "source_http_rejected",
  "source_body_rejected",
  "source_timeout",
  "source_boundary_rejected",
  "observer_failed",
  "observer_ok",
  "observer_unavailable",
  "match_none",
  "match_ambiguous",
  "resolved",
  "resolver_failed",
]);
const reasons = new Set([
  "size",
  "empty",
  "aborted",
  "read_error",
  "decode_error",
  "type",
  "exception",
  "fetch",
  "body",
  "parser",
  "raw_text",
  "duplicate_attribute",
  "nested_anchor",
  "parser_limit",
  "missing_article",
  "unclosed_anchor",
]);
export type Diagnostic = (
  stage: string,
  fields?: { reason?: string; status?: number; attachment_count?: number },
) => void;
export type DiagnosticSink = (
  event: Readonly<Record<string, string | number>>,
) => void;
export const noDiagnostic: Diagnostic = () => {};
export const consoleDiagnostic: DiagnosticSink = (event) =>
  console.info(JSON.stringify(event));
export function createDiagnostic(sink?: DiagnosticSink): Diagnostic {
  if (!sink) return noDiagnostic;
  // Correlates concurrent requests without any resource/user identifier.
  let trace: string;
  try {
    trace = crypto.randomUUID();
  } catch {
    return noDiagnostic;
  }
  return (stage, fields) => {
    try {
      if (!stages.has(stage)) return;
      const event: Record<string, string | number> = {
        event: "resource_resolver",
        trace_id: trace,
        resolver_stage: stage,
      };
      if (fields?.reason && reasons.has(fields.reason)) {
        event.reason = fields.reason;
      }
      if (
        Number.isInteger(fields?.status) && fields!.status! >= 100 &&
        fields!.status! <= 599
      ) event.status = fields!.status!;
      if (
        Number.isInteger(fields?.attachment_count) &&
        fields!.attachment_count! >= 0 && fields!.attachment_count! <= 1001
      ) event.attachment_count = fields!.attachment_count!;
      sink(event);
    } catch {
      /* Diagnostics must never alter delivery or fallback behavior. */
    }
  };
}
