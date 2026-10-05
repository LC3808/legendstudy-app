-- ADMIN-P0-B — Credit grant boundary support, payment operations read and
-- 1:1 inquiry management for the LegendStudy release-operations console.
--
-- Reuse, not replacement. This file adds no wallet, no analytics store, no
-- admin auth, no email service and no payment architecture:
--   public.admin_users              operations allowlist (20260917000100, reused)
--   public.admin_operator()         fail-closed gate (20261005000200, reused)
--   public.essay_admin_grant(...)   the ONLY Credit write path (20260929000300)
--   public.payment_support(jsonb)   the ONLY order action path (20261004000100)
--   Resend + the notification-queue claim/retry pattern (20260917000100/200)
--
-- Credit granting is NOT implemented here. public.essay_admin_grant is owned by
-- essay_finance and callable only by that role; the browser reaches it through a
-- server boundary that holds the finance bearer. This file adds only the
-- operator-side read helpers the console needs, and nothing that could grant.
--
-- Installable independently of the still-pending subsystem migrations. The
-- payment read reports NOT_INSTALLED (JSON null) rather than a fake 0 when
-- public.payment_orders is absent.
--
-- Privacy: no password or hash, no JWT or refresh token, no provider token, no
-- finance bearer, no raw provider payload, no credit external_reference and no
-- answer body ever leaves these functions. An inquiry body is returned only from
-- the single-inquiry detail read, never from a list.
begin;

-- 1. Payment operations read --------------------------------------------------
-- Bounded, operator-gated read of the canonical order table. No write, no
-- provider call: cancel/reconcile stay on public.payment_support(jsonb) behind
-- the finance bearer.
create function public.admin_payment_orders(p jsonb) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare installed boolean; q text; st text; lim integer; off integer; rows jsonb; total bigint;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','state','query','limit','offset']<>'{}'::jsonb
  or p->>'dto_version' is distinct from 'admin-v1' then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 st:=nullif(btrim(coalesce(p->>'state','')),'');
 q:=nullif(btrim(coalesce(p->>'query','')),'');
 lim:=least(greatest(coalesce((p->>'limit')::integer,25),1),50);
 off:=greatest(coalesce((p->>'offset')::integer,0),0);
 if st is not null and st not in ('ORDER_CREATED','AUTHORIZATION_PENDING','PAID','CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED','FAILED','EXPIRED') then
  raise sqlstate 'PT422' using message='INVALID_STATE'; end if;
 if q is not null and (char_length(q)<3 or char_length(q)>120) then raise sqlstate 'PT422' using message='INVALID_QUERY'; end if;
 if not exists(select 1 from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='payment_orders' and c.relkind='r') then
  return jsonb_build_object('dto_version','admin-v1','as_of',statement_timestamp(),'installed',false,
   'runtime_state','LIVE_OFF','runtime_label','결제 기능 미활성 (실결제 아님)','mode','NONE',
   'total',null,'limit',lim,'offset',off,'orders',null);
 end if;
 -- The order table exists but its provider mode decides what may be claimed.
 execute $sql$
  select count(*) from public.payment_orders o
  where ($1 is null or o.state=$1)
   and ($2 is null or o.id::text=$2 or coalesce(o.provider_purchase_id,'') ilike '%'||$2||'%'
        or o.sku=$2 or o.subject_id::text=$2)$sql$ into total using st,q;
 execute $sql$
  select coalesce(jsonb_agg(jsonb_build_object(
   'order_id',o.id,'subject_id',o.subject_id,'sku',o.sku,'amount',o.amount,'quantity',o.quantity,
   'currency',o.currency,'mode',o.mode,'state',o.state,'grant_state',o.grant_state,
   'provider',o.provider,'paid_at',o.paid_at,'created_at',o.created_at,
   'credit_expires_at',o.credit_expires_at,
   'reconciliation_required',(o.mode='LIVE' and o.state='AUTHORIZATION_PENDING' and o.grant_id is null),
   'refundable',(o.state='PAID' and o.grant_id is not null)
  ) order by o.created_at desc,o.id desc),'[]'::jsonb)
  from (select * from public.payment_orders o
        where ($1 is null or o.state=$1)
         and ($2 is null or o.id::text=$2 or coalesce(o.provider_purchase_id,'') ilike '%'||$2||'%'
              or o.sku=$2 or o.subject_id::text=$2)
        order by o.created_at desc,o.id desc limit $3 offset $4) o$sql$ into rows using st,q,lim,off;
 return jsonb_build_object('dto_version','admin-v1','as_of',statement_timestamp(),'installed',true,
  'runtime_state','LIVE_OFF','runtime_label','결제 기능 미활성 (실결제 아님)',
  'mode',(select case when count(*)=0 then 'NONE' when bool_or(o.mode='LIVE') then 'LIVE' else 'TEST' end
          from public.payment_orders o),
  'total',total,'limit',lim,'offset',off,'orders',rows);
