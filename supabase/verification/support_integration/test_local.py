"""Synthetic integration tests. Hard-coded loopback TEST port; never Production."""
import json, subprocess, concurrent.futures, time
PSQL=['/opt/homebrew/opt/postgresql@17/bin/psql','-h','127.0.0.1','-p','55441','-d','legendstudy_support_upgrade_20261104','-X','-qAt','-v','ON_ERROR_STOP=1']
ADMIN='00000000-0000-4000-8000-000000000001'; A='00000000-0000-4000-8000-000000000002'; B='00000000-0000-4000-8000-000000000003'
F='10000000-0000-4000-8000-000000000001'; G='10000000-0000-4000-8000-000000000002'; W='20000000-0000-4000-8000-000000000001'; KEY='30000000-0000-4000-8000-000000000001'
count=0
def sql(q,user=None,role=None,fail=None):
 claims=json.dumps({"sub":user,"role":"authenticated","exp":int(time.time())+3600})
 prefix=f"set request.jwt.claims='{claims}';set request.jwt.claim.sub='{user or ''}';"+(f'set role {role};' if role else '')
 r=subprocess.run(PSQL+['-c',prefix+q],text=True,capture_output=True)
 if fail:
  assert r.returncode and fail in r.stderr,(fail,r.stderr); return
 assert r.returncode==0,r.stderr
 return r.stdout.strip()
def rpc(name,p,user=ADMIN,role='authenticated',fail=None):
 return sql(f"select public.{name}('{json.dumps(p)}'::jsonb)",user,role,fail)
def check(label,condition):
 global count
 assert condition,label
 count+=1;print('PASS',label)
