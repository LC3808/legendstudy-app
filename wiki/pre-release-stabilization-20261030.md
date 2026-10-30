# Pre-release stabilization — 2026-10-30

## Scope and restore

Owner paused APP30 device QA. No new evaluation/Provider request, Credit adjustment, DB migration, Worker/Auth deployment, device installation or store submission. Read-only SELECT/RPC against LegendStudy `stlhijzpjfgwwdgunlsd` only; ownership claim used inside a rolled-back read-only transaction for existing History. No production data mutation.

APP: `codex/essay-evaluation-stability-p0-20261029`, baseline `6ff979978b64556c3671885dcfc3f4a0d7f54541` (reported6600a3c is older). Existing untracked `.fvmrc` preserved. WEB: `/Users/woojinchang/development/legendstudy-release-20261024`, `codex/web-app-release-20261024`, baseline `0ae9e2f0153807b6379a67c6f22b6a0b94d8d694`. `6ff9799` belongs to APP Wiki recording the WEB work, not a second WEB release. Claude Analytics checkout/branch untouched. Existing APP30 binary preserved; no new build required by this directive.

Reuses [Round29](app-device-round29-20261030.md), [WEB result refinement](essay-web-result-refinement-20261030.md), [growth display policy](essay-growth-history-ui-20261026.md), [P0 stability](essay-evaluation-stability-p0-20261029.md) and [longitudinal preservation](longitudinal-learning-admissions-data-strategy.md). No new assessment or billing policy.

## Seven preservation answers

1. Only an offline correction proposal is a new artifact; original evaluation occurrence, package, answer and request timestamps are unchanged. Candidate review date2026-10-30 is not an evaluation date.
2. Private original package, PDF SHA/page, before-text SHA, manifest and diff retain reconstruction evidence.
3. No UPDATE. New version4 candidate is separate from operating version3; catalog browser projection is derived from immutable research and current catalog.
4. No student identity or run linkage changes. Candidate retains exam/question IDs.
5. Learning evidence provenance only; no admissions Decision/Outcome claim.
6. PDF/package bodies stay in the existing private materials area, not Git/public browser data. Public report contains only identifiers/counts/hashes; no student text. Existing rights/retention constraints remain.
7. Heuristics are MANUAL_PDF_REVIEW candidates, never confirmed facts or activation. Version/digest/provenance and uncertainty retained.

## Official evidence and cause

Three existing completed runs / three packages / seven questions inspected. This is a bounded audit, not a claim that all universities are clean.

| University | Run / exam | Package | PDF hash / physical pages | Finding |
|---|---|---|---|---|
| Seoul Women's2026 | `6ef28b49-12a5-4825-886d-548f0d9897df` / `6679b5ff-d797-53c9-8a2a-424375d7210c` | v3 `dffdb94b185ba6e316bae052db1d5c1a92259c5cc974476ecc3c86877877a233` | `bd57ddfa7982c2c2c72bcb39b9c41693b19efe3eccf3c59095f2eadcab31be15` /6,14 (printed5,13) | B/C confirmed: merged left-column 준거 labels interleave right-column sentences. D line-wrap candidates remain. |
| Kyunghee2024 mock | `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1` / `51e7299e-0ae7-5e6d-9d37-a46718be76bb` | v1 `55b0f040abda62fbe4919424c1410aa55bd4d8fab055947cbe30bea41560382d` | `9132a43c0e08f39add57513356f09632e6d446922eef5a0847b0e6216cebef48` /3 | Visual page is question paper: demand801–900chars/40pts and1001–1100chars/60pts. It is not the SWU rubric table. Whether a separate official rubric should be bound needs source-policy review; no invented correction. |
| Dongguk2026 | `c5b5ec08-ebd9-44da-ba79-061194ed8293` / `e75f643f-034b-5dc0-afc2-0a0ddeabc3dc` | v2 `8401b5cfc9eb9a8f649dddf234d5349ef5eab313fbe7f640f1cc69b10f2d09f2` | `a03ea699f15417a15a7dfdc47bd9d19d5f5e52693529f76eaa20189c702524ac` /6,12,17 | Page17 visually confirms multi-column criteria/points and S–F grouped grades flattened into text. No guessed structured table. Other pages still need visual review. |

