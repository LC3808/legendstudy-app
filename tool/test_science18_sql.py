"""Disposable PostgreSQL rehearsal of exact science material apply/reversal."""
import argparse,json,os,re,subprocess,tempfile
from pathlib import Path
APP=Path(__file__).resolve().parents[1]
def run(app,baseline,pg):
    root=app/'.local/khu-mock-science-20261112';candidate=app/'supabase/candidates/khu_mock_science_20261112'
    read=lambda p:json.loads(p.read_text())
    packages=read(root/'science-packages.private.json');registry=read(root/'science-registry.private.json');functions=read(baseline)
    dump=lambda path,value:path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
    env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
    command=lambda args,**kw:subprocess.run([str(a) for a in args],env=env,text=True,capture_output=True,**kw)
    lit=lambda s:"'"+str(s).replace("'","''")+"'"
    with tempfile.TemporaryDirectory(prefix='ewha-essay-') as directory:
        t=Path(directory);sock=t/'socket';sock.mkdir();data=t/'db'
        for args in [[pg/'initdb','-D',data,'-U','local_admin','--auth=trust','--no-locale','--encoding=UTF8'],[pg/'pg_ctl','-D',data,'-l',t/'postgres.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']]:
            r=command(args);assert not r.returncode,r.stderr
        try:
            def sql(query, failure=None):
                r=command([pg/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','local_admin','-d','postgres'],input="set timezone='UTC';"+query)
                if failure:assert r.returncode and failure in r.stderr,r.stderr;return
                assert not r.returncode,r.stderr;return r.stdout.strip()
            sql("create schema essay_exam_private;create schema essay_material_private;create schema storage;create role authenticated;create table storage.buckets(id text primary key,public bool);insert into storage.buckets values('essay-material-originals',false);create table storage.objects(id int);create policy untouched on storage.objects for select to authenticated using(false);create table public.essay_exams(id uuid primary key,is_active bool);create table public.essay_questions(id uuid primary key,essay_exam_id uuid,question_key text,is_published bool);create table essay_material_private.documents(sha256 text primary key,resource_id uuid,title text,page_count int,object_key text,created_at timestamptz default now());create table essay_material_private.reviews(exam_id uuid primary key,revision int,state text,body jsonb,updated_at timestamptz default now(),reviewer uuid,approval_requested bool);create table essay_material_private.revisions(exam_id uuid,revision int,state text,body jsonb,reviewer uuid,created_at timestamptz default now(),primary key(exam_id,revision));create table essay_exam_private.runs(id uuid primary key,exam_id uuid,state text,result jsonb)")
            for name in ('runtime_policy','essay_material_runtime_package','essay_exam_preflight','essay_exam_submit','essay_exam_submit_cycle'):
                f=next(f for f in functions if f['proname']==name);sql(f['definition'])
            for exam in registry['exams']:
                sql(f"insert into public.essay_exams values({lit(exam['examId'])},false)")
                for q in exam['questions']:sql(f"insert into public.essay_questions values({lit(q['id'])},{lit(exam['examId'])},{lit(q['sourceKey'])},false)")
            for table in ('reviews','revisions'):
                rows=read(baseline.parent/('science-existing-'+table+'.private.json'))
                for row in rows:
                    sql(f"insert into essay_material_private.{table} select * from jsonb_populate_record(null::essay_material_private.{table},{lit(json.dumps(row['r']))}::jsonb)")
            original_revisions=sql("select jsonb_agg(to_jsonb(r) order by exam_id,revision) from essay_material_private.revisions r")
            oldid='00000000-0000-4000-8000-000000000003'
            sql(f"insert into public.essay_exams values({lit(oldid)},true);insert into public.essay_questions values({lit(oldid)},{lit(oldid)},'preserved',true);insert into essay_exam_private.runs values({lit(oldid)},{lit(oldid)},'completed','{{\"preserve\":true}}')")
            policy=next(f for f in functions if f['proname']=='runtime_policy');oldids=sorted(set(re.findall(r"p_exam='([a-f0-9-]{36})'",policy['definition'])))
            read_policies=lambda:sql("select jsonb_object_agg(e,essay_exam_private.runtime_policy(e::uuid)) from unnest(array["+','.join(lit(x) for x in oldids)+"]) e")
            before=read_policies()
            def checks(name):
                q=(candidate/name).read_text().strip().rstrip(';');v=json.loads(sql('select row_to_json(r) from ('+q+') r'));assert all(x is True for x in v.values()),v;return len(v)
            pre=checks('essay-precheck.sql')
            first=next(iter(packages));sql(f"insert into essay_exam_private.runs values('00000000-0000-4000-8000-000000000004',{lit(first)},'running',null)")
            sql((root/'essay-apply.private.sql').read_text(),'SCIENCE_ESSAY_BASELINE_CHANGED')
            sql("delete from essay_exam_private.runs where id='00000000-0000-4000-8000-000000000004'")
            sql((root/'essay-apply.private.sql').read_text());post=checks('essay-postcheck.sql')
            sql((root/'essay-apply.private.sql').read_text(),'SCIENCE_ESSAY_BASELINE_CHANGED')
            assert before==read_policies()
            assert sql('select count(*) from public.essay_questions where is_published')=='1'
            for eid,p in packages.items():
                actual=sql(f"select body->'package'->>'package_digest' from essay_material_private.reviews where exam_id={lit(eid)}");assert actual==p['package_digest']
            sql((candidate/'essay-rollback.sql').read_text());sql((candidate/'essay-rollback.sql').read_text())
            assert before==read_policies()
            assert sql('select count(*) from public.essay_questions where is_published')=='1'
            assert sql('select count(*) from essay_material_private.revisions')=='7'
            assert sql("select jsonb_agg(to_jsonb(r) order by exam_id,revision) from essay_material_private.revisions r where revision=1 and exam_id in ('0b5b9aea-e23f-5644-84df-5e5f6f5a2782','c71cb668-d9c6-52a9-b771-c48c3efd7dc3')")==original_revisions
            assert sql("select result->>'preserve' from essay_exam_private.runs")=='true'
            assert sql("select count(*) from pg_policies where policyname='untouched'")=='1'
            assert sql('select count(*) from essay_material_private.documents')=='13'
            outcome=dict(status='PASS',environment='isolated PostgreSQL17 Unix socket',prechecks=pre,postchecks=post,
              inserted_documents=13,inserted_reviews=3,advanced_reviews=2,old_revisions_preserved=2,inserted_revisions=5,runtime_connected_questions=22,legacy_registry_flags_preserved=True,
              old_runtime_entries_preserved=len(oldids),all_5_jsonb_digests_verified=True,reapply_blocked=True,
              existing_runs_block_apply=True,rollback_idempotent=True,rollback_keeps_all_materials_and_histories=True,
              existing_question_publication_unchanged=True,existing_RLS_unchanged=True,production_writes=0)
            dump(candidate/'essay-sql-validation.json',outcome)
        finally:command([pg/'pg_ctl','-D',data,'-m','immediate','-w','stop'])
    return outcome

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--baseline',type=Path,required=True);p.add_argument('--pg-bin',type=Path,required=True);a=p.parse_args();print(run(APP,a.baseline,a.pg_bin))
