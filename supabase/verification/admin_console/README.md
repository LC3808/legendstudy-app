# ADMIN-P0-A — operations console read boundary

Migration: [`20261005000200_admin_console_read.sql`](../../migrations/20261005000200_admin_console_read.sql)
Branch: `manus/admin-console-p0-a` (base `claude/app-release-blocker-closeout-1 @ 0b0b562`)

Read-only, operator-gated surface for the LegendStudy release-operations console.
**Not applied to Production.** `PRODUCTION_MUTATION = NO`; application is a
separate Owner decision.

## Objects

Eight `public` functions, all `SECURITY DEFINER`, owner `postgres`, `search_path=''`.

| Function | Purpose | Callable by |
|---|---|---|
| `admin_operator()` | operations allowlist gate | authenticated |
| `admin_dashboard()` | P0 metrics | authenticated (gate inside) |
| `admin_member_search(text,int,int)` | bounded member lookup | authenticated (gate inside) |
| `admin_member_detail(uuid)` | member summary | authenticated (gate inside) |
| `admin_member_credit(uuid,int,int)` | credit summary + history | authenticated (gate inside) |
| `admin_count(text)` | installation probe | nobody (internal) |
| `admin_account_state(uuid)` | lifecycle state | nobody (internal) |
| `admin_credit_snapshot(uuid)` | one-account credit summary | nobody (internal) |

The three internal helpers are revoked from `public`, `anon`, `authenticated` and
`service_role`, so an authenticated caller cannot read another subject's state or
probe installation state directly. `admin_count` accepts only
`public.<snake_case>` and rejects anything else, so it is not an arbitrary-query
surface. The full ownership/ACL matrix is in [validation.json](validation.json).

Authorization is `public.admin_users` (service operations) and is deliberately
separate from `public.quality_operators` (AI Quality / Human Review). Neither
scope is widened into the other. `admin_operator()` mirrors
`is_quality_operator()`'s fail-closed pattern: `auth.uid()` must match the `sub`
claim, `role` must be `authenticated`, `exp` must be present and unexpired, and
the caller must be on the allowlist. A malformed claim set denies.

No write authority exists in this migration: no Credit grant, no balance update,
no transaction insert, no payment action. Credit granting stays on
`public.essay_admin_grant(...)`, which requires an `essay_finance` capability
that is never available to a browser.

## Pending subsystems degrade gracefully

`20261001000300` (account deletion), `20261002000100–000300` (Math) and
`20261003000100`/`20261004000100` (payment) are `NOT_APPLIED` candidates, and the
payment/Math preflights additionally require the ADR-2 topology. This migration
therefore installs and runs **without** them:

| Relation | Absent behaviour |
|---|---|
| `public.payment_orders` | `payment.installed=false`, `orders=null` |
| `public.math_attempts` / `math_evaluations` | `math.installed=false`, counts `null` |
| `public.account_deletion_requests` | `account.deletion=null`, state `NORMAL`/`ERASED` |

`null` is reported instead of `0`, so "the subsystem is not installed" is never
mistaken for "installed and empty". An installed-but-empty relation reports a
genuine `0`. Math and payment always carry an explicit `runtime_state`
(`RUNTIME_OFF` / `LIVE_OFF`) and never claim to be live.

## Activation gate for ADMIN-P0-B/C

`public.admin_credit_snapshot()` deliberately does **not** apply the
`CANCEL_PENDING` grant fence that the consumer `public.credit_summary()` applies,
because that fence reads `payment_orders`. Today no order can be in
`CANCEL_PENDING` (payment `LIVE OFF`), so both functions agree. **When the payment
runtime is installed, the fence must be added here** or the operator figure will
drift above the member's own figure during a cancellation window.

## Verification

```bash
bash supabase/verification/admin_console/harness.sh
```

Builds a throwaway PostgreSQL cluster with synthetic Supabase shims (`auth`
schema + `auth.uid()`, `storage` catalog, platform roles), applies the canonical
chain in ledger order, then runs [behavior.sql](behavior.sql).

**126 checks, 0 failed** ([validation.json](validation.json)). Engine:
PostgreSQL 16.15 — the platform is 17; the delta is not exercised by this
migration, which uses no version-specific feature.

Two phases:

- **PHASE 1** — deletion/Math/payment absent: gate denial matrix, dashboard,
  search, detail, credit read, ACL, and `NOT_INSTALLED` degradation.
- **PHASE 2** — structural stand-ins created for those three subsystems: the
  installed-path branches execute, including `DELETION_PENDING` → `ERASING` →
  `ERASED` surfacing through both search and detail.

Coverage: anonymous / non-operator / expired / subject-mismatch / wrong-role /
malformed claims denial; bounded list and pagination; `PT422` on short query,
`limit` 0 and 51, negative offset, null query, null account; `PT404` on unknown
account; secret absence (`password`, `token`, `refresh`, `service_role`,
`external_reference`, `actor_reference`, `body`); credit arithmetic against a
hand-computed fixture; expired-grant flagging; actor namespace reduction; and the
full ownership/ACL matrix.

### Limits

- **The stand-ins in PHASE 2 are not the real migrations.** They prove the admin
  boundary behaves correctly when those relations exist; they are not evidence
  that the Math/payment/deletion migrations apply.
- Auth claims are synthetic shims, not a real JWT gateway verification.
- `duration_seconds` on `study_sessions` is generated, so the fixture asserts a
  numeric shape rather than a fixed value.
- `profiles.grade_level` is `smallint`; the distribution is keyed by its text
  form and the console maps `1/2/3` → `고1/고2/고3`.
