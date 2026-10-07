# Admin Console / `/ql` Reconciliation — READ-ONLY Gap Analysis & Codex Handoff

2026-10-07 · **READ-ONLY GAP ANALYSIS + IMPLEMENTATION HANDOFF.** No LAB/APP code,
migration, DB write, Production, Admin-account, Credit, Payment, Toss, or QL-write
change. Authority: Unified Wiki (`legendstudy-docs` 00_PROJECT) + READ-ONLY
Production (Supabase `stlhijzpjfgwwdgunlsd`, 2026-10-07) + READ-ONLY git on
`legendstudy-lab` / `legendstudy-app`. **Not** a build — Admin/QL are already
implemented; this reconciles and hands off merge+apply.

## 1. EXECUTIVE_SUMMARY

The Admin Console (**P0-A/B/C**) and the `/ql` AI-Quality integration are **already
implemented and tested** on dedicated branches — they are **NOT merged to main and
NOT deployed to Production** (`/admin/*` and `/ql/` are 404 in Production). The QL
*backend* is already **Production-applied**; the Admin *backend* and both front
ends are not. The operator account `admin@legendstudy.com` **already exists and is
already enrolled in both operator allowlists.** So the remaining work is
**reconcile → apply 3 admin migrations (Owner-gated) → merge/deploy the LAB admin
branch → set the `essay_finance` credential for write actions** — minimal new code.

## 2. AUTHORITY_CHECKED
- Unified Wiki `00_PROJECT/AI_CONTEXT.md` (Admin console row) + `CURRENT_STATUS.md`
  + DAILY `2026-10-06.md` (ADMIN-P0-C section).
- `legendstudy-lab`: `origin/main @ 30613ee`, `manus/admin-console-p0-a @ bbc23cb`,
  `claude/quality-console-v0 @ 253867b` (merge-status + file inventory).
- `legendstudy-app`: `manus/admin-console-p0-a @ 49c02de` (admin migrations/RPCs);
  canonical ledger `claude/app-release-blocker-closeout-1 @ 0b0b562` (32 migrations).
- Production `stlhijzpjfgwwdgunlsd` READ-ONLY (tables/functions/allowlists/operator
  existence only; no student data, no passwords).

## 3. CURRENT_MAIN_STATE (LAB `main @ 30613ee`)
No `/admin/*` and no `/ql` routes — **admin & QL front ends are NOT in main.**
`manus/admin-console-p0-a` and `claude/quality-console-v0` are **NOT ancestors of
main** (not merged).

## 4. MANUS_ADMIN_STATE (LAB `bbc23cb` + APP `49c02de`) — IMPLEMENTED, not merged/applied
- **LAB routes:** `/admin` (dashboard), `/admin/members`, `/admin/credit`,
  `/admin/payment`, `/admin/operations` (Essay/Math ops), `/admin/inquiries`
  (member 1:1), `/ql` (AI Quality, imported unchanged). Server-side **Cloudflare
  functions** keep secrets off the browser: `functions/api/admin/credit-grant.ts`,
  `functions/api/admin/payment-support.ts`, `cloudflare/admin-finance.ts`.
  `src/components/admin/*`, `src/lib/admin/*` (client/contract/errors/finance-
  boundary/grant-reasons/ops-runtime) + tests. **The admin branch is a superset of
  the QL branch** (QL imported unchanged) → merging it brings `/ql` too.
- **APP backend (3 migrations, NOT applied):**
  `20261007000100_admin_console_read` (P0-A): `admin_operator()`, `admin_dashboard`,
  `admin_member_search/detail/credit`, `admin_credit_snapshot`, `admin_account_state`,
  `admin_count`. `20261007000200_admin_console_p0b` (P0-B): `admin_payment_orders`,
  inquiry system (`inquiries`/`inquiry_replies`/`inquiry_status_events`/
  `inquiry_notifications` + `inquiry_submit/mine`, `admin_inquiry_list/detail/reply/
  set_status`, `admin_support_metrics`, notification claim/complete).
  `20261007000400_admin_console_p0c` (P0-C): `essay_private.admin_relation_ready`,
  `admin_essay_operations`, `admin_math_operations`, `admin_operations_summary`.
