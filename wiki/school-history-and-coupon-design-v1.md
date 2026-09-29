# School History & Essay Credit Coupon/Voucher — Product / Data Design v1

2026-09-29 · **DESIGN / WIKI ONLY — NO IMPLEMENTATION.** No Flutter/DB/migration/
RPC/Production/AI change; no coupon/credit created. Canonical home for two
Owner-decided features; other canonical docs link here (no full-text
duplication). SoT principles follow [Analytics P0 contract](analytics-p0-launch-contract.md);
credit reuse follows [Essay product / G1](essay-lab-product-v1.md) /
[server transactions](essay-lab-server-transactions.md); longitudinal framing per
[strategy](longitudinal-learning-admissions-data-strategy.md).

---

# PART 1 — School History & Change Policy

## 1.1 Current state (verified)
`profiles.neis_office_code` + `neis_school_code` (NEIS pair, `20260913000100`) hold
**only the current school and are overwritten on change** — no history, no change
count, no cooldown. Also present: `grade_level`, `academic_status`,
`onboarding_completed_at`. Set from onboarding + MY (`/my/school`), reused by meals
and (future) analytics. **Every change silently destroys the prior academic
context** — a longitudinal data loss that continues every day.

## 1.2 Product principle
High-school identity is **longitudinal academic context** (내신/모의고사/수능/지원
전략/Outcome/cohort는 "당시 학생의 학교"를 알아야 해석된다), not profile decoration.
Canonical direction = **School History (append-only) + Current School Projection**,
not overwrite. **Academic School History ≠ verified B2B Organization Membership**
(§Part 3) — selecting A고 in MY never means "A고 B2B 계약 학생."

## 1.3 Change policy (Owner default: 2 + 14d)
- After first set, **2 free immediate corrections**; thereafter each change is
  **applied immediately** but starts a **14-day cooldown** before the next change.
  Never a hard ban; **transfers (전학) supported**.
- Comparison (design opinion, not to implement):
  - **Free corrections 2 vs 3:** keep **2**. 3 marginally helps fat-finger fixes
    but widens a data-churn / abuse window; a support/admin correction path covers
    genuine >2 mistakes better than a looser default.
  - **Cooldown 14 vs 30 days:** keep **14**. 30d better protects data stability but
    is student-hostile for real mid-term transfers; 14d is enough to blunt casual
    flipping while tolerating real change. **Recommendation: 2 + 14d.**
- **Server-authoritative** (§1.6). The change is immediate; only the *next* change
  is gated.

## 1.4 Cooldown UX
Not "apply after 14 days" — school changes **now**, next change is limited.
- Copy: "학교 정보는 성적·입시 분석에 활용되는 중요한 정보예요. 학교를 변경하면
  14일 동안 다시 변경할 수 없습니다." + show **다음 변경 가능일** explicitly.
- Future: admin/customer-support correction path (bypasses cooldown, audited).

## 1.5 School History — historical facts (design only)
Append-only record per school assignment; candidate fields:
`user_id, school_id(NEIS pair), effective_from, effective_to(null=current),
recorded_at, change_type(initial|correction|transfer|admin_correction),
source(onboarding|my|admin), verification_state(self_reported|…future)`.
- **correction vs real transfer:** worth distinguishing later (a correction
  replaces a mis-entry; a transfer is a real new period). MVP may record
  `change_type` and refine semantics later. Don't block launch on perfect
  semantics.
- **No backfill of fake history**: existing users' current school becomes the
  first history row with `effective_from = recorded_at` (or null "unknown start"),
  **never an invented past school**.
- **Current projection** = the row with `effective_to is null` (or a projected
  column on profiles kept in sync) — clients keep reading a single current value.

## 1.6 Server-authoritative validation (design)
- change-count + last-change timestamp are **server facts** (DB), not client UI.
- Server decides: can-change / remaining-cooldown / next-change-at. Client only
  displays.
- Must survive **app reinstall, other device, Web↔App** (state lives in DB keyed by
  user_id, never local clock/storage). Cooldown compares **server time**, not
  client clock.
- Concurrency: single-writer per user (row lock / CAS on a change-count or
  version) so double-tap / retry / stale request can't skip the gate.
- Reuse existing **NEIS identity** (office+school code) as `school_id`.

---

# PART 2 — Essay Credit Coupon/Voucher (Launch P0)

## 2.1 Role — a distribution channel into the existing ledger
Coupon is **not a new credit system and has no separate balance**. Canonical flow:
```
coupon code → server validation → campaign policy → redemption
            → existing credit grant (credit_post_grant) → credit_transactions
            → ledger-derived balance → essay_cycle
```
**Reuse G1 directly.** `credit_grants.origin` already supports **`promotion`**
(individual/event/promo) and **`b2b_program`** (school batch); the idempotent
primitive `essay_private.credit_post_grant(user, qty, origin, key, reason, actor,
expires)` posts grant+ledger atomically. **No new grant origin, no coupon balance,
no new accounting.** Coupon provenance lives in campaign/voucher/redemption rows,
linked to the created `credit_grant` (its `external_reference` = the redemption key).

