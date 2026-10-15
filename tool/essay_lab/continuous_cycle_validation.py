"""Synthetic local PostgreSQL validation; no Provider or network credentials."""
import json, uuid, concurrent.futures

def cases(sql, root, user, account, exam, question, initial):
    folder=root/'supabase/candidates/essay_continuous_cycles'
    legacy=sql("select md5(string_agg(id::text||snapshot::text||coalesce(result::text,''),'' order by id)) from essay_exam_private.runs")
    sql((folder/'preflight.sql').read_text())
    sql((folder/'install.sql').read_text())
    sql((folder/'postflight.sql').read_text())
    assert sql("select md5(string_agg(id::text||snapshot::text||coalesce(result::text,''),'' order by id)) from essay_exam_private.runs")==legacy
    sql((folder/'install.sql').read_text(),'CYCLES_ALREADY_INSTALLED')
    answers=json.dumps([dict(questionId=question,body='Synthetic next paid answer',revision=4)])
    def request(key,previous=initial,role='essay_worker'):
        return f"set role {role};select public.essay_exam_submit_cycle('{user}','{exam}','{key}','{answers}'::jsonb,null,'{previous}')"
    for role in ('anon','authenticated','service_role'):
        sql(request(str(uuid.uuid4()),role=role),'permission denied')
    def quote(parent=None,previous=None,who=user):
        a="null" if parent is None else "'"+parent+"'"
        b="null" if previous is None else "'"+previous+"'"
        return f"set role essay_worker;select public.essay_exam_quote('{who}','{exam}',array['{question}']::uuid[],{a},{b})"
    transactions=sql('select count(*) from public.credit_transactions')
    assert json.loads(sql(quote()))['credits']==1
    assert json.loads(sql(quote(previous=initial)))['credits']==1
    assert sql('select count(*) from public.credit_transactions')==transactions
    for role in ('anon','authenticated','service_role'):
        sql(quote().replace('set role essay_worker','set role '+role),'permission denied')
    sql(quote().replace("array['"+question+"']","array['"+question+"','"+question+"']"),'INVALID_QUESTION_SET')
    sql(quote(parent=initial),'REEVALUATION_NOT_INCLUDED')
    key=str(uuid.uuid4())
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        ids=list(pool.map(lambda _:sql(request(key)),range(4)))
    assert len(set(ids))==1
    paid=ids[0]
    assert sql(f"select previous_paid_run_id from essay_exam_private.runs where id='{paid}'")==initial
    sql(request(str(uuid.uuid4())),'PAID_CYCLE_ALREADY_STARTED')
    def balance():return sql(f"select sum(balance_delta)||','||sum(reserved_delta) from public.credit_transactions where account_id='{account}'")
    assert balance()=='2,1',balance()
    # Use existing private finalizer to isolate billing contract from Provider.
    result=sql(f"select result from essay_exam_private.runs where id='{initial}'")
    quoted="'"+result.replace("'","''")+"'::jsonb"
    sql(f"select essay_exam_private.finish('{paid}',{quoted},false)")
    assert balance()=='1,0'
    assert json.loads(sql(quote(parent=paid)))['credits']==0
    sql(quote(previous=initial),'PAID_CYCLE_ALREADY_STARTED')
    free=str(uuid.uuid4())
    run=sql(f"set role essay_worker;select public.essay_exam_submit('{user}','{exam}','{free}','{answers}'::jsonb,'{paid}')")
    sql(f"select essay_exam_private.finish('{run}',{quoted},false)")
    assert balance()=='1,0'
    sql(f"set role essay_worker;select public.essay_exam_submit('{user}','{exam}','{uuid.uuid4()}','{answers}'::jsonb,'{paid}')",'REEVALUATION_ALREADY_USED')
    def compete(_):
        try:return sql(request(str(uuid.uuid4()),paid))
        except AssertionError as error:
            assert any(reason in str(error) for reason in ('PAID_CYCLE_ALREADY_STARTED','INSUFFICIENT_CREDIT'))
            return None
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        winners=[x for x in pool.map(compete,range(4)) if x]
    assert len(winners)==1
    next_paid=winners[0]
    assert balance()=='1,1'
    sql(f"select essay_exam_private.finish('{next_paid}',null,true)")
    assert balance()=='1,0'
    retry=sql(request(str(uuid.uuid4()),paid))
    sql(f"select essay_exam_private.finish('{retry}',null,true)")
    assert balance()=='1,0'
    sql((folder/'rollback.sql').read_text(),'NONEMPTY_CYCLE_ROLLBACK_DENIED')
    assert sql(f"select count(distinct submission_index)=count(*) from essay_exam_private.runs where submission_index is not null")=='t'
    print('PASS: local continuous paid/free, same-intent concurrency, unique successor, failure recovery, immutable sequence, role denial; no Provider')
