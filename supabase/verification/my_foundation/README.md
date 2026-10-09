# MY shared foundation candidates — 2026-10-08

Production target: stlhijzpjfgwwdgunlsd. Schema inventory supplied by Owner.
No `supabase db push`. Files existing in Git do not imply deployed migrations.

## Candidate sets

- **005 Target**: replacing existing uniqueness is held under Owner §74. Do not apply
  until explicitly cleared and APP compatibility accepted. Rows/IDs are not rewritten.
- **006–008 Foundation**: additive Application/events, Study read and Student360/Essay
  read. Independent of005. No replacement of existing DB functions, Payment, Credit,
  APP timer storage, lifecycle worker or QL. Direct client writes to new fact tables
  are denied; self RPC + lifecycle subject lock; operator allowlist for Admin.

Owner apply sequence: read-only preflight -> exact reviewed source -> prepare script ->
review SQL/hash -> SQL Editor transaction -> postflight -> deploy compatible LAB ->
Owner/reviewer runtime only. Never apply to ordinary users as a test. The preparation
script connects to no database and refuses overwriting an existing output file.

```sh
python3 tool/production/prepare_my_foundation.py \
  --source <FULL_REVIEWED_COMMIT> --mode foundation \
  --output /tmp/legendstudy-my-foundation.sql
```

Target mode additionally requires `--target-constraint-approved`; this flag must reflect
actual Owner approval, not a way to bypass the stop condition. Do not combine005 into
an unapproved Foundation package. No automatic apply command is provided.

The exact package is tested under PostgreSQL17 with a NOSUPERUSER postgres migration
owner. It uses one transaction and records ledger rows only after successful DDL. It
aborts on recorded versions, unexpected existing objects, changed dependency bodies,
owner/search_path drift and missing profile/Auth cascade. Current guards:
allowed794b021de5153ccb209b96ddbdce370e; lock_subject f721da4d53a6ef9abab7663c484f9aec;
admin_operator98ff2257c8da2b1180e527099ab60247; personal1937b1d72a09548a376c06fa65ea509a;
postconditions24a2fb3425e92a556a63511a5196da65. These functions are read, never replaced.
Owner preflight confirmed all five helper/admin/lifecycle hashes, owners and empty search_path; candidate migration list is empty and student_private/Application objects absent.

## Verification

PGlite executes the migrations, canonical target RLS, canonical lifecycle allowed/lock
functions and canonical Admin gate fixture. Essay fixture declares only actual queried
columns; it is a read-model fixture, not a replacement of Production schema authority.

```
PGLITE_MODULE=/path/to/@electric-sql/pglite/dist/index.js node supabase/verification/my_foundation/target.mjs
# repeat for application.mjs, study.mjs, student360.mjs
PG_BIN=/path/to/postgresql/17/bin python3 supabase/verification/my_foundation/real_roles.py
```

The Python harness needs psycopg and local Unix sockets; it starts/removes its own
isolated cluster, not a remote connection. Verifies nested roles, eight concurrent
same-key create/event requests, non-admin/quality-only deny, admin allow, schema
owner/search_path, ledger/replay guard and Auth cascade. PGlite adds owner revision,
correction history, duplicate rejection, lifecycle denial, Study midnight/week/30d/
overlap/pause/excluded/empty cases. APP Dart tests exist but pinned Flutter3.47.6 was
not available in cloud; official SDK egress is pending environment Publish. Do not
report APP regression as passed.

## Rollback / disable

Before writes, revoking these grants disables only the new endpoints (no data erase):

```sql
BEGIN;
REVOKE EXECUTE ON FUNCTION public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid),
 public.my_application_event(uuid,text,timestamptz,uuid,uuid),public.my_application_delete(uuid),
 public.my_applications(integer),public.my_application_events(uuid,integer),
 public.my_study_summary(),public.my_essay_summary(),public.admin_student360(uuid) FROM authenticated;
REVOKE SELECT ON public.student_applications,public.student_application_events FROM authenticated;
COMMIT;
```

Preserve any already recorded facts; do not DROP live tables or remove migration history.
This is an exposure rollback, not a claim of dropping data reversibly. Foundation does
not change existing RPC behavior. Target old uniqueness can only be restored if no
user/university/year has multiple rows; if it does, STOP instead of deleting rows.

Application lifecycle: self RPCs share account lock + allowed fence. New rows are
personal, not finance audit. Auth deletion cascades via profiles to applications/events
in the existing AUTH phase; no worker rewrite. Owner explicit application delete also
cascades that application's events. Essay practice remains independent of Application.