## 2.2 Campaign / Voucher / Redemption model (design only — minimize tables)
Policy is owned by a **server-side Campaign**, never by the code string. Candidate
persistence (exact tables/columns decided at implementation review; not
necessarily three):

- **Campaign** — `credit_amount`, `grant_origin`('promotion'|'b2b_program'),
  `grant_reason`, `starts_at`, `expires_at`, `active/revoked`, `total_issue_limit`,
  `total_redemption_limit`, `total_credit_budget`, `per_user_redemption_limit`,
  optional `organization_id`/`program_ref` (future).
- **Voucher / Code** — `campaign_id`, **code hash** (not plaintext), `status`,
  `redemption_limit` (1 for individual; >1/shared for promo), `expires_at`,
  `revoked`, `created_at`. A **shared promotion code** = one voucher with a high
  redemption_limit + per-user cap; **individual voucher** = redemption_limit 1.
- **Redemption** — `campaign_id, voucher_id, user_id, redeemed_at,
  credit_grant_id, redemption_key`. Enforces per-user + total limits + idempotency;
  reconstructs "누가/언제/어떤 grant".

**Prefix** may be used for operational/readability/campaign labelling **only** —
never the SoT for credit amount, usage count, school authority or security. DB
campaign/voucher policy decides everything.

## 2.3 Coupon types supported by the model
A. Individual voucher (1 code → 1 use → +N). B. Multiple-voucher campaign (student
may redeem several **different** vouchers, +10 +10 = 20). C. Per-user-limited
campaign (account may redeem only 1 despite holding many). D. Shared promo code
(one code, many users, per-account cap). E. Test/operational campaign (bounded).
F. **Future** organization-restricted campaign (§Part 3).

## 2.4 B2B example (structure only)
A고 계약 100명 × 10 Credits = 1,000 → issue **10-credit voucher × 100** →
CSV/XLSX to the school (P1) → distribute. `per_user_limit=1` → ≤10 per student;
multiple-voucher allowed → two codes = 20. **Campaign policy decides**, per real
contract.

## 2.5 Unlimited / reusable code policy
**No production master code that mints unlimited credit** (no `TEST9999 → ∞`).
Any reusable/shared code MUST carry: per-user limit, total redemption limit, total
credit budget, expiry, revoke, audit. **A leaked code must not become infinite
credit.**

## 2.6 Organization-restricted coupons — the critical rule
`profile.school_id == campaign.school_id` **does NOT grant B2B eligibility** (users
freely pick their school). School-restricted coupons validate against **verified
organization membership** (§Part 3), which need not exist for launch — **P0 runs
general (non-org-restricted) vouchers/promos only; keep the structure extensible.**

## 2.7 Security (implementation must verify)
Sufficient code entropy (not sequential `00000001`); guessing resistance;
human-typeable + brute-force-resistant (random base32, grouped `XXXX-XXXX-XXXX`,
optional checksum, defined case-sensitivity); **store a secure hash for lookup, not
long-term plaintext**; **generate/export the real code once** for operator CSV/XLSX,
minimizing DB plaintext retention; redemption **idempotency + concurrency +
duplicate protection**; per-user / campaign / budget limits; expiry; revoke;
**grant+ledger atomicity**; audit. **Client never decides** credit amount, grant
origin, org eligibility, campaign policy, or user_id — server uses `auth.uid()`.

## 2.8 Redemption RPC (concept — name/signature at impl review)
`essay_redeem_coupon(p_code)` (final name per existing RPC naming/security):
server validates authenticated user, campaign active + window, voucher validity +
limit, per-user + total campaign limit, total credit budget, optional org
eligibility, duplicate/existing redemption → then grants. **One safe transaction**:
validate → reserve/claim → `credit_post_grant` → positive ledger posting →
redemption completion. No split state (credit-without-redemption or vice-versa);
retry returns the same result; concurrent redeem of the same voucher/last-budget
grants at most once.

## 2.9 Abuse / rate limit (design)
Account-based attempt limit + server throttling + temporary cooldown + generic
invalid response + monitoring. **No device fingerprinting.** Avoid overly detailed
errors that let an attacker probe valid codes, while still giving authenticated
users the needed 만료 / 이미 사용 / 한도 도달 states — balance UX vs security.

## 2.10 Paywall / Coupon UX (P0)
Purchase surface with an always-discoverable **secondary** coupon entry (not a
hidden admin menu, not overpowering purchase):
```
첨삭권 구매   [1회] [3회] [5회·추천] [10회]
─────────────
쿠폰 코드 등록
학교/이벤트/프로모션에서 받은 쿠폰 코드를 입력해 주세요.
[ XXXX-XXXX-XXXX ]   [쿠폰 등록]
```
Success shows the **server-returned** amount ("첨삭권 10회가 추가되었습니다 · 현재
첨삭권 13회"); client never infers amount from prefix. Errors (invalid/expired/
already-used/limit-reached/campaign-exhausted/not-eligible) as student copy, **no
raw SQL/DB errors**. The surface also signals "학교/이벤트에서도 쓰는 서비스"
naturally — **without implying a partnership that doesn't exist.**

