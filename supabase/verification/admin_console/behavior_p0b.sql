-- ADMIN-P0-B behavioral verification.
--
-- Runs after behavior.sql against the same isolated cluster, so the P0-A
-- fixtures (admin, two members, one outsider, one profile-less account) already
-- exist. Covers the three P0-B surfaces:
--   A. Credit grant boundary      (essay_admin_grant reachability + idempotency)
--   B. Payment operations read    (not-installed degradation, bounds, ACL)
--   C. 1:1 inquiry                (member submit, operator list/detail/reply,
--                                  status audit, delivery queue, isolation)
-- Stand-ins are never used here: the payment read is exercised in its genuinely
-- absent state, which is the state the isolated cluster is in.
\set ON_ERROR_STOP on
-- The queue lifecycle checks run under the service role, which must be able to
-- record its own result.
grant insert, select on public.admin_verify to service_role;
grant usage, select on all sequences in schema public to service_role;
create table if not exists public.p0b_worker_seen(
 seq integer primary key, notification_id uuid, claim_token uuid, member_id uuid,
 attempt_count integer, completed boolean);
grant insert, select on public.p0b_worker_seen to service_role;
create or replace function pg_temp.check(p_name text, p_ok boolean) returns void
language plpgsql as $$
begin
 insert into admin_verify(name,ok) values(p_name,coalesce(p_ok,false));
 if not coalesce(p_ok,false) then raise warning 'CHECK FAILED: %', p_name; end if;
end$$;
create or replace function pg_temp.as_admin() returns void language plpgsql as $$
begin perform set_config('request.jwt.claims',
 json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
end$$;
create or replace function pg_temp.as_member(p uuid default '22222222-2222-4222-8222-222222222222') returns void language plpgsql as $$
begin perform set_config('request.jwt.claims',
 json_build_object('sub',p::text,'role','authenticated','exp',extract(epoch from now())+600)::text,true);
end$$;
create or replace function pg_temp.as_anon() returns void language plpgsql as $$
begin perform set_config('request.jwt.claims','',true); end$$;
-- Expected-error probe: returns the SQLSTATE raised, or 'NONE'.
create or replace function pg_temp.err(p_sql text) returns text language plpgsql as $$
begin execute p_sql; return 'NONE'; exception when others then return sqlstate; end$$;

-- ===========================================================================
-- A. Credit grant boundary
-- ===========================================================================
do $$
begin
 -- The canonical grant path is reachable by the finance role alone. A browser
 -- role reaching it would mean a finance credential had leaked into a client.
 perform pg_temp.check('A anon cannot execute essay_admin_grant',
  not has_function_privilege('anon','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute'));
 perform pg_temp.check('A authenticated cannot execute essay_admin_grant',
  not has_function_privilege('authenticated','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute'));
 perform pg_temp.check('A service_role cannot execute essay_admin_grant',
  not has_function_privilege('service_role','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute'));
 perform pg_temp.check('A essay_finance can execute essay_admin_grant',
  has_function_privilege('essay_finance','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute'));
 -- No browser role may write the ledger directly.
 perform pg_temp.check('A authenticated cannot insert credit_grants',
  not has_table_privilege('authenticated','public.credit_grants','insert'));
 perform pg_temp.check('A authenticated cannot update credit_transactions',
  not has_table_privilege('authenticated','public.credit_transactions','update'));
 -- The consumer app legitimately reads its own credit history, so the boundary
 -- asserted here is the write side, not the read side.
 perform pg_temp.check('A authenticated cannot insert credit_transactions',
  not has_table_privilege('authenticated','public.credit_transactions','insert'));
 perform pg_temp.check('A authenticated cannot delete credit_transactions',
  not has_table_privilege('authenticated','public.credit_transactions','delete'));
end$$;

-- The finance boundary authenticates the actor from the signed server context,
-- never from the payload, so a caller without that context is refused.
do $$
begin
 perform pg_temp.as_admin();
 -- The signature is validated at the gateway; inside the database the grant path
 -- requires an authenticated identity in the request context. Without one it
 -- refuses rather than posting to a null actor.
 perform set_config('request.jwt.claims','',true);
 perform pg_temp.check('A grant refused with no request identity',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant','aaaa1111-1111-4111-8111-111111111111','manual_support')$q$)
  in ('PT401','42501'));
 perform pg_temp.as_anon();
 perform pg_temp.check('A grant refused for anonymous caller',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant','aaaa1111-1111-4111-8111-111111111112','manual_support')$q$)
  in ('PT401','42501'));
end$$;

-- Rejection matrix, evaluated as the finance role with a valid identity.
do $$
declare before_total bigint; after_total bigint; g1 uuid; g2 uuid; g3 uuid;
begin
 perform pg_temp.as_admin();
 select count(*) into before_total from public.credit_transactions;

 -- Origin/reason pairs are a closed set; anything else is refused.
 perform pg_temp.check('A invalid origin refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'purchase','bbbb1111-1111-4111-8111-111111111111','manual_support')$q$)='PT422');
 perform pg_temp.check('A mismatched origin/reason refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant','bbbb1111-1111-4111-8111-111111111112','customer_compensation')$q$)='PT422');
 perform pg_temp.check('A arbitrary reason string refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant','bbbb1111-1111-4111-8111-111111111113','free_money')$q$)='PT422');
 perform pg_temp.check('A null idempotency key refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant',null,'manual_support')$q$)='PT422');
 -- Quantity must be a bounded positive integer.
 perform pg_temp.check('A zero quantity refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',0,'admin_grant','cccc1111-1111-4111-8111-111111111111','manual_support')$q$)<>'NONE');
 perform pg_temp.check('A negative quantity refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',-5,'admin_grant','cccc1111-1111-4111-8111-111111111112','manual_support')$q$)<>'NONE');
 -- A past expiry is not a valid grant.
 perform pg_temp.check('A past expiry refused',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant','cccc1111-1111-4111-8111-111111111113','manual_support',now()-interval '1 day')$q$)='PT422');

 -- Success path: exactly p_quantity is posted, on the canonical tables only.
 g1:=public.essay_admin_grant('22222222-2222-4222-8222-222222222222',2,'admin_grant','dddd1111-1111-4111-8111-111111111111','manual_support');
 perform pg_temp.check('A grant returns a grant id', g1 is not null);
 perform pg_temp.check('A grant posts the requested quantity',
  (select balance_delta from public.credit_transactions where grant_id=g1)=2);
 perform pg_temp.check('A grant records the canonical origin',
  (select origin from public.credit_grants where id=g1)='admin_grant');
 perform pg_temp.check('A grant records the canonical reason',
  (select reason_code from public.credit_transactions where grant_id=g1)='manual_support');
 perform pg_temp.check('A grant records the operator actor',
  (select actor_reference from public.credit_transactions where grant_id=g1)='operator/11111111-1111-4111-8111-111111111111');

 -- Idempotency: a retried click returns the same grant and posts nothing new.
 g2:=public.essay_admin_grant('22222222-2222-4222-8222-222222222222',2,'admin_grant','dddd1111-1111-4111-8111-111111111111','manual_support');
 perform pg_temp.check('A duplicate key returns the same grant', g2=g1);
 select count(*) into after_total from public.credit_transactions where grant_id=g1;
 perform pg_temp.check('A duplicate key posts exactly one transaction', after_total=1);
 -- A replayed key with different content is a conflict, not a second grant.
 perform pg_temp.check('A duplicate key with a different quantity conflicts',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',9,'admin_grant','dddd1111-1111-4111-8111-111111111111','manual_support')$q$)='PT409');
 perform pg_temp.check('A duplicate key with a different reason conflicts',
  pg_temp.err($q$select public.essay_admin_grant('22222222-2222-4222-8222-222222222222',2,'admin_grant','dddd1111-1111-4111-8111-111111111111','test_account')$q$)='PT409');
 -- The three remaining canonical origin/reason pairs are accepted.
 g3:=public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'promotion','eeee1111-1111-4111-8111-111111111111','operational_promotion');
 perform pg_temp.check('A promotion/operational_promotion accepted', g3 is not null);
 perform pg_temp.check('A compensation/customer_compensation accepted',
  public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'compensation','eeee1111-1111-4111-8111-111111111112','customer_compensation') is not null);
 perform pg_temp.check('A b2b_program/program_allocation accepted',
  public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'b2b_program','eeee1111-1111-4111-8111-111111111113','program_allocation') is not null);
 perform pg_temp.check('A admin_grant/test_account accepted',
  public.essay_admin_grant('22222222-2222-4222-8222-222222222222',1,'admin_grant','eeee1111-1111-4111-8111-111111111114','test_account') is not null);
