#!/usr/bin/env python3
"""Reuse disposable PG17 coaching tests; candidate is adapted only to synthetic IDs.
No hosted DB connection, Provider, real student or billing write.
"""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
source=(R/'tool/test_task16f_coaching.py').read_text()
setup='''
 # Install the exact candidate against synthetic leaf/source IDs and local baseline hash.
 c.execute('alter function public.math_coaching(jsonb) rename to math_coaching_before_task16g')
 c.execute("create function public.math_coaching(p_request jsonb) returns jsonb language plpgsql security definer set search_path='' as $$ declare answer jsonb; begin answer=public.math_coaching_before_task16g(p_request); return answer;end $$")
 c.execute('revoke all on function public.math_coaching(jsonb) from public,anon,service_role; grant execute on function public.math_coaching(jsonb) to authenticated')
 c.execute('revoke create on schema public from math_executor')
 inner_hash=scalar("select md5(pg_get_functiondef('public.math_coaching_before_task16g(jsonb)'::regprocedure))")
 old_definition=scalar(\"select pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure)")
 local_hash=scalar("select md5(pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure))")
 target_leaf=str(scalar('select leaf_id from public.math_evaluations where id=%s',(eid,)))
 problem=str(scalar('select problem_id from public.math_subproblems where id=%s',(target_leaf,)))
 source_id=new()
 c.execute("insert into public.math_source_artifacts(id,problem_id,source_role,source_url,locator,provenance,verification,content_sha256) values(%s,%s,'SCORING','https://example.edu/synthetic','synthetic page3','OFFICIAL','HASH_VERIFIED',%s)",(source_id,problem,'05a33c9d47d91710ea1215b535b20036f054762d2b382c967e5b932103872522'))
 candidate_sql=(R/'supabase/candidates/task16_final_quality_20261104/20261104004833_task16_final_inha_official_solution.sql').read_text()
 candidate_sql=candidate_sql.replace('4bab7b41ef9e1f68b275d62ca4edd496',inner_hash).replace('e05c492620a5e7120050fcd1e995691c',local_hash).replace('018b6b54-4815-504a-adb8-685faa204516',target_leaf).replace('b0c21a43-bbcb-5a22-995e-fd8283ba2080',source_id)
 old_results=scalar('select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.math_evaluations e')
 old_pins=scalar('select md5(coalesce(jsonb_agg(to_jsonb(r) order by evaluation_id,solution_id)::text,\'[]\')) from public.math_considered_references r')
 with ns['psycopg'].connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  admin.execute(candidate_sql)
 ok('existing_evaluations_not_backfilled',old_results==scalar('select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.math_evaluations e'))
 ok('schema_create_stays_denied',not scalar("select has_schema_privilege('math_executor','public','CREATE')"))
 ok('inner_definition_unchanged',inner_hash==scalar("select md5(pg_get_functiondef('public.math_coaching_before_task16g(jsonb)'::regprocedure))"))
 ok('assessment_reference_pins_unchanged',old_pins==scalar('select md5(coalesce(jsonb_agg(to_jsonb(r) order by evaluation_id,solution_id)::text,\'[]\')) from public.math_considered_references r'))
'''
# Avoid quoting nested SQL literals in the injected source.
setup=setup.replace("scalar('select md5(coalesce(jsonb_agg(to_jsonb(r) order by evaluation_id,solution_id)::text,'[]')) from public.math_considered_references r')",'scalar("select md5(coalesce(jsonb_agg(to_jsonb(r) order by evaluation_id,solution_id)::text,\'[]\')) from public.math_considered_references r")')
source=source.replace(" before=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')",setup+"\n before=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')")
source=source.replace(" ok('disclosure_durable',", " ok('supplemental_official_after_reveal',any(r.get('relationship')=='SUPPLEMENTAL_AFTER_ASSESSMENT' and r.get('source_locator')=='공식 문항카드 3쪽 · 예시답안' for r in revealed['full_solution']['references']))\n ok('disclosure_durable',")
source=source.replace("  m.o.execute_as_production(c,admin,(candidate/'rollback.sql').read_text())", "  rollback_sql=(R/'supabase/candidates/task16_final_quality_20261104/rollback.sql').read_text().replace('e05c492620a5e7120050fcd1e995691c',local_hash)\n  admin.execute(rollback_sql)\n  ok('exact_rollback_restores_definition',scalar(\"select pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure)\")==old_definition)\n  ok('rollback_keeps_solution_identity',scalar(\"select state from public.math_canonical_solutions where id='b4ea4666-f2a7-5ff1-83a8-41498b86b044'\")==\"RETIRED\")\n  admin.execute('alter function public.math_coaching(jsonb) owner to math_executor') # fixture-only legacy teardown\n  m.o.execute_as_production(c,admin,(candidate/'rollback.sql').read_text())")
exec(compile(source,str(R/'tool/test_task16f_coaching.py'),'exec'),{'__file__':str(R/'tool/test_task16f_coaching.py'),'__name__':'__main__'})