Question identity/source-key mapping (not UUID sort):
- SWU: `source:swu-2026-admission-humanities:q1` → `a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6`; criteria pages [6].
- SWU: `source:swu-2026-admission-humanities:q2` → `d0862954-4d0d-5811-9b48-5dc8e319634d`; criteria pages [14].
- KHU: `source:6d5b7452c99c735cde3c4b96c2331112f2e7483315eae61b72521e4a400cc405:1` → `abb351b6-d462-5916-a03a-956c964f6359`; criteria pages [3].
- KHU: `source:6d5b7452c99c735cde3c4b96c2331112f2e7483315eae61b72521e4a400cc405:2` → `92a9044c-9eaa-58d8-b4e9-365b2e9a02f0`; criteria pages [3].
- Dongguk: `source:dongguk-2026-admission-humanities-1:q1` → `e7b04480-638e-56ad-9d15-1201007bd461`; criteria pages [6].
- Dongguk: `source:dongguk-2026-admission-humanities-1:q2` → `67b9faa8-a781-5d9f-956b-030f033396a0`; criteria pages [12].
- Dongguk: `source:dongguk-2026-admission-humanities-1:q3` → `09cdd3fa-a044-531a-bbcd-6b6789fb874e`; criteria pages [17].

Reproduction: official PDF bytes checked against hash; pages6/14 rendered and visually read. `pdfplumber==0.11.9` `page.extract_text()` reproduces each of the four operating criteria verbatim as substrings, including `제시하
준거 1 는` and `인
준거 2 공 지능`. The error therefore exists at PDF flattening before package storage. Read-only `essay_exam_history` returned four criteria with these two exact anomalies (one match each). APP `examEvaluationReport` and WEB `examReports` use stored criterion labels; display normalization does not originate or safely repair this ordering. A/E/F/G semantic omissions, columns or duplicates require PDF comparison; heuristics alone cannot clear them.

### Separate correction candidate — NOT deployed

Private folder: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/pre-release-stabilization-20261030/`

- `swu-prior-v3.private.json`: original immutable copy.
- `swu-correction-manifest.private.json`: four reviewed replacements (criteria references4/5 for each question), before hashes, PDF/page proof.
- `swu-candidate-v4.private.json`: `CANDIDATE_OWNER_REVIEW`, digest `3353d03a103a2154eeb8c62c69b964e0155c8a725ddb6aff232a9a53dcd95ed1`.
- `swu-candidate.diff.txt`: full before/after; private source path stored in manifest.
- `quality-candidates.json` and three `*-operating-package.private.json`: bounded audit evidence.

PyMuPDF extraction of visually verified table reading order moves each left-cell 준거 label before its right-cell body. After removing ONLY whitespace and 준거 labels, before/after body character order is exactly identical for all four replacements: no added/deleted/reworded sentence. Interleaved-label flags6→0 across SWU package. Soft line wraps remain conservative/manual; this candidate does not claim every whitespace issue resolved. Other question/intent/scoring evidence, IDs and rights metadata untouched. Candidate/reference statuses deliberately cannot pass the existing VERIFIED_MANIFEST/VERIFIED runtime gate. Kyunghee/Dongguk correction packages are not fabricated; source/table review remains open. Existing history continues to pin old version until separately approved future migration policy.

### Offline quality checker

`tool/essay_lab/evidence_text_quality.py`: `text_findings`, `audit`, `correction_candidate`, CLI. No network/DB/Provider imports. Checks split-word candidates, interleaved numbers, repeated sentences, hard wraps, duplicate criterion headings, flattened table markers, subquestion order, missing question/criteria. `--require-role` accepts an explicitly reviewed package-specific required role list for intent/example-answer/scoring; it does not assume every exam publishes an example answer. All evidence roles are scanned. Column order/semantic omissions remain manual.

Run: `python3 tool/essay_lab/evidence_text_quality.py PRIVATE_PACKAGE... --output NEW_REPORT.json` (exclusive output, no overwrite). Public aggregate [quality report](pre-release-evidence-quality-20261030.json) includes per-question counts. SWU387, KHU162, Dongguk513 flags =1062 candidates, predominantly line wraps; NOT1062 confirmed errors. Eight new unit tests cover detection/manual status, absent role, immutable copy, hash/page drift, duplicate replacement and rejected unreviewed candidate. Tests use synthetic text.

## WEB failures — all18 baseline cases plus load failure

Original1373PASS/18FAIL/4SKIP and one no-suite load failure reproduced before refinement in `/tmp/web-baseline.log` and after refinement `/tmp/web-final-tests.log`. All rows below were preexisting, locally fixed and verified; no deleted test/no new skip/no reduced quality gate. C=stale contract; B=fixture; D=offline generator defect; A=test environment.

1. `src/components/konkuk-humanities-mock.test.tsx` — **canonical humanities draft uses existing submit, result, free rewrite and owner History adapters**
   - Failure: `TestingLibraryElementError: Unable to find an accessible element with the role "link" and name "나의 첨삭 기록 →"`
   - C: History link renamed; expected current text/href while preserving draft/free-rewrite assertions. Impact: Test-only; no evaluation change. Result: fixed/PASS.
2. `src/components/scoped-exam-math.test.tsx` — **shows one round submission surface for the selected server-mapped Math question**
   - Failure: `TestingLibraryElementError: Unable to find role="region" and name "수리논술 회차 첨삭"`
   - C: Photo review region replaced old round heading; assert current surface. Impact: Test-only; Math closed gate preserved. Result: fixed/PASS.
3. `src/components/university-catalog-detail.test.tsx` — **puts collapsed schedule before question selection and hides admission details without removing source data**
   - Failure: `TestingLibraryElementError: Unable to find an accessible element with the role "heading" and name "기출문제 선택"`
   - C: Question selection heading is now 시험 선택. Impact: Test-only. Result: fixed/PASS.
4. `src/components/university-discovery.test.tsx` — **keeps essay-first selection compact without changing all42 routes and applies the Owner location order**
   - Failure: `AssertionError: expected [ '서강대학교', '고려대학교', '건국대학교' ] to deeply equal [ '건국대학교', '경희대학교', '고려대학교' ]`
   - C: Owner Sogang→Korea front priority already recorded; update expected order. Impact: Test-only;42routes retained. Result: fixed/PASS.
5. `src/components/university-essay-start.test.tsx` — **restores approved Hanyang PDF and original writer for account without evaluation**
   - Failure: `TestingLibraryElementError: Unable to find an element by: [data-testid="approved-pdf"]`
   - B: Reentry gate now reads existing history; mock read-only dashboard dependency. Impact: Test-only; account PDF flow. Result: fixed/PASS.
6. `src/components/university-essay-start.test.tsx` — **loads canonical metadata even when a prior caller has no cached university UUID**
   - Failure: `TestingLibraryElementError: Unable to find an element by: [data-testid="approved-pdf"]`
   - B: Same missing dashboard mock without cached UUID. Impact: Test-only; no records created. Result: fixed/PASS.
7. `src/lib/materials/materials.test.ts` — **serves only the Owner-approved 487 question mappings and keeps 25 pending mappings closed**
   - Failure: `AssertionError: expected 894 to be 512 // Object.is equality`
   - C: Approved metadata grew512→894 total,487→879 approved,155→312 assets; still checks every approval/source boundary. Impact: Test-only;15pending closed. Result: fixed/PASS.
