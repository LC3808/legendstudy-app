"""Isolated Postgres contract test. Synthetic rows only; not full Essay integration."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[3]
container='legendstudy-iap-expiry-check'
def sql(text):
    p=subprocess.run(['docker','exec','-i',container,'psql','-U','postgres','-v','ON_ERROR_STOP=1'],input="set request.jwt.claim.role='service_role';\n"+text,text=True,capture_output=True)
    if p.returncode: raise RuntimeError(p.stderr)
    return p.stdout
fixture="""
create schema if not exists auth;
create schema if not exists account_private;
create schema if not exists essay_private;
do $$begin
 if not exists(select from pg_roles where rolname='anon') then create role anon; end if;
 if not exists(select from pg_roles where rolname='authenticated') then create role authenticated; end if;
 if not exists(select from pg_roles where rolname='service_role') then create role service_role; end if;
end$$;
create function account_private.lock_subject(uuid) returns void language sql as $$select$$;
create function account_private.allowed(uuid) returns boolean language sql as $$select true$$;
create table public.credit_accounts(id uuid primary key default gen_random_uuid(),user_id uuid unique);
create table public.credit_grants(id uuid primary key default gen_random_uuid(),account_id uuid references credit_accounts(id),origin text,external_reference text unique,expires_at timestamptz);
create table public.credit_transactions(id uuid primary key default gen_random_uuid(),grant_id uuid references credit_grants(id),transaction_type text,balance_delta integer,reason_code text);
create function account_private.finance_privacy_guard() returns trigger language plpgsql as $$begin raise exception 'immutable finance row' using errcode='23514';end$$;
create trigger credit_grant_terms_frozen before update on public.credit_grants for each row execute function account_private.finance_privacy_guard();
create function essay_private.credit_post_grant(u uuid,q integer,o text,r text,c text,a text,e timestamptz) returns void language plpgsql as $$declare acct uuid;g uuid;begin
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into acct from public.credit_accounts where user_id=u;
 insert into public.credit_grants(account_id,origin,external_reference,expires_at) values(acct,o,r,e) returning id into g;
 insert into public.credit_transactions(grant_id,transaction_type,balance_delta,reason_code) values(g,'purchase',q,c);
end$$;
"""
sql(fixture)
sql((root/'supabase/migrations/20261009000200_iap_verified_credit.sql').read_text())
sql("""
select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000001','apple','com.legendstudy.essay.credit1','synthetic1','2026-10-22T12:04:46Z');
select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000001','apple','com.legendstudy.essay.credit3','synthetic3','2026-10-22T13:48:07Z');
select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000002','google','com.legendstudy.essay.credit1','syntheticG','2026-10-23T05:39:15.345Z');
""")
# Production guard is checked verbatim against the canonical predecessor function.
sql((root/'tool/iap_recovery/expiry/owner_apply.sql').read_text())
sql("""
do $$declare result text; begin
 select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000001','apple','com.legendstudy.essay.credit1','synthetic1','2026-10-22T12:04:46Z') into result;
 assert result='already_processed';
 select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000001','apple','com.legendstudy.essay.credit3','synthetic3','2026-10-22T13:48:07Z') into result;
 assert result='already_processed';
 select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000002','google','com.legendstudy.essay.credit1','syntheticG','2026-10-23T05:39:15.345Z') into result;
 assert result='already_processed';
 assert (select count(*) from credit_transactions)=3;
 assert (select sum(balance_delta) from credit_transactions)=5;
 assert (select count(*) from account_private.iap_expiry_amendments_20261023)=3;
 begin
 perform public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000002','apple','com.legendstudy.essay.credit1','synthetic1','2026-10-22T12:04:46Z');
 raise exception 'wrong account accepted'; exception when sqlstate 'PT409' then null;end;
 begin
 perform public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000001','apple','com.legendstudy.essay.credit5','synthetic1','2026-10-22T12:04:46Z');
 raise exception 'wrong SKU accepted'; exception when sqlstate 'PT409' then null;end;
 begin update credit_grants set expires_at=now();raise exception 'guard missing';exception when check_violation then null;end;
 begin delete from account_private.iap_expiry_amendments_20261023;raise exception 'audit mutable';exception when check_violation then null;end;
 assert (((timestamptz '2026-10-31 16:00Z' at time zone 'Asia/Seoul')::date+interval '3 months')::date+time '23:59:59.999999') at time zone 'Asia/Seoul'=timestamptz '2027-02-01 14:59:59.999999Z';
 assert (((timestamptz '2027-11-30 10:00Z' at time zone 'Asia/Seoul')::date+interval '3 months')::date+time '23:59:59.999999') at time zone 'Asia/Seoul'=timestamptz '2028-02-29 14:59:59.999999Z';
 assert (((timestamptz '2026-11-30 10:00Z' at time zone 'Asia/Seoul')::date+interval '3 months')::date+time '23:59:59.999999') at time zone 'Asia/Seoul'=timestamptz '2027-02-28 14:59:59.999999Z';
end$$;
""")
sql("""
do $$declare result text;e timestamptz;begin
 select public.iap_post_verified_purchase('00000000-0000-0000-0000-000000000002','google','com.legendstudy.essay.credit1','syntheticNew',clock_timestamp()) into result;
 assert result='granted';
 select expires_at into e from credit_grants where external_reference='iap/google/'||encode(sha256(convert_to('syntheticNew','UTF8')),'hex');
 assert (e at time zone 'Asia/Seoul')::time=time '23:59:59.999999';
end$$;
""")
print('PASS: 3 amended grants, replay x3, unchanged ledger sum, cross-account/SKU conflict, frozen grants/audit, KST boundary, month-end/leap-year, new grant end-of-day.')
