-- OWNER REVIEW CANDIDATE. Does not activate LIVE or rewrite payment/credit rows.
-- Run as postgres only after the current function hashes and identity are reviewed.
begin;
do $$begin
 if current_user<>'postgres' or pg_has_role('postgres','essay_executor','SET') or has_schema_privilege('essay_executor','public','CREATE') then raise exception 'LIVE_PREP_TOPOLOGY';end if;
 if md5(pg_get_functiondef('public.payment_order(jsonb)'::regprocedure))<>'66d56523afa59d4830be50cea9c384a4' or md5(pg_get_functiondef('public.payment_process(jsonb)'::regprocedure))<>'f71fd69c6e37653a4ba4fe7d2ff42a02' then raise exception 'LIVE_PREP_FUNCTION_DRIFT';end if;
 if (select mode from payment_private.configuration where singleton) is distinct from 'TEST' then raise exception 'LIVE_PREP_EXPECT_TEST';end if;
 if not exists(select 1 from auth.users where id='ddc5ae63-acbb-490b-a423-c996b811dea8' and email='review@legendstudy.com' and email_confirmed_at is not null) then raise exception 'LIVE_PREP_REVIEW_IDENTITY';end if;
end$$;
create temporary table payment_live_before on commit drop as select
 (select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m) memberships,
 (select nspacl::text from pg_namespace where nspname='public') acl,
 (select jsonb_agg(jsonb_build_array(oid,proowner,proacl::text) order by oid) from pg_proc where oid in ('public.payment_order(jsonb)'::regprocedure,'public.payment_process(jsonb)'::regprocedure)) functions;
-- Narrow private read helper: no email argument, no caller-selected user, no browser EXECUTE.
create function payment_private.current_order_mode() returns text language plpgsql stable security definer set search_path='' as $$
declare u uuid=essay_private.uid(); m text;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 select mode into m from payment_private.configuration where singleton;
 if m='TEST' then return 'TEST';end if;
 if m is distinct from 'LIVE' then raise sqlstate 'PT503' using message='MODE_UNAVAILABLE';end if;
 if exists(select 1 from auth.users where id=u and id='ddc5ae63-acbb-490b-a423-c996b811dea8' and email='review@legendstudy.com' and email_confirmed_at is not null) then return 'TEST';end if;
 return 'LIVE';
end$$;
revoke all on function payment_private.current_order_mode() from public,anon,authenticated,service_role;
grant execute on function payment_private.current_order_mode() to essay_executor;
-- Preserve existing ownership/ACL; temporarily reuse the canonical bootstrap capability.
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to essay_executor;
set role essay_executor;
do $$declare old text; updated text;begin
 old=pg_get_functiondef('public.payment_order(jsonb)'::regprocedure);
 updated=replace(old,'select mode into v_mode from payment_private.configuration where singleton;','v_mode=payment_private.current_order_mode();');
 if old=updated then raise exception 'LIVE_PREP_ORDER_MARKER';end if;
 execute updated;
 old=pg_get_functiondef('public.payment_process(jsonb)'::regprocedure);
 updated=replace(old,'if o.mode is distinct from (select mode from payment_private.configuration where singleton) then',
 'if not exists(select 1 from payment_private.configuration where singleton and (mode=o.mode or (mode=''LIVE'' and o.mode=''TEST''))) then');
 if old=updated then raise exception 'LIVE_PREP_PROCESS_MARKER';end if;
 execute updated;
end$$;
reset role;
revoke create on schema public from essay_executor;
revoke essay_executor from postgres granted by postgres;
do $$begin
 if (select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m) is distinct from (select memberships from payment_live_before)
 or (select nspacl::text from pg_namespace where nspname='public') is distinct from (select acl from payment_live_before)
 or (select jsonb_agg(jsonb_build_array(oid,proowner,proacl::text) order by oid) from pg_proc where oid in ('public.payment_order(jsonb)'::regprocedure,'public.payment_process(jsonb)'::regprocedure)) is distinct from (select functions from payment_live_before)
 then raise exception 'LIVE_PREP_RESTORE_FAILED';end if;
end$$;
commit;
