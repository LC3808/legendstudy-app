"""Apply review drafts ONLY to a newly created Supabase local project.
CLI status JSON is private; never print credentials. No remote Supabase commands.
"""
import json,os,subprocess
from pathlib import Path
from urllib.parse import urlparse
import psycopg

def main():
 if os.environ.get('ESSAY_REVIEW_DISPOSABLE')!='YES':raise SystemExit('REFUSED: consent required')
 project=os.environ['ESSAY_REVIEW_LOCAL_PROJECT_ID']
 if not project.startswith(('essay-review-','essay-p2b-')):raise SystemExit('REFUSED: dedicated local project id required')
 cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
 api=urlparse(cfg['API_URL']);db=urlparse(cfg['DB_URL'])
 if api.hostname not in ('127.0.0.1','::1') or db.hostname not in ('127.0.0.1','::1'):raise SystemExit('REFUSED: numeric loopback only')
 container=json.loads(subprocess.check_output(['docker','inspect','supabase_db_'+project],text=True))[0]
 if container['Config']['Labels'].get('com.supabase.cli.project')!=project:raise SystemExit('REFUSED: local container identity mismatch')
 ports=container['NetworkSettings']['Ports'].get('5432/tcp',[])
 if not any(int(p['HostPort'])==db.port and p['HostIp'] in ('127.0.0.1','0.0.0.0','::') for p in ports):raise SystemExit('REFUSED: local DB port mismatch')
 root=Path(__file__).resolve().parents[4]
 with psycopg.connect(cfg['DB_URL'],autocommit=True) as c:
  if c.info.server_version<170000:raise SystemExit('REFUSED: PostgreSQL17 required')
  if c.execute("select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m')").fetchone()[0]:raise SystemExit('REFUSED: public schema already populated')
  for name in ['supabase/migrations/20260912000100_initial_content_schema.sql','supabase/migrations/20260927000200_essay_lab_foundation.sql','supabase/review/essay_lab_product/001_student_essay_product.draft.sql','supabase/review/essay_lab_product/002_entitlements.draft.sql','supabase/review/essay_lab_product/003_server_operations.draft.sql']:
   c.execute((root/name).read_text())
  c.execute('grant essay_worker,essay_finance to authenticator')
  c.execute("notify pgrst,'reload schema'")
 print('LOCAL_SUPABASE_REVIEW_APPLY_PASS')
if __name__=='__main__':main()
