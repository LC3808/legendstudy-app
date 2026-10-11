# Essay full-service implementation — 2026-10-11

**PARTIAL — implemented / contract verified; no new real Provider E2E.**
Branch: `codex/essay-full-service-implementation` in APP, LAB and DOCS.
This is the Oct10 Owner full-service directive continued past midnight KST. It
supersedes the V2 preview-only stopping point, not publication or DB approval gates.

## Oct11 Catalog/detail UX final refinement — COMPLETE

Owner-approved UI release is live at https://lab.legendstudy.com/essay-lab/ .
Production source `d39cb5b29565ae48ccd31188402d347e72145388`, Pages deployment
`437bd406-9afe-4a5c-80da-98d098802ac9`, success `2026-10-11T02:10:07.770175Z`.
Source was committed, pushed and exact remote SHA verified before deployment.
Existing Pages static export/Functions procedure; production branch selector main
is not a Git main merge. Later closeout commits are documentation only.
Rollback point: prior UI deployment `9d802cb2-13c8-42b1-8909-6c2bcccde573`, source
`35fd8f97aa791aeb2bdc855c8c06a3ab7a22f867`; rollback not performed. Intermediate
`b4147413`/`e7622b4` was replaced after live QA found unresolved source-note wording.

### UI, data and Owner policy

White cards with gray border/soft shadow, Navy white-text44–48px CTA, visible focus,
type/status badges and4/2/1 intrinsic grid. University detail now separates Hero,
admissions facts, essay characteristics, recruitment/schedule, actual exam-year
questions, disabled AI service panel and official sources. Existing search, filters,
pagination, campus/source IDs,27 DB UUIDs and15 nullable university IDs preserved.
DB-unmapped Eulji still opens both campus records with an honest empty question state.
Existing writer42:58/mobile switch, results/rewrite/comparison, History unchanged.

Owner22 focus universities and GroupA4/B18 are fixed by source ID in existing read
model policy; original30 preparation cohort remains intact (union33). Public42/49
unchanged. Default university-name order; optional 주요 대학 shows22 + Seoul=32.
No verified applicant counts/competition rates exist in retained source fields, so
no invented statistical sort or8000-applicant qualification. This data gap does not
remove any university or redefine the Owner22 list. Internal groups never select
question evaluators. Full named list stays in the existing roadmap, not duplicated.

Reused52 published Master rows within49 offerings,10 Manus research records and27
additional official reference links. Facts preserve per-track scope/source basis,
2027 admissions year and original verification dates; never sum distinct tracks.
Only confirmed/partial official source fields are projected. Unresolved value markers
are omitted even when embedded mid-sentence; original private research unchanged.
No question text, private Evidence Package, answer or prompt newly published.
Existing Evidence Packages remain runtime inputs, not public admission statistics.

### Validation and limits

- Full WEB113 files:1022 PASS,1 optional private-fixture skip; Python projection5 PASS.
- Lint/typecheck/boundary audit/GitHub readiness/Node22 webpack static build PASS.
- Catalog42/49, Owner22, retained30, GroupA4/B18, original source identity/date/campus
  preservation, filters, unknown-statistic omission and disabled service regression PASS.
- Browser local and actual production catalog/Konkuk detail:360/375/390/768/1280/1440
  no horizontal overflow; desktop4/tablet2/mobile1 cards. Mobile Eulji two-campus
  detail and disabled empty state verified. Actual production search 건국 + Seoul +
  Math +2027 returns1; 주요 대학32 and all42 verified.
- 200% text tested using root-font32px in a copy of built output, all6 widths for
  catalog/detail no overflow. This is text-size simulation, not device QA/browser zoom.
- Keyboard Tab focus, semantic headings/labels, external rel protection,44px targets
  and reduced-motion styles checked; no claim of a full screen-reader/WCAG audit.
- Before captured from actual old Production Konkuk and university list; after from
  actual new Production. Source URLs/dates and rendered links checked; this is not
  a fresh availability audit of every external admissions website.

Production env maps compare exactly equal before/after (including allowlist); Math
flags remain false, reviewed/recovery flags unset. No new Provider call, Credit
transaction, migration, RLS/permissions, Worker/Auth/Payment/Toss/IAP change or mobile
debugging. Existing Math regression suite passes; prior real E2E is preserved, not
repeated or claimed as new evidence. Public AI activation remains **HOLD**. Official
Humanities production readiness remains the separately documented PARTIAL task.
No Owner action is required for this UI deployment. Future metadata/recovery SQL,
missing verified statistics and public activation retain their existing gates.

## Prior Oct11 Catalog release and university scope correction

