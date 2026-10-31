"""Disposable PostgreSQL fixture only. No network hosts or production credentials accepted."""
import concurrent.futures
import subprocess
import sys
from pathlib import Path

database = sys.argv[1]
assert database.startswith('task06_') and database.replace('_', '').isalnum()
psql = ['/opt/homebrew/opt/postgresql@17/bin/psql', '-h', '127.0.0.1', '-p', '55439', '-U', 'postgres', '-d', database, '-v', 'ON_ERROR_STOP=1', '-At']
def sql(query):
    return subprocess.check_output(psql + ['-c', query], text=True)
auth = "set test.actor='90000000-0000-4000-8000-000000000001';set test.admin='true';set test.allowed='true';"
sql("update essay_ops_private.thresholds set threshold=1 where rule='stuck_seconds'")
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    results = list(pool.map(lambda _: sql(auth + 'select public.admin_essay_operations_check_alerts()'), range(8)))
assert all('checked_at' in result for result in results)
assert sql("select count(*) from essay_ops_private.alerts where rule='stuck_seconds' and resolved_at is null").strip() == '1'
counts = sql('select (select count(*) from essay_exam_private.runs),(select count(*) from public.credit_transactions),(select count(*) from essay_exam_private.checkpoints),(select count(*) from essay_ops_private.access_log),(select count(*) from essay_ops_private.cost_snapshots)')
subprocess.check_call(psql + ['-f', str(Path(__file__).with_name('rollback.sql'))])
assert counts == sql('select (select count(*) from essay_exam_private.runs),(select count(*) from public.credit_transactions),(select count(*) from essay_exam_private.checkpoints),(select count(*) from essay_ops_private.access_log),(select count(*) from essay_ops_private.cost_snapshots)')
assert sql("select to_regprocedure('public.admin_essay_operations(timestamptz,timestamptz,jsonb,integer,uuid)') is null").strip() == 't'
print('PASS: 8 concurrent alert checks; single open alert; rollback preserves operational + audit history')
