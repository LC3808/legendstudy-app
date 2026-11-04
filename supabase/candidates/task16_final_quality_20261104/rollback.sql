-- Exact inverse; no role/schema ACL changes. Preserve historical identities.
begin;
do $rollback$
declare definition text; patched text := $new$ answer=public.math_coaching_before_task16g(p_request);
 -- Supplemental official material; no modification of assessment authority pins.
 if p_request->>'action' in ('read','reveal') and answer->'result'->>'disclosed'='true' then
  answer=jsonb_set(answer,'{result,full_solution,references}',coalesce(answer#>'{result,full_solution,references}','[]'::jsonb)||coalesce((
   select jsonb_agg(jsonb_build_object('id',s.id,'origin',s.origin,'body',s.body,'relationship','SUPPLEMENTAL_AFTER_ASSESSMENT','source_locator','공식 문항카드 3쪽 · 예시답안','source_sha256',source_artifact.content_sha256))
   from public.math_evaluations e join public.math_canonical_solutions s on s.leaf_id=e.leaf_id
   join public.math_source_artifacts source_artifact on source_artifact.id=s.source_id
   where e.id=(p_request->'payload'->>'evaluation_id')::uuid
    and s.id='b4ea4666-f2a7-5ff1-83a8-41498b86b044'::uuid and s.state='ACTIVE'
    and not exists(select 1 from jsonb_array_elements(coalesce(answer#>'{result,full_solution,references}','[]'::jsonb)) r where r->>'id'=s.id::text)
  ),'[]'::jsonb));
 end if;$new$; original text := $old$ answer=public.math_coaching_before_task16g(p_request);$old$;
begin
 definition=pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure);
 if (length(definition)-length(replace(definition,patched,'')))/length(patched)<>1 then raise exception 'ROLLBACK_TARGET_CHANGED';end if;
 if md5(replace(definition,patched,original))<>'e05c492620a5e7120050fcd1e995691c' then raise exception 'ROLLBACK_BASELINE_CHANGED';end if;
 execute replace(definition,patched,original);
 update public.math_canonical_solutions set state='RETIRED' where id='b4ea4666-f2a7-5ff1-83a8-41498b86b044' and state='ACTIVE';
end $rollback$;
commit;