- All reads SECURITY DEFINER, owner `postgres`, empty `search_path`, internal
  helpers revoked; **no operations read returns answer text** (build-enforced
  boundary). `admin_relation_ready` distinguishes NOT_INSTALLED vs SCHEMA_INCOMPLETE.
- Harness (per wiki): P0-A 167 / P0-B 360 / notifications 70 / P0-C 170 checks, 0
  failed; LAB 324 tests + boundary audit PASS.

## 5. CLAUDE_QL_STATE (`253867b`) — backend Production-applied; UI not deployed
- LAB UI: `/ql` + `src/components/quality/*` + `src/lib/quality/*` (Essay Human
  Review + Math). **Entirely contained inside the admin branch** (imported
  unchanged).
- **Backend LIVE in Production:** `ql_list_cases`, `ql_case_detail`,
  `ql_list_human_judgments`, `ql_review_state`, `ql_submit_human_judgment` (Essay) +
  `qlm_*` (Math) — verified present. `quality_operators` allowlist exists.
- UI status: `IMPLEMENTED / LOCAL_VERIFIED`; Production operator write
  `NOT_ASSESSABLE` (no legitimate case yet) — **not** `PRODUCTION_VERIFIED`.

## 6. PRODUCTION_BACKEND_STATE (READ-ONLY 2026-10-07)
| Object | Production |
|---|---|
| `admin_users` table | **EXISTS** (from feedback `20260917000100`), 1 operator |
| `quality_operators` table | **EXISTS**, 1 operator |
| `ql_*` / `qlm_*` quality RPCs | **APPLIED (live)** |
| `admin_*` RPCs | **ABSENT** (none in Production) |
| `inquiries` table | **ABSENT** |
| admin-console migrations `202610070*` | **0 applied** |
| Payment (`payment_orders`, `payment_order/support/compensate`, enum TOSS/APPLE_IAP/GOOGLE_PLAY) | **APPLIED**, Toss TEST E2E PASS, LIVE OFF (see [IAP gap](iap-store-billing-gap-analysis-v1.md)) |
| `admin@legendstudy.com` | **EXISTS**, in `admin_users` **and** `quality_operators` |

## 7. ADMIN_IA_FINAL (fixed — do not re-plan)
Dashboard · Members · Credit · Payment · Essay/Math Ops · AI Quality. All six are
already built. AI Quality = the existing `/ql` (reused). No new top-level menus.

## 8–14. Module gaps (reads built; writes gated)
- **DASHBOARD_GAP:** `admin_dashboard` built (reads existing tables); apply+wire
  only. No invented metrics.
- **MEMBERS_GAP:** `admin_member_search/detail/credit` built (profile, join date,
  provider, school/grade/target, credit, essay/math activity, deletion state);
  apply+wire. No answer text in lists (boundary-guarded).
- **CREDIT_GAP:** read (`admin_credit_snapshot`, member credit, ledger, free/paid/
  promo, expiry) built. **Grant WRITE** via server function → `credit_post_grant`
  (reuses canonical authority; no new wallet, no direct table INSERT). Grant is
  **BLOCKED on the Production `essay_finance` credential.**
- **PAYMENT_GAP:** `admin_payment_orders` read built (order/provider/mode/sku/amount/
  state/grant_state/operation/timestamps); provider-agnostic → same UI shows TOSS/
  APPLE_IAP/GOOGLE_PLAY. Write/cancel/refund = `payment_support`/`payment_compensate`
  (finance role) → **READ now, WRITE gated on `essay_finance`.**
- **ESSAY_OPS_GAP:** `admin_essay_operations` + `admin_operations_summary` built
  (session/attempt/evaluation status, failures, version, relations); apply+wire.
- **MATH_OPS_GAP:** `admin_math_operations` built (extraction/evaluation/failure/
  retry/learning lineage); apply+wire. No Math architecture change.
- **AI_QUALITY_GAP:** backend **already Production-applied** (`ql_*`/`qlm_*`); only
  the `/ql` UI needs to ship (via the admin merge). First Production human-review
  write remains `NOT_ASSESSABLE` until a legitimate case exists.

