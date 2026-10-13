"""Local PostgreSQL only; no production credentials or mutations."""
import json,os,subprocess,tempfile
from pathlib import Path
R=Path(__file__).resolve().parents[1];PG=Path('/opt/homebrew/opt/postgresql@17/bin')
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')}
 with tempfile.TemporaryDirectory(prefix='material-worker-') as td:
  d=Path(td);sock=d/'sock';sock.mkdir()
  def run(args,**kw):return subprocess.run([str(x) for x in args],text=True,capture_output=True,env=env,**kw)
  def sql(s,error=None):
   r=run([PG/'psql','-XqAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
   if error:assert r.returncode and error in r.stderr,r.stderr;return
   assert not r.returncode,r.stderr
   return r.stdout.strip()
  assert not run([PG/'initdb','-D',d/'db','-U','postgres','--auth=trust','--encoding=UTF8']).returncode
  assert not run([PG/'pg_ctl','-D',d/'db','-l',d/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start']).returncode
  try:
   e='00000000-0000-4000-8000-000000000001';q='00000000-0000-4000-8000-000000000002'
   sql(f"create role anon;create role authenticated;create role essay_worker;create schema essay_material_private;create table essay_material_private.reviews(exam_id uuid,state text,approval_requested bool,body jsonb);create table public.essay_questions(id uuid,essay_exam_id uuid,question_key text);insert into public.essay_questions values('{q}','{e}','source:q');")
   source=(R/'supabase/candidates/essay_material_review/worker_read.sql').read_text();sql(source);sql(source)
   p=dict(exam_id=e,verification_status='VERIFIED_MANIFEST',rights_status={},questions=[dict(question_id=q,source_key='source:q',source_page_references=[dict(role='question',verification='VERIFIED',evidenceText='question')])])
   def store(p):
    raw=json.dumps(p).replace("'","''")
    sql(f"delete from essay_material_private.reviews;insert into essay_material_private.reviews values('{e}','VERIFIED',true,jsonb_build_object('documents',jsonb_build_array('source'),'package','{raw}'::jsonb||jsonb_build_object('package_digest',encode(sha256(convert_to(('{raw}'::jsonb)::text,'UTF8')),'hex'))));")
    return sql("select body->'package'->>'package_digest' from essay_material_private.reviews")
   digest=store(p)
   def call(digest):return f"select public.essay_material_runtime_package('{e}','{digest}')"
   sql('set role anon;'+call(digest),'permission denied');sql('set role authenticated;'+call(digest),'permission denied')
   sql('set role essay_worker;'+call(digest),'PROVIDER_RIGHTS_REQUIRED')
   p['rights_status']={'source':{'providerTransmission':'APPROVED'}};digest=store(p)
   assert json.loads(sql('set role essay_worker;'+call(digest)))['package_digest']==digest
   sql('set role essay_worker;'+call('0'*64),'REVIEWED_PACKAGE_UNAVAILABLE')
   p['questions'][0]['source_page_references'][0]['evidenceText']='';digest=store(p)
   sql('set role essay_worker;'+call(digest),'QUESTION_CONTENT_INVALID')
   sql((R/'supabase/candidates/essay_material_review/worker_read_rollback.sql').read_text())
   sql('set role essay_worker;'+call(digest),'permission denied')
   assert sql('select count(*) from essay_material_private.reviews')=='1'
   print('PASS: replay, caller grants, missing rights, pinned read, stale digest, empty question, retained-data rollback')
  finally:run([PG/'pg_ctl','-D',d/'db','-m','fast','-w','stop'])
if __name__=='__main__':main()
