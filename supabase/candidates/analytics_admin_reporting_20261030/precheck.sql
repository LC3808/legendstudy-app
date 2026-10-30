-- Run BEFORE apply.sql. Read-only. Fails loudly if a dependency is missing.
-- Wrap in a read-only transaction to guarantee no writes.
begin read only;

do $$
begin
  -- Operational admin gate (Owner-applied, outside committed migrations).
  if to_regprocedure('public.admin_operator()') is null then
    raise exception 'MISSING dependency: public.admin_operator()';
  end if;
  if to_regprocedure('account_private.allowed(uuid)') is null then
    raise exception 'MISSING dependency: account_private.allowed(uuid)';
  end if;
  -- Required tables.
  perform 1 from information_schema.tables where table_schema='public' and table_name in (
    'profiles','universities','essay_exams','essay_questions','essay_practice_sessions',
    'essay_attempts','essay_evaluations','essay_ai_processing_runs','credit_accounts',
    'credit_grants','credit_transactions','essay_billing_decisions','payment_orders','payment_operations'
  ) having count(*)=14;
  if not found then
    raise exception 'MISSING one or more required public tables';
  end if;
  -- Columns the functions depend on (spot checks).
  perform 1 from information_schema.columns where table_schema='public' and table_name='essay_evaluations' and column_name in ('request_kind','status','completed_at','requested_at','error_code') having count(*)=5;
  if not found then raise exception 'essay_evaluations columns changed'; end if;
  perform 1 from information_schema.columns where table_schema='public' and table_name='essay_ai_processing_runs' and column_name in ('run_no','latency_ms','cost_amount','cost_basis','total_tokens','input_tokens','output_tokens','provider','model_name') having count(*)=9;
  if not found then raise exception 'essay_ai_processing_runs columns changed'; end if;
  perform 1 from information_schema.columns where table_schema='public' and table_name='payment_orders' and column_name in ('state','mode','sku','amount','paid_at','subject_id') having count(*)=6;
  if not found then raise exception 'payment_orders columns changed'; end if;
  raise notice 'precheck OK';
end $$;

rollback;
