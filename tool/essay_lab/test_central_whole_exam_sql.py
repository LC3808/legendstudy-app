"""Exercise a prepared Central batch in local disposable Postgres, never Production."""
import json,os,subprocess,tempfile,argparse,sys
from pathlib import Path

def verify(root,pg):
 read=lambda n:json.loads((root/n).read_text())
 baseline=read('central-baseline.private.json');packages=read('central-packages.private.json');registry=read('central-registry.private.json');manifest=read('central-owner-sql/manifest.json');out=root/'central-owner-sql'
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(a,**kw):return subprocess.run([str(x) for x in a],env=env,text=True,capture_output=True,**kw)
 lit=lambda x:"'"+str(x).replace("'","''")+"'"
 with tempfile.TemporaryDirectory(prefix='central-batch-') as tmp:
  t=Path(tmp);s=t/'sock';s.mkdir();data=t/'db'
  for a in [[pg/'initdb','-D',data,'-U','local_admin','--auth=trust','--no-locale','--encoding=UTF8'],[pg/'pg_ctl','-D',data,'-l',t/'log','-o',f"-k {s} -p 5432 -c listen_addresses=''",'-w','start']]:
   r=run(a);assert not r.returncode,r.stderr
  try:
   def sql(q,error=None):
    r=run([pg/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',s,'-U','local_admin','-d','postgres'],input=q)
    if error:assert r.returncode and error in r.stderr,r.stderr;return
    assert not r.returncode,r.stderr[:1200];return r.stdout.strip()
   sql("create schema essay_exam_private;create schema essay_material_private;create schema storage;create role authenticated;create function public.account_service_allowed() returns boolean language sql as 'select true';create table storage.buckets(id text primary key,public boolean);create table storage.objects(id serial,bucket_id text,name text);create table public.essay_exams(id uuid primary key);create table public.resources(id uuid primary key);create table public.essay_questions(id uuid primary key,essay_exam_id uuid,question_key text);create table essay_material_private.documents(sha256 text primary key,resource_id uuid,title text,page_count int,object_key text);create table essay_material_private.reviews(exam_id uuid primary key,revision int,state text,body jsonb,reviewer uuid,updated_at timestamptz,approval_requested bool);create table essay_material_private.revisions(exam_id uuid,revision int,state text,body jsonb,reviewer uuid,primary key(exam_id,revision));create table essay_exam_private.runs(id uuid primary key,exam_id uuid,state text,result jsonb);create table public.preserved_ledger(id int primary key,body jsonb);insert into public.preserved_ledger values(1,'{\"keep\":true}');insert into storage.buckets values('essay-material-originals',false);create policy untouched on storage.objects for select to authenticated using(false);")
   for f in baseline['functions']:sql(f['definition'])
   for e in registry['exams']:
    sql(f"insert into public.essay_exams values({lit(e['examId'])})")
    for q in e['questions']:sql(f"insert into public.essay_questions values({lit(q['id'])},{lit(e['examId'])},{lit(q['sourceKey'])})")
   for h,d in manifest['documents'].items():sql(f"insert into public.resources values({lit(d['resource_id'])});insert into storage.objects(bucket_id,name) values('essay-material-originals',{lit(h+'.pdf')});")
   def checks(name):
    v=json.loads(sql('select row_to_json(t) from ('+(out/name).read_text().strip().rstrip(';')+') t'));assert all(x is True for x in v.values()),v;return len(v)
   def policies():return json.loads(sql('select jsonb_object_agg(id,essay_exam_private.runtime_policy(id)) from public.essay_exams'))
   old=policies();pre=checks('precheck.sql');eid=next(iter(packages))
   sql(f"insert into essay_exam_private.runs values('00000000-0000-4000-8000-000000000001',{lit(eid)},'running','{{\"keep\":true}}')")
   sql((out/'apply.private.sql').read_text(),'CENTRAL_BASELINE_CHANGED');sql("update essay_exam_private.runs set state='completed'")
   sql((out/'apply.private.sql').read_text());post=checks('postcheck.sql');sql((out/'apply.private.sql').read_text(),'CENTRAL_BASELINE_CHANGED')
   new=policies();assert all(new[k]==v for k,v in old.items() if k not in packages)
   exported=json.loads(sql("select jsonb_agg(jsonb_build_object('exam_id',exam_id,'package',body->'package','policy',essay_exam_private.runtime_policy(exam_id))) from essay_material_private.reviews"));(root/'central-local-applied.private.json').write_text(json.dumps(exported,ensure_ascii=False))
   from essay_lab.material_runtime import load_reviewed_material
   for e in exported:
    hosted,report=load_reviewed_material(e['package'],registry,pinned_digest=e['policy']['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False)
    assert report['ready'] and len(hosted)==3,report
   sql((out/'rollback.sql').read_text());sql((out/'rollback.sql').read_text());assert policies()==old
   assert sql('select count(*) from essay_material_private.revisions')=='10'
   assert sql("select body->>'keep' from public.preserved_ledger")=='true'
   assert sql("select result->>'keep' from essay_exam_private.runs")=='true'
   for e in exported:assert sql(f"select jsonb_array_length(public.essay_material_runtime_package({lit(e['exam_id'])},{lit(e['package']['package_digest'])})->'questions')")=='3'
   result=dict(status='PASS',exams=10,questions=30,prechecks=pre,postchecks=post,postgres_digest_input_pass=30,other_policies_preserved=True,completed_history_preserved=True,ledger_fixture_preserved=True,duplicate_blocked=True,active_run_blocked=True,rollback_idempotent=True,rollback_keeps_packages=True,production_writes=0)
   (root/'central-sql-isolation-result.json').write_text(json.dumps(result,indent=2));return result
  finally:run([pg/'pg_ctl','-D',data,'-m','immediate','-w','stop'])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('--pg',type=Path,default=Path('/opt/homebrew/opt/postgresql@17/bin'));a=p.parse_args();print(json.dumps(verify(a.root,a.pg)))
