#!/usr/bin/env python3
"""Non-superuser C/D/E apply, bootstrap failure restoration and bounded rollback."""
from pathlib import Path
import json,hashlib
import psycopg
import test_math_installation as i
R=i.R;E=R/'supabase/verification/math_essay/learning';M=R/'supabase/migrations/20261002000300_math_learning_runtime.sql'
def learning(c):
 before=i.b.snapshot(c);body=M.read_text();checks=[]
 c.execute((E/'catalog.sql').read_text())
 for n,marker in enumerate(['grant math_executor to postgres with admin false,inherit false,set true granted by postgres;','grant create on schema math_private to math_executor;','set role math_executor;','reset role;','grant execute on function public.math_learning(jsonb) to authenticated;']):
  assert marker in body
  try:c.execute(body.replace(marker,marker+"\ndo $$begin raise exception 'LEARNING_INJECT';end$$;",1));raise AssertionError('failure absent')
  except psycopg.errors.RaiseException as ex:assert ex.diag.message_primary=='LEARNING_INJECT'
  finally:c.execute('rollback')
  assert i.b.snapshot(c)==before;checks.append('failure_'+str(n))
 c.execute(body);c.execute((E/'postflight.sql').read_text());after=i.b.snapshot(c)
 assert before['memberships']==after['memberships'] and before['schemas']==after['schemas']
 inventory=json.loads((E/'ownership.json').read_text())
 for f in inventory['new_functions']+inventory['changed_functions']:
  sig=f['signature'].replace('p_request jsonb','jsonb')
  row=c.execute('select pg_get_userbyid(proowner),prosecdef,proconfig,provolatile from pg_proc where oid=%s::regprocedure',(sig,)).fetchone()
  assert row==(f['owner'],f['security']=='DEFINER',['search_path=""'],'s' if f['volatility']=='STABLE' else 'v'),(sig,row)
  acl=c.execute('select pg_get_userbyid(a.grantee) from pg_proc p cross join lateral aclexplode(proacl) a where oid=%s::regprocedure order by 1',(sig,)).fetchall();assert acl==sorted((r,) for r in f['execute']),(sig,acl)
 checks.append('function_owner_acl_security_volatility_search_path')
 assert all(x in after['relations'] for x in before['relations']) and before['policies']==after['policies'];checks.append('rls_table_acl_preserved')
 old={x[0]:x for x in before['functions']};new={x[0]:x for x in after['functions']}
 # Only the explicitly allowlisted existing validator may differ.
 changed=[k for k in old if old[k]!=new.get(k)];assert len(changed)==1,changed
 checks.append('existing_function_preservation')
 c.execute('create view public.learning_dependency as select public.math_learning(null::jsonb)')
 try:c.execute((E/'rollback.sql').read_text());raise AssertionError('dependency accepted')
 except psycopg.errors.DependentObjectsStillExist:pass
 finally:c.execute('rollback')
 c.execute('drop view public.learning_dependency');checks.append('unexpected_dependency_abort')
 c.execute((E/'rollback.sql').read_text());restored=i.b.snapshot(c)
 assert before==restored,[k for k in before if before[k]!=restored[k]]
 checks.append('exact_empty_install_rollback')
 (E/'ownership_validation.json').write_text(json.dumps(dict(checks=checks,count=len(checks),migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),execution_superuser=False,production_writes=0),indent=2)+'\n')
s=(R/'tool/test_math_runtime_installation.py').read_text().replace(' c.execute(body)\n',' c.execute(body)\n learning(c)\n')
s=s.replace("(V/'physical_catalog.json')","(E/'runtime_physical_catalog.json')").replace("(V/'ownership_validation.json')","(E/'runtime_ownership_validation.json')").replace("runtime/installation_validation.json","learning/installation_validation.json")
exec(compile(s,str(R/'tool/test_math_runtime_installation.py'),'exec'),{'__file__':str(R/'tool/test_math_runtime_installation.py'),'__name__':'__main__','learning':learning,'E':E})
