-- Owner/operator SQL only after separately approved installation; never a browser RPC.
-- Bounded, read-only, no provider payload/key, identity, JWT or learning data.
begin read only;
set local statement_timeout='15s';
select o.id,o.mode,o.state,o.grant_state,o.sku,o.amount,o.quantity,
 o.paid_at,o.credit_expires_at,op.kind,op.state operation_state,
 op.created_at pending_since,op.amount operation_amount,op.error_code
from public.payment_orders o join public.payment_operations op on op.order_id=o.id
where op.state='PENDING' order by op.created_at,op.id limit 100;
with facts as (
 select o.id,o.mode,o.state,o.grant_state,o.amount,o.deduction_unit,o.grant_id,
 coalesce(sum(t.balance_delta) filter(where t.transaction_type in ('consume','refund')),0) net_use,
 coalesce(sum(t.balance_delta),0) remaining,
 coalesce(sum(t.reserved_delta),0) reserved,
 count(t.id) filter(where t.transaction_type='purchase') purchase_postings
 from public.payment_orders o left join public.credit_transactions t on t.grant_id=o.grant_id
 group by o.id
)
select id,mode,state,grant_state,remaining,reserved,purchase_postings,
 greatest(0,amount-greatest(0,-net_use)*deduction_unit) general_policy_amount_before_state_expiry_checks
from facts where (mode='TEST' and (grant_id is not null or purchase_postings<>0))
 or (mode='LIVE' and state in ('PAID','CANCEL_PENDING','CANCELLED','PARTIALLY_CANCELLED') and (grant_id is null or purchase_postings<>1))
 or remaining<0 or reserved<0
order by id limit 100;
commit;