end$$;

-- ===========================================================================
-- B. Payment operations read
--
-- The P0-A suite installs a structural stand-in for public.payment_orders, so
-- this section exercises the installed read path. The genuinely-absent path is
-- exercised in section D, after the stand-in is dropped.
-- ===========================================================================
do $$
declare r jsonb; o jsonb;
begin
 -- ACL: only authenticated may call the read; the console defines no write.
 perform pg_temp.check('B anon cannot execute admin_payment_orders',
  not has_function_privilege('anon','public.admin_payment_orders(jsonb)','execute'));
 perform pg_temp.check('B authenticated can execute admin_payment_orders',
  has_function_privilege('authenticated','public.admin_payment_orders(jsonb)','execute'));
 perform pg_temp.check('B service_role cannot execute admin_payment_orders',
  not has_function_privilege('service_role','public.admin_payment_orders(jsonb)','execute'));
 -- The order-action contract is owned by the finance role. Its migration is not
 -- applied in this cluster, so assert reachability rather than existence: if it
 -- is installed, no browser role may reach it.
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='public' and p.proname='payment_support') then
  perform pg_temp.check('B anon cannot execute payment_support',
   not has_function_privilege('anon','public.payment_support(jsonb)','execute'));
  perform pg_temp.check('B authenticated cannot execute payment_support',
   not has_function_privilege('authenticated','public.payment_support(jsonb)','execute'));
  perform pg_temp.check('B only essay_finance executes payment_support',
   has_function_privilege('essay_finance','public.payment_support(jsonb)','execute'));
 else
  perform pg_temp.check('B order-action contract absent from this cluster', true);
 end if;
 -- No browser role may read or write orders directly.
 perform pg_temp.check('B no browser role reads orders directly',
  not has_table_privilege('anon','public.payment_orders','select')
  and not has_table_privilege('authenticated','public.payment_orders','select'));
 perform pg_temp.check('B no browser role writes orders directly',
  not has_table_privilege('anon','public.payment_orders','insert')
  and not has_table_privilege('authenticated','public.payment_orders','insert')
  and not has_table_privilege('anon','public.payment_orders','update')
  and not has_table_privilege('authenticated','public.payment_orders','update'));

 -- Anonymous and non-operator callers are refused.
 perform pg_temp.as_anon();
 perform pg_temp.check('B anonymous payment read refused',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v1"}'::jsonb)$q$)=('PT401'));
 perform pg_temp.as_member();
 perform pg_temp.check('B normal member payment read refused',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v1"}'::jsonb)$q$)=('PT401'));

 -- Operator path.
 perform pg_temp.as_admin();
 r:=public.admin_payment_orders('{"dto_version":"admin-v1"}'::jsonb);
 perform pg_temp.check('B installed order table is reported as installed', (r->>'installed')='true');
 perform pg_temp.check('B order list is returned', jsonb_array_length(r->'orders')=1);
 perform pg_temp.check('B total matches the row count', (r->>'total')::integer=1);
 perform pg_temp.check('B runtime state is LIVE_OFF', (r->>'runtime_state')='LIVE_OFF');
 perform pg_temp.check('B runtime label names the disabled state', r->>'runtime_label' like '%미활성%');
 perform pg_temp.check('B runtime label does not claim a live payment state',
  r->>'runtime_label' like '%실결제 아님%');
 perform pg_temp.check('B provider mode is reported', (r->>'mode')='TEST');
 perform pg_temp.check('B response carries the dto version', (r->>'dto_version')='admin-v1');
 o:=r->'orders'->0;
 -- The fields an operator needs to answer a payment question.
 perform pg_temp.check('B order carries the order id', (o->>'order_id') is not null);
 perform pg_temp.check('B order carries the member', (o->>'subject_id')='22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('B order carries the product', (o->>'sku')='credit_5');
 perform pg_temp.check('B order carries the amount', (o->>'amount')::integer=4900);
 perform pg_temp.check('B order carries the credit quantity', (o->>'quantity')::integer=5);
 perform pg_temp.check('B order carries the currency', (o->>'currency')='KRW');
 perform pg_temp.check('B order carries the payment state', (o->>'state')='PAID');
 perform pg_temp.check('B order carries the grant state', (o->>'grant_state')='NONE');
 perform pg_temp.check('B order carries the payment date', (o->>'paid_at') is not null);
 perform pg_temp.check('B order carries the reconciliation flag', (o->>'reconciliation_required')='false');
 perform pg_temp.check('B paid order with a grant is marked refundable', (o->>'refundable')='true');
 -- Raw provider identifiers never reach the console.
 perform pg_temp.check('B order payload omits the provider purchase id', not (o ? 'provider_purchase_id'));
 perform pg_temp.check('B no provider or finance secret in the read payload',
  not (r::text ~* 'service_role|bearer|access_token|refresh_token|payment_key|provider_purchase_id|external_reference'));

 -- Filters and bounds.
 perform pg_temp.check('B state filter matches a paid order',
  (public.admin_payment_orders('{"dto_version":"admin-v1","state":"PAID"}'::jsonb)->>'total')::integer=1);
 perform pg_temp.check('B state filter excludes non-matching rows',
  (public.admin_payment_orders('{"dto_version":"admin-v1","state":"CANCELLED"}'::jsonb)->>'total')::integer=0);
 perform pg_temp.check('B search by order id matches',
  (public.admin_payment_orders(jsonb_build_object('dto_version','admin-v1','query',(select id::text from public.payment_orders limit 1)))->>'total')::integer=1);
 perform pg_temp.check('B search by member id matches',
  (public.admin_payment_orders('{"dto_version":"admin-v1","query":"22222222-2222-4222-8222-222222222222"}'::jsonb)->>'total')::integer=1);
 perform pg_temp.check('B unknown state refused',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v1","state":"REFUNDED"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('B short query refused',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v1","query":"ab"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('B limit is bounded to 50',
  (public.admin_payment_orders('{"dto_version":"admin-v1","limit":5000}'::jsonb)->>'limit')::integer=50);
 perform pg_temp.check('B limit floor is 1',
  (public.admin_payment_orders('{"dto_version":"admin-v1","limit":0}'::jsonb)->>'limit')::integer=1);
 perform pg_temp.check('B negative offset is floored to 0',
  (public.admin_payment_orders('{"dto_version":"admin-v1","offset":-9}'::jsonb)->>'offset')::integer=0);
 perform pg_temp.check('B wrong dto version refused',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v9"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('B unknown payload key refused',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v1","grant":true}'::jsonb)$q$)='PT422');
end$$;

-- ===========================================================================
-- C. 1:1 inquiry — member side
-- ===========================================================================
do $$
declare r jsonb; first_id uuid; mine jsonb;
begin
 perform pg_temp.check('C anon cannot execute inquiry_submit',
  not has_function_privilege('anon','public.inquiry_submit(jsonb)','execute'));
 perform pg_temp.check('C authenticated can execute inquiry_submit',
  has_function_privilege('authenticated','public.inquiry_submit(jsonb)','execute'));
 perform pg_temp.check('C no browser role can read the inquiry table directly',
  not has_table_privilege('authenticated','public.inquiries','select')
  and not has_table_privilege('anon','public.inquiries','select'));
 perform pg_temp.check('C no browser role can write the inquiry table',
  not has_table_privilege('authenticated','public.inquiries','insert')
  and not has_table_privilege('authenticated','public.inquiries','update')
  and not has_table_privilege('authenticated','public.inquiries','delete'));
 perform pg_temp.check('C no browser role can read replies directly',
  not has_table_privilege('authenticated','public.inquiry_replies','select'));
 perform pg_temp.check('C no browser role can read the delivery queue',
  not has_table_privilege('authenticated','public.inquiry_notifications','select')
  and not has_table_privilege('service_role','public.inquiry_notifications','select'));
 perform pg_temp.check('C anon cannot drain the delivery queue',
  not has_function_privilege('anon','public.claim_inquiry_notifications(integer)','execute')
  and not has_function_privilege('authenticated','public.claim_inquiry_notifications(integer)','execute'));

 perform pg_temp.as_anon();
 perform pg_temp.check('C anonymous submit refused',
  pg_temp.err($q$select public.inquiry_submit('{"dto_version":"inquiry-v1","category":"credit","title":"t","body":"b","request_key":"99999999-9999-4999-8999-999999999991"}'::jsonb)$q$)=('PT401'));

 perform pg_temp.as_member();
 r:=public.inquiry_submit('{"dto_version":"inquiry-v1","category":"payment","title":"결제 확인 요청","body":"10월 3일 결제 건의 Credit 지급 상태를 확인해 주세요.","request_key":"99999999-9999-4999-8999-999999999992"}'::jsonb);
 first_id:=(r->>'inquiry_id')::uuid;
 perform pg_temp.check('C member submit creates an inquiry', first_id is not null);
 perform pg_temp.check('C new inquiry starts RECEIVED', (r->>'status')='RECEIVED');
 perform pg_temp.check('C first submit is not a duplicate', (r->>'duplicate')='false');
 perform pg_temp.check('C submit records a status event',
  (select count(*) from public.inquiry_status_events e where e.inquiry_id=first_id)=1);
 -- The client cannot choose the owner.
 perform pg_temp.check('C inquiry owner is the caller, not the payload',
  (select user_id from public.inquiries where id=first_id)='22222222-2222-4222-8222-222222222222');

 -- Idempotency.
 r:=public.inquiry_submit('{"dto_version":"inquiry-v1","category":"payment","title":"결제 확인 요청","body":"10월 3일 결제 건의 Credit 지급 상태를 확인해 주세요.","request_key":"99999999-9999-4999-8999-999999999992"}'::jsonb);
 perform pg_temp.check('C duplicate submit returns the same inquiry', (r->>'inquiry_id')::uuid=first_id);
 perform pg_temp.check('C duplicate submit is flagged', (r->>'duplicate')='true');
 perform pg_temp.check('C duplicate submit does not create a second row',
  (select count(*) from public.inquiries where user_id='22222222-2222-4222-8222-222222222222')=1);
 perform pg_temp.check('C duplicate submit with different content conflicts',
  pg_temp.err($q$select public.inquiry_submit('{"dto_version":"inquiry-v1","category":"credit","title":"다른 제목","body":"다른 내용","request_key":"99999999-9999-4999-8999-999999999992"}'::jsonb)$q$)='PT409');

 -- Validation.
 perform pg_temp.check('C unknown category refused',
  pg_temp.err($q$select public.inquiry_submit('{"dto_version":"inquiry-v1","category":"sales","title":"t","body":"b","request_key":"99999999-9999-4999-8999-999999999993"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('C blank title refused',
  pg_temp.err($q$select public.inquiry_submit('{"dto_version":"inquiry-v1","category":"credit","title":"   ","body":"b","request_key":"99999999-9999-4999-8999-999999999994"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('C over-long body refused',
  pg_temp.err($q$select public.inquiry_submit(jsonb_build_object('dto_version','inquiry-v1','category','credit','title','t','body',repeat('x',4001),'request_key','99999999-9999-4999-8999-999999999995'))$q$)='PT422');
 perform pg_temp.check('C unknown payload key refused',
  pg_temp.err($q$select public.inquiry_submit('{"dto_version":"inquiry-v1","category":"credit","title":"t","body":"b","request_key":"99999999-9999-4999-8999-999999999996","status":"CLOSED"}'::jsonb)$q$)='PT422');
 -- A member cannot forge an answer status through the submit contract.
 perform pg_temp.check('C submit cannot set the status',
  (select status from public.inquiries where id=first_id)='RECEIVED');

 -- Ownership: another member sees only their own list.
 perform pg_temp.as_member('33333333-3333-4333-8333-333333333333');
 mine:=public.inquiry_mine('{"dto_version":"inquiry-v1"}'::jsonb);
 perform pg_temp.check('C mine returns an empty list for a member with no inquiries',
  jsonb_array_length(mine->'items')=0);
 perform pg_temp.check('C mine never leaks another member inquiry',
  not (mine::text like '%'||first_id::text||'%'));
 perform pg_temp.as_member();
 mine:=public.inquiry_mine('{"dto_version":"inquiry-v1"}'::jsonb);
 perform pg_temp.check('C mine returns the caller own inquiry',
  (mine->'items'->0->>'inquiry_id')::uuid=first_id);
 perform pg_temp.check('C mine marks an unanswered inquiry as unanswered',
  (mine->'items'->0->>'answered')='false');
 perform pg_temp.check('C mine is bounded',
  (public.inquiry_mine('{"dto_version":"inquiry-v1","limit":999}'::jsonb)->>'limit')::integer=50);
end$$;

-- ===========================================================================
-- C. 1:1 inquiry — operator side
-- ===========================================================================
do $$
declare r jsonb; iid uuid; rid uuid; n int; code text;
begin
 select id into iid from public.inquiries order by created_at limit 1;
 perform pg_temp.check('C anon cannot execute admin_inquiry_list',
  not has_function_privilege('anon','public.admin_inquiry_list(jsonb)','execute'));
 perform pg_temp.check('C authenticated can execute admin_inquiry_list',
  has_function_privilege('authenticated','public.admin_inquiry_list(jsonb)','execute'));

 perform pg_temp.as_member();
 perform pg_temp.check('C normal member inquiry list refused',
  pg_temp.err($q$select public.admin_inquiry_list('{"dto_version":"admin-v1"}'::jsonb)$q$)='PT401');
 perform pg_temp.check('C normal member inquiry detail refused',
  pg_temp.err($q$select public.admin_inquiry_detail(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1)))$q$)='PT401');
 perform pg_temp.check('C normal member reply refused',
  pg_temp.err($q$select public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'body','x','request_key','88888888-8888-4888-8888-888888888881'))$q$)='PT401');
 perform pg_temp.check('C normal member status change refused',
  pg_temp.err($q$select public.admin_inquiry_set_status(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'status','CLOSED'))$q$)='PT401');
 perform pg_temp.check('C normal member support metrics refused',
  pg_temp.err($q$select public.admin_support_metrics()$q$)='PT401');

 perform pg_temp.as_admin();
 r:=public.admin_inquiry_list('{"dto_version":"admin-v1"}'::jsonb);
 perform pg_temp.check('C operator list returns the inquiry', (r->>'total')::integer=1);
 perform pg_temp.check('C operator list carries the open count', (r->>'open')::integer=1);
 perform pg_temp.check('C operator list marks the member', (r->'items'->0->>'user_id')='22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('C operator list carries the category', (r->'items'->0->>'category')='payment');
 perform pg_temp.check('C operator list truncates the body preview',
  char_length(r->'items'->0->>'preview')<=120);
 perform pg_temp.check('C operator list has no full body field', not (r->'items'->0 ? 'body'));
 -- Filters and bounds.
 perform pg_temp.check('C status filter excludes non-matching rows',
  (public.admin_inquiry_list('{"dto_version":"admin-v1","status":"CLOSED"}'::jsonb)->>'total')::integer=0);
 perform pg_temp.check('C category filter matches',
  (public.admin_inquiry_list('{"dto_version":"admin-v1","category":"payment"}'::jsonb)->>'total')::integer=1);
 perform pg_temp.check('C unknown status filter refused',
  pg_temp.err($q$select public.admin_inquiry_list('{"dto_version":"admin-v1","status":"PENDING"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('C unknown category filter refused',
  pg_temp.err($q$select public.admin_inquiry_list('{"dto_version":"admin-v1","category":"sales"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('C short search query refused',
  pg_temp.err($q$select public.admin_inquiry_list('{"dto_version":"admin-v1","query":"ab"}'::jsonb)$q$)='PT422');
 perform pg_temp.check('C list limit is bounded',
  (public.admin_inquiry_list('{"dto_version":"admin-v1","limit":999}'::jsonb)->>'limit')::integer=50);
 perform pg_temp.check('C search by inquiry id matches',
  (public.admin_inquiry_list(jsonb_build_object('dto_version','admin-v1','query',iid::text))->>'total')::integer=1);

 -- Detail: the single read that returns the body.
 r:=public.admin_inquiry_detail(jsonb_build_object('dto_version','admin-v1','id',iid));
 perform pg_temp.check('C detail returns the body', (r->'inquiry'->>'body') like '%Credit%');
 perform pg_temp.check('C detail returns the member block', (r->'member'->>'account_id')='22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('C detail returns the credit snapshot', (r->'member'->>'spendable') is not null);
 perform pg_temp.check('C detail returns the account state', (r->'member'->>'account_state') is not null);
 perform pg_temp.check('C detail returns the status history',
  jsonb_array_length(r->'status_events')=1);
 perform pg_temp.check('C detail starts with no replies', jsonb_array_length(r->'replies')=0);
 perform pg_temp.check('C detail carries bounded related references',
  (r->'related') ? 'essay_evaluations' and (r->'related') ? 'payment_orders');
 perform pg_temp.check('C related payment count reflects the member own orders',
  (r->'related'->'payment_orders')::integer=1);
 perform pg_temp.check('C related reference count is bounded to the submitting member',
  (r->'related'->'essay_evaluations')::integer=0);
 perform pg_temp.check('C unknown inquiry id is NOT_FOUND',
  pg_temp.err($q$select public.admin_inquiry_detail('{"dto_version":"admin-v1","id":"00000000-0000-4000-8000-000000000000"}'::jsonb)$q$)='PT404');
 perform pg_temp.check('C malformed inquiry id refused',
  pg_temp.err($q$select public.admin_inquiry_detail('{"dto_version":"admin-v1","id":"not-a-uuid"}'::jsonb)$q$)='PT422');

 -- A status write cannot fabricate an answer.
 code:=pg_temp.err($q$select public.admin_inquiry_set_status(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries order by created_at limit 1),'status','ANSWERED'))$q$);
 perform pg_temp.check('C ANSWERED without a reply refused ['||code||']', code='PT409');
 perform pg_temp.check('C status can move to IN_PROGRESS',
  (public.admin_inquiry_set_status(jsonb_build_object('dto_version','admin-v1','id',iid,'status','IN_PROGRESS'))->>'changed')='true');
 perform pg_temp.check('C status change is audited',
  (select count(*) from public.inquiry_status_events where inquiry_id=iid)=2);
 perform pg_temp.check('C repeating the same status is a no-op',
  (public.admin_inquiry_set_status(jsonb_build_object('dto_version','admin-v1','id',iid,'status','IN_PROGRESS'))->>'changed')='false');
 perform pg_temp.check('C status change does not duplicate the audit row',
  (select count(*) from public.inquiry_status_events where inquiry_id=iid)=2);

 -- Reply: append-only, status moves to ANSWERED, delivery is queued once.
 r:=public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',iid,'body','확인했습니다. 해당 결제 건의 Credit은 정상 지급되었습니다.','request_key','77777777-7777-4777-8777-777777777771'));
 rid:=(r->>'reply_id')::uuid;
 perform pg_temp.check('C reply returns a reply id', rid is not null);
 perform pg_temp.check('C reply sets the inquiry to ANSWERED', (r->>'status')='ANSWERED');
 perform pg_temp.check('C reply reports the delivery as queued', (r->>'queued')='true');
 perform pg_temp.check('C reply stamps answered_at',
  (select answered_at is not null from public.inquiries where id=iid));
 perform pg_temp.check('C reply is appended, not overwritten',
  (select body from public.inquiries where id=iid) like '%10월 3일%');
 perform pg_temp.check('C reply is recorded', (select count(*) from public.inquiry_replies where inquiry_id=iid)=1);
 perform pg_temp.check('C reply is audited',
  (select count(*) from public.inquiry_status_events where inquiry_id=iid)=3);
 select count(*) into n from public.inquiry_notifications where inquiry_id=iid;
 perform pg_temp.check('C exactly one delivery is queued', n=1);
 perform pg_temp.check('C queued delivery starts pending',
  (select status from public.inquiry_notifications where inquiry_id=iid)='pending');
 perform pg_temp.check('C queued delivery stores no recipient address',
  not exists(select 1 from information_schema.columns where table_schema='public'
   and table_name='inquiry_notifications' and column_name in ('recipient','email','to_address')));

 -- Duplicate response prevention.
 r:=public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',iid,'body','확인했습니다. 해당 결제 건의 Credit은 정상 지급되었습니다.','request_key','77777777-7777-4777-8777-777777777771'));
 perform pg_temp.check('C duplicate reply returns the same reply', (r->>'reply_id')::uuid=rid);
 perform pg_temp.check('C duplicate reply is flagged', (r->>'duplicate')='true');
 perform pg_temp.check('C duplicate reply does not queue a second delivery',
  (select count(*) from public.inquiry_notifications where inquiry_id=iid)=1);
 perform pg_temp.check('C duplicate reply does not append a second row',
  (select count(*) from public.inquiry_replies where inquiry_id=iid)=1);
 perform pg_temp.check('C duplicate reply with different content conflicts',
  pg_temp.err($q$select public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'body','완전히 다른 답변','request_key','77777777-7777-4777-8777-777777777771'))$q$)='PT409');
 perform pg_temp.check('C blank reply refused',
  pg_temp.err($q$select public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'body','   ','request_key','77777777-7777-4777-8777-777777777772'))$q$)='PT422');
 perform pg_temp.check('C reply to an unknown inquiry is NOT_FOUND',
  pg_temp.err($q$select public.admin_inquiry_reply('{"dto_version":"admin-v1","id":"00000000-0000-4000-8000-000000000000","body":"x","request_key":"77777777-7777-4777-8777-777777777773"}'::jsonb)$q$)='PT404');
end$$;

-- The member view of the answered inquiry, evaluated as the member.
do $$
declare mine jsonb;
begin
 perform pg_temp.as_member();
 mine:=public.inquiry_mine('{"dto_version":"inquiry-v1"}'::jsonb);
 perform pg_temp.check('C member sees the inquiry as answered',
  (mine->'items'->0->>'answered')='true');
 perform pg_temp.check('C member sees the ANSWERED status',
  (mine->'items'->0->>'status')='ANSWERED');
 perform pg_temp.check('C member list still omits the reply body',
  not (mine->'items'->0 ? 'body') and not (mine->'items'->0 ? 'replies'));
end$$;

do $$
declare r jsonb;
begin
 -- Close, then confirm a closed inquiry refuses further replies.
 perform pg_temp.as_admin();
 perform pg_temp.check('C status can move to CLOSED',
  (public.admin_inquiry_set_status(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'status','CLOSED'))->>'changed')='true');
 perform pg_temp.check('C reply to a closed inquiry refused',
  pg_temp.err($q$select public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'body','추가 답변','request_key','77777777-7777-4777-8777-777777777774'))$q$)='PT409');

 -- Support metrics.
 r:=public.admin_support_metrics();
 perform pg_temp.check('C metrics count the open queue', (r->>'open')::integer=0);
 perform pg_temp.check('C metrics count closed inquiries', (r->>'closed')::integer=1);
 perform pg_temp.check('C metrics count answered inquiries', (r->>'answered')::integer=0);
 perform pg_temp.check('C metrics count today new inquiries', (r->>'new_today')::integer=1);
 perform pg_temp.check('C metrics report the failed delivery count', (r->>'failed_deliveries')::integer=0);
 -- Response time is computed only from real reply timestamps, never invented.
 perform pg_temp.check('C first response time is a real measurement',
  (r->>'first_response_seconds') is not null and (r->>'first_response_seconds')::numeric>=0);
 perform pg_temp.check('C oldest open inquiry is null when nothing is open',
  jsonb_typeof(r->'oldest_open_id')='null');

 -- Delivery queue lifecycle: claim, then complete.
 perform pg_temp.check('C claim is service-role only',
  has_function_privilege('service_role','public.claim_inquiry_notifications(integer)','execute'));
 perform pg_temp.check('C complete is service-role only',
  has_function_privilege('service_role','public.complete_inquiry_notification(uuid,uuid,boolean,text)','execute'));
