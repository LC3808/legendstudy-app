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

## APP WEB UX cleanup — 2026-10-10

Owner-approved UI cleanup on `codex/app-web-ux-cleanup`, based on APP938b02b
and LABc652133 (latest remote refs verified before independent worktrees).
Login hero uses the existing section-title token, two centered lines; policy links
follow Guest at the SafeArea footer. Shared primary buttons are navy/white and
secondary buttons white/gray/navy; destructive and provider brand styles remain.
MY has three divided LAB rows and a compact canonical Credit balance/IAP top-up.
LAB home removes balance categories. Display labels are 논술 LAB / 내신 LAB / 수능 LAB;
settings removes only LAB 이용 안내. Submit buttons are 첨삭 진행 / 재첨삭, with
1 Credit + included same-answer reevaluation within14 days still visible before submit.
WEB guide removes the requested redundant purchase/promo copy; refund copy and
responsive wrapping are corrected without changing amounts, periods or legal rights.

Availability cause: production has0 published general essay_questions but1 ACTIVE
Math problem/set. The existing APP catalog and WEB entry depended on evaluation
availability, so switching evaluation OFF also hid approved Math questions.
Availability now adds `catalog.math` after the existing authenticated allowlist check,
separately from `types.math` (unchanged evaluation meaning). The APP reads this field
with a backward-compatible fallback. Approved accounts can browse while evaluation
is OFF; other/anonymous accounts cannot gain access. UI evaluation actions stay
disabled and the APP rechecks availability before any submission mutation. Existing
server Provider/Worker/DB GATE remains authoritative. No migration/RLS/Storage,
Auth/Profile/Payment/Toss/IAP verification/Ledger or evaluation contract redesign.
No Provider call, new submission, reevaluation or Credit debit was performed for UI QA.

Checks: Flutter3.47.6 analyze PASS (0 issues); full regression1019 PASS/2 opt-in skips;
latest focused31 PASS plus2 Android/iOS login render tests. New widget cases cover
360/375/430dp and100/200% text for hero/footer/compact Credit, plus CTA colors and
catalog-open/evaluation-closed behavior. WEB81 related tests PASS; final copy/gate
subset53 PASS; full ESLint, TypeScript and static production build PASS.
Android debug APK and iOS Simulator builds PASS with existing public configuration.
WEB pricing/refund six viewport widths360/375/390/768/1280/1440 at100% and200%
zoom have no horizontal overflow after the scoped minimum-width correction.
Widget render captures use test fonts: they establish geometry, not Korean visual QA.

Public activation remains HOLD; Math flags and DB evaluation switch stay OFF,
existing single-account allowlist retained. No APP main merge or store submission.
Prior actual Math E2E evidence and its unresolved OAuth/first-install/orphan recovery
and Worker-expiry follow-ups remain in the preceding section, outside this UI task.

Deployment/visual verification: LAB source015f6e9 deployed through existing Pages
procedure, canonical deploymentf03197c5-b040-481d-ae62-c77c7173ca88 SUCCESS.
Production guide/refund/naming verified in browser. Anonymous availability HTTP200
has catalog.math=false/all types=false; CF three flags=false, DB evaluation=false,
allowlist count1 unchanged. No secret values recorded.
Android SM-G950N update: two-line navy hero, primary Login and bottom muted
privacy/terms links visually PASS. Guest remains accessible. iOS Simulator MY
shows live credit_summary11 and divided LAB rows. These are read-only UI checks.
Approved catalog runtime verification needs a fresh test login: current Review
server sessions count0; old Simulator JWT still reads RLS data but server Auth
user lookup returns403. This is a stale-session limitation, not a reason to bypass
Auth or open the allowlist. Owner Android re-login requested; no password collected.
