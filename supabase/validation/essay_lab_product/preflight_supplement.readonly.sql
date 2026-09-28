begin read only;
select jsonb_build_object(
 'server_version',current_setting('server_version'),
 'extensions',(select jsonb_agg(jsonb_build_object('name',extname,'version',extversion)) from pg_extension),
 'parents',(select jsonb_agg(jsonb_build_object('name',c.relname,'rls',c.relrowsecurity,'pk',(select pg_get_constraintdef(k.oid) from pg_constraint k where k.conrelid=c.oid and k.contype='p'))) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in ('profiles','universities','resources','essay_exams','essay_exam_resources')),
 'orphan_exams',(select count(*) from public.essay_exams e left join public.universities u on u.id=e.university_id where u.id is null),
 'orphan_exam_resource_exam',(select count(*) from public.essay_exam_resources r left join public.essay_exams e on e.id=r.essay_exam_id where e.id is null),
 'orphan_exam_resource_resource',(select count(*) from public.essay_exam_resources e left join public.resources r on r.id=e.resource_id where r.id is null),
 'set_updated_at',to_regprocedure('public.set_updated_at()') is not null,
 'uuid_builtin',to_regprocedure('pg_catalog.gen_random_uuid()') is not null,
 'sha256_builtin',to_regprocedure('pg_catalog.sha256(bytea)') is not null,
 'similar_relations',(select jsonb_agg(c.relname) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v') and (c.relname like '%essay%' or c.relname like '%evaluation%' or c.relname like '%credit%')),
 'migration_schema',to_regnamespace('supabase_migrations') is not null,
 'counts',jsonb_build_object('universities',(select count(*) from public.universities),'essay_exams',(select count(*) from public.essay_exams),'essay_exam_resources',(select count(*) from public.essay_exam_resources))
) as supplement;
rollback;
