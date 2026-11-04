"""Migration preservation check on a second synthetic local database."""
import subprocess, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[3]
BASE=['/opt/homebrew/opt/postgresql@17/bin/psql','-h','127.0.0.1','-p','55441','-X','-qAt','-v','ON_ERROR_STOP=1']
DB='legendstudy_support_upgrade_20261104'
def run(text,db=DB):
 r=subprocess.run(BASE+['-d',db],input=text,text=True,capture_output=True);assert r.returncode==0,r.stderr;return r.stdout.strip()
run(f'drop database if exists {DB};','postgres');run(f'create database {DB};','postgres')
p=ROOT/'supabase/verification/support_integration'
bootstrap=(p/'bootstrap.sql').read_text().replace('create role anon; create role authenticated; create role service_role bypassrls;','')
run(bootstrap)
run((ROOT/'supabase/migrations/20260917000100_feedback_operations.sql').read_text())
run((p/'live_functions_baseline.sql').read_text())
run((p/'admin_operator_baseline.sql').read_text())
run("""insert into auth.users values('00000000-0000-4000-8000-000000000001','synthetic@example.invalid');
insert into profiles(id) select id from auth.users;
insert into admin_users select id,now() from auth.users;
insert into feedback_submissions(user_id,category,title,body,app_version,build_number,platform,os_version) select id,'suggestion','Existing APP','Existing original','1','1','ios','test' from auth.users;
insert into inquiries(user_id,category,title,body,request_key) select id,'other','Existing WEB','Existing WEB original',gen_random_uuid() from auth.users;
insert into inquiry_replies(inquiry_id,author_id,body,request_key) select id,user_id,'Existing reply',gen_random_uuid() from inquiries;
insert into inquiry_notifications(inquiry_id,reply_id) select inquiry_id,id from inquiry_replies;
insert into inquiry_status_events(inquiry_id,from_status,to_status,actor_kind) select id,null,'RECEIVED','member' from inquiries;
""")
tables=['feedback_submissions','inquiries','inquiry_replies','inquiry_notifications','inquiry_status_events']
def digest(t):return run(f"select md5(string_agg((to_jsonb(t)-'feedback_id')::text,'' order by id)) from {t} t")
before={t:digest(t) for t in tables}
run((ROOT/'supabase/migrations/20261104002306_unified_support_inquiries.sql').read_text())
for t in tables:assert before[t]==digest(t),t;print('PASS existing row preservation:',t)
assert run('select count(*) from support_private.items')=='2'
assert run('select count(*) from support_private.feedback_state')=='0'
print('7 upgrade checks PASS; source rows and existing answers/notifications/events unchanged')
