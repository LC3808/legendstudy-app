# Essay LAB Phase 2B — server transactions and Supabase integration

**Subsequent Owner acceptance:** shared identity PASS; KEEP19+4/RPCs approved and
[migrations promoted](essay-lab-migration-promotion.md), NOT APPLIED. The execution record below preserves
Phase2B findings; its earlier identity/promotion pending gates are historical, not current blockers.

**OWNER REVIEW READY — review RPCs validated; Production NOT APPLIED.**
KEEP19, no new/removed tables. Twelve RPCs replace test-only inline transactions at the operation boundary.
Native PostgreSQL17.11: existing77 regression assertions +55 new checks PASS. Actual local Supabase
Auth/PostgREST:37 checks PASS, including real password-issued user JWTs. Five safety guards and36
static tests PASS. [Machine result](../supabase/review/essay_lab_product/runtime/server-result.json)
contains exact check names and source hashes. This is not deployment, AI quality or App/LAB OAuth E2E approval.

## G1 Credit Commercial Core — 2026-09-29

### Production apply — Owner authorized 2026-09-29

**PRODUCTION_DEPLOYED / POST_APPLY_VALIDATED.** Applied only
`20260929000300_essay_credit_commercial_core.sql` once, through normal linked Supabase
migration flow. Latest branch HEAD at start was `9af9667`; no checkout/reset to G1.
Approved migration bytes exactly matched `2ce0840`; migration itself was not edited.
[Sanitized apply result](../supabase/validation/essay_lab_product/g1_production_result.json),
[supplemental read-only query](../supabase/validation/essay_lab_product/g1_post_apply.readonly.sql).

Preflight matched linked LegendStudy, existing ledger19, exactly G1 pending, accepted47-object
schema/security plus Scaffolding definitions and canonical baseline. Dry-run listed only G1,
no seeds or unrelated role bundle. Apply succeeded; read-only post-apply **151 checks PASS**:

- Ledger20 local/remote MATCH; pending0. KEEP19; one `billing_policy_version text NOT NULL`
  column/default v2 and existing session immutability; two public RPCs added (14 total).
- All47 expected catalog hashes match previously validated G1 runtime. Existing37 function
  signatures/security preserved; unchanged34 definitions exact; eight approved static function
  bodies exact; new activation helper has fixed deployment-time cutoff.
- Existing RLS/policies/client table rights, worker/finance boundaries, fixed search_path,
  function ownership, managed ADMIN-only membership and helper execute restrictions preserved.
  Manual grant EXECUTE denied to anon/authenticated/worker/service_role; finance only.
- Product19 tables: all0 before→after; financial accounts/grants/transactions/decisions0.
  Canonical universities5, exams21, mappings134, resources10556; full fingerprints unchanged.
  No existing-user backfill, manual grant, test Auth user, student/evaluation data or AI.

The initial supplemental read-only fingerprint query assumed all tables had an `id`; corrected
its sort to row JSON for composite-key tables and reran read-only validation. No schema correction,
migration retry, repair/replay or write fixture. The prior isolated PG84/JWT88 and regression
reports remain behavioral evidence, not a claim of new Production write tests. Static39 PASS.

Signup is now deployed behavior: eligible post-activation Auth identities receive +3 on profile
provisioning; no existing-user retroactive bonus. IAP/price/Paywall/Store unchanged. Essay production
worker/AI/student traffic remain NOT_ENABLED. **Ready for separately authorized Essay Live
Integration: YES; ready for real student traffic: NO.** Next Owner review → PreviewEssayGateway
replacement with real RPC/worker integration; IAP later, separately authorized.

### Historical isolated implementation checkpoint

