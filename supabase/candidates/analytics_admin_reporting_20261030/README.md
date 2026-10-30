> Codex integration review (2026-10-30): **NOT APPLIED**. 관리자 gate/ACL 정적 검증만 완료.
> 운영 적용 승인 전 현행 exam run/checkpoint 포함 여부, 가입 코호트와 주간 NSM 정의,
> 결제 환불/비용 통화 및 실제 스키마를 대조해야 한다. 아래 READY 표기는 승인용 후보
> 준비를 의미하며 운영 집계 정확성 PASS가 아니다. Owner 승인 없이 실행하지 않는다.

# Analytics Admin Reporting — Owner-apply candidate (2026-10-30)

**STATUS: READY_FOR_OWNER_REVIEW — NOT APPLIED.** Claude does not apply this to
Production (AGENTS §4). Owner reviews, applies `apply.sql`, runs `precheck.sql`
before and `postcheck.sql` after, and keeps `rollback.sql` ready.

## Purpose

Admin-gated, **read-only aggregate** reporting functions over EXISTING tables for
the LegendStudy Analytics v1.0 admin dashboard. No new fact/event table, no
schema change to existing tables, no change to the evaluation/credit/payment
contracts or ledger. Every function is `security definer`, `set search_path=''`,
returns aggregate JSON only (no row-level student data), and is gated by the
existing operational admin check.

Role split (wiki/analytics-p0-launch-contract.md): PostgreSQL is the **official
Source of Truth** for completion/failure/reprocessing, Credit, payment and
revenue. GA4 carries behaviour events only and is never the official count.

## Dependencies (verified to exist in committed migrations, except where noted)

- `public.admin_operator()` — operational admin gate. **Owner-applied; defined
  outside the committed migration tree** (used by `public.admin_member_list`,
  migration `20261008000900_admin_member_directory.sql`). `precheck.sql` asserts
  it exists before apply.
- `account_private.allowed(uuid)` — `20261001000300_account_deletion_lifecycle.sql`.
- Tables (all existing): `auth.users`, `public.profiles`, `public.universities`,
  `public.essay_exams`, `public.essay_questions`, `public.essay_practice_sessions`,
  `public.essay_attempts`, `public.essay_evaluations`, `public.essay_ai_processing_runs`,
  `public.credit_accounts`, `public.credit_grants`, `public.credit_transactions`,
  `public.essay_billing_decisions`, `public.payment_orders`, `public.payment_operations`.

## Functions (all `(p_from timestamptz, p_to timestamptz)` unless noted)

| Function | Returns (sections) |
|---|---|
| `public.analytics_admin_check()` | boolean — true when caller is an operational admin |
| `public.analytics_kpi_overview` | active DAU/WAU/MAU (서버 활동 기준), new signups, completed-eval users, free-eval users, paid buyers, revenue, eval success rate |
| `public.analytics_funnel` | signup → first submit → first completed eval → rewrite → full-loop(NSM); counts + conversion |
| `public.analytics_free_credit` | signup_bonus granted/used/exhausted, per-user avg, drop-off after 1/2/3, free→paid |
| `public.analytics_revenue` | by-sku count/revenue, buyers, AOV, ARPPU, repeat, refund, net (LIVE only) |
| `public.analytics_reliability` | eval requested/completed/failed, reprocess req/success, latency p50/p95, failure by question/exam, provider error buckets, credit integrity A/B/E/F |
| `public.analytics_api_cost` | by provider/model tokens, eval/reprocess call counts, per-eval est cost, daily total; `cost_basis` separates provider_reported vs estimate; null → 데이터 없음 |
| `public.analytics_university_usage` | sessions/attempts/completed by university |

## Definitions / assumptions for Owner validation

- **Active DAU/WAU/MAU = active *learners*** (submitted an attempt OR a completed
  student evaluation) in the trailing 1/7/30 days ending `p_to`. App-open DAU is a
  GA4 metric, not a DB fact; the dashboard labels this accordingly.
- **NSM (full loop)** = authenticated users with `essay_attempts.attempt_no=1`
  whose evaluation is `status='completed', request_kind='student'`, then a later
  `attempt_no>=2` in the same session whose student evaluation also completed.
  Provider retries (`essay_ai_processing_runs.run_no>1`) are **not** new attempts;
  operator re-evaluation (`request_kind='operator_reevaluation'`) is excluded.
- **Free vs paid credit:** a consume `credit_transactions` row joins its
  `grant_id → credit_grants.origin`. Free = `signup_bonus` (also `promotion`,
  `compensation`, `b2b_program`); paid = `purchase`. Signup +3 = the single
  `origin='signup_bonus'` grant per account (`credit_signup_once_per_account`).
- **Revenue = `payment_orders` with `state='PAID'` and `mode='LIVE'`** (TEST
  excluded). Amount/quantity/sku come from the row; refund = `payment_operations`
  `kind='CANCEL', state='SUCCEEDED', reason='GENERAL_REFUND'`. Prices are read
  from `amount`, never hard-coded.
- **Reprocess** = provider retry rows (`run_no>1`); reprocess success = those
  `status='completed'`. Provider error buckets from `error_code`; unknown codes
  are reported as `other` and never invented (directive §9).
- All windows are `[p_from, p_to)`. No function triggers any evaluation.

## Not verified by Claude

- SQL was authored against the committed schema but **not executed** and **not
  pglast-checked** (no pglast env here). Owner `precheck`/`postcheck` are the
  verification gate.
- `public.admin_operator()` definition is Owner-applied (outside the tree);
  `precheck.sql` asserts its presence.
