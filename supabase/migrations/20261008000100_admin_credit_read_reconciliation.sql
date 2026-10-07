-- Additive correction after the existing Admin candidates; their history is unchanged.
-- No Payment function/table, ledger, RLS, ownership or ACL is changed.
-- Mandatory hosted preflight: existing definitions must match the reviewed inputs.
begin;
do $preflight$
begin
 if to_regprocedure('public.admin_credit_snapshot(uuid)') is null
 or to_regprocedure('public.admin_dashboard()') is null
 or to_regprocedure('public.admin_member_credit(uuid,integer,integer)') is null
 or to_regprocedure('public.admin_inquiry_detail(jsonb)') is null then
  raise exception 'ADMIN_READ_PREREQUISITES_MISSING';
 end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.admin_credit_snapshot(uuid)') and md5(prosrc)='0d4385467aca7e99107d476cda87f0ed' and prosecdef and provolatile='s' and proconfig=array['search_path=""']) then raise exception 'ADMIN_AUTHORITY_MISMATCH: admin_credit_snapshot'; end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.admin_dashboard()') and md5(prosrc)='c8a3196e59d99f82743b40ad166919ed' and prosecdef and provolatile='s' and proconfig=array['search_path=""']) then raise exception 'ADMIN_AUTHORITY_MISMATCH: admin_dashboard'; end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.admin_member_credit(uuid,integer,integer)') and md5(prosrc)='6f746cdaba1c58bc014eeea4800334a7' and prosecdef and provolatile='s' and proconfig=array['search_path=""']) then raise exception 'ADMIN_AUTHORITY_MISMATCH: admin_member_credit'; end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.admin_inquiry_detail(jsonb)') and md5(prosrc)='6214069428442f10508cab8947614a2d' and prosecdef and provolatile='s' and proconfig=array['search_path=""']) then raise exception 'ADMIN_AUTHORITY_MISMATCH: admin_inquiry_detail'; end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.admin_member_detail(uuid)') and md5(prosrc)='8f451b3b327334b9f5694c01ffe17939' and prosecdef and provolatile='s' and proconfig=array['search_path=""']) then raise exception 'ADMIN_AUTHORITY_MISMATCH: admin_member_detail'; end if;
