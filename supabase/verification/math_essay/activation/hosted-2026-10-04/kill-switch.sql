begin;
set local statement_timeout='10s';
do $$begin
 begin
  insert into public.math_evaluations default values;
  raise exception 'KILL_SWITCH_FAILED';
 exception when sqlstate '55000' then
  if sqlerrm <> 'MATH_EVALUATIONS_PAUSED' then raise;end if;
 end;
end$$;
select 'PASS' as admission_before_constraints_and_billing,(select count(*) from public.math_evaluations) evaluations;
rollback;