8. `src/lib/essay-runtime/catalog-api.test.ts` — **APP and WEB receive the same existing source keys and question metadata**
   - Failure: `AssertionError: expected [ Array(269) ] to have a length of 237 but got 269`
   - C: Reviewed catalog now269questions, not237. Impact: Test-only; shared metadata contract. Result: fixed/PASS.
9. `src/lib/essay-runtime/catalog-demand-projection.test.ts` — **matches the committed browser projection, excluding provisional numeric claims**
   - Failure: `Error: Invalid catalog identity/year`
   - D: Historical research null UUID predates canonical catalog linking. Resolve exact source key only. Impact: Offline projection generation previously blocked. Result: fixed/PASS.
10. `src/lib/essay-runtime/catalog-demand-projection.test.ts` — **uses separately verified university totals only, never reported counts or campus sums**
   - Failure: `Error: Invalid catalog identity/year`
   - D: Same identity guard prevented verified-total fixture from reaching validation. Impact: Verified numeric/source rules unchanged. Result: fixed/PASS.
11. `src/lib/essay-runtime/catalog-demand-projection.test.ts` — **rejects mismatched canonical identities and duplicate totals**
   - Failure: `AssertionError: expected [Function] to throw error including 'Duplicate' but got 'Invalid catalog identity/year'`
   - D: Same guard masked duplicate-total rejection. Non-null conflict and duplicates still reject. Impact: Fail-closed validation preserved. Result: fixed/PASS.
12. `src/lib/essay-runtime/catalog-demand.test.ts` — **joins44 research rows to42 canonical universities, keeping two campus records distinct**
   - Failure: `AssertionError: expected null to be '881976e7-8e3d-53e3-8bd8-4ebe5d3a0445' // Object.is equality`
   - C: Research null stays historical; compare current derived projection identity. Impact: No research rewrite. Result: fixed/PASS.