end $preflight$;
create or replace function public.admin_credit_snapshot(p_account_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $function$
declare result jsonb; fenced uuid[] := array[]::uuid[];
begin
 if p_account_id is null then return null; end if;
 -- Match credit_summary without requiring the optional payment subsystem.
 if to_regclass('public.payment_orders') is not null then
  execute $$select coalesce(array_agg(o.grant_id) filter (where o.grant_id is not null),array[]::uuid[]) from public.payment_orders o where o.state='CANCEL_PENDING'$$ into fenced;
 end if;
 with g as (
  select gr.id,gr.origin,gr.expires_at,
   coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved
  from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id
  where gr.account_id=p_account_id group by gr.id
 ), s as (
  select *,greatest(0,balance-reserved) available from g
  where (expires_at is null or expires_at>statement_timestamp()) and not (id=any(fenced))
 )
 select jsonb_build_object(
  'spendable',coalesce(sum(available),0),
  'paid',coalesce(sum(available) filter (where origin='purchase'),0),
  'free',coalesce(sum(available) filter (where origin='signup_bonus'),0),
  'other',coalesce(sum(available) filter (where origin not in ('purchase','signup_bonus')),0),
  'reserved',coalesce(sum(reserved),0),
  'next_expiry',min(expires_at) filter (where available>0)
 ) into result from s;
 return result;
end$function$;

create or replace function public.admin_dashboard() returns jsonb
language plpgsql stable security definer set search_path='' as $function$
declare result jsonb; fenced uuid[] := array[]::uuid[];
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 -- Match credit_summary without requiring the optional payment subsystem.
 if to_regclass('public.payment_orders') is not null then
  execute $$select coalesce(array_agg(o.grant_id) filter (where o.grant_id is not null),array[]::uuid[]) from public.payment_orders o where o.state='CANCEL_PENDING'$$ into fenced;
 end if;
 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'members',jsonb_build_object(
   'total',(select count(*) from public.profiles),
   'new_today',(select count(*) from public.profiles p where p.created_at>=date_trunc('day',statement_timestamp())),
   'new_7d',(select count(*) from public.profiles p where p.created_at>statement_timestamp()-interval '7 days'),
   'new_30d',(select count(*) from public.profiles p where p.created_at>statement_timestamp()-interval '30 days'),
   'active_30d',(select count(distinct s.user_id) from public.study_sessions s where s.started_at>statement_timestamp()-interval '30 days')
  ),
  'profile',jsonb_build_object(
   'grade_distribution',coalesce((select jsonb_agg(jsonb_build_object('key',g.k,'count',g.c) order by g.c desc,g.k) from (
     select coalesce(p.grade_level::text,'UNKNOWN') k,count(*) c from public.profiles p group by 1) g),'[]'::jsonb),
   'school_distribution',coalesce((select jsonb_agg(jsonb_build_object('school_code',s.code,'count',s.c) order by s.c desc,s.code) from (
     select p.neis_school_code code,count(*) c from public.profiles p where p.neis_school_code is not null group by 1 order by c desc,code limit 20) s),'[]'::jsonb),
   'school_code_note','school names are not stored; distribution is by NEIS school code only'
  ),
  'essay',jsonb_build_object(
   'submissions',(select count(*) from public.essay_attempts a where a.submitted_at is not null),
   'evaluation_requests',(select count(*) from public.essay_evaluations),
   'evaluation_completed',(select count(*) from public.essay_evaluations e where e.status='completed'),
   'evaluation_failed',(select count(*) from public.essay_evaluations e where e.status='failed'),
   'rewrites',(select count(*) from public.essay_attempts a where a.attempt_no>1),
   'reevaluations',(select count(*) from public.essay_evaluations e where e.supersedes_evaluation_id is not null)
  ),
  'math',jsonb_build_object(
   'installed',(to_regclass('public.math_attempts') is not null),
   'runtime_state','RUNTIME_OFF',
   'runtime_label','수리논술 평가 기능 비활성 (운영 준비 중)',
   'attempts',public.admin_count('public.math_attempts'),
   'evaluations',public.admin_count('public.math_evaluations')
  ),
  'credit',(
   with g as (
    select gr.id,gr.origin,gr.expires_at,
     coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved
    from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id group by gr.id
   ), s as (
    select *,greatest(0,balance-reserved) available from g
    where (expires_at is null or expires_at>statement_timestamp()) and not (id=any(fenced))
   )
   select jsonb_build_object(
    'spendable',coalesce(sum(available),0),
    'available_by_origin',jsonb_build_object(
     'signup_bonus',coalesce(sum(available) filter (where origin='signup_bonus'),0),
     'purchase',coalesce(sum(available) filter (where origin='purchase'),0),
     'promotion',coalesce(sum(available) filter (where origin='promotion'),0),
     'admin_grant',coalesce(sum(available) filter (where origin='admin_grant'),0),
     'compensation',coalesce(sum(available) filter (where origin='compensation'),0),
     'b2b_program',coalesce(sum(available) filter (where origin='b2b_program'),0),
     'other',coalesce(sum(available) filter (where origin not in ('signup_bonus','purchase','promotion','admin_grant','compensation','b2b_program')),0)
    ),
    'expiring_30d',coalesce(sum(available) filter (where expires_at is not null and expires_at<=statement_timestamp()+interval '30 days'),0),
    'granted_total',(select coalesce(sum(t.balance_delta),0) from public.credit_transactions t where t.balance_delta>0),
    'consumed_total',(select coalesce(-sum(t.balance_delta),0) from public.credit_transactions t where t.balance_delta<0)
   ) from s
  ),
  'payment',jsonb_build_object(
   'installed',(to_regclass('public.payment_orders') is not null),
   'runtime_state','LIVE_OFF',
   'runtime_label','결제 기능 미활성 (실결제 아님)',
   'orders',public.admin_count('public.payment_orders')
  )
 ) into result;
 return result;
