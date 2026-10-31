"""Generate reviewable candidate from the verified production function definitions."""
import json,pathlib,re
p=pathlib.Path(__file__).parent
rows=json.loads((p/'baseline.json').read_text())
def replace(s,old,new):
 assert s.count(old)==1,(old,s.count(old))
 return s.replace(old,new)
patch=[]
for r in rows:
 s=r['definition']; name=r['name']
 if name=='reserve':
  s=replace(s,"clock_timestamp()>parent.completed_at+interval '14 days'","not essay_beta_private.revision_open(parent.id)")
 elif name=='essay_exam_quote':
  s=replace(s,"clock_timestamp()>r.completed_at+interval '14 days'","not essay_beta_private.revision_open(r.id)")
  s=replace(s,"'kind',case", "'free_rewrite_expires_at',case when p_parent is not null then essay_beta_private.revision_deadline(p_parent) end,\n 'kind',case")
 elif name=='essay_exam_history':
  s=replace(s,"clock_timestamp()<=r.completed_at+interval '14 days'","essay_beta_private.revision_open(r.id)")
  s=replace(s,"'free_rewrite_available',", "'free_rewrite_expires_at',essay_beta_private.revision_deadline(r.id),\n 'free_rewrite_available',")
 elif name=='credit_summary':
  s=replace(s,'where a.user_id=u', 'where a.user_id=u and not essay_beta_private.is_beta(g.id)')
 elif name=='eligible':
  s=replace(s,"and (not s.has_math or length(btrim(s.owner_math_qa_reference))>0)","and not s.has_math and s.runtime_policy->>'evaluation_type'='humanities'")
 else: continue
 patch.append(s+';')
checks=[]
for r in rows:
 identity=f"{r['schema']}.{r['name']}({','.join(x.strip().split()[-1] for x in r['args'].split(','))})" if r['args'] else f"{r['schema']}.{r['name']}()"
 checks.append(f"if to_regprocedure('{identity}') is null or md5(pg_get_functiondef('{identity}'::regprocedure))<>'{r['digest']}' then raise exception 'BASELINE_CHANGED: {identity}';end if;")
 checks.append(f"if (select pg_get_userbyid(proowner)<>'{r['owner']}' or proacl::text is distinct from '{r['acl']}' from pg_proc where oid='{identity}'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: {identity}';end if;")
pre="do $guard$ begin\n"+'\n'.join(checks)+"\nif exists(select 1 from essay_beta_private.daily_grants) or exists(select 1 from essay_beta_private.campaigns) then raise exception 'REVIEW_EXISTING_BETA_HISTORY_FIRST';end if;\nend $guard$;\n"
(p/'precheck.sql').write_text('begin read only;\n'+pre+'rollback;\n')
(p/'install.sql').write_text('-- REVIEW CANDIDATE ONLY. Does not activate beta.\nbegin;\n'+pre+(p/'runtime.sql').read_text()+'\n'+'\n'.join(patch)+'\ncommit;\n')
# After activation rollback must stop NEW claims without removing expiry/allocator fences.
(p/'rollback.sql').write_text("-- Emergency stop only; retains all grants, runs, ledger and beta revision deadlines.\nbegin;\nupdate essay_beta_private.campaigns set enabled=false where enabled;\ncommit;\n-- Never restore old unscoped allocators or delete grant history after activation.\n")
print('generated install/precheck/rollback; finish and Provider remain unchanged')

manifest=p/'expected-functions.json'
if manifest.exists():
 assertions=[]
 for row in json.loads(manifest.read_text()):
  identity=row['identity']
  assertions.append(f"if md5(pg_get_functiondef('{identity}'::regprocedure))<>'{row['digest']}' then raise exception 'DEPLOYMENT_DEFINITION_MISMATCH: {identity}';end if;")
  assertions.append(f"if (select pg_get_userbyid(proowner)<>'{row['owner']}' or proacl::text is distinct from '{row['acl']}' from pg_proc where oid='{identity}'::regprocedure) then raise exception 'DEPLOYMENT_SECURITY_MISMATCH: {identity}';end if;")
 (p/'verify.sql').write_text('begin read only;\ndo $verify$ begin\n'+'\n'.join(assertions)+"\nend $verify$;\nselect count(*) as campaigns,count(*) filter(where enabled) as active_campaigns from essay_beta_private.campaigns;\nselect count(*) as beta_grants from essay_beta_private.daily_grants;\nselect p.oid::regprocedure,p.prosecdef,p.proconfig,p.proacl from pg_proc p where p.oid in ('public.essay_beta_daily_claim_v2()'::regprocedure,'public.essay_beta_notice_ack(uuid)'::regprocedure);\nrollback;\n")
