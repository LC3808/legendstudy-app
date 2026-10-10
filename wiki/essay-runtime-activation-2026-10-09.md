# Essay runtime activation — 2026-10-09

ESSAY_ACTIVATION: PARTIAL. Actual provider-backed authenticated evaluations:0.
All four types remain GATED; code deployment is not service activation.

## Existing access re-audit

Prior006–009 applications used prepared SQL executed in Owner SQL Editor; key/worker
operations used the authenticated Owner Mac Supabase CLI. That Mac path is absent in
the cloud filesystem. Current CLI token/config files and management/provider/test
bindings are absent. Supabase management GET returned401; Cloudflare management GET
returned400/code9106 (missing authentication headers). Both repository Actions workflow
inventories return0. Git proxy read/push and Cloudflare Git deployment work, but do not
grant DB or secret access. No privilege was inferred from an old successful deployment.

Current environment draft initially had zero secret/runtime requirements. Three existing
access requirements were saved as metadata only: SUPABASE_ACCESS_TOKEN (api.supabase.com),
CLOUDFLARE_API_TOKEN (api.cloudflare.com), MATH_TEST_ACCESS_TOKEN (project Supabase + LAB).
No value was output/stored/generated; draft requires secure configuration review/save
and environment publish before it becomes usable. Existing install/start configuration
preserved. No Owner SQL, terminal, login or mid-task response request.

## Implemented

[Component persistence candidate](../supabase/candidates/essay_components/README.md)
adds canonical claim/finalize/read bridge with a single parent transaction.38 isolated
PG17 checks PASS, including actual canonical Credit consumption, concurrency and rollback.
The Web server adapter checks student ownership before worker claim, pins the reviewed
manifest, checkpoints before commit and replays only the durable checkpoint on ambiguity.
Existing History IDs locate the optional component result; legacy null is distinct from
RPC failure; account switch discards stale response. No second child billing RPC.

Science/mixed can persist validated component feedback under a valid canonical1.3 parent.
They cannot manufacture that parent rubric or turn scientific verdicts into numeric levels.
Real reviewed catalog/output binding and private artifact→canonical submission linkage
remain activation prerequisites. No real science/mixed exam was published.

## Content/provider authority

Existing Humanities evidence manifests retain reviewed Sookmyung/Hanyang provenance,
source hashes and v3 prompt authority. Full accepted private packages/original answers
are not present here; metadata alone is not publishable content. Latest Owner DB evidence
had published Humanities questions0/criteria0; this is historical inventory, not a fresh
privileged count. Existing Math OpenAI Responses adapter/gate/worker/RPC paths remain;
Cloudflare secret values cannot be read through Git. Real provider configuration and
approved authenticated account are unverified; no live provider call/charge performed.

## Verification

LAB854 PASS; lint/typecheck/boundary/build PASS. Python70 PASS/29 private-fixture skips.
Canonical component SQL38 PASS; Math SQL↔Web16 PASS; unchanged010 local projection10 PASS
(stubbed lifecycle in that projection test, NOT live RLS E2E). No provider quality claim.
New candidate installation pins existing function bodies, adds no migration ledger row
and leaves all core functions unchanged.010 SHA256 remains
cc911a6d7ad90c768b388e52520a7e72c40ebb885b4d862c0e07231b34e49734;
MIGRATION_010=BLOCKED_NO_PRIVILEGE. No Production DB write.

## Preservation / next activation conditions

Seven answers: immutable original attempts/results; occurrence/recorded versions retained;
no historical overwrite; same auth identity; learning separate from admissions outcomes;
owner/active-account/private-artifact scope and existing cascade erasure; feedback is
versioned derived evidence, never invented raw grades. No new shared-data authority.

Existing access bindings must become available; then inspect current runtime config,
DB topology/body hashes and collision state, promote only reviewed additive candidates,
use an approved isolated/reviewer session and real reviewed content/provider for E2E.
No ordinary user Credit may be used. Do not enable any type merely because tests pass.
Payment/Toss/IAP/Signup/Target005/Credit policy and MY/Admin/Manus visuals unchanged.
APP Store RC85aefb1 is a documentation-only finalization over a3cc3b3; preserved.


## Google Auth / Essay Production user flow — 2026-10-10

