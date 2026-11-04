-- Exact inverse only. Preserve solution identity and all historical references.
begin;
do $rollback$
declare definition text; patched text := $new$   -- Supplemental official material is NOT retroactively an evaluation authority pin.
   refs=refs||coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'origin',s.origin,'body',s.body,'relationship','SUPPLEMENTAL_AFTER_ASSESSMENT','source_locator','공식 문항카드 3쪽 · 예시답안','source_sha256',source_artifact.content_sha256)) from public.math_canonical_solutions s join public.math_source_artifacts source_artifact on source_artifact.id=s.source_id where s.id='b4ea4666-f2a7-5ff1-83a8-41498b86b044'::uuid and s.leaf_id=e.leaf_id and s.state='ACTIVE' and not exists(select 1 from public.math_considered_references r where r.evaluation_id=e.id and r.solution_id=s.id)),'[]'::jsonb);
   answer=answer||jsonb_build_object('full_solution',jsonb_build_object('steps',e.result->'steps','paths',e.result->'paths','references',refs,'generated_solution',e.result->'generated_solution'));$new$; original text := $old$   answer=answer||jsonb_build_object('full_solution',jsonb_build_object('steps',e.result->'steps','paths',e.result->'paths','references',refs,'generated_solution',e.result->'generated_solution'));$old$;
begin
 definition=pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure);
 if (length(definition)-length(replace(definition,patched,'')))/length(patched)<>1 then raise exception 'ROLLBACK_TARGET_CHANGED';end if;
 if md5(replace(definition,patched,original))<>'e05c492620a5e7120050fcd1e995691c' then raise exception 'ROLLBACK_BASELINE_CHANGED';end if;
 execute replace(definition,patched,original);
 update public.math_canonical_solutions set state='RETIRED' where id='b4ea4666-f2a7-5ff1-83a8-41498b86b044' and state='ACTIVE';
end $rollback$;
commit;
