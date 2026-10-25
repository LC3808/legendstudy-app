"""Run the private candidate against an ephemeral Unix-socket PostgreSQL only."""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path


def verify(root, pg):
    sql_root = root / 'owner-sql'
    reviews = json.loads((root.parent / 'expansion-live-reviews.private.json').read_text())
    registry = json.loads((root / 'registry.private.json').read_text())
    functions = json.loads((root / 'functions.private.json').read_text())
    packages = json.loads((root / 'packages.private.json').read_text())
    env = {k: v for k, v in os.environ.items() if not k.startswith('PG')};env['LC_ALL'] = 'C'
    def run(args, **kwargs):
        return subprocess.run([str(a) for a in args], env=env, text=True, capture_output=True, **kwargs)
    lit = lambda x: "'" + str(x).replace("'", "''") + "'"
    with tempfile.TemporaryDirectory(prefix='group1a-') as temp:
        tmp = Path(temp);sock = tmp / 'sock';sock.mkdir();data = tmp / 'db'
        for args in [[pg/'initdb', '-D', data, '-U', 'local_admin', '--auth=trust', '--no-locale', '--encoding=UTF8'],
                     [pg/'pg_ctl', '-D', data, '-l', tmp/'log', '-o', f"-k {sock} -p 5432 -c listen_addresses=''", '-w', 'start']]:
            result = run(args);assert result.returncode == 0, result.stderr
        try:
            def sql(text, failure=None):
                result = run([pg/'psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', sock, '-U', 'local_admin', '-d', 'postgres'], input=text)
                if failure:
                    assert result.returncode and failure in result.stderr, result.stderr
                    return
                assert result.returncode == 0, result.stderr
                return result.stdout.strip()
            sql("create schema essay_exam_private;create schema essay_material_private;create schema storage;create role authenticated;create function public.account_service_allowed() returns boolean language sql as 'select true';create table storage.buckets(id text primary key,public boolean);create table storage.objects(id int,bucket_id text,name text);create table essay_material_private.reviews(exam_id uuid primary key,revision int,state text,body jsonb,reviewer uuid,updated_at timestamptz,approval_requested bool);create table essay_material_private.revisions(exam_id uuid,revision int,state text,body jsonb,reviewer uuid,primary key(exam_id,revision));create table essay_exam_private.runs(id uuid primary key,exam_id uuid,state text,result jsonb);create table public.essay_questions(id uuid primary key,essay_exam_id uuid,question_key text);")
            sql("insert into storage.buckets values('essay-material-originals',false);insert into storage.objects values(1,'essay-material-originals','7acf8c7c396ac1ad8b05f071592c184c37c32bd2ece9f2f697346733845c5cb4.pdf');create policy untouched on storage.objects for select to authenticated using(false)")
            for f in functions:sql(f['definition'])
            for row in reviews:
                sql('insert into essay_material_private.reviews select * from jsonb_populate_record(null::essay_material_private.reviews,' + lit(json.dumps(row)) + '::jsonb)')
                sql('insert into essay_material_private.revisions select exam_id,revision,state,body,reviewer from essay_material_private.reviews where exam_id=' + lit(row['exam_id']))
            for exam in registry['exams']:
                for q in exam['questions']:
                    sql(f"insert into public.essay_questions values({lit(q['id'])},{lit(exam['examId'])},{lit(q['sourceKey'])})")
            def policies():
                return sql('select jsonb_object_agg(essay_exam_id,essay_exam_private.runtime_policy(essay_exam_id)) from public.essay_questions')
            def checks(name):
                values = json.loads(sql('select row_to_json(t) from (' + (sql_root/name).read_text().strip().rstrip(';') + ') t'))
                assert all(v is True for v in values.values()), values
                return len(values)
            before = policies();pre = checks('precheck.sql')
            eid = next(iter(packages))
            sql(f"insert into essay_exam_private.runs values('00000000-0000-4000-8000-000000000001',{lit(eid)},'running','{{\"preserve\":true}}')")
            sql((sql_root/'apply.private.sql').read_text(), 'GROUP1A_BASELINE_CHANGED')
            sql("update essay_exam_private.runs set state='completed'")
            sql((sql_root/'apply.private.sql').read_text());post = checks('postcheck.sql')
            sql((sql_root/'apply.private.sql').read_text(), 'GROUP1A_BASELINE_CHANGED')
            exported = json.loads(sql("select jsonb_agg(jsonb_build_object('exam_id',exam_id,'package',body->'package','policy',essay_exam_private.runtime_policy(exam_id))) from essay_material_private.reviews"))
            (root/'local-applied.private.json').write_text(json.dumps(exported, ensure_ascii=False))
            # Every other policy and the immutable historical record must survive.
            after = json.loads(policies());old = json.loads(before)
            assert all(after[k] == v for k, v in old.items() if k not in packages)
            assert sql("select result->>'preserve' from essay_exam_private.runs") == 'true'
            assert sql("select count(*) from pg_policies where policyname='untouched'") == '1'
            sql((sql_root/'rollback.sql').read_text());sql((sql_root/'rollback.sql').read_text())
            assert before == policies()
            assert sql('select count(*) from essay_material_private.revisions') == '6'
            for item in exported:
                assert int(sql(f"select jsonb_array_length(public.essay_material_runtime_package({lit(item['exam_id'])},{lit(item['package']['package_digest'])})->'questions')")) == len(packages[item['exam_id']]['questions'])
            result = dict(status='PASS',environment='isolated PostgreSQL17',prechecks=pre,postchecks=post,
                          reapply_blocked=True,active_run_blocks=True,other_policies_preserved=True,
                          history_preserved=True,rollback_idempotent=True,rollback_keeps_readable_packages=True,
                          production_writes=0)
            (root/'sql-isolation-result.json').write_text(json.dumps(result, indent=2));return result
        finally:
            run([pg/'pg_ctl', '-D', data, '-m', 'immediate', '-w', 'stop'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__);parser.add_argument('root',type=Path)
    parser.add_argument('--pg',type=Path,default=Path('/opt/homebrew/opt/postgresql@17/bin'))
    args = parser.parse_args();print(json.dumps(verify(args.root,args.pg)))