**IMPLEMENTED / isolated runtime PASS / NOT APPLIED to Production.** Commercial meaning lives in
[Product Credit policy](essay-lab-product-v1.md#credits--g1-commercial-policy-2026-09-29).
Forward [migration20260929000300](../supabase/migrations/20260929000300_essay_credit_commercial_core.sql)
adds **0 tables, 1 column, 2 public RPCs**. KEEP19; historical migrations untouched.
[Sanitized result](../supabase/validation/essay_lab_product/g1-result.json) and
[runnable suite](../supabase/validation/essay_lab_product/g1_runtime.py) cover fixtures A–Q.

### Policy, locks and history

`essay_practice_sessions.billing_policy_version` is the one required extension: existing rows v1,
future inserts v2. Session immutability prevents client policy changes. Inferring from the first
billing decision would misclassify pre-existing sessions with no request, so this pin is necessary.
`essay_request_evaluation` dispatches by this server-owned session value independently of model
regime. The old v1 request functions remain byte-for-byte unchanged. Both existing success finalize
implementations change only the consume reason expression to the decision's policy key/version.

v2 retains account → session → grants(sorted ID) → request locking. Allocation uses earliest expiry,
then created_at/id; reservation honors existing expiry/reconcile semantics. One active evaluation per
session serializes pair allocation. A settled unrefunded paid decision with no active/settled included
child is eligible; a later distinct submitted revision explicitly links that parent. The partial
UNIQUE on parent decision additionally prevents two authorized/reserved/settled v2 included claims.
Released failures are retryable under a new request key; reusing a failed request key returns that
same historical request. Provider retry/timeout never creates an additional student charge.

No submitted answer, prior decision, ledger posting, progress or evaluation is rewritten. Result plus
consume settle together; failure/lease/fencing/refund/erasure operations stay unchanged. A refunded
parent is excluded from future included selection. Already authorized children are not retroactively
cancelled. Balance is ledger-derived per unexpired grant minus active reservations, not a new column.

### Signup and operator boundary

| Operation | Authorized caller | Validation / idempotency |
|---|---|---|
| `essay_claim_signup_credit()` | authenticated self | server `auth.uid()` only; activation cutoff; fixed +3; same UUID/key returns grant |
| profile AFTER INSERT trigger | existing profile provisioning transaction | same private grant operation; profile + grant + ledger atomic; no auth schema trigger |
| `essay_admin_grant(p_user,p_quantity,p_origin,p_key,p_reason,p_expires)` | server-only `essay_finance` JWT with operator `sub` | existing profile/account; quantity1..100000; UUID request key; origin/reason allowlist; expiry validated |

Signup activation timestamp is captured once by the migration in a fixed-path boolean Auth helper.
It exposes no Auth row or profile fields. New profile creation via existing app provisioning activates
it; delayed/retried provisioning uses the same key. Existing Auth users are intentionally ineligible.
Two layers prevent duplicates: `external_reference=signup_bonus/<auth UUID>` global UNIQUE plus
partial signup UNIQUE per account. No provider/device key. Profile/Essay erasure is not permission to
mint a second bonus under the same UUID; detached financial records remain retained. A genuinely new
Auth UUID is a new eligibility identity; natural-person anti-abuse remains out of scope.

Manual grant audit actor is read from the **signed finance JWT**, never from request parameters.
Finance role issuance is trusted server/operator infrastructure; ordinary clients cannot mint it.
Anonymous, authenticated, worker and service_role have no EXECUTE. No new role membership or broad
helper grants. All new functions use fixed empty search_path; grant logic is owned by essay_executor.
The narrow Auth eligibility bridge is migration-owner SECURITY DEFINER like the existing uid bridge.

Allowed manual pairs: admin_grant/test_account or manual_support; promotion/operational_promotion;
compensation/customer_compensation; b2b_program/program_allocation. Purchase and signup cannot be
minted through this operation. For a test account +10, an authorized operator calls the signature
above with quantity10, admin_grant, a fresh UUID key and test_account; retain that key on retry.
No Owner SQL Editor operation is required. An identical key/payload returns the original grant;
changed recipient, amount, origin, reason, expiry or actor conflicts. Grant+positive ledger posting
share one transaction. No direct balance write. B2B later links organization/program/batch metadata
to existing grant IDs and per-recipient keys without replacing personal account or ledger identity;
no bulk grant interface or organization schema is built now.

### Seven preservation questions

1. Facts: grant origin/amount/actor/time and each versioned authorization, reserve, consume/refund;
   successful included benefit has an explicit parent paid decision.
2. Reconstruction: immutable ledger and billing decisions retain policy/request/session provenance.
3. Updates: existing history is untouched; only normal pre-completion request/decision state changes;
   refund is an appended posting. No rewriting old v1 into v2.
4. Identity: profiles/auth.users.id reused; providers/devices do not redefine the student.
5. Domain: financial/entitlement history linked to learning facts, not Admissions Outcome or telemetry.
6. Boundary: own reads, narrow server writes, financial retention separate from learning erasure;
   no new PII, body copies, analytics SDK properties or device fingerprints.
7. Derived values: balance/usage computed from the ledger; no new cache/source of truth or invented
   historical backfill. Policy snapshot records the rule that actually applied.

### Verification and repeatable local package

- Pre-G1 regression: native Phase2A77 + Phase2B55, Scaffolding80, submit timing306;
  local Auth JWT/PostgREST37 before +37 after legacy correction, Scaffolding79, timing306 PASS.
- G1 actual operations: native84 / local Auth JWT+PostgREST88 PASS. Includes six paid/included slots,
  failure/retry at every slot, included/last-credit races, old v1 in-flight +1/0/1/1, v1.2 contract on v2,
  signup+3/concurrent retry/DB uniqueness, manual+10/retry/payload attacks/origins/role denials,
  injected grant and settlement rollback, timeout/stale rejection, bounded refund and erasure.
- Post-G1 legacy Scaffolding suite: native80 / JWT70 PASS. Test-only session default temporarily
  pins v1 to emulate legacy sessions and is restored to v2; the shipping migration is not changed.
  The local migration login cannot directly invoke private envelope helpers after G1; the suite
  verifies that denial instead of privileged envelope probes. Native80 covers those probes.
- Static: validation39 + review55 tests PASS. Finalize function equality allows only the reason-code
  expression change. Existing submit/security/Scaffolding migrations are unchanged. pglast parses the
  SQL and non-trigger functions; its known trigger AST JSON serialization limitation is covered by
  real PostgreSQL compilation and signup trigger execution.

Use an **empty disposable** UTF8 PostgreSQL database (`essay_review_*`,127.0.0.1) or dedicated local
Supabase project (`essay-review-*`, verified Docker label/port). First run existing
`submit_timing_runtime.py --native|--supabase`; then `g1_runtime.py` with the same guarded environment.
See the [existing runtime prerequisite](../supabase/review/essay_lab_product/runtime/README.md) and
[Scaffolding runtime package](essay-lab-scaffolding-persistence.md) for local credential-file setup.
The G1 runner refuses non-local targets and an already-applied G1 schema. All identities/answers are
synthetic. Result files contain check names, counts and hashes only; do not retain JWT/DSN/email.

No Production query/apply, AI, IAP/Store, Analytics, Ads, Banner, Deep Link or UI work occurred.
At this historical implementation checkpoint Production remained on v1. Then-next: Owner G1 review →
Production apply decision → G2 IAP. Runtime PASS is not payment/real-student traffic authorization.

## Implementation and caller boundary

Use PostgreSQL RPCs, matching existing Supabase architecture; no new backend framework.
[SQL003](../supabase/review/essay_lab_product/003_server_operations.draft.sql) follows001/002 in the
review package only. All public operations use SECURITY DEFINER, fixed empty search_path and qualified
objects. Authenticated client identity comes from auth.uid(), never a user_id parameter.

| RPC | Caller | Atomic purpose / retry behavior |
|---|---|---|
| essay_open_session | authenticated owner | Published question + session/draft; same session UUID/context returns existing |
| essay_save_draft | owner | Expected revision CAS; stale revision conflicts |
| essay_submit_attempt | owner | Lock session/draft, verify revision/body hash, assign next number, compute hash/count; same submission key/payload returns original |
| essay_request_evaluation | owner | Regime/evidence snapshot + policy decision + reservation; same key/payload or same live logical request reuses evaluation |
| essay_request_rewrite | owner | Completed settled evaluation → one optional AI example request; no extra credit; reuse existing result |
| essay_claim | worker | Authorized request, new run/token/generation +120-second lease; returns only answer/evidence identities and relevant improvement actions |
| essay_timeout | worker | Mark fenced run unknown; retain reservation pending retry/reconciliation |
| essay_finalize_success | worker | Validate result + history + consume/settle in one transaction; same selected run/output hash is idempotent |
| essay_finalize_failure | worker | Failure history + request failure + release in one transaction |
| essay_reconcile | worker | Cancel abandoned evaluation/rewrite after lease expiry; release evaluation reservation; reject active lease |
| essay_refund | finance | Append refund under account lock; cumulative amount ≤ original consume; posting key mismatch conflicts |
| essay_erase | owner | Release outstanding reservations, remove session learning records; detach/preserve financial history |

Clients may read their RLS-scoped learning history and edit drafts. Existing draft trigger requires
revision+1; supported cross-device save uses CAS RPC. Direct submitted answer/evaluation/dimension/
progress/rewrite/ledger/processing writes remain denied. Immutable submitted snapshots are never overwritten.
The general service_role is not the worker identity.

`essay_executor` is NOLOGIN/BYPASSRLS solely to own narrowly scoped definer functions; it is not granted
to authenticated, worker or finance. Worker/finance are NOLOGIN/NOBYPASSRLS and receive only named RPC
EXECUTE, no direct fact-table writes. Finance alone can refund; worker cannot create credit or refund.
Bootstrap temporarily grants executor membership and schema CREATE to transfer function ownership;
both are revoked before commit. Local integration grants worker/finance roles to its isolated
PostgREST authenticator and uses server-signed synthetic role JWTs. Deployment must separately provision
short-lived scoped credentials; never distribute service_role or the JWT signing secret to workers/clients.

Supabase's auth schema is owned by supabase_admin. Its postgres migration role cannot delegate auth
schema USAGE. A private, parameterless definer bridge owned by the migration role returns only auth.uid();
only executor may call it. No auth table reads or broad auth grants were added. JWT tampering, another
user's UUID, temp-schema shadowing and client finalize attempts were rejected in tests.

## Submission and evaluation identity

Submission fingerprint = session + expected draft revision + answer hash. Identical retries return
one immutable attempt; changed payload with the original key conflicts. Attempt hash/count are computed
server-side; active writing time is bounded by elapsed time. Count rule is explicitly Unicode codepoints
including whitespace, with official question counting-rule metadata retained separately. Do not claim
all official length rules are interchangeable with this count.

Evaluation identity is attempt + server-allowed regime. The original request UUID has a payload hash;
new UUID retries of the same live logical request reuse that evaluation. Such alternate UUIDs are not
stored as durable aliases; callers must retain the returned canonical request ID. A new approved regime
allows coexistence without updating old results. Review regimes are essay-v1.2 and essay-v1.2-next-model;
both snapshot contract1.2 and differ in model-policy scope. They are not deployed model selections.

Input snapshot records answer hash, criterion IDs/versions, allowed evidence IDs/roles/locators/hashes/
mapping versions, contract, model policy and deterministic package version. Question identity is the
immutable evaluation FK. Only active official verified question/passage/intent/criteria mappings are used;
reference-answer labels/bodies are excluded. Official document bodies are not duplicated in evaluation rows.
No student name/email/phone/profile is returned in worker input.

Success checks required summary/strengths/checklist, complete unique criteria, level1..5, explanation,
allowed evidence references, distinct issue keys and explicit previous-progress relationship when supplied.
Cross-question criterion/evidence injection is rejected. DB constraints additionally validate categories,
priorities and statuses. Duplicate keys are rejected; semantic paraphrase deduplication remains a contract
quality check, not something SQL proves. Student-language, stance preservation and minimal editing remain
v1.2 requirements; synthetic transaction tests cannot prove generated prose quality.

## Billing and external work lifecycle

Policy essay_cycle/v1 is applied by the operation, not attempt_no pricing. First settled paid cycle in a
session permits one later submitted-answer included revision. Concurrent requests serialize: one included
claim, the other paid (or insufficient credit). Database reason `included_revision` means the Owner's
included_first_revision. Failed/released included claims do not permanently consume that benefit.
Further revisions are paid under v1; no provider retry creates a second student charge.

Lock order: account → session → grants sorted by ID → request. Allocation: earliest expiration first,
NULL expiry last, then created_at/ID. Already expired grants are unusable. A valid reservation retains its
right through settlement even if its grant expires meanwhile. Balance remains derived from ledger;
reserve/consume/release/refund are append-only postings. Refund never rewrites consume.

1. Request authorizes/reserves and commits.
2. Worker claims a120-second lease, commits, then would call the external provider outside any DB transaction.
3. Success writes result, dimensions, issue observations, evidence, selected run and settlement atomically.
4. Explicit failure records failure and releases without consume.
5. Timeout becomes unknown, retaining reservation. After lease expiry retry creates a higher run_no/new token.
6. Reconciler rejects active leases; abandoned unclaimed jobs become cancellable after15minutes. Expired
   claimed jobs can be cancelled/released. A released or old-generation worker cannot publish/settle.

Request/claim age cap15minutes and lease120seconds are review operational defaults. A production scheduler
and provider-aware timeout policy remain to be connected; no scheduler or AI provider is deployed here.
Unknown attempts retain history and may incur provider cost even when no student result is accepted.
No late provider response can revive a cancelled result. Reconciliation versus claim/finalize uses the same locks.

## Atomicity and history

Two real PostgreSQL connections race for the last credit, same logical request, and included revision.
Only one last-credit winner and one included claim are allowed. Same logical request yields one evaluation
and one consume. Test-only before/after ledger triggers inject failures between result/settlement and before
commit: result/dimensions/consume all roll back. No split result/charge survived.

Attempts, evaluations, dimensions and completed processing history remain immutable. Issue observations
OPEN→IMPROVED→RESOLVED→RECURRED remain four rows linked to evaluations/attempts; current status is derived.
Normalized issue identity remains optional, not an AI-assigned permanent student trait. New model-policy
regime results coexist with old results. No broad schema or Pilot redesign/re-execution.

## Exact minimum schema amendments

SCHEMA_CHANGE_REQUIRED: YES; four additive columns across three existing tables, KEEP19.

| Column | Blocker / minimum remedy | History / security effect |
|---|---|---|
| attempts.submission_request_hash | Answer hash alone cannot distinguish same key with changed revision/context after mutable draft changes | Preserve immutable submission payload identity; owner read, server write |
| evaluations.input_snapshot | A manifest hash alone cannot validate returned evidence/criteria against identities used at request time | Bounded identity JSON, no official/private body duplication; completed history guard applies |
| processing_runs.lease_token | run_no alone is not an unguessable finalize capability | Server-only token, no authenticated table read |
| processing_runs.lease_expires_at | Existing timestamps cannot represent authorized worker lifetime | Immutable per-run bounded lease; retry creates new run |

Nullable compatibility preserves existing reference fixtures/older rows. New RPC writes these values.
Old unsnapshotted queued records are not automatically eligible for product processing; migration rollout
must handle such legacy rows explicitly. No new public data access. These amendments require separate
review/promotion approval;001/002 and historical Phase2A results are preserved.

## Erasure and privacy

Owner session erasure removes draft, attempts, evaluations, dimensions, issue observations, generated
examples, events and dependent processing records. Outstanding reservations are released first. Financial
ledger/decisions survive with learning references detached, no answer body copied. Another user cannot erase
or read the session. Active worker finalize after erasure fails. Whole-Essay deletion can enumerate owned
sessions through the same operation; account deletion orchestration remains a separate lifecycle.

This validates relational deletion, not legal retention completion. Provider/backup retention and future
private image-storage deletion remain review gates. No image assets or actual provider transmissions occur
in this package. No growth cache exists to invalidate. Core learning, operational and financial retention
must remain independently governed. No actual student data should be enabled before remaining rollout gates.

## Verification record and reproducibility

[Runtime instructions](../supabase/review/essay_lab_product/runtime/README.md) and machine report contain
commands/check names. Native run applies003 before rerunning the accepted77 assertions, then55 actual RPC
checks. Supabase local uses genuine Auth users/password JWTs + PostgREST, not SET ROLE as a JWT substitute.
Worker/finance JWTs are synthetic local server roles. Integration covers S1–S12 and additional scoped worker,
refund/idempotency checks (37 named assertions total, including4 Auth provisioning checks).

| Requested matrix | Evidence |
|---|---|
| T1–T6 | CAS/stale, submission/hash/count, same/different payload, cross-owner |
| T7–T11 | Paid/included, simultaneous included claim, insufficient/last credit |
| T12–T18 | Failure release, timeout retry, stale late success, rollback injection, idempotent settlement, refund bound |
| T19–T24 | Invalid level/criterion, cross-question evidence, version coexistence, owner/other erasure, retained finance |
| S1–S6 | Actual JWT/REST anon/owner/other reads and direct answer/evaluation/ledger write denial |
| S7–S12 | Submit authorization, server-only finalize, tampered JWT, payload conflict, logout/account switch |

Lease/expiry tests replace the private time function only inside disposable fixtures, then restore it;
shipped SQL has no test GUC or fault switch. Concurrency uses barriers and independent transactions;
it is evidence for tested schedules, not proof for every possible schedule. Logout tests clear the client
session and switch tokens while a separate A answer remains; they do not claim all previously issued access tokens immediately cease validity.

Runtime-found corrections: grant UPDATE needed for grant-row FOR UPDATE (immutable term trigger remains);
qualified JSON aliases avoid PL/pgSQL ambiguity; temporary role ownership bootstrap; private auth.uid bridge.
No permission check or immutable/history constraint was weakened to make tests pass.

Provider/model currently record `unconfigured`/approved regime because no model deployment was selected.
Token/cost/latency fields already exist, but the real provider adapter, validated telemetry ingestion and
cost reconciliation still need implementation before live AI operation. This package validates transaction
safety, not a complete operational worker service.

## Shared App/LAB identity — separate gate

Static backend match PASS: App app_config.dart validates stlhijzpjfgwwdgunlsd.supabase.co;
LAB auth-config.ts validates the same project. App/LAB use Supabase auth.users.id and existing profiles.id.
Provider transport differs (native/PKCE/browser) but session authority is shared. No secret/config dump or
Production request was used. Focused existing App shared-account tests3 PASS; LAB auth/Kakao tests33 PASS.

| Provider | Code/static route | Phase2B real same-account E2E |
|---|---|---|
| Email/password | Supabase password authentication, same configured backend | NOT_VERIFIED |
| Google | App native / LAB OAuth → Supabase | NOT_VERIFIED |
| Kakao | App PKCE / LAB OIDC ID token → Supabase | NOT_VERIFIED |
| Apple | Native/browser provider → Supabase | NOT_VERIFIED |

Existing Owner Apple/Google same-identity acceptance remains historical accepted evidence; this phase does
not erase it or claim a fresh physical-device run. Production provider configuration was not queried.
APP_LAB_SAME_AUTH_USER_ID for complete provider matrix remains NOT_VERIFIED; real student rollout BLOCKED.

Owner E2E is deferred to review approval, not a request to execute SQL. Operator first prepares a private
comparison harness using each client's server-validated auth.getUser() identity, one-time salted digest,
no token/email logging, and SAME_USER boolean. Existing App debug diagnostic exists but its manual UUID
workflow is not the desired final harness; cross-surface automatic pairing remains to be connected (no UI
work authorized here). Then Owner only signs into App and LAB with the same provider, and performs A logout
→ B switch. Operator verifies match and that A history is inaccessible to B. Do not ask Owner to copy UUIDs,
find SQL or inspect DB console; do not mark PASS from merely matching email/provider labels.

## Error and product contract

PT401 UNAUTHENTICATED; PT403 FORBIDDEN; PT404 NOT_FOUND; PT402 INSUFFICIENT_CREDIT;
PT409 CONFLICT/STALE_DRAFT/PAYLOAD_MISMATCH/INVALID_STATE/STALE_WORKER/EXCESS_REFUND;
PT422 INVALID_INPUT/INVALID_REGIME/INVALID_OUTPUT/INVALID_EVIDENCE. PostgreSQL type/constraint failures
also need a server/client adapter to safe generic errors; no raw SQL text should reach student screens.
No UI adapter is implemented in this phase.

Examples are on-demand, collapsed by product policy, ai_generated, one normal result per evaluation;
failed/cancelled requests do not silently regenerate. Direct rewriting remains the primary student action.
No extra credit. Contract1.2 retains stance preservation/minimal editing; official weight remains separate
from level1..5. No additional Evaluation/Rewrite model calls were made.

| Gate | Status |
|---|---|
| Schema static / native PostgreSQL regression | PASS |
| Server transaction boundary / billing / idempotency | PASS (review implementation) |
| Worker lease/fencing / result-settlement atomicity | PASS |
| Actual Supabase Auth JWT / PostgREST | PASS (isolated local) |
| Shared App/LAB identity | STATIC_PASS / provider E2E incomplete |
| Relational erasure | PASS |
| External retention / real provider adapter / worker credential deployment | REVIEW / NOT_IMPLEMENTED |
| Migration promotion | NOT_PERFORMED; Owner approval required for minimum amendments |
| Production apply / mutation | NO |

MIGRATION_PROMOTION_READY: CONDITIONAL on Owner review of four additive columns and deployment role setup.
The prior environment-only Supabase gate is now closed locally. Real-student readiness remains NO.
Next: Owner/ChatGPT review → shared identity and remaining privacy/worker deployment preparation → explicit
migration-promotion instruction. Never automatically promote/apply or connect real student writes.
