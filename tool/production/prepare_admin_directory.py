#!/usr/bin/env python3
"""Prepare only Admin directory009 for Owner SQL Editor; never connect to DB."""
import argparse,hashlib,re,subprocess
from pathlib import Path
FILE='supabase/migrations/20261008000900_admin_member_directory.sql'
GUARDS={'account_private.allowed(uuid)':'794b021de5153ccb209b96ddbdce370e','public.admin_operator()':'98ff2257c8da2b1180e527099ab60247'}
def quote(s):return "'"+s.replace("'","''")+"'"
def prepare(source,read):
 if not re.fullmatch('[0-9a-f]{40}',source):raise ValueError('Full SHA required')
 sql=read(FILE)
 lines=['-- Owner-reviewed Admin directory009 ONLY; no Target005 or Essay runtime activation.', '-- Candidate '+source,'begin;',"set local lock_timeout='5s';","set local statement_timeout='60s';","select pg_advisory_xact_lock(hashtextextended('legendstudy/admin-directory/activation',0));",'do $preflight$ begin',
 "if current_user<>'postgres' then raise exception 'EXPECTED_POSTGRES_OWNER';end if;",
 "if exists(select 1 from supabase_migrations.schema_migrations where version='20261008000900') then raise exception 'MIGRATION_COLLISION';end if;",
 "if (select count(*) from supabase_migrations.schema_migrations where version in ('20261008000600','20261008000700','20261008000800'))<>3 then raise exception 'EXISTING_FOUNDATION_REQUIRED';end if;",
 "if to_regnamespace('student_private') is null or to_regclass('student_private.school_display_cache') is not null or exists(select 1 from pg_proc where pronamespace='public'::regnamespace and proname='admin_member_list') then raise exception 'DIRECTORY_OBJECT_COLLISION';end if;"]
 for signature,digest in GUARDS.items():
  lines.append(f"if not exists(select 1 from pg_proc where oid=to_regprocedure({quote(signature)}) and md5(prosrc)={quote(digest)} and pg_get_userbyid(proowner)='postgres' and prosecdef and proconfig=array['search_path=\"\"']) then raise exception 'AUTHORITY_DRIFT: {signature}';end if;")
 lines+=['end $preflight$;',re.sub(r'^\s*(begin|commit);\s*$','',sql,flags=re.M|re.I),"insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008000900','admin_member_directory',array["+quote(sql)+']);',"notify pgrst,'reload schema';",'commit;',"select version,name from supabase_migrations.schema_migrations where version='20261008000900';"]
 return '\n'.join(lines)+'\n'
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',required=True);p.add_argument('--output',required=True);a=p.parse_args()
 data=prepare(a.source,lambda path:subprocess.check_output(['git','show',a.source+':'+path],text=True)).encode()
 with Path(a.output).open('xb') as f:f.write(data)
 print('FILE='+a.output);print('BYTES='+str(len(data)));print('SHA256='+hashlib.sha256(data).hexdigest());print('PREPARED_ONLY — DB not changed')
