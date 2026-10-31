-- Run is the billing evaluation unit; question checkpoint failures remain partial failures.
create view essay_beta_private.beta_run_facts as
select r.id evaluation_id,a.user_id,r.created_at,r.state,r.parent_id,
 d.campaign_id,d.grant_day,
 coalesce(tx.reserved,0) reserved,coalesce(tx.consumed,0) consumed,coalesce(tx.released,0) released,
 tx.recovered_at,
 case when tx.released>0 then case when tx.automatic_release=tx.released then 'automatic' else 'manual_check' end else null end recovery_method,
 coalesce(rr.generation,0) generation,
 coalesce(cp.failed_questions,0) failed_questions,
 cp.failure_codes,
 case when tx.released>0 and tx.released=tx.reserved then 'recovered'
 when tx.released>tx.reserved or (r.state='completed' and r.parent_id is null and coalesce(tx.consumed,0)<>1) then 'manual_check'
 when r.state='completed' then 'completed'
 when r.state='failed' and tx.reserved>coalesce(tx.released,0) then 'recovery_pending'
 when r.state='failed' or coalesce(cp.failed_questions,0)>0 then 'failed'
 else 'processing' end operation_status
from essay_exam_private.runs r
join public.credit_accounts a on a.id=r.account_id
left join essay_exam_private.runs parent on parent.id=r.parent_id
join lateral (
 select distinct dg.* from public.credit_transactions t join essay_beta_private.daily_grants dg on dg.grant_id=t.grant_id
 where t.decision_id=coalesce(parent.decision_id,r.decision_id) and t.transaction_type='reserve'
) d on true
left join lateral (
 select sum(reserved_delta) filter(where transaction_type='reserve') reserved,
 -sum(balance_delta) filter(where transaction_type='consume') consumed,
 -sum(reserved_delta) filter(where transaction_type='release') released,
 max(created_at) filter(where transaction_type='release') recovered_at,
 -sum(reserved_delta) filter(where transaction_type='release' and reason_code='essay_exam_finalization') automatic_release
 from public.credit_transactions where decision_id=r.decision_id and grant_id=d.grant_id
) tx on true
left join lateral (select * from essay_exam_private.retry_requests where run_id=r.id order by generation desc limit 1) rr on true
left join lateral (
 select count(*) filter(where c.payload->>'state'='failed') failed_questions,
 jsonb_agg(jsonb_build_object('question_id',ans.value->>'questionId','state',c.payload->>'state','diagnostics',(select jsonb_agg(jsonb_build_object('code',z.payload->>'code','stage',z.payload->>'stage','http_status',z.payload->>'http_status')) from essay_exam_private.checkpoints z where z.run_id=r.id and z.state='checkpoint' and z.key like 'q'||(ans.ordinality-1)||'-a'||coalesce(rr.attempts->>(ans.ordinality-1)::text,'0')||'-%' and z.payload->>'component' in ('execution_failure','validation_failure')))) filter(where c.payload->>'state'='failed') failure_codes
 from jsonb_array_elements(r.snapshot->'answers') with ordinality ans(value,ordinality)
 left join essay_exam_private.checkpoints c on c.run_id=r.id and c.key='q'||(ans.ordinality-1)||
 case when coalesce((rr.attempts->>(ans.ordinality-1)::text)::integer,0)=0 then '' else '-retry-'||(rr.attempts->>(ans.ordinality-1)::text) end
) cp on true;
revoke all on essay_beta_private.beta_run_facts from public,anon,authenticated,service_role;

