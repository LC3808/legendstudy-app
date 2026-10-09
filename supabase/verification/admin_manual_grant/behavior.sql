-- LOCAL ONLY: run against an isolated canonical Credit/Admin fixture database.
-- The harness provides account_private.allowed for lifecycle boundary simulation.
begin;
insert into auth.users(id,email) values
 ('ac000000-0000-4000-8000-000000000001','operator@example.test'),
 ('ac000000-0000-4000-8000-000000000002','recipient@example.test'),
 ('ac000000-0000-4000-8000-000000000003','ordinary@example.test');
insert into public.profiles(id) values ('ac000000-0000-4000-8000-000000000001'),('ac000000-0000-4000-8000-000000000002'),('ac000000-0000-4000-8000-000000000003') on conflict do nothing;
insert into public.admin_users(user_id) values ('ac000000-0000-4000-8000-000000000001');
select set_config('request.jwt.claims',jsonb_build_object('sub','ac000000-0000-4000-8000-000000000001','role','authenticated','exp',extract(epoch from now())+3600)::text,true);
set local role authenticated;
do $$ declare g uuid; again uuid; begin
 g:=public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',1,'검증 지급','ac000000-0000-4000-8000-000000000010');
 again:=public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','RECIPIENT@example.test',1,' 검증 지급 ','ac000000-0000-4000-8000-000000000010');
 if g is distinct from again then raise exception 'Replay failed';end if;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',2,'검증 지급','ac000000-0000-4000-8000-000000000010');raise exception 'conflict accepted';exception when sqlstate 'PT409' then null;end;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','wrong@example.test',1,'검증 지급','ac000000-0000-4000-8000-000000000011');raise exception 'wrong email accepted';exception when sqlstate 'PT409' then null;end;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',101,'검증 지급','ac000000-0000-4000-8000-000000000011');raise exception '101 accepted';exception when sqlstate 'PT422' then null;end;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',0,'검증 지급','ac000000-0000-4000-8000-000000000011');raise exception 'zero accepted';exception when sqlstate 'PT422' then null;end;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',1,'   ','ac000000-0000-4000-8000-000000000011');raise exception 'empty reason accepted';exception when sqlstate 'PT422' then null;end;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',1,repeat('x',501),'ac000000-0000-4000-8000-000000000011');raise exception 'long reason accepted';exception when sqlstate 'PT422' then null;end;
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',1,'valid',null);raise exception 'null key accepted';exception when sqlstate 'PT422' then null;end;
end $$;
select set_config('request.jwt.claims',jsonb_build_object('sub','ac000000-0000-4000-8000-000000000003','role','authenticated','exp',extract(epoch from now())+3600)::text,true);
do $$ begin
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',1,'denied','ac000000-0000-4000-8000-000000000011');raise exception 'ordinary allowed';exception when sqlstate 'PT403' then null;end;
end $$;
select set_config('request.jwt.claims',jsonb_build_object('sub','ac000000-0000-4000-8000-000000000001','role','authenticated','exp',1)::text,true);
do $$ begin
 begin perform public.admin_manual_credit_grant('ac000000-0000-4000-8000-000000000002','recipient@example.test',1,'denied','ac000000-0000-4000-8000-000000000011');raise exception 'expired allowed';exception when sqlstate 'PT403' then null;end;
end $$;
reset role;
do $$ declare n integer; begin
 select count(*) into n from public.credit_transactions where idempotency_key like 'grant/admin_manual/ac000000-%';
 if n<>1 then raise exception 'Unexpected transaction count %',n;end if;
 if not exists(select 1 from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id join public.credit_accounts a on a.id=t.account_id where
 t.idempotency_key='grant/admin_manual/ac000000-0000-4000-8000-000000000010'
 and t.balance_delta=1 and t.reserved_delta=0 and t.transaction_type='admin_grant'
 and t.reason_code='manual_support: 검증 지급' and t.actor_reference='operator/ac000000-0000-4000-8000-000000000001'
 and g.origin='admin_grant' and g.expires_at is null and a.user_id='ac000000-0000-4000-8000-000000000002') then raise exception 'Ledger mismatch';end if;
 if has_function_privilege('anon','public.admin_manual_credit_grant(uuid,text,integer,text,uuid)','execute') or has_function_privilege('service_role','public.admin_manual_credit_grant(uuid,text,integer,text,uuid)','execute') then raise exception 'ACL leak';end if;
 if has_function_privilege('authenticated','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute') then raise exception 'Finance authority broadened';end if;
end $$;
rollback;
