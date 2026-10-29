"""Local-only read API tests against the real Ledger and checkpoint schema."""
import json, uuid

def cases(sql, root, user, account, exam, question, source):
    def lit(x): return "'"+json.dumps(x).replace("'", "''")+"'::jsonb"
    folder=root/'supabase/candidates/essay_observation_p0'
    # Match Production's already installed uuid-ossp namespace (local fixture only).
    sql('create schema if not exists extensions;create extension if not exists "uuid-ossp" with schema extensions;')
    sql((folder/'install.sql').read_text())
    snap=json.loads(sql(f"select snapshot from essay_exam_private.runs where id='{source}'"))
    q2=sql(f"select id from public.essay_questions where essay_exam_id='{exam}' and id<>'{question}' limit 1")
    original=snap['answers'][0]
    snap['answers']=[dict(original,questionId=q2),original]
    key=str(uuid.uuid4())
    run=sql(f"select essay_exam_private.reserve('{account}','{exam}','{key}',{lit(snap)})")
    out=json.loads(sql(f"select result->'questions'->0->'evaluation' from essay_exam_private.runs where id='{source}'"))
    out['local_reviews']=[{'private':'must not escape'}]
    evaluation=str(uuid.uuid4())
    rows={'q0':{'state':'failed','output':None},'q1':{'state':'completed','evaluation_id':evaluation,'output':out},
          'q1-reviewed':{'p_evaluation':evaluation,'p_output':out},'q1-usage':{'p_input_tokens':1}}
    for k,payload in rows.items():
        sql(f"insert into essay_exam_private.checkpoints values('{run}','{k}','{uuid.uuid4()}','checkpoint',{lit(payload)})")
    def read(call,owner=user): return json.loads(sql(f"set request.jwt.claim.sub='{owner}';set role authenticated;select public.{call}"))
    other=str(uuid.uuid4())
    sql(f"insert into auth.users(id) values('{other}');insert into public.profiles(id) values('{other}');")
    ledger=sql('select md5(jsonb_agg(to_jsonb(t) order by id)::text) from public.credit_transactions t')
    frozen=sql(f"select md5(to_jsonb(r)::text) from essay_exam_private.runs r where id='{run}'")
    found=read(f"essay_exam_request_status('{key}','{exam}')")
    assert found['run_id']==run and found['found']
    assert not read(f"essay_exam_request_status('{uuid.uuid4()}','{exam}')")['found']
    observed=read(f"essay_exam_observation('{run}')")
    assert [(q['question_id'],q['label'],q['state']) for q in observed['questions']]==[(question,'Q1','completed'),(q2,'Q2','failed')]
    assert observed['retry_allowed'] and observed['generation']==0
    call=f"essay_exam_question_result('{run}','{question}')"
    partial=read(call)
    assert partial['state']=='reserved' and partial['question_state']=='completed'
    assert len(partial['answers'])==len(partial['result']['questions'])==1
    q=partial['result']['questions'][0]
    assert q['questionId']==question and 'telemetry' not in q and 'local_reviews' not in q['evaluation']
    assert q['criteria'][0]['binding']['id']==out['dimensions'][0]['criterion_id']
    sql(f"set request.jwt.claim.sub='{user}';set role authenticated;select public.essay_exam_question_result('{run}','{q2}')",'QUESTION_RESULT_UNAVAILABLE')
    sql(f"update essay_exam_private.checkpoints set payload='{{}}'::jsonb where run_id='{run}' and key='q1-reviewed'")
    sql(f"set request.jwt.claim.sub='{user}';set role authenticated;select public.{call}",'QUESTION_RESULT_UNAVAILABLE')
    sql(f"update essay_exam_private.checkpoints set payload={lit(rows['q1-reviewed'])} where run_id='{run}' and key='q1-reviewed'")
    for role in ('anon','service_role'):
        sql(f"set role {role};select public.{call}",'permission denied')
    assert not read(f"essay_exam_request_status('{key}','{exam}')",other)['found']
    sql(f"set request.jwt.claim.sub='{other}';set role authenticated;select public.{call}",'PT404')
    sql(f"insert into public.account_deletion_requests values('{user}','DELETION_PENDING')")
    sql(f"set request.jwt.claim.sub='{user}';set role authenticated;select public.{call}",'ACCOUNT_RESTRICTED')
    sql(f"delete from public.account_deletion_requests where subject_id='{user}'")
    assert frozen==sql(f"select md5(to_jsonb(r)::text) from essay_exam_private.runs r where id='{run}'")
    assert ledger==sql('select md5(jsonb_agg(to_jsonb(t) order by id)::text) from public.credit_transactions t')
    sql((folder/'rollback.sql').read_text())
    assert frozen==sql(f"select md5(to_jsonb(r)::text) from essay_exam_private.runs r where id='{run}'")
    assert ledger==sql('select md5(jsonb_agg(to_jsonb(t) order by id)::text) from public.credit_transactions t')
    # Discard only this synthetic fixture through existing finish, after verifying
    # the read APIs and rollback made zero ledger changes.
    sql(f"select essay_exam_private.finish('{run}',null,true)")
    print('PASS: owner/key lookup, canonical labels despite reversed snapshot, reviewed partial result, redaction, failed question denial, foreign/anon/service/lifecycle denial, unchanged run and Ledger, additive rollback.')