## 2.11 Coupon analytics boundary
Authoritative coupon facts reconstruct from **Campaign/Voucher/Redemption/Grant/
Ledger** — **do NOT make `coupon_redeemed`/`credit_granted`/`campaign_usage` a GA4
source of truth.** UI-only signals (`coupon_entry_view`, `coupon_submit_attempt`)
are decided by the Analytics track if needed; **the coupon system builds no
`analytics_events` of its own.**

---

# PART 3 — B2B Organization boundary (P1)

**Academic School ("나는 A고 재학") ≠ B2B Membership ("나는 계약된 A고 프로그램의
확인된 참여자").** Long-term structure (design only): `organizations →
program/contract → verified organization_memberships → coupon campaign → voucher
batch → redemption → existing credit grant/ledger`. Principles:
- `auth.users.id` stays the personal identity; organization = 소속/계약 관계.
- Membership never replaces personal Learning-History ownership; school change
  never changes the account; **a school never auto-gains read access to a
  student's essays/evaluations** — that's a separate permission problem, not
  granted by a coupon contract.
- **B2B analytics** = program-level aggregates (발행/등록/활성/첫 첨삭/재작성/
  full-loop counts) under proper permission/privacy — **different from exposing
  individual answers**; follows the Analytics P0 SoT (reconstruct from DB).
- Batch issuance, CSV/XLSX export, issued/redeemed/unused, budget, school-operator
  role, audit = **P1**. Don't add P0 schema that blocks this extensibility.

---

# PART 4 — Implementation phases (design; not implemented here)

### A. School History / Cooldown
Reuse profiles' NEIS pair + grade/status. Minimal persistence: a school-history
(append-only) record + a server-authoritative change-count/last-change (or derive
from history) + current projection. Existing users → seed one current-school
history row (no invented past). Server decides change eligibility/cooldown (not
client clock); survive reinstall/other-device/Web↔App. Flutter: MY `/my/school` +
onboarding show remaining corrections / next-change-date; server validation only.
Concurrency via lock/CAS.

### B. Coupon/Voucher P0
Campaign + Voucher(code hash) + Redemption persistence (minimize count after
reviewing G1); `essay_redeem_coupon` RPC → `credit_post_grant` (origin
promotion/b2b_program). Paywall coupon entry (secondary). Idempotency/concurrency/
budget/limits/expiry/revoke/audit. General vouchers only (no org restriction) at
launch. **Schedule with the IAP/Paywall phase.**

### C. B2B Organization P1
organizations / verified memberships / program-contract / batch voucher issuance +
CSV/XLSX export + issued/redeemed/unused + operator role + program analytics.
Org-restricted coupons activate once verified membership exists.

---

# PART 5 — Priority & report

- **COUPON_IMPLEMENTATION_PRIORITY: P0 (Launch)** but must **not** interrupt the L2
  Worker/Provider critical path. Recommended order: L2 Worker/Provider → Learning
  Loop E2E → **IAP/Paywall + Coupon** → device QA → Store. Coupon DB/Flutter ships
  **with the IAP/Paywall phase**.
- **SCHOOL_IMPLEMENTATION_PRIORITY: P0_NON_BLOCKING**, leaning **elevated for data
  preservation**. The overwrite model loses longitudinal academic context every
  day, which is not recoverable — so it deserves higher-than-UX-polish priority.
  But it must **not** risk the Store launch: if the history schema is heavy, ship a
  **staged migration** (a small "start recording history + server cooldown" step
  first; richer transfer/correction semantics later). A separate small phase from
  Coupon.
- **Brand leverage (context, not a claim):** legendstudy.com ~15년 운영, Owner
  기준 누적 방문자 ~5천만+/pageview ~1억, 교사 이용 기반 — an asset for LAB trust,
  school awareness, teacher B2B leads, coupon-surface strategy. **These figures are
  NOT promoted to a verified external marketing claim here**; verify via real
  analytics/operations before external use.

DECISION_GATE: SCHOOL_DATA_DESIGN **READY** · COUPON_P0_DESIGN **READY** ·
READY_FOR_CODEX_COUPON_IMPLEMENTATION **YES** (with IAP/Paywall) ·
READY_FOR_CODEX_SCHOOL_IMPLEMENTATION **YES** (staged) · L2_CONFLICT **NO** ·
ANALYTICS_CONFLICT **NO**.

Guardrails: no code/DB/migration/RPC/Production/coupon/credit/AI change; L2 &
Analytics artifacts untouched; Owner files preserved.
