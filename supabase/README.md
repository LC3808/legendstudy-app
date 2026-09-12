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
indexes, 8 triggers and 2 invoker functions. The inspection file contains 16
SELECT-only statements; none were executed. Fourteen offline test methods include
106 rejected mutation cases (54 existing + 52 scalar-invariant additions), plus
acceptance of harmless formatting/comments, boolean reordering and equivalent
single-column table UNIQUE constraints.

The checker compares policy/index/trigger ASTs, exact column grants, FK actions,
function settings/revokes, shared exam PK/type FK, same-content scope integrity,
source feed expression and verified ingestion contract.
Its explicit identifier contracts must be reviewed when the design changes.
PASS means offline syntax, reviewed structural invariants and regression protection.
It is not a SQL equivalence engine. PASS does not validate PostgreSQL catalog,
Supabase compatibility, RLS/PostgREST/trigger/generated-column runtime, performance
or ingestion implementation correctness.

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

## Final checker hardening (2026-09-13)

The migration is byte-for-byte unchanged from b28c003. The checker independently
requires content_items.slug NOT NULL, global UNIQUE and lowercase/hyphen regex;
source_posts.url NOT NULL, global UNIQUE and HTTP(S) shape. URL uniqueness remains
only a collision guard; canonical source identity is (source, external_post_id).

Default-private publication is a reviewed security/operating invariant:
content_items, subjects, exam_subjects and resources require is_active NOT NULL
DEFAULT false. True/missing defaults and nullable changes fail independently.
The checker also locks exam year/academic_year 1900..2200, month 1..12, grade 1/2/3,
confidence 0..1, source/content/exam/mapping/resource/link/quarantine domain lists
and nonnegative occurrence/resource display_order and taxonomy sort_order.
These are normalized AST contracts, not raw SQL string/grep checks. Not every
possible CHECK equivalence or runtime behavior is proved.

The final SELECT-only inspection detects active exam-type content without an
exams extension. Expect zero rows before publication acceptance; returned rows
need review. Run under an authorized owner/backend role in a future task. This
checks the reverse existence condition that the child-to-parent FK cannot enforce.

## Generated-column fallbacks — only after an observed target failure

Do not preemptively change the migration or loosen the checker. If the separately
authorized LegendStudy target rejects a generated definition, record the exact
error/server version and review the replacement, checker and behavioral tests
as a separate change before retrying. No failure or fallback has been exercised now.

- exams.content_type: ordinary `content_type text not null default 'exam'` with
  `CHECK (content_type = 'exam')` can replace the generated constant, retaining the
  existing shared PK and composite type FK. Explicit NULL/non-exam writes must fail.
- feed_updated_at: first consider a stored generated CASE preserving GREATEST's
  NULL semantics: published NULL → source_updated_at; source_updated_at NULL →
  published_at; otherwise choose the later value (both NULL remains NULL). If
  generated columns themselves are unsupported, review an ordinary column maintained
  atomically by trusted backend with the same source-time semantics, never now().
- exams.sort_date: consider ordinary nullable `sort_date date` maintained by trusted
  ingestion with the existing exam_date → known year/month day 1 → known year
  January 1 → NULL rule. Retain numeric range CHECKs and test every fallback path.

All three are contingency designs, not changes to the current schema or evidence
of target Supabase compatibility. Runtime acceptance still belongs to a later task.
