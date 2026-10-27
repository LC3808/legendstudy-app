begin;
do $$ begin if md5(pg_get_functiondef('public.essay_material_runtime_package(uuid,text)'::regprocedure))<>'52c6869ac3a7183254c9e5540033ff72' then raise exception 'READER_BASELINE_CHANGED';end if;end $$;
CREATE OR REPLACE FUNCTION public.essay_material_runtime_package(p_exam uuid, p_digest text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r essay_material_private.reviews; p jsonb; h text; q jsonb; current_body jsonb; historical essay_material_private.revisions;
begin
 select * into r from essay_material_private.reviews where exam_id=p_exam;
 current_body:=r.body;
 -- Preserve exact historical package digests for seven scoped exams. Latest approval and rights still apply.
 if p_exam in ('6679b5ff-d797-53c9-8a2a-424375d7210c'::uuid,'035e5d8d-e91f-5acd-a3a3-4d321bc9f067'::uuid,'d420ef29-218a-57fd-8524-842a0e551714'::uuid,'62dab8a7-9fe6-5ab3-aaa1-7db5cfd870aa'::uuid,'d53da73c-e631-5a8a-b4b5-04f1511115cd'::uuid,'0d4fcaa4-2be0-52a0-9590-c61f65c5f199'::uuid,'6ee238ff-0fc8-5731-b39a-ea546e153d9a'::uuid)
 and r.body->'package'->>'package_digest' is distinct from p_digest then
  if r.state is distinct from 'NEEDS_REVIEW'
   or r.body->'runtimeApproval'->>'status' is distinct from 'APPROVED'
   or r.body->'runtimeApproval'->>'revision' is distinct from r.revision::text
   or r.body->'package'->>'review_scope' is distinct from 'selected_questions'
   or (select jsonb_agg(x->'question_id' order by x->>'question_id') from jsonb_array_elements(r.body->'package'->'questions') x) is distinct from (select jsonb_agg(x order by x::text) from jsonb_array_elements(r.body->'runtimeApproval'->'question_ids') x)
   then raise exception 'REVIEWED_PACKAGE_UNAVAILABLE';end if;
  select * into historical from essay_material_private.revisions v
   where v.exam_id=p_exam and v.revision=(case p_exam when '62dab8a7-9fe6-5ab3-aaa1-7db5cfd870aa'::uuid then 3 when 'd53da73c-e631-5a8a-b4b5-04f1511115cd'::uuid then 2 when '0d4fcaa4-2be0-52a0-9590-c61f65c5f199'::uuid then 2 when '6ee238ff-0fc8-5731-b39a-ea546e153d9a'::uuid then 2 else 2 end)
   and v.body->'package'->>'package_digest'=p_digest
   and (case p_exam when '62dab8a7-9fe6-5ab3-aaa1-7db5cfd870aa'::uuid then p_digest='b717bcdbe5adad5388115aa04e52c1cdd6e5d3e5cea5f9eeb38a82961e171b49' when 'd53da73c-e631-5a8a-b4b5-04f1511115cd'::uuid then p_digest='16b28f5359c091f77059f6361426e4e9b295413c2d153f875343a728b82eaa39' when '0d4fcaa4-2be0-52a0-9590-c61f65c5f199'::uuid then p_digest='2b05d2d4e04ad1a39ae035feb21ac5dab8e764765e9043039e1da10d3f468fd7' when '6ee238ff-0fc8-5731-b39a-ea546e153d9a'::uuid then p_digest='6645abf8949ed3fd3724fd29cb20ae05639b691e4e5ebcbd02c952103b968044' else true end)
   and v.body->'runtimeApproval'->>'status'='APPROVED'
   and v.body->'runtimeApproval'->>'revision'=v.revision::text;
  if historical.exam_id is null then raise exception 'REVIEWED_PACKAGE_UNAVAILABLE';end if;
  r.body:=historical.body;r.revision:=historical.revision;r.state:=historical.state;
 end if;
 p:=r.body->'package';
 if not coalesce(((r.state='VERIFIED' and coalesce(r.approval_requested,false)) or
 (r.state='NEEDS_REVIEW' and r.body->'runtimeApproval'->>'status'='APPROVED'
 and r.body->'runtimeApproval'->>'revision'=r.revision::text
 and p->>'review_scope'='selected_questions'
 and (select jsonb_agg(x->'question_id' order by x->>'question_id') from jsonb_array_elements(p->'questions') x)
 = (select jsonb_agg(x order by x::text) from jsonb_array_elements(r.body->'runtimeApproval'->'question_ids') x))),false)
 or p is null or p->>'exam_id' is distinct from p_exam::text
 or jsonb_typeof(p->'questions') is distinct from 'array' or jsonb_array_length(p->'questions')=0
 or p->>'verification_status' is distinct from 'VERIFIED_MANIFEST'
 or p_digest is null or p->>'package_digest' is distinct from p_digest
 or p_digest is distinct from encode(sha256(convert_to((p-'package_digest')::text,'UTF8')),'hex')
 then raise exception 'REVIEWED_PACKAGE_UNAVAILABLE';end if;
 for h in select distinct m->>'sourceHash' from jsonb_array_elements(p->'questions') x cross join lateral jsonb_array_elements(x->'source_page_references') m loop
  if not (current_body->'documents' ? h) or current_body->'package'->'rights_status'->h->>'providerTransmission' is distinct from 'APPROVED' or not (r.body->'documents' ? h) or p->'rights_status'->h->>'providerTransmission' is distinct from 'APPROVED'
  then raise exception 'PROVIDER_RIGHTS_REQUIRED';end if;
 end loop;
 for q in select * from jsonb_array_elements(p->'questions') loop
  if not exists(select 1 from public.essay_questions x where x.id=(q->>'question_id')::uuid and x.essay_exam_id=p_exam and x.question_key=q->>'source_key')
  or not exists(select 1 from jsonb_array_elements(q->'source_page_references') m where m->>'role'='question' and m->>'verification'='VERIFIED' and length(btrim(m->>'evidenceText'))>0)
  or exists(select 1 from jsonb_array_elements(q->'source_page_references') m where m->>'questionId' is distinct from q->>'question_id' or m->>'verification' is distinct from 'VERIFIED')
  then raise exception 'QUESTION_CONTENT_INVALID';end if;
 end loop;
 return p;
end$function$
;
commit;
