"""Disposable PostgreSQL: review locking, permission checks and non-destructive rollback.
Minimal canonical table fixtures; not a production migration approval or API E2E.
"""
import json,os,subprocess,tempfile,concurrent.futures
from pathlib import Path
R=Path(__file__).resolve().parents[1];PG=Path('/opt/homebrew/opt/postgresql@17/bin')
E='00000000-0000-4000-8000-000000000001';Q='00000000-0000-4000-8000-000000000002';U='00000000-0000-4000-8000-000000000003';H='a'*64

def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(args,**kw):return subprocess.run([str(x) for x in args],text=True,capture_output=True,env=env,**kw)
 with tempfile.TemporaryDirectory(prefix='material-review-') as td:
  d=Path(td);sock=d/'sock';sock.mkdir();db=d/'db'
  r=run([PG/'initdb','-D',db,'-U','postgres','--auth=trust','--encoding=UTF8']);assert r.returncode==0,r.stderr
  r=run([PG/'pg_ctl','-D',db,'-l',d/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start']);assert r.returncode==0,r.stderr
  def sql(s,error=None):
   r=run([PG/'psql','-XqAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
   if error:assert r.returncode and error in r.stderr,r.stderr;return
   assert r.returncode==0,r.stderr
   return r.stdout.strip()
  try:
   sql(f"""create role anon;create role authenticated;create schema auth;create schema storage;
    create table auth.users(id uuid primary key);insert into auth.users values('{U}');
    create function auth.uid() returns uuid language sql as $$select nullif(current_setting('test.uid',true),'')::uuid$$;
    create function public.is_quality_operator() returns boolean language sql as $$select coalesce(auth.uid()='{U}',false)$$;
    create table public.resources(id uuid primary key);create table public.universities(id uuid primary key,name text);
    create table public.essay_exams(id uuid primary key,university_id uuid,admission_year int,exam_kind text,exam_name text,field_or_division text);
    create table public.essay_questions(id uuid primary key,essay_exam_id uuid,label text,question_key text,display_order int);
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(bucket_id text,name text);alter table storage.objects enable row level security;
    grant usage on schema public,auth,storage to anon,authenticated;
    grant select,insert on storage.objects to authenticated;
    insert into public.universities values('{U}','Fixture');insert into public.essay_exams values('{E}','{U}',2024,'admission','Fixture');
    insert into public.essay_questions values('{Q}','{E}','Q1','source:fixture',1);
   """)
   candidate=(R/'supabase/candidates/essay_material_review/install.sql').read_text();sql(candidate);sql(candidate)
   sql('set role anon;select public.essay_material_list()','permission denied')
   sql('set role authenticated;select public.essay_material_list()','MATERIAL_OPERATOR_REQUIRED')
   sql('set role authenticated;select * from essay_material_private.documents','permission denied')
   auth=f"set test.uid='{U}';set role authenticated;"
   sql(auth+f"insert into storage.objects values('essay-material-originals','{H}.pdf');select public.essay_material_register('{H}','Synthetic',3)")
   body=dict(documents=[H],mappings=[dict(questionId=Q,sourceHash=H,role='question',startPage=1,endPage=2,verification='VERIFIED')],checks={})
   def save(rev,state='IN_REVIEW',b=None,approval=False):
    encoded=json.dumps(b if b is not None else body).replace("'","''")
    return auth+f"select public.essay_material_save('{E}',{rev},'{encoded}','{state}',{str(approval).lower()});"
   sql(save(0,'VERIFIED'),'CHECKLIST_INCOMPLETE');sql(save(0,'ACTIVE'),'STATE_TRANSITION_DENIED')
   with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    def race(_):
     try:sql(save(0));return 'saved'
     except AssertionError as e:assert 'REVISION_CONFLICT' in str(e);return 'conflict'
    assert sorted(pool.map(race,range(2)))==['conflict','saved']
   bad=json.loads(json.dumps(body));bad['mappings'][0]['questionId']=U
   sql(save(1,b=bad),'QUESTION_NOT_IN_EXAM')
   bad=json.loads(json.dumps(body));bad['mappings'][0]['endPage']=4;sql(save(1,b=bad),'INVALID_PAGE_RANGE')
   bad=json.loads(json.dumps(body));bad['mappings'][0]['questionId']='';sql(save(1,b=bad))
   checks=['university','year','kind','track','sessionCampus','question','passages','questionPages','visuals','length','intent','explanation','criteria','modelAnswer','source','providerRights','studentRights'];body['checks']={k:True for k in checks}
   sql(save(2,'VERIFIED',approval=True));detail=json.loads(sql(auth+f"select public.essay_material_detail('{E}')"));assert len(detail['history'])==3 and detail['review']['approvalRequested']
   sql((R/'supabase/candidates/essay_material_review/rollback.sql').read_text())
   sql(auth+'select public.essay_material_list()','permission denied')
   assert sql('select count(*) from essay_material_private.revisions')=='3'
   print('PASS: repeat install, anonymous/nonoperator/direct table denial, upload metadata, concurrent revision conflict, cross-exam/page guards, draft save, checklist, activation denial, audit, retained-data rollback')
  finally:run([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])
if __name__=='__main__':main()
