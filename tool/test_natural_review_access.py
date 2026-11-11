"""Rehearse shared, closed Owner scope over all186 leaves in disposable PG17 only.
Reuses the existing KAU boundary cases and baseline fixture; never calls a Provider.
"""
import inspect,json,hashlib
from pathlib import Path
import test_kau_review as prior
from psycopg import sql
stage=prior.stage;R=stage.R
B=R/'supabase/candidates/natural_owner_review_20261112';P=R/'.local/natural-owner-review-20261112'
SCOPE=R/'supabase/candidates/natural_tech_ready_20261112/integrated-review-scope.json'
def seed_scope(c):
 scope=json.loads(SCOPE.read_text());packages=[]
 # Only synthetic Registry metadata in an isolated fixture; originals remain untouched.
 for q in scope['questions']:
  c.execute("insert into public.universities(id,slug,name,is_active) values(%s,%s,'Synthetic university',false) on conflict(id) do nothing",(q['university_id'],'fixture-'+q['university_id']))
  c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,verification_status,provenance,is_active) values(%s,%s,%s,%s,'Synthetic exam','admission','review','official',false) on conflict(id) do nothing",(q['exam_id'],q['university_id'],q['year'],'fixture-'+q['exam_id']))
  c.execute('insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,is_published,metadata_version) values(%s,%s,%s,%s,%s,false,1) on conflict(id) do nothing',(q['question_id'],q['exam_id'],q['question_key'],q['label'],q['display_order']))
  if q['status']=='TECH_READY':
   raw=(R/q['private_package_directory']/(q['question_id']+'.package.private.json')).read_bytes();assert hashlib.sha256(raw).hexdigest()==q['package_sha256'];package=json.loads(raw);package['existing_schema_rows']={t:package['existing_schema_rows'][t] for t in stage.ORDER};packages.append(package)
 c.execute(stage.registration_sql(packages));return packages

def main():
 source=inspect.getsource(prior.review_case)
 source=source.replace("c.execute((stage.PRIVATE/'apply-draft.private.sql').read_text())","c.execute((stage.PRIVATE/'apply-draft.private.sql').read_text());packages=seed_scope(c)")
 source=source.replace("(P/'owner.private.json')","(R/'.local/kau-owner-review-20261112/owner.private.json')")
 source=source.replace("(B/'production-runtime-functions.json')","(R/'supabase/candidates/kau_owner_review_20261112/production-runtime-functions.json')")
 source=source.replace('kau_review','natural_review').replace('KAU_REVIEW_DENIED','OWNER_REVIEW_DENIED').replace('REVIEW_REQUIRES_SEVEN_DRAFT','REVIEW_REQUIRES_EXACT_DRAFT_SCOPE')
 source=source.replace("rpc('math_catalog',[50]","rpc('math_catalog',[200]")
 source=source.replace('exactly_seven_added','exactly_186_added').replace('len(catalog)+7','len(catalog)+186')
 source=source.replace(" def enable():c.execute(\"update math_private.natural_review_control set enabled=true,valid_until=clock_timestamp()+interval '1 hour'\")"," def enable():\n  c.execute(\"update math_private.natural_review_control set enabled=true,valid_until=clock_timestamp()+interval '1 hour'\")\n  c.execute('update math_private.natural_review_scope set approved_for_review=true')")
 source=source.replace(" content('ACTIVE');enable()", """ content('ACTIVE')
 ok('exact_scope_186_default_unapproved',scalar('select count(*) from math_private.natural_review_scope where not approved_for_review')==186)
 for role in ['anon','authenticated','service_role']:
  ok(role+'_no_scope_table_access',not scalar("select has_table_privilege(%s,'math_private.natural_review_scope','SELECT')",(role,)))
 c.execute("update math_private.natural_review_control set enabled=true,valid_until=clock_timestamp()+interval '1 hour'")
 deny('global_enabled_cannot_bypass_leaf_approval',lambda:submit(packages[0]),'OWNER_REVIEW_DENIED')
 enable()
 c.execute('update math_private.natural_review_scope set approved_for_review=false where leaf_id=%s',(packages[-1]['ids']['leaf'],))
 deny('one_leaf_revocation_blocks_owner',lambda:submit(packages[-1]),'OWNER_REVIEW_DENIED')
 ok('other_university_leaf_remains_allowed',scalar('select math_private.natural_review_allowed(%s,%s)',(owner,packages[0]['ids']['leaf'])))
 enable()""")
 source=source.replace(" ok('hold_five_absent'", """ for status in ['HOLD','NOT_READY','PARTIAL']:
  excluded=[q['question_id'] for q in json.loads((R/'supabase/candidates/natural_tech_ready_20261112/integrated-review-scope.json').read_text())['questions'] if q['status']==status]
  ok(status+'_excluded_from_review_scope',scalar('select count(*) from math_private.natural_review_scope where question_id=any(%s::uuid[])',(excluded,))==0)
 ok('hold_five_absent'""")
 source=source.replace(" sid=new();rpc('account_reauth_attest'", """ c.execute("update public.account_deletion_requests set state='ERASING' where subject_id=%s and state='DELETION_PENDING'",(owner,))
 deny('erasing_owner_submit_denied',lambda:submit(p),'ACCOUNT')
 ok('erasing_gate_false',not scalar('select math_private.natural_review_allowed(%s,%s)',(owner,p['ids']['leaf'])))
 c.execute("update public.account_deletion_requests set state='DELETION_PENDING' where subject_id=%s and state='ERASING'",(owner,))
 sid=new();rpc('account_reauth_attest'""")
 ns=dict(prior.__dict__);ns.update(B=B,P=P,seed_scope=seed_scope);exec(source,ns)
 setup=inspect.getsource(stage.content_case).split(' checks=[]')[0]+'\n review_case(c,rpc,new,scalar,A,B,old,packages)\n'
 env=dict(stage.__dict__);env['review_case']=ns['review_case'];exec(setup,env);stage.content_case=env['content_case'];stage.main()
if __name__=='__main__':main()
