-- ISOLATED DATABASE ONLY. psql -v ON_ERROR_STOP=1 -f local_test.sql
create role anon;
create role authenticated;
create role service_role;
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
\ir install.sql
create function public.assert_ok(ok boolean, msg text) returns void language plpgsql as $$ begin if ok is distinct from true then raise exception 'ASSERT: %',msg; end if; end $$;
create function public.assert_denied(query text) returns void language plpgsql as $$begin execute query;raise exception 'EXPECTED DENIAL: %',query;exception when insufficient_privilege then return;end$$;
create function public.assert_error(query text, expected text) returns void language plpgsql as $$declare detail text;begin begin execute query;exception when others then get stacked diagnostics detail=message_text;if detail=expected then return;else raise;end if;end;raise exception 'EXPECTED ERROR: %',expected;end$$;
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.notice_admin_save(jsonb_build_object('title','공개 공지','content','내용 <script>alert(1)</script>', 'category','general','status','published','published_at',now()-interval '1 hour','is_pinned',true)) as public_notice \gset
select public.notice_admin_save(jsonb_build_object('title','회원 공지','content','내용','category','policy','status','published','published_at',now()-interval '1 hour','is_public',false)) as member_notice \gset
select public.notice_admin_save(jsonb_build_object('title','예약','content','내용','category','update','status','published','published_at',now()+interval '1 hour')) as scheduled \gset
select public.notice_admin_save(jsonb_build_object('title','종료','content','내용','category','beta','status','published','published_at',now()-interval '2 hours','expires_at',now()-interval '1 hour')) as expired \gset
select public.notice_admin_save('{"title":"초안","content":"내용","category":"event","status":"draft"}') as draft \gset
select public.notice_admin_save(jsonb_build_object('title','WEB만','content','내용','category','maintenance','status','published','published_at',now()-interval '1 hour','show_app',false)) as web_only \gset
select public.assert_ok((public.notice_list('app')->>'total')::int=2,'admin visible public/member');
select public.assert_ok((public.notice_admin_list()->>'total')::int=6,'admin all');
reset role;
set role anon;
select set_config('request.jwt.claim.sub','',false);
select public.assert_ok((public.notice_list('app')->>'total')::int=1,'guest only public active APP');
select public.assert_ok((public.notice_list('web')->>'total')::int=2,'platform gating');
select public.assert_ok((public.notice_list('app')->>'unread')::int=0,'guest unread not fabricated');
select public.assert_ok(public.notice_detail((:'member_notice'::jsonb->>'notice_id')::uuid,'app') is null,'guest member detail denied');
select public.assert_ok(public.notice_detail((:'draft'::jsonb->>'notice_id')::uuid,'app') is null,'draft detail hidden');
select public.assert_ok(public.notice_detail((:'scheduled'::jsonb->>'notice_id')::uuid,'app') is null,'scheduled detail hidden');
select public.assert_ok(public.notice_detail((:'expired'::jsonb->>'notice_id')::uuid,'app') is null,'expired detail hidden');
select public.assert_denied('select public.notice_admin_list()');
select public.assert_denied('select * from notice_private.notices');
select public.assert_denied('select public.notice_mark_read(null,''app'',now())');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
select public.assert_denied('select public.notice_admin_save(''{}'')');
select public.assert_denied('select public.notice_admin_list()');
select public.assert_denied('select * from notice_private.reads');
select public.assert_ok((public.notice_list('app')->>'unread')::int=2,'unread initial');
select public.assert_ok(public.notice_mark_read((:'public_notice'::jsonb->>'notice_id')::uuid,'app',(:'public_notice'::jsonb->>'updated_at')::timestamptz),'mark owned');
select public.assert_ok((public.notice_list('web')->>'unread')::int=2,'APP read reflected WEB');
select public.assert_ok(public.notice_mark_read((:'public_notice'::jsonb->>'notice_id')::uuid,'app',(:'public_notice'::jsonb->>'updated_at')::timestamptz),'repeated read succeeds idempotently');
select public.assert_ok((public.notice_detail((:'public_notice'::jsonb->>'notice_id')::uuid,'web')->>'is_read')::boolean,'read synced');
select public.assert_ok(not public.notice_mark_read((:'draft'::jsonb->>'notice_id')::uuid,'app',now()),'hidden receipt rejected');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.assert_ok((public.notice_list('app')->>'unread')::int=2,'other user receipt isolated');
select public.notice_admin_save(:'public_notice'::jsonb || '{"title":"改訂 notice"}') as edited \gset
select public.assert_error(format('select public.notice_admin_save(%L::jsonb)', :'public_notice'), 'NOTICE_CONFLICT');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
select public.assert_ok((public.notice_list('app')->>'unread')::int=2,'edit becomes unread');
select public.assert_ok(not public.notice_mark_read((:'public_notice'::jsonb->>'notice_id')::uuid,'app',(:'public_notice'::jsonb->>'updated_at')::timestamptz),'stale read cannot mark new edit');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',false);
select public.assert_ok(public.notice_detail((:'member_notice'::jsonb->>'notice_id')::uuid,'app') is null,'disabled member blocked');
select public.assert_denied('select public.notice_mark_read(null,''app'',now())');
reset role;
select public.assert_ok((select count(*)=7 from notice_private.revisions),'all successful save snapshots retained');
select public.assert_ok((select count(*)=1 from notice_private.reads),'read idempotent no other identity writes');
select public.assert_ok((select count(*)=3 from auth.users),'identities unchanged');
select public.assert_ok(not has_function_privilege('service_role','public.notice_admin_save(jsonb)','EXECUTE'),'service role denied');
select public.assert_ok((select bool_and(relrowsecurity) from pg_class where relnamespace='notice_private'::regnamespace and relkind='r'),'RLS all tables');
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.notice_admin_save(:'edited'::jsonb || '{"status":"archived"}') as archived \gset
select public.assert_ok(public.notice_detail((:'edited'::jsonb->>'notice_id')::uuid,'app') is null,'archived hidden immediately');
reset role;
\ir rollback.sql
set role authenticated;
select public.assert_denied('select public.notice_list(''app'')');
reset role;
select public.assert_ok((select count(*)=6 from notice_private.notices),'rollback preserves all notices');
select public.assert_ok((select count(*)=8 from notice_private.revisions),'rollback preserves revisions');
select 'NOTICE CONTRACT PASS' as result;
