# Supabase — initial schema applied

The owner reports successful deployment of
`migrations/20260912000100_initial_content_schema.sql` after main merge
`c16350c0a60fe1c6281234a7c2056cf02b54d9ad`: `Success. No rows returned`.
Dedicated project: **LegendStudy**, ref `stlhijzpjfgwwdgunlsd`, Seoul
`ap-northeast-2`, PostgreSQL **17.6**; separate from Muselry.

This documentation records owner-provided runtime evidence, not new database
queries by the documentation agent. Flutter remains unconnected. Do not execute
SQL or deployment commands as part of this docs task. The applied initial migration
is immutable, including its historical DRAFT comments; future DB changes require
new migration files. Do not replay the initial migration.

Canonical model, runtime evidence, RLS matrix and remaining checks:
`wiki/database.md`. Parser/reprocessing rules: `wiki/ingestion.md`.

## Offline check (safe: reads files, no database)

Create an isolated Python virtual environment outside the repository, install
`review/requirements.txt` there, then use its Python interpreter to run:

```sh
PYTHONDONTWRITEBYTECODE=1 python supabase/review/check_schema_draft.py
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s supabase/review -p 'test_*.py' -v
```

Validated with pglast 8.4 (PostgreSQL 18 grammar); the owner-reported deployed
server is PostgreSQL 17.6. The SQL intentionally uses ordinary tables/FKs/RLS and no PG18-only
syntax. Native SQL and PL/pgSQL parsing is not semantic/catalog/RLS validation.
The checker calls the native PL/pgSQL parser without JSON decoding because the
high-level pglast 8.4 helper has a trigger-record serialization issue. No function
body or SQL statement is executed by this checker.

## Recorded deployment prerequisites and runtime results

The owner confirmed auth.users, auth.uid(), anon/authenticated/service_role,
service_role BYPASSRLS, deployer REFERENCES on auth.users and no conflicting
application tables/functions. Generated content_items.feed_updated_at,
exams.content_type and exams.sort_date all created/calculated successfully on
PostgreSQL 17.6. No generated-column fallback was needed.

Actual publishable-key anon `/rest/v1` requests read active content; inactive
slug reads returned []. Source posts and quarantine returned HTTP 401 permission
denied, with no authenticated SELECT privilege; anon profiles also returned 401.
Real Auth users A/B using password-grant JWTs verified own-profile creation/read,
cross-user isolation, bookmark ownership and HTTP 403 rejection of a spoofed
user_id. Recent views preserved ID and advanced viewed_at on repeated
(user_id, content_item_id) upsert without duplication; cross-user reads were isolated.

Inactive taxonomy visibility was checked structurally against the policies:
inactive subjects stay hidden while active occurrences/resources retain independent
visibility. A complete taxonomy REST trace was not supplied. SQL Editor SET ROLE
is not authoritative client-path evidence because session behavior may differ.
Use real anon headers/user JWTs for remaining client-path checks.

## Recorded inventory and cleanup

10 application tables, 16 policies, 10 non-constraint indexes, 8 triggers and
2 trigger functions. RLS enabled on all tables; FORCE RLS false.
After fixture cleanup, source_posts, content_items, exams, subjects, exam_subjects,
resources, profiles, bookmarks, recent_views and ingestion_quarantine each have
**0 rows**, as reported by the owner. Two Auth test users may remain; Auth-user
cleanup is not claimed. No production ingestion or Flutter integration is implemented.

## Future repair notes

The initial migration has already succeeded. For future migration failures before
commit, roll back the transaction, inspect the cause and reconcile migration history.
Do not edit or replay the applied initial file.

For the deployed schema, use a reviewed forward correction in a new migration. Destructive
rollback is only acceptable for an explicitly confirmed disposable empty setup:
remove dependent personal/quarantine/resources/occurrence tables before exams/subjects/content_items/source
posts (including the self-referencing content merge FK), then remove the two functions after their triggers are gone. Never drop
auth.users/auth schema or any shared extension. Never use broad DROP CASCADE
to bypass unknown dependencies. Data-bearing rollback requires backup and explicit
user approval; no rollback SQL is automatically run or provided as an easy default.

## Review remediation verification

The LegendStudy initial schema is deployed. Independently, the unchanged
migration parses as 74 statements, 10 RLS tables, 16 policies, 10 non-constraint
indexes, 8 triggers and 2 invoker functions. The inspection file contains 16
SELECT-only statements; the offline checker executes none. The deployment report
does not separately attest execution of every inspection statement. Fourteen offline test methods include
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

Generated columns and the reported anon/JWT paths passed runtime checks. The
remaining behavioral matrix (including all-type personal cases and additional FK
negative cases) and Flutter integration still need their own evidence. Parser PASS
does not establish unreported runtime coverage.

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
need review. The report does not separately confirm this exact query was run;
retain it for authorized owner/backend publication acceptance. This
checks the reverse existence condition that the child-to-parent FK cannot enforce.

## Generated-column fallbacks — only after an observed target failure

All three definitions succeeded on the deployed PostgreSQL 17.6 target; no fallback
is needed. Retain these designs only as emergency reference. If a future target
fails, record the exact error/version and review a new corrective migration, checker
and behavioral tests. Never rewrite the applied initial migration or loosen its
checker merely to accommodate a failure.

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

All three remain unused contingency designs. They do not change the deployed
schema. Next is Day 4 Flutter integration: supabase_flutter, URL/publishable key,
initialization, explicit-projection anonymous ContentRepository reads and session/
personal repositories. Never put service_role credentials in Flutter.
