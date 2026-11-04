-- Owner approval required before Production. No source inquiry is copied or moved.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
create schema support_private;
revoke all on schema support_private from public, anon, authenticated;

-- Preserve the existing WEB foreign keys; each new child has exactly one parent.
alter table public.inquiry_replies alter column inquiry_id drop not null;
alter table public.inquiry_replies add column feedback_id uuid references public.feedback_submissions(id) on delete cascade;
alter table public.inquiry_replies add constraint reply_one_parent check ((inquiry_id is null) <> (feedback_id is null));
create unique index reply_feedback_request on public.inquiry_replies(feedback_id,request_key) where feedback_id is not null;
alter table public.inquiry_replies add constraint reply_feedback_identity unique(id,feedback_id);
alter table public.inquiry_notifications alter column inquiry_id drop not null;
alter table public.inquiry_notifications add column feedback_id uuid references public.feedback_submissions(id) on delete cascade;
alter table public.inquiry_notifications add constraint notification_one_parent check ((inquiry_id is null) <> (feedback_id is null));
alter table public.inquiry_notifications add constraint notification_feedback_reply foreign key(reply_id,feedback_id) references public.inquiry_replies(id,feedback_id) on delete cascade;
alter table public.inquiry_status_events alter column inquiry_id drop not null;
alter table public.inquiry_status_events add column feedback_id uuid references public.feedback_submissions(id) on delete cascade;
alter table public.inquiry_status_events add constraint event_one_parent check ((inquiry_id is null) <> (feedback_id is null));

create index support_notifications_feedback on public.inquiry_notifications(feedback_id) where feedback_id is not null;
create index support_events_feedback on public.inquiry_status_events(feedback_id,created_at,id) where feedback_id is not null;

create table support_private.feedback_state (
 feedback_id uuid primary key references public.feedback_submissions(id) on delete cascade,
 status text not null check(status in ('RECEIVED','IN_PROGRESS','ANSWERED','CLOSED')),
 updated_at timestamptz not null default now(), answered_at timestamptz, closed_at timestamptz,
 check(status<>'ANSWERED' or answered_at is not null), check(status<>'CLOSED' or closed_at is not null)
);
alter table support_private.feedback_state enable row level security;
revoke all on support_private.feedback_state from public,anon,authenticated;

create view support_private.items as
 select 'WEB'::text source,i.id,i.user_id,i.category,i.title,i.body,i.status,i.created_at,i.updated_at,i.answered_at,i.closed_at,
 (select count(*) from public.inquiry_replies r where r.inquiry_id=i.id) reply_count
 from public.inquiries i
 union all
 select 'APP',f.id,f.user_id,f.category,f.title,f.body,
 coalesce(s.status,case f.status when 'new' then 'RECEIVED' when 'reviewing' then 'IN_PROGRESS' else 'CLOSED' end),
 f.created_at,coalesce(s.updated_at,f.updated_at),s.answered_at,s.closed_at,
 (select count(*) from public.inquiry_replies r where r.feedback_id=f.id)
 from public.feedback_submissions f left join support_private.feedback_state s on s.feedback_id=f.id;
revoke all on support_private.items from public,anon,authenticated;

create function support_private.validate(p jsonb, fields text[], dto text) returns void language plpgsql set search_path='' as $$
begin
 if p is null or jsonb_typeof(p)<>'object' or p-fields<>'{}'::jsonb or p->>'dto_version' is distinct from dto then
 raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
end $$;
create function support_private.source(p jsonb) returns text language plpgsql immutable set search_path='' as $$
declare s text:=coalesce(p->>'source','WEB'); begin
 if s not in ('APP','WEB') then raise sqlstate 'PT422' using message='INVALID_SOURCE'; end if; return s;
end $$;