end$$;
revoke all on function public.admin_payment_orders(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.admin_payment_orders(jsonb) to authenticated;

-- 2. Inquiry model ------------------------------------------------------------
-- The existing public.feedback_submissions is the APP feedback form: it requires
-- app_version, build_number, platform and os_version, and its notification queue
-- mails the operator. A LAB web 1:1 inquiry has none of those values and needs
-- the reply mailed to the member, so forcing it into that table would mean
-- fabricating build metadata. This is the minimal additive model instead, reusing
-- the same queue claim/retry shape and the same Resend delivery path.
create table public.inquiries(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 category text not null check (category in ('account','material','essay_humanities','essay_math','credit','payment','deletion','technical','other')),
 title text not null check (char_length(btrim(title)) between 1 and 120),
 body text not null check (char_length(btrim(body)) between 1 and 4000),
 status text not null default 'RECEIVED' check (status in ('RECEIVED','IN_PROGRESS','ANSWERED','CLOSED')),
 request_key uuid not null,
 created_at timestamptz not null default clock_timestamp(),
 updated_at timestamptz not null default clock_timestamp(),
 answered_at timestamptz,
 closed_at timestamptz,
 unique(user_id,request_key),
 check (status<>'ANSWERED' or answered_at is not null),
 check (status<>'CLOSED' or closed_at is not null)
);
create index inquiries_created on public.inquiries(created_at desc,id desc);
create index inquiries_user on public.inquiries(user_id,created_at desc,id desc);
create index inquiries_status on public.inquiries(status,created_at desc,id desc);
alter table public.inquiries enable row level security;
revoke all on public.inquiries from public,anon,authenticated,service_role;

-- Append-only operator replies. The original inquiry body is never overwritten.
create table public.inquiry_replies(
 id uuid primary key default gen_random_uuid(),
 inquiry_id uuid not null references public.inquiries(id) on delete cascade,
 author_id uuid not null,
 body text not null check (char_length(btrim(body)) between 1 and 4000),
 request_key uuid not null,
 created_at timestamptz not null default clock_timestamp(),
 unique(inquiry_id,request_key)
);
create index inquiry_replies_inquiry on public.inquiry_replies(inquiry_id,created_at,id);
alter table public.inquiry_replies enable row level security;
revoke all on public.inquiry_replies from public,anon,authenticated,service_role;

-- Status transitions, auditable without a workflow engine.
create table public.inquiry_status_events(
 id bigint generated always as identity primary key,
 inquiry_id uuid not null references public.inquiries(id) on delete cascade,
 from_status text, to_status text not null,
 actor_kind text not null check (actor_kind in ('member','operator','system')),
 actor_id uuid,
 created_at timestamptz not null default clock_timestamp()
);
create index inquiry_status_events_inquiry on public.inquiry_status_events(inquiry_id,created_at,id);
alter table public.inquiry_status_events enable row level security;
revoke all on public.inquiry_status_events from public,anon,authenticated,service_role;

-- Member-facing reply delivery queue. No recipient address is stored: the worker
-- resolves it from auth.users by inquiry.user_id with the service role.
create table public.inquiry_notifications(
 id uuid primary key default gen_random_uuid(),
 inquiry_id uuid not null references public.inquiries(id) on delete cascade,
 reply_id uuid not null references public.inquiry_replies(id) on delete cascade,
 channel text not null default 'email' check (channel='email'),
 status text not null default 'pending' check (status in ('pending','processing','sent','failed')),
 attempt_count integer not null default 0 check (attempt_count between 0 and 8),
 last_error_code text check (last_error_code is null or char_length(last_error_code) between 1 and 80),
 created_at timestamptz not null default clock_timestamp(),
 next_attempt_at timestamptz default clock_timestamp(),
 claimed_at timestamptz,
 claim_token uuid,
 sent_at timestamptz,
 unique(reply_id,channel),
 constraint inquiry_notifications_sent_at_state check ((status='sent')=(sent_at is not null)),
 constraint inquiry_notifications_processing_claim_check check ((status='processing')=(claimed_at is not null and claim_token is not null)),
 constraint inquiry_notifications_non_processing_claim_clear check (status='processing' or (claimed_at is null and claim_token is null))
);
create index inquiry_notifications_claimable on public.inquiry_notifications(next_attempt_at,created_at,id)
 where status in ('pending','failed') and attempt_count<8;
create index inquiry_notifications_inquiry on public.inquiry_notifications(inquiry_id,created_at desc);
alter table public.inquiry_notifications enable row level security;
revoke all on public.inquiry_notifications from public,anon,authenticated,service_role;

create function public.inquiry_touch() returns trigger language plpgsql security invoker set search_path='' as $$
begin new.updated_at=clock_timestamp(); return new; end$$;
revoke all on function public.inquiry_touch() from public,anon,authenticated,service_role;
create trigger inquiries_touch before update on public.inquiries for each row execute function public.inquiry_touch();

-- 3. Member-facing inquiry API ------------------------------------------------
create function public.inquiry_submit(p jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r public.inquiries; cat text; t text; b text; key uuid; prior public.inquiries;
begin
 if u is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','category','title','body','request_key']<>'{}'::jsonb
  or not(p ?& array['category','title','body','request_key']) or p->>'dto_version' is distinct from 'inquiry-v1' then
  raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 cat:=p->>'category'; t:=btrim(coalesce(p->>'title','')); b:=btrim(coalesce(p->>'body',''));
 begin key:=(p->>'request_key')::uuid; exception when others then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end;
 if cat not in ('account','material','essay_humanities','essay_math','credit','payment','deletion','technical','other')
  or char_length(t) not between 1 and 120 or char_length(b) not between 1 and 4000 then
  raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 if not exists(select 1 from public.profiles where id=u) then raise sqlstate 'PT404' using message='MEMBER_NOT_FOUND'; end if;
 -- Idempotent: a retried submission returns the original inquiry, never a copy.
 select * into prior from public.inquiries where user_id=u and request_key=key;
 if prior.id is not null then
  if prior.category<>cat or prior.title<>t or prior.body<>b then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT'; end if;
  return jsonb_build_object('inquiry_id',prior.id,'status',prior.status,'created_at',prior.created_at,'duplicate',true);
 end if;
 insert into public.inquiries(user_id,category,title,body,request_key) values(u,cat,t,b,key) returning * into r;
 insert into public.inquiry_status_events(inquiry_id,from_status,to_status,actor_kind,actor_id)
  values(r.id,null,'RECEIVED','member',u);
 return jsonb_build_object('inquiry_id',r.id,'status',r.status,'created_at',r.created_at,'duplicate',false);
end$$;
revoke all on function public.inquiry_submit(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.inquiry_submit(jsonb) to authenticated;

-- Own inquiries only. Identity is always auth.uid(); no parameter can widen it.
create function public.inquiry_mine(p jsonb) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare u uuid:=auth.uid(); lim integer; off integer; rows jsonb;
begin
 if u is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','limit','offset']<>'{}'::jsonb
  or p->>'dto_version' is distinct from 'inquiry-v1' then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 lim:=least(greatest(coalesce((p->>'limit')::integer,20),1),50);
 off:=greatest(coalesce((p->>'offset')::integer,0),0);
 select coalesce(jsonb_agg(jsonb_build_object('inquiry_id',i.id,'category',i.category,'title',i.title,
  'status',i.status,'created_at',i.created_at,'updated_at',i.updated_at,
  'answered',exists(select 1 from public.inquiry_replies r where r.inquiry_id=i.id)) order by i.created_at desc,i.id desc),'[]'::jsonb)
  into rows from (select * from public.inquiries where user_id=u order by created_at desc,id desc limit lim offset off) i;
 return jsonb_build_object('dto_version','inquiry-v1','as_of',statement_timestamp(),'limit',lim,'offset',off,'items',rows);
end$$;
revoke all on function public.inquiry_mine(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.inquiry_mine(jsonb) to authenticated;

-- 4. Operator inquiry API -----------------------------------------------------
create function public.admin_inquiry_list(p jsonb) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare st text; cat text; q text; lim integer; off integer; rows jsonb; total bigint; unread bigint;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','status','category','query','limit','offset']<>'{}'::jsonb
  or p->>'dto_version' is distinct from 'admin-v1' then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 st:=nullif(btrim(coalesce(p->>'status','')),'');
 cat:=nullif(btrim(coalesce(p->>'category','')),'');
 q:=nullif(btrim(coalesce(p->>'query','')),'');
 lim:=least(greatest(coalesce((p->>'limit')::integer,25),1),50);
 off:=greatest(coalesce((p->>'offset')::integer,0),0);
 if st is not null and st not in ('RECEIVED','IN_PROGRESS','ANSWERED','CLOSED') then raise sqlstate 'PT422' using message='INVALID_STATUS'; end if;
 if cat is not null and cat not in ('account','material','essay_humanities','essay_math','credit','payment','deletion','technical','other') then
  raise sqlstate 'PT422' using message='INVALID_CATEGORY'; end if;
 if q is not null and (char_length(q)<3 or char_length(q)>120) then raise sqlstate 'PT422' using message='INVALID_QUERY'; end if;
 select count(*) into total from public.inquiries i where (st is null or i.status=st) and (cat is null or i.category=cat)
  and (q is null or i.id::text=q or i.user_id::text=q or i.title ilike '%'||q||'%');
 select count(*) into unread from public.inquiries i where i.status in ('RECEIVED','IN_PROGRESS');
 select coalesce(jsonb_agg(jsonb_build_object('inquiry_id',i.id,'status',i.status,'category',i.category,
  'title',i.title,'user_id',i.user_id,'created_at',i.created_at,'updated_at',i.updated_at,
  'reply_count',(select count(*) from public.inquiry_replies r where r.inquiry_id=i.id),
  'preview',left(i.body,120)) order by i.created_at desc,i.id desc),'[]'::jsonb)
  into rows from (select * from public.inquiries i where (st is null or i.status=st) and (cat is null or i.category=cat)
   and (q is null or i.id::text=q or i.user_id::text=q or i.title ilike '%'||q||'%')
   order by i.created_at desc,i.id desc limit lim offset off) i;
 return jsonb_build_object('dto_version','admin-v1','as_of',statement_timestamp(),'limit',lim,'offset',off,
  'total',total,'open',unread,'items',rows);
end$$;
revoke all on function public.admin_inquiry_list(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.admin_inquiry_list(jsonb) to authenticated;

-- Single inquiry detail. This is the only read that returns the body.
create function public.admin_inquiry_detail(p jsonb) returns jsonb
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
  'spendable',(public.admin_credit_snapshot(i.user_id)->>'spendable')::integer,
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
revoke all on function public.admin_inquiry_detail(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.admin_inquiry_detail(jsonb) to authenticated;

-- Append-only reply. Never overwrites the inquiry body; idempotent on request_key.
create function public.admin_inquiry_reply(p jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare target_id uuid; body text; key uuid; actor uuid:=auth.uid(); i public.inquiries; prior public.inquiry_replies; r public.inquiry_replies;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','id','body','request_key']<>'{}'::jsonb
  or not(p ?& array['id','body','request_key']) or p->>'dto_version' is distinct from 'admin-v1' then
  raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 begin target_id:=(p->>'id')::uuid; key:=(p->>'request_key')::uuid; exception when others then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end;
 body:=btrim(coalesce(p->>'body',''));
 if char_length(body) not between 1 and 4000 then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 select * into i from public.inquiries where inquiries.id=target_id for update;
 if i.id is null then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 if i.status='CLOSED' then raise sqlstate 'PT409' using message='INQUIRY_CLOSED'; end if;
 select * into prior from public.inquiry_replies where inquiry_id=target_id and request_key=key;
 if prior.id is not null then
  if prior.body<>body then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT'; end if;
  return jsonb_build_object('reply_id',prior.id,'status',i.status,'duplicate',true,'queued',false);
 end if;
 insert into public.inquiry_replies(inquiry_id,author_id,body,request_key) values(target_id,actor,body,key) returning * into r;
 -- One queued delivery per reply; the worker resolves the member address itself.
 insert into public.inquiry_notifications(inquiry_id,reply_id) values(target_id,r.id) on conflict(reply_id,channel) do nothing;
 update public.inquiries set status='ANSWERED',answered_at=coalesce(answered_at,clock_timestamp()) where inquiries.id=target_id;
 insert into public.inquiry_status_events(inquiry_id,from_status,to_status,actor_kind,actor_id)
  values(target_id,i.status,'ANSWERED','operator',actor);
 return jsonb_build_object('reply_id',r.id,'status','ANSWERED','created_at',r.created_at,'duplicate',false,'queued',true);
end$$;
revoke all on function public.admin_inquiry_reply(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.admin_inquiry_reply(jsonb) to authenticated;

create function public.admin_inquiry_set_status(p jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare target_id uuid; next_status text; actor uuid:=auth.uid(); i public.inquiries;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p is null or jsonb_typeof(p)<>'object' or p-array['dto_version','id','status']<>'{}'::jsonb
  or not(p ?& array['id','status']) or p->>'dto_version' is distinct from 'admin-v1' then
  raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 begin target_id:=(p->>'id')::uuid; exception when others then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end;
 next_status:=p->>'status';
 if next_status not in ('RECEIVED','IN_PROGRESS','ANSWERED','CLOSED') then raise sqlstate 'PT422' using message='INVALID_STATUS'; end if;
 select * into i from public.inquiries where inquiries.id=target_id for update;
 if i.id is null then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 -- ANSWERED is owned by the reply path, so a status write cannot fake an answer.
 if next_status='ANSWERED' and not exists(select 1 from public.inquiry_replies r where r.inquiry_id=target_id) then
  raise sqlstate 'PT409' using message='REPLY_REQUIRED'; end if;
 if i.status=next_status then return jsonb_build_object('inquiry_id',target_id,'status',next_status,'changed',false); end if;
 update public.inquiries set status=next_status,
  answered_at=case when next_status='ANSWERED' then coalesce(answered_at,clock_timestamp()) else answered_at end,
  closed_at=case when next_status='CLOSED' then coalesce(closed_at,clock_timestamp()) else null end
  where inquiries.id=target_id;
 insert into public.inquiry_status_events(inquiry_id,from_status,to_status,actor_kind,actor_id)
  values(target_id,i.status,next_status,'operator',actor);
 return jsonb_build_object('inquiry_id',target_id,'status',next_status,'changed',true);
end$$;
revoke all on function public.admin_inquiry_set_status(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.admin_inquiry_set_status(jsonb) to authenticated;

-- 5. Support metrics for the operations dashboard -----------------------------
-- Only what the data can answer exactly. No invented average response time:
-- first_response_seconds is emitted only when at least one inquiry has both a
-- creation time and a reply, otherwise it is null.
create function public.admin_support_metrics() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare open_count bigint; today_count bigint; in_progress bigint; answered bigint; closed bigint;
 oldest record; avg_seconds bigint; failed_deliveries bigint;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 select count(*) filter(where status in ('RECEIVED','IN_PROGRESS')),
        count(*) filter(where created_at>=date_trunc('day',clock_timestamp())),
        count(*) filter(where status='IN_PROGRESS'),
        count(*) filter(where status='ANSWERED'),
        count(*) filter(where status='CLOSED')
  into open_count,today_count,in_progress,answered,closed from public.inquiries;
 select i.id as inquiry_id,i.created_at,
  (select min(r.created_at) from public.inquiry_replies r where r.inquiry_id=i.id) as first_reply
  into oldest from public.inquiries i where i.status in ('RECEIVED','IN_PROGRESS')
  order by i.created_at,i.id limit 1;
 select round(avg(extract(epoch from (r.first_reply-i.created_at))))::bigint into avg_seconds
  from public.inquiries i join lateral
   (select min(x.created_at) as first_reply from public.inquiry_replies x where x.inquiry_id=i.id) r on true
  where r.first_reply is not null;
 select count(*) into failed_deliveries from public.inquiry_notifications n where n.status='failed';
 return jsonb_build_object('installed',true,'open',open_count,'new_today',today_count,
  'in_progress',in_progress,'answered',answered,'closed',closed,
  'oldest_open_id',oldest.inquiry_id,'oldest_open_at',oldest.created_at,
  'first_response_seconds',avg_seconds,'failed_deliveries',failed_deliveries);
end$$;
revoke all on function public.admin_support_metrics() from public,anon,authenticated,service_role;
grant execute on function public.admin_support_metrics() to authenticated;

-- 6. Worker queue -------------------------------------------------------------
-- Same claim/retry shape as claim_feedback_notifications. Reachable by the
-- service role only; no browser role can drain or read the queue.
create function public.claim_inquiry_notifications(p_batch_size integer default 10)
returns table(notification_id uuid, inquiry_id uuid, reply_id uuid, member_id uuid, claim_token uuid, attempt_count integer)
language plpgsql security definer set search_path='' as $$
declare bounded integer:=least(greatest(coalesce(p_batch_size,1),1),10);
begin
 return query
 with candidates as (
  select n.id from public.inquiry_notifications n
  where n.attempt_count<8 and ((n.status='pending' and coalesce(n.next_attempt_at,clock_timestamp())<=clock_timestamp())
    or (n.status='failed' and coalesce(n.next_attempt_at,clock_timestamp())<=clock_timestamp()))
  order by n.next_attempt_at nulls first,n.created_at,n.id limit bounded for update skip locked),
 claimed as (
  update public.inquiry_notifications n set status='processing',claimed_at=clock_timestamp(),
   claim_token=gen_random_uuid(),attempt_count=n.attempt_count+1
  where n.id in (select id from candidates) returning n.*)
 select c.id,c.inquiry_id,c.reply_id,i.user_id,c.claim_token,c.attempt_count
  from claimed c join public.inquiries i on i.id=c.inquiry_id;
end$$;
revoke all on function public.claim_inquiry_notifications(integer) from public,anon,authenticated,service_role;
grant execute on function public.claim_inquiry_notifications(integer) to service_role;

create function public.complete_inquiry_notification(p_notification uuid,p_token uuid,p_ok boolean,p_error text default null)
returns boolean language plpgsql security definer set search_path='' as $$
declare n public.inquiry_notifications;
begin
 select * into n from public.inquiry_notifications where id=p_notification for update;
 if n.id is null or n.status<>'processing' or n.claim_token is distinct from p_token then
  raise sqlstate 'PT409' using message='CLAIM_LOST'; end if;
 if p_ok then
  update public.inquiry_notifications set status='sent',sent_at=clock_timestamp(),claimed_at=null,claim_token=null,last_error_code=null
   where id=n.id;
 else
  update public.inquiry_notifications set status='failed',claimed_at=null,claim_token=null,
   last_error_code=left(coalesce(p_error,'unknown'),80),
   next_attempt_at=clock_timestamp()+make_interval(secs=>least(3600,30*(2^least(n.attempt_count,6))))
   where id=n.id;
 end if;
 return p_ok;
end$$;
revoke all on function public.complete_inquiry_notification(uuid,uuid,boolean,text) from public,anon,authenticated,service_role;
grant execute on function public.complete_inquiry_notification(uuid,uuid,boolean,text) to service_role;

commit;
