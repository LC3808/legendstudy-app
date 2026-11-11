-- SYNTHETIC FIXTURES. Local scratch database ONLY; never production.
\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('00000000-0000-0000-0000-000000000001'),('00000000-0000-0000-0000-000000000002');
insert into public.universities(id,name) values('00000000-0000-0000-0000-000000000010','SYNTHETIC TEST UNIVERSITY');
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000001';
do $$
declare v jsonb; cfg jsonb := '{"config_version":1,"cards":[{"card_id":"dday","visible":false,"display_order":0}]}';
begin
  if public.my_home_configuration() is not null then raise exception 'Unset should be null'; end if;
  v := public.save_my_home_configuration(cfg,0);
  if v->>'revision' <> '1' then raise exception 'First revision'; end if;
  v := public.save_my_home_configuration(cfg,0);
  if v->>'revision' <> '1' then raise exception 'Retry must be idempotent'; end if;
  begin
    perform public.save_my_home_configuration('{"config_version":1,"cards":[]}',0);
    raise exception 'Stale revision accepted';
  exception when serialization_failure then null; end;
  v := public.save_my_home_configuration('{"config_version":1,"cards":[]}',1);
  if v->>'revision' <> '2' then raise exception 'Second revision'; end if;
  begin
    perform public.save_my_home_configuration('{"config_version":1,"cards":[{"card_id":"dday","visible":true,"display_order":0},{"card_id":"dday","visible":false,"display_order":1}]}',2);
    raise exception 'Duplicate accepted';
  exception when invalid_parameter_value then null; end;
  begin
    perform * from public.home_configuration_revisions;
    raise exception 'Direct history read allowed';
  exception when insufficient_privilege then null; end;
end; $$;
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000002';
do $$begin if public.my_home_configuration() is not null then raise exception 'Cross-owner leak'; end if; end;$$;
set local request.jwt.claim.sub='';
do $$begin
  begin perform public.save_my_home_configuration('{"config_version":1,"cards":[]}',0); raise exception 'Anonymous save';
  exception when invalid_authorization_specification then null; end;
end;$$;
reset role;
do $$begin
  if (select count(*) from public.home_configuration_revisions) <> 2 then raise exception 'History lost'; end if;
  if has_function_privilege('anon','public.save_my_home_configuration(jsonb,bigint)','execute') then raise exception 'Anonymous privilege'; end if;
  if has_function_privilege('authenticated','public.task04_news_immutable()','execute') then raise exception 'Trigger exposed'; end if;
end;$$;
insert into public.university_official_sources values('00000000-0000-0000-0000-000000000010','admission.example.edu',now());
insert into public.university_news_revisions(series_key,revision,university_id,academic_year,scope,kind,event_type,title,precision,starts_on,source_host,source_title,source_url,source_sha256,source_archive_key,source_locator,verified_at,updated_at,expires_at,status)
values('00000000-0000-0000-0000-000000000020',1,'00000000-0000-0000-0000-000000000010',2027,'university','schedule','final_result','SYNTHETIC','date','2026-12-18','admission.example.edu','SYNTHETIC','https://admission.example.edu/notice',repeat('a',64),'synthetic-only','p1',now(),now(),now()+interval '1 day','verified');
do $$begin
 if jsonb_array_length(public.university_news_feed(array['00000000-0000-0000-0000-000000000010'::uuid])->'items') <> 1 then raise exception 'Missing verified'; end if;
 begin update public.university_news_revisions set title='overwrite'; raise exception 'Immutable evidence overwritten';
 exception when raise_exception then if SQLERRM='Immutable evidence overwritten' then raise; end if; end;
end;$$;
insert into public.university_news_revisions(series_key,revision,university_id,academic_year,scope,kind,event_type,title,precision,source_host,source_title,source_url,source_sha256,source_archive_key,source_locator,verified_at,updated_at,expires_at,status)
values('00000000-0000-0000-0000-000000000020',2,'00000000-0000-0000-0000-000000000010',2027,'university','schedule','final_result','SYNTHETIC RETRACTED','unknown','admission.example.edu','SYNTHETIC','https://admission.example.edu/notice',repeat('b',64),'synthetic-only','p2',now(),now(),now()+interval '1 day','withdrawn');
set local role authenticated;
do $$begin
 if public.university_news_feed(array['00000000-0000-0000-0000-000000000010'::uuid])->'items' <> '[]'::jsonb then raise exception 'Withdrawal resurrected older schedule'; end if;
 begin insert into public.university_news_revisions default values; raise exception 'Client news mutation allowed';
 exception when insufficient_privilege then null; end;
end;$$;
reset role;
delete from auth.users where id='00000000-0000-0000-0000-000000000001';
do $$begin if exists(select 1 from public.home_configuration_revisions) then raise exception 'Account deletion failed to cascade'; end if; end;$$;
rollback;
select 'PASS: isolation, CAS, retry, immutable revisions, withdrawal, grants, deletion' as result;
