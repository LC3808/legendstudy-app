-- READ ONLY. Empty Hosted TEST fixture verification, not a Production balance rule.
-- Historical baseline was zero; sums here are deltas for this bounded fixture only.
with classified as (
 select t.*,g.origin,a.user_id,
 (g.origin='signup_bonus' and t.transaction_type='signup_bonus'
  and t.account_id=g.account_id and g.external_reference='signup_bonus/'||a.user_id::text
  and t.idempotency_key='grant/'||g.external_reference
  and t.reason_code='signup_bonus_v1' and t.actor_reference='system/signup_bonus'
  and t.decision_id is null and g.expires_at is null) as canonical_signup,
 (g.origin='purchase' or g.external_reference like 'payment/%'
  or t.idempotency_key like 'grant/payment/%' or t.actor_reference='system/payment'
  or exists(select 1 from public.payment_orders o where o.grant_id=g.id)) as payment_linked
 from public.credit_transactions t
 join public.credit_grants g on g.id=t.grant_id
 join public.credit_accounts a on a.id=g.account_id
)
select
 coalesce(sum(balance_delta) filter(where canonical_signup),0) as signup_bonus_delta,
 coalesce(sum(balance_delta-reserved_delta) filter(where payment_linked),0) as payment_attributable_spendable_delta,
 count(*) filter(where payment_linked) as payment_linked_postings,
 count(*) filter(where not canonical_signup and not payment_linked) as unexplained_postings,
 coalesce(sum(balance_delta) filter(where not canonical_signup and not payment_linked),0) as unexplained_delta,
 (select count(*) from public.credit_transactions)-count(*) as unclassified_postings,
 (select count(*) from public.credit_grants where origin='purchase') as purchase_grants,
 (select count(*) from public.payment_orders where grant_id is not null or grant_state='POSTED') as order_grant_links,
 (select count(*) from public.payment_orders where mode='LIVE') as live_orders,
 (select count(*) from public.payment_operations) as payment_operations,
 (select count(*) from public.payment_orders where provider_purchase_id is not null) as provider_purchase_links,
 (select count(*) from public.payment_events where event<>'CREATED' or operation_id is not null) as non_creation_events
from classified;
