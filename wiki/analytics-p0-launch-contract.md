# Analytics P0 — Existing State / Gap / Minimum Launch Data Contract

2026-09-29 · **REVIEW / DESIGN ONLY — NO IMPLEMENTATION.** No Flutter/LAB-web/
Supabase/RPC/migration/GA4/Firebase/Store change. Audits the actual repo against
the Analytics P0 Implementation Spec v1.0 and fixes the minimum launch contract
for the mid-Oct 2026 Store launch. Companion to the higher-level
[measurement review](analytics-architecture-review-v1.md). Learning/Business SoT =
[Essay product](essay-lab-product-v1.md) / [server transactions](essay-lab-server-transactions.md).

**Headline:** the Learning + Business + Reliability **data contract is already in
Production Postgres and is the Source of Truth for almost every P0 KPI.** The only
genuinely new P0 work is (1) a thin Growth/acquisition client-event layer and
(2) **acquisition attribution persistence at signup** — the single launch-
irreversible gap — plus (3) reporting views over existing tables. **No new
`analytics_events` table, no GA4 duplication of DB facts.**

---

## Existing State Matrix (evidence-based)

| Item | State | Evidence |
|---|---|---|
| GA4 (legendstudy.com) | EXTERNAL_OWNER_ACTION | Tistory site with GA (external; not in this repo) |
| GA4 (LAB web / app) | NOT_IMPLEMENTED | no gtag/GA in repo; LAB web is a separate site |
| Firebase / Firebase Analytics | NOT_IMPLEMENTED | no deps in `pubspec.yaml`; no `google-services.json`/`GoogleService-Info.plist` |
| Crashlytics | NOT_IMPLEMENTED | same |
| FCM (push) | NOT_IMPLEMENTED | same |
| Supabase Auth | IMPLEMENTED | `auth.users.id = profiles.id`; native + LAB shared identity STATIC_PASS |
| Anonymous identity | NOT_IMPLEMENTED | guest = session-only state; no persistent `anonymous_id` |
| Authenticated user identity | IMPLEMENTED | pseudonymous `profiles.id` (uuid) |
| App/Web shared identity | IMPLEMENTED (static) | one Supabase project; provider E2E still gated |
| Attribution / First Touch / Signup Touch | NOT_IMPLEMENTED | no acquisition-context capture anywhere |
| Essay session/attempts/revisions | IMPLEMENTED (schema DEPLOYED, data OFF) | `essay_practice_sessions`, `essay_attempts` (attempt_no, device_class) |
| Evaluations / processing runs | IMPLEMENTED (schema) | `essay_evaluations` (status, request_kind, requested/completed_at, error_code), `essay_ai_processing_runs` (status incl. unknown/timed_out, latency_ms, run_no, cost) |
| Scaffolding / learning events | IMPLEMENTED (schema) | `essay_learning_events` (learning_stage: first_evaluated/rewrite_started/rewrite_submitted/rewrite_evaluated) |
| Credit ledger / grants / signup +3 / billing decisions | IMPLEMENTED (DEPLOYED, G1) | `credit_accounts/grants/transactions`, `essay_billing_decisions` (reason, status, included_by) |
| IAP / Purchase records / Paywall | NOT_IMPLEMENTED | no IAP dep; Owner reports IAP pending |
| LAB Web client | EXTERNAL (separate) | not in this repo |
| Flutter App | IMPLEMENTED | this repo; Essay entry gated |
| legendstudy.com / Tistory CTA | EXTERNAL_OWNER_ACTION | external site |
| Web ↔ App context | PARTIAL | shared identity yes; cross-surface context passing not built |

**Production reality:** Essay schema + Scaffolding 1.3 + submit-timing + G1 Credit
DEPLOYED; **Production AI / student / worker OFF** (no live student data yet).

---

## Source of Truth Matrix

