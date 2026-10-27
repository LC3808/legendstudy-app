begin;
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
 -- Exact already-approved revision2 digest for SWU and two SKKU exams only. Latest approval and rights still apply.
 if p_exam in ('6679b5ff-d797-53c9-8a2a-424375d7210c'::uuid,'035e5d8d-e91f-5acd-a3a3-4d321bc9f067'::uuid,'d420ef29-218a-57fd-8524-842a0e551714'::uuid)
 and r.body->'package'->>'package_digest' is distinct from p_digest then
  if r.state is distinct from 'NEEDS_REVIEW'
   or r.body->'runtimeApproval'->>'status' is distinct from 'APPROVED'
   or r.body->'runtimeApproval'->>'revision' is distinct from r.revision::text
   or r.body->'package'->>'review_scope' is distinct from 'selected_questions'
   or (select jsonb_agg(x->'question_id' order by x->>'question_id') from jsonb_array_elements(r.body->'package'->'questions') x) is distinct from (select jsonb_agg(x order by x::text) from jsonb_array_elements(r.body->'runtimeApproval'->'question_ids') x)
   then raise exception 'REVIEWED_PACKAGE_UNAVAILABLE';end if;
  select * into historical from essay_material_private.revisions v
   where v.exam_id=p_exam and v.revision=2
   and v.body->'package'->>'package_digest'=p_digest
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