## 15. AUTHORIZATION_MODEL
Two **separate** SECURITY-DEFINER-gated allowlists (least privilege):
`public.admin_users` (service operations) and `public.quality_operators` (AI
Quality) — **intentionally not merged.** `admin_operator()` gates admin RPCs; QL
RPCs gate on `quality_operators`. Browser never holds `service_role`; privileged
finance operations run in Cloudflare server functions. **No new `profiles.is_admin`
boolean** — the allowlist-table model is correct and already in Production.

## 16. ADMIN_ACCOUNT_PLAN
`admin@legendstudy.com` **already exists** and is **already in both `admin_users`
and `quality_operators`** → one operator account carries both roles via the two
separate allowlists. **No account creation, no role change needed** (and none made
here). Keeping the allowlists separate is recommended; a single operator in both is
fine. Future additional operators = insert their uid into the relevant allowlist
(Owner-gated), never a client path.

## 17. SECURITY
service_role never in browser ✓; privileged JWT not exposed (Cloudflare functions)
✓; SECURITY DEFINER + empty search_path + revoked internal helpers ✓; self-scoped
(`inquiry_mine`) vs operator (`admin_inquiry_*`) RPCs separated ✓; audit/reason on
grant ✓ (reuses ledger provenance); idempotency (`request_key`) ✓; no answer text in
ops reads (build-guarded) ✓; PII minimized. **Blocker:** write actions (credit
grant, payment cancel/refund) need the Production **`essay_finance`** credential —
READ ships without it.

## 18. RECONCILIATION_MATRIX
| Feature | Current main | Manus Admin | Claude QL | Production backend | ACTION |
|---|---|---|---|---|---|
| Admin shell + auth gate | absent | built (`admin-surface`, `admin_operator()`) | — | `admin_users` table live, RPC absent | **PORT** (merge + apply) |
| Dashboard | absent | built | — | RPC absent | REUSE (apply+wire) |
| Members | absent | built | — | RPC absent | REUSE (apply+wire) |
| Credit (read) | absent | built | — | ledger live, admin RPC absent | REUSE (apply+wire) |
| Credit (grant write) | absent | built (server fn) | — | `credit_post_grant` live | REUSE — **DEFER write until `essay_finance`** |
| Payment (read) | absent | built | — | payment live, admin RPC absent | REUSE (apply+wire) |
| Payment (cancel/refund) | absent | built (server fn) | — | `payment_support/compensate` live | REUSE — **DEFER write until `essay_finance`** |
| Essay Ops | absent | built | — | RPC absent | REUSE (apply+wire) |
| Math Ops | absent | built | — | RPC absent | REUSE (apply+wire) |
| Inquiries (member 1:1) | absent | built | — | tables+RPC absent | REUSE (apply+wire) |
| AI Quality (`/ql`) | absent | imported unchanged | built | **`ql_*`/`qlm_*` LIVE** | **KEEP** backend; ship UI via merge |
| Authorization allowlists | — | reuses both | reuses `quality_operators` | both tables live | KEEP (no change) |
| Admin operator account | — | — | — | `admin@…` enrolled both | KEEP (no change) |

## 19. FILES / RPC / ROUTES_TO_REUSE
- **ROUTES_TO_REUSE (LAB `bbc23cb`):** `/admin`, `/admin/members`, `/admin/credit`,
  `/admin/payment`, `/admin/operations`, `/admin/inquiries`, `/ql`.
- **COMPONENTS_TO_REUSE:** `src/components/admin/*`, `src/components/quality/*`,
  `src/lib/admin/*`, `src/lib/quality/*`, `functions/api/admin/*`,
  `cloudflare/admin-finance.ts`.
- **RPC_TO_REUSE (apply from APP `49c02de`):** `admin_operator`, `admin_dashboard`,
  `admin_member_search/detail/credit`, `admin_credit_snapshot`, `admin_account_state`,
  `admin_count`, `admin_payment_orders`, `inquiry_submit/mine`, `admin_inquiry_*`,
  `admin_support_metrics`, `admin_essay_operations`, `admin_math_operations`,
  `admin_operations_summary`. **Already live (reuse as-is):** `ql_*`, `qlm_*`,
  `credit_post_grant`, `credit_summary`, `payment_order/support/compensate`.
- **BACKEND_ALREADY_PRODUCTION:** `admin_users`, `quality_operators`, `ql_*`,
  `qlm_*`, credit ledger, payment core.
