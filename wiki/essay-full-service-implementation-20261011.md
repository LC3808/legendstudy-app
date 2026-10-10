# Essay full-service implementation — 2026-10-11

**PARTIAL — implemented / contract verified; no new real Provider E2E.**
Branch: `codex/essay-full-service-implementation` in APP, LAB and DOCS.
This is the Oct10 Owner full-service directive continued past midnight KST. It
supersedes the V2 preview-only stopping point, not publication or DB approval gates.

## Product and source authority

Read Unified AI_CONTEXT, CURRENT_STATUS, ARCHITECTURE, SOURCE_OF_TRUTH, latest Daily,
APP product architecture/decisions/product v1, Essay/monetization roadmaps, data
foundation, Manus handoff and runtime/Credit/Quality documents before implementation.
Fresh remote bases: APP1fd87f5 / LABa5f7f17 / DOCS0dfa081. Older Unified current
sections predate completed QA metadata APP4de2125/LABc977493; those implementations
are preserved, not recreated. Main and prior worktrees/branches are unchanged.

Student value: official requirements → own answer → evidence-based strengths and
WHERE/WHAT/WHY/HOW/NEXT CHECK → direct rewrite → comparable stored progress.
Existing positive-learning prompt, native APP identity, shared Auth/Credit/History,
1 Credit initial success + first same-answer reevaluation within14 days remain.
No AI-generated replacement answer is added. CORE selection remains Owner-owned.

## Verified content inventory

Production read-only inventory found0 general `essay_questions`,0 question evidence
and0 evaluation criteria. This explains why a new general-essay route cannot yet
show production practice questions; previous successful Math E2E uses a separate
canonical Math catalog and is not evidence of official general-question publication.
Existing university/exam/resource IDs are reused. No Offering/Track tables invented.

One existing private frozen package was connected: 성균관대2025 인문1,3 questions,
9 official numbered criteria (3 per question),21 unique source excerpts expressed
as34 question/evidence relations,1 canonical resource. A–F grade bands remain
context, not nine independent dimensions or invented numeric weights. Limits not
verified in the package remain NULL. Candidate question/criterion IDs are stable
UUIDv5 values; university/exam/resource identities are existing canonical values.

Package: `v1-sha256:bac7afbcbc2d11c18360d464d687065abf32a242d2a8545ad8fb3b1935576fd4`.
Retained sourcePDF SHA256:
`43371e05adaecbd324cadd2e28895d2b76e7d1598c9e857d1bd75aaa34d53e0d` reverified.
Private package: `.local/essay-evidence/skku-2025-humanities1-v1` in the original
APP development checkout. SourcePDF is `.local/essay-pilot-2025/pdfs/1689-00.pdf`.
No source body, private student answer, PDF or graph was committed or transmitted.

`tool/essay_lab/service_content.py` reuses existing evidence validators; generates
an ignored0600 private import plan, validates exact frozen hashes/locators/graph,
and transactionally imports into existing tables in isolated Unix-socket PG only.
Exact replay is a no-op; changed rows abort, never overwrite. Publication false.
The retained importer is deliberately NOT a production import command.
`cache_for_claim` binds actual source extracts and criteria to the canonical frozen
worker claim. Q1 text input verifies; Q2/Q3 fail closed because the current text
worker cannot faithfully include their required graph. Official example answers
remain private references and are not silently added to provider projection.

Manus V2 research53 Master/50 Offering/101 Track/42 universities and LSL27-052
quarantine preserved. This task did not turn50 research offerings into operational
admissions rows. Existing Hanyang2024/Sookmyung2025 packages and retained Hanyang
PDFs were located/reused as evidence inventory; not recollected or reclassified as
service-ready. Hanyang2024 afternoon2 lacks a verified matching canonical exam ID.
The134-post export and complete5-year coverage are still missing. Dongguk/Kyunghee/
Kwangwoon official per-question packages require extraction and verification.

## Backend and WEB implementation

- Existing `essay_exams`/universities RLS catalog (active+verified), published
  question reads, university/type/track query, actual-exam-year and campus filters.
  Bounded latest200 exams/100 questions per exam; no full-catalog pagination claim.
  Existing2027 research preview and current public catalog are preserved separately.
- `/essay-lab/write/?question=...&session=...`: existing login, canonical
  `essay_open_session`, draft restore, CAS save, immutable/idempotent submit.
  Unsaved-answer warning and auth identity revocation; prior submitted answer kept
  when student chooses direct rewrite. No anonymous Auth account or new wallet.
- Result status uses existing RPC, stored summary/strengths/checklist, shared
  `/my/essays/` detail and existing criteria/improvement/history/growth readers.
  This session's result status is refreshed manually; no claimed background push.
