begin transaction read only;
set local statement_timeout='15s';
select jsonb_build_object(
 'versions',(select jsonb_agg(version order by version) from supabase_migrations.schema_migrations),
 'prerequisites',(select jsonb_agg(jsonb_build_object('signature',name,'present',to_regprocedure(name) is not null)) from unnest(array['essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)','essay_private.uid()','account_private.allowed(uuid)','account_private.lock_subject(uuid)']) name),
 'purchase_grants',(select count(*) from public.credit_grants where origin='purchase'),
 'credit_functions',(select jsonb_agg(p.oid::regprocedure::text order by p.oid::regprocedure::text) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private') and p.proname like '%credit%')
) as dependencies;
commit;
