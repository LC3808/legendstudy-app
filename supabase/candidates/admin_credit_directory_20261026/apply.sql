-- APPLIED after Owner approval on 2026-10-26. DO NOT RE-RUN. No balances/ledger/order mutations.
begin;
create function public.admin_credit_member_list(
 p_query text default '',p_limit integer default 10,p_offset integer default 0,p_sort text default 'balance_desc'
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare q text:=btrim(coalesce(p_query,''));qid uuid;result jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then
  raise sqlstate '42501' using message='OPERATOR_REQUIRED';
 end if;
 if length(q)>254 or p_limit is null or p_limit not in (10,20,50)
 or p_offset is null or p_offset<0 or p_sort is null
 or p_sort not in ('balance_desc','balance_asc','granted_desc','used_desc','joined_desc') then
  raise sqlstate '22023' using message='INVALID_FILTER';
 end if;
 if q ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then qid:=q::uuid;end if;
 with members as materialized (
  select u.id account_id,u.email::text email,u.created_at,u.last_sign_in_at,a.id credit_account_id
  from auth.users u left join public.credit_accounts a on a.user_id=u.id
  where q='' or (qid is not null and u.id=qid) or
    (qid is null and strpos(lower(coalesce(u.email,'')),lower(q))>0)
 ), balances as materialized (
  select m.*,coalesce(public.admin_credit_snapshot(m.credit_account_id),
   '{"spendable":0,"reserved":0,"paid":0,"free":0,"other":0}'::jsonb) summary,
   (select max(g.created_at) from public.credit_grants g where g.account_id=m.credit_account_id) last_granted_at,
   (select max(t.created_at) from public.credit_transactions t where t.account_id=m.credit_account_id and t.transaction_type='consume') last_used_at
  from members m
 ), ranked as (
  select *,row_number() over(order by
   case when p_sort='balance_desc' then (summary->>'spendable')::bigint end desc nulls last,
   case when p_sort='balance_asc' then (summary->>'spendable')::bigint end asc nulls last,
   case when p_sort='granted_desc' then last_granted_at end desc nulls last,
   case when p_sort='used_desc' then last_used_at end desc nulls last,
   case when p_sort='joined_desc' then created_at end desc nulls last,
   account_id) ordinal from balances
 ), page as (select * from ranked order by ordinal limit p_limit offset p_offset)
 select jsonb_build_object('version','admin-credit-members-v1','as_of',statement_timestamp(),
  'total',(select count(*) from members),'limit',p_limit,'offset',p_offset,
  'items',coalesce((select jsonb_agg(jsonb_build_object(
   'account_id',account_id,'email',email,'summary',summary,
   'created_at',created_at,'last_sign_in_at',last_sign_in_at,
   'last_granted_at',last_granted_at,'last_used_at',last_used_at
  ) order by ordinal) from page),'[]'::jsonb)) into result;
 return result;
end $$;
alter function public.admin_credit_member_list(text,integer,integer,text) owner to postgres;
revoke all on function public.admin_credit_member_list(text,integer,integer,text) from public,anon,authenticated,service_role;
grant execute on function public.admin_credit_member_list(text,integer,integer,text) to authenticated;
commit;
