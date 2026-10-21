-- Read-only before AND after application. Never executes submission/Provider RPCs.
begin read only;
select now() as observed_at,
 (select count(*) from public.essay_exams) exams,
 (select count(*) from public.essay_questions) questions,
 (select count(*) from essay_material_private.documents) documents,
 (select count(*) from essay_material_private.reviews) reviews,
 (select count(*) from essay_exam_private.runs) runs;
select count(*) cohort_exams,
 sum((select count(*) from public.essay_questions q where q.essay_exam_id=r.exam_id)) cohort_questions,
 sum(jsonb_array_length(body->'mappings')) evidence_links
from essay_material_private.reviews r where state='NEEDS_REVIEW';
select count(distinct m->>'sourceHash') cohort_pdfs from essay_material_private.reviews r,
lateral jsonb_array_elements(body->'mappings') m where state='NEEDS_REVIEW';
select md5(string_agg(to_jsonb(p)::text,E'\n' order by schemaname,tablename,policyname)) policy_hash from pg_policies p;
select p.oid::regprocedure signature,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl,
 md5(pg_get_functiondef(p.oid)) definition_md5
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname in ('essay_browse_catalog','essay_exam_submit','essay_exam_submit_cycle','essay_exam_history'))
or (n.nspname='essay_exam_private' and p.proname in ('reserve','finish','confirmed_answers'))
or (n.nspname='math_private' and p.proname='essay_leaf_identity_guard');
select id,public from storage.buckets;
select conname,pg_get_constraintdef(oid),convalidated from pg_constraint
where conrelid='public.math_subproblems'::regclass;
select indexname,indexdef from pg_indexes where schemaname='public' and tablename='math_subproblems';
select tgname,pg_get_triggerdef(oid) from pg_trigger where tgrelid='public.math_subproblems'::regclass and not tgisinternal;
select version,name from supabase_migrations.schema_migrations where version in ('20261021071701','20261021071702');
commit;
