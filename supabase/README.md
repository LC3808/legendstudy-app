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
PYTHONDONTWRITEBYTECODE=1 python supabase/review/check_schema_draft.py
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s supabase/review -p 'test_*.py' -v
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
3. Check for conflicting public tables/functions, target PostgreSQL version,
   generated-column support, immutable make_date and deployer REFERENCES on
   auth.users. No extension is required. Inspect role inheritance/default ACLs;
   explicit grants in the draft do not prove target effective permissions.
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

Ten empty application tables, two invoker trigger functions, eight update/clock
triggers, RLS on all ten tables, 16 policies, 10 non-constraint indexes, and the
listed explicit table/column grants. All parent content defaults inactive; exams inherits parent publication. No taxonomy
seed, profiles auth trigger, ingestion job, storage bucket or Flutter integration.

## Rollback / repair notes for later review

The draft is transactional: if a statement fails before commit, roll back the
transaction and inspect the cause; do not mark the migration deployed. Before
retry, resolve schema/catalog conflicts and reconcile migration history.

After a successful future commit, prefer a reviewed forward correction. Destructive
rollback is only acceptable for an explicitly confirmed disposable empty setup:
remove dependent personal/quarantine/resources/occurrence tables before exams/subjects/content_items/source
posts (including the self-referencing content merge FK), then remove the two functions after their triggers are gone. Never drop
auth.users/auth schema or any shared extension. Never use broad DROP CASCADE
to bypass unknown dependencies. Data-bearing rollback requires backup and explicit
user approval; no rollback SQL is automatically run or provided as an easy default.

## Review remediation verification

The owner confirms the LegendStudy project is **not created or linked**. The
current draft parses as 74 statements, 10 RLS tables, 16 policies, 10 non-constraint
indexes, 8 triggers and 2 invoker functions. The inspection file contains 15
SELECT-only statements; none were executed. Six offline test methods include
45 unsafe schema mutations, four personal-target/policy mutations, two ingestion-contract
mutations and three inspection mutation cases, plus acceptance of harmless formatting/boolean operand reordering.

The checker compares policy/index/trigger ASTs, exact column grants, FK actions,
function settings/revokes, shared exam PK/type FK, same-content scope integrity,
source feed expression and verified ingestion contract.
Its explicit identifier contracts must be reviewed when the design changes.
It is not a SQL equivalence engine. PASS does not validate PostgreSQL catalog,
RLS runtime, PostgREST, Supabase grants, trigger runtime or performance.

Public clients must use the explicit projections in wiki/database.md. Source
posts and persistent quarantine have zero client grants/policies. Taxonomy master
inactivity must not suppress raw occurrences/resources. Source-link-first remains;
notification schema follows in a later **v1.0** milestone. No import, seed, Flutter
feature or Supabase SDK changes are included.

## Unified content review boundary

content_items is the public search/Home/Saved/Recent parent. Private source_posts
never becomes an app API. Exams has a shared content_item_id primary key and an
exam-only generated discriminator FK; public children depend on active content.
No duplicate exam flag/source/title/slug. General resources support non-exam PDFs.
Home uses known original-source publication/update time, never crawl/DB-update time.
See database.md for exact projections, all five source cases and null-tail cursors.

Before future application, verify generated columns in the actual server version,
exam-type/shared-key/composite FKs, all-type personal upserts and inactive-parent
RLS with explicit projections. No runtime behavior is established by parser PASS.