13. `src/lib/essay-runtime/catalog-demand.test.ts` — **keeps Owner22 policy separate from research ranks; preserves30/42/49 and stable filtered order**
   - Failure: `AssertionError: expected [ Array(22) ] to deeply equal [ 'gachon', 'cau', 'skku', …(19) ]`
   - C: Owner22 eligibility separate from default ordering priority. Impact: No research rank used as policy. Result: fixed/PASS.
14. `src/lib/essay-runtime/public-discovery.test.ts` — **uses all 42 source universities without five-sample fallback or invented canonical IDs**
   - Failure: `AssertionError: expected [ { …(6) }, { …(5) }, { …(6) }, …(26) ] to have a length of 27 but got 29`
   - C: Public canonical mapping now29 universities instead of27. Impact: No manufactured UUID. Result: fixed/PASS.
15. `src/lib/essay-runtime/source-registry.test.ts` — **reviewed source metadata and runtime boundary > does not manufacture canonical question UUIDs or turn on evaluation from metadata**
   - Failure: `AssertionError: expected 'kwangwoon' to be 'hanyang' // Object.is equality`
   - C: Kwangwoon reviewed PDF mappings added after Hanyang-only fixture. Match exact verified asset pair; retain legacy Hanyang pin. Impact: EvaluationReady remainsfalse. Result: fixed/PASS.
16. `src/components/math-release/student-route.test.tsx` — **student route integration > image upload → actual row id normalization → correction → confirmation**
   - Failure: `TestingLibraryElementError: Unable to find a label with the text of: /답안 사진/`
   - C: Current image label is 답안 이미지 첨부. Impact: Upload/rowid/correction assertions retained. Result: fixed/PASS.
17. `src/components/my/goals.test.tsx` — **shows saved target and only opens inputs on change, returning to summary on success**
   - Failure: `TestingLibraryElementError: Unable to find an accessible element with the role "button" and name "변경"`
   - C: Saved goal action is inside 대학 관리 accordion. Open it before 관심 대학 변경. Impact: Save contract unchanged. Result: fixed/PASS.
18. `src/components/my/goals.test.tsx` — **keeps editing after failed save and cancel preserves saved value**
   - Failure: `TestingLibraryElementError: Unable to find an accessible element with the role "button" and name "변경"`
   - C: Same accordion prerequisite for edit-failure/cancel. Impact: Failure/cancel preservation retained. Result: fixed/PASS.

Load failure: `src/components/phase1-browse-snapshot.test.tsx` → `No test suite found` when optional snapshot env absent (A). Add deterministic public synthetic fallback, actually exercise current accordion expand/collapse and block unexpected network. Optional captured snapshot supported; no operating result required.

Additional repeat-run race: `registered-exam-selection.test.tsx` logout test waited for metadata request count, then synchronously queried UI before React committed. Await actual disabled button; preserve immediate old-account clearing and disabled-state assertions. This was not one of original18; recorded separately.

Generator patch: `scripts/project-catalog-demand.mjs::projectCatalogDemand`; historical **null only**, exact existing source key, current canonical ID; undefined/conflicting UUID/unknown source/year/offering/duplicate verified totals still reject. Regenerated only two canonical IDs in `src/data/essay-catalog-demand.json`; no numeric claims/verification promotion. Regression verifies research immutability and unknown-source rejection.

## APP/WEB display contract

| Stored field | APP | WEB | Preserved meaning |
|---|---|---|---|
| criteria.binding.id/version | evaluation_report.dart::examEvaluationReport | lib/my/exam-history.ts::examReports | Canonical ID/version retained; labels never identity |
| criteria.label / reviewed alias | criterion display + original details | criterion-display.ts / growth-label.ts | Reviewed aliases only; uncertain original/detail preserved,537 existing pending aliases remain |
| dimensions[].level | rubric.rating | rubric.stars | Saved integer1–5; no score conversion |
| dimensions[].explanation | rubric.feedback | rubric.feedback | Saved judgment |
| dimensions[].evidence_ids + matchingcriterion | evidenceLabels | evidenceLabels | Same saved judgment label/explanation with real references; no invented citation text |
| strengths | strengths | strengths | Saved strength strings |
| improvements / next action | improvement advice | improvement advice | Preserve issue state and action; no synthesized improvement |
| checklist | actions | actions | Saved rewrite checklist |
| parent_id + question/rubric/evidence/contract pins | compareEvaluationReports | compareReports | Same criterion/question/version only; no cross-exam averaging |
| summary | summary text | summary text | Qualitative overall evaluation, not numeric overall score |

