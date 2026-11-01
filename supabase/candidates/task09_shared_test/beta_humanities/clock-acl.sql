begin;
do $$begin
 if current_user <> 'postgres' or (select pg_get_functiondef('essay_private.clock()'::regprocedure)) not like '%select pg_catalog.clock_timestamp()%'
 then raise exception 'TEST_CLOCK_BASELINE_REVIEW_REQUIRED'; end if;
end $$;
grant essay_executor to postgres with admin false, inherit false, set true;
set local role essay_executor;
grant execute on function essay_private.clock() to postgres;
reset role;
revoke essay_executor from postgres;
commit;
