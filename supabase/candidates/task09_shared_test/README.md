# TASK09 shared TEST bootstrap — PARTIAL / HOLD

Target ONLY `kpqbedylxlyntrrfybpn` (existing IAP sandbox). Never run against Production.

## Applied on 2026-11-01

1. `admin_gate.sql`: verified existing admin membership/JWT contract. Fails if function already exists.
2. Existing `../notices_v1/install.sql` unchanged.
3. Existing migrations: 20261012215054, 20261013032726, 20261013033132, 20261013115731, 20261014020622.
4. `exam_api_test_adaptation.sql`: 20261014023133 exam API, preserving existing inactive TEST provider functions.
5. Existing migrations: 20261014044957, 20261015121723, 20261021071701, 20261021071702, 20261028120000.
6. Existing `../essay_feedback_v1/install.sql` unchanged.

Do not blindly replay: inspect Supabase migration history and function definitions first. A migration file is not proof of installation.

## Security and adaptation

TEST already owns provider_policy/provider_binding_valid/hash through essay_executor. Replacing these with postgres-owned functions fails ownership checks and would alter the TEST provider contract. The adapter checks existing definition hashes, retains their bodies, grants only required EXECUTE to postgres, then removes its temporary SET-capable membership. Existing supabase_admin-granted ADMIN-only membership is retained. Public/anon/authenticated/service_role/essay_worker do not gain private provider EXECUTE. Owner-preserving schema dump was replayed locally as postgres; the earlier no-owner dump was insufficient for this check.

No provider activated, Registry/package copied, evaluation submitted, or production schema changed. Existing TEST Credit rows retained. Browser TEST signup generated one normal signup_bonus_v1 +3 row; this is not beta or production Credit.

## Verification

`python3 supabase/candidates/task09_shared_test/test_admin_gate.py` uses disposable local PostgreSQL and canonical notice implementation: real JWT/admin gate, missing/expired/mismatched contexts, schedule/expiry/channel/read sync, denial and rollback.

Remote TEST APIs: Owner login/admin allowed; student admin 403; anonymous denied; one notice published and read through APP channel then WEB unread=0. Feedback same request id returns same row; changed payload conflicts; Owner list allowed; student/guest denied. These API checks are not physical APP E2E.

## Blocked dependencies

Existing TEST lacks math_session_submit and its modern session tables. The canonical essay_beta_credit_runtime_20261027 allocator precheck correctly refuses installation. Do not remove its exact-definition checks or install unit-test stubs into shared TEST. A verified complete predecessor schema/ACL chain is needed before daily-v2/admin-beta/operations/analytics integration. No new credit implementation is authorized or required.

## Rollback / retention

Do not run destructive rollback on the preexisting IAP sandbox. Disable TEST Preview/build flags first. Retain test accounts, feedback and notice audit data until reviewed; use individual canonical package rollback only after dependency/inventory review. There is no all-in-one drop-schema rollback. Adapter provider bodies are unchanged; retain ownership/ACL evidence before reversing API migrations. Production rollback is unnecessary: it was not modified.

Canonical status and Owner instructions: `wiki/essay-shared-test-task09-20261101.md`.
