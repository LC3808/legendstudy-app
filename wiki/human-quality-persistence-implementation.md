# Human Quality persistence — HQP-3

2026-10-01. IMPLEMENTED / ISOLATED_VERIFIED; Production NOT_APPLIED. Historical [HQP-2](human-quality-persistence-canonical-review.md) remains unchanged. Owner D1–D5 retained; E1/E2 now resolved.

## Final reconciliation before SQL

| HQP-2 finding | HQP-3 choice | Enforcement | Isolated test |
|---|---|---|---|
| 01 student erasure | evaluation-dependent QA, no archive/tombstone | evaluation FK CASCADE, child CASCADE | E1-A–E and session/account cascade |
| 02 reviewer erasure | retain QA, remove direct identity | auth.users FK SET NULL; narrow immutable guard exception | E2-A–F |
| 03 unstable target_ref | exact typed JSON shapes; sentence progress_id + observation_key | helper shape checks + same-evaluation transactional lookup | T27–30 and all seven positive targets |
| 04 branching/idempotency | one successor; global key, exact canonical payload | unique constraints, parent/member/subject locks, server hash | T31–48 including two real connections |
| 05 projection/rubric | active heads, exact-version comparison, severity consistency | versioned validators and derived read RPC | T13–24, T49–58 |
| 06 assessability/rewrite arrival | completed1.3/available context required; official-source review attestation; captured completed rewrite | server availability checks; client confirmation is not semantic proof | unknown context rejection, late rewrite retry |
| 07 indexes | history/constraints/child lookup only | five explicit support indexes/constraints plus PK | catalog + isolated plans; no analytics indexes |

No unresolved HQP-2 blocker remains beyond implementation verification. Names of rubric keys are fixed in the new payload contract from HQP-2's nine dimensions. Existing ql-read-v1 is untouched.

## Account deletion boundary

Owner policy: deletion request → 14-day grace → automatic personal-data erasure. Deletion-pending data is not analytics retention. Current `supabase/functions/delete-account/handler.ts` invokes deleteUser immediately; it has no 14-day scheduler. ACCOUNT_DELETION_14D_IMPLEMENTATION=SEPARATE_IMPLEMENTATION_REQUIRED. ADMIN_DELETION_NOTIFICATION=FOLLOW_UP_REQUIRED. Restriction of access/processing while pending, cancellation and notification belong to that separate account lifecycle; this migration implements none of them. On eventual hard deletion, QA cascades with the evaluation. Invalidation/supersession do not erase QA.

Reviewer deletion preserves QA while the student subject exists, nulls reviewer_user_id and exposes deleted/unavailable reviewer state, never an alias or another reviewer. No reviewer name/email copy. PRIVACY_ANALYTICS_RETENTION_DESIGN is a separate future gate; no copy-before-delete, backup, archive or pseudonymization pipeline here.

## Implemented objects and contract

[Owner package](../supabase/verification/human_quality/README.md), [single forward migration](../supabase/migrations/20261001000200_human_quality_persistence.sql), [isolated validation](../supabase/verification/human_quality/validation.json), [runner](../tool/test_human_quality.py). New operational fact: human review of a specific immutable AI output under a rubric, not a student grade, model truth, progress, authorization or billing event.

Two tables: `human_quality_judgments`, `human_quality_findings`; three public RPCs; four private helpers. Exact ownership/ACL/constraints/indexes in Owner package. Historical HQP-2 remains unchanged; E1/E2 corrections are implemented here. ql-read-v1 and is_quality_operator/quality_operators unchanged. No default client table rights, no self enrollment, no extra reviewer role. Writer locks current membership, serializes global key, locks evaluation and correction parent; immutable source is never overwritten.

### Writer DTO

`ql_submit_human_judgment(p_payload jsonb)` accepts ONLY:

- dto_version=`hq-write-v1`; evaluation_id UUID; expected_output_sha256; client_submission_id UUID; rubric_version=`hq-rubric-v1`.
- overall_disposition=PASS/PASS_WITH_NOTES/NEEDS_REVIEW/FAIL.
- rubric_result exact keys: diagnosis, core_priority, actionability, evidence_adherence, stance_preservation, hallucination_absence (OK/CONCERN/FAIL); sentence_feedback, progression, generated_rewrite (same + NA).
- findings array (required, may be [], maximum20); optional summary_note (≤2000 Unicode chars); optional supersedes_judgment_id.
- optional selection_reason (EARLY_CENSUS default; RANDOM_SAMPLE/ANOMALY/USER_REPORT/OPERATOR_REQUEST/MODEL_CHANGE_AUDIT/DISPUTE/OTHER) and recommended_action (NONE default; MONITOR/REVIEW_PROMPT/REVIEW_EVIDENCE/RE_EVALUATE/INVALIDATE_CANDIDATE/ESCALATE).
- official_source_reviewed=true: operator confirmation of matching official material/context, **not server proof of semantic correctness or official PDF availability**. Do not submit complete rubric when source/history cannot be assessed.

