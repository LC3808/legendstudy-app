-- Disable both candidate policies; retain Registry, Ledger, runs and every revision.
-- Set Pages/Worker execution flags OFF before rollback. No external calls.
begin;
do $rollback$
declare e constant uuid:='345d3caa-3438-58c3-8f80-62a6242179ec';r essay_material_private.reviews;p jsonb;rights jsonb;b jsonb;h text;pol jsonb;
begin
 pol=essay_exam_private.runtime_policy(e);
 if pol is null or essay_private.provider_policy(pol->>'regime')->>'policy_version' is distinct from 'hanyang-2024-afternoon2-pilot-v1'
 then raise exception 'DIFFERENT_POLICY';end if;
 select * into r from essay_material_private.reviews where exam_id=e for update;
 if r.revision<>17 or r.body->'package'->>'package_digest' is distinct from pol->>'package_digest'
 then raise exception 'LATER_REVIEW_REQUIRES_MANUAL_ROLLBACK';end if;
 rights=r.body->'rights';
 for h in select jsonb_array_elements_text(r.body->'documents') loop
  rights=jsonb_set(rights,array[h,'providerTransmission'],'"REVOKED"'::jsonb);
 end loop;
 p=((r.body->'package')-'package_digest')||jsonb_build_object('rights_status',rights,'package_version',18);
 p=p||jsonb_build_object('package_digest',encode(sha256(convert_to(p::text,'UTF8')),'hex'));
 b=jsonb_set(jsonb_set(r.body,'{rights}',rights),'{package}',p);
 insert into essay_material_private.revisions(exam_id,revision,state,body,reviewer) values(e,18,r.state,b,r.reviewer);
 update essay_material_private.reviews set revision=18,body=b,updated_at=now() where exam_id=e;
end $rollback$;
create or replace function essay_private.provider_policy(p_regime text) returns jsonb language sql immutable set search_path='' as $$select null::jsonb$$;
create or replace function essay_exam_private.runtime_policy(p_exam uuid) returns jsonb language sql stable set search_path='' as $$select null::jsonb$$;
commit;
