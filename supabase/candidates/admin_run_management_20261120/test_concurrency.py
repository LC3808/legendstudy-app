"""Only local fixture database on port 55439. Two concurrent admin retry transactions."""
import subprocess, os
BASE=['psql','-h','/private/tmp','-p','55439','-d',os.environ.get('ADMIN_TEST_DB','postgres'),'-v','ON_ERROR_STOP=1','-At']
def sql(s):return subprocess.run(BASE+['-c',s],text=True,capture_output=True,check=True).stdout
sql("select make_run(11)")
actor="set test.actor='00000000-0000-4000-8000-000000000001';"
run='10000000-0000-4000-8000-000000000011'
first=subprocess.Popen(BASE+['-c',actor+f"begin;select admin_lab_manage_run('{run}','retry',gen_random_uuid());select pg_sleep(0.5);commit;"],text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
second=subprocess.Popen(BASE+['-c',actor+f"select admin_lab_manage_run('{run}','retry',gen_random_uuid());"],text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
a=first.communicate();b=second.communicate()
assert sorted([first.returncode,second.returncode])==[0,1],(a,b)
assert 'ACTIVE_LEASE' in a[1]+b[1]
assert sql(f"select count(*) from essay_exam_private.retry_requests where run_id='{run}'").strip()=='1'
assert sql(f"select count(*) from essay_ops_private.run_actions where run_id='{run}'").strip()=='1'
print('PASS: concurrent retry -> exactly one generation/audit, second ACTIVE_LEASE')
