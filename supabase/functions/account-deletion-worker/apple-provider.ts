/** Worker provider-revoke adapter for Apple. Plugs the deletion worker's
 * `providerEraseAndVerify` port into the existing `revokeAppleToken` transport using a
 * provenance-bound refresh token read (lease-fenced) from account_private. Returns false
 * on any missing material/credential/failure so local privacy erasure is never blocked by
 * an unknown provider result (ADR-2: false is retained as unknown, never faked success). */

import { revokeAppleToken } from "./apple-revoke.ts";
import { appleClientSecret, type AppleSigningConfig } from "./apple-client-secret.ts";
import type { Job } from "./worker.ts";

export type StoredProviderMaterial = {
  provider: string;
  token: string;
  token_type: "refresh_token" | "access_token";
} | null;

export function createAppleProvider(deps: {
  /** null when no Apple signing credential is provisioned (Owner gate). */
  signing: AppleSigningConfig | null;
  /** Reads the subject's stored revoke material for an ERASING request (lease-fenced). */
  readMaterial: (job: Job) => Promise<StoredProviderMaterial>;
  transport?: typeof fetch;
  now?: () => number;
}): (job: Job) => Promise<boolean> {
  return async (job: Job): Promise<boolean> => {
    if (!deps.signing) return false;
    let material: StoredProviderMaterial;
    try {
      material = await deps.readMaterial(job);
    } catch {
      return false;
    }
    if (!material || material.provider !== "apple" || !material.token) return false;
    if (material.token_type !== "refresh_token" && material.token_type !== "access_token") {
      return false;
    }
    let secret: string;
    try {
      secret = await appleClientSecret(deps.signing, (deps.now ?? Date.now)());
    } catch {
      return false;
    }
    return await revokeAppleToken(
      {
        clientId: deps.signing.clientId,
        clientSecret: secret,
        token: material.token,
        tokenType: material.token_type,
      },
      deps.transport,
    );
  };
}