Total normalized JSONB text ≤32KiB UTF-8. Unknown keys/versions rejected; reviewer/time/actual output hash/rewrite binding are server-derived. All six required dimensions present, no NA; conditional NA must match actual available sentence/prior context/completed rewrite. Completed Contract1.3 and complete stored scaffolding/frozen binding arrays required; missing legacy context/source is not “no problem.” No hidden numeric score. PASS permits only OK/NA and zero findings; PASS_WITH_NOTES permits no FAIL or material/critical finding. NEEDS_REVIEW and FAIL are human decisions, neither triggers any action.

Each finding: issue_category, severity, target_kind, target_ref, optional note≤1000. Categories and exact seven typed target shapes are in HQP-2 §9 and enforced by hq_finding_valid; server validates target membership. OVERALL/GENERATED_REWRITE use explicit JSON null; SENTENCE uses progress_id+observation_key. No fake sentence UUID. Evidence link composite must resolve exactly once. Root CORE membership remains canonical core_focus, never a priority heuristic. CORE=[] valid.

Writer returns only dto_version, judgment_id, replayed. JSONB key order/whitespace and top-level omitted defaults normalize; findings array order and supplied finding object values are part of the request identity. Preserve exact original request for retry; no client hash authority. Hash includes captured completed rewrite; later rewrite completion does not alter earlier NA/retry. Erasure of a bound artifact may make its prior retry conflict; never retain a detached identifier just to support retries. No idempotency tombstone after subject erasure.

### Read DTOs and projection

`ql_review_state(uuid[])`: gate before existence lookup, maximum100 input elements, reject null elements/multidimensional arrays, []→[]; deduplicated UUID order. Missing case returns NOT_FOUND availability. Existing case has active_count/total_count/latest_human_reviewed_at/has_material_issue plus derived review state. Heads exclude superseded rows. Zero UNREVIEWED; one REVIEWED_ACCEPTABLE / REVIEWED_WITH_CONCERNS / REVIEWED_FAILED; multiple matching buckets MULTIPLE_REVIEWS, incompatible disposition buckets DISAGREEMENT; different exact rubric versions MULTIPLE_REVIEWS + NOT_COMPARABLE. No latest-wins or score.

`ql_list_human_judgments(uuid,integer=20,timestamptz=NULL,uuid=NULL)`: max100, paired created_at/id descending keyset cursor. Missing case error; existing empty history []. Includes independent and superseded judgments, findings/internal notes, reviewer UUID when present and DELETED_OR_UNAVAILABLE when removed. No email/name/student account identifier; no client idempotency key/hash in response. UTC timestamps; optional notes/rewrite/reviewer remain null. Future UI must not call a paginated page full history. All new read responses hq-read-v1. Existing ql-read-v1 untouched.

## Verification and launch gate

105 isolated PG17 checks PASS, including actual two-connection concurrency. T1–T69 mapped in runner/validation (T11/T12 combined catalog check). E1 invalidation and supersession preserve old QA; evaluation/session/auth-user deletion cascades QA and findings. E2 auth reviewer deletion nulls identity while preserving QA/findings. Strict UPDATE guards, seven targets, CORE0, conditional NA, note/payload bounds, source attestation, no billing/Essay data side effect, original catalogs and bounded rollback checked. Incompatible-version projection tested directly on production helper; unknown version submission remains denied.

Schema snapshot covers existing public/private definitions, ownership, RLS/policies, table/function ACLs, columns, constraints and user triggers. Auth shim is local role/claim simulation only; no Production JWT proof. No live catalog access, test user/evaluation creation or SQL application. Original22 remote ledger snapshot is reused, local migration25; provider005/day_targets unchanged. No analytics indexes, no Production load tests.

Seven preservation answers: server created_at/explicit correction separates events; evaluation/hash/rubric/rewrite pin retained subject; no correction UPDATE; canonical auth identity reused; human operational judgment distinct from Learning/Outcome; explicit E1/E2 erasure and operator-only notes; review state/metrics derived, never stored as model ground truth. Hard erasure deliberately ends per-student QA reproducibility. Future analytics retention cannot quietly restore it.

READY_FOR_OWNER_MIGRATION_REVIEW=YES. READY_FOR_PRODUCTION_APPLY=NO (Owner required); READY_FOR_HUMAN_REVIEW_WRITE_UI=NO until apply+gateway verification; READY_FOR_REAL_STUDENT_PILOT=NO. AI OFF; model NOT_SELECTED. Stop after source/doc closeout; no HQP runtime apply or LAB work authorized here.
