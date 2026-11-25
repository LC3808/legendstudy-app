"""Synthetic isolated PostgreSQL; captured production grant functions, no network/production fallback."""
from pathlib import Path
import json,subprocess,uuid,concurrent.futures
HERE=Path(__file__).resolve().parent
PG='/opt/homebrew/opt/postgresql@17/bin/psql';DB='signup_policy_test'
def sql(q,role=None,actor=None,db=DB,user_name="postgres"):
 prefix=("set role "+role+';' if role else '')+("set test.uid='"+actor+"';" if actor else '')
 p=subprocess.run([PG,'-X','-h','/private/tmp','-p','55443','-U',('supabase_admin' if role else user_name),'-d',db,'-Atq','-v','ON_ERROR_STOP=1'],input=prefix+q,text=True,capture_output=True)
 if p.returncode:raise RuntimeError(p.stderr)
 return p.stdout.strip()
def lit(x):return "'"+str(x).replace("'","''")+"'"
def uid():return str(uuid.uuid4())
checks=[]
def ok(v,n):
 assert v,n
 checks.append(n)
def deny(fn,n):
 try:fn()
 except RuntimeError:checks.append(n);return
 raise AssertionError(n)
def user(confirmed=True,old=False):
 u=uid();sql(f"insert into auth.users values('{u}',{'now()' if confirmed else 'null'},{repr('2020-01-01') if old else 'now()'},true);insert into public.profiles values('{u}');")
 return u
