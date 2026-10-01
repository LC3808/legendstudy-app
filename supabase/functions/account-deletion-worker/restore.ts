/** Restore-only plan. Apply by request_id, verify effects, then recompute before reopening.
 * Subject IDs are transient privileged execution input, never public output or logs.
 */
export type Obligation = {
  request_id: string;
  state: "DELETION_PENDING" | "ERASING" | "CANCELLED" | "ERASED";
  requested_at: string;
  deadline: string;
  cancelled_at: string | null;
  completed_at: string | null;
  expires_at: string | null;
  key_version: string | null;
  restore_tag: string | null;
};
export type RestoreAction = {
  request_id: string;
  subject: string;
  action:
    | "RESTORE_RESTRICTION"
    | "RESUME_ERASURE"
    | "NEUTRALIZE_CANCELLED"
    | "REAPPLY_ERASURE";
  requested_at: string;
  deadline: string;
  cancelled_at: string | null;
  completed_at: string | null;
};
export async function restoreGate(
  subjects: readonly string[],
  manifest: readonly Obligation[],
  keys: ReadonlyMap<string, Uint8Array>,
  now: Date,
  backupHorizonHours: number,
  proof: {
    inventoryComplete: boolean;
    checkpointFresh: boolean;
    // Trusted restore executor must verify exact request action/postconditions, never a browser assertion.
    verifyAction?: (action: RestoreAction) => Promise<boolean>;
  },
): Promise<{ reopen: boolean; actions: RestoreAction[] }> {
  const fail = () => {
    throw Error("RESTORE_GATE_UNSATISFIED");
  };
  if (
    !Number.isFinite(now.getTime()) || !Number.isFinite(backupHorizonHours) ||
    backupHorizonHours > 720 || backupHorizonHours < 0 ||
    manifest.length > 100000 ||
    !proof.inventoryComplete || !proof.checkpointFresh
  ) fail();
  const actions: RestoreAction[] = [];
  const seen = new Map<string, string>();
  for (
    const o of [...manifest].sort((a, b) =>
      a.requested_at.localeCompare(b.requested_at) ||
      a.request_id.localeCompare(b.request_id)
    )
  ) {
    if (
      !o.request_id ||
      !["DELETION_PENDING", "ERASING", "CANCELLED", "ERASED"].includes(o.state)
    ) fail();
    const encoded = JSON.stringify(o);
    if (seen.has(o.request_id)) {
      if (seen.get(o.request_id) !== encoded) fail();
      else continue;
    }
    seen.set(o.request_id, encoded);
    const requested = Date.parse(o.requested_at),
      deadline = Date.parse(o.deadline);
    if (!Number.isFinite(requested) || deadline - requested !== 336 * 3600000) {
      fail();
    }
    const terminal = o.state === "CANCELLED"
      ? o.cancelled_at
      : o.state === "ERASED"
      ? o.completed_at
      : null;
    if (o.state === "CANCELLED" || o.state === "ERASED") {
      const end = Date.parse(terminal ?? "");
      if (
        !Number.isFinite(end) ||
        Date.parse(o.expires_at ?? "") - end !== 720 * 3600000 ||
        end < requested
      ) fail();
      if (o.state === "CANCELLED" && end >= deadline) fail();
      if (o.state === "ERASED" && end < deadline) fail();
      if (Date.parse(o.expires_at!) <= now.getTime()) continue;
    } else if (o.expires_at || o.cancelled_at || o.completed_at) fail();
    // Missing bind is visible in SQL's LEFT JOIN, not silently omitted.
    const secret = o.key_version ? keys.get(o.key_version) : undefined;
    if (
      !secret || secret.byteLength < 32 ||
      !o.restore_tag?.match(/^[a-f0-9]{64}$/)
    ) fail();
    const key = await crypto.subtle.importKey(
      "raw",
      secret! as BufferSource,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    for (const subject of [...new Set(subjects)].sort()) {
      const mac = await crypto.subtle.sign(
        "HMAC",
        key,
        new TextEncoder().encode("legendstudy/restore-only\0" + subject),
      );
      const tag = Array.from(
        new Uint8Array(mac),
        (b) => b.toString(16).padStart(2, "0"),
      ).join("");
      if (tag !== o.restore_tag) continue;
      const action: RestoreAction = {
        request_id: o.request_id,
        subject,
        action: o.state === "CANCELLED"
          ? "NEUTRALIZE_CANCELLED"
          : o.state === "ERASED"
          ? "REAPPLY_ERASURE"
          : o.state === "ERASING" || deadline <= now.getTime()
          ? "RESUME_ERASURE"
          : "RESTORE_RESTRICTION",
        requested_at: o.requested_at,
        deadline: o.deadline,
        cancelled_at: o.cancelled_at,
        completed_at: o.completed_at,
      };
      if (!proof.verifyAction || !await proof.verifyAction(action)) {
        actions.push(action);
      }
    }
  }
  // A plan is not executed reconciliation. Reopening requires verified replay, never just this plan.
  return { reopen: actions.length === 0, actions };
}
