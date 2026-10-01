/** Restore-only pre-service control. Never expose tags or returned subjects to clients/logs.
 * The manifest must come from the protected checkpoint outside the restored DB.
 */
export type Obligation = {
  state: string;
  deadline: string;
  expires_at: string | null;
  key_version: string;
  restore_tag: string;
};
export async function restoreGate(
  subjects: readonly string[],
  manifest: readonly Obligation[],
  keys: ReadonlyMap<string, Uint8Array>,
  now: Date,
  backupHorizonHours: number,
  proof: { inventoryComplete: boolean; checkpointFresh: boolean },
): Promise<{ reopen: boolean; subjectsToErase: string[] }> {
  if (
    backupHorizonHours > 720 || backupHorizonHours < 0 ||
    manifest.length > 100000
  ) throw Error("RESTORE_GATE_UNSATISFIED");
  const pending = new Set<string>();
  for (const obligation of manifest) {
    if (!["DELETION_PENDING", "ERASING", "ERASED"].includes(obligation.state)) {
      throw Error("RESTORE_GATE_UNSATISFIED");
    }
    if (
      obligation.expires_at &&
      Date.parse(obligation.expires_at) <= now.getTime()
    ) continue;
    if (!Number.isFinite(Date.parse(obligation.deadline))) {
      throw Error("RESTORE_GATE_UNSATISFIED");
    }
    const secret = keys.get(obligation.key_version);
    if (!secret || secret.byteLength < 32) {
      throw Error("RESTORE_GATE_UNSATISFIED");
    }
    const key = await crypto.subtle.importKey(
      "raw",
      secret as BufferSource,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    for (const subject of subjects) {
      const mac = await crypto.subtle.sign(
        "HMAC",
        key,
        new TextEncoder().encode("legendstudy/restore-only\0" + subject),
      );
      const tag = Array.from(
        new Uint8Array(mac),
        (b) => b.toString(16).padStart(2, "0"),
      ).join("");
      if (tag === obligation.restore_tag) pending.add(subject);
    }
  }
  // Even not-yet-due PENDING accounts must have restrictions/deadline replayed before reopen.
  return {
    reopen: pending.size === 0 && proof.inventoryComplete &&
      proof.checkpointFresh,
    subjectsToErase: [...pending],
  };
}
