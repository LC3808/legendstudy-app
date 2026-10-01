-- OWNER ONLY, NOT EXECUTED. Replace BOTH placeholders after private auth.users verification.
-- Neither email/domain nor client-provided profile data can enroll an operator.
-- Run on the confirmed LegendStudy project only AFTER the exact migration is verified.
-- Registration is a privileged write; retain this approved operation's execution record.
begin;
set local lock_timeout='5s';
set local statement_timeout='15s';
select set_config('ql_registration.operator_uuid','REPLACE_WITH_CONFIRMED_OPERATOR_UUID',true),
       set_config('ql_registration.student_uuid','REPLACE_WITH_CONFIRMED_NORMAL_STUDENT_UUID',true);
do $$
declare op uuid := current_setting('ql_registration.operator_uuid')::uuid;
        student uuid := current_setting('ql_registration.student_uuid')::uuid;
begin
 if op=student or not exists(select 1 from auth.users where id=op)
  or not exists(select 1 from auth.users where id=student)
  or exists(select 1 from public.quality_operators where user_id=student) then
  raise exception 'Distinct confirmed operator and normal auth user required';
 end if;
 insert into public.quality_operators(user_id) values(op);
end$$;
-- Simulate trusted server request context for a SQL authorization assertion, NOT JWT verification.
select set_config('request.jwt.claim.sub',current_setting('ql_registration.operator_uuid'),true),
 set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('ql_registration.operator_uuid'),
 'role','authenticated','exp',extract(epoch from now())+300)::text,true);
set local role authenticated;
do $$begin
 if not public.is_quality_operator() then raise exception 'Operator verification failed'; end if;
 perform public.ql_list_cases(1);
end$$;
select set_config('request.jwt.claim.sub',current_setting('ql_registration.student_uuid'),true),
 set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('ql_registration.student_uuid'),
 'role','authenticated','exp',extract(epoch from now())+300)::text,true);
do $$begin
 if public.is_quality_operator() then raise exception 'Normal user unexpectedly allowed'; end if;
 begin
  perform public.ql_list_cases(1);
  raise exception 'Normal user unexpectedly allowed';
 exception when insufficient_privilege then null;
 end;
end$$;
reset role;
commit;
-- Separately verify via real authenticated gateway sessions after application.
-- Do not copy JWTs, answers or account identifiers into Wiki or Git.