def arg(**kw):return dict(dto_version='admin-v1',**kw)
sql('truncate public.feedback_submissions, public.inquiries cascade;')
sql(f"insert into auth.users values('{ADMIN}','admin@example.invalid'),('{A}','a@example.invalid'),('{B}','b@example.invalid') on conflict do nothing; insert into profiles(id) select id from auth.users on conflict do nothing;")
sql(f"insert into admin_users(user_id) values('{ADMIN}') on conflict do nothing")
# Real APP direct insert under the authenticated role, not a service-only insert.
sql(f"insert into feedback_submissions(category,title,body,app_version,build_number,platform,os_version) values('suggestion','Synthetic APP suggestion','Synthetic body','1','1','ios','test')",A,'authenticated')
sql(f"insert into feedback_submissions(category,title,body,app_version,build_number,platform,os_version) values('bug','Synthetic guest','Synthetic guest body','1','1','ios','test')",None,'anon')
F=sql("select id from feedback_submissions where title='Synthetic APP suggestion'"); G=sql("select id from feedback_submissions where title='Synthetic guest'")
web=json.loads(rpc('inquiry_submit',dict(dto_version='inquiry-v1',category='material',title='Synthetic WEB',body='Synthetic body',request_key=KEY),A));W=web['inquiry_id']
original=sql('select md5(string_agg(row_to_json(f)::text,id::text order by id)) from feedback_submissions f')
check('APP+WEB submission and existing intake outbox',sql('select count(*) from feedback_notifications')=='2')
page=json.loads(rpc('support_admin_list',arg()));check('unified count and open',page['total']==3 and page['open']==3)
check('source category filter',json.loads(rpc('support_admin_list',arg(source='APP',category='suggestion')))['total']==1)
p1=json.loads(rpc('support_admin_list',arg(limit=1,offset=0)))['items'];p2=json.loads(rpc('support_admin_list',arg(limit=1,offset=1)))['items'];check('global pagination no repeat',p1[0]['inquiry_id']!=p2[0]['inquiry_id'])
check('WEB admin detail delegates to preserved function',json.loads(rpc('support_admin_detail',arg(source='WEB',id=W)))['inquiry']['body']=='Synthetic body')
check('APP admin detail',json.loads(rpc('support_admin_detail',arg(source='APP',id=F)))['inquiry']['body']=='Synthetic body')
rpc('support_admin_list',arg(),B,fail='OPERATOR_REQUIRED');check('member admin denied',True)
rpc('support_admin_list',arg(),None,'anon',fail='permission denied');check('guest admin denied',True)
rpc('support_admin_status',arg(source='APP',id=F,status='ANSWERED'),fail='REPLY_REQUIRED');check('cannot fake answered',True)
# Concurrent network retries share the request key.
p=arg(source='APP',id=F,body='Synthetic APP reply',request_key=KEY)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(lambda _:json.loads(rpc('support_admin_reply',p)),range(4)))
check('concurrent idempotent reply',len({x['reply_id'] for x in results})==1 and sum(x['created'] for x in results)==1)
check('one reply notification',sql(f"select count(*) from inquiry_notifications where feedback_id='{F}'")=='1')
rpc('support_admin_reply',arg(source='APP',id=F,body='Different body',request_key=KEY),fail='IDEMPOTENCY_CONFLICT');check('retry payload conflict',True)
web_reply=json.loads(rpc('support_admin_reply',arg(source='WEB',id=W,body='Synthetic WEB reply',request_key=KEY)));check('WEB existing reply path',web_reply['created'])
check('APP owner sees reply',json.loads(rpc('support_detail',dict(dto_version='inquiry-v1',source='APP',id=F),A))['replies'][0]['body']=='Synthetic APP reply')
check('WEB owner sees reply',json.loads(rpc('support_detail',dict(dto_version='inquiry-v1',source='WEB',id=W),A))['replies'][0]['body']=='Synthetic WEB reply')
rpc('support_detail',dict(dto_version='inquiry-v1',source='APP',id=F),B,fail='INQUIRY_NOT_FOUND');check('cross owner detail denied',True)
check('owner list scoped',len(json.loads(rpc('support_mine',dict(dto_version='inquiry-v1'),A))['items'])==2 and not json.loads(rpc('support_mine',dict(dto_version='inquiry-v1'),B))['items'])
check('integrated pending after replies',json.loads(sql('select support_metrics()',ADMIN,'authenticated'))['open']==1)
rpc('support_admin_reply',arg(source='APP',id=G,body='Guest reply stored',request_key=KEY));check('guest has no invented recipient',sql(f"select count(*) from inquiry_notifications where feedback_id='{G}'")=='0')
rpc('support_admin_status',arg(source='APP',id=F,status='CLOSED'));check('retry after closure still idempotent',not json.loads(rpc('support_admin_reply',p))['created'])
check('raw APP original fully unchanged',original==sql('select md5(string_agg(row_to_json(f)::text,id::text order by id)) from feedback_submissions f'))
check('no fake WEB source rows',sql('select count(*) from inquiries')=='1')
# Worker claims both origins and delivery failure cannot remove replies.
jobs=json.loads(sql('select claim_support_notifications()',None,'service_role'));check('queue contains APP WEB recipients',len(jobs)==2 and {j['source'] for j in jobs}=={'APP','WEB'})
job=jobs[0]
check('stale token fenced',sql(f"select finish_support_notification('{job['notification_id']}','{KEY}',null)",None,'service_role')=='f')
sql(f"select finish_support_notification('{job['notification_id']}','{job['claim_token']}','network')",None,'service_role')
check('delivery failure keeps reply',sql('select count(*) from inquiry_replies')=='3')
check('failed delivery scheduled',sql(f"select next_attempt_at is not null from inquiry_notifications where id='{job['notification_id']}'")=='t')
job=jobs[1];sql(f"select finish_support_notification('{job['notification_id']}','{job['claim_token']}',null)",None,'service_role')
check('successful send finalized',sql(f"select status from inquiry_notifications where id='{job['notification_id']}'")=='sent')
sql('select claim_support_notifications()',A,'authenticated',fail='permission denied');check('client cannot claim email queue',True)
sql('select * from support_private.items',A,'authenticated',fail='permission denied');check('projection not publicly exposed',True)
# FK validation and preservation of WEB original reply APIs.
sql(f"insert into inquiry_replies(inquiry_id,feedback_id,author_id,body,request_key) values('{W}','{F}','{ADMIN}','Invalid','40000000-0000-4000-8000-000000000001')",fail='reply_one_parent');check('exactly one original FK enforced',True)
check('legacy WEB list retained',json.loads(rpc('admin_inquiry_list',arg()))['total']==1)
check('legacy WEB user list retained',len(json.loads(rpc('inquiry_mine',dict(dto_version='inquiry-v1'),A))['items'])==1)
sql("set test.support_account_blocked='true'; select support_mine('{\"dto_version\":\"inquiry-v1\"}')",A,'authenticated',fail='ACCOUNT_RESTRICTED');check('existing lifecycle restriction honored',True)
sql("set request.jwt.claims='{\"sub\":\"00000000-0000-4000-8000-000000000001\",\"role\":\"authenticated\",\"exp\":1}';select support_metrics()",ADMIN,'authenticated',fail='OPERATOR_REQUIRED');check('expired admin context denied',True)
print(f'{count} database integration checks PASS')
