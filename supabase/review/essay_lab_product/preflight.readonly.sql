begin read only;
select jsonb_build_object(
 'tables',(select jsonb_agg(jsonb_build_object('name',c.relname,'kind',c.relkind,'rls',c.relrowsecurity) order by c.relname) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m')),
 'columns',(select jsonb_agg(jsonb_build_object('table',table_name,'column',column_name,'type',data_type,'nullable',is_nullable) order by table_name,ordinal_position) from information_schema.columns where table_schema='public' and table_name in ('profiles','universities','essay_exams','essay_exam_resources','study_sessions','mock_exam_attempts')),
 'constraints',(select jsonb_agg(jsonb_build_object('table',c.conrelid::regclass::text,'definition',pg_get_constraintdef(c.oid))) from pg_constraint c join pg_namespace n on n.oid=c.connamespace where n.nspname='public' and c.conrelid in ('public.profiles'::regclass,'public.universities'::regclass,'public.essay_exam_resources'::regclass,'public.essay_exams'::regclass)),
 'functions',(select jsonb_agg(jsonb_build_object('name',p.proname,'arguments',pg_get_function_identity_arguments(p.oid))) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
 'profile_policies',(select jsonb_agg(jsonb_build_object('name',policyname,'command',cmd,'roles',roles,'qual',qual,'check',with_check)) from pg_policies where schemaname='public' and tablename='profiles')
) as inventory;
rollback;
