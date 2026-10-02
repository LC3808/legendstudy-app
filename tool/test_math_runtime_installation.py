#!/usr/bin/env python3
"""Runtime migration/rollback at actual non-superuser topology; inherits isolated-only runner."""
import inspect,json,hashlib
from pathlib import Path
import psycopg
import test_math_installation as i
R=i.R;V=i.V/'runtime';M=R/'supabase/migrations/20261002000200_math_runtime_surface.sql'
def runtime(c):
 before=i.b.snapshot(c);body=M.read_text();passed=[]
 markers=['grant math_executor to postgres with admin false,inherit false,set true granted by postgres;','grant create on schema public to math_executor;','set role math_executor;','reset role;',"grant execute on function public.math_evaluation(jsonb) to math_evaluation_worker;"]
 for n,marker in enumerate(markers):
  try:c.execute(body.replace(marker,marker+"\ndo $$begin raise exception 'RUNTIME_INJECT';end$$;",1));raise AssertionError('no injected failure')
  except psycopg.errors.RaiseException as e:assert e.diag.message_primary=='RUNTIME_INJECT'
  finally:c.execute('rollback')
  assert i.b.snapshot(c)==before;passed.append('failure_'+str(n))
 c.execute(body)
 c.execute((V/'catalog.sql').read_text())
 for name,role in [('qlm_quality','authenticated'),('math_input','authenticated'),('math_extraction','math_extraction_worker'),('math_evaluation','math_evaluation_worker')]:
  row=c.execute("select pg_get_userbyid(proowner),prosecdef,proconfig,proargnames from pg_proc where oid=%s::regprocedure",('public.'+name+'(jsonb)',)).fetchone();assert row==('postgres',True,['search_path=""'],['p_request']),row
  acl=c.execute("select pg_get_userbyid(a.grantee)::text from pg_proc p cross join lateral aclexplode(p.proacl) a where p.oid=%s::regprocedure order by 1",('public.'+name+'(jsonb)',)).fetchall();assert acl==sorted([(role,),('postgres',)]),acl
 assert i.b.snapshot(c)['memberships']==before['memberships'];assert i.b.snapshot(c)['schemas']==before['schemas'];passed.append('topology_acl_security')
 # Owner-only definition snapshot drives documentation; not a Production-generated client type.
 mapping=c.execute("select oid::regprocedure::text,pg_get_function_arguments(oid),pg_get_function_result(oid),pg_get_userbyid(proowner),prosecdef,proconfig,proacl::text from pg_proc where pronamespace='public'::regnamespace and (proname like 'math_%' or proname like 'qlm_%') order by proname").fetchall()
 (V/'physical_catalog.json').write_text(json.dumps({'provenance':'isolated canonical MATH-2C + MATH-2D PG17 schema','functions':mapping,'input_columns':c.execute("select table_name,column_name,data_type,is_nullable,column_default from information_schema.columns where table_schema='public' and table_name in ('math_attempts','math_attempt_artifacts','math_extraction_runs','math_extraction_regions','math_evaluations') order by table_name,ordinal_position").fetchall()},indent=2)+'\n')
 c.execute('create view public.math_runtime_dependency as select public.math_input(null::jsonb)')
 try:c.execute((V/'rollback.sql').read_text());raise AssertionError('dependency ignored')
 except psycopg.errors.DependentObjectsStillExist:pass
 finally:c.execute('rollback')
 c.execute('drop view public.math_runtime_dependency');passed.append('unexpected_dependency_abort')
 c.execute((V/'rollback.sql').read_text());assert i.b.snapshot(c)==before;passed.append('exact_empty_install_rollback')
 (V/'ownership_validation.json').write_text(json.dumps(dict(checks=passed,count=len(passed),migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),execution_superuser=False,production_writes=0),indent=2)+'\n')
source=inspect.getsource(i.verify).replace(' c.execute(candidate)\n',' c.execute(candidate)\n runtime(c)\n')
ns=dict(i.__dict__);ns['runtime']=runtime;exec(source,ns);i.verify=ns['verify']
main=inspect.getsource(i.main).replace("(V/'installation_validation.json')","(V/'runtime/installation_validation.json')")
ns=dict(i.__dict__);exec(main,ns);ns['main']()
