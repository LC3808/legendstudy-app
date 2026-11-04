-- Disable new writes/projections without deleting any saved judgement or History.
begin;
do $$ declare source text;begin
 source=pg_get_functiondef('math_private.coaching_before_task16l(jsonb)'::regprocedure);
 execute replace(source,'math_private.coaching_before_task16l(','public.math_coaching(');
 source=pg_get_functiondef('public.math_evaluation(jsonb)'::regprocedure);
 source=replace(source,'''evaluation_id'',''lease_token'',''output'',''learning_judgement''','''evaluation_id'',''lease_token'',''output''');
 source=replace(source,'math_private.finalize_with_learning((v->>''evaluation_id'')::uuid,(v->>''lease_token'')::uuid,v->''output'',v->''learning_judgement'')','public.math_finalize_evaluation((v->>''evaluation_id'')::uuid,(v->>''lease_token'')::uuid,v->''output'')');
 execute source;
 if to_regprocedure('math_private.mixed_coaching_before_task16l(jsonb)') is not null then
  source=pg_get_functiondef('math_private.mixed_coaching_before_task16l(jsonb)'::regprocedure);
  execute replace(source,'math_private.mixed_coaching_before_task16l(','public.essay_math_coaching(');
 end if;
end$$;
-- Retain column and private backup functions to preserve data and audit. Do not reapply
-- the migration after rollback without a new reviewed forward migration.
commit;
