"""Promotion clean-apply + read-only validation SQL tests; ONLY a new disposable UTF8 PG17 DB.
No Production access, no credentials output, no schema resets. Synthetic public evidence only.
"""
import os,json
from pathlib import Path
import psycopg
from psycopg import sql
from psycopg.conninfo import conninfo_to_dict
from pglast import parse_sql
from pglast.stream import RawStream
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
MIGRATIONS=['20260928000100_student_essay_product.sql','20260928000200_essay_entitlements.sql','20260928000300_essay_server_operations.sql']
def main():
 if os.environ.get('ESSAY_REVIEW_DISPOSABLE')!='YES':raise SystemExit('REFUSED: explicit disposable consent')
 dsn=os.environ['ESSAY_REVIEW_TEST_DSN'];cfg=conninfo_to_dict(dsn)
 if cfg.get('host') not in ('127.0.0.1','::1') or cfg.get('hostaddr',cfg.get('host')) not in ('127.0.0.1','::1') or cfg.get('service') or not cfg.get('dbname','').startswith('essay_review_'):raise SystemExit('REFUSED: dedicated numeric-loopback review DB')
 c=psycopg.connect(dsn,autocommit=True)
 assert c.info.server_version>=170000 and c.info.encoding=='utf-8'
 assert c.execute("select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','auth') and c.relkind in ('r','p','v','m')").fetchone()[0]==0,'REFUSED: populated DB'
 c.execute("""create schema auth;create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 do $$begin
 if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin;end if;
 if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin;end if;
 if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls;end if;
 end$$;grant usage on schema public,auth to anon,authenticated,service_role;
 grant execute on function auth.uid() to anon,authenticated,service_role;
 create schema supabase_migrations;create table supabase_migrations.schema_migrations(version text primary key);
 """)
 for name in ['20260912000100_initial_content_schema.sql','20260927000200_essay_lab_foundation.sql']:
  c.execute((ROOT/'supabase/migrations'/name).read_text());c.execute('insert into supabase_migrations.schema_migrations values(%s)',(name.split('_')[0],))
 # Existing canonical rows must survive promotion byte-for-byte; these are invented public fixtures.
 def uid(n):return f'20000000-0000-0000-0000-{n:012d}'
 def put(table,**values):c.execute(sql.SQL('insert into public.{} ({}) values ({})').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,values)),sql.SQL(',').join(sql.Placeholder() for _ in values)),list(values.values()))
 put('source_posts',id=uid(1),source='synthetic',external_post_id='promotion',url='https://example.edu/promotion',title='Synthetic')
 put('content_items',id=uid(2),source_post_id=uid(1),source_content_key='promotion',slug='promotion',content_type='university_essay',title='Synthetic',source_url='https://example.edu/promotion',is_active=True)
 put('resources',id=uid(3),content_item_id=uid(2),source_post_id=uid(1),source_resource_key='promotion',title='Synthetic',source_url='https://example.edu/promotion.pdf',is_active=True)
 put('universities',id=uid(4),slug='promotion',name='Synthetic',is_active=True)
 put('essay_exams',id=uid(5),university_id=uid(4),admission_year=2024,exam_key='promotion',exam_name='Synthetic',exam_kind='admission',provenance='official',verification_status='verified',verified_at='2026-01-01',official_source_url='https://example.edu/promotion',evidence_note='Synthetic',is_active=True)
 put('essay_exam_resources',essay_exam_id=uid(5),resource_id=uid(3),role='question',provenance='official',verification_status='verified',verified_at='2026-01-01',official_source_url='https://example.edu/promotion',source_locator='p1',evidence_note='Synthetic',is_active=True)
 def statements(name):
  result=[]
  for node in parse_sql((HERE/name).read_text()):
   cur=c.execute(RawStream()(node));result.append((tuple(x.name for x in cur.description),cur.fetchall()) if cur.description else ((),[]))
  return result
 def find(results,column):return next(rows for names,rows in results if column in names)
 before=statements('preflight.readonly.sql')
 assert all(row[1] for row in find(before,'name_available'))
 assert all(row[1] for row in find(before,'prerequisite_present'))
 assert all(row[2] for row in find(before,'function_name_available'))
 for name in MIGRATIONS:
  c.execute((ROOT/'supabase/migrations'/name).read_text());c.execute('insert into supabase_migrations.schema_migrations values(%s)',(name.split('_')[0],))
 after=statements('post_apply.readonly.sql')
 definitions=find(after,'definition_matches');assert all(row[2] for row in definitions),[(x[0],x[1]) for x in definitions if not x[2]]
 assert find(after,'all_19_present')==[(True,True)]
 assert all(x[2] for x in find(after,'additive_column_present'))
 assert all(x[1]==0 for x in find(after,'initial_count_should_be_zero'))
 assert all(x[2]==0 for x in find(after,'orphan_count'))
 assert find(before,'content_fingerprint')==find(after,'content_fingerprint')
 public={'essay_questions','essay_question_evidence','essay_evaluation_criteria'}
 for table,role,privilege,granted in find(after,'granted'):
  expected=role=='anon' and table in public and privilege=='SELECT' or role=='authenticated' and ((privilege=='SELECT' and table!='essay_ai_processing_runs') or (privilege in ('INSERT','UPDATE','DELETE') and table in ('essay_drafts','student_target_universities')))
  assert granted==expected,(table,role,privilege)
 client={'essay_open_session','essay_save_draft','essay_submit_attempt','essay_request_evaluation','essay_request_rewrite','essay_erase'}
 worker={'essay_claim','essay_timeout','essay_finalize_success','essay_finalize_failure','essay_reconcile'}
 for schema,name,args,owner,definer,config,role,allowed in find(after,'executable'):
  expected=schema=='public' and ((name in client and role=='authenticated') or (name in worker and role=='essay_worker') or (name=='essay_refund' and role=='essay_finance'))
  assert allowed==expected,(schema,name,role)
 assert find(after,'executor_public_create_must_be_false')==[(False,False)]
 assert find(after,'member_role')==[]
 collisions=statements('preflight.readonly.sql');assert all(not row[1] for row in find(collisions,'name_available'))
 print(json.dumps({'clean_promoted_apply':'PASS','read_only_preflight_executes':'PASS','read_only_post_apply_executes':'PASS','catalog_objects_matched':len(definitions),'new_tables':19,'additive_columns':4,'new_table_rows':0,'orphan_counts_zero':True,'existing_canonical_counts_and_fingerprints_preserved':True,'exact_table_grants_verified':True,'exact_function_grants_verified':True,'bootstrap_privileges_revoked':True,'post_apply_preflight_detects_collisions':True,'baseline':'Actual initial content + Essay foundation with local Auth/history fixtures; not a full app migration replay','production_connected':False},indent=2))
if __name__=='__main__':main()
