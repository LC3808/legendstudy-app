import type { DiagnosticSink } from "./diagnostics.ts";
import { createHandler } from "./handler.ts";
import { createBoundedSourceObserver } from "./observer.ts";
import { CanonicalRepository, RestResolverDatabase } from "./repository.ts";

// Wired by index.ts using platform-provided server environment. No secrets
// are read and no network requests run at module import or construction.
export function createProductionCandidate(
  url: string,
  serviceKey: string,
  diagnosticSink?: DiagnosticSink,
) {
  const db = new RestResolverDatabase(url, serviceKey);
  return createHandler(
    new CanonicalRepository(db),
    createBoundedSourceObserver(),
    {
      allow: (id) => db.consumeQuota(id),
    },
    diagnosticSink,
  );
}
