-- Owner approval required. Read projection only: no ledger writes or billing RPC changes.
begin;
-- Verify the approved read-function baseline; stop on drift before any DDL.
do $$ begin
 if md5(pg_get_functiondef('public.admin_member_credit(uuid,integer,integer)'::regprocedure)) <> '5d23c4ab6c7f94f764175cce6187b7e1' then
  raise exception 'MEMBER_READ_BASELINE_DRIFT';
 end if;
 if to_regprocedure('public.admin_credit_report(jsonb)') is not null then raise exception 'REPORT_ALREADY_EXISTS';end if;
end $$;
create or replace function essay_private.credit_display_kind(p_origin text,p_reason text,p_beta boolean default false)
returns text language plpgsql immutable set search_path='' as $$
declare audit jsonb;
begin
 if p_origin='promotion' and (p_beta or p_reason='essay_beta_daily') then return 'beta'; end if;
 if p_origin='admin_grant' and left(ltrim(coalesce(p_reason,'')),1)='{' then
  begin audit:=p_reason::jsonb; exception when invalid_text_representation then audit:=null; end;
  if audit->>'operation'='admin_grant_v2' and audit->>'kind'='other' then return 'other'; end if;
 end if;
 return case p_origin when 'signup_bonus' then 'signup' when 'promotion' then 'event'
 when 'admin_grant' then 'admin' when 'purchase' then 'purchase' when 'compensation' then 'compensation'
 when 'b2b_program' then 'school' else 'other' end;
end $$;
create or replace function essay_private.credit_display_action(p_type text,p_reason text,p_balance integer)
returns text language sql immutable set search_path='' as $$
 select case
 when p_type in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program') then 'grant'
 when p_type='reserve' then 'reserve' when p_type='consume' then 'consume' when p_type='release' then 'release'
 when p_type='expiration' then 'expiration'
 when p_type='refund' and p_balance>0 then 'restore'
 when p_type='adjustment' and p_reason in ('iap_refund_reversal_apple','iap_refund_reversal_google') and p_balance>0 then 'restore'
 when p_type='adjustment' and p_reason in ('purchase_cancel_v1','iap_refund_apple','iap_refund_google') and p_balance<0 then 'refund_adjustment'
 else 'adjustment' end
$$;
create or replace function essay_private.credit_display_grant(p_grant uuid)
returns text language sql stable set search_path='' as $$
 select essay_private.credit_display_kind(g.origin,
  (select t.reason_code from public.credit_transactions t where t.grant_id=g.id and t.transaction_type=g.origin and t.balance_delta>0 order by t.created_at,t.id limit 1),
  exists(select 1 from essay_beta_private.daily_grants b where b.grant_id=g.id))
 from public.credit_grants g where g.id=p_grant
$$;
create or replace function public.admin_credit_report(p jsonb)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare start_at timestamptz;end_at timestamptz;lim integer;off integer;subject uuid;kind text;filter_action text;result jsonb;
begin
 if public.admin_operator() is not true then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED';end if;
 if jsonb_typeof(p) is distinct from 'object' or p-array['version','from','to','source','action','subject','limit','offset']<>'{}'::jsonb
 or p->>'version' is distinct from 'credit-report-v2' then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 start_at:=coalesce((p->>'from')::timestamptz,'-infinity');end_at:=coalesce((p->>'to')::timestamptz,'infinity');
 lim:=coalesce((p->>'limit')::integer,25);off:=coalesce((p->>'offset')::integer,0);subject:=(p->>'subject')::uuid;
 kind:=coalesce(p->>'source','all');filter_action:=coalesce(p->>'action','all');
 if start_at>=end_at or lim not between 1 and 50 or off not between 0 and 1000000
 or kind not in ('all','signup','beta','event','admin','purchase','compensation','school','other')
 or filter_action not in ('all','grant','reserve','consume','release','restore','expiration','refund_adjustment','adjustment')
 then raise sqlstate 'PT422' using message='INVALID_FILTER';end if;
 with ledger as materialized (
  select t.id,t.account_id,t.grant_id,t.decision_id,t.created_at,t.transaction_type,t.reason_code,t.reversal_of,nullif(split_part(coalesce(t.actor_reference,''),'/',1),'') actor_kind,
   t.balance_delta,t.reserved_delta,g.origin,g.expires_at,
   essay_private.credit_display_grant(g.id) source_kind,
   essay_private.credit_display_action(t.transaction_type,t.reason_code,t.balance_delta) action,
   sum(t.balance_delta) over(partition by t.grant_id order by t.created_at,t.id rows unbounded preceding) grant_balance_after,
   sum(t.reserved_delta) over(partition by t.grant_id order by t.created_at,t.id rows unbounded preceding) grant_reserved_after
  from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id
  join public.credit_accounts a on a.id=t.account_id
  where subject is null or a.user_id=subject
 ), filtered as materialized (
  select l.*,case when l.action in ('reserve','release') then abs(l.reserved_delta) else abs(l.balance_delta) end quantity
  from ledger l where l.created_at>=start_at and l.created_at<end_at
  and (kind='all' or l.source_kind=kind) and (filter_action='all' or l.action=filter_action)
 ), page as (
  select * from filtered order by created_at desc,id desc limit lim offset off
 ), details as (
  select page.*,d.status billing_status,d.evaluation_id,
   coalesce(er.id,mr.id) run_id,coalesce(er.exam_id,mr.exam_id) exam_id,
   coalesce(er.state,mr.state) run_state,e.exam_name
  from page left join public.essay_billing_decisions d on d.id=page.decision_id
  left join lateral(select r.id,r.exam_id,r.state from essay_exam_private.runs r where r.decision_id=page.decision_id order by r.id limit 1) er on true
  left join lateral(select r.id,r.exam_id,r.state from math_private.session_runs r where r.decision_id=page.decision_id order by r.id limit 1) mr on true
  left join public.essay_exams e on e.id=coalesce(er.exam_id,mr.exam_id)
 )
 select jsonb_build_object('version','credit-report-v2','as_of',statement_timestamp(),'limit',lim,'offset',off,
  'total',(select count(*) from filtered),'balance_delta',(select coalesce(sum(balance_delta),0) from filtered),
  'reserved_delta',(select coalesce(sum(reserved_delta),0) from filtered),
  'grant_total',(select coalesce(sum(balance_delta),0) from filtered where filtered.action='grant'),
  'consume_total',(select coalesce(-sum(balance_delta),0) from filtered where filtered.action='consume'),
  'grant_stats',coalesce((select jsonb_agg(to_jsonb(x) order by source_kind) from
   (select source_kind,count(*) records,sum(balance_delta) quantity from filtered where filtered.action='grant' group by source_kind)x),'[]'::jsonb),
  'action_stats',coalesce((select jsonb_agg(to_jsonb(x) order by action) from
   (select filtered.action,count(*) records,sum(quantity) quantity,sum(balance_delta) balance_delta,sum(reserved_delta) reserved_delta from filtered group by filtered.action)x),'[]'::jsonb),
  'rows',coalesce((select jsonb_agg(to_jsonb(details) order by created_at desc,id desc) from details),'[]'::jsonb)) into result;
 return result;
