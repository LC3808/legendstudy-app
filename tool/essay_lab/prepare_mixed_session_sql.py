"""Combine exact content approval with existing confirmed-input candidate.
No execution. Actual production definitions, not stale submit migrations, are patched.
"""
import argparse,json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from essay_lab.prepare_standby_connection_sql import prepare

def build(root,app):
    out=root/'owner-sql'
    prepare(root,root/'manifest.json',root/'assets.private.json',out,'hanyang_mixed_20261026_problem_read')
    quote=lambda v:"'"+str(v).replace("'","''")+"'"
    sql=(out/'apply.private.sql').read_text()
    if not sql.endswith('commit;\n'):raise ValueError('TRANSACTION_REQUIRED')
    sql=sql[:-len('commit;\n')]
    candidate=(app/'supabase/migrations/20261021071702_essay_confirmed_math_input.sql').read_text()
    additions=candidate[candidate.index('alter table public.math_subproblems'):candidate.index('create or replace function public.essay_exam_submit(')]
    sql+="do $$begin if to_regprocedure('essay_exam_private.confirmed_answers(uuid,uuid,uuid,jsonb)') is not null or exists(select 1 from information_schema.columns where table_schema='public' and table_name='math_subproblems' and column_name='essay_question_id') then raise exception 'MIXED_BASELINE_CHANGED';end if;end$$;\n"
    sql+=additions
    rows=json.loads((root/'math-content.private.json').read_text())
    if len(rows)!=8:raise ValueError('EXACT_EIGHT_EXAMS_REQUIRED')
    for row in rows:
        p=row['profile'];c=row['criteria'][0];s=row['source'];dims="array['logical_development','computation_accuracy','final_conclusion']::text[]"
        sql+=f"insert into public.math_problem_sets(id,essay_exam_id,logical_id,version,label,state) values({quote(row['problem_set_id'])},{quote(row['exam_id'])},{quote(row['problem_set_id'])},1,{quote(row['name'])},'ACTIVE');\n"
        sql+=f"insert into public.math_problems(id,problem_set_id,logical_id,version,display_order,statement,state) values({quote(row['problem_id'])},{quote(row['problem_set_id'])},{quote(row['problem_id'])},1,1,{quote(row['statement'])},'ACTIVE');\n"
        sql+=f"insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format,essay_question_id) values({quote(row['leaf_id'])},{quote(row['problem_id'])},'whole-q2',0,{quote(row['statement'])},'FULL_SOLUTION',{quote(row['question_id'])});\n"
        resource=quote(s['resource_id'])+'::uuid' if s['resource_id'] else 'null'
        sql+=f"insert into public.math_source_artifacts(id,problem_id,resource_id,source_role,source_url,locator,provenance,verification,content_sha256) values({quote(s['id'])},{quote(row['problem_id'])},{resource},'SCORING',{quote(s['source_url'])},{quote(s['locator'])},'OFFICIAL','HASH_VERIFIED',{quote(s['content_sha256'])});\n"
        sql+=f"insert into public.math_scoring_criteria(id,leaf_id,source_id,criterion_key,description,official_points,rubric_dimensions) values({quote(c['id'])},{quote(row['leaf_id'])},{quote(s['id'])},'official-q2',{quote(c['description'])},null,{dims});\n"
        sql+=f"insert into public.math_evaluation_profiles(id,logical_id,version,scope,essay_exam_id,response_format,rubric_version,required_dimensions,optional_dimensions,reasoning_required,state) values({quote(p['id'])},{quote(p['logical_id'])},1,'EXAM',{quote(row['exam_id'])},'FULL_SOLUTION','math-rubric-v1',{dims},'{{}}',true,'DRAFT');select math_private.activate_profile({quote(p['id'])});\n"
    definitions=json.loads((root/'functions.private.json').read_text())
    for name in ['essay_exam_submit','essay_exam_submit_cycle']:
        definition=next(r['definition'] for r in definitions if r['signature'].startswith(name+'('))
        marker=' for q in select value from jsonb_array_elements(p_answers) loop'
        if definition.count(marker)!=1:raise ValueError('SUBMIT_BASELINE_FORMAT_CHANGED')
        definition=definition.replace(marker,' p_answers=essay_exam_private.confirmed_answers(p_subject,p_exam,p_key,p_answers);\n'+marker)
        definition=definition.replace("q-array['questionId','body','revision']","q-array['questionId','body','revision','input']")
        definition=definition.replace("a->>'body' is distinct from x->>'body'","(a->>'body' is distinct from x->>'body' or a->'input' is distinct from x->'input')")
        sql+=definition.rstrip().rstrip(';')+';\n'
    sql+=(app/'supabase/candidates/essay_mixed_session_20261026/math_context.sql').read_text()+'\ncommit;\n'
    (out/'apply.private.sql').write_text(sql)
    baseline=json.loads((root/'baseline.private.json').read_text())
    post=(out/'postcheck.sql').read_text().rstrip().removesuffix(';')
    for name in ['essay_exam_private.reserve','essay_exam_private.finish']:
        f=next(f for f in baseline['functions'] if f['signature'].startswith(name+'('))
        post+=f",\nmd5(pg_get_functiondef({quote(f['signature'])}::regprocedure))={quote(f['md5'])} as {name.split('.')[-1]}_unchanged"
    post+=",\nto_regprocedure('public.essay_exam_math_context(uuid,uuid,uuid,uuid)') is not null as math_context_installed"
    ids=','.join(quote(r['question_id'])+'::uuid' for r in rows)
    post+=f",\n(select count(*)=8 from public.math_subproblems where essay_question_id in ({ids})) as exact_eight_math_mappings;\n"
    (out/'postcheck.sql').write_text(post)
    (out/'rollback.sql').write_text((out/'rollback.sql').read_text()+"\n-- Keep additive input/lease helpers and immutable Math content. Disable only new scope.\n-- Never remove helpers while a mixed parent is reserved; keep Worker until it completes.\n")
    print(json.dumps({'exams':8,'provider_calls':0,'production_applied':False,'financial_functions_replaced':0}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('app',type=Path);a=p.parse_args();build(a.root,a.app)
