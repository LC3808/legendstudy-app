begin;set local lock_timeout='5s';set local statement_timeout='30s';
do $rollback$ declare definition text;p jsonb;old_pin text;begin
definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);
p:=essay_exam_private.runtime_policy('d420ef29-218a-57fd-8524-842a0e551714'::uuid);old_pin:='46fc6b755b2b86c998852902cb1d8940a2b1e9e096f1008596a727acdb5a511f';
if p->>'package_digest'<>old_pin then
if p->>'package_digest' is distinct from (select body->'package'->>'package_digest' from essay_material_private.reviews where exam_id='d420ef29-218a-57fd-8524-842a0e551714' and revision=3) then raise exception 'SKKU_ROLLBACK_SCOPE_CHANGED';end if;
definition:=replace(definition,p->>'package_digest',old_pin);end if;
p:=essay_exam_private.runtime_policy('035e5d8d-e91f-5acd-a3a3-4d321bc9f067'::uuid);old_pin:='90c515fbca16a5989969ca3d6e3b6e95fb096215dbbfd2271838bcfd0a651b4a';
if p->>'package_digest'<>old_pin then
if p->>'package_digest' is distinct from (select body->'package'->>'package_digest' from essay_material_private.reviews where exam_id='035e5d8d-e91f-5acd-a3a3-4d321bc9f067' and revision=3) then raise exception 'SKKU_ROLLBACK_SCOPE_CHANGED';end if;
definition:=replace(definition,p->>'package_digest',old_pin);end if;
execute definition;end $rollback$;commit;
