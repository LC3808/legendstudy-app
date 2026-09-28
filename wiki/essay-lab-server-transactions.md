# Essay LAB Phase 2B — server transactions and Supabase integration

**OWNER REVIEW READY — review RPCs validated; Production NOT APPLIED.**
KEEP19, no new/removed tables. Twelve RPCs replace test-only inline transactions at the operation boundary.
Native PostgreSQL17.11: existing77 regression assertions +55 new checks PASS. Actual local Supabase
Auth/PostgREST:37 checks PASS, including real password-issued user JWTs. Five safety guards and36
static tests PASS. [Machine result](../supabase/review/essay_lab_product/runtime/server-result.json)
contains exact check names and source hashes. This is not deployment, AI quality or App/LAB OAuth E2E approval.

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
