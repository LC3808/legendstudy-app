import pathlib,re,hashlib,json
p=pathlib.Path(__file__).parent
base=(p.parent/'essay_beta_credit_runtime_20261027/allocators.sql').read_text()
before=base[base.index('CREATE OR REPLACE FUNCTION essay_exam_private.reserve'):].split('\n;\nreset role;')[0]+'\n'
# pg_get_functiondef preserves body and final newline, excluding the statement semicolon.
(p/'reserve-baseline.sql').write_text(before)
after=before.replace("  if g is null then raise exception 'INSUFFICIENT_CREDIT';end if;", """  -- Check after exact request replay, but before any reservation/Ledger write.
  -- Old clients cannot silently fall back once this account has received beta.
  if nullif(current_setting('legendstudy.confirmed_credit_grant',true),'') is null then
   if current_setting('legendstudy.credit_confirmation_required',true)='true' or exists(select 1 from essay_beta_private.daily_grants d join public.credit_accounts a on a.user_id=d.user_id where a.id=p_account)
   then raise sqlstate 'PT409' using message='CREDIT_SOURCE_CONFIRMATION_REQUIRED';end if;
  elsif g is distinct from nullif(current_setting('legendstudy.confirmed_credit_grant',true),'')::uuid then
   raise sqlstate 'PT409' using message='CREDIT_SOURCE_CHANGED';
  end if;
  if g is null then raise exception 'INSUFFICIENT_CREDIT';end if;""")
assert after!=before
# Preserve purchase cancellation fencing in both selection paths.
after=after.replace('(cg.expires_at is null or cg.expires_at>clock_timestamp()) and',"(cg.expires_at is null or cg.expires_at>clock_timestamp()) and\n   not exists(select 1 from public.payment_orders o where o.grant_id=cg.id and o.state='CANCEL_PENDING') and")
(p/'reserve.sql').write_text(after+';\n')
digest=hashlib.md5(before.encode()).hexdigest()
(p/'precheck.sql').write_text(f"select md5(pg_get_functiondef('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))='{digest}' as baseline_matches, not exists(select 1 from essay_beta_private.campaigns where enabled) as campaign_inactive, to_regprocedure('public.essay_exam_quote_source(uuid,uuid,uuid[],uuid,uuid)') is null as new_quote_absent;\n")
(p/'apply.sql').write_text("-- NOT APPLIED. Requires separate Owner approval.\nbegin;\nset local lock_timeout='5s';\ndo $$begin if md5(pg_get_functiondef('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))<>'"+digest+"' then raise exception 'BASELINE_CHANGED';end if;end$$;\n"+(p/'runtime.sql').read_text()+after+';\ncommit;\n')
(p/'postcheck.sql').write_text("select md5(pg_get_functiondef('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))='"+hashlib.md5(after.encode()).hexdigest()+"' as reserve_matches, not exists(select 1 from essay_beta_private.campaigns where enabled) as campaign_inactive, has_function_privilege('essay_worker','public.essay_exam_quote_source(uuid,uuid,uuid[],uuid,uuid)','EXECUTE') as worker_quote, not has_function_privilege('authenticated','public.essay_exam_submit_source(uuid,uuid,uuid,jsonb,uuid,uuid,uuid)','EXECUTE') as client_submit_blocked, not has_function_privilege('anon','public.essay_exam_quote_source(uuid,uuid,uuid[],uuid,uuid)','EXECUTE') as anon_quote_blocked;\n")
(p/'rollback.sql').write_text('-- Safe stop only: preserve source-consent guard and all reservations.\nbegin;update essay_beta_private.campaigns set enabled=false where enabled;commit;\n')
