import { createProductionCandidate } from "./candidate.ts";
import { createHandler } from "./handler.ts";

type ReadEnvironment = (name: string) => string | undefined;

/** Guest endpoint; caller headers never become database credentials. */
export function createEntrypoint(readEnvironment: ReadEnvironment) {
  try {
    const url = readEnvironment("SUPABASE_URL");
    const serviceKey = readEnvironment("SUPABASE_SERVICE_ROLE_KEY");
    if (!url?.trim() || !serviceKey?.trim()) {
      throw new Error("configuration unavailable");
    }
    return createProductionCandidate(url, serviceKey);
  } catch {
    // Preserve safe CORS/method/input handling; no lookup/source fetch without
    // valid server configuration. Never return/log environment or raw errors.
    return createHandler(
      { findById: async () => null },
      { observe: async () => null },
      {
        allow: async () => {
          throw new Error("configuration unavailable");
        },
      },
    );
  }
}

export function startResourceResolver(
  readEnvironment: ReadEnvironment,
  serve: (handler: ReturnType<typeof createEntrypoint>) => void,
) {
  serve(createEntrypoint(readEnvironment));
}

// Importing in offline tests does not read secrets or start a listener.
if (import.meta.main) {
  startResourceResolver(
    (name) => Deno.env.get(name),
    (handler) => {
      Deno.serve(handler);
    },
  );
}
