# Source registration76/234 — Owner-approved registration APPLIED

Exact migration: `../../migrations/20261012212352_essay_source_registration_76_234.sql` (CLI-generated name in UTC).
Applied only this reviewed file using the existing Owner Supabase SQL/migration
procedure. Do not run blanket `db push`: unrelated pending migrations are not approved.
Owner approved only this private registration on2026-10-13. Production apply succeeded; hosted migration version20261012212352. SQL content SHA256 unchanged from the reviewed127473bc… package. This package registers metadata, not public
content, evaluation rights, source text, Rubrics, user answers or billing.

## Scope

74 new inactive/review exams +234 unpublished question metadata;2 existing exams
reused unchanged. Source University/question keys preserved. Yonsei2025 additional
natural1exam/3inputs remains in manifest.held and outside SQL. Counts describe
exam/subject input records, not234 fully reviewed evaluation packages.
No table/function/RLS/grant/worker/ledger changes. No general user activation.

## Before apply

Verify LegendStudy project `stlhijzpjfgwwdgunlsd`, hashes in `sha256.json`, current
branch and Owner approval. Save current metadata/security export. Existing read-only
preflight found questions0/exams22. Verify any intervening edits before execution.
Migration takes short table locks (5s lock/60s statement timeout), checks exact
existing public policies/SELECT-only client grants and identities, then inserts in
one transaction. Drift/collision/publication changes abort the transaction; never
weaken guards to force apply. Rerunning identical unchanged metadata is safe.

## After apply

Run `postflight.sql`:234questions/published0;74new exams/active0. Existing2 exam
identities and all prior Math/History/Credit records must remain unchanged.
Public API remains source21/77/237, canonical published0,evaluationReady0.
No additional tests that reserve/consume real Credit are authorized by registration.

## Rollback

Use `rollback.sql` only while candidate rows are unchanged and unused. It compares
full row metadata excluding timestamps, preserves existing exams, rejects practice
sessions and relies on restrictive FKs for other dependencies. No CASCADE. If any
learning or review has started, stop and prepare forward repair; never delete user
records or financial history. Exact prior22-exam fixture restored locally.

## Verification

LAB `scripts/essay-materials/test_registration_database.py --app-root <APP>
--pg-bin /opt/homebrew/opt/postgresql@17/bin --migration <exact migration>`:
local PG17 canonical15 prerequisites; replay, unpublished state, anonymous and
authenticated hidden reads/write denial, RLS drift abort, policies unchanged,
edited-row rollback denial and baseline restore PASS. This is not actual Provider
E2E, full production schema replay or authorization to publish the questions.

## Actual postflight —2026-10-13 KST

74 new exams,234 questions,0 published,0 active new exams; total exams96.
Existing RLS expression hashes unchanged. Hosted migration name/version verified.
CLI draft timestamp20261012211746 renamed to hosted version20261012212352 to avoid
future duplicate migration replay. SHA256 SQL content unchanged. No Credit/provider
calls or activation. Rollback has only been exercised locally, not in Production.

Security advisor baseline was read: existing pg_net-in-public, authenticated
SECURITY DEFINER API notices and leaked-password protection notice remain outside
this metadata-only migration. No privileges/functions changed by this registration.
No claim that every existing advisor finding is cleared. References:
https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public
https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
