"""Actual local PostgreSQL retry/ledger concurrency tests; synthetic checkpoints."""
import json,uuid,concurrent.futures

def cases(sql,root,user,exam,question,source):
    def uid():return str(uuid.uuid4())
    def literal(x):return "'"+json.dumps(x).replace("'","''")+"'::jsonb"
    account=sql(f"select id from public.credit_accounts where user_id='{user}'")
    snapshot=json.loads(sql(f"select snapshot from essay_exam_private.runs where id='{source}'"))
    snapshot['ownerId']=user
    q2=sql(f"select id from public.essay_questions where essay_exam_id='{exam}' and id<>'{question}' limit 1")
    snapshot['answers'].append(dict(snapshot['answers'][0],questionId=q2))
    run=sql(f"select essay_exam_private.reserve('{account}','{exam}','{uid()}',{literal(snapshot)})")
    dispatch=uid()
    def claim():return json.loads(sql(f"set role essay_worker;select public.essay_exam_session_claim('{user}','{run}','{dispatch}')"))
    token=claim()['lease_token']
    def cp(key,state):
        writer=uid()
        base=f"'{user}','{run}','{token}','{key}'"
        assert json.loads(sql(f"set role essay_worker;select public.essay_exam_session_checkpoint({base},'begin','{writer}')"))['started']
        sql(f"set role essay_worker;select public.essay_exam_session_checkpoint({base},'write','{writer}',{literal(dict(state=state))})")
    cp('q0','completed');cp('q1','reconciling')
    def status():return json.loads(sql(f"set request.jwt.claim.sub='{user}';set role authenticated;select public.essay_exam_session_status('{run}')"))
    assert status()['retry_allowed'] is False
    sql(f"set request.jwt.claim.sub='{uid()}';set role authenticated;select public.essay_exam_session_status('{run}')",'ACCOUNT_RESTRICTED')
    def retry(key):return f"set role essay_worker;select public.essay_exam_retry('{user}','{run}','{key}','{exam}')"
    sql(retry(uid()),'RECONCILIATION_REQUIRED')
    # Test-only replacement represents a separate confirmed-failure fixture.
    sql(f"update essay_exam_private.checkpoints set payload={literal(dict(state='failed'))} where run_id='{run}' and key='q1'")
    assert status()['retry_allowed'] is True
    original=sql(f"select jsonb_agg(to_jsonb(c) order by key) from essay_exam_private.checkpoints c where run_id='{run}'")
    ledger=sql(f"select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t where account_id='{account}'")
    key=uid()
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        values=list(pool.map(lambda _:json.loads(sql(retry(key))),range(8)))
    assert all(v==values[0] for v in values)
    assert claim()['attempts']=={'1':1}
    assert status()['retry_allowed'] is False
    assert [q['state'] for q in status()['questions']]==['completed','waiting']
    assert sql(f"select count(*) from essay_exam_private.retry_requests where run_id='{run}'")=='1'
    sql(retry(uid()),'RECONCILIATION_REQUIRED')
    assert ledger==sql(f"select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t where account_id='{account}'")
    assert original==sql(f"select jsonb_agg(to_jsonb(c) order by key) from essay_exam_private.checkpoints c where run_id='{run}'")
    cp('q1-retry-1','completed')
    sql(retry(uid()),'RETRY_NOT_AVAILABLE')
    result=dict(summary='Synthetic reviewed summaries',questions=[dict(questionId=a['questionId'],rubricVersion=a['rubricVersion'],evidenceVersion=a['evidenceVersion'],evaluation={'summary':'Synthetic'}) for a in snapshot['answers']])
    finish=f"set role essay_worker;select public.essay_exam_finish('{user}','{run}','{token}',{literal(result)},false)"
    sql(finish);sql(finish)
    assert sql(f"select sum(balance_delta)||','||sum(reserved_delta) from public.credit_transactions where account_id='{account}'")=='2,0'
    sql((root/'supabase/candidates/essay_session_retry/rollback.sql').read_text(),'NONEMPTY_RETRY_ROLLBACK_DENIED')
    # Existing erasure cascade must work; retained ledger facts cannot be deleted.
    sql(f"update public.credit_accounts set user_id=null where id='{account}'")
    assert sql(f"select count(*) from essay_exam_private.retry_requests where run_id='{run}'")=='0'
    assert sql(f"select sum(balance_delta) from public.credit_transactions where account_id='{account}'")=='2'
    print('PASS: retry confirmed failures only; eight concurrent identical retries one generation; successful checkpoints and Ledger unchanged; finish exactly 1 Credit; no retry of unknown/pending/completed; erasure cascade preserves Ledger.')
