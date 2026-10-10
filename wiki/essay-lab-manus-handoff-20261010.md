# Manus Essay handoff V2 — 2026-10-10

Status: approved offline implementation complete; public activation HOLD. ZIP internal
CODEX_OVERNIGHT_INSTRUCTIONS.md V2 supersedes V1. Prior QA metadata APP4de2125/LABc977493
is inherited unchanged; migration and DOCS PR#1 remain awaiting separate approval.
No mobile/device/Provider/Credit/Production DB mutation or deployment.

## Source of truth and integrity

Owner local source: `~/Downloads/legendstudy_essay_manus_handoff_20261010_V2.zip`.
Extracted for this run at `/private/tmp/legendstudy-manus-v2`. No Ubuntu Manus paths
are assumed. Original12 research/data/policy files match all manifest SHA256 hashes.
The manifest's instructions entry still has V1 bytes/hash; current V2 instruction
hash is separately recorded, not silently rewritten. This warning does not invalidate
the12 matching research originals. [Exact per-file audit](../tool/essay_lab/evidence/overnight-20261010/manus-audit.json).

Master53 / unique university42; Seoul27 + non-Seoul26; Offerings50; Tracks101;
university evidence10. JSON/CSV values, disjoint subset coverage and all source/parent
IDs/year/university links pass. Supported transport formats: UTF8 BOM CSV, safe Python
list literals, pipe-delimited track IDs, True/true boolean spelling. No truth value
inference.53→50 is explicit source aggregation: CAU Seoul023+024, Korea Sejong050+051,
PNU048+049; all original IDs and per-row fields remain available, no numerical sums.
LSL27-052 mentions2027-08-27 after as_of2026-09-18: quarantined candidate, raw note
unchanged. UNKNOWN/NOT PUBLISHED/REVIEW_REQUIRED and provisional format/input evidence
states remain literal. All101 routing statuses remain NOT_ROUTABLE_WITHOUT_QUESTION_AND_GOLD_PACKAGE.

## Actual schema / route correspondence

Read-only production catalog inspection confirms the following tables; no DDL.

| Product node | Existing canonical implementation | Candidate treatment |
|---|---|---|
| University | public.universities UUID + unique slug | Keep source university_id; explicit reconciliation required (e.g. skku vs sungkyunkwan). Never generate a DB UUID from a slug |
| Essay offering | Administrative metadata in essay_exams; no essay_offerings table | Preserve50 independent candidate IDs and original53 rows; future persistence design review needed |
| Essay Track | No essay_tracks table; existing context/profile fields are not Track identities | Keep101 candidates, four axes separate, no new table |
| QuestionSet | essay_exams exam/session and Math math_problem_sets | No automatic2027→historical paper association |
| Question | essay_questions; Math math_problems/math_subproblems | No question created; empty questionSets is explicit missing state |
| Evidence / rubric | essay_exam_resources/resources + source-bound private packages and versioned profiles | Reuse source hash/page/role/version; rights/evaluation gates independent |

LAB public-catalog previously exposes five reviewed public fixtures and university/year
routes. `/essay-lab/universities/` existed as a route directory but had no index page;
new index reuses the existing catalog in normal mode. Existing main, university and
year routes now accept the local-only research adapter; no competing project/routes.
No Production API has been added. Development-only server file loading reads ignored
`.local/essay-research/catalog.json` with LEGENDSTUDY_ESSAY_PREVIEW=1. Production always
returns null even with this flag. Default reviewed public fixture behavior remains.

UI: university search/Seoul filter → year → separately rendered campus/offering/track
→ per-source original numbers/date/status → official citation → missing historical
question state → disabled evaluation. Current source HTTP URLs remain HTTP; no silent
rewrite. University identity is never a cohort/score/probability. Provisional format
labels (including Humanities/MATH_REASONING combinations) are source claims for review,
not question-level validated formats. No actual scoring route is inferred.

