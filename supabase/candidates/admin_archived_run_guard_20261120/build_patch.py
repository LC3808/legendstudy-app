"""Build an exact-preimage-guarded RPC-only patch. Never connects to a database."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
records = json.loads((HERE / 'preimage.json').read_text())['functions']
original = {r['proname']: r['definition'] for r in records}
patched = original.copy()


def replace(name, before, after):
    assert patched[name].count(before) == 1, (name, before)
    patched[name] = patched[name].replace(before, after, 1)


hidden = "exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden)"
uncertain = "exists(select 1 from essay_exam_private.checkpoints c where c.run_id=p_run and (c.key='final' or c.state='pending' or c.payload->>'state'='reconciling'))"
replace('admin_essay_operations',
 "'live',(select jsonb_build_object('processing',count(*) filter(where state='reserved'),'retry_pending',count(*) filter(where state='reserved' and failed_questions>0)) from essay_ops_private.run_facts),",
 "'live',(select jsonb_build_object('processing',count(*) filter(where f.state='reserved' and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=f.evaluation_id and h.hidden)),'retry_pending',count(*) filter(where f.state='reserved' and f.failed_questions>0 and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=f.evaluation_id and h.hidden)),'archived',count(*) filter(where exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=f.evaluation_id and h.hidden))) from essay_ops_private.run_facts f),")

replace('admin_lab_run_capabilities',
 'ledger_count integer; live boolean; verified boolean; retry_reason text; delete_reason text;',
 'ledger_count integer; live boolean; verified boolean; retry_reason text; delete_reason text; archived boolean; archive_reason text;')
replace('admin_lab_run_capabilities',
 " if live then retry_reason='ACTIVE_LEASE';",
 f" archived={hidden};\n archive_reason=case when archived then 'ALREADY_ARCHIVED' when live then 'ACTIVE_LEASE' when r.state='reserved' and (r.dispatch_key is null or r.lease_token is null or {uncertain}) then 'RECONCILIATION_REQUIRED' end;\n if archived then retry_reason='RUN_ARCHIVED';\n elsif live then retry_reason='ACTIVE_LEASE';")
replace('admin_lab_run_capabilities',
 "'hidden',coalesce((select hidden from essay_ops_private.hidden_runs where run_id=p_run),false)",
 "'hidden',archived,'archive_allowed',archive_reason is null,'archive_reason',archive_reason,'restore_allowed',archived")

replace('admin_lab_manage_run',
 ' select * into prior from essay_ops_private.run_actions where id=p_key;',
 f" -- Archived retry intents cannot replay into a queue after an operator pauses the run.\n if p_action='retry' and {hidden} then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;\n select * into prior from essay_ops_private.run_actions where id=p_key;")

replace('admin_lab_set_run_hidden',
 'BEGIN\n PERFORM essay_ops_private.require_admin();',
 'DECLARE r essay_exam_private.runs; a uuid;\nBEGIN\n PERFORM essay_ops_private.require_admin();')
replace('admin_lab_set_run_hidden',
 " IF NOT EXISTS(SELECT 1 FROM essay_exam_private.runs WHERE id=p_run) THEN RAISE SQLSTATE 'PT404' USING MESSAGE='RUN_NOT_FOUND'; END IF;",
 f" -- Same account -> run lock order as claim/retry, including this legacy entry.\n SELECT account_id INTO a FROM essay_exam_private.runs WHERE id=p_run;\n PERFORM 1 FROM public.credit_accounts WHERE id=a FOR UPDATE;\n SELECT * INTO r FROM essay_exam_private.runs WHERE id=p_run FOR UPDATE;\n IF r.id IS NULL THEN RAISE SQLSTATE 'PT404' USING MESSAGE='RUN_NOT_FOUND'; END IF;\n IF p_hidden AND NOT {hidden} THEN\n  IF coalesce(r.lease_until>clock_timestamp(),false) OR EXISTS(SELECT 1 FROM essay_exam_private.retry_requests WHERE run_id=p_run AND lease_until>clock_timestamp()) THEN\n   RAISE SQLSTATE 'PT409' USING MESSAGE='ACTIVE_LEASE';\n  END IF;\n  IF r.state='reserved' AND (r.dispatch_key is null or r.lease_token is null or {uncertain}) THEN RAISE SQLSTATE 'PT409' USING MESSAGE='RECONCILIATION_REQUIRED';END IF;\n END IF;")

replace('essay_exam_claim',
 " if r.id is null or p_dispatch is null then raise sqlstate 'PT403';end if;",
 f" if r.id is null or p_dispatch is null then raise sqlstate 'PT403';end if;\n if {hidden} then return jsonb_build_object('state','archived','run_id',r.id,'dispatch_allowed',false);end if;")
replace('essay_exam_retry',
 " if r.id is null or p_key is null or p_exam is null or r.exam_id<>p_exam then raise sqlstate 'PT403';end if;",
 f" if r.id is null or p_key is null or p_exam is null or r.exam_id<>p_exam then raise sqlstate 'PT403';end if;\n if {hidden} then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;")

for name in ['essay_exam_checkpoint', 'essay_exam_session_checkpoint']:
    replace(name,
     " if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;",
     f" if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;\n -- Preserve reads and the original writer's late evidence; block new execution only.\n if p_action='begin' and {hidden} then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;")
replace('essay_exam_session_status',
 " retryable=r.state='reserved' and not exists",
 f" retryable=r.state='reserved' and not {hidden} and not exists")
replace('essay_exam_observation',
 "'retry_allowed',r.state='reserved' and not exists",
 f"'retry_allowed',r.state='reserved' and not {hidden} and not exists")

dispatch_guard = """CREATE FUNCTION public.essay_exam_dispatch_guard(p_subject uuid,p_run uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
declare r essay_exam_private.runs;
begin
 perform math_private.require_active(array[p_subject]);
 select x.* into r from essay_exam_private.runs x join public.credit_accounts a on a.id=x.account_id
  where x.id=p_run and a.user_id=p_subject;
 if r.id is null then raise sqlstate 'PT403';end if;
 return jsonb_build_object('run_id',r.id,'state',case when exists(
  select 1 from essay_ops_private.hidden_runs h where h.run_id=r.id and h.hidden) then 'archived' else r.state end);
end$$;
revoke all on function public.essay_exam_dispatch_guard(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_dispatch_guard(uuid,uuid) to essay_worker;
"""

def guard(records_to_check, *, new_guard_absent=False):
    entries = ',\n'.join("('public." + r['signature'].replace("'", "''") + "','" + r['md5'] + "')" for r in records_to_check)
    extra = " if to_regprocedure('public.essay_exam_dispatch_guard(uuid,uuid)') is not null then raise exception 'DISPATCH_GUARD_ALREADY_EXISTS';end if;\n" if new_guard_absent else ''
    return "do $$declare x record;begin\n for x in select * from (values\n" + entries + ") v(signature,expected_md5) loop\n  if md5(pg_get_functiondef(x.signature::regprocedure))<>x.expected_md5 then raise exception 'PREIMAGE_CHANGED: %',x.signature;end if;\n end loop;\n" + extra + 'end$$;\n'

header = "-- Owner-authorized RPC-only archive eligibility correction. No existing row mutations.\n-- Existing state/snapshot/checkpoints/billing/ledger and historical statistics remain unchanged.\n"
body = '\n'.join(patched[r['proname']].rstrip() + ';\n' for r in records)
(HERE / 'install.sql').write_text(header + 'begin;\n' + guard(records,new_guard_absent=True) + body + dispatch_guard + "notify pgrst,'reload schema';\ncommit;\n")
(HERE / 'preimage.sql').write_text('\n'.join(r['definition'].rstrip() + ';\n' for r in records))
# Exact postimage guards are filled by local PostgreSQL canonical pg_get_functiondef
# after installation. Source hashes remain reproducible without a running database.
manifest = [{'signature':r['signature'],'before_md5':r['md5'],'source_sha256':hashlib.sha256(patched[r['proname']].encode()).hexdigest()} for r in records]
(HERE / 'manifest.json').write_text(json.dumps({'functions':manifest,'new_rpc':'essay_exam_dispatch_guard(uuid,uuid)','install_sha256':hashlib.sha256((HERE/'install.sql').read_bytes()).hexdigest()},indent=2)+'\n')
print('Generated install/preimage/manifest; no database writes.')
