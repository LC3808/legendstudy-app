"""LOCAL ONLY: supply a disposable fixture DB, never a Production connection."""
import concurrent.futures, json, os, re, subprocess, uuid
psql='/opt/homebrew/opt/postgresql@17/bin/psql'
db=os.environ.get('FEEDBACK_TEST_DB','feedback_task05b')
assert db.startswith('feedback_task05'), 'Disposable fixture database required'
p=json.dumps(dict(request_key=str(uuid.uuid4()),kind='quality',satisfaction='helpful',platform='web',app_version='concurrency-fixture'))
sql=f"begin; set local test.actor='00000000-0000-4000-8000-000000000001';set local test.admin='false';set local role authenticated;select public.essay_feedback_submit($p${p}$p$::jsonb);select pg_sleep(0.2);commit;"
def run(_):
 r=subprocess.run([psql,'-h','127.0.0.1','-p','55439','-U','postgres','-d',db,'-Atq','-v','ON_ERROR_STOP=1','-c',sql],capture_output=True,text=True,check=True)
 return re.findall(r'^[a-f0-9-]{36}$',r.stdout,re.M)[0]
with concurrent.futures.ThreadPoolExecutor(2) as pool: ids=list(pool.map(run,range(2)))
assert ids[0]==ids[1],ids
print('PASS: concurrent connections returned one feedback ID')