## Evidence reuse and import readiness

Reused [data foundation](essay-lab-data-foundation.md), [SKKU package](essay-lab-evidence-package-v1.md),
[roadmap](roadmap-essay-lab.md), existing evidence_vnext_l2c1_result and source manifests.
[Existing package references](../tool/essay_lab/evidence/overnight-20261010/existing-package-references.json)
preserve SKKU2025, Hanyang2024 afternoon2 and Sookmyung2025 source hashes, versions,
question IDs and page locators. Hanyang afternoon1's separate mismatch is not hidden
by afternoon2 PASS. No PDF/student/accepted-answer content was copied or downloaded.
Package metadata availability is not fresh verification of private PDF bytes.

[10 candidate readiness records](../tool/essay_lab/evidence/overnight-20261010/import-candidate-readiness.json)
reuse the existing evidence_preview.evidence_manifest role/visibility verifier;
question + scoring_criteria mappings require official/verified/source locator/hash,
with explicit missing states. Candidates retain research-tier versus Owner UNDECIDED; no CORE promotion. Full source URL candidate
JSON is generated locally, with missing question/exam/year/PDF hash/locator and rights
review blockers. Existing full source-bound packages are referenced instead of rebuilt.
The134-row inventory CSV and PDF bodies are missing from ZIP; reported134 posts/30
normalized universities/1635 attachment labels are research claims, not freshly audited
row counts. Rights to commercial use/AI processing/storage/redistribution are unapproved.
No missing evidence or permission is replaced by a plausible value.

## Credit / QA preservation

Prior E2E timeout lease recovery released one reservation once (existing Wiki evidence).
Read-only deployed math_recover_evaluation(uuid) inspection: locks attempt/evaluation,
checks active account, recovers expired PROCESSING or REQUESTED older than5min, invokes
existing release_billing then FAILED/TIMEOUT; other states return false. Function MD5
5cc017fbbd0ba9ca4602827dd0fbeeeb; anon/authenticated execute false. It was not called.
This deployed wrapper was not found by name in the checked-out migration sources:
operational provenance/scheduled orphan recovery remains a follow-up, not authority to
invent a replacement. No local defect was reproduced; no Credit code or new recovery
contract tests were added under V2's conditional scope. Original upstream failure cause
and unattended recovery reliability remain unresolved. No actual transaction incurred.
QA metadata34-test evidence reused, not rerun; existing migration/rollback bytes unchanged.

## Preservation review (seven questions)

1. Keep research as_of, original checked_at and generation version distinct.
2.12 immutable source hashes reproduce offline conversion; raw sources untouched.
3. No current-state UPDATE or destructive merge; retain every source ID and raw row.
4. No Auth UID or new account identity; university/candidate IDs only.
5. Research is source metadata, not student Learning/Decision/Outcome history.
6. Local-only data, missing rights held, no student collection or new retention policy.
7. Research tiers/provisional formats are not verified facts, model scores or permissions.

## Validation / restore

Python10 tests PASS (actual local package + tamper/orphan/determinism/evidence gates).
WEB13 tests PASS (actual converted bundle, synthetic UI and production fail-closed),
typecheck/changed-scope lint/static build PASS. Local browser1280px:42 universities,
search to1 university/2 offerings, existing year navigation, separate campuses, disabled
CTA, no horizontal overflow. No physical device, provider E2E or old963-suite repetition.
Production export with preview flag set contains0 candidate source-ID/routing markers.
Run instructions live in LAB `docs/ESSAY_RESEARCH_PREVIEW.md`. Only sanitized audit and
metadata references are committed; original research and converted rows stay local.
Next gates: review future notice/ambiguous provisional formats, Owner CORE and usage
rights, missing inventory/PDF evidence, explicit canonical mappings, separately approved
persistence/publication/evaluator binding. QA migration and Wiki PR#1 approval remain separate.