**Catalog release COMPLETE / Scope correction COMPLETE / official Humanities runtime
still PARTIAL.** Owner authorized migration-free production deployment then corrected
the preparation floor to20+, metropolitan15+, mandatory Pusan/Kyungpook; no upper cap.
[Canonical30-university A–H matrix and correction](roadmap-essay-lab.md#2026-10-11-owner-scope-correction--current-service-preparation-scope).
The previous11 note was10 deeply researched universities + Pusan, not a code filter.
Restore the existing30-university Manus inventory, including all19 omitted from that
planning subset.28 unique metro: Seoul21/Gyeonggi-Incheon11 with4 overlap. No evidence
of the older complete named approval list was found; do not invent retrospective
approval. Latest Owner instruction controls. Historical10–15 strategy stays historical.
Gangnam/Eulji deferred special-format, retained public; no existing university removed.

Production https://lab.legendstudy.com/essay-lab/ now shows all42 universities/49
public offerings. Source35fd8f97aa791aeb2bdc855c8c06a3ab7a22f867 pushed/remote-verified,
Pages9d802cb2-13c8-42b1-8909-6c2bcccde573 successful2026-10-11T01:30:33Z. Existing
Pages static/Functions deployment, no Git main merge or DB migration. QA nullable
metadata consumers remain compatible with legacy RPCs; missing metadata stays unknown.
Prior blanket deployment hold below is superseded for this authorized catalog release.
Metadata/recovery migration approval gates themselves are unchanged.

Live domain:42 unique names/4 pages, search/regions/4 types/admissionyear filters,
Pusan/SKKU/Eulji detail, official-link href preservation and empty question states.
Economics0 is current verified mapping, not a guessed humanities conversion. No
ready-evaluation promise.6 widths360/375/390/768/1280/1440 pass catalog and Pusan detail;
200% root-font32px simulation on a separate built copy passes catalog/Kyungpook detail
at all6 widths (not live browser zoom/native-device QA). WEB1016 PASS/1 optional private
fixture skip; lint/types/boundaries/audit/Node22 webpack build PASS. Scope rows/counts,
source IDs, source links and30-set preservation independently checked against Catalog.

Before/after Pages production env is exactly unchanged, including allowlist. Math
switches false; reviewed-runtime/recovery switches unset. Production read-only
postflight: Math COMPLETED8/FAILED1, general questions/evaluations0. No new actual
Provider calls, Credit transactions, SQL changes or mobile debugging. Command-line
admission probe was Cloudflare403 before application and is not application E2E proof.
No new live Humanities verification is claimed; existing Math E2E/History preserved.
Rollback available to previous Pagesa2e09fea (501d272), no DB rollback needed/not run.

Next:30-university evidence gaps stay in A-stage; first actual official runtime target
SKKU2025Q1 remains rights/content/host gated, Q2/Q3 graph-blocked.3 private historical
packages and5 scoped research rubric findings retained, no invented content.
General evaluation activation HOLD; Payment/Toss/IAP/Credit Ledger unchanged.

## Oct11 continuation — runtime adapter, approved UI and full catalog

**Runtime PARTIAL / Catalog LOCAL IMPLEMENTED, Production NOT DEPLOYED.** Continued
from APP9081ee8/LABa942aa7/DOCSc50d6d4 after fresh remote and Unified Wiki verification.
The earlier sections below are the previous checkpoint; this section supersedes
its five-university UI and “host adapter not implemented” statements only.

### Runtime and actual state

`tool/essay_lab/runtime_host.py` now implements bounded private POST admission/evaluate
and WSGI dispatch over the existing ReviewedRuntimeWorker. Pages supports an existing
service binding or explicit HTTPS private origin + separate service token. Caller
JWT/allowlist/owned snapshot stay distinct from the narrow worker credential.
Admission fails before reservation unless rights, text-compatible reviewed content,
provider policy and provider/reviewer/persistence preflight pass. Durable checkpoint
replay never repeats a Provider call. No new engine, wallet or public listener.
**Concrete host dependency composition/provisioning is still incomplete**: no actual
Auth/PostgREST host acceptance, current independent review storage or deployment
was supplied. Dependency injection tests do not establish an operating service.

Production read-only recheck: general questions0/evaluations0, Math COMPLETED8 and
FAILED1 (no in-flight Math state observed). Existing claim/finalize functions present.
Cloudflare authenticated read recovered through existing Node22/Wrangler credentials;
Production remains source501d272/deploymenta2e09fea. Both Math evaluation switches
false, general runtime/recovery switches unset; allowlist and opaque worker secret
present. Actual JWT validity/expiry unknown. No credentials or permissions changed.

SKKU2025 3-question/9-criterion/1-package plan reused, not re-extracted. Q1 text cache
supported, Q2/Q3 graph-dependent and blocked. Source rights remain unresolved; no
public passage/body delivery, first actual Humanities evaluation, revised evaluation,
Credit settlement, shared actual Humanities History or admin-human QA E2E claimed.
[Concrete activation impacts/rollback and remaining prerequisites](../supabase/verification/essay_service/runtime-integration-review.md).

### Sep28 approved UI → current implementation

Source APP commits `f153c43` and `ebbc43c` were inspected, together with the existing
UI v1 Wiki and native implementation. Native APP files are unchanged.

| Approved screen / behavior | Current WEB connection | Validation / remaining |
|---|---|---|
| Desktop problem42% / answer58% | CSS grid, independently scrolling panes | Implemented; authenticated visual E2E pending |
| Mobile question ↔ answer | Tabs preserve mounted draft text | Implemented; existing Draft/CAS tests preserved |
| Summary → strengths → criteria → weaknesses → priority → rewrite → evidence | Existing shared MY RecordDetail and human report reused in workspace | DOM order regression PASS; actual result absent |
| Five-level item/status/right stars, optional details | Original native labels, exact stored level, collapsed details | PASS, never official point prediction |
| Primary 다시 써보기 | Submitted answer retained; student edits draft | Existing submit/rewrite contract PASS |
| Initial/revised stars/status/reason | Actual selected_previous_evaluation_id required; exact pins | Different session/question/rubric rejected; missing connection not invented |
| Teacher-style explanation | Stored summary/why/actions + existing positive-learning prompt | Real Provider tone NOT validated |
| Model-answer area collapsed | Existing stored AI-generated example explicitly labeled; separate official area | Official body unavailable; source link only, no invented example |
| Shared WEB/APP results | Same existing evaluation/criteria/progress/History contract | Native implementation reused; no device debugging |

### Public Catalog and shared identifiers

`tool/essay_lab/public_catalog.py` deterministically projects the retained V2 catalog
into LAB `src/data/essay-public-catalog.json`:42 universities,49 public offerings.
The original53 Master/50 Offering/101 Track source remains unchanged; future-date
LSL27-052 remains quarantined, Hongik is retained through its verified Seoul row.
No new research or invented university/count padding. Source SHA is embedded.
Read-only active Production identities50 were reconciled by exact Korean name:
27 canonical UUID matches,15 explicit nulls. Original Manus sourceUniversityId is
shared across clients; null means no backend routing, never a fabricated WEB DB ID.
Campus-specific offering/source IDs remain separate under each original university.

Home/list and common university/year detail now use the actual42-university read
model instead of the five sample array. Legacy test fixtures are retained outside
these discovery routes. Search + region + literal source essay-type +2027 admission
filter +12-per-page pagination use the same offering for combined matches.
Verified 기출 exam years are queried separately through existing RLS (currently no
published general questions);2027 admission rows never claim2027 past questions.
Literal 수학 논술/수리 and explicit 과학 labels are mapped for discovery only. Unknown
or administrative tracks do not route to evaluators. Econ/Business is not inferred
where the source lacks a verified type. Official links/check dates and nullable
question state are retained. No internal CORE/NEXT tier shown; Owner core selection
remains undecided. Existing Math entry/availability gate remains separate and intact.

Question availability uses live published-question RLS reads, not an invented READY
flag; network/config failures show unknown, missing questions show preparing. No
university is advertised evaluation-ready without runtime proof. Canonical question
metadata and write route still enforce the existing server admission.15 unmatched
universities have source metadata/detail but no fabricated question link.

### Current validation and release limits

- Python26 contract tests PASS: host7 + catalog3 + provider binding8 + reviewed
  runtime8. Provider HTTP is synthetic, no external call. A system-Python run first
  lacked psycopg for the unchanged SQL suite; the new pure contract suite then ran
  clean. Previous19 content/21 recovery PG evidence was not relabeled as new E2E.
- Full WEB1014 PASS +1 optional private V2 fixture SKIP;110 test files. Lint,
  typecheck, boundary audit and Webpack build PASS; final checks use existing Node22.
- Browser catalog + detail360/375/390/768/1280/1440: no horizontal overflow. Catalog
  and detail200% root-font simulation (32px) on temporary built-page copies: no overflow;
  test style restored, not committed. Real search, pagination and combined region/
  type/year filter verified. Authenticated writer/results 200% visual QA is pending.
- Anonymous actual PostgREST GET: questions HTTP200/0 rows, verified exams HTTP200/21.
  Localhost Auth is intentionally closed by existing origin binding, not bypassed.
- No actual Provider, Credit, migration, deployment or native-device action. Existing
  QA metadata migration/paired deployment and Wiki PR#1 remain pending. No bulk
  migration or hidden approval bypass to put this accumulated branch in Production.

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
