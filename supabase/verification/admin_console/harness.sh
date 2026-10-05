#!/usr/bin/env bash
# ADMIN-P0-A isolated installation harness.
#
# Loads the canonical migration chain into a throwaway PostgreSQL cluster with
# synthetic Supabase shims (auth schema, storage catalog, platform roles) and
# then applies 20261005000200_admin_console_read.sql.
#
# No Production connection, no remote apply, no ledger write.
#
# EXCLUDED from the chain, because they are explicitly NOT APPLIED candidates and
# reconstructing the pre-ADR2 attempt is not this task's subject:
#   20261001000300_account_deletion_lifecycle  ("ADR-2 candidate. NOT APPLIED.")
#   20261005000100_account_provider_revocation (depends on the ADR-2 objects)
#   20261002000100/000200/000300 Math           (READY_NOT_APPLIED; preflight
#                                               refuses a superuser installation
#                                               context by design)
# Excluding them reproduces the most likely current Production shape — core
# applied, deletion/payment/Math subsystems pending — which is exactly the case
# the admin read boundary must degrade gracefully inside.
set -uo pipefail
DB=legendstudy_admin_test
MIG=supabase/migrations
LOG=/tmp/admin_console_chain.log
EXCLUDE="20261001000300_account_deletion_lifecycle.sql 20261005000100_account_provider_revocation.sql"
EXCLUDE="$EXCLUDE 20261002000100_math_essay_persistence.sql 20261002000200_math_runtime_surface.sql 20261002000300_math_learning_runtime.sql"
EXCLUDE="$EXCLUDE 20261003000100_payment_foundation.sql 20261004000100_payment_runtime.sql"

sudo -n pg_ctlcluster 16 main start >/dev/null 2>&1 || true
sleep 2

sudo -n -u postgres psql -q -c "drop database if exists $DB;" postgres >/dev/null
sudo -n -u postgres psql -q -c "create database $DB;" postgres >/dev/null

# Role attributes must match what the migrations themselves declare, otherwise a
# pre-created role silently keeps the wrong RLS posture: 20260928000300 creates
# essay_executor WITH BYPASSRLS and essay_worker/essay_finance WITHOUT it, and
# its `if not exists` guard would skip a role this script had already created.
for r in anon authenticated service_role math_executor \
         math_extraction_worker math_evaluation_worker supabase_admin authenticator; do
  sudo -n -u postgres psql -q -c "do \$\$begin if not exists(select 1 from pg_roles where rolname='$r') then create role $r nologin; end if; end\$\$;" postgres >/dev/null
done
sudo -n -u postgres psql -q -c "do \$\$begin
  if not exists(select 1 from pg_roles where rolname='essay_executor') then create role essay_executor nologin bypassrls; end if;
  if not exists(select 1 from pg_roles where rolname='essay_worker') then create role essay_worker nologin nobypassrls; end if;
  if not exists(select 1 from pg_roles where rolname='essay_finance') then create role essay_finance nologin nobypassrls; end if;
  -- Roles are cluster-wide and survive the database drop, so an earlier run with
  -- the wrong attributes would otherwise persist. Assert, do not assume.
  if exists(select 1 from pg_roles where rolname='essay_executor' and not rolbypassrls) then alter role essay_executor bypassrls; end if;
  if exists(select 1 from pg_roles where rolname in ('essay_worker','essay_finance') and rolbypassrls) then
    alter role essay_worker nobypassrls; alter role essay_finance nobypassrls; end if;
end\$\$;" postgres >/dev/null