- New `/api/essay/admission` and `/api/essay/evaluate` default CLOSED. Caller JWT,
  existing allowlist, exact origin and owned attempt precede worker admission.
  Trusted service binding must confirm question+metadata, provider policy and
  ≤120-second readiness; canonical request key is stable across ambiguous dispatch.
  A new retry key is allowed only after owned failed evaluation and canonical
  `no_credit_consumed` confirmation. Unknown outcomes remain status-check requests.
- Gateway calls an `ESSAY_REVIEWED_WORKER` service binding. **Hosted adapter is not
  implemented/provisioned in this change**: existing Python ReviewedRuntimeWorker,
  real provider policy, reviewed cache, independent signed reviewer and durable
  checkpoint storage must be composed by that adapter. No dummy ready response,
  test-key reviewer or fake completion enables production billing.
- Student prompt/passage bodies are NOT published. Current detail provides actual
  metadata and verified official source link; in-page authorized passage/figure
  delivery remains incomplete. Links alone are not full-service acceptance.
- No new real Humanities, Econ/Business, Math-official or Science Provider E2E.
  Existing Composition/Science contracts and previous synthetic-Math real E2E
  remain unchanged. Figure/formula rendering and type-specific minimum official
  questions are still release blockers, not falsely marked READY.

## Recovery and SQL review packet

Owner-only `/api/math/recover` verifies existing student learning state before
using the existing narrow worker credential for deployed `math_recover_evaluation`.
A separately gated prepared batch entry point can process up to20 expired jobs.
New SQL adds only `math_recover_expired_evaluations(integer)` (maximum50), delegating
expiry/settlement to the unchanged canonical single-job function, using attempt-first
SKIP LOCKED locking. Lifecycle denials are counted, not bypassed. No Cron installed.

[Migration, backup, dependency/permission audit, rollback and evidence](../supabase/verification/essay_service/README.md).
**Production NOT_APPLIED.** Original function fingerprint preserved. No Billing,
Ledger, Auth, Profile, Payment/Toss/IAP, Storage policy, RLS or QA read/write change.
Closed lifecycle jobs can be skipped on every batch; operators must inspect a
persistently nonzero skipped count rather than assume every orphan is recovered.
Existing worker credential renewal (prior Wiki expiryOct16) still needs operations.

## Validation and practical limits

- Isolated PG17 actual retained content:19 assertions PASS. Canonical import,
  unpublished RLS, foreign user/CAS denial, submit replay, frozen snapshot/cache,
  immutable rewrite and failed-evaluation release. No Provider call.
- Isolated PG17 Math recovery:21 assertions PASS. Role denials, active lease,
  expired requested/processing, duplicate release, late finalize rejection,
  concurrent lock skip, unchanged completed history/function and rollback.
- WEB related Vitest:96 PASS,1 SKIP in17 files. Skip is the optional private V2
  converted-catalog bundle absent in this new worktree, not a service E2E test.
- Full WEB lint/typecheck and boundary audit PASS. The boundary audit's two old
  `모의·수능 LAB` assertions were corrected to the existing Owner-approved `수능 LAB`.
- WEB production export: Webpack build PASS (final log recorded at closeout).
  Default Turbopack rejects the pre-existing node_modules symlink outside project
  root; dependencies were reused, not reinstalled. Use `npm run build -- --webpack`.
- Actual local browser guest catalog360/390/768/1280: document scroll width equals
  viewport width; login-return boundary verified. No authenticated browser E2E or
 200% text-scaling acceptance claimed. Private answers were not entered in browser.
- Flutter/native UI untouched; no Flutter builds or device debugging performed.
- New actual Provider calls0, production Credit transactions0, production writes0,
  deployments0. Isolated fixture Credit writes are synthetic test facts only.

## Next implementation / review

1. Review the migration packet separately; no SQL is authorized to apply by this
   report. Keep QA metadata migration and WikiPR#1/#2 approval pending.
2. Obtain the exact official-content processing/display permissions, approve a
   frozen per-question provider policy, and prepare controlled unpublished import
   from the reviewed plan. Do not run the isolated importer against production.
3. Implement the hosted private ReviewedRuntimeWorker binding with independent
   review/checkpoint persistence; verify it against isolated Auth/PostgREST before
   any allowlisted live reservation. Keep runtime flags absent/OFF until ready.
4. Add authorized student prompt/figure delivery, then one real private successful
   initial+reevaluation per supported type; verify shared APP/WEB History/Credit.
   Do not reuse synthetic Math success as official-content quality acceptance.
5. Owner UI review: catalog, editor, status/result/rewrite and shared history. Owner
   AI review: SKKUQ1 official3 criteria and strengths/CORE/teacher-like feedback;
   Q2/Q3 after visual support. Neither review is claimed complete.

General user activation HOLD. No main merge, store submission, device debugging,
Production DB apply, allowlist expansion or real Credit mutation occurred.