end $$;
revoke all on function essay_private.credit_display_kind(text,text,boolean),essay_private.credit_display_action(text,text,integer),essay_private.credit_display_grant(uuid) from public,anon,authenticated,service_role;
revoke all on function public.admin_credit_report(jsonb) from public,anon,service_role;
grant execute on function public.admin_credit_report(jsonb) to authenticated;
CREATE OR REPLACE FUNCTION public.admin_member_credit(p_account_id uuid, p_limit integer DEFAULT 25, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare lim integer; off integer; acct uuid; result jsonb; fenced uuid[] := array[]::uuid[];
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 -- Match credit_summary without requiring the optional payment subsystem.
 if to_regclass('public.payment_orders') is not null then
  execute $$select coalesce(array_agg(o.grant_id) filter (where o.grant_id is not null),array[]::uuid[]) from public.payment_orders o where o.state='CANCEL_PENDING'$$ into fenced;
 end if;
 if p_account_id is null then raise sqlstate 'PT422' using message='INVALID_ACCOUNT'; end if;
 if p_limit is null or p_limit<1 or p_limit>50 then raise sqlstate 'PT422' using message='INVALID_LIMIT'; end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise sqlstate 'PT422' using message='INVALID_OFFSET'; end if;
 lim := p_limit; off := p_offset;
 if not exists(select 1 from auth.users u where u.id=p_account_id) then raise sqlstate 'PT404' using message='MEMBER_NOT_FOUND'; end if;
 select c.id into acct from public.credit_accounts c where c.user_id=p_account_id;
 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'account_id',p_account_id,
  'summary',public.admin_credit_snapshot(acct),
  'page',jsonb_build_object(
   'limit',lim,'offset',off,
   'grants_total',(select count(*) from public.credit_grants gr where gr.account_id=acct),
   'transactions_total',(select count(*) from public.credit_transactions t where t.account_id=acct)
  ),
  'grants',coalesce((
   select jsonb_agg(jsonb_build_object(
    'grant_id',x.id,'origin',x.origin,'display_kind',essay_private.credit_display_grant(x.id),'created_at',x.created_at,'expires_at',x.expires_at,
    'granted',x.granted,'balance',x.balance,'reserved',x.reserved,'available',x.available,
    'expired',x.expired
   ) order by x.created_at desc,x.id)
   from (
    select gr.id,gr.origin,gr.created_at,gr.expires_at,
     coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved,
     coalesce(sum(t.balance_delta) filter (where t.balance_delta>0),0) granted,
     (gr.expires_at is not null and gr.expires_at<=statement_timestamp()) expired,
     case when (gr.expires_at is not null and gr.expires_at<=statement_timestamp()) or gr.id=any(fenced) then 0
      else greatest(0,coalesce(sum(t.balance_delta),0)-coalesce(sum(t.reserved_delta),0)) end available
    from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id
    where gr.account_id=acct group by gr.id
    order by gr.created_at desc,gr.id limit lim offset off
   ) x
  ),'[]'::jsonb),
  'transactions',coalesce((
   select jsonb_agg(jsonb_build_object(
    'transaction_id',t.id,'grant_id',t.grant_id,'transaction_type',t.transaction_type,
    'balance_delta',t.balance_delta,'reserved_delta',t.reserved_delta,
    'reason_code',t.reason_code,'actor_kind',nullif(split_part(coalesce(t.actor_reference,''),'/',1),''),
    'reversal_of',t.reversal_of,'created_at',t.created_at
   ) order by t.created_at desc,t.id)
   from (select * from public.credit_transactions t where t.account_id=acct order by t.created_at desc,t.id limit lim offset off) t
  ),'[]'::jsonb)
 ) into result;
 return result;
end$function$;

commit;