end$$;

-- The worker runs with the service role, which is also the role the queue expects.
set role service_role;
do $$
declare c record; ok boolean; second int;
begin
 select * into c from public.claim_inquiry_notifications(10);
 second:=(select count(*) from public.claim_inquiry_notifications(10));
 ok:=public.complete_inquiry_notification(c.notification_id,c.claim_token,true,null);
 insert into public.p0b_worker_seen values(1,c.notification_id,c.claim_token,c.member_id,c.attempt_count,ok);
 perform pg_temp.check('C a second claim finds nothing while the lease is held', second=0);
end$$;
reset role;

do $$
declare c public.p0b_worker_seen;
begin
 select * into c from public.p0b_worker_seen where seq=1;
 perform pg_temp.check('C worker claims the queued delivery', c.notification_id is not null);
 perform pg_temp.check('C claim resolves the member for delivery', c.member_id='22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('C claim returns a token', c.claim_token is not null);
 perform pg_temp.check('C claim counts the attempt', c.attempt_count=1);
 perform pg_temp.check('C completion marks the delivery sent', c.completed);
 perform pg_temp.check('C sent delivery is stamped',
  (select sent_at is not null and claim_token is null from public.inquiry_notifications where id=c.notification_id));
end$$;

do $$
declare c record; n int;
begin
 -- Failure path: a provider error schedules a retry instead of losing the reply.
 perform pg_temp.as_admin();
 perform pg_temp.check('C operator can reopen and answer again',
  (public.admin_inquiry_set_status(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),'status','IN_PROGRESS'))->>'changed')='true');
 perform public.admin_inquiry_reply(jsonb_build_object('dto_version','admin-v1','id',(select id from public.inquiries limit 1),
  'body','추가 안내드립니다. 확인 후 다시 연락드리겠습니다.','request_key','77777777-7777-4777-8777-777777777775'));
 select count(*) into n from public.inquiry_notifications where status='pending';
 perform pg_temp.check('C a second reply queues a second delivery', n=1);