end$function$;

create or replace function public.admin_member_credit(p_account_id uuid,p_limit integer default 25,p_offset integer default 0)
returns jsonb language plpgsql stable security definer set search_path='' as $function$
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
    'grant_id',x.id,'origin',x.origin,'created_at',x.created_at,'expires_at',x.expires_at,
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

create or replace function public.admin_inquiry_detail(p jsonb) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare target_id uuid; i public.inquiries; replies jsonb; events jsonb; member jsonb; related jsonb;
 essay_count bigint; order_count bigint;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','id']<>'{}'::jsonb
  or p->>'dto_version' is distinct from 'admin-v1' or not(p ? 'id') then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 begin target_id:=(p->>'id')::uuid; exception when others then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end;
 select * into i from public.inquiries where inquiries.id=target_id;
 if i.id is null then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('reply_id',r.id,'author_id',r.author_id,'body',r.body,
  'created_at',r.created_at,'delivery',coalesce((select n.status from public.inquiry_notifications n where n.reply_id=r.id),'none'),
  'attempts',coalesce((select n.attempt_count from public.inquiry_notifications n where n.reply_id=r.id),0))
  order by r.created_at,r.id),'[]'::jsonb) into replies from public.inquiry_replies r where r.inquiry_id=i.id;
 select coalesce(jsonb_agg(jsonb_build_object('from_status',e.from_status,'to_status',e.to_status,
  'actor_kind',e.actor_kind,'created_at',e.created_at) order by e.created_at,e.id),'[]'::jsonb)
  into events from public.inquiry_status_events e where e.inquiry_id=i.id;
 -- Member block reuses the P0-A read helpers; no new personal-data surface.
 select jsonb_build_object('account_id',i.user_id,
  'grade_level',(select p.grade_level from public.profiles p where p.id=i.user_id),
  'account_state',public.admin_account_state(i.user_id),
  'spendable',(public.admin_credit_snapshot((select c.id from public.credit_accounts c where c.user_id=i.user_id))->>'spendable')::integer,
  'deletion_state',public.admin_account_state(i.user_id)) into member;
 -- Related service references are bounded and only ever the submitting member's.
 select count(*) into essay_count from public.essay_evaluations e
  join public.essay_attempts a on a.id=e.attempt_id
  join public.essay_practice_sessions s on s.id=a.session_id
  where s.user_id=i.user_id;
 -- An uninstalled subsystem is reported as null, never as a fabricated zero.
 if public.admin_count('public.payment_orders') is null then
  order_count:=null;
 else
  execute 'select count(*) from public.payment_orders where subject_id=$1' into order_count using i.user_id;
 end if;
 related:=jsonb_build_object('essay_evaluations',essay_count,'payment_orders',order_count);
 return jsonb_build_object('dto_version','admin-v1','as_of',statement_timestamp(),
  'inquiry',jsonb_build_object('inquiry_id',i.id,'category',i.category,'title',i.title,'body',i.body,
   'status',i.status,'submitted_at',i.created_at,'updated_at',i.updated_at,
   'answered_at',i.answered_at,'closed_at',i.closed_at),
  'member',member,'replies',replies,'status_events',events,'related',related);
