"""Generate approval-only psql scripts from reviewed data. Never executes SQL."""
import hashlib,json
from pathlib import Path
from build_task03b_candidate import R,D,read,write
O=R/'supabase/candidates/task03b_ready_20261111'
def q(v):return "'"+str(v).replace("'","''")+"'"
def main():
 O.mkdir(exist_ok=True);load=read(D/'load_data.json');registry=read(R/'data/mock_expansion/task03/registry_snapshot.json');live=read(D/'production_preflight.json')
 tables={'answer_key_versions':'keys','exam_questions':'questions','grade_cutoff_references':'refs'};payload=['-- Reviewed local data only. Generated; DO NOT apply without Owner approval.']
 for table,short in tables.items():
  rows=load[table];cols=','.join(rows[0]);data=json.dumps(rows,ensure_ascii=False,separators=(',',':'));assert '$task03b$' not in data
  payload += [f'create temporary table task03b_{short} (like public.{table} including defaults) on commit drop;',f'insert into task03b_{short}({cols}) select {cols} from jsonb_populate_recordset(null::public.{table},$task03b${data}$task03b$::jsonb);']
 flat=[dict(content_item_id=e['content_item_id'],academic_year=e['academic_year'],exam_month=e['exam_month'],exam_type=e['exam_type'],exam_subject_id=s['id'],subject_id=s['subject_id'],subject_code=s['code'],subject_label=s['label']) for e in registry for s in e['subjects']]
 payload+=['create temporary table task03b_registry(content_item_id uuid,academic_year int,exam_month int,exam_type text,exam_subject_id uuid,subject_id uuid,subject_code text,subject_label text) on commit drop;',"insert into task03b_registry select * from jsonb_populate_recordset(null::task03b_registry,$task03b$"+json.dumps(flat,ensure_ascii=False,separators=(',',':'))+"$task03b$::jsonb);"]
 (O/'payload.sql').write_text('\n'.join(payload)+'\n')
 # Before changing any function, require exact live definitions/ACL observed read-only.
 guards=["if current_setting('server_version_num')::int < 170000 then raise exception 'TASK03B_PG17_REQUIRED'; end if;"]
 for f in live['functions']+live['account_dependencies']:
  guards.append(f"if md5(pg_get_functiondef(to_regprocedure({q(f['name'])}))) is distinct from {q(f['definition_md5'])} then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %',{q(f['name'])}; end if;")
  guards.append(f"if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure({q(f['name'])})) is distinct from {q(json.dumps(f['acl']))+'::jsonb' if f['acl'] is not None else 'null'} then raise exception 'TASK03B_LIVE_ACL_DRIFT: %',{q(f['name'])}; end if;")
 contract=read(D/'production_schema_contract.json')
 for c in contract['constraints']:
  guards.append(f"if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass({q('public.'+c['table'])}) and conname={q(c['name'])}) is distinct from {q(c['definition'])} then raise exception 'TASK03B_CONSTRAINT_DRIFT: %',{q(c['name'])}; end if;")
 for r in contract['rls']:
  guards.append(f"if not coalesce((select relrowsecurity from pg_class where oid=to_regclass({q('public.'+r['name'])})),false) then raise exception 'TASK03B_RLS_DISABLED: %',{q(r['name'])}; end if;")
 guard='do $guard$ begin\n'+'\n'.join(guards)+'\nend $guard$;\n'
 (O/'00_preflight.sql').write_text('-- READ ONLY. Re-run immediately before approval/application.\nbegin transaction read only;\n'+guard+"select current_setting('server_version'),now();\nselect 'answer_key_versions' as relation,count(*) from public.answer_key_versions union all select 'exam_questions',count(*) from public.exam_questions union all select 'mock_exam_attempts',count(*) from public.mock_exam_attempts union all select 'mock_exam_answers',count(*) from public.mock_exam_answers union all select 'grade_cutoff_versions',count(*) from public.grade_cutoff_versions union all select 'grade_cutoff_references',count(*) from public.grade_cutoff_references;\nrollback;\n")
 engine=(R/'supabase/candidates/task03_scoring_v2/candidate.sql').read_text();assert engine.count('begin;')==1
 source_engine=engine
 # Preserve the real production account lifecycle guard exactly. This does not change Auth.
 old_guard="if owner_id is null then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;"
 new_guard="perform account_private.lock_subject(owner_id); if not account_private.allowed(owner_id) then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;"
 contract=read(D/'production_schema_contract.json');live_submit=next(f['definition'] for f in contract['functions'] if f['name'].startswith('submit_mock_attempt('))
 assert new_guard in live_submit and engine.count(old_guard)==1
 engine=engine.replace(old_guard,new_guard)
 (O/'01_engine.sql').write_text(engine.replace('begin;','begin;\nset local lock_timeout=\'5s\';\n'+guard,1))
 registry_guard="""if exists(select 1 from task03b_registry r left join public.exam_subjects s on s.id=r.exam_subject_id left join public.exams e on e.content_item_id=r.content_item_id left join public.content_items c on c.id=e.content_item_id left join public.subjects subj on subj.id=s.subject_id where s.id is null or not s.is_active or not c.is_active or e.grade_level is distinct from 3 or (e.academic_year,e.exam_month,e.exam_type) is distinct from (r.academic_year,r.exam_month,r.exam_type) or (s.content_item_id,s.subject_id,s.raw_subject_label,subj.code) is distinct from (r.content_item_id,r.subject_id,r.subject_label,r.subject_code)) then raise exception 'TASK03B_REGISTRY_DRIFT'; end if;"""
 checks=[registry_guard]
 for table,short in tables.items():
  cols=[c for c in load[table][0] if c not in ('status','is_current')]
  match='r.id=s.id' if short!='questions' else 'r.answer_key_version_id=s.answer_key_version_id and r.question_number=s.question_number'
  diff=' or '.join(f'r.{c} is distinct from s.{c}' for c in cols)
  checks.append(f"if exists(select 1 from public.{table} r join task03b_{short} s on {match} where {diff}) then raise exception 'TASK03B_DATA_CONFLICT_{short}'; end if;")
 # Families may not be silently taken over, even if a different version exists.
 checks += ["if exists(select 1 from public.answer_key_versions r join task03b_keys s using(exam_subject_id,paper_variant) where r.id<>s.id) then raise exception 'TASK03B_KEY_FAMILY_CONFLICT'; end if;","if exists(select 1 from public.grade_cutoff_references r join task03b_refs s using(content_item_id,exam_subject_id,elective_key,grade) where r.id<>s.id) then raise exception 'TASK03B_CUTOFF_FAMILY_CONFLICT'; end if;"]
 (O/'check_staged.sql').write_text('do $check$ begin\n'+'\n'.join(checks)+'\nend $check$;\n')
 header="-- OWNER APPROVAL REQUIRED. psql -X -v ON_ERROR_STOP=1 -f <this-file>\nbegin;\nset local lock_timeout='5s';\nselect pg_advisory_xact_lock(20261111,3);\nlock table public.answer_key_versions,public.exam_questions,public.grade_cutoff_references in share row exclusive mode;\n\\ir payload.sql\n\\ir check_staged.sql\n"
 seed=[]
 for table,short in tables.items():
  cols=','.join(load[table][0]);pk='id' if short!='questions' else 'answer_key_version_id,question_number'
  match='r.id=s.id' if short!='questions' else 'r.answer_key_version_id=s.answer_key_version_id and r.question_number=s.question_number'
  # Do NOT use ON CONFLICT DO NOTHING: BEFORE INSERT question triggers touch published keys.
  seed.append(f'insert into public.{table}({cols}) select '+','.join('s.'+c for c in load[table][0])+f' from task03b_{short} s where not exists(select 1 from public.{table} r where {match});')
 (O/'02_seed_drafts.sql').write_text(header+'\n'.join(seed)+'\ncommit;\n')
 # Exact two-way set equality prevents publishing missing/extra questions.
 exact=[]
 for table,short in tables.items():
  cols=','.join('r.'+c for c in load[table][0] if c not in ('status','is_current'));sc=','.join('s.'+c for c in load[table][0] if c not in ('status','is_current'));join='r.id=s.id' if short!='questions' else 'r.answer_key_version_id in (select id from task03b_keys)'
  actual=f'select {cols} from public.{table} r '+(f'join task03b_{short} s on {join}' if short!='questions' else f'where {join}')
  expected=f'select {sc} from task03b_{short} s'
  exact.append(f"if exists(({expected} except {actual}) union all ({actual} except {expected})) then raise exception 'TASK03B_INCOMPLETE_{short}'; end if;")
 (O/'check_complete.sql').write_text('do $check$ begin\n'+'\n'.join(exact)+'\nend $check$;\n')
 publish="\\ir check_complete.sql\ndo $$ begin if exists(select 1 from public.answer_key_versions r join task03b_keys s using(id) where r.status='withdrawn') or exists(select 1 from public.grade_cutoff_references r join task03b_refs s using(id) where r.status='withdrawn') then raise exception 'TASK03B_WITHDRAWN_REQUIRES_NEW_REVIEW'; end if; end $$;\nupdate public.answer_key_versions r set status='published',is_current=true from task03b_keys s where r.id=s.id and (r.status,r.is_current) is distinct from ('published'::text,true);\nupdate public.grade_cutoff_references r set status='published',is_current=true from task03b_refs s where r.id=s.id and (r.status,r.is_current) is distinct from ('published'::text,true);\ncommit;\n"
 (O/'03_publish.sql').write_text(header+publish)
 (O/'04_validate.sql').write_text("-- READ ONLY: only temporary staging writes, rolled back. No persistent data changes.\nbegin;\n\\ir payload.sql\n\\ir check_staged.sql\n\\ir check_complete.sql\nselect count(*) as published_ready_keys from public.answer_key_versions r join task03b_keys s using(id) where r.status='published' and r.is_current and r.verification_status='READY';\nselect count(*) as published_reference_rows from public.grade_cutoff_references r join task03b_refs s using(id) where r.status='published' and r.is_current;\nselect relname,relrowsecurity from pg_class where oid in ('public.mock_exam_attempts'::regclass,'public.mock_exam_answers'::regclass,'public.grade_cutoff_references'::regclass);\nrollback;\n")
 # Stop only this batch, preserving draft keys, all published questions, attempts and evidence.
 (O/'05_rollback_visibility.sql').write_text(header.replace('\\ir check_staged.sql\n','')+"\\ir check_complete.sql\nupdate public.answer_key_versions r set is_current=false,status=case when r.status='published' then 'withdrawn' else r.status end from task03b_keys s where r.id=s.id;\nupdate public.grade_cutoff_references r set is_current=false,status=case when r.status='published' then 'withdrawn' else r.status end from task03b_refs s where r.id=s.id;\ncommit;\n")
 write(D/'sql_manifest.json',dict(engine_source_sha256=hashlib.sha256(source_engine.encode()).hexdigest(),preserved_production_account_guard=True,counts={t:len(load[t]) for t in tables},files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(O.glob('*.sql'))}))
 print('Generated approval-only SQL',len(list(O.glob('*.sql'))))
if __name__=='__main__':main()