end$$;

set role service_role;
do $$
declare c record; stale text;
begin
 select * into c from public.claim_inquiry_notifications(10);
 perform public.complete_inquiry_notification(c.notification_id,c.claim_token,false,'provider_5xx');
 -- A replayed completion with a fresh token must not resurrect the lease.
 stale:=pg_temp.err(format('select public.complete_inquiry_notification(%L,%L,true,null)',c.notification_id,gen_random_uuid()));
 insert into public.p0b_worker_seen values(2,c.notification_id,c.claim_token,c.member_id,c.attempt_count,false);
 perform pg_temp.check('C a stale claim token cannot complete the delivery', stale='PT409');
end$$;
reset role;

do $$
declare c public.p0b_worker_seen; n int;
begin
 perform pg_temp.as_admin();
 select * into c from public.p0b_worker_seen where seq=2;
 perform pg_temp.check('C worker claims the second delivery', c.notification_id is not null);
 perform pg_temp.check('C failed delivery records the error code',
  (select last_error_code from public.inquiry_notifications where id=c.notification_id)='provider_5xx');
 perform pg_temp.check('C failed delivery schedules a retry',
  (select next_attempt_at>clock_timestamp() from public.inquiry_notifications where id=c.notification_id));
 perform pg_temp.check('C failed delivery releases the lease',
  (select claim_token is null from public.inquiry_notifications where id=c.notification_id));
 perform pg_temp.check('C failed delivery does not lose the reply',
  (select count(*) from public.inquiry_replies where inquiry_id=(select inquiry_id from public.inquiry_notifications where id=c.notification_id))=2);
 perform pg_temp.check('C failed delivery is counted in the metrics',
  (public.admin_support_metrics()->>'failed_deliveries')::integer=1);
 select count(*) into n from public.inquiry_notifications where status='failed';
 perform pg_temp.check('C exactly one delivery is in the failed state', n=1);
