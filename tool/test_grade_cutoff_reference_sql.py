"""Disposable Postgres contract test. Never connects to Supabase/production."""
import json,os,subprocess,tempfile
from pathlib import Path
R=Path(__file__).resolve().parents[1];PG=Path('/opt/homebrew/opt/postgresql@17/bin')
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(args,**kw):return subprocess.run(list(map(str,args)),text=True,capture_output=True,env=env,**kw)
 with tempfile.TemporaryDirectory(prefix='task19-pg-') as td:
  d=Path(td);sock=d/'s';sock.mkdir();db=d/'db'
  r=run([PG/'initdb','-D',db,'-U','postgres','--auth=trust','--encoding=UTF8']);assert r.returncode==0,r.stderr
  r=run([PG/'pg_ctl','-D',db,'-l',d/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start']);assert r.returncode==0,r.stderr
  def sql(s,error=None):
   r=run([PG/'psql','-XqAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
   if error:assert r.returncode and error in r.stderr,r.stderr;return
   assert r.returncode==0,r.stderr
   return r.stdout.strip()
  try:
   sql('''create role anon;create role authenticated;
    create table content_items(id uuid primary key,is_active boolean);
    create table exams(content_item_id uuid primary key references content_items,academic_year int,exam_month int,grade_level int,exam_type text);
    create table exam_subjects(id uuid primary key,content_item_id uuid references content_items,subject_id uuid,raw_subject_label text,display_order int,is_active boolean,unique(id,content_item_id));
    grant select on content_items,exams,exam_subjects to anon,authenticated;
    create table grade_cutoff_versions(id int);insert into grade_cutoff_versions values(1);
   ''')
   sql((R/'supabase/migrations/20261105032113_grade_cutoff_reference_lookup.sql').read_text())
   registry=json.loads((R/'data/grade_cutoffs/task19/registry_snapshot.json').read_text());rows=json.loads((R/'data/grade_cutoffs/task19/reviewed_rows.json').read_text())
   def lit(v):
    if v is None:return 'null'
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(int,float)):return str(v)
    return "'"+str(v).replace("'","''")+"'"
   for e in registry:
    sql(f"insert into content_items values('{e['content_item_id']}',true);insert into exams values('{e['content_item_id']}',{e['academic_year']},{e['exam_month']},3,'{e['exam_type']}');")
    for i,s in enumerate(e['subjects']):sql(f"insert into exam_subjects values('{s['id']}','{e['content_item_id']}',{lit(s['subject_id'])},{lit(s['label'])},{i},true);")
   def insert(row):return 'insert into grade_cutoff_references('+','.join(row)+') values('+','.join(map(lit,row.values()))+');'
   import sys
   def candidate(mode):
    r=run([sys.executable,R/'tool/check_task19_cutoffs.py',mode]);assert r.returncode==0,r.stderr;return r.stdout
   sql(candidate('--seed-sql'))
   sql(candidate('--seed-sql'),'overlaps existing')
   eid=rows[0]['content_item_id'];base=rows[0]
   assert sql(f"set role anon;select grade_cutoff_lookup('{eid}');")=='[]'
   sql(candidate('--publish-sql'))
   visible=json.loads(sql(f"set role anon;select grade_cutoff_lookup('{eid}');"));assert len(visible)==sum(r['content_item_id']==eid for r in rows)
   sql('set role authenticated;delete from grade_cutoff_references;','permission denied')
   sql('set role anon;update grade_cutoff_references set raw_score=0;','permission denied')
   sql('set role authenticated;'+insert({**base,'revision':2}),'permission denied')
   sql('update grade_cutoff_references set raw_score=0;','new revision')
   sql('delete from grade_cutoff_references;','immutable')
   sql(insert({**base,'revision':2,'status':'published','is_current':True}),'duplicate key')
   sql(insert({**base,'revision':2,'verified_at':None,'status':'published'}),'check constraint')
   sql(insert({**base,'revision':2,'raw_score':None,'raw_score_min':94,'raw_score_max':92}),'check constraint')
   sql(insert({**base,'revision':2,'exam_subject_id':registry[-1]['subjects'][0]['id']}),'foreign key')
   assert sql('select count(*) from grade_cutoff_versions')=='1'
   sql(f"update content_items set is_active=false where id='{eid}';")
   assert sql(f"set role anon;select grade_cutoff_lookup('{eid}');")=='[]'
   sql(candidate('--withdraw-sql'))
   assert sql('set role anon;select count(*) from grade_cutoff_references')=='0'
   assert sql('select count(*) from grade_cutoff_references')==str(len(rows))
   print(f'PASS: {len(rows)} draft rows / 11 canonical exams; read-only public API, unpublished hidden, raw range, duplicate current, cross-exam FK, immutable evidence, inactive hidden, old grading untouched')
  finally:run([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])
if __name__=='__main__':main()