| Fact / Event | Authoritative Source | Existing table/system | Client event needed? | New persistence? | PII risk | Launch-critical | Tier |
|---|---|---|---|---|---|---|---|
| essay_submit | Product DB | `essay_attempts` | no | no | none (no body to analytics) | reliability/activation | P0 (exists) |
| evaluation_complete/fail | Product DB | `essay_evaluations`.status | no | no | none | reliability | P0 (exists) |
| rewrite_submit / re-eval | Product DB | `essay_attempts`(attempt_no≥2) + `essay_learning_events` | no | no | none | activation/NSM | P0 (exists) |
| credit_grant/use/exhaust | Ledger | `credit_transactions`/`essay_billing_decisions` | no | no | none | monetization/integrity | P0 (exists) |
| signup_complete | Auth/Product DB | `auth.users`/`profiles` | no | no | PII stays in DB | activation | P0 (exists) |
| purchase_complete/refund | Verified Store backend | **not built** (IAP) | no (server verify) | yes (future) | none in analytics | revenue | P1 (join contract only) |
| cta_click (.com) | Analytics | GA4 (Tistory) | **yes** | no | none | acquisition (irreversible-ish) | **P0** |
| lab_landing_view / problem_view / signup_start / paywall_view | Analytics | GA4 (LAB web) | **yes** | no | none | acquisition/funnel | P0/P1 |
| first_touch / signup_touch | Product DB | **not built** | capture on web, persist at signup | **yes (minimal)** | pseudonymous only | **launch-irreversible** | **P0_BLOCKING (design)** |

**Rule preserved:** a fact is authoritative in **one** place. DB facts (submit,
eval, rewrite, credit, purchase) are **not** re-emitted to GA4 as a second truth;
GA4 only owns pre-login anonymous marketing events.

---

## L2_SHARED_CONTRACT (for Codex L2-A worker — Claude does not touch L2 code)

