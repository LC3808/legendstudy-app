#!/usr/bin/env python3
"""Prepare an exact Owner SQL Editor package. Never connects to a database."""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess

FILES={
 'target':['20261008000500_target_division_identity.sql'],
 'foundation':['20261008000600_student_application_foundation.sql','20261008000700_shared_study_summary.sql','20261008000800_student360_read_foundation.sql'],
}
# Exact deployed/canonical lifecycle contracts. Drift aborts; no function is overwritten.
GUARDS={
 'account_private.allowed(uuid)':'794b021de5153ccb209b96ddbdce370e',
 'account_private.lock_subject(uuid)':'f721da4d53a6ef9abab7663c484f9aec',
 'public.admin_operator()':'98ff2257c8da2b1180e527099ab60247',
 'public.account_deletion_personal(uuid,uuid)':'1937b1d72a09548a376c06fa65ea509a',
 'public.account_deletion_postconditions(uuid,uuid)':'24a2fb3425e92a556a63511a5196da65',
}

def quoted(value):return "'"+value.replace("'","''")+"'"

def prepare(source,mode,read):
    if not re.fullmatch(r'[0-9a-f]{40}',source):raise ValueError('Full candidate SHA required')
    scripts=[(name,read(f'supabase/migrations/{name}')) for name in FILES[mode]]
    versions=[name.split('_',1)[0] for name,_ in scripts]
    header=['-- Owner SQL Editor: exact candidate '+source,'-- One transaction; no db push, Credit grant, Payment or deletion function change.','begin;',"select pg_advisory_xact_lock(hashtextextended('legendstudy/my-foundation/activation',0));",'do $preflight$ begin',
      "if exists(select 1 from supabase_migrations.schema_migrations where version in ("+','.join(map(quoted,versions))+")) then raise exception 'MIGRATION_ALREADY_RECORDED_OR_COLLISION';end if;"]
    for signature,digest in GUARDS.items():
        header.append(f"if not exists(select 1 from pg_proc where oid=to_regprocedure({quoted(signature)}) and md5(prosrc)={quoted(digest)} and pg_get_userbyid(proowner)='postgres' and prosecdef and proconfig=array['search_path=\"\"']) then raise exception 'AUTHORITY_DRIFT: {signature}';end if;")
    if mode=='foundation':
        header.append("if to_regnamespace('student_private') is not null or to_regclass('public.student_applications') is not null or to_regclass('public.student_application_events') is not null then raise exception 'FOUNDATION_OBJECT_COLLISION';end if;")
        header.append("if not exists(select 1 from pg_constraint where conrelid='public.profiles'::regclass and confrelid='auth.users'::regclass and contype='f' and confdeltype='c') then raise exception 'PROFILE_AUTH_CASCADE_REQUIRED';end if;")
    header.append('end $preflight$;')
    for name,sql in scripts:
        # Only standalone outer transaction statements. PL/pgSQL BEGIN has no semicolon.
        body=re.sub(r'^\s*(?:begin|commit);\s*$', '',sql,flags=re.M|re.I)
        version,title=name[:-4].split('_',1)
        header.extend(['\n-- '+name,body,
          'insert into supabase_migrations.schema_migrations(version,name,statements) values('+quoted(version)+','+quoted(title)+',array['+quoted(sql)+']);'])
    header.extend(["notify pgrst,'reload schema';",'commit;','select version,name from supabase_migrations.schema_migrations where version in ('+','.join(map(quoted,versions))+') order by version;'])
    return '\n'.join(header)+'\n'

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',required=True);p.add_argument('--mode',choices=FILES,default='foundation');p.add_argument('--output',required=True);p.add_argument('--target-constraint-approved',action='store_true');args=p.parse_args()
    if args.mode=='target' and not args.target_constraint_approved:p.error('Owner §74 explicit approval is required for target constraint replacement')
    def read(path):return subprocess.check_output(['git','show',args.source+':'+path],text=True)
    data=prepare(args.source,args.mode,read).encode();out=Path(args.output)
    with out.open('xb') as f:f.write(data)
    print('FILE='+str(out));print('BYTES='+str(len(data)));print('SHA256='+hashlib.sha256(data).hexdigest());print('PREPARED_ONLY — DB not changed')