create function public.admin_essay_beta_report(p_kind text,p_user uuid default null,p_from timestamptz default null,p_to timestamptz default null,p_sort text default 'recent',p_offset integer default 0) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; total bigint;
begin
 perform essay_beta_private.require_admin();
 if p_kind not in ('usage','failures','audit') or p_kind is null or p_sort not in ('recent','usage','failures') or p_sort is null or p_offset is null or p_offset<0 or p_offset>100000 or (p_from is not null and p_to is not null and p_from>=p_to) then raise exception 'INVALID_FILTER';end if;
 if p_kind='audit' then
  select count(*) into total from essay_beta_private.settings_audit where (p_user is null or actor=p_user) and (p_from is null or recorded_at>=p_from) and (p_to is null or recorded_at<p_to);
  select jsonb_agg(to_jsonb(x)) into result from (select * from essay_beta_private.settings_audit where (p_user is null or actor=p_user) and (p_from is null or recorded_at>=p_from) and (p_to is null or recorded_at<p_to) order by id desc limit 25 offset p_offset) x;
 elsif p_kind='failures' then
  select count(*) into total from essay_beta_private.beta_run_facts where (state='failed' or failed_questions>0 or released>0 or operation_status='manual_check') and (p_user is null or user_id=p_user) and (p_from is null or created_at>=p_from) and (p_to is null or created_at<p_to);
  select jsonb_agg(to_jsonb(x)) into result from (select * from essay_beta_private.beta_run_facts where (state='failed' or failed_questions>0 or released>0 or operation_status='manual_check') and (p_user is null or user_id=p_user) and (p_from is null or created_at>=p_from) and (p_to is null or created_at<p_to) order by created_at desc,evaluation_id limit 25 offset p_offset) x;
 else
  -- Period applies to evaluation events; today's figures always use the current KST day.
  select count(*) into total from auth.users u where (p_user is null or u.id=p_user);
  with stats as (
   select u.id user_id,max(f.created_at) latest_use,count(f.evaluation_id) filter(where parent_id is null) free_count,
   count(*) filter(where parent_id is not null) rewrite_count,
   count(*) filter(where state='completed') success_count,
   count(*) filter(where state='failed' or failed_questions>0) failure_count,
   count(*) filter(where released>0) recovery_count
   from auth.users u left join essay_beta_private.beta_run_facts f on f.user_id=u.id and (p_from is null or f.created_at>=p_from) and (p_to is null or f.created_at<p_to) where (p_user is null or u.id=p_user) group by u.id
  ), rows as (
   select s.*,u.created_at signup_at,
   coalesce(today.used,0) today_used,coalesce(today.remaining,(select case when essay_beta_private.operations_open(o.campaign_id) then case when essay_private.clock()>=o.limit_effective_at then o.next_daily_limit else o.daily_free_limit end else 0 end from essay_beta_private.operations_config o join essay_beta_private.campaigns c on c.id=o.campaign_id where c.enabled),0) today_remaining
   from stats s join auth.users u on u.id=s.user_id
   left join lateral (
    select greatest(0,coalesce(sum(t.reserved_delta-t.balance_delta) filter(where t.transaction_type in ('reserve','release','consume')),0)) used,
    case when essay_beta_private.operations_open(d.campaign_id) then greatest(0,coalesce(sum(t.balance_delta-t.reserved_delta),0)) else 0 end remaining
    from essay_beta_private.daily_grants d join public.credit_transactions t on t.grant_id=d.grant_id
    where d.user_id=s.user_id and d.grant_day=(essay_private.clock() at time zone 'Asia/Seoul')::date group by d.campaign_id
   ) today on true
   order by case when p_sort='usage' then free_count end desc nulls last,
    case when p_sort='failures' then failure_count end desc nulls last,latest_use desc nulls last,user_id
   limit 25 offset p_offset
  ) select jsonb_agg(to_jsonb(rows)) into result from rows;
 end if;
 return jsonb_build_object('rows',coalesce(result,'[]'),'total',total,'offset',p_offset,'page_size',25);
end $$;
revoke all on function essay_beta_private.operations(uuid),essay_beta_private.operations_open(uuid),essay_beta_private.require_admin(boolean) from public,anon,authenticated,service_role;
revoke all on function public.admin_essay_beta_config(),public.admin_essay_beta_save(uuid,integer,jsonb,text),public.admin_essay_beta_report(text,uuid,timestamptz,timestamptz,text,integer) from public,anon,service_role;
grant execute on function public.admin_essay_beta_config(),public.admin_essay_beta_save(uuid,integer,jsonb,text),public.admin_essay_beta_report(text,uuid,timestamptz,timestamptz,text,integer) to authenticated;
