/** Dispatch-only aggregate diagnostics. Never retain subjects, markers or raw errors. */
export type BenefitStage = "AUTH" | "MARKERS" | "CLAIM";
const safeCodes = new Set([
  "42501",
  "23503",
  "23505",
  "23514",
  "22023",
  "42702",
  "42883",
  "PT401",
  "PT403",
  "PT409",
  "PT422",
  "PGRST202",
  "PGRST301",
]);
export class RemoteFailure extends Error {
  readonly code: string;
  constructor(readonly status: number, code?: unknown) {
    super("REMOTE_UNAVAILABLE");
    this.code = typeof code === "string" && safeCodes.has(code)
      ? code
      : "OTHER";
  }
}
export class BenefitFailure extends Error {
  readonly category: string;
  constructor(stage: BenefitStage, error: unknown) {
    super("BENEFIT_PENDING");
    this.category = error instanceof RemoteFailure
      ? `${stage}_HTTP_${error.status}_${error.code}`
      : `${stage}_UNAVAILABLE`;
  }
}
