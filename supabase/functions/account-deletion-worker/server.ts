// Server-only boundary. Never import from Flutter/LAB. No credentials are provisioned here.
import { type Job, markers, type Ports } from "./worker.ts";
import { identityInputs } from "./http.ts";
import { eraseOwnedStorage } from "./storage.ts";
export type Config = {
  url: string;
  publicKey: string;
  workerJwt: string;
  authAdminKey: string;
  benefitKeys: ReadonlyMap<string, Uint8Array>;
  restoreKey: Uint8Array;
  restoreVersion: string;
  financeReviewed: boolean;
  checkpoint: (manifest: unknown) => Promise<void>;
  notification: (event: unknown) => Promise<void>;
  provider: (job: Job) => Promise<boolean>;
};
export function createPorts(c: Config): Ports {
  if (c.restoreKey.byteLength < 32 || c.benefitKeys.size === 0) {
    throw Error("ACTIVATION_GATE");
  }
  const request = async (
    path: string,
    token: string,
    method = "GET",
    body?: unknown,
  ) => {
    const res = await fetch(c.url + path, {
      method,
      headers: {
        apikey: c.publicKey,
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) throw Error("REMOTE_UNAVAILABLE");
    return res.status === 204 ? null : await res.json();
  };
  const rpc = async (name: string, args: Record<string, unknown>) =>
    request("/rest/v1/rpc/" + name, c.workerJwt, "POST", args);
  const authUser = async (subject: string) => {
    const res = await fetch(
      c.url + "/auth/v1/admin/users/" + encodeURIComponent(subject),
      {
        headers: {
          apikey: c.publicKey,
          authorization: `Bearer ${c.authAdminKey}`,
        },
        signal: AbortSignal.timeout(10000),
      },
    );
    if (res.status === 404) return null;
    if (!res.ok) throw Error("AUTH_UNAVAILABLE");
    const data = await res.json();
    return data.user ?? data;
  };
  return {
    rpc,
    async claimVerifiedBenefit(subject) {
      const user = await authUser(subject);
      if (!user) throw Error("ELIGIBILITY_UNAVAILABLE");
      await rpc("account_benefit_claim", {
        p_subject: subject,
        p_markers: await markers(c.benefitKeys, identityInputs(user)),
      });
    },
    async bindAndCheckpoint(job) {
      if (!job.subject_id) return;
      const user = await authUser(job.subject_id);
      if (!user) return; // Auth timeout-after-success: SQL FK determines the next phase.
      const inputs = identityInputs(user);
      const values = await markers(c.benefitKeys, [...new Set(inputs)]);
      await rpc("account_benefit_record_existing", {
        p_subject: job.subject_id,
        p_markers: values,
      });
      const key = await crypto.subtle.importKey(
        "raw",
        c.restoreKey as BufferSource,
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"],
      );
      const mac = await crypto.subtle.sign(
        "HMAC",
        key,
        new TextEncoder().encode("legendstudy/restore-only\0" + job.subject_id),
      );
      const tag = Array.from(
        new Uint8Array(mac),
        (b) => b.toString(16).padStart(2, "0"),
      ).join("");
      await rpc("account_deletion_bind", {
        p_id: job.request_id,
        p_markers: await markers(
          c.benefitKeys,
          [...new Set(inputs)],
          "lifecycle",
        ),
        p_restore_version: c.restoreVersion,
        p_restore_marker: tag,
      });
      await c.checkpoint(await rpc("account_deletion_restore_manifest", {}));
    },
    async storageEraseAndVerify(subject) {
      await eraseOwnedStorage({
        list: async (bucket, prefix, limit) =>
          await request(
            "/storage/v1/object/list/" + bucket,
            c.authAdminKey,
            "POST",
            {
              prefix,
              limit,
              offset: 0,
              sortBy: { column: "name", order: "asc" },
            },
          ),
        remove: async (bucket, paths) => {
          await request(
            "/storage/v1/object/" + bucket,
            c.authAdminKey,
            "DELETE",
            { prefixes: paths },
          );
        },
      }, subject);
    },
    providerEraseAndVerify: c.provider,
    financePolicyReady: () => c.financeReviewed,
    async authDeleteAndVerify(subject) {
      if (!await authUser(subject)) return;
      try {
        await request(
          "/auth/v1/admin/users/" + encodeURIComponent(subject),
          c.authAdminKey,
          "DELETE",
        );
      } catch { /* only definitive absence below establishes success */ }
      if (await authUser(subject)) throw Error("AUTH_UNAVAILABLE");
    },
    async verifyErasure(job) {
      return await rpc("account_deletion_postconditions", {
        p_id: job.request_id,
        p_token: job.lease_token,
      }) === true;
    },
    async checkpointManifest() {
      await c.checkpoint(await rpc("account_deletion_restore_manifest", {}));
    },
    notify: c.notification,
  };
}
