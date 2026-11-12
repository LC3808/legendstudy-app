import pathlib,json,tempfile,subprocess,os,hashlib,uuid,re
import psycopg
from psycopg.rows import dict_row
O=pathlib.Path(__file__).resolve().parents[1]/'supabase/candidates/kwangwoon_public_20261112';meta=json.loads((O/'browse-function.json').read_text());baseline={u:sorted(rows,key=lambda e:e['examId']) for u,rows in json.loads((O/'browse-baseline.json').read_text()).items()};names=dict(re.findall(r"\('([a-z]+)',(?:'[^']+'|null),'([^']+)'\)",meta['definition']));full=json.loads((O/'browse-target-metadata.json').read_text());scope=json.loads((O/'scope.json').read_text());pg='/opt/homebrew/opt/postgresql@17/bin/'
with tempfile.TemporaryDirectory(prefix='sook-browse-',dir='/private/tmp') as t:
 p=pathlib.Path(t);(p/'sock').mkdir();subprocess.run([pg+'initdb','-D',str(p/'db'),'-A','trust','--no-locale','-E','UTF8','-U','postgres'],check=True,stdout=subprocess.DEVNULL)
 subprocess.run([pg+'pg_ctl','-D',str(p/'db'),'-l',str(p/'server.log'),'-o',"-k "+str(p/'sock')+" -c listen_addresses=''",'start','-w'],check=True,stdout=subprocess.DEVNULL)
 try:
  with psycopg.connect(host=str(p/'sock'),dbname='postgres',user='postgres',autocommit=True,row_factory=dict_row) as c:
   c.execute('create role anon;create role authenticated;create table public.universities(id uuid primary key,slug text,name text);create table public.essay_exams(id uuid primary key,university_id uuid,admission_year integer,exam_kind text,field_or_division text,admission_track text,exam_name text);create table public.essay_questions(id uuid primary key,essay_exam_id uuid,label text,display_order integer)')
   for u,exams in baseline.items():
    for e in exams:
     c.execute('insert into public.universities values(%s,%s,%s) on conflict do nothing',(e['universityId'],u,names[u]))
     c.execute('insert into public.essay_exams values(%s,%s,%s,%s,%s,null,%s)',(e['examId'],e['universityId'],e['year'],e['kind'],e['track'],e['title']))
     for i,q in enumerate(e['questions']):c.execute('insert into public.essay_questions values(%s,%s,%s,%s)',(q['id'],e['examId'],q['label'],i))
   for r in full:
    c.execute('insert into public.essay_exams values(%s,%s,%s,%s,%s,%s,%s) on conflict do nothing',tuple(r[k] for k in ['exam_id','university_id','admission_year','exam_kind','field_or_division','admission_track','exam_name']))
    c.execute('insert into public.essay_questions values(%s,%s,%s,%s) on conflict do nothing',tuple(r[k] for k in ['question_id','exam_id','label','display_order']))
   for eid in meta['remaining_hidden_exam_ids']:
    c.execute("insert into public.essay_exams values(%s,%s,2020,'mock','Synthetic HOLD',null,'Synthetic HOLD')",(eid,full[0]['university_id']))
    c.execute("insert into public.essay_questions values(%s,%s,'HOLD',1)",(str(uuid.uuid4()),eid))
   c.execute(meta['definition']);c.execute('revoke all on function public.essay_browse_catalog(text) from public;grant execute on function public.essay_browse_catalog(text) to anon,authenticated')
   acl=c.execute("select proowner,proacl::text acl from pg_proc where oid='public.essay_browse_catalog(text)'::regprocedure").fetchone()
   def read(u):return sorted(c.execute('select public.essay_browse_catalog(%s) d',(u,)).fetchone()['d'],key=lambda e:e['examId'])
   assert all(read(u)==rows for u,rows in baseline.items()),[u for u,rows in baseline.items() if read(u)!=rows]
   before=c.execute('select (select count(*) from public.essay_exams) exams,(select count(*) from public.essay_questions) questions').fetchone()
   c.execute((O/'browse-open.sql').read_text())
   for role in ['anon','authenticated']:
    c.execute('set role '+role)
    for u,rows in baseline.items():
     now=read(u)
     if u!='kwangwoon':assert now==rows,u
     else:
      assert len(now)==37;assert all(r in now for r in rows)
      new=[r for r in now if r['examId'] in scope['exams']];assert len(new)==21;assert {q['id'] for e in new for q in e['questions']}==set(scope['questions']);assert not {r['examId'] for r in now}.intersection(meta['remaining_hidden_exam_ids'])
    c.execute('reset role')
   assert c.execute("select proowner,proacl::text acl from pg_proc where oid='public.essay_browse_catalog(text)'::regprocedure").fetchone()==acl
   c.execute((O/'browse-rollback.sql').read_text());assert all(read(u)==rows for u,rows in baseline.items()),[u for u,rows in baseline.items() if read(u)!=rows];assert c.execute('select (select count(*) from public.essay_exams) exams,(select count(*) from public.essay_questions) questions').fetchone()==before
   # Reapplication after rollback succeeds, but accidental double application refuses drift.
   c.execute((O/'browse-open.sql').read_text())
   try:c.execute((O/'browse-open.sql').read_text());raise AssertionError('Double apply accepted')
   except psycopg.Error:c.execute('rollback')
   result=dict(status='PASS',environment='isolated Unix-only PG17; metadata fixtures; no Provider',universities=42,roles=['anon','authenticated'],new_questions=42,new_exam_scope=21,exclusions_removed=20,other_exclusions_preserved=16,existing_catalog_rows_preserved=True,rollback_exact=True,data_counts_preserved=True,acl_owner_preserved=True,duplicate_apply_rejected=True)
   (O/'browse-isolated-verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
 finally:subprocess.run([pg+'pg_ctl','-D',str(p/'db'),'stop','-m','fast','-w'],check=True,stdout=subprocess.DEVNULL)