psql_run() { sudo -n -u postgres psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$1"; }

cat > /tmp/shim.sql <<'SQL'
create extension if not exists pgcrypto;
create schema if not exists auth;
create table if not exists auth.users(
  id uuid primary key default gen_random_uuid(),
  email text unique,
  created_at timestamptz not null default now(),
  app_metadata jsonb not null default '{}'::jsonb
);
-- Faithful to the platform helper: prefer the single claim, fall back to the
-- JSON claim set, and never invent an identity.
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(coalesce(
    nullif(current_setting('request.jwt.claim.sub',true),''),
    nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub'
  ),'')::uuid
$$;
create or replace function auth.role() returns text language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.role',true),''),
                  nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role')
$$;
grant usage on schema auth to anon,authenticated,service_role;
grant select on auth.users to authenticated,service_role;

-- Storage is a separate Supabase service; the chain only needs its catalog.
create schema if not exists storage;
create table if not exists storage.buckets(
  id text primary key, name text not null, owner uuid, owner_id text,
  public boolean default false, avif_autodetection boolean default false,
  file_size_limit bigint, allowed_mime_types text[],
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists storage.objects(
  id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets(id),
  name text, owner uuid, owner_id text, version text, user_metadata jsonb,
  metadata jsonb, path_tokens text[], created_at timestamptz default now(),
  updated_at timestamptz default now(), last_accessed_at timestamptz
);
create or replace function storage.foldername(name text) returns text[] language sql immutable as $$
  select string_to_array(name,'/')
$$;
create or replace function storage.extension(name text) returns text language sql immutable as $$
  select split_part(name,'.',array_length(string_to_array(name,'.'),1))
$$;
grant usage on schema storage to anon,authenticated,service_role;
grant all on storage.buckets, storage.objects to service_role;
SQL
psql_run /tmp/shim.sql || { echo "SHIM_FAILED"; exit 1; }

: > "$LOG"
fail=0
for f in $(ls "$MIG"/*.sql | sort); do
  b=$(basename "$f")
  case " $EXCLUDE " in *" $b "*) echo "  SKIP $b"; continue;; esac
  if psql_run "$f" >>"$LOG" 2>&1; then
    echo "  OK   $b"
  else
    echo "  FAIL $b"
    grep -E "^psql.*ERROR" "$LOG" | tail -2 | sed 's/^/        /'
    fail=1
    break
  fi
done
if [ "$fail" = 0 ]; then echo "CANONICAL_CHAIN=OK"; else echo "CANONICAL_CHAIN=FAIL"; exit 1; fi

# The chain loop above already applied the admin migrations in ledger order, so
# assert the installed function set instead of applying them a second time.
# An explicit list, not a magic count: a renamed or dropped entry point fails.
EXPECTED="admin_account_state admin_count admin_credit_snapshot admin_dashboard admin_inquiry_detail admin_inquiry_list admin_inquiry_reply admin_inquiry_set_status admin_member_credit admin_member_detail admin_member_search admin_operator admin_payment_orders admin_support_metrics claim_inquiry_notifications complete_inquiry_notification inquiry_mine inquiry_submit inquiry_touch"
ACTUAL=$(sudo -n -u postgres psql -qtA -d "$DB" -c \
  "select string_agg(p.proname,' ' order by p.proname) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and (p.proname like 'admin\\_%' or p.proname like 'inquiry\\_%' or p.proname like 'claim\\_inquiry%' or p.proname like 'complete\\_inquiry%')" 2>/dev/null)
if [ "$ACTUAL" = "$EXPECTED" ]; then
  echo "ADMIN_MIGRATION_APPLY=OK (19 entry points)"
else
  echo "ADMIN_MIGRATION_APPLY=FAIL"
  echo "  expected: $EXPECTED"
  echo "  actual:   $ACTUAL"
  exit 1
fi
echo "=== behavior suite ==="
if sudo -n -u postgres psql -q -v ON_ERROR_STOP=1 -d "$DB" \
     -f supabase/verification/admin_console/behavior.sql > /tmp/admin_behavior.log 2>&1; then
  grep -E "ADMIN_CONSOLE_CHECKS" /tmp/admin_behavior.log | sed 's/^/  /'
  echo "BEHAVIOR=PASS"
else
  grep -E "ADMIN_CONSOLE_CHECKS|CHECK FAILED|FAILED:|ERROR" /tmp/admin_behavior.log | tail -12 | sed 's/^/  /'
  echo "BEHAVIOR=FAIL"
  exit 1
fi
echo "=== behavior suite (P0-B) ==="
if sudo -n -u postgres psql -q -v ON_ERROR_STOP=1 -d "$DB" \
     -f supabase/verification/admin_console/behavior_p0b.sql > /tmp/admin_behavior_p0b.log 2>&1; then
  grep -E "ADMIN_P0B_CHECKS" /tmp/admin_behavior_p0b.log | sed 's/^/  /'
  echo "BEHAVIOR_P0B=PASS"
else
  grep -E "ADMIN_P0B_CHECKS|CHECK FAILED|P0B FAILED|ERROR" /tmp/admin_behavior_p0b.log | tail -20 | sed 's/^/  /'
  echo "BEHAVIOR_P0B=FAIL"
  exit 1
fi
python3 supabase/verification/admin_console/collect.py "$DB"
exit 0
