-- DRAFT ONLY / NOT APPLIED. Logical subsystem separate from student learning data.
-- Ledger posting/locking/RPC implementation is deliberately NOT included.
-- No prices, provider, IAP, attempt-number pricing or initial free allocation.
begin;
create table public.credit_accounts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid unique references public.profiles(id) on delete set null,
 created_at timestamptz not null default now()
 -- Account survives learning/account deletion without profile PII.
 -- Future organization principal + explicit entitlement membership lives here, not in essays.
);
create table public.credit_grants (
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.credit_accounts(id) on delete restrict,
 origin text not null check (origin in ('purchase','promotion','admin_grant')),
 external_reference text unique, -- opaque reconciled receipt/grant ID only, no payment payload
 expires_at timestamptz,
 created_at timestamptz not null default now(),
 unique(id,account_id)
);
create table public.essay_billing_decisions (
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.credit_accounts(id) on delete restrict,
 evaluation_id uuid unique references public.essay_evaluations(id) on delete set null,
 idempotency_key uuid not null unique,
 policy_version text not null,
 reason text not null check (reason in ('paid_cycle','included_revision','promotion','subscription','institution','admin_grant','technical_reevaluation')),
 credits_required integer not null check (credits_required >= 0),
 status text not null check (status in ('authorized','reserved','settled','released','rejected')),
 included_by_decision_id uuid,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(id,account_id),
 foreign key(included_by_decision_id,account_id) references public.essay_billing_decisions(id,account_id) on delete restrict,
 check (included_by_decision_id is distinct from id)
);
-- Number of included revisions is application policy; no DB uniqueness imposing one forever.
create table public.credit_transactions (
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.credit_accounts(id) on delete restrict,
 grant_id uuid not null,
 decision_id uuid,
 transaction_type text not null check (transaction_type in ('purchase','promotion','admin_grant','reserve','consume','release','refund','expiration','adjustment')),
 balance_delta integer not null,
 reserved_delta integer not null,
 idempotency_key text not null unique,
 reversal_of uuid,
 reason_code text not null,
 actor_reference text, -- pseudonymous audit principal, no free-form PII
 created_at timestamptz not null default now(),
 foreign key(grant_id,account_id) references public.credit_grants(id,account_id) on delete restrict,
 foreign key(decision_id,account_id) references public.essay_billing_decisions(id,account_id) on delete restrict,
 check (
  (transaction_type in ('purchase','promotion','admin_grant','refund') and balance_delta > 0 and reserved_delta = 0)
  or (transaction_type = 'reserve' and balance_delta = 0 and reserved_delta > 0 and decision_id is not null)
  or (transaction_type = 'consume' and balance_delta < 0 and reserved_delta = balance_delta and decision_id is not null)
  or (transaction_type = 'release' and balance_delta = 0 and reserved_delta < 0 and decision_id is not null)
  or (transaction_type = 'expiration' and balance_delta < 0 and reserved_delta = 0)
  or (transaction_type = 'adjustment' and balance_delta <> 0 and reserved_delta = 0)
 ),
 check (transaction_type <> 'refund' or reversal_of is not null),
 unique(id,account_id),
 foreign key(reversal_of,account_id) references public.credit_transactions(id,account_id) on delete restrict
);
create index credit_transactions_account_time on public.credit_transactions(account_id,created_at,id);
create index credit_transactions_grant on public.credit_transactions(grant_id);
create index essay_billing_pending on public.essay_billing_decisions(updated_at) where status in ('authorized','reserved');
create trigger credit_ledger_no_update before update on public.credit_transactions for each row execute function public.essay_product_reject_update();
-- Retention/erasure cannot modify the ledger; account.user_id and decision.evaluation_id
-- alone detach with SET NULL. No immutable-update trigger on these detachable links.
alter table public.credit_accounts enable row level security;
revoke all on public.credit_accounts from public, anon, authenticated;
grant select on public.credit_accounts to authenticated;
create policy credit_accounts_owner_read on public.credit_accounts for select to authenticated using (user_id = (select auth.uid()));
grant select, insert, update on public.credit_accounts to service_role;
alter table public.credit_grants enable row level security;
revoke all on public.credit_grants from public, anon, authenticated;
grant select on public.credit_grants to authenticated;
create policy credit_grants_owner_read on public.credit_grants for select to authenticated using (exists (select 1 from public.credit_accounts a where a.id = credit_grants.account_id and a.user_id = (select auth.uid())));
grant select, insert, update on public.credit_grants to service_role;
alter table public.essay_billing_decisions enable row level security;
revoke all on public.essay_billing_decisions from public, anon, authenticated;
grant select on public.essay_billing_decisions to authenticated;
create policy essay_billing_decisions_owner_read on public.essay_billing_decisions for select to authenticated using (exists (select 1 from public.credit_accounts a where a.id = essay_billing_decisions.account_id and a.user_id = (select auth.uid())));
grant select, insert, update on public.essay_billing_decisions to service_role;
alter table public.credit_transactions enable row level security;
revoke all on public.credit_transactions from public, anon, authenticated;
grant select on public.credit_transactions to authenticated;
create policy credit_transactions_owner_read on public.credit_transactions for select to authenticated using (exists (select 1 from public.credit_accounts a where a.id = credit_transactions.account_id and a.user_id = (select auth.uid())));
grant select, insert on public.credit_transactions to service_role;
commit;
