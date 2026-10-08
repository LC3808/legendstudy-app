/** ADR-2 transport-independent worker. All transports are server-only.
 * No implicit provider success; bounded calls and lease lifetime are transport contracts.
 * Driver must not log jobs, IDs, tokens or payloads.
 */
import { BenefitFailure } from "./benefit-diagnostics.ts";
export type Job = {
  request_id: string;
  subject_id: string | null;
  phase: string;
  state?: string;
  lease_token: string;
};
export type Marker = { version: string; marker: string };
export interface Ports {
  rpc(name: string, args: Record<string, unknown>): Promise<unknown>;
  claimVerifiedBenefit(subject: string): Promise<void>;
  captureBenefit(
    job: Job,
  ): Promise<"CAPTURED" | "NOT_AVAILABLE" | "FAILED_SAFE">;
  // Registers verified-credential blocking + restore tags while identity exists.
  bindAndCheckpoint(job: Job): Promise<void>;
  // Enumerate ALL registered owner namespaces, remove via API, verify absence.
  storageEraseAndVerify(subject: string): Promise<void>;
  // Return false if unknown or unsupported. Never fake provider completion.
  providerEraseAndVerify(job: Job): Promise<boolean>;
  financePolicyReady(): boolean;
  authDeleteAndVerify(subject: string): Promise<void>;
  // Confirm local postconditions + external obligations, even when Auth already gone.
  verifyErasure(job: Job): Promise<boolean>;
  checkpointManifest(): Promise<void>;
  notify(event: unknown): Promise<void>;
}
export async function dispatch(
  p: Ports,
): Promise<{
  processed: number;
  retryable: number;
  benefits: {
    attempted: number;
    completed: number;
    failed: number;
    failures: Record<string, number>;
  };
}> {
  const unbound = await p.rpc("account_deletion_unbound", {
    p_limit: 20,
  }) as Job[];
  for (const pending of unbound) {
    try {
      await p.bindAndCheckpoint(pending);
    } catch { /* Retry this subject; do not starve other due requests. */ }
  }
  await p.checkpointManifest(); // Do not lose obligations across restore.
  const jobs = await p.rpc("account_deletion_claim", { p_limit: 5 }) as Job[];
  const result = {
    processed: 0,
    retryable: 0,
    benefits: {
      attempted: 0,
      completed: 0,
      failed: 0,
      failures: {} as Record<string, number>,
    },
  };
  for (const job of jobs) {
    let failure = "TRANSPORT_UNAVAILABLE";
    const args = { p_id: job.request_id, p_token: job.lease_token };
    const advance = async (phase: string, next: string) => {
      await p.rpc("account_deletion_advance", { ...args, p_phase: phase });
      job.phase = next;
    };
    try {
      if (job.subject_id) await p.bindAndCheckpoint(job);
      if (job.phase === "PERSONAL") {
        let captured: "CAPTURED" | "NOT_AVAILABLE" | "FAILED_SAFE" =
          "FAILED_SAFE";
        try {
          captured = await p.captureBenefit(job);
        } catch { /* no promotional retry holds privacy */ }
        await p.rpc("account_deletion_capture_result", {
          p_id: job.request_id,
          p_result: captured,
        });
      }
      if (job.phase === "PERSONAL") {
        if (await p.rpc("account_deletion_personal", args) !== true) {
          throw Error("BATCH_REMAINS");
        }
        job.phase = "STORAGE";
      }
      if (job.phase === "STORAGE") {
        failure = "STORAGE_UNAVAILABLE";
        if (!job.subject_id) throw Error();
        await p.storageEraseAndVerify(job.subject_id);
        await advance("STORAGE", "PROVIDER");
      }
      if (job.phase === "PROVIDER") {
        failure = "PROVIDER_EXTERNAL_GATE";
        let verified = false;
        try {
          verified = await p.providerEraseAndVerify(job);
        } catch { /* local erasure must continue */ }
        await p.rpc("account_deletion_provider_result", {
          ...args,
          p_verified: verified,
        });
        await advance("PROVIDER", "FINANCE");
      }
      if (job.phase === "FINANCE") {
        failure = "FINANCE_EXTERNAL_GATE";
        if (!p.financePolicyReady()) throw Error();
        await advance("FINANCE", "AUTH");
      }
      if (job.phase === "AUTH") {
        failure = "AUTH_UNAVAILABLE";
        // Null subject means the FK confirms Auth deletion already occurred.
        if (job.subject_id) await p.authDeleteAndVerify(job.subject_id);
        await advance("AUTH", "VERIFY");
      }
      if (job.phase === "VERIFY") {
        // Local erasure completion does not claim provider-side revocation.
        // Unknown provider status remains a sanitized operational notification.
        failure = "POSTCONDITION_FAILED";
        if (!await p.verifyErasure(job)) throw Error();
        await p.rpc("account_deletion_finish", args);
        await p.checkpointManifest();
        result.processed++;
      }
    } catch {
      result.retryable++;
      // If lease expired, leave it recoverable; never send raw exception text.
      try {
        await p.rpc("account_deletion_retry", { ...args, p_error: failure });
      } catch { /* watchdog reclaims */ }
    }
  }
  const events = await p.rpc("account_deletion_notifications", {}) as {
    request_id: string;
  }[];
  for (const event of events) {
    try {
      await p.notify(event);
      await p.rpc("account_deletion_notification_ack", {
        p_id: event.request_id,
      });
    } catch { /* independent retry */ }
  }
  const candidates = await p.rpc("account_benefit_candidates", {
    p_limit: 20,
  }) as string[];
  for (const subject of candidates) {
    result.benefits.attempted++;
    try {
      await p.claimVerifiedBenefit(subject);
      // A completed RPC is not proof of a newly created grant; verify the ledger.
      result.benefits.completed++;
    } catch (error) {
      result.benefits.failed++;
      const category = error instanceof BenefitFailure
        ? error.category
        : "UNKNOWN";
      result.benefits.failures[category] =
        (result.benefits.failures[category] ?? 0) + 1;
      // Benefit pending; account creation and erasure remain unaffected.
    }
  }
  await p.rpc("account_deletion_maintenance", {});
  return result;
}
/** Inputs supplied only by verified server adapters, never client profile metadata. */
export async function markers(
  keys: ReadonlyMap<string, Uint8Array>,
  inputs: readonly string[],
  purpose: "benefit" | "lifecycle" = "benefit",
): Promise<Marker[]> {
  if (
    keys.size === 0 || inputs.length === 0 || keys.size * inputs.length > 16
  ) throw Error("ELIGIBILITY_UNAVAILABLE");
  const output: Marker[] = [];
  for (const [version, secret] of keys) {
    if (secret.byteLength < 32) throw Error("ELIGIBILITY_UNAVAILABLE");
    const key = await crypto.subtle.importKey(
      "raw",
      secret as BufferSource,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    for (const input of inputs) {
      const mac = await crypto.subtle.sign(
        "HMAC",
        key,
        new TextEncoder().encode(
          `legendstudy/${purpose}/essay_signup_3_v1\0` + input,
        ),
      );
      output.push({
        version,
        marker: Array.from(
          new Uint8Array(mac),
          (b) => b.toString(16).padStart(2, "0"),
        ).join(""),
      });
    }
  }
  return output;
}
