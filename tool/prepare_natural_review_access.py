"""Generate closed review-admission candidate. No network/DB connector or activation."""
import hashlib,json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
B=R/'supabase/candidates/natural_owner_review_20261112'
PRIVATE=R/'.local/natural-owner-review-20261112'
STAGE1=R/'supabase/candidates/natural_expansion_20261111/kau-production-preflight'
def sha(s):return hashlib.sha256(s.encode()).hexdigest()
def build(owner):
 import uuid
 owner=str(uuid.UUID(owner))
 scope=json.loads((R/'supabase/candidates/natural_tech_ready_20261112/integrated-review-scope.json').read_text());qs=[q for q in scope['questions'] if q['status']=='TECH_READY'];assert len(qs)==186 and not scope['production_execution_approved']
 assert len({q['question_id'] for q in qs})==len(qs) and len({q['leaf_id'] for q in qs})==len(qs)
 for q in qs:
  for key in ['leaf_id','question_id','exam_id']:assert str(uuid.UUID(q[key]))==q[key]
 leaves=[q['leaf_id'] for q in qs];arr='array['+','.join("'"+x+"'::uuid" for x in leaves)+']'
 functions=json.loads((STAGE1/'production-functions.json').read_text())+json.loads((R/'supabase/candidates/kau_owner_review_20261112/production-runtime-functions.json').read_text())
 names=['resolve_profile','release_catalog','math_claim_evaluation','math_claim_extraction'];old={n:next(f['definition'] for f in functions if f['name']==n) for n in names}
 signatures={'resolve_profile':'math_private.resolve_profile(uuid)','release_catalog':'math_private.release_catalog(uuid)','math_claim_evaluation':'public.math_claim_evaluation(uuid)','math_claim_extraction':'public.math_claim_extraction(uuid)'}
 def deny(subject,leaf):return f" if {leaf}=any({arr}) and not math_private.natural_review_allowed({subject},{leaf}) then raise insufficient_privilege using message='OWNER_REVIEW_DENIED';end if;\n"
 changed={}
 changed['resolve_profile']=old['resolve_profile'].replace('begin\n','begin\n'+deny('math_private.current_subject()','$1'),1)
 f=old['release_catalog'];assert f.count('where l.id=any(array[')==1 and f.count(") and p.state='ACTIVE'")==1
 f=f.replace('where l.id=any(array[','where (l.id=any(array[',1).replace(") and p.state='ACTIVE'", ") or math_private.natural_review_allowed(math_private.current_subject(),l.id)) and (not l.id=any("+arr+") or math_private.natural_review_allowed(math_private.current_subject(),l.id)) and p.state='ACTIVE'",1);changed['release_catalog']=f
 f=old['math_claim_evaluation'];needle=' select * into e from public.math_evaluations where id=$1;\n';assert f.count(needle)==1;changed['math_claim_evaluation']=f.replace(needle,needle+deny('u','e.leaf_id'))
 f=old['math_claim_extraction'];needle=' select * into a from public.math_attempts where id=$1;\n';assert f.count(needle)==1;changed['math_claim_extraction']=f.replace(needle,needle+deny('a.student_id','a.leaf_id'))
 def guard(defs):return '\n'.join("do $$begin if md5(pg_get_functiondef('"+signatures[n]+"'::regprocedure))<>'"+hashlib.md5(f.encode()).hexdigest()+"' then raise exception 'REVIEW_FUNCTION_DRIFT: "+n+"';end if;end$$;" for n,f in defs.items())
 pre="""begin;
set local lock_timeout='5s';
select pg_advisory_xact_lock(20261112,53);
"""
 state_guard="do $$begin if (select count(*) from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id where l.id=any("+arr+") and p.state='DRAFT' and s.state='DRAFT')<>186 then raise exception 'REVIEW_REQUIRES_EXACT_DRAFT_SCOPE';end if;end$$;\n"
 values=','.join("('%s'::uuid,'%s'::uuid,false)"%(q['leaf_id'],q['question_id']) for q in qs)
 scope_sql="""
create table math_private.natural_review_scope(
 leaf_id uuid primary key references public.math_subproblems(id),
 question_id uuid not null unique references public.essay_questions(id),
 approved_for_review boolean not null default false
);
alter table math_private.natural_review_scope enable row level security;
revoke all on math_private.natural_review_scope from public,anon,authenticated,service_role;
"""+'insert into math_private.natural_review_scope values '+values+';\n'
 scope_sql+="do $$begin if exists(select 1 from math_private.natural_review_scope r join public.math_subproblems l on l.id=r.leaf_id where l.essay_question_id is distinct from r.question_id) then raise exception 'REVIEW_REGISTRY_BINDING_DRIFT';end if;end$$;\n"
 install=pre+guard(old)+'\n'+state_guard+"""
create table math_private.natural_review_control(
 singleton boolean primary key default true check(singleton),
 owner_subject uuid not null references auth.users(id),
 enabled boolean not null default false,
 valid_until timestamptz,
 created_at timestamptz not null default clock_timestamp(),
 check(not enabled or valid_until is not null)
);
alter table math_private.natural_review_control enable row level security;
revoke all on math_private.natural_review_control from public,anon,authenticated,service_role;
"""+f"insert into math_private.natural_review_control(singleton,owner_subject,enabled) values(true,'{owner}',false);\n"+scope_sql+"""
create function math_private.natural_review_allowed(p_subject uuid,p_leaf uuid) returns boolean
language sql stable security definer set search_path='' as $gate$
 select p_subject is not null and p_leaf=any("""+arr+""") and exists(
 select 1 from math_private.natural_review_control c where c.singleton and c.enabled
 and c.owner_subject=p_subject and c.valid_until>statement_timestamp()
 and account_private.allowed(p_subject)) and exists(
 select 1 from math_private.natural_review_scope r where r.leaf_id=p_leaf and r.approved_for_review);
$gate$;
revoke all on function math_private.natural_review_allowed(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function math_private.natural_review_allowed(uuid,uuid) to math_executor;
"""+'\n'.join(changed[n].rstrip()+';' for n in names)+"\ncommit;\n"
 close=pre+"update math_private.natural_review_control set enabled=false where singleton;\ncommit;\n"
 restore=pre+guard(changed)+'\n'+state_guard+"update math_private.natural_review_control set enabled=false where singleton;\n"+'\n'.join(old[n].rstrip()+';' for n in names)+"\n-- Keep the disabled private control row/helper as audit evidence. No history deletion.\ncommit;\n"
 PRIVATE.mkdir(exist_ok=True);B.mkdir(exist_ok=True)
 (PRIVATE/'install-closed.private.sql').write_text(install)
 (B/'close.sql').write_text(close);(B/'restore-functions.sql').write_text(restore)
 (B/'function-diff.json').write_text(json.dumps({n:dict(signature=signatures[n],before=old[n],after=changed[n]) for n in names},indent=2)+'\n')
 receipt=dict(owner_subject_sha256=sha(owner),scope=leaves,scope_manifest_sha256=hashlib.sha256((R/'supabase/candidates/natural_tech_ready_20261112/integrated-review-scope.json').read_bytes()).hexdigest(),per_leaf_approval_default=False,execution_ready=False,private_install=str(PRIVATE/'install-closed.private.sql'),install_sha256=sha(install),close_sha256=sha(close),restore_sha256=sha(restore),activation_included=False,provider_calls=0,production_writes=0)
 (B/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(dict(questions=len(qs),new_private_table=2,new_private_helper=1,patched_existing_functions=4,enabled=False,install_sha256=sha(install))))
if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--owner-file',type=Path,required=True);a=p.parse_args();build(json.loads(a.owner_file.read_text())['owner_subject'])
