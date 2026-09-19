# Monetization & In-App Learning Strategy

Recorded 2026-09-19 from a Product Owner decision. **Documentation only.**
Nothing here is implemented, no price or product is final, and nothing here
promotes an excluded feature into v1.0 — `product-scope.md` governs that.

## 1. How features are evaluated from now on

Every new feature is assessed on four axes, and its role on each is stated at
design time:

| axis | question |
|---|---|
| **User value** | Does it solve a real student problem? |
| **App advantage** | Is there a clear reason to do this in the app rather than on legendstudy.com? |
| **Retention** | Is it one-shot, or does it bring the student back? |
| **Monetization** | Is it Free, Paid subscription, or Credit? |

## 2. Web and App are different products, not two skins

| channel | role |
|---|---|
| **Web** (legendstudy.com) | search acquisition, public archive, 입시정보, free public content, existing AdSense revenue |
| **App** | 자료 탐색, in-app viewing, solving, timer, answer entry, auto scoring, grade/result, Academic Record, Academic Analytics, Achievement, LS LAB, Target University, admissions analysis |

Canonical product loop: **FIND → VIEW → SOLVE → SCORE → RECORD → ANALYZE →
IMPROVE.** The app is never developed into a WebView wrapper or a blog-link
shell; that is already a durable decision (`decisions.md`, 2026-09-12 — Native
app, not WebView).

## 3. In-app PDF viewer direction

Today some resources open outbound to the original LegendStudy post. The
direction is that **core study material is read inside the app**, because it
reduces drop-off, connects browsing to studying, feeds Mock Exam directly, keeps
bookmarks and recent views coherent, makes the ad-free purchase feel consistent,
and creates app value the Web cannot match.

`product-scope.md` already lists PDF viewing inside the v1.0 core content
experience, and `ui-ux-v1.md` records the native viewer as a later
implementation. This entry does not change that; it explains why it matters
commercially as well as for UX.

**Not everything moves at once.** Historical PDFs are not bulk-migrated into our
own Storage.

### Open prerequisite — rights, not engineering

Two existing decisions gate any mirrored copy and must not be contradicted:

- `decisions.md` (2026-09-12 — Resource locations and ingestion identity): no
  bulk mirroring or Supabase Storage setup in v0.1; a future mirror must
  preserve original provenance.
- `day-9-ingestion.md` and `day-9-pilot-c-package.md`: a Storage mirror is
  redistribution of third-party exam material and **needs an explicit rights
  decision, which the Owner deferred**. Runtime re-resolution of expiring source
  URLs is forbidden by `AGENTS.md` §8.

So "in-app viewer" here means the product direction. Whether a given resource is
served from a mirrored copy, from a durable official URL, or only through the
source post is decided per resource **after** that rights decision.

## 4. Viewer pilot — recent three years, grade 3 core exams

First pilot candidate: roughly three years × three exam types — 6월 평가원
모의평가, 9월 평가원 모의평가, 대학수학능력시험. The Owner's recent view
statistics show demand concentrated on 고3 평가원/수능 material, so this is a
demand-driven pilot, not an arbitrary slice. The exact resource inventory is
re-confirmed against Historical ingestion results before any pilot starts.

## 5. Metadata coverage ≠ viewer coverage

An architecture principle worth stating plainly: the two need not match.

- Metadata may expand to 2020–present.
- Viewer may cover only the recent three years of 고3 core material.
- Anything the viewer does not cover falls back to the original post.

**Storage cost therefore never becomes a reason to slow Historical metadata
expansion.**

## 6. Primary and fallback resource access

`PRIMARY → in-app viewer`, `FALLBACK → original LegendStudy source page`. Even
when a viewer or a mirrored copy fails, the student must still be able to reach
the original material.

## 7. Storage, cost and device cache

Viewer coverage expands from measurement, not optimism. Candidate pilot metrics:
PDF count, total storage size, average file size, monthly opens, downloaded GB,
repeat-open rate, device cache hit ratio, storage cost, egress cost.

Repeated reads of the same PDF should not repeat egress forever, so a
device-private cache is a candidate: first open downloads into a private cache,
repeat opens read locally, and a change of resource hash/version forces a
re-download. Not implemented.

## 8. Free content principle — do not paywall basic access

Public educational material and the basic viewer are **not** the core of the
paywall. A free user must be able to search and read in the app well enough to
see the point of the app. The viewer's job is adoption, app advantage, retention
and conversion funnel — not revenue by itself.

## 9. Sell intelligence, not basic access

Premium value is 풀이 → 채점 → 기록 → 분석 → 개인화된 학습 지원 → 입시 지원
분석. In one line: **data + analysis + AI + continuity**, not content access.

## 10. Mock Exam premium funnel

Earlier candidate journey (Viewer-first ordering superseded by the paper-first
refinement below): free viewer → exam mode → answer entry → auto scoring →
원점수/등급 → 문항·영역 분석 → Academic Record → 성적 변화 → Academic
Analytics. This chain is the primary conversion candidate.

