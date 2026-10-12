"""New read RPC against real Math/account lifecycle DDL, local Unix PG only.
Existing Math setup runs once; no live database/provider or real student data.
"""
import inspect,json
from pathlib import Path
import test_math_persistence as m
R=m.R
M=R/'supabase/migrations/20261012215054_essay_private_registry_read.sql'
def cases(c,rpc,new,scalar,A,B,OP,*unused):
 checks=[]
 def ok(name,value=True):assert value,name;checks.append(name)
 def deny(fn):
  try:fn()
  except m.psycopg.Error as e:assert e.sqlstate in ('42501','P0001');return
  raise AssertionError('unexpected permission')
 manifest=json.loads((R/'supabase/reviews/essay-source-registration/manifest.json').read_text())
 for e in manifest['exams']:
  c.execute("insert into public.universities(id,slug,name) values(%s,%s,'Fixture') on conflict(id) do nothing",(e['universityId'],e['universityId']))
  c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind) values(%s,%s,%s,%s,'Fixture',%s)",(e['examId'],e['universityId'],e['year'],e['examKey'],e['kind']))
  for q in e['questions']:
   c.execute("insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version,is_published) values(%s,%s,%s,%s,%s,'source-registration-v1',false)",(q['id'],e['examId'],q['sourceKey'],q['label'],q['order']))
 security=scalar("select jsonb_agg(to_jsonb(p)) from pg_policies p where tablename in ('essay_questions','essay_exams')")
 credit=scalar('select count(*) from public.credit_transactions')
 c.execute(M.read_text())
 rows=rpc('essay_registered_questions',[A],role='essay_worker')
 ok('234_exact_private_ids',len(rows)==234 and {x['id'] for x in rows}=={q['id'] for e in manifest['exams'] for q in e['questions']})
 ok('metadata_only',all(set(x)=={'id','essay_exam_id','question_key','metadata_version','is_published','essay_exams'} and not x['is_published'] for x in rows))
 for role in ['anon','authenticated','service_role','math_evaluation_worker','math_extraction_worker']:
  deny(lambda role=role:rpc('essay_registered_questions',[A],role=role))
 ok('all_other_roles_denied')
 deny(lambda:rpc('essay_registered_questions',[None],role='essay_worker'))
 deny(lambda:rpc('essay_registered_questions',[new()],role='essay_worker'))
 c.execute('update account_private.dispatch_health set enabled=true')
 rpc('account_deletion_request',uid=B)
 deny(lambda:rpc('essay_registered_questions',[B],role='essay_worker'))
 ok('real_account_lifecycle_denied')
 ok('unchanged_rls_and_credit',security==scalar("select jsonb_agg(to_jsonb(p)) from pg_policies p where tablename in ('essay_questions','essay_exams')") and credit==scalar('select count(*) from public.credit_transactions'))
 c.execute((R/'supabase/reviews/essay-private-registry/rollback.sql').read_text())
 ok('rollback_removes_only_rpc',scalar("select to_regprocedure('public.essay_registered_questions(uuid)')") is None and scalar("select count(*) from public.essay_questions where metadata_version='source-registration-v1'")==234)
 c.execute(M.read_text());ok('reinstall_after_rollback')
 Path('/private/tmp/essay-private-registry-verification.json').write_text(json.dumps({'checks':checks,'productionApplied':False,'providerCalls':0},indent=2))
 print('PRIVATE_REGISTRY',len(checks),'PASS')
 return checks
# Reuse canonical dependency setup but preserve its prior verification artifact.
source=inspect.getsource(m.verify).replace("R/'supabase/verification/math_essay/behavior_validation.json'","Path('/private/tmp/essay-private-registry-math-regression.json')")
ns=dict(m.__dict__);ns.update(verify_math_cases=cases,Path=Path)
exec(source,ns)
m.h.verify_hqp=ns['verify']
if __name__=='__main__':m.h.main(bootstrap_user='supabase_admin')