Shared synthetic `test/fixtures/exam-history-v1.json` and WEB `src/lib/my/exam-history.fixture.json` are byte-identical SHA256 `300bbaf91d17b52cc12416ff1867d09d422d0853a4c4fe850738737d54a25661`. Both adapter regression suites verify canonical identity, saved rating3, advice, parent and improved direction; evidence reference tests reject missing/unknown criterion. Existing result display tests retain distinct evidence and deduplicate identical judgment text. No new API contract/adapter semantic change was required. Historical source extraction corruption is shared, not repaired by an alias.

## Overall stage proposal — design only

Read-only three saved runs/seven question evaluations: run.summary and question.evaluation.summary are strings; keys include dimensions, strengths, improvements, checklist, sentence_feedback, reviews, but no numeric overall stage. Existing1.3 engine validates dimension levels; official PDF points40/60 or table item points are separate from learning levels. Growth compares dimension levels with pinned criteria. No numeric overall star should be displayed from these results.

Future candidate contract, separately approved: nullable `overall_assessment {level_1_to_5, scale_version, scope, rubric_binding, rationale, provenance}` produced only by an explicit validated holistic criterion, never the mean of dimension scores/official points. Pin same scope/version for comparisons; old results remain null; no backfill/re-evaluation. Engine/schema change requires Owner approval and independent output validation/review tests. Current task adds no field or computation.

## Retry and release validation

Python32PASS: eight quality tests plus24 existing synthetic runtime/retry/diagnostics tests. EXACT_QUOTE/reviewer refusal remain rejected;429 is classified with a single fake transport call; timeout remains reconciling without redelivery; successful checkpoint byte copy retained; only failed generation gets dispatch; lost-finish replay is identical and no extra evaluation. Finalization idempotency and reservation behavior are tested with mocks, not real Credit posting.

APP Flutter3.47.6: Analyze0 issues; full1233PASS/7SKIP. WEB final1393PASS/0FAIL/4SKIP (1397 total), TypeScript PASS, Lint0errors/4existingwarnings, Production Build PASS. The extra two tests versus original1395 are the now-registered offline browse case and new source-identity regression. Existing observation/idempotency/free-rewrite/Credit/History/partial-results/UI fixtures ran in full suites. No claim of real account settlement/device behavior from these tests.

APP skips are existing external/private snapshot or opt-in live checks; WEB4 skips require Owner private converted/operating result bundles. No skip counted as PASS. WEB lint existing4warnings: source selection effect selected dependency and two unused retry-test args; no errors. These remain review risk, not silently fixed outside scope. Production build is local only.

Rollback: revert this task's commits individually on the corresponding branches. No DB/Worker rollback needed; delete/unselect private candidate only if rejected, leave operating v3 unchanged. APP30 binary unaffected. No merge into Claude Analytics/release branches beyond existing authorized WEB work branch; push is source publication, not evidence of deployed Production.

## Release risks / manual work

- SWU candidate requires Owner/source reviewer approval before separate activation; existing malformed package still operating. Soft wraps unresolved conservatively.
- KHU exact source-role sufficiency and Dongguk all-page table reconstruction pending; A/E/G semantic correctness cannot be automatically cleared.
- Only three package snapshots audited. Wider university source audit/537 pending aliases not completed by this bounded pass.
- No device QA/new evaluation/provider/real free-rewrite/settlement check. APP30 QA remains paused; private fixture skips are explicit.
- Existing lint effect warnings require focused follow-up if behavior reproduces; no Auth behavior change made here.

## Final verification and Git receipt

- APP implementation commit: `9e555ac4722d1f1884218df67b69bca83d373a64` (offline tool/test only; no APP runtime change).
- WEB generator commit: `f7c9dbd`; final test commit: `93b37419105835fb9b793f285c85cf27ab649bb4`.
- Full WEB suite1393PASS/0FAIL/4SKIP; TS0errors; Lint0errors/4warnings; local Production Build PASS. APP Analyze0; full1233PASS/7SKIP. Python32PASS. Wiki routing/internal links/current-status budget check PASS (11852bytes).
- Push completed; LOCAL/REMOTE equality verified for APP `8fe2cdb86b8411862657e717de880cfc32bdef55` and WEB `93b37419105835fb9b793f285c85cf27ab649bb4`. This receipt is recorded in the following documentation-only commit. No Production deployment inferred from commits.
- Durable private execution logs copied under the private candidate folder `verification/`; no user answers or secrets added to Git.
- Rollback WEB commits in reverse order (`93b3741`, then `f7c9dbd`); APP offline code `9e555ac` can be reverted independently of this documentation record. Never run old operating rollback SQL for this offline change.