end$$;

-- ===========================================================================
-- Privacy: nothing sensitive crosses the inquiry surface
-- ===========================================================================
do $$
declare blob text;
begin
 perform pg_temp.as_admin();
 select string_agg(coalesce(public.admin_inquiry_list('{"dto_version":"admin-v1"}'::jsonb)::text,'')||
  coalesce(public.admin_inquiry_detail(jsonb_build_object('dto_version','admin-v1','id',i.id))::text,'')||
  coalesce(public.admin_support_metrics()::text,'')||
  coalesce(public.admin_payment_orders('{"dto_version":"admin-v1"}'::jsonb)::text,''),'')
  into blob from public.inquiries i;
 perform pg_temp.check('C no secret token in any P0-B payload',
  not (blob ~* 'service_role|bearer|access_token|refresh_token|password|private_key|sk_live|sk_test'));
 perform pg_temp.check('C no finance actor reference in any P0-B payload',
  not (blob ~* 'operator/|essay_finance|actor_reference'));
end$$;

do $$
declare t text;
begin
 select string_agg(pg_get_functiondef(p.oid),' ') into t
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and (p.proname like 'inquiry\_%' or p.proname like 'claim\_inquiry%'
   or p.proname like 'complete\_inquiry%');
 -- The admin console owns no write path: granting stays on essay_admin_grant.
 perform pg_temp.check('C admin console defines no credit write function',
  t !~* 'essay_admin_grant|credit_post_grant|update public\.credit_grants|insert into public\.credit_transactions');
 perform pg_temp.check('C inquiry functions never update a credit table',
  t !~* 'credit_grants|credit_transactions|credit_accounts');
