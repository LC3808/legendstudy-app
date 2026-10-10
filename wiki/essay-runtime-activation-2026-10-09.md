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

Owner expanded this task to device-once introduction, Splash and first-run flow.
APP worktree `/private/tmp/legendstudy-user-flow-app`, branch
`codex/essay-production-user-flow`, base6b003888. Original Claude checkout and its
.fvm/.fvmrc/supabase/.temp remain untouched. LAB independently starts at8991b51.

Native Math reuses math_catalog, math_input, math_learning and the existing WEB
/api/math/evaluate gateway. Availability is checked against the existing signed-in
allowlist endpoint. Auth tokens are only sent to the pinned LegendStudy origin;
redirects are disabled. No worker key, new AI engine or client-side billing.
Typed inputs are frozen before writes; retries retain submission/evaluation keys.
Pending History evaluations can resume the same gateway request. Completed
results use the existing report/Growth reader; included rewrite follows canonical
predecessor/prior-evaluation lineage and server eligibility. request_reevaluation
atomically rejects any paid fallback. Credit/History refresh on completion/error.
Other essay types remain unverified and unavailable for public evaluation.

Seven preservation answers: (1) server submission/evaluation timestamps retained;
(2) original attempts and evidence never overwritten; (3) rewrite creates a linked
attempt; (4) current Auth UID scopes all reads and responses; (5) learning results
remain learning evidence, no admissions prediction; (6) existing owner/RLS/private
storage unchanged; (7) reports are derived reads, no new raw-data collection or
ledger writes. The only new persistence is install-local introduction completion.

Google diagnosis: Cloud Console originally had Web/iOS clients but no Android
client. Actual Mac debug keystore SHA-1 is
0F:EB:E3:EF:8F:2C:92:C7:42:D9:08:D9:B4:68:5D:3E:E1:B6:A9:88,
package com.legendstudy.app. Owner registered LegendStudy Android Debug; both
values were independently confirmed in Console. Web server client/iOS client,
nonce exchange and callback remain unchanged. Release signing file is absent,
so Release SHA is NOT VERIFIED. After registration and network restoration,
SM-G950N actual Google account selection → Supabase session → Home PASS.
No authentication-code redesign was required.

Validation at implementation checkpoint: Flutter3.47.6 wrapper analyze PASS;
1019 tests PASS / 2 existing opt-in skips; Android debug APK, iOS Simulator and
signed iOS debug builds PASS. New tests cover first-frame brand visibility,
slow initialization, local completion failure/retry, both introduction exits,
owner-scoped gateway, exact DTO/retry keys and redirect refusal. Earlier failing
fixture tests were corrected; final suite has zero failures.

SM-G950N update install preserved data. Returning Guest reached Home/login
choice; Apple is absent on Android. Google login succeeded at 2026-10-10
19:36:50 KST. This Google identity had no existing Profile: new-user setup was
correctly shown, Skip created its Profile, and cold relaunch restored the session
and Home without repeating introduction/profile setup. This does not establish
restoration of populated school/grade/targets on the separate approved review account.
Fresh isolated iOS Simulator verified introduction Next/Start → login choice
(with Apple) → Guest Home; relaunch goes directly Home. iPhone 17 Pro Max signed
update install succeeded after Owner unlock; physical runtime QA continues.
Owner then signed in the approved review account on Android and the isolated
iOS Simulator. Android restored its existing Profile directly to Home. Android
and WEB both show4 Credits and the same two Oct09 Math History rows (initial
and rewrite); actual stored report and three-dimension comparison are readable.
New cross-surface submissions/Provider calls remain unverified. Cloudflare CLI
reauthentication is awaiting explicit Owner approval after automatic review denied
the Pages-write/account-read/user-read/offline-access authorization flow. Automated
mocks are not real Provider acceptance.

Production checkpoint: DB evaluations_enabled=false; Cloudflare three Math gates
false; existing allowlist has one approved UID, unchanged. Worker expiry remains
2026-10-16 18:57:41 KST; rotate via existing dedicated authority before expiry.
Migration010 not reapplied,005 HOLD; Payment/Toss/IAP/Credit Ledger unchanged.
Final operational evidence will update this checkpoint and Unified Wiki.
