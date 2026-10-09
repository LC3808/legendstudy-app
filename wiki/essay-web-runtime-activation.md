# Essay Web runtime activation — 2026-10-08

Status: PARTIAL. This release restores the existing Math consumer and server gateways
behind closed admission; it does not establish public, four-type evaluation readiness.

## Current authority

APP Store RC a3cc3b3310453502c3653b788c59aa1059400a7f (backend unchanged from ca60d73).
LAB Math source: codex/math-production-activation-1,34bfab5c962c6a79d91ca1eae3ec3907b4185489.
Only absent Math input/evaluation/learning/consumer/gateway files were reconciled;
no whole-branch merge, operator frontend, shared visual or payment code was copied.
APP gateway essay_live_gateway.dart supplies Humanities session/CAS/idempotency semantics.

Owner Production inventory: 0 published Essay questions,0 Essay criteria; Math has
1 problem set,1 problem,1 leaf,1 ACTIVE profile. These counts do not verify reviewed
content or model readiness. math-private is private,20MiB,PNG/JPEG/WebP/PDF.
Existing C/D/E and Oct04 storage activation migrations are installed.010 is absent.

## Implemented

- `/api/essay/availability`: authenticated, no-store read admission using existing
  server config, Auth-verified narrow subject allowlist, unexpired worker JWT role
  metadata, existing DB kill switch through candidate010, and nonempty Math catalog.
  No provider calls, billing or secret/subject values in the response.
- `/math/` and Essay LAB entry reuse the Math student consumer. Missing config,
  missing010, closed DB switch, unknown subject or read failure cannot advertise Math.
  The existing max10-subject test boundary remains; this is not a public launch.
- `/api/math/upload|extract|evaluate` reuse existing private-storage/hash/owner gates,
  pinned provider configuration, validated output and finalize semantics.
- Humanities Web client adapter reuses canonical RPCs: deterministic APP session and
  request keys, CAS draft save, immutable submit, evaluation/status/result and bounded
  history. Default writes disabled. It is tested with fixtures, NOT mounted as a live
  Humanities editor or backed by a newly deployed worker.
- Account-keyed runtime entry drops in-flight availability after user switch. Login
  uses the existing `next` destination contract. Existing demo editor remains clearly
  labelled browser-only practice; its simulated feedback is not a live evaluation.

## Types and remaining gaps

| Type | Status | Required before public availability |
|---|---|---|
| Humanities/social | BLOCKED | reviewed published questions/criteria, deployed trusted worker/provider admission; current Python worker is synthetic-only |
| Economics/business mixed | BLOCKED | reviewed capability bindings and atomic shared billing/result coordinator; no independent per-child charges |
| Math | IMPLEMENTED, activation BLOCKED | verified content/profile, existing server bindings/model approval, DB switch/admission and authenticated end-to-end verification |
| Science | BLOCKED | reviewed science evaluator/rubric/golden fixtures; no inference from text/image format |

Exam category and question capabilities remain distinct. Humanities/mixed/science
availability is explicitly false. Math does not imply science or economic reasoning.
Negative routing tests are NOT successful integration tests for those three types.

## Credit, storage and learning

SQL remains the sole ledger/reservation/settlement/release authority. No wallet,
manual credit, eligibility change, refund shortcut or client-side charge calculation.
Existing Math tests cover owner denial before worker claim, duplicate completed retry,
validated finalization, transaction rollback, private upload verification, included
reevaluation eligibility/336h expiry, re-solve and append-only learning history.
Ambiguous failure remains pending/reconciling, never an invented successful release.
Humanities included-rewrite policy requires separate live verification; do not infer
its expiry from Math's336h tests. No private artifact becomes a public URL.

## Deployment and operating limits

010 only adds a read RPC projecting the existing kill switch; it does not open it.
Candidate lives in APP codex/essay-web-runtime. No whole db push or005. No Production
DB apply has been performed from this environment: no Supabase credential binding,
DB URL, privileged connector or installed authenticated CLI was available. Environment
configuration metadata also contained no secret/runtime bindings. Cloudflare privileged
configuration access was absent; Git-based deploy is separate from provider activation.

No live provider call, authenticated student E2E, synthetic content publication or
actual Credit consumption is claimed. Owner-away override is respected: no SQL Editor,
terminal, intermediate approval or secret-in-chat request. Remaining operational
access and content/provider prerequisites are collected in the final closeout.

Preserved: Signup CLOSED; Target005 HOLD; Payment/Toss/IAP unchanged; MY/Admin and
Manus Header/Icon/Favicon/global CSS unchanged by this task.

## Verified release evidence

LAB main `ea144bc0c19d64c916fb4485b8bd7b175a465154`, Cloudflare Production
`2e7b5c14-953b-497c-b873-88567c521442` SUCCESS. Existing isolated math-test project
also deployed via its pre-existing Git integration; no new infrastructure/config.
Production browser `/essay-lab/` and `/math/`,390/1440px:4 checks PASS, HTTP200,
correct login-next destination, no anonymous evaluation control or page error.
Actual availability HTTP200/all four false; anonymous upload/extract HTTP409 and
EVALUATE HTTP503, no body/artifact/token submitted. This is denial/read verification,
NOT authenticated evaluation, model quality, credit consumption or end-to-end evidence.

LAB824 tests/80 files, lint/typecheck/boundary/static export and browser secret graph
PASS. APP31 synthetic contract/worker tests PASS; PostgreSQL17 existing Math learning,
legacy102 and installation14 suites PASS; isolated010 projection10 checks PASS with
stubbed existing lifecycle authority. 010 remains NOT_APPLIED; provider calls0.
APP candidate361880b records implementation; this documentation does not apply it.
