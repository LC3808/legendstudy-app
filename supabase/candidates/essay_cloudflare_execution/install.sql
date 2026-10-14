-- CANDIDATE ONLY: Owner approval required. No Provider/Credit/activation.
begin;
create table essay_exam_private.checkpoints (
 run_id uuid not null references essay_exam_private.runs(id) on delete cascade,
 key text not null check(key ~ '^[a-zA-Z0-9_-]{1,100}$'),
 writer uuid not null,
 state text not null check(state in ('pending','checkpoint')),
 payload jsonb,
 primary key(run_id,key),
 check((state='checkpoint')=(payload is not null)),
 check(payload is null or (jsonb_typeof(payload)='object' and octet_length(payload::text)<=8388608))
);
alter table essay_exam_private.checkpoints enable row level security;
alter table essay_exam_private.checkpoints force row level security;
revoke all on essay_exam_private.checkpoints from public,anon,authenticated,service_role,essay_worker;
create function public.essay_exam_checkpoint(p_subject uuid,p_run uuid,p_token uuid,p_key text,p_action text,p_writer uuid default null,p_payload jsonb default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; c essay_exam_private.checkpoints; account uuid; inserted int;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;
 if p_key is null or p_key !~ '^[a-zA-Z0-9_-]{1,100}$' or p_action is null or p_action not in ('read','begin','write') then raise sqlstate 'PT422';end if;
 select * into c from essay_exam_private.checkpoints where run_id=p_run and key=p_key;
 if p_action='read' then
  return case when c.run_id is null then null else jsonb_build_object('state',c.state,'payload',c.payload) end;
 end if;
 if r.state<>'reserved' or p_writer is null then raise sqlstate 'PT409';end if;
 if p_action='begin' then
  if r.lease_until is null or r.lease_until<=clock_timestamp() then raise sqlstate 'PT409' using message='DISPATCH_LEASE_EXPIRED';end if;
  -- Never renew or steal even the SAME writer: lost begin response is ambiguous.
  insert into essay_exam_private.checkpoints values(p_run,p_key,p_writer,'pending',null) on conflict do nothing;
  get diagnostics inserted=row_count;
  return jsonb_build_object('started',inserted=1);
 end if;
 if c.run_id is null or c.writer<>p_writer or p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>8388608 then raise sqlstate 'PT409';end if;
 if c.state='checkpoint' and c.payload is distinct from p_payload then raise sqlstate 'PT409' using message='CHECKPOINT_IMMUTABLE';end if;
 -- Original writer may persist after dispatch expiry; no new Provider execution.
 update essay_exam_private.checkpoints set state='checkpoint',payload=p_payload where run_id=p_run and key=p_key;
 return jsonb_build_object('stored',true);
end$$;
revoke all on function public.essay_exam_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb) to essay_worker;
commit;