## 11. Free trial

Direction: let free users experience the premium learning/evaluation flow a
limited number of times — currently about **three** — before subscribing.

Undecided and deliberately not fixed here: whether it is exactly three, which
action consumes one, whether the counter is per account, per device or per
signup, and whether it expires. **Status: product direction, not a final
entitlement contract.** LS LAB records a comparable "first ~3 evaluations free"
direction in `roadmap-essay-lab.md`; the two must be reconciled when the
entitlement contract is actually designed.

## 12. Subscription tiers — concept only

Candidate tiers **FREE / BASIC / ADVANCED / MAX**. Names may change. This is
product architecture, not a product line-up. It supersedes the earlier
Free/Basic/Pro sketch in `architecture.md` as the working vocabulary; the
Entitlement-layer rule there still stands, including "a free viewing limit must
never delete attempts beyond that limit".

| tier | direction (not final) |
|---|---|
| **FREE** | 자료 검색; PDF viewer; bookmark; 최근 본 자료; Study 기본; Meal 등 생활형 기능; some Achievement; premium analysis trial |
| **BASIC** | 시험 모드; 자동 채점; 원점수·등급; Academic Record; 기본 성적 그래프; a bounded analysis quota |
| **ADVANCED** | Basic + Academic Analytics; per-subject Study × Score; 취약 영역; 학습 Gap; Target University/Department linkage; higher quota; some LS LAB entitlement/credit |
| **MAX** | Advanced + high analysis/AI quota; expanded LS LAB AI essay evaluation; future handwritten math / Vision evaluation; advanced admissions analysis; premium AI features |

Exact entitlements and quotas are undecided at every tier.

## 13. Subscription + credits for AI-heavy features

Features with a real marginal AI cost — LS LAB 장문 논술, AI evaluation,
handwritten math Vision, science/multimodal evaluation — combine a subscription
entitlement with usage credits.

**MAX is not defined as unlimited AI.** Candidate structure: subscription +
included credits + optional additional credits. Quotas and prices are set after
cost measurement, not before. LS LAB already records the server-authoritative
credit contract (`CHECK → RESERVE → EVALUATE → SETTLE`, with safe restore on
failure) in `roadmap-essay-lab.md`; that contract is the reference
implementation shape, still unimplemented.

## 14. LS LAB integration

LS LAB is not fixed as a separate payment island. It stays connectable to the
LegendStudy membership/entitlement architecture, so that 모의고사, 성적 기록,
학습시간, Academic Analytics, 논술 첨삭, Target University and admissions
analysis can read as one learning ecosystem to a student — while LS LAB's real
AI cost remains controllable through credits and quota.

Handwritten math and multimodal evaluation carry comparatively high inference
cost and are candidates for a higher tier or credit-based usage. No plan
assignment or price is fixed here.

## 15. Ad-free one-time purchase stays a separate product

The existing ₩4,900 one-time "커피 한 잔 후원" ad-removal idea is preserved, and
the price is not final. It and the subscription are **different product roles**:

| product | role |
|---|---|
| Ad-free one-time purchase | removes ads; neither a subscription nor a core-feature unlock (`decisions.md`, 2026-09-12) |
| Premium subscription | learning / analytics / AI entitlement |

Including ad removal in BASIC and above is a direction to evaluate, not a
decision.

## 16. Why outbound ads matter here

Choosing a resource in the app and then landing on the Web with AdSense again
hurts perceived app quality, pushes the user out of the learning loop, weakens
the value of the ad-free purchase, and clashes with a premium UX. In-app viewing
of core material is therefore a monetization-architecture issue as much as a UX
one.

## 17. Web monetization is preserved

An in-app viewer does not retire legendstudy.com. Web keeps search acquisition,
public material and AdSense; App carries the learning workflow and AdMob / IAP /
subscription. The two channels have separate roles.

## 18. Community — PLANNED, free and retention-oriented

Community is part of the long-term product map and must not be dropped from it.
It remains **PLANNED / NOT IMPLEMENTED**, and `product-scope.md` still excludes
"Community / free-talk board" and "Meal-photo/community" from v1.0.

- **Role: FREE / RETENTION.** Community is not the centre of the early paywall.
- Initial candidates: **학교 급식 자랑** (connected to the Meal feature — 급식
  사진과 학교생활 참여), and **잡담**. Later candidates: 공부 인증, 모의고사
  후기, 학습 팁.
- **Not a launch blocker.** Features that are valuable to a single user on their
  own — viewer, Mock Exam, Academic Record — come first. Community needs other
  people present to be worth anything, which is exactly why it cannot gate the
  first release.
- **Safety is designed with the posting feature, not after it.** The users are
  students, so reporting, blocking, moderation, spam and banned-word handling,
  prevention of personal-information exposure, image safety and an operator
  workflow are part of the same design task as posting itself.