The reliability/monetization KPIs depend on the L2 worker **writing existing
fields faithfully**. Requirements (all already in schema — this is a "don't drop
them" contract):

1. `essay_ai_processing_runs`: write `status` including **`unknown`/`timed_out_at`**
   (never silently drop a timeout), `run_no` (increment on retry, never reuse),
   `latency_ms` (or started/completed_at), `error_code`, `selected_result`,
   token/cost fields. → success/failure/timeout/retry/latency p50·p95 KPIs.
2. `essay_evaluations.status` transitions requested→processing→completed/failed/
   cancelled with `requested_at`/`completed_at`/`terminated_at`, `error_code`,
   `request_kind` ('student' vs 'operator_reevaluation'). → North Star must count
   **student** revisions only.
3. `essay_billing_decisions`: on evaluation **failure**, decision must end
   `released` (not `settled`); `included_revision` must have `credits_required=0`;
   idempotency keys must dedupe retries. → integrity checks A/B/E/F = 0.
4. `essay_learning_events`: emit `first_evaluated`/`rewrite_started`/
   `rewrite_submitted`/`rewrite_evaluated` on the real loop. → funnel/NSM.

**Launch-irreversible facts** these preserve: transaction integrity + reliability
history are **already fact-of-record** in these tables, so they are *not at risk*
once the worker writes them — no separate analytics capture needed.

---

## KPI Calculability (against the real schema)

- **NORTH_STAR_CALCULABLE: YES.** Weekly unique authenticated users completing a
  full loop = `essay_attempts`(attempt_no=1) → its `essay_evaluations`
  (status='completed', request_kind='student') → `essay_attempts`(attempt_no≥2,
  same session) submitted → its completed student evaluation. **Retries/
  regeneration are `processing_runs`, not new attempts → not miscounted; operator
  re-eval excluded via `request_kind`.** Cross-check via `essay_learning_events`
  stages. No missing field.
- **ACTIVATION_KPI_CALCULABLE: YES.** First-essay-submission rate (auth users vs
  users with ≥1 attempt), evaluation completion rate (completed/requested),
  **rewrite rate** (denominator = sessions whose **first student evaluation
  status='completed'** [eligible]; numerator = sessions with a submitted
  attempt_no≥2; failed/cancelled first evals excluded from denominator), full-loop
  completion = NSM.
- **MONETIZATION_KPI_CALCULABLE: PARTIAL.** Signup +3 grant, free usage,
  3-credit exhaustion, product mix by `billing_decisions.reason`, consumption =
  **calculable now** from ledger + decisions. **Revenue/buyers/AOV/ARPPU/repeat =
  NOT yet** (IAP/verified purchase not built) → design join contract only:
  verified purchase → `credit_grants`(reason='paid_cycle') keyed by receipt.
  **No fabricated purchase data.**
- **RETENTION_KPI_CALCULABLE: YES (activity-based).** Define retention on
  **meaningful learning activity** = submitted an attempt OR completed evaluation
  OR `rewrite_submitted` event (not mere app_open), cohorted by signup date.
  D1/D7 = P0 (view); D14/D30 = P1.
- **RELIABILITY_KPI_CALCULABLE: YES.** Success/failure rate, latency p50/p95
  (`processing_runs.latency_ms`), credit integrity. Detectable now:
  **A** failure+consumed (`evaluations.status='failed'` ∧ decision `settled`) → 0;
  **B** retry+duplicate consume (`run_no>1` ∧ >1 settled per evaluation) → 0;
  **E** included-but-consumed (`reason='included_revision'` ∧ consume>0) → 0;
  **F** paid-but-no-consume (`reason='paid_cycle'` ∧ no settled txn) → 0.
  **C/D** (purchase-side) = contract only until IAP. **Credit Integrity Error target 0.**

---

## Identity / Attribution Contract

- **Identity:** pre-login `anonymous_id` = first-party cookie (web) / install-id
  (app); post-login pseudonymous `profiles.id`. Cross-device via **authenticated
  user_id only**. Forbidden: email/phone/name as analytics id, fingerprinting,
  probabilistic matching, essay/OCR content. **Do not build a new identity
  framework** — reuse Supabase id.
- **FIRST_TOUCH vs SIGNUP_TOUCH:** recommend **SIGNUP_TOUCH = P0**, **FIRST_TOUCH
  = P1**. Signup-touch (the context present when the account is created) is the
  launch-irreversible minimum and is a single persisted record; full first-touch
  (earliest anonymous session, stitched across pre-login visits) needs anonymous
  session storage + stitching that risks the Oct timeline. Lost by deferring
  first-touch: multi-visit journeys and assisted-conversion credit before signup
  (recoverable later, approximately, from GA4 landing data).
- **Attribution naming:** external `utm_source/utm_medium/utm_campaign`; internal
  first-party params `ls_placement`, `ls_university` (= `universities.id`),
  `ls_problem` (= `essay_questions.id`), `ls_exam_year`, `ls_source_page`,
  `ls_content_type`. **Reuse existing DB ids — no analytics-only university/problem
  ids.** Canonical analytics `platform` = {desktop_web, mobile_web, ios, android};
  note `essay_attempts.device_class` uses {web_desktop, web_mobile, app_mobile,
  tablet} — provide a mapping, do not rename the DB column.

---

## Minimum client events (P0)

- **Tistory .com:** `essay_cta_click` (P0) with {ls_university, ls_placement,
  ls_content_type, ls_source_page, utm_*, device_type}. `essay_cta_impression` →
  **P1** if Tistory instrumentation is complex/unreliable.
- **LAB web (GA4):** `lab_landing_view`, `problem_view`, `signup_start`,
  `paywall_view` (pre-login, anonymous) + default `page_view`.
- **App:** **no client funnel events required for P0** (DB already has the
  authenticated funnel). Crashlytics recommended for crash reliability (below).
- Web/App use the **same event names**; platform is a property.

---

## DB / Web / App / Tistory impact

- **DB_IMPACT:** P0 core = **NO_CHANGE + REPORTING VIEWS** over existing tables
  (KPIs above are all view-computable). The **one** candidate new persistence =
  **signup attribution** (a minimal `signup_attribution(user_id, signup_touch
  jsonb, captured_at)` or columns) — because acquisition context has nowhere to
  live today and is launch-irreversible. **Designed only; migration NOT written
  here** (out of scope) — flag for a separate approved task. No giant
  `analytics_events` table.
- **WEB_IMPACT:** LAB web (separate repo) adds GA4 + the 4 pre-login events + the
  signup-touch handoff (pass `ls_*`/`utm_*` into the signup call so the server
  persists it). Not this repo.
- **APP_IMPACT:** none required for P0 funnel. Optional Crashlytics (deps +
  config). No Production code change in this task.
- **TISTORY_IMPACT:** add `essay_cta_click` via GA/tag only; **do not rebuild the
  site** for analytics.

---

## Crashlytics recommendation

**RECOMMENDED, P0_NON_BLOCKING.** Native crash visibility is the one reliability
signal the DB cannot provide (evaluation reliability is already in `processing_
runs`). Work to adopt: add `firebase_core` + `firebase_crashlytics`, create a
Firebase project, add `GoogleService-Info.plist` / `google-services.json`, Gradle/
Podfile wiring, minimal privacy note. Estimate ~0.5–1 day + Owner console. **If it
threatens the Store timeline → defer to P1**; do not let it delay L2/IAP/Store.

---

## Launch Dashboard v1 (spec only — not built)

One page. Each metric: **definition · numerator · denominator · SoT · cadence ·
calculable-now?**. Never show the same metric from GA4 and DB side by side.

| Section | Metric | Num / Denom | SoT | Now? |
|---|---|---|---|---|
| Acquisition | LAB signup conversion | signups / lab_landing_view | GA4 + Auth | needs GA4 |
| Acquisition | CTA→LAB CTR | essay_cta_click / impression(or reach) | GA4 | needs GA4 |
| Activation | First-essay rate | users w/ ≥1 attempt / signups | Postgres | YES |
| Activation | **Full-loop completion (NSM)** | loop-complete users / signups (weekly) | Postgres | YES |
| Activation | Rewrite rate | attempt_no≥2 sessions / first-eval-completed sessions | Postgres | YES |
| Monetization | Free-credit exhaustion | users w/ 3 free used / +3 granted | Ledger | YES |
| Monetization | Free→Paid | first paid decision / free-exhausted users | Ledger (+IAP) | PARTIAL |
| Monetization | Revenue / ARPPU / mix | store-verified | IAP backend | NO (P1) |
| Retention | D1 / D7 (activity) | active dN / cohort | Postgres | YES |
| Reliability | Eval success/fail, p50/p95 latency | processing_runs | Postgres | YES |
| Reliability | Credit integrity errors (A/B/E/F) | detected / total | Postgres | YES (target 0) |

Cadence: reliability + activation near-real-time (view); monetization daily.

---

## P0 / P1 / P2 (re-classified for the Oct critical path)

- **P0_BLOCKING** (launch-irreversible / integrity-critical): **signup-touch
  attribution persistence design** (context lost forever otherwise) — minimal;
  **L2_SHARED_CONTRACT** faithfully written by the worker (integrity + reliability
  facts); **privacy/minors compliance gate** (Signals off, no cross-app tracking,
  consent/retention — legal, not optional).
- **P0_NON_BLOCKING** (add without blocking Store): GA4 on LAB web + 4 pre-login
  events; Tistory `essay_cta_click`; reporting views over existing tables; the
  1-page launch dashboard; Crashlytics (if timeline allows).
- **P1** (right after): `essay_cta_impression`; first-touch stitching; OCR funnel
  events; web→app prompt + minimal deferred deep link; D14/D30; IAP purchase
  events + revenue KPIs once IAP ships; cohort dashboards.
- **P2** (2027): dedicated product-analytics tool (PostHog self-host), MMP/MMM,
  cross-platform causal experiments, LTV models, university-conversion stats.

**Nothing analytics-related is a Store blocker except the irreversible signup-
touch persistence and the legal/privacy gate.** Dashboards/GA convenience do not
block launch.

---

## External Owner Actions

GA4 property + web/app data streams (Signals OFF); Tistory GA/tag for
`essay_cta_click`; (if Crashlytics adopted) Firebase project + service files;
Apple/Google IAP product setup for the credit packs (IAP track, separate); consent
/retention decisions (Compliance track). **Do not force console work not yet needed.**

---

## Report

- CODE_CHANGED: NO · DB_CHANGED: NO · PRODUCTION_CHANGED: NO · AI_EXECUTED: NO
- ANALYTICS_P0_DESIGN: **READY**
- LAUNCH_CRITICAL_DATA_GAPS: **YES** — (1) signup-touch acquisition persistence
  (irreversible), (2) worker must write reliability/integrity facts
  (L2_SHARED_CONTRACT), (3) minors/privacy legal gate.
- L2_CONFLICT: **NO** — no L2/worker/processing/evaluation-schema files touched;
  requirements handed off as L2_SHARED_CONTRACT for Owner/ChatGPT review.