create function public.support_admin_list(p jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare st text; cat text; src text; q text; lim int; off int; rows jsonb; total bigint; opened bigint;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 perform support_private.validate(p,array['dto_version','status','category','source','query','limit','offset'],'admin-v1');
 st:=nullif(p->>'status',''); cat:=nullif(p->>'category',''); src:=nullif(p->>'source',''); q:=nullif(btrim(p->>'query'),'');
 lim:=least(greatest(coalesce((p->>'limit')::int,25),1),50); off:=greatest(coalesce((p->>'offset')::int,0),0);
 if st is not null and st not in ('RECEIVED','IN_PROGRESS','ANSWERED','CLOSED') or src is not null and src not in ('APP','WEB') then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 if q is not null and char_length(q) not between 3 and 120 then raise sqlstate 'PT422' using message='INVALID_QUERY'; end if;
 select count(*) into total from support_private.items i where (st is null or status=st) and (cat is null or category=cat) and (src is null or source=src) and (q is null or id::text=q or user_id::text=q or title ilike '%'||q||'%');
 select count(*) into opened from support_private.items where status in ('RECEIVED','IN_PROGRESS');
 select coalesce(jsonb_agg(jsonb_build_object('source',i.source,'inquiry_id',i.id,'user_id',i.user_id,'category',i.category,'title',i.title,'status',i.status,'created_at',i.created_at,'updated_at',i.updated_at,'reply_count',i.reply_count,'preview',left(i.body,120)) order by i.created_at desc,i.source,i.id desc),'[]') into rows
 from (select * from support_private.items where (st is null or status=st) and (cat is null or category=cat) and (src is null or source=src) and (q is null or id::text=q or user_id::text=q or title ilike '%'||q||'%') order by created_at desc,source,id desc limit lim offset off)i;
 return jsonb_build_object('dto_version','admin-v1','as_of',statement_timestamp(),'total',total,'open',opened,'limit',lim,'offset',off,'items',rows);
end $$;

create function support_private.thread(src text, target uuid) returns jsonb language sql stable set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('reply_id',r.id,'author_id',r.author_id,'body',r.body,'created_at',r.created_at,'delivery',coalesce(n.status,'none'),'attempts',coalesce(n.attempt_count,0)) order by r.created_at,r.id),'[]') from public.inquiry_replies r left join public.inquiry_notifications n on n.reply_id=r.id where (src='APP' and r.feedback_id=target) or (src='WEB' and r.inquiry_id=target)
$$;
create function public.support_admin_detail(p jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare src text; target uuid; i record; events jsonb; result jsonb;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 perform support_private.validate(p,array['dto_version','source','id'],'admin-v1'); src:=support_private.source(p); target:=(p->>'id')::uuid;
 if src='WEB' then return public.admin_inquiry_detail(p-'source') || jsonb_build_object('source','WEB'); end if;
 select * into i from support_private.items where source=src and id=target;
 if not found then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('from_status',from_status,'to_status',to_status,'actor_kind',actor_kind,'created_at',created_at) order by created_at,id),'[]') into events from public.inquiry_status_events where feedback_id=target;
 return jsonb_build_object('dto_version','admin-v1','as_of',statement_timestamp(),'source',src,
 'inquiry',jsonb_build_object('inquiry_id',i.id,'category',i.category,'title',i.title,'body',i.body,'status',i.status,'submitted_at',i.created_at,'updated_at',i.updated_at,'answered_at',i.answered_at,'closed_at',i.closed_at),
 'member',jsonb_build_object('account_id',i.user_id,'grade_level',null,'account_state',null,'spendable',null),
 'related',jsonb_build_object('essay_evaluations',null,'payment_orders',null),'replies',support_private.thread(src,target),'status_events',events);
end $$;

