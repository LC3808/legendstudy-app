from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4]; target=root/'supabase/candidates/task09_shared_test/beta_humanities';target.mkdir(exist_ok=True)
p=root/'supabase/candidates/essay_beta_credit_runtime_20261027'
sql=(p/'apply-with-temporary-role.sql').read_text()
# Remove ONLY absent math-session RPC guard and its exact definition block.
reg='public.math_session_submit(uuid,uuid,uuid[],uuid)'
sql='\n'.join(l for l in sql.split('\n') if not (l.startswith('if md5(') and reg in l))
start=sql.index('CREATE OR REPLACE FUNCTION public.math_session_submit(')
end=sql.index('\nreset role;',start)
sql=sql[:start]+sql[end:]
# Existing TEST math allocator must still exclude beta grants. Do not import its
# newer production implementation or create the absent session subsystem.
before=(target/'math-before.sql').read_text()
assert hashlib.md5(before.encode()).hexdigest()=='3a7a3e7a33636d6a01295dfad9734e04'
anchor='from public.credit_grants g where g.account_id=account';assert before.count(anchor)==1
after=before.replace(anchor,anchor+' and not essay_beta_private.is_beta(g.id)')
sql=sql.replace('0154a967dde40918213692e93cb4f5b0','3a7a3e7a33636d6a01295dfad9734e04')
start=sql.index('CREATE OR REPLACE FUNCTION math_private.authorize_billing(')
end=sql.index('\nreset role;',start)
sql=sql[:start]+after+';'+sql[end:]
# Explicit schema fail-closed guard (project target is enforced by the operator); no campaign or credit issuance.
guard="""do $$begin
 if to_regprocedure('public.math_session_submit(uuid,uuid,uuid[],uuid)') is not null then raise exception 'UNEXPECTED_MATH_SESSION_REVIEW_REQUIRED';end if;
 if to_regnamespace('essay_beta_private') is not null then raise exception 'BETA_ALREADY_PRESENT';end if;
end$$;
"""
sql=sql.replace("set local lock_timeout='5s';", "set local lock_timeout='5s';\n"+guard,1)
sql=sql.replace('\ncommit;', '\n-- Canonical ACL order required by the existing exact v2 precheck.\nrevoke execute on function public.essay_beta_daily_claim() from authenticated;\ngrant execute on function public.essay_beta_daily_claim() to authenticated;\ncommit;')
(target/'install.sql').write_text('-- TEST kpqbedylxlyntrrfybpn ONLY; verified allocator adaptation. Not a Production migration.\n'+sql)
(target/'manifest.json').write_text(json.dumps({'test_project':'kpqbedylxlyntrrfybpn','absent_dependency':reg,'math_allocator_before_md5':hashlib.md5(before.encode()).hexdigest(),'math_allocator_after_md5':hashlib.md5(after.encode()).hexdigest(),'policy':'Existing math allocator excludes beta; absent math session is not installed; campaigns remain inactive.'},indent=2)+'\n')
print(target)
