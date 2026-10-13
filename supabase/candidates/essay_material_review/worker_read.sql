-- CANDIDATE ONLY. Requires Owner approval. No authentication membership grant.
-- Existing narrow Worker may read one exact current reviewed package; no writes.
begin;
create or replace function public.essay_material_runtime_package(p_exam uuid,p_digest text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r essay_material_private.reviews; p jsonb; h text; q jsonb;
begin
 select * into r from essay_material_private.reviews where exam_id=p_exam;
 p:=r.body->'package';
 if r.state is distinct from 'VERIFIED' or not coalesce(r.approval_requested,false)
 or p is null or p->>'exam_id' is distinct from p_exam::text
 or jsonb_typeof(p->'questions') is distinct from 'array' or jsonb_array_length(p->'questions')=0
 or p->>'verification_status' is distinct from 'VERIFIED_MANIFEST'
 or p_digest is null or p->>'package_digest' is distinct from p_digest
 or p_digest is distinct from encode(sha256(convert_to((p-'package_digest')::text,'UTF8')),'hex')
 then raise exception 'REVIEWED_PACKAGE_UNAVAILABLE';end if;
 for h in select jsonb_array_elements_text(r.body->'documents') loop
  if p->'rights_status'->h->>'providerTransmission' is distinct from 'APPROVED'
  then raise exception 'PROVIDER_RIGHTS_REQUIRED';end if;
 end loop;
 for q in select * from jsonb_array_elements(p->'questions') loop
  if not exists(select 1 from public.essay_questions x where x.id=(q->>'question_id')::uuid and x.essay_exam_id=p_exam and x.question_key=q->>'source_key')
  or not exists(select 1 from jsonb_array_elements(q->'source_page_references') m where m->>'role'='question' and m->>'verification'='VERIFIED' and length(btrim(m->>'evidenceText'))>0)
  then raise exception 'QUESTION_CONTENT_INVALID';end if;
 end loop;
 return p;
end$$;
revoke all on function public.essay_material_runtime_package(uuid,text) from public,anon,authenticated;
grant execute on function public.essay_material_runtime_package(uuid,text) to essay_worker;
commit;
