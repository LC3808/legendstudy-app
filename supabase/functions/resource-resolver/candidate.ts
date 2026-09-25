import { createHandler } from "./handler.ts";
import { createBoundedSourceObserver } from "./observer.ts";
import { CanonicalRepository, RestResolverDatabase } from "./repository.ts";

// Deliberately NOT called by index.ts. Review, migration and deployment are
// separate Owner steps. No environmental secrets are read at module import.
export function createProductionCandidate(url: string, serviceKey: string) {
  const db = new RestResolverDatabase(url, serviceKey);
  return createHandler(
    new CanonicalRepository(db),
    createBoundedSourceObserver(),
    {
      allow: (id) => db.consumeQuota(id),
    },
  );
}
