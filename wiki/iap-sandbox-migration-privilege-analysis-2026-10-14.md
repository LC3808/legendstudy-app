# TEST migration halt — privilege root-cause analysis (2026-10-14)

READ-ONLY analysis of the `supabase db push` failure on the IAP test project
`kpqbedylxlyntrrfybpn` (production `stlhijzpjfgwwdgunlsd` NOT accessed). No DB/
ownership/privilege/migration change, no re-run, no deploy — analysis only.

## Facts (read-only, from the test DB)
- Migrations recorded: **25** (`20260912000100` … `20261001000200`). `#26` `20261001000300`
  **not recorded** (`has_26=0`, last=`20261001000200`).
- Schema ownership: `essay_private` → **postgres**; `public` → **pg_database_owner**;
  `credit_accounts` → **postgres** (so the applied DDL ran as postgres via `SET ROLE postgres`).
- `essay_executor`: `login=f, bypassrls=t, super=f`.
- `essay_executor` currently has CREATE on `essay_private`=**false**, on `public`=**false**.
- `postgres` IS a member of `pg_database_owner`. Roles present: authenticator, pg_database_owner,
  postgres, supabase_admin.
- Management API (MCP) connection: `current_user=postgres`, `session_user=postgres`,
  `is_superuser=false`, member of pg_database_owner, `can_create_public=true`.

## 1. Exact cause
Migration `#26` (one `begin;…commit;` transaction) does, near the end:
`set local role essay_executor; … ; reset role; revoke create on schema essay_private,public from essay_executor;`
- **`RESET ROLE` restores the *session* user** (the authenticated login role), **not** the last
  `SET ROLE`. To `REVOKE CREATE` on a schema you must own it, be a member of the owning role, or be
  superuser. `essay_private` is owned by `postgres`; `public` by `pg_database_owner`.
- Under `supabase db push`, objects were **created** as postgres (via `SET ROLE postgres`), but the
  **session user is NOT postgres** (it is the CLI/pooler login role). Proof: if the session user were
  postgres, `reset role` would land on postgres (owner of essay_private, member of pg_database_owner)
  and the revoke would succeed — it did not, so the session user ≠ postgres. After `reset role` the
  role is that non-owning session login → `permission denied for schema essay_private`.
- The management API connects **as postgres directly** (`session_user=postgres`), so `reset role` →
  postgres → the revoke is permitted. This is the whole difference.
- This migration implicitly assumes the applier's **session user owns these schemas** (i.e. direct
  `postgres` connection / dashboard), which is how production was provisioned.

## 2. Was #26 partially applied?
**No.** The file is a single `begin;…commit;` transaction; the failed `revoke` aborts and **rolls
back the whole file**. Confirmed: `essay_executor` has no CREATE grant on either schema (the earlier
`grant create…` in the same file did not persist), and `#26` is **absent** from `schema_migrations`.
The DB is cleanly at 25 applied migrations; re-applying `#26` starts from a clean slate for that file.

## 3. db-push vs management-API DB role
- **db push**: authenticates as the CLI login/pooler role (Supabase's session-pooler login is
  `postgres.<ref>`, a tenant role ≠ bare `postgres`), then `SET ROLE postgres` for DDL. `RESET ROLE`
  in `#26` drops back to that non-owning session role → denied. (Exact session role would be confirmed
  on the next run; the ownership + RESET-ROLE semantics already prove it is not `postgres`.)
- **management API (MCP)**: connects as `postgres` (session_user=postgres), member of
  pg_database_owner → the revoke is allowed.

## 4. Recovery comparison (no Ledger/RLS/RPC contract change in either)
### A. Keep the `supabase db push` path (Owner's preferred option 3)
- **Fix without any DB role/ownership/migration change**: run db push over the **direct Postgres
  connection as `postgres`** (session_user=postgres) instead of the pooler, so `#26`'s `reset role`
  lands on the owner. Command (Owner supplies the DB password; Claude does not handle passwords):
  `supabase db push --db-url "postgresql://postgres:[DB_PASSWORD]@db.kpqbedylxlyntrrfybpn.supabase.co:5432/postgres"`
  (or set `SUPABASE_DB_PASSWORD` and push against the direct host).
- **No ownership/grant change** — the existing `postgres` ownership already suffices; only the
  *connection's session user* must be `postgres`.
- **History**: native — CLI continues appending `#26…#42` to `schema_migrations`. Clean, canonical.
- **Follow-on migrations**: all remaining (27–42) then apply via the same session. `#31 payment_runtime`
  (credit_summary) and `#42 iap_verified_credit` (iap_post_verified_purchase) land as intended.
- **Needs**: the postgres DB password (Owner) + approval to re-run `db push` (currently on the no-do list).
- **Risk**: low; if Supabase's direct host still resolves a non-`postgres` session user (unexpected),
  it would fail identically — verified on the first direct push.

### B. Management API (`apply_migration`) for #26→#42
- Connects as `postgres` → `reset role` works; applies the **verbatim** canonical SQL per file.
- **No password** needed; Claude can run it if approved.
- **History consistency** (must verify): `apply_migration` records into
  `supabase_migrations.schema_migrations`; the recorded `version` must equal the CLI's numeric prefix
  (e.g. `20261001000300`) so a later `supabase migration list`/`db push` treats them as applied and
  does not duplicate. Validate on the first file before continuing.
- **Duplicate prevention**: `#26`+ are unrecorded/rolled back, so fresh application is safe.
- **begin/commit nesting**: files carry their own `begin;…commit;`; confirm `apply_migration` runs
  them without double-wrapping (else the inner commit could split the file). Validate on the first file.
- **Failure recovery**: per-file transactional; on error, stop and report (as now).

## 5. Recommendation
**Option A** (direct-`postgres` `db push`) — it matches the Owner's preferred path, needs **no**
DB role/ownership/migration/SQL change (only the connection's session user = postgres), and keeps
native CLI migration history. Option B is the no-password fallback if a direct connection is
undesirable, with the schema_migrations-format check above. Either way: no Ledger/RLS/RPC change,
production untouched.

## 6. Risks
- A: needs the postgres password handled by the Owner; a wrong `--db-url` host must target the TEST
  ref only. B: schema_migrations version/format drift and begin/commit wrapping (validate on file 1).
- Both: must re-confirm the target is `kpqbedylxlyntrrfybpn` immediately before any write.

## 7. Approval needed (nothing executed yet)
Pick A or B. For A: lift the "no db push re-run" hold for the TEST project and have the Owner supply
the postgres password / run the direct-URL push. For B: approve management-API application of the
verbatim `#26…#42`. Then DB verification (§4 of the prior directive) and the Edge deploy proceed.
