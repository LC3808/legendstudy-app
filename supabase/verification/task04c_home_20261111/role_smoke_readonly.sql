begin transaction read only;
set local statement_timeout='15s';
do $verify$
declare u uuid; observed jsonb;
begin
  -- Existing blocked users only. No Auth/lifecycle changes and no test records.
  for u in select subject_id from public.account_deletion_requests
    where state in ('DELETION_PENDING','ERASING') and subject_id is not null loop
    perform set_config('request.jwt.claim.sub',u::text,true);
    perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
    execute 'set local role authenticated';
    begin
      perform public.my_home_configuration();
      raise exception 'BLOCKED_HOME_READ_ACCEPTED';
    exception when insufficient_privilege then null; end;
    begin
      perform public.save_my_home_configuration('{"config_version":1,"cards":[]}',0);
      raise exception 'BLOCKED_HOME_SAVE_ACCEPTED';
    exception when insufficient_privilege then null; end;
    execute 'reset role';
  end loop;
  select id into u from auth.users where account_private.allowed(id) order by id limit 1;
  if u is null then raise exception 'NO_ACTIVE_USER_FOR_READ_SMOKE'; end if;
  perform set_config('request.jwt.claim.sub',u::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
  execute 'set local role authenticated';
  observed := public.my_home_configuration();
  -- Inspect only the existing shared read RPC's contract, never change applications.
  observed := public.my_applications(0);
  if observed->>'version' is distinct from 'applications-v1' then raise exception 'EXISTING_RPC_CONTRACT_CHANGED'; end if;
  begin
    perform 1 from public.home_configuration_revisions;
    raise exception 'DIRECT_HOME_TABLE_READ_ACCEPTED';
  exception when insufficient_privilege then null; end;
  execute 'reset role';
  perform set_config('request.jwt.claim.sub','',true);
  perform set_config('request.jwt.claims','{}',true);
  execute 'set local role anon';
  begin
    perform public.my_home_configuration();
    raise exception 'ANON_HOME_READ_ACCEPTED';
  exception when insufficient_privilege then null; end;
  execute 'reset role';
end;
$verify$;
select 'PASS: read-only DB-role smoke; existing blocked users denied; active read/shared application read valid; direct table/anon denied' as result,
 (select jsonb_object_agg(state,n) from (select state,count(*) n from public.account_deletion_requests where state in ('DELETION_PENDING','ERASING') group by state) s) as blocked_states,
 (select count(*) from public.home_configuration_revisions) as home_rows;
rollback;