- **NEEDS_NEW_BACKEND:** none to design — apply the 3 existing admin migrations
  (`20261007000100/200/400`) to Production (Owner-gated DB apply). No new schema.
- **NEEDS_NEW_UI:** none to design — rebase/merge `bbc23cb` onto `main @ 30613ee`
  and align to current design tokens.
- **DO_NOT_TOUCH:** Toss/payment runtime, Math architecture, QL backend, the two
  allowlists' membership, Owner iOS, Codex's in-flight LAB frontend reconciliation,
  account-deletion lifecycle.

## 20. MINIMAL_NEW_WORK
1. Apply admin migrations `20261007000100/200/400` to Production (Owner-gated).
2. Rebase/merge LAB `bbc23cb` onto current `main @ 30613ee`; resolve drift; align
   design tokens; keep `/ql` import unchanged.
3. Set Production **`essay_finance`** credential to enable grant + payment
   cancel/refund writes (until then, ship READ + inquiries, DEFER finance writes).
4. Deploy LAB; smoke `/admin/*` + `/ql` behind the operator gate.
No new feature design required.

## 21. IMPLEMENTATION_ORDER
A) Apply 3 admin migrations + merge LAB admin branch (shell+gate+Dashboard+Members+
Credit read + Essay/Math Ops read + `/ql`) → deploy, operator smoke. B) Set
`essay_finance` → enable Credit grant + Payment cancel/refund writes + audit. C)
First legitimate AI-Quality Production human-review write (closes `NOT_ASSESSABLE`);
Coupon campaign admin views **DEFER** until the coupon backend ships (shell can
reserve the slot). This supersedes a from-scratch Phase A/B/C build — most is done.

## 22. ESTIMATED_SCOPE
**Small–Medium / mostly reconciliation.** Backend: apply 3 existing, tested
migrations (no new SQL). Frontend: rebase/merge one branch + token alignment + QA
(324 tests already pass pre-rebase). Ops: one Production credential + migration
apply (Owner). The hard design/implementation is already done and tested.

## 23. OWNER_DECISIONS_REQUIRED
1. Authorize Production apply of admin migrations `20261007000100/200/400`.
2. Provision the Production **`essay_finance`** credential (enables finance writes;
   until then admin ships read-only for credit/payment).
3. `/ql` final placement: **(C) keep `/ql` route + link from Admin AI-Quality** is
   recommended (minimal change; it already works and the admin branch links it) vs
   moving the UI under `/admin/quality`. Recommend **keep `/ql`, link from Admin.**
4. Confirm the single operator account (`admin@…` in both allowlists) is intended,
   or split service-admin vs quality operators onto distinct accounts later.
5. Merge sequencing vs Codex's in-flight LAB frontend reconciliation (avoid conflict).

## 24. CODEX_IMPLEMENT_HANDOFF
- **Apply (Owner-gated):** APP `49c02de` migrations `20261007000100/200/400` to
  Production (admin_users/quality_operators + ledger + payment already present;
  `admin_relation_ready` makes partial Math schema safe).
- **Merge:** LAB `bbc23cb` → `main @ 30613ee` (rebase, resolve drift, token align,
  keep `/ql` unchanged). Deploy. Verify `/admin/*` + `/ql` operator-gated (404 for
  non-operators).
- **Enable writes** only after `essay_finance`; until then Credit/Payment panels are
  read-only (inquiries + reads work without it).
- **Reuse** all listed RPCs/components; **do not** rebuild Admin or Quality, change
  Toss/Math/QL backend, touch the allowlists' membership, or alter Codex's LAB work.

---

## ADMIN_IMPLEMENTATION_READY: **YES (reconcile + apply + merge, not a build)**

Admin P0-A/B/C + `/ql` are implemented and tested; the operator account and
allowlists are already in Production; the QL backend is live; the only gates are the
Owner-gated **migration apply**, the **LAB merge/deploy**, and the **`essay_finance`
credential** for finance writes. Not deployed/merged yet, so not COMPLETE — but
ready to finish with minimal, mostly-reconciliation work.

*Read-only analysis. CODE 0 · DB 0 · Production 0 · Payment/Toss 0 · no QL write,
no Admin account change, no student data, no passwords read.*
