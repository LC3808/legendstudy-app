-- OWNER EXECUTES ONLY on stlhijzpjfgwwdgunlsd.
-- Reuses the unmodified 6-page problem-only original. Q1 opens physical page2.
-- Pages5-6 contain sibling QUESTIONS only, no answers; sibling evaluation remains disabled.
-- Adds one authenticated SELECT policy. No data, ID, Credit, History or runtime-policy writes.
begin;
do $guard$
declare checks jsonb;
begin
 select to_jsonb(v) into checks from (select
exists(select 1 from storage.buckets where id='essay-material-originals' and public=false) as private_bucket,
(select count(*)=1 from storage.objects where bucket_id='essay-material-originals' and name='582f370e73f3d4b96e374f0596e4ae204e6f79e750ca07ff2c752244826fd7eb.pdf' and metadata->>'size'='734653' and metadata->>'mimetype'='application/pdf') as exact_existing_pdf,
(select revision=2 and body->'package'->>'package_digest'='90c515fbca16a5989969ca3d6e3b6e95fb096215dbbfd2271838bcfd0a651b4a' and body->'runtimeApproval'->'question_ids'='["601d62cc-a067-542d-b053-71609074da20"]'::jsonb from essay_material_private.reviews where exam_id='035e5d8d-e91f-5acd-a3a3-4d321bc9f067') as q1_package_preserved,
(select md5(coalesce(string_agg(policyname||':'||roles::text||':'||cmd||':'||coalesce(qual,'')||':'||coalesce(with_check,''),E'\n' order by policyname),''))='40dd65e9fcb830dceb2d149c7b72ecd0' from pg_policies where schemaname='storage' and tablename='objects' and policyname<>'skku_2026_language1_problem_read') as other_storage_policies_preserved,
(select md5(string_agg(id::text,',' order by id))='74c42916a3fd430f5a457d0c684e288b' from public.essay_exams) as exam_ids_preserved,
(select md5(string_agg(id::text||':'||essay_exam_id::text,',' order by id))='91217f81744b8e72b03f611b959e602c' from public.essay_questions) as question_ids_preserved,
md5(pg_get_functiondef('essay_exam_submit(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))='bdef051e18631f299bd22af91e0ed19b' as submit_preserved,
(select md5(coalesce(string_agg(id::text||':'||essay_exam_private.runtime_policy(id)::text,E'\n' order by id),''))='543d49adb0bf3b317365a1d5de5eff21' from public.essay_exams) as all_runtime_policies_preserved,
not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='skku_2026_language1_problem_read') as new_policy_absent) v;
 if exists(select 1 from jsonb_each(checks) e where e.value is distinct from 'true'::jsonb)
 then raise exception 'SKKU_PDF_BASELINE_MISMATCH: %',checks; end if;
end $guard$;
create policy skku_2026_language1_problem_read on storage.objects
for select to authenticated
using ((select public.account_service_allowed())
  and bucket_id='essay-material-originals'
  and name='582f370e73f3d4b96e374f0596e4ae204e6f79e750ca07ff2c752244826fd7eb.pdf');
commit;