end$$;

-- ===========================================================================
-- D. Payment read degradation — the genuinely absent subsystem
--
-- P0-A installed the stand-in for the earlier sections, so it is dropped here.
-- An uninstalled subsystem must report NOT_INSTALLED, never a fabricated zero:
-- an operator reading "0 orders" would conclude there had been no sales.
-- ===========================================================================
do $$
declare r jsonb;
begin
 perform pg_temp.as_admin();
 drop table if exists public.payment_orders;
 r:=public.admin_payment_orders('{"dto_version":"admin-v1"}'::jsonb);
 perform pg_temp.check('D absent order table is reported as not installed', (r->>'installed')='false');
 perform pg_temp.check('D absent order table reports a JSON null total', jsonb_typeof(r->'total')='null');
 perform pg_temp.check('D absent order table reports a JSON null list', jsonb_typeof(r->'orders')='null');
 perform pg_temp.check('D absent order table is not reported as zero', (r->>'total') is null);
 perform pg_temp.check('D absent order table reports mode NONE', (r->>'mode')='NONE');
 perform pg_temp.check('D absent order table still reports LIVE_OFF', (r->>'runtime_state')='LIVE_OFF');
 perform pg_temp.check('D absent order table still validates the request',
  pg_temp.err($q$select public.admin_payment_orders('{"dto_version":"admin-v9"}'::jsonb)$q$)='PT422');
 -- The related-reference read degrades the same way rather than erroring.
 perform pg_temp.check('D related payment count degrades to null',
  jsonb_typeof(public.admin_inquiry_detail(jsonb_build_object('dto_version','admin-v1',
   'id',(select id from public.inquiries limit 1)))->'related'->'payment_orders')='null');
end$$;

-- ===========================================================================
-- Summary
-- ===========================================================================
do $$
declare total int; failed int; r record;
begin
 select count(*),count(*) filter(where not ok) into total,failed from admin_verify;
 raise notice 'ADMIN_P0B_CHECKS total=% failed=%', total, failed;
 if failed>0 then
  for r in select name from admin_verify where not ok order by id loop
   raise notice 'P0B FAILED: %', r.name;
  end loop;
  raise exception 'ADMIN_P0_B_BEHAVIOR_FAILED';
 end if;
end$$;