APP `codex/essay-production-user-flow` (implementation56f1635, base6b003888)
and LAB branch of the same name (implementationb4df1936 + credit-refresh9c66fe2,
base8991b51) are pushed. Fetch latest refs before continuing; APP main untouched.
Native Math reuses existing catalog/input/learning/evaluation contracts and WEB
Provider gateway. No new AI engine, schema, Payment/Toss/IAP or Ledger policy.
Device-local introduction is separate from Auth, exits to login choice, supports
Guest without anonymous Auth, and preserves returning Profile/Home routing.
BrandGate paints official symbol and wordmark before routing, without fixed delay.

Validation: Flutter3.47.6 analyze PASS; **1019 tests PASS / 2 opt-in skips / 0 failures**;
Android debug APK, iOS Simulator and signed iPhone debug builds PASS. LAB16 relevant
UI tests, TypeScript, targeted lint and static build PASS. Mock tests are separate
from the following actual Production UI evidence:

- Android SM-G950N: missing Android OAuth client was the configuration cause.
  Owner registered the verified com.legendstudy.app/debug SHA-1 pair; real Google
  chooser → Supabase session → new-user Profile setup/Skip → Home → cold relaunch
  session/Profile persistence PASS. Review-account existing Profile goes straight
  Home. Release SHA unavailable because release signing material is absent.
- WEB, physical Android and physical iPhone each completed an actual Math initial
  evaluation and included reevaluation through their UI, using the same approved
  Auth UID, existing OpenAI/gpt-5.6-sol Provider and canonical backend.
  WEB evaluation prefixes2c6af9ee/4a35ac2b; iPhone0ffeb194/a9e65551;
  Android7432ad79/07512c6f. All six are COMPLETED; no mocked result insertion.
- Actual Credit4→3→2→1: three consume transactions total−3; three included
  reevaluations add no debit. One earlier Android requestce4d77dd timed out after
  entering PROCESSING. Existing math_recover_evaluation after lease expiry marked
  FAILED/TIMEOUT and released its reservation. Four reserves, three consumes,
  one release net reserved0. No direct ledger edits or duplicate charge.
  The original upstream/finalization failure cause remains undetermined; reliable
  automatic orphan recovery needs follow-up before public activation.
- WEB→Android History and APP→WEB History/report/comparison verified. Final WEB,
  Android and iPhone UI balances all1. WEB persistent header could become stale
  after another device spent Credit; route/focus/visibility canonical reload fixes
  this without changing billing. Existing Oct09 records remain intact.
- WEB actual PNG upload → private Storage → actual extraction → confirm four
  regions → evaluation-ready PASS. This uploaded attempt was not evaluated or
  charged; PDF upload and native image/voice submission are not claimed.
- Final post-essay cold relaunch on both physical devices restored Review Home
  directly, with no login/introduction/Profile setup repeat.
- Fresh isolated iOS Simulator Next/Start → login choice → Guest Home → relaunch
  Home PASS; Skip covered by unit tests. Both physical devices used update installs
  to preserve data. Physical clean-install/brand cold-start capture, populated
  school/grade/targets restoration and provider-switching matrix remain limited.
  iPhone Apple button present; Android absent. iPhone Google/Kakao/Apple and Android
  Kakao actual provider login acceptance remain pending Owner-assisted QA.

Production deployed source9c66fe2 via existing Pages procedure; canonical deployment
`92f79bf7-7bb5-4fce-867f-735a6b4b8b99` SUCCESS. Final MATH_ENABLED,
MATH_PROVIDER_CALLS_ENABLED and NEXT_PUBLIC_MATH_ENABLED=false; DB evaluations=false.
One existing approved UID remains allowlisted; no public widening. Public availability
HTTP200 reports all four types false; signed-in UI has no available evaluation entry.
**PUBLIC_ACTIVATION: HOLD.** Humanities/Econ-Business/Science actual Provider QA
not performed and remain unavailable. Worker JWT expiry2026-10-16 18:57:41 KST:
renew using existing dedicated authority before expiry. Migration010 not reapplied;
Target005 HOLD; worker bindings, RLS/private Storage and existing Math E2E preserved.
No APP main merge, Store submission or release-signing change.

Next: finish remaining physical OAuth/first-install/Profile matrix, investigate
orphan evaluation recovery and renew Worker credentials before a separately
approved public release. No further evaluation activation is authorized by this
closeout. Owner-assisted remaining device authentication QA is requested.