def claim(u,m):return sql(f"select public.account_benefit_claim('{u}',{lit(json.dumps([{'version':'v1','marker':m}]))}::jsonb)",role='account_lifecycle_worker')
def balance(u):return int(sql(f"select coalesce(sum(t.balance_delta),0) from public.credit_transactions t join public.credit_accounts a on a.id=t.account_id where a.user_id='{u}'"))
def facts():return sql("select jsonb_build_object('g',(select jsonb_agg(to_jsonb(t) order by id) from public.credit_grants t),'t',(select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t),'b',(select jsonb_agg(to_jsonb(t) order by subject_id) from account_private.benefit_delivery t),'m',(select jsonb_agg(to_jsonb(t) order by marker) from account_private.benefit_claims t))")
def main():
 assert sql('show data_directory',db='postgres',user_name='supabase_admin')=='/private/tmp/legendstudy-signup-policy-pg'
 sql('alter role postgres superuser',db='postgres',user_name='supabase_admin');sql('drop database if exists '+DB,db='postgres');sql('create database '+DB,db='postgres')
 sql("""do $$declare r text;begin foreach r in array array['essay_executor','anon','authenticated','service_role','account_lifecycle_worker'] loop if not exists(select 1 from pg_roles where rolname=r) then execute format('create role %I',r);end if;end loop;end$$;
 create schema auth;create schema essay_private;create schema account_private;
 create table auth.users(id uuid primary key,email_confirmed_at timestamptz,created_at timestamptz,active boolean);
 create table public.profiles(id uuid primary key);
 create table public.credit_accounts(id uuid primary key default gen_random_uuid(),user_id uuid unique,created_at timestamptz default now());
 create table public.credit_grants(id uuid primary key default gen_random_uuid(),account_id uuid references credit_accounts,origin text,external_reference text unique,expires_at timestamptz,created_at timestamptz default now());
 create unique index credit_signup_once_per_account on public.credit_grants(account_id) where origin='signup_bonus';
 create table public.credit_transactions(id uuid primary key default gen_random_uuid(),account_id uuid references credit_accounts,grant_id uuid references credit_grants,decision_id uuid,transaction_type text,balance_delta integer,reserved_delta integer,idempotency_key text unique,reversal_of uuid,reason_code text,actor_reference text,created_at timestamptz default now());
 create table account_private.benefit_claims(benefit_type text,key_version text,marker text,claimed_at timestamptz default now(),primary key(benefit_type,key_version,marker));
 create table account_private.benefit_delivery(subject_id uuid primary key,grant_id uuid);
 create table account_private.dispatch_health(singleton boolean primary key,enabled boolean);insert into account_private.dispatch_health values(true,true);
 create function account_private.lock_subject(uuid) returns void language sql as $$select pg_advisory_xact_lock(hashtextextended($1::text,84612))$$;
 create function account_private.allowed(uuid) returns boolean language sql security definer set search_path='' as $$select coalesce((select active from auth.users where id=$1),false)$$;
 create function essay_private.clock() returns timestamptz language sql as $$select now()$$;
 create function essay_private.uid() returns uuid language sql as $$select nullif(current_setting('test.uid',true),'')::uuid$$;
 grant usage on schema essay_private,account_private to essay_executor;
 grant all on public.credit_accounts,public.credit_grants,public.credit_transactions to essay_executor;
 grant select on public.profiles,account_private.benefit_delivery to essay_executor;
 """)
 for f in json.loads((HERE/'preimage.json').read_text()):
  sig=f["nspname"]+'.'+f['proname']+'('+f['args']+')'
  sql(f['definition']+';'+f'alter function {sig} owner to {f["owner"]};revoke all on function {sig} from public;')
  for entry in f['acl'].strip('{}').split(','):
   role=entry.split('=')[0];sql(f'grant execute on function {sig} to {role};')
 sql('create trigger essay_signup_credit after insert on public.profiles for each row execute function essay_private.credit_profile_signup()')
 old=user();claim(old,'a'*64);ok(balance(old)==3,'old_three_baseline')
 used=user();claim(used,'b'*64);sql(f"insert into credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta) select id,(select id from credit_grants where account_id=a.id),'consume',-3,0 from credit_accounts a where user_id='{used}'");ok(balance(used)==0,'exhausted_baseline')
 sql('grant essay_executor to supabase_admin with admin true');sql('grant essay_executor to postgres with admin true,inherit false,set false granted by supabase_admin;alter role postgres nosuperuser createrole bypassrls',user_name='supabase_admin');before=facts();sql((HERE/'install.sql').read_text());ok(before==facts(),'migration_preserves_all_existing_facts')
 fresh=user();claim(fresh,'c'*64);ok(balance(fresh)==2,'new_lifecycle_two')
 claim(fresh,'c'*64);ok(balance(fresh)==2,'duplicate_no_topup')
 claim(old,'a'*64);claim(used,'b'*64);ok(balance(old)==3 and balance(used)==0,'existing_three_and_exhausted_preserved')
 rejoin=user();claim(rejoin,'b'*64);ok(balance(rejoin)==0,'same_marker_new_uuid_no_second_grant')
 race=user()
 with concurrent.futures.ThreadPoolExecutor(4) as pool:list(pool.map(lambda _:claim(race,'d'*64),range(4)))
 ok(balance(race)==2,'concurrent_lifecycle_once')
 sql('update account_private.dispatch_health set enabled=false')
 legacy=user();ok(balance(legacy)==2,'legacy_profile_trigger_two')
 ok(bool(sql('select public.essay_claim_signup_credit()',role='authenticated',actor=legacy)),'legacy_own_claim')
 sql('select public.essay_claim_signup_credit()',role='authenticated',actor=old);sql('select public.essay_claim_signup_credit()',role='authenticated',actor=used)
 ok(balance(old)==3 and balance(used)==0,'legacy_claim_old_quantity_no_conflict')
 with concurrent.futures.ThreadPoolExecutor(4) as pool:list(pool.map(lambda _:sql('select public.essay_claim_signup_credit()',role='authenticated',actor=legacy),range(4)))
 ok(balance(legacy)==2,'concurrent_legacy_once')
 no=user(False);early=user(old=True)
 deny(lambda:sql('select public.essay_claim_signup_credit()',role='authenticated',actor=no),'unverified_denied')
 deny(lambda:sql('select public.essay_claim_signup_credit()',role='authenticated',actor=early),'preactivation_denied')
 deny(lambda:sql('select public.essay_claim_signup_credit()',role='anon',actor=legacy),'anon_denied')
 for role in ['anon','authenticated','service_role']:
  deny(lambda r=role:sql(f"select essay_private.credit_signup_grant('{legacy}','attack')",role=r),role+'_private_mint_denied')
 deny(lambda:sql(f"select public.account_benefit_claim('{legacy}','[]')",role='authenticated'),'lifecycle_rpc_denied_to_student')
 sql(f"update auth.users set active=false where id='{legacy}'")
 deny(lambda:sql('select public.essay_claim_signup_credit()',role='authenticated',actor=legacy),'restricted_account_denied')
 sql(f"select essay_private.credit_post_grant('{fresh}',10,'purchase','synthetic-paid','paid','fixture',null)")
 ok(balance(fresh)==12,'paid_grant_quantity_unchanged')
 sql((HERE/'postcheck.sql').read_text())
 after=facts();sql((HERE/'rollback.sql').read_text());ok(after==facts(),'rollback_preserves_two_and_three_history')
 three=user();ok(balance(three)==3,'rollback_future_three_only')
 sql('select public.essay_claim_signup_credit()',role='authenticated',actor=fresh);ok(balance(fresh)==12,'rollback_claim_two_no_conflict')
 print(json.dumps({'status':'PASS','checks':checks,'count':len(checks)},ensure_ascii=False,indent=2))
if __name__=='__main__':main()
