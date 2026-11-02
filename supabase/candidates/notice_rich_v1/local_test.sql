-- ISOLATED DATABASE ONLY. psql -v ON_ERROR_STOP=1 -f local_test.sql
do $$begin
 if not exists(select 1 from pg_roles where rolname='anon') then create role anon; end if;
 if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
 if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role; end if;
end$$;
create schema auth;
create schema account_private;
create table auth.users(id uuid primary key);
create table public.admin_users(user_id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
-- Account policy fixture: third identity is disabled.
create function account_private.allowed(id uuid) returns boolean language sql stable as $$select id is not null and id<>'00000000-0000-0000-0000-000000000003'::uuid$$;
create function public.admin_operator() returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and exists(select 1 from public.admin_users where user_id=auth.uid())$$;
grant usage on schema public,auth to anon,authenticated,service_role;
insert into auth.users values('00000000-0000-0000-0000-000000000001'),('00000000-0000-0000-0000-000000000002'),('00000000-0000-0000-0000-000000000003');
insert into public.admin_users values('00000000-0000-0000-0000-000000000001');
create schema storage;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(bucket_id text references storage.buckets,name text,primary key(bucket_id,name));
alter table storage.objects enable row level security;
grant usage on schema storage to anon,authenticated;
grant select,insert,update,delete on storage.objects to anon,authenticated;
-- Simulate broad unrelated Storage policy: restrictive notice guards must override it.
create policy unrelated_broad on storage.objects for all to anon,authenticated using(true) with check(true);
\ir ../notices_v1/install.sql
\ir install.sql
create function public.assert_ok(ok boolean, msg text) returns void language plpgsql as $$ begin if ok is distinct from true then raise exception 'ASSERT: %',msg; end if; end $$;
create function public.assert_denied(query text) returns void language plpgsql as $$begin execute query;raise exception 'EXPECTED DENIAL: %',query;exception when insufficient_privilege then return;end$$;
create function public.assert_error(query text, expected text) returns void language plpgsql as $$declare detail text;begin begin execute query;exception when others then get stacked diagnostics detail=message_text;if detail=expected then return;else raise;end if;end;raise exception 'EXPECTED ERROR: %',expected;end$$;

set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.assert_ok(public.notice_editor_capability()->>'version'='1','admin capability');
insert into storage.objects values('notice-media','00000000-0000-0000-0000-000000000001/00000000-0000-0000-0000-000000000010.webp');
select public.notice_admin_save_rich('{
 "title":"서식 공지","category":"general","status":"draft","content":"forged fallback",
 "content_document":{"version":1,"blocks":[
 {"type":"text","text":"중요 안내","size":22,"bold":true,"underline":true},
 {"type":"image","path":"00000000-0000-0000-0000-000000000001/00000000-0000-0000-0000-000000000010.webp","alt":"일정 안내"}]}}') as rich \gset
select public.assert_ok(:'rich'::jsonb->>'content'=E'중요 안내\n\n[이미지: 일정 안내]','server-derived legacy text');
reset role;
select public.assert_ok((select count(*) from notice_private.revisions where snapshot->'content_document' is not null)=1,'rich immutable revision');
set role anon;
select set_config('request.jwt.claim.sub','',false);
select public.assert_ok((select count(*) from storage.objects where bucket_id='notice-media')=0,'draft image hidden despite broad policy');
select public.assert_denied('select public.notice_admin_save_rich(''{}'')');
select public.assert_denied('select public.notice_editor_capability()');
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
select public.assert_denied('select public.notice_admin_save_rich(''{}'')');
select public.assert_denied('insert into storage.objects values(''notice-media'',''00000000-0000-0000-0000-000000000002/00000000-0000-0000-0000-000000000010.webp'')');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.assert_error('select public.notice_admin_save_rich(''{"content_document":{"version":1,"blocks":[{"type":"html"}]}}'')','INVALID_NOTICE_DOCUMENT');
select public.notice_admin_save_rich(:'rich'::jsonb || jsonb_build_object('status','published','published_at',now()-interval '1 hour')) as published \gset
select public.assert_error('select public.notice_admin_save_rich(' || quote_literal(:'rich') || ')','NOTICE_CONFLICT');
set role anon;
select set_config('request.jwt.claim.sub','',false);
select public.assert_ok((select count(*) from storage.objects where bucket_id='notice-media')=1,'published public image readable');
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.notice_admin_save_rich(:'published'::jsonb || '{"is_public":false}') as member \gset
set role anon;
select set_config('request.jwt.claim.sub','',false);
select public.assert_ok((select count(*) from storage.objects where bucket_id='notice-media')=0,'member image hidden from guest');
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
select public.assert_ok((select count(*) from storage.objects where bucket_id='notice-media')=1,'member image available to eligible member');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',false);
select public.assert_ok((select count(*) from storage.objects where bucket_id='notice-media')=0,'disabled account denied');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.notice_admin_save_rich(:'member'::jsonb || jsonb_build_object('expires_at',now()-interval '1 second')) as expired \gset
set role anon;
select set_config('request.jwt.claim.sub','',false);
select public.assert_ok((select count(*) from storage.objects where bucket_id='notice-media')=0,'expired image hidden');
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.notice_admin_save(:'expired'::jsonb || '{"content":"legacy edit"}') as legacy \gset
select public.assert_ok(:'legacy'::jsonb->'content_document'='null'::jsonb,'old writer cannot retain stale formatting');
reset role;
select public.assert_ok((select count(*) from storage.objects)=1,'image history not deleted');
\ir rollback.sql
set role authenticated;
select public.assert_denied('select public.notice_editor_capability()');
reset role;
select public.assert_ok((select count(*) from notice_private.revisions)>0,'rollback keeps history');
select 'NOTICE_RICH_SQL_PASS' as result;