create function public.support_admin_reply(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare src text; target uuid; k uuid; b text; i record; prior public.inquiry_replies; r public.inquiry_replies; result jsonb;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 perform support_private.validate(p,array['dto_version','source','id','body','request_key'],'admin-v1'); src:=support_private.source(p);
 target:=(p->>'id')::uuid; k:=(p->>'request_key')::uuid; b:=btrim(p->>'body');
 if target is null or k is null or b is null or char_length(b) not between 1 and 4000 then raise sqlstate 'PT422' using message='INVALID_REQUEST'; end if;
 if src='WEB' then
 -- Lock before checking a retry, including retries after closure.
 perform 1 from public.inquiries where id=target for update;
 select * into prior from public.inquiry_replies where inquiry_id=target and request_key=k;
 if prior.id is not null then
 if prior.body<>b then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT'; end if;
 return jsonb_build_object('reply_id',prior.id,'created',false,'duplicate',true); end if;
 result:=public.admin_inquiry_reply(p-'source'); return result||jsonb_build_object('created',not coalesce((result->>'duplicate')::boolean,false));
 end if;
 perform 1 from public.feedback_submissions where id=target for update;
 if not found then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 select * into prior from public.inquiry_replies where feedback_id=target and request_key=k;
 if prior.id is not null then
 if prior.body<>b then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT'; end if;
 return jsonb_build_object('reply_id',prior.id,'created',false,'duplicate',true); end if;
 select * into i from support_private.items where source='APP' and id=target;
 if i.status='CLOSED' then raise sqlstate 'PT409' using message='INQUIRY_CLOSED'; end if;
 insert into public.inquiry_replies(feedback_id,author_id,body,request_key) values(target,auth.uid(),b,k) returning * into r;
 -- Delivery is asynchronous; guests have no invented address or recipient.
 if i.user_id is not null then insert into public.inquiry_notifications(feedback_id,reply_id) values(target,r.id); end if;
 insert into support_private.feedback_state(feedback_id,status,answered_at) values(target,'ANSWERED',r.created_at)
 on conflict(feedback_id) do update set status='ANSWERED',updated_at=clock_timestamp(),answered_at=coalesce(feedback_state.answered_at,excluded.answered_at),closed_at=null;
 insert into public.inquiry_status_events(feedback_id,from_status,to_status,actor_kind,actor_id) values(target,i.status,'ANSWERED','operator',auth.uid());
 return jsonb_build_object('reply_id',r.id,'created',true,'duplicate',false,'queued',i.user_id is not null);
end $$;

create function public.support_admin_status(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare src text; target uuid; st text; i record;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 perform support_private.validate(p,array['dto_version','source','id','status'],'admin-v1'); src:=support_private.source(p);
 if src='WEB' then return public.admin_inquiry_set_status(p-'source'); end if;
 target:=(p->>'id')::uuid; st:=p->>'status';
 if st is null or st not in ('RECEIVED','IN_PROGRESS','ANSWERED','CLOSED') then raise sqlstate 'PT422' using message='INVALID_STATUS'; end if;
 perform 1 from public.feedback_submissions where id=target for update;
 if not found then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 select * into i from support_private.items where source=src and id=target;
 if st='ANSWERED' and i.reply_count=0 then raise sqlstate 'PT409' using message='REPLY_REQUIRED'; end if;
 if st=i.status then return jsonb_build_object('status',st,'changed',false); end if;
 insert into support_private.feedback_state(feedback_id,status,answered_at,closed_at) values(target,st,i.answered_at,case when st='CLOSED' then clock_timestamp() end)
 on conflict(feedback_id) do update set status=st,updated_at=clock_timestamp(),closed_at=excluded.closed_at;
 insert into public.inquiry_status_events(feedback_id,from_status,to_status,actor_kind,actor_id) values(target,i.status,st,'operator',auth.uid());
 return jsonb_build_object('status',st,'changed',true);
end $$;

create function public.support_mine(p jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare rows jsonb; lim int; off int; u uuid:=auth.uid();
begin
 if u is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED'; end if;
 if not public.account_service_allowed() then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED'; end if;
 perform support_private.validate(p,array['dto_version','limit','offset'],'inquiry-v1');
 lim:=least(greatest(coalesce((p->>'limit')::int,20),1),50); off:=greatest(coalesce((p->>'offset')::int,0),0);
 select coalesce(jsonb_agg(jsonb_build_object('source',i.source,'inquiry_id',i.id,'category',i.category,'title',i.title,'status',i.status,'created_at',i.created_at,'answered',i.reply_count>0) order by i.created_at desc,i.source,i.id desc),'[]') into rows from
 (select * from support_private.items where user_id=u order by created_at desc,source,id desc limit lim offset off)i;
 return jsonb_build_object('dto_version','inquiry-v1','items',rows,'limit',lim,'offset',off);
end $$;
create function public.support_detail(p jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare i record; src text; rows jsonb;
begin
 if auth.uid() is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED'; end if;
 if not public.account_service_allowed() then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED'; end if;
 perform support_private.validate(p,array['dto_version','source','id'],'inquiry-v1'); src:=support_private.source(p);
 select * into i from support_private.items where source=src and id=(p->>'id')::uuid and user_id=auth.uid();
 if not found then raise sqlstate 'PT404' using message='INQUIRY_NOT_FOUND'; end if;
 select coalesce(jsonb_agg(x-'author_id'-'delivery'-'attempts'),'[]') into rows from jsonb_array_elements(support_private.thread(src,i.id))x;
 return jsonb_build_object('source',src,'inquiry_id',i.id,'title',i.title,'body',i.body,'status',i.status,'created_at',i.created_at,'replies',rows);
end $$;

create function public.support_metrics() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb; oldest record;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 select * into oldest from support_private.items where status in ('RECEIVED','IN_PROGRESS') order by created_at,source,id limit 1;
 select jsonb_build_object('open',count(*) filter(where status in ('RECEIVED','IN_PROGRESS')),'new_today',count(*) filter(where created_at >= (date_trunc('day',now() at time zone 'Asia/Seoul') at time zone 'Asia/Seoul')),'in_progress',count(*) filter(where status='IN_PROGRESS'),'answered',count(*) filter(where status='ANSWERED'),'closed',count(*) filter(where status='CLOSED'),'first_response_seconds',round(avg(extract(epoch from (answered_at-created_at))))::bigint) into result from support_private.items;
 return result||jsonb_build_object('installed',true,'oldest_open_id',oldest.id,'oldest_open_source',oldest.source,'oldest_open_at',oldest.created_at,'failed_deliveries',(select count(*) from public.inquiry_notifications where status='failed'));
end $$;

-- Reuse the existing queue with lease reclaim, bounded retries and current owner lookup.
create function public.claim_support_notifications(p_batch_size integer default 10) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 update public.inquiry_notifications set status='failed',claimed_at=null,claim_token=null,next_attempt_at=clock_timestamp(),last_error_code='timeout' where status='processing' and claimed_at<clock_timestamp()-interval '15 minutes';
 with candidates as (select id from public.inquiry_notifications where attempt_count<8 and (status='pending' or status='failed' and next_attempt_at is not null) and coalesce(next_attempt_at,clock_timestamp())<=clock_timestamp() order by created_at,id limit least(greatest(coalesce(p_batch_size,10),1),10) for update skip locked),
 claimed as (update public.inquiry_notifications n set status='processing',claimed_at=clock_timestamp(),claim_token=gen_random_uuid(),attempt_count=attempt_count+1 where id in(select id from candidates) returning n.*)
 select coalesce(jsonb_agg(jsonb_build_object('notification_id',c.id,'reply_id',r.id,'claim_token',c.claim_token,'source',i.source,'target_id',i.id,'member_email',nullif(u.email,''),'body',r.body,'attempt_count',c.attempt_count)),'[]') into result from claimed c join public.inquiry_replies r on r.id=c.reply_id join support_private.items i on i.id=coalesce(c.feedback_id,c.inquiry_id) and i.source=case when c.feedback_id is null then 'WEB' else 'APP' end left join auth.users u on u.id=i.user_id;
 return result;
end $$;
create function public.finish_support_notification(p_id uuid,p_token uuid,p_error text default null) returns boolean language plpgsql security definer set search_path='' as $$
begin
 if p_error is not null and p_error not in ('network','timeout','rate_limited','provider_5xx','provider_rejected','no_recipient','unknown') then raise exception 'INVALID_ERROR'; end if;
 update public.inquiry_notifications set status=case when p_error is null then 'sent' else 'failed' end,sent_at=case when p_error is null then clock_timestamp() end,claimed_at=null,claim_token=null,last_error_code=p_error,
 next_attempt_at=case when p_error in ('network','timeout','rate_limited','provider_5xx') and attempt_count<8 then clock_timestamp()+make_interval(secs=>least(3600,30*(2^least(attempt_count,6)))) end
 where id=p_id and status='processing' and claim_token=p_token;
 return found;
end $$;

revoke all on all functions in schema support_private from public,anon,authenticated;
revoke all on function public.support_admin_list(jsonb),public.support_admin_detail(jsonb),public.support_admin_reply(jsonb),public.support_admin_status(jsonb),public.support_mine(jsonb),public.support_detail(jsonb),public.support_metrics() from public,anon;
grant execute on function public.support_admin_list(jsonb),public.support_admin_detail(jsonb),public.support_admin_reply(jsonb),public.support_admin_status(jsonb),public.support_mine(jsonb),public.support_detail(jsonb),public.support_metrics() to authenticated;
revoke all on function public.claim_support_notifications(integer),public.finish_support_notification(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.claim_support_notifications(integer),public.finish_support_notification(uuid,uuid,text) to service_role;
commit;
