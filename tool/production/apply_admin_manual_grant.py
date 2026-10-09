"""Apply only the Owner-approved additive Admin RPC after exact dependency checks.
Management credential is used solely for migrations, never as a student/operator JWT.
"""
import argparse, hashlib, json, os, pathlib, urllib.request
ROOT = pathlib.Path(__file__).resolve().parents[2]
VERSION = '20261009000100'
MIGRATION = ROOT / 'supabase/migrations/20261009000100_admin_manual_credit_grant.sql'
EXPECTED = {
 'public.admin_operator()': '98ff2257c8da2b1180e527099ab60247',
 'account_private.allowed(uuid)': '794b021de5153ccb209b96ddbdce370e',
 'account_private.lock_subject(uuid)': 'f721da4d53a6ef9abab7663c484f9aec',
 'essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)': '0d54d2db17f289a20ee6a3f914ec3fdc',
 'public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)': '05b606aecdca2a6d6937b3d009e21575',
}
def query(sql, read_only=True):
    request = urllib.request.Request('https://api.supabase.com/v1/projects/stlhijzpjfgwwdgunlsd/database/query',
        data=json.dumps({'query':sql,'read_only':read_only}).encode(),
        headers={'Authorization':'Bearer '+os.environ['SUPABASE_ACCESS_TOKEN'],'Content-Type':'application/json'})
    with urllib.request.urlopen(request,timeout=60) as response: return json.load(response)
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');args=parser.parse_args()
    source=MIGRATION.read_text(); digest=hashlib.sha256(source.encode()).hexdigest()
    assertions='\n'.join(f"if (select md5(prosrc) from pg_proc where oid='{signature}'::regprocedure) is distinct from '{md5}' then raise exception 'DEPENDENCY_CHANGED';end if;" for signature,md5 in EXPECTED.items())
    guard=f"""do $guard$ begin
    {assertions}
    if exists(select 1 from supabase_migrations.schema_migrations where version='{VERSION}')
    or to_regprocedure('public.admin_manual_credit_grant(uuid,text,integer,text,uuid)') is not null then raise exception 'ALREADY_APPLIED_OR_COLLISION';end if;
    if not has_function_privilege('postgres','essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)','execute') then raise exception 'MISSING_HELPER_EXECUTE';end if;
    end $guard$;"""
    # No broad db push: a single transaction includes guard, exact file, and ledger entry.
    body=source[source.index('begin;')+len('begin;'):source.rindex('commit;')]
    query('begin read only;'+guard+'rollback;')
    print('PREFLIGHT_PASS SHA256='+digest)
    if args.apply:
        statement=source.replace("'","''")
        sql="begin;select pg_advisory_xact_lock(hashtext('legendstudy-admin-manual-grant-migration'));"+guard+body
        sql+=f"insert into supabase_migrations.schema_migrations(version,name,statements) values('{VERSION}','admin_manual_credit_grant',array['{statement}']);commit;"
        query(sql,False)
        print('PRODUCTION_APPLIED='+VERSION)
        print(json.dumps(query((ROOT/'supabase/verification/admin_manual_grant/postflight.sql').read_text())))
if __name__=='__main__':main()
