"""Generate review-only DRAFT apply/check/retire SQL from private packages.

No DB connector. Never grants, activates or deletes; rollback retains history.
"""
import argparse,json
from pathlib import Path
from essay_lab.natural_expansion import require
from essay_lab.task20_priority_packages import literal

PRESERVE=['essay_attempts','essay_evaluations','credit_transactions']
STATE_TABLES=['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']
def build(root):
    require('.local' in root.resolve().parts,'PRIVATE_OUTPUT_REQUIRED')
    pp=[json.loads(p.read_text()) for p in sorted(root.glob('*.package.private.json'))]
    require(pp and all(p['state']=='DRAFT' and p['publication_allowed'] is False for p in pp),'DRAFT_REQUIRED')
    ids={t:[r['id'] for p in pp for r in p['existing_schema_rows'][t]] for t in pp[0]['existing_schema_rows']}
    guard="""do $guard$ begin
 if md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure)) <> '54acd2a1914f360e6ecd62e39acc8222' then raise exception 'WORKER_DEFINITION_DRIFT'; end if;
 if has_table_privilege('anon','math_private.task20_hanyang_source_pages','SELECT') or has_table_privilege('authenticated','math_private.task20_hanyang_source_pages','SELECT') then raise exception 'PRIVATE_SOURCE_ACL_DRIFT'; end if;
end $guard$;"""
    preserved=" union all ".join("select "+literal(t)+" name,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public."+t+" x" for t in PRESERVE)
    unchanged="do $preserve$ begin if exists(select 1 from ("+preserved+") current_rows full join _natural_preserve prior_rows using(name) where current_rows.digest is distinct from prior_rows.digest) then raise exception 'EXISTING_HISTORY_DRIFT'; end if; end $preserve$;"
    registration=(root/'register-draft.private.sql').read_text().strip();require(registration.startswith('begin;') and registration.endswith('commit;'),'TRANSACTION_FORMAT')
    worker=(root/'worker-source.private.sql').read_text();worker=worker[worker.index('begin;')+6:worker.rindex('commit;')]
    qids=','.join(literal(p['essay_question_id']) for p in pp)
    sql='-- REVIEW CANDIDATE ONLY; separate Owner authorization required. DRAFT only.\nbegin;\n'+guard+'\ncreate temp table _natural_preserve on commit drop as '+preserved+';\n'
    sql+="do $registry$ begin if exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id in ("+qids+") and (q.is_published or e.is_active)) then raise exception 'PUBLICATION_STATE_DRIFT'; end if; end $registry$;\n"
    sql+=registration[6:-7]+worker+'\n'+unchanged+'\ncommit;\n';(root/'apply-draft.private.sql').write_text(sql)
    checks=['begin read only;','-- All expected rows are exact manifest IDs; state must remain DRAFT.']
    for table,values in ids.items():
        checks.append('select '+literal(table)+' object,'+str(len(values))+' expected,count(*) actual'+(",bool_and(state='DRAFT') all_draft" if table in STATE_TABLES else '')+' from public.'+table+' where id in ('+','.join(map(literal,values))+');')
    checks.append('select count(*) worker_sources from math_private.task20_hanyang_source_pages where question_id in ('+qids+');')
    checks.append("select md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure)) worker_md5;")
    checks.append("select r,has_table_privilege(r,'math_private.task20_hanyang_source_pages','SELECT') source_read,has_function_privilege(r,'math_private.hanyang_worker_references(jsonb)','EXECUTE') worker_execute from unnest(array['anon','authenticated']) r;")
    checks.append('commit;');(root/'verify.sql').write_text('\n'.join(checks)+'\n')
    before=['begin read only;','-- Expected: every Registry identity exists, no foreign leaf/Worker/publication, helper hash matches.']
    for p in pp:
        before.append('select '+literal(p['essay_question_id'])+' question_id,exists(select 1 from public.essay_questions where id='+literal(p['essay_question_id'])+' and essay_exam_id='+literal(p['exam_id'])+') registry_matches,(select count(*) from public.math_subproblems where essay_question_id='+literal(p['essay_question_id'])+') existing_leaves,exists(select 1 from math_private.task20_hanyang_source_pages where question_id='+literal(p['essay_question_id'])+') existing_worker;')
    before+=checks[-3:-1]+[preserved+';','commit;'];(root/'preflight.sql').write_text('\n'.join(before)+'\n')
    rollback=['-- REVIEW ONLY. Close approved WEB release scope first. No DELETE, DROP or global ACL change.','begin;',"set local lock_timeout='5s';",guard]
    for table in STATE_TABLES:
        rollback.append('update public.'+table+" set state='RETIRED' where id in ("+','.join(map(literal,ids[table]))+") and state in ('DRAFT','ACTIVE');")
    rollback+=['-- Candidate sources, Registry, attempts, evaluations and credit history are retained.','commit;']
    (root/'rollback-retire.sql').write_text('\n'.join(rollback)+'\n')
    return dict(packages=len(pp),rows=sum(map(len,ids.values())),objects=list(ids)+['math_private.task20_hanyang_source_pages'])

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args();print(json.dumps(build(a.root)))