- Meal → 급식 자랑 is recorded as a future cross-feature UX candidate.

## 19. App value principle

A student should never think "웹에서도 되는데 왜 앱을 설치하지?". The app's core
value is the continuous chain: 자료 발견 → 즉시 열람 → 문제 풀이 → 채점 → 기록
→ 분석 → 성장 추적.

## 20. Do not over-paywall

The basic experience is not deliberately degraded to drive conversion. Search,
PDF reading and core utilities keep real free value. Monetization is built on
more intelligence, deeper analysis, AI evaluation and longitudinal data value.

## 21. Relationship to ingestion work

**Historical expansion** prioritises metadata coverage; viewer Storage migration
is a separate later step, gated on the rights decision in §3. Candidate order:
Historical 2024 reconciliation → independent answer-first Exam Engine validation;
in parallel, rights-gated 고3 viewer pilot → viewer usage/cost measurement →
viewer coverage expansion. This refines the earlier viewer-before-exam sequence.

**Daily content sync** (Blog → App, incremental plus Owner manual sync) connects
as: metadata ingestion → validation → viewer mirror eligibility → optional
Storage mirror → viewer availability. **Automatic Storage mirroring of every new
PDF is not decided.**

## 22. Feature → monetization map (planning framework, not a price table)

| feature | candidate role |
|---|---|
| Meal | FREE / retention |
| Study basic | FREE / retention |
| Materials search | FREE / acquisition |
| PDF viewer | FREE / app advantage |
| Community | FREE / retention |
| Mock Exam basic trial | FREE TRIAL |
| Mock Exam scoring / record | BASIC candidate |
| Academic Record | BASIC candidate |
| Academic Analytics | ADVANCED candidate |
| Achievement | FREE / BASIC retention candidate |
| Target University | ADVANCED candidate |
| Admissions Engine | ADVANCED / MAX candidate |
| LS LAB AI essay | ADVANCED / MAX + credits candidate |
| Handwritten math Vision | MAX / credits candidate |

## 23. Current implementation status

| capability | status |
|---|---|
| Outbound resource open | **existing** |
| In-app PDF viewer | NOT IMPLEMENTED |
| Storage mirror | NOT IMPLEMENTED (and rights-gated) |
| Viewer cache | NOT IMPLEMENTED |
| Viewer ↔ Mock Exam integration | NOT IMPLEMENTED |
| Free analysis trial | NOT IMPLEMENTED |
| Subscription | NOT IMPLEMENTED |
| FREE / BASIC / ADVANCED / MAX | PRODUCT CONCEPT ONLY |
| Credit system | NOT IMPLEMENTED |
| LS LAB subscription integration | NOT IMPLEMENTED |
| Community | NOT IMPLEMENTED (PLANNED) |

This document is a strategy record. None of the above was built by writing it.

## 24. Not in this entry

No Flutter code, PDF viewer, Storage, DB migration, Supabase, RLS, RPC, Edge
Function, payment, IAP, RevenueCat, AdMob, AI, subscription, credit, resource
migration or PDF download. No price and no product line-up is final. Related
roadmaps: [roadmap-academic-analytics.md](roadmap-academic-analytics.md),
[roadmap-essay-lab.md](roadmap-essay-lab.md).

## In-App Exam RED TEAM gate

Detailed implementation prerequisites live in [architecture-in-app-exam.md](architecture-in-app-exam.md).
Basic Academic Record/history are V1-required; Advanced Analytics is V2. Payment
implementation remains separate, while an entitlement-compatible reserve/settle
boundary is required in design now. Rights, metadata/viewer separation and
undecided free quotas/tier pricing above are unchanged. No implementation started.

## Paper-first / answer-first product refinement

The prior RED TEAM gates remain safety requirements, but PDF delivery is not an
Exam Engine dependency. Primary mobile: obtain/print a permitted paper externally,
solve, select exam, enter answers, submit, receive server score/grade, record and
compare. Viewer is for preview/reference/original access/download convenience or
optional Tablet use, not the primary mobile paywall. Viewer failure cannot stop
answers/scoring/history. No mirrors or downloads were implemented here.

FREE candidates: search, basic resource access, original/download access, basic
Viewer and bounded Premium Trial. Paid value candidates: repeated automatic
scoring, grade/long-term records, exam comparisons, subject/area/weakness analysis,
study-strategy generation and advanced Analytics. Prices and tier/quota contracts
remain undecided; no new free-count promise. Basic Record/comparison is V1;
AI/deep strategy is later. Retention asset is USER ACADEMIC HISTORY, not PDF
collection: Exam → Score → Grade → Subject Performance → Historical Trend →
Weakness → Study Strategy. [Architecture](architecture-in-app-exam.md) separates
Viewer CONDITIONAL, mirror/Storage HOLD and independent Engine CONDITIONAL gates.
