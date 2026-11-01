-- EMPTY isolated PostgreSQL database ONLY. Never run on shared TEST/production.
set timezone='UTC';
create schema auth;create schema account_private;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('test.user',true),'')::uuid$$;
create function public.admin_operator() returns boolean language sql as $$select coalesce(current_setting('test.admin',true),'false')='true'$$;
create function account_private.allowed(uuid) returns boolean language sql as $$select $1 is not null$$;
create table public.profiles(id uuid primary key);
create table public.universities(id uuid primary key,name text);
create table public.content_items(id uuid primary key,title text);
create table public.student_target_universities(user_id uuid,university_id uuid,created_at timestamptz);
create table public.bookmarks(user_id uuid,content_item_id uuid,created_at timestamptz);
create table public.recent_views(user_id uuid,content_item_id uuid,viewed_at timestamptz);
create table public.student_applications(user_id uuid,university_id uuid,created_at timestamptz);
create table public.study_sessions(user_id uuid,started_at timestamptz,ended_at timestamptz,include_in_study_total boolean,active_segments jsonb);
\ir install.sql
select set_config('test.user','00000000-0000-0000-0000-000000000001',false);
do $$begin
 begin perform public.admin_learning_analytics('2026-11-01','2026-11-02');raise exception 'denial failed';exception when insufficient_privilege then null;end;
end$$;
select set_config('test.admin','true',false);
do $$begin
 assert public.admin_learning_analytics('2026-11-01','2026-11-02')->>'state'='EMPTY';
 begin perform public.admin_learning_analytics('2026-11-02','2026-11-01');raise exception 'period failed';exception when sqlstate 'PT422' then null;end;
 assert not has_function_privilege('anon','public.admin_learning_analytics(timestamptz,timestamptz)','execute');
 assert not has_function_privilege('service_role','public.admin_learning_analytics(timestamptz,timestamptz)','execute');
 assert has_function_privilege('authenticated','public.admin_learning_analytics(timestamptz,timestamptz)','execute');
end$$;
insert into profiles select ('00000000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid from generate_series(1,5)i;
insert into universities values('10000000-0000-0000-0000-000000000001','검증 대학');
insert into student_target_universities select id,'10000000-0000-0000-0000-000000000001','2026-11-01' from profiles;
-- Duplicate same learner in a different target year must not increase unique users.
insert into student_target_universities select * from student_target_universities limit 1;
insert into study_sessions select id,'2026-11-01','2026-11-01 01:00Z',true,'[[0,3600000]]' from profiles;
insert into study_sessions select * from study_sessions;
do $$declare r jsonb;begin
 r=public.admin_learning_analytics('2026-11-01','2026-11-02');
 assert (r#>>'{metrics,targets}')::int=5;
 assert (r#>>'{metrics,study_ms}')::bigint=18000000;
 assert r#>>'{rows,0,label}'='검증 대학';
 assert (r#>>'{rows,0,records}')::int=6;
 -- boundary clipping and per-user union
 assert (public.admin_learning_analytics('2026-11-01 00:30Z','2026-11-02')#>>'{metrics,study_ms}')::bigint=9000000;
end$$;
delete from study_sessions where user_id=(select id from profiles limit 1);
delete from student_target_universities where user_id=(select id from profiles limit 1);
do $$declare r jsonb;begin
 r=public.admin_learning_analytics('2026-11-01','2026-11-02');
 assert r->>'state'='SUPPRESSED';assert r#>'{metrics,study_ms}'='null'::jsonb;assert r->'rows'='[]'::jsonb;
end$$;
\ir rollback.sql
do $$begin assert not has_function_privilege('authenticated','public.admin_learning_analytics(timestamptz,timestamptz)','execute');assert (select count(*) from profiles)=5;end$$;
