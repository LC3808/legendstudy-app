-- CANDIDATE: Owner approved material transmission; operating DB apply still needs approval.
-- No Provider, Credit, grants, student publication or execution flag changes.
begin;
do $install$
declare
 e constant uuid:='345d3caa-3438-58c3-8f80-62a6242179ec';
 old_digest constant text:='09b50772b37f69ec7544a752ba88f5cde6c8de555ab17339a13eb6ef4fdcf106';
 hashes constant jsonb:='["ced37494c6b65531cca30649093846dde665bf401e630e8751f0bc8a3be90060","4f3b87f2197a042c8abdd361584e3e03ab4bd4d15bc5341273dee27b7b6fc73b"]';
 r essay_material_private.reviews; b jsonb; p jsonb; rights jsonb; h text; binding jsonb; regime text; policy jsonb;
begin
 -- Never overwrite a later model/activation policy or a later Owner review.
 if btrim((select prosrc from pg_proc where oid='essay_exam_private.runtime_policy(uuid)'::regprocedure)) not in ('select null::jsonb','select null::jsonb;')
 or btrim((select prosrc from pg_proc where oid='essay_private.provider_policy(text)'::regprocedure)) not in ('select null::jsonb','select null::jsonb;')
 then raise exception 'POLICY_ALREADY_CONFIGURED';end if;
 select * into r from essay_material_private.reviews where exam_id=e for update;
 if r.revision is distinct from 16 or r.state is distinct from 'VERIFIED' or not r.approval_requested
 or r.body->'package'->>'package_digest' is distinct from old_digest
 or r.body->'documents' is distinct from hashes
 then raise exception 'REVIEW_VERSION_CHANGED';end if;
 p=r.body->'package';
 if encode(sha256(convert_to((p-'package_digest')::text,'UTF8')),'hex')<>old_digest then raise exception 'PACKAGE_HASH_MISMATCH';end if;
 if exists(select 1 from essay_exam_private.runs where exam_id=e) then raise exception 'EXISTING_RUN_REQUIRES_REVIEW';end if;
 rights=coalesce(nullif(r.body->'rights','null'::jsonb),'{}'::jsonb);
 for h in select jsonb_array_elements_text(hashes) loop
  rights=jsonb_set(rights,array[h],coalesce(rights->h,'{}'::jsonb)||jsonb_build_object(
   'providerTransmission','APPROVED','provider','openai','purpose','essay_evaluation_and_independent_review',
   'approvalReference','Owner explicit approval 2026-10-14; Hanyang 2024 admission humanities afternoon2 only'));
 end loop;
 b=jsonb_set(r.body,'{rights}',rights,true);
 p=(p-'package_digest')||jsonb_build_object('rights_status',rights,'package_version',17);
 p=p||jsonb_build_object('package_digest',encode(sha256(convert_to(p::text,'UTF8')),'hex'));
 b=jsonb_set(b,'{package}',p);
 -- Immutable revision16 remains; only rights/version/digest change in revision17.
 if (p-array['rights_status','package_version','package_digest']) is distinct from
    ((r.body->'package')-array['rights_status','package_version','package_digest']) then raise exception 'CONTENT_CHANGED';end if;
 insert into essay_material_private.revisions(exam_id,revision,state,body,reviewer)
 values(e,17,r.state,b,r.reviewer);
 update essay_material_private.reviews set revision=17,body=b,updated_at=now() where exam_id=e;
 binding=jsonb_build_object('policy_version','hanyang-2024-afternoon2-pilot-v1','provider','openai',
 'model','gpt-5.6-sol','model_version','gpt-5.6-sol','prompt_version','scaffolding-1.3-v3','contract_version','1.3');
 regime='essay-v1.3/policy/'||encode(sha256(convert_to(binding::text,'UTF8')),'hex');
 policy=jsonb_build_object('package_digest',p->>'package_digest','regime',regime,'evaluation_type','humanities');
 execute format('create or replace function essay_private.provider_policy(p_regime text) returns jsonb language sql immutable set search_path='''' as %L',
  format('select case when p_regime=%L then %L::jsonb else null::jsonb end',regime,binding::text));
 execute format('create or replace function essay_exam_private.runtime_policy(p_exam uuid) returns jsonb language sql stable set search_path='''' as %L',
  format('select case when p_exam=%L::uuid then %L::jsonb else null::jsonb end',e,policy::text));
 if not essay_private.provider_binding_valid(regime,binding) then raise exception 'POLICY_HASH_MISMATCH';end if;
end $install$;
commit;
