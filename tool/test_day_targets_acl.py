#!/usr/bin/env python3
"""Isolated PostgreSQL17 security regression. NEVER connects to Production.
Usage: python3 tool/test_day_targets_acl.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
Creates a fresh temporary cluster, Unix socket only, and stops/removes it on exit.
No application rows, credentials, network endpoint, or existing database are used.
"""
import argparse
import json
import os
import re
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20260930000100_day_targets_least_privilege.sql'
BASELINE = ROOT / 'supabase/migrations/20260926000100_day_targets.sql'
SETUP = """
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as
$$select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid$$;
grant usage on schema public, auth to anon, authenticated, service_role;
grant execute on function auth.uid() to authenticated;
create table public.profiles(id uuid primary key, target_date date, target_label text);
-- Exact broad default pattern observed live; reproduction, not a proposed policy.
alter default privileges for role postgres in schema public
 grant all on tables to anon, authenticated, service_role;
create table public.unrelated_acl_probe(id integer);
insert into auth.users values
 ('00000000-0000-0000-0000-000000000001'),
 ('00000000-0000-0000-0000-000000000002');
"""
SNAPSHOT = """
select jsonb_build_object(
 'policies',(select jsonb_agg(to_jsonb(p) order by policyname) from pg_policies p where tablename='day_targets' and schemaname='public'),
 'owner_rls',(select jsonb_build_array(relowner,relrowsecurity,relforcerowsecurity) from pg_class where oid='public.day_targets'::regclass),
 'internal_acl',(select jsonb_agg(to_jsonb(a) order by grantee,privilege_type) from pg_class c cross join lateral aclexplode(c.relacl) a where c.oid='public.day_targets'::regclass and a.grantee in (select oid from pg_roles where rolname in ('postgres','service_role'))),
 'other',(select relacl::text from pg_class where oid='public.unrelated_acl_probe'::regclass),
 'defaults',(select jsonb_agg(to_jsonb(d) order by oid) from pg_default_acl d));
"""
CHECKS = """
begin;
do $$declare r text; p text; begin
 foreach r in array array['anon','authenticated'] loop
  foreach p in array array['TRUNCATE','TRIGGER','REFERENCES','MAINTAIN'] loop
   if has_table_privilege(r,'public.day_targets',p) then raise exception 'excess privilege % %',r,p; end if;
  end loop;
 end loop;
 foreach p in array array['SELECT','INSERT','UPDATE','DELETE'] loop
  if not has_table_privilege('authenticated','public.day_targets',p) then raise exception 'missing CRUD %',p; end if;
  if has_table_privilege('anon','public.day_targets',p) then raise exception 'anon CRUD %',p; end if;
 end loop;
end$$;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$declare n integer; begin
 insert into public.day_targets(id,owner_id,title,event_date) values
 ('10000000-0000-0000-0000-000000000001',auth.uid(),'own','2027-01-01');
 select count(*) into n from public.day_targets; if n<>1 then raise exception 'owner SELECT'; end if;
 update public.day_targets set title='edited' where owner_id=auth.uid();
 get diagnostics n=row_count; if n<>1 then raise exception 'owner UPDATE'; end if;
 begin
  update public.day_targets set owner_id='00000000-0000-0000-0000-000000000002';
  raise exception 'owner transfer allowed';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.day_targets(owner_id,title,event_date) values ('00000000-0000-0000-0000-000000000002','forged','2027-01-01');
  raise exception 'foreign INSERT allowed';
 exception when insufficient_privilege then null; end;
end$$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$declare n integer; begin
 select count(*) into n from public.day_targets; if n<>0 then raise exception 'non-owner SELECT'; end if;
 update public.day_targets set title='foreign'; get diagnostics n=row_count; if n<>0 then raise exception 'non-owner UPDATE'; end if;
 delete from public.day_targets; get diagnostics n=row_count; if n<>0 then raise exception 'non-owner DELETE'; end if;
end$$;
reset role;
set local role anon;
do $$declare q text; begin
 foreach q in array array[
  'select * from public.day_targets',
  'insert into public.day_targets(owner_id,title,event_date) values (''00000000-0000-0000-0000-000000000001'',''anon'',''2027-01-01'')',
  'update public.day_targets set title=''anon''',
  'delete from public.day_targets'] loop
  begin execute q; raise exception 'anon access allowed'; exception when insufficient_privilege then null; end;
 end loop;
end$$;
reset role;
set local role service_role;
do $$declare n integer; begin
 select count(*) into n from public.day_targets; if n<>1 then raise exception 'service SELECT'; end if;
 insert into public.day_targets(owner_id,title,event_date) values ('00000000-0000-0000-0000-000000000002','service','2027-01-02');
 update public.day_targets set title='service-updated' where title='service';
 get diagnostics n=row_count; if n<>1 then raise exception 'service UPDATE'; end if;
 delete from public.day_targets where title='service-updated'; get diagnostics n=row_count; if n<>1 then raise exception 'service DELETE'; end if;
end$$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$declare n integer; begin
 delete from public.day_targets; get diagnostics n=row_count; if n<>1 then raise exception 'owner DELETE'; end if;
end$$;
reset role;
rollback;
"""

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--pg-bin', required=True, type=Path)
    args = ap.parse_args()
    # Static scope guard: no DML, RLS/schema/function/default-ACL or other-table edits.
    statements = [re.sub(r'\s+', ' ', x.strip()).lower() for x in
                  re.sub(r'--[^\n]*', '', MIGRATION.read_text()).split(';') if x.strip()]
    assert statements == [
        'begin', "set local lock_timeout = '5s'", "set local statement_timeout = '30s'",
        'revoke all privileges on table public.day_targets from public, anon, authenticated',
        'grant select, insert, update, delete on table public.day_targets to authenticated', 'commit'
    ], 'Migration escaped the approved single-table ACL scope'
    # Explicit binaries + own Unix socket; inherited PG connection variables excluded.
    env = {k: v for k, v in os.environ.items() if not k.startswith('PG')}
    def run(command, **kw):
        return subprocess.run([str(x) for x in command], env=env, check=True,
                              capture_output=True, text=True, **kw).stdout
    version = run([args.pg_bin/'postgres', '--version'])
    if ' 17.' not in version:
        raise SystemExit('PostgreSQL17 required to cover MAINTAIN')
    with tempfile.TemporaryDirectory(prefix='ls-day-acl-', dir='/private/tmp') as temp:
        root = Path(temp); data = root/'db'; sock = root/'socket'; sock.mkdir()
        run([args.pg_bin/'initdb','-D',data,'-U','postgres','--auth=trust','--no-locale'])
        started = False
        try:
            run([args.pg_bin/'pg_ctl','-D',data,'-l',root/'server.log','-o',
                 f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start'])
            started = True
            def sql(text):
                return run([args.pg_bin/'psql','-X','-h',sock,'-p','5432','-U','postgres',
                            '-d','postgres','-v','ON_ERROR_STOP=1','-Atq'],input=text)
            sql(SETUP); sql(BASELINE.read_text())
            assert sql("select has_table_privilege('anon','public.day_targets','MAINTAIN');").strip()=='t'
            assert sql("select has_table_privilege('authenticated','public.day_targets','TRUNCATE');").strip()=='t'
            before = json.loads(sql(SNAPSHOT))
            sql(MIGRATION.read_text()); after = json.loads(sql(SNAPSHOT))
            assert before==after, 'RLS/owner/service/other/default drift'
            acl = sql("select relacl from pg_class where oid='public.day_targets'::regclass;")
            sql(MIGRATION.read_text())
            assert acl==sql("select relacl from pg_class where oid='public.day_targets'::regclass;"), 'not idempotent'
            sql(CHECKS)
            print('PASS: broad default reproduction; owner CRUD; non-owner isolation; forged-owner rejection; anon denial; excessive privilege removal (including MAINTAIN); service CRUD; RLS/owner/service/other/default preservation; idempotency')
        finally:
            if started:
                run([args.pg_bin/'pg_ctl','-D',data,'-m','fast','-w','stop'])
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
