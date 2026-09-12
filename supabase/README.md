# Supabase schema proposal — NOT DEPLOYED

**Day 3 is design-only. Do not execute this migration locally or remotely.**
Do not run `supabase db reset`, `supabase db push`, `supabase migration up`, or
execute the SQL in an editor as part of this task. No Supabase project was created,
linked, inspected or modified; an unrelated existing project must never be used.
A `.sql` file under `migrations/` is discoverable by future CLI operations: the
DRAFT comment does not prevent execution. There is deliberately no CLI project
configuration or deployment workflow in this change.

Canonical model, examples, RLS matrix and review gates: `wiki/database.md`.
Parser/reprocessing rules: `wiki/ingestion.md`.

## Offline check (safe: reads files, no database)

Create an isolated Python virtual environment outside the repository, install
`review/requirements.txt` there, then use its Python interpreter to run:

```sh
python supabase/review/check_schema_draft.py
```

Validated with pglast 8.4 (PostgreSQL 18 grammar); target Supabase server/version is
not verified. The SQL intentionally uses ordinary tables/FKs/RLS and no PG18-only
syntax. Native SQL and PL/pgSQL parsing is not semantic/catalog/RLS validation.
The checker calls the native PL/pgSQL parser without JSON decoding because the
high-level pglast 8.4 helper has a trigger-record serialization issue. No function
body or SQL statement is executed by this checker.

## Prerequisites for a later, separately authorized application

1. ChatGPT review, and preferably Claude review of RLS/FKs/idempotency; owner
   explicitly authorizes the target project and execution. No approval is implied now.
2. Confirm the project belongs only to LegendStudy. Confirm auth.users, auth.uid(),
   anon/authenticated/service_role roles and service_role BYPASSRLS exist.
3. Check for conflicting public tables/functions, extension schema and version.
   `pg_trgm` must be absent (draft installs in `extensions`) or already in that
   schema. Do not relocate an existing extension silently. Confirm permission to
   create it and use `extensions.gin_trgm_ops`.
4. Snapshot/back up any target data. An empty application schema is assumed; the
   migration is not replay-safe and makes no automatic alterations to old schemas.
5. User executes only after approval and records actual output/migration status.
6. User/reviewer runs the read-only inspection in
   `review/initial_content_schema_checks.sql` and the behavioral test matrix in
   `wiki/database.md`. Verify role-denied writes by returned rows and a follow-up
   read, not just lack of an exception. Validate PostgREST recent upsert and trigger
   privileges. Refresh schema cache through the supported deployment process if needed.
7. Reconcile repo history with verified DB state before any client integration.

## Expected future result (not observed)

Eight empty application tables, two invoker trigger functions, seven update/clock
triggers, RLS on all eight tables, 15 policies, 11 non-constraint indexes, and the
listed explicit table/column grants. All content defaults inactive. No taxonomy
seed, profiles auth trigger, ingestion job, storage bucket or Flutter integration.

## Rollback / repair notes for later review

The draft is transactional: if a statement fails before commit, roll back the
transaction and inspect the cause; do not mark the migration deployed. Before
retry, resolve schema/extension conflicts and reconcile migration history.

After a successful future commit, prefer a reviewed forward correction. Destructive
rollback is only acceptable for an explicitly confirmed disposable empty setup:
remove dependent personal/resources/occurrence tables before exams/subjects/source
posts, then remove the two functions after their triggers are gone. Never drop
auth.users/auth schema or a shared pg_trgm extension. Never use broad DROP CASCADE
to bypass unknown dependencies. Data-bearing rollback requires backup and explicit
user approval; no rollback SQL is automatically run or provided as an easy default.
