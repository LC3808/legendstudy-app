"""Negative-only checks. Uses a populated disposable PG17 DB and empty disposable PG16 DB.
No database creation/reset here, no DSN output. Do not point at a shared cluster.
"""
import os,json,subprocess,sys
from pathlib import Path
import psycopg
from psycopg.conninfo import conninfo_to_dict,make_conninfo
runner=Path(__file__).with_name('run.py')
def validate(dsn):
 cfg=conninfo_to_dict(dsn)
 if cfg.get('host') not in ('127.0.0.1','::1') or cfg.get('hostaddr',cfg.get('host')) not in ('127.0.0.1','::1') or cfg.get('service') or not cfg.get('dbname','').startswith('essay_review_'):
  raise SystemExit('REFUSED: invalid disposable guard target')
 return cfg
def footprint(dsn):
 with psycopg.connect(dsn) as c:
  return c.execute("select n.nspname,c.relname,c.relkind from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','auth') order by 1,2").fetchall()
def main():
 if os.environ.get('ESSAY_REVIEW_DISPOSABLE')!='YES':raise SystemExit('REFUSED: explicit consent required')
 main_dsn=os.environ['ESSAY_REVIEW_TEST_DSN'];old_dsn=os.environ['ESSAY_REVIEW_OLD_VERSION_DSN']
 cfg=validate(main_dsn);validate(old_dsn)
 with psycopg.connect(old_dsn) as c:
  old_version=c.info.server_version
  assert old_version<170000
 before=[footprint(main_dsn),footprint(old_dsn)]
 assert before[0] and not before[1], 'Need populated PG17 and empty PG16 negative fixtures'
 cases=[('missing_consent',main_dsn,None,'NOT_RUN:'),('non_loopback',make_conninfo(**dict(cfg,host='example.invalid')), 'YES','REFUSED: only'),('wrong_db_name',make_conninfo(**dict(cfg,dbname='not_a_review_database')),'YES','REFUSED: only'),('populated_database',main_dsn,'YES','REFUSED: DB must be empty'),('postgres_before_17',old_dsn,'YES','REFUSED: dedicated PostgreSQL17+')]
 results=[]
 for name,dsn,consent,expected in cases:
  env=dict(os.environ,ESSAY_REVIEW_TEST_DSN=dsn)
  env.pop('ESSAY_REVIEW_DISPOSABLE',None)
  if consent:env['ESSAY_REVIEW_DISPOSABLE']=consent
  p=subprocess.run([sys.executable,str(runner)],env=env,capture_output=True,text=True,timeout=15)
  assert p.returncode!=0 and expected in p.stdout+p.stderr, name
  results.append({'guard':name,'status':'PASS','refused':True})
 assert before==[footprint(main_dsn),footprint(old_dsn)]
 print(json.dumps({'guards':results,'negative_server_version_num':old_version,'schema_footprints_unchanged':True,'dsn_logged':False},indent=2))
if __name__=='__main__':main()