end$$;
create or replace function public.admin_member_detail(p_account_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $function$
declare
 result jsonb; providers jsonb; del jsonb; state text;
 study_total bigint; study_30d bigint; study_seconds bigint; study_last timestamptz;
 essay_attempts bigint; essay_submitted bigint; essay_evals bigint; essay_last timestamptz;
 math_attempts bigint; math_evals bigint;
 mock_attempts bigint; mock_last timestamptz;
 bookmark_count bigint; view_count bigint; view_last timestamptz;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p_account_id is null then raise sqlstate 'PT422' using message='INVALID_ACCOUNT'; end if;
 if not exists(select 1 from auth.users u where u.id=p_account_id) then raise sqlstate 'PT404' using message='MEMBER_NOT_FOUND'; end if;

 state := public.admin_account_state(p_account_id);
 if to_regclass('public.account_deletion_requests') is not null then
  execute $q$select jsonb_build_object('request_id',r.id,'state',r.state,'phase',r.phase,
    'requested_at',r.requested_at,'scheduled_deletion_at',r.scheduled_deletion_at,
    'cancelled_at',r.cancelled_at,'completed_at',r.completed_at)
   from public.account_deletion_requests r where r.subject_id=$1
   order by r.requested_at desc, r.id desc limit 1$q$ using p_account_id into del;
 end if;

 select count(*),count(*) filter (where s.started_at>statement_timestamp()-interval '30 days'),
  coalesce(sum(s.duration_seconds),0),max(s.started_at)
  into study_total,study_30d,study_seconds,study_last
 from public.study_sessions s where s.user_id=p_account_id;

 select count(*),count(*) filter (where a.submitted_at is not null),max(a.submitted_at)
  into essay_attempts,essay_submitted,essay_last
 from public.essay_attempts a join public.essay_practice_sessions ps on ps.id=a.session_id
 where ps.user_id=p_account_id;
 select count(*) into essay_evals from public.essay_evaluations e
 where e.session_id in (select ps.id from public.essay_practice_sessions ps where ps.user_id=p_account_id);

 if to_regclass('public.math_attempts') is not null then
  execute 'select count(*) from public.math_attempts ma where ma.student_id=$1' using p_account_id into math_attempts;
  if to_regclass('public.math_evaluations') is not null then
   execute 'select count(*) from public.math_evaluations me join public.math_attempts ma on ma.id=me.attempt_id where ma.student_id=$1' using p_account_id into math_evals;
  end if;
 end if;

 select count(*),max(mx.submitted_at) into mock_attempts,mock_last
 from public.mock_exam_attempts mx where mx.user_id=p_account_id;
 select count(*) into bookmark_count from public.bookmarks b where b.user_id=p_account_id;
 select count(*),max(v.viewed_at) into view_count,view_last from public.recent_views v where v.user_id=p_account_id;

 if to_regclass('auth.identities') is not null then
  execute $$select coalesce(jsonb_agg(x.provider order by x.provider),'[]'::jsonb) from (select distinct provider from auth.identities where user_id=$1) x$$ into providers using p_account_id;
 end if;
 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'member',jsonb_build_object(
   'account_id',u.id,'email',u.email::text,'created_at',u.created_at,
   'display_name',p.display_name,'grade_level',p.grade_level::text,
   'school_code',p.neis_school_code,'school_office_code',p.neis_office_code,
   'email_confirmed',u.email_confirmed_at is not null,
   'auth_providers',providers,
   'intended_major',to_jsonb(p)->>'intended_major',
   'target_universities',coalesce((select jsonb_agg(jsonb_build_object('university_name',t.name,'intended_division',t.intended_division) order by t.created_at,t.id) from (
    select st.id,st.created_at,un.name,st.intended_division from public.student_target_universities st
    join public.universities un on un.id=st.university_id
    where st.user_id=p_account_id and st.status='interested' order by st.created_at,st.id limit 50
   ) t),'[]'::jsonb)
  ),
  'account',jsonb_build_object('state',state,'deletion',del),
  'usage',jsonb_build_object(
   'study',jsonb_build_object('sessions_total',study_total,'sessions_30d',study_30d,
     'active_seconds_total',study_seconds,'last_started_at',study_last),
   'essay',jsonb_build_object('attempts',essay_attempts,'submitted',essay_submitted,
     'evaluations',essay_evals,'last_submitted_at',essay_last),
   'math',jsonb_build_object('installed',(to_regclass('public.math_attempts') is not null),
     'runtime_state','RUNTIME_OFF','attempts',math_attempts,'evaluations',math_evals),
   'mock',jsonb_build_object('attempts',mock_attempts,'last_submitted_at',mock_last),
   'library',jsonb_build_object('bookmarks',bookmark_count,'recent_views',view_count,
     'last_viewed_at',view_last)
  )
 ) into result from auth.users u left join public.profiles p on p.id=u.id where u.id=p_account_id;
 return result;
end$function$;
commit;
