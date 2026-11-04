-- CANDIDATE ONLY: Owner production approval required. Existing evaluations/credits untouched.
begin;
do $guard$
begin
 if md5(pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure))<>'e05c492620a5e7120050fcd1e995691c' then raise exception 'COACHING_DEFINITION_CHANGED';end if;
 if not exists(select 1 from public.math_source_artifacts s join public.math_subproblems l on l.problem_id=s.problem_id where s.id='b0c21a43-bbcb-5a22-995e-fd8283ba2080' and l.id='018b6b54-4815-504a-adb8-685faa204516' and s.provenance='OFFICIAL' and s.verification='HASH_VERIFIED' and s.content_sha256='05a33c9d47d91710ea1215b535b20036f054762d2b382c967e5b932103872522') then raise exception 'OFFICIAL_SOURCE_MISMATCH';end if;
end $guard$;
insert into public.math_canonical_solutions(id,leaf_id,source_id,logical_id,version,origin,state,body)
values('b4ea4666-f2a7-5ff1-83a8-41498b86b044','018b6b54-4815-504a-adb8-685faa204516','b0c21a43-bbcb-5a22-995e-fd8283ba2080','b4ea4666-f2a7-5ff1-83a8-41498b86b044',1,'OFFICIAL','ACTIVE',$body$(1-1) 접선과 삼각형의 넓이
점 \(P(t,f(t))\)에서 접선의 방정식은
\[y=f'(t)(x-t)+f(t)\]
이고, 접선과 x축의 교점은 \(A(t-f(t)/f'(t),0)\)이다.
\[f'(t)=\frac{3t^4-1}{t^2},\qquad t>\frac{1}{\sqrt[4]{3}}\]
이므로 \(f'(t)\ne0\)이다.
\[\frac{f(t)}{f'(t)}=\frac{(t^4+1)/t}{(3t^4-1)/t^2}=\frac{t(t^4+1)}{3t^4-1}\]
\[\overline{AB}=t-\left(t-\frac{t(t^4+1)}{3t^4-1}\right)=\frac{t(t^4+1)}{3t^4-1},\qquad \overline{PB}=f(t)=\frac{t^4+1}{t}\]
따라서
\[S(t)=\frac12\overline{AB}\,\overline{PB}=\frac12\frac{t(t^4+1)}{3t^4-1}\frac{t^4+1}{t}=\frac{(t^4+1)^2}{2(3t^4-1)}.\]

(1-2) 치환과 최솟값
\(u=t^4\)이라 하고
\[T(u)=S(t)=S(\sqrt[4]{u})=\frac{(u+1)^2}{2(3u-1)}\]
라 하자. \(t>1/\sqrt[4]{3}\)이므로 \(u>1/3\)이다.
\[T'(u)=\frac{(u+1)(3u-5)}{2(3u-1)^2}\]
\(u>1/3\)에서 \(u=5/3\)일 때 극값을 갖는다.
\(1/3<u<5/3\)에서는 \(T'(u)<0\)이므로 감소하고, \(u>5/3\)에서는 \(T'(u)>0\)이므로 증가한다.
따라서 \(T(u)\)는 \(u=5/3\)일 때 최솟값 \(8/9\)를 갖는다.
\[t>\frac1{\sqrt[4]{3}}\text{ 에서 }S(t)\text{의 최솟값은 }\frac89.\]$body$);
do $patch$
declare old_text text:=$old$   answer=answer||jsonb_build_object('full_solution',jsonb_build_object('steps',e.result->'steps','paths',e.result->'paths','references',refs,'generated_solution',e.result->'generated_solution'));$old$;new_text text:=$new$   -- Supplemental official material is NOT retroactively an evaluation authority pin.
   refs=refs||coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'origin',s.origin,'body',s.body,'relationship','SUPPLEMENTAL_AFTER_ASSESSMENT','source_locator','공식 문항카드 3쪽 · 예시답안','source_sha256',source_artifact.content_sha256)) from public.math_canonical_solutions s join public.math_source_artifacts source_artifact on source_artifact.id=s.source_id where s.id='b4ea4666-f2a7-5ff1-83a8-41498b86b044'::uuid and s.leaf_id=e.leaf_id and s.state='ACTIVE' and not exists(select 1 from public.math_considered_references r where r.evaluation_id=e.id and r.solution_id=s.id)),'[]'::jsonb);
   answer=answer||jsonb_build_object('full_solution',jsonb_build_object('steps',e.result->'steps','paths',e.result->'paths','references',refs,'generated_solution',e.result->'generated_solution'));$new$;definition text;
begin
 definition=pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure);
 if (length(definition)-length(replace(definition,old_text,'')))/length(old_text)<>1 then raise exception 'COACHING_PATCH_TARGET_MISMATCH';end if;
 execute replace(definition,old_text,new_text);
end $patch$;
commit;
