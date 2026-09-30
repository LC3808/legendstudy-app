# Monetization & In-App Learning Strategy

## Post-audit commercial boundary — 2026-09-30

Owner 재확인: **ESSAY CREDIT ≠ AD REMOVAL ≠ PREMIUM INTELLIGENCE MEMBERSHIP**.

| Product | Meaning / canonical boundary |
|---|---|
| Essay Credit / 첨삭권 | 사용량·회차 기반. 무료·개인 구매·Coupon·Voucher·Institution 제공은 기존 credit_accounts/grants/transactions 및 essay_billing_decisions를 재사용한다. 새 wallet/balance 금지 |
| Ad Removal | **ONE-TIME PURCHASE**. Credit이나 Premium 구독과 별도. profiles boolean/entitlement table 등 저장 방식은 아직 확정하지 않음 |
| Premium Intelligence | 심층 성적·입결·대학/학과 비교·공식 환산·고교 보정·교과/학과 가중·진학 분석·합격예측의 기간형 서비스 후보. Subscription / Semester Membership / Annual Membership은 검토 가능하며 가격/기간/schema는 미확정 |

**USAGE CREDIT ≠ TIME-BASED SERVICE ENTITLEMENT.** 기관 사용권의 scope/기간/자격과 실제 Essay credit 지급을 분리한다. 기존 paid→included 반복 정책과 lifetime rewrite cap 없음은 유지한다. 이번 작업은 Coupon/IAP/Subscription/Entitlement 구현을 승인하지 않는다. 개발 순서는 [Academic/Admission phased roadmap](roadmap-academic-analytics.md#phased-and-source-gated--owner-clarification-2026-09-30)을 따른다. 아래 과거 상품 예시는 이 의미 경계를 바꾸지 않는다.

> **Essay Credit Coupon/Voucher = Launch P0** (distribution channel into the
> existing G1 ledger; no separate coupon balance): design in
> [School History & Coupon/Voucher design](school-history-and-coupon-design-v1.md#part-2--essay-credit-couponvoucher-launch-p0).
> B2B organization/membership/batch = P1.

## 2026–2027 roadmap and monetization — Owner decision 2026-09-29

**CANONICAL ROADMAP / STRATEGY ONLY.** 아래 일정은 Owner가 확정한 제품 목표와
개발 우선순위다. 개발·Store 심사·데이터 준비 상황에 따라 조정 가능하며 출시 완료
주장이 아니다. 이 절은 과거 내신→모의고사 순서, 10월 Beta 목표, 미확정 Essay 가격 및
구독 tier 예시보다 우선한다. 과거 기록은 아래에 보존한다.

### Delivery calendar

| 목표 시기 | 제품 목표 / 완료 의미 |
|---|---|
| ~2026년 10월 중순 | LegendStudy+ App + Essay LAB을 App Store / Google Play 등록·심사·배포 단계까지 포함한 출시 가능 상태로 완성. 단순 개발 완료가 아님 |
| 10월 중순~10월 말 | 실제 운영 결과 기반 Essay LAB v1 안정화·1차 고도화; 2026-10-31 전후 목표 |
| 10월 말~11월 초 | Essay 1차 안정화 후 모의고사/수능 LAB을 다음 최우선으로 개발 |
| 2026년 11월 | 모의고사/수능 분석 BETA |
| 2026년 11~12월 | 수능 분석 → 대학/학과 비교 → 정시 지원 분석 고도화 |
| 2026년 12월~2027년 | 실제 Application / Outcome data 연결·확대, 별도 개인정보/수집 승인 필요 |
| 2027년 | 내신 LAB + 모의고사/수능 LAB + Admissions Analytics 고도화 및 Subscription 정식화 검토 |

출시 핵심은 **문제 선택 → 답안 작성 → 제출 → 첨삭 → 결과 확인 → 재작성 →
재첨삭 → 변화 확인 → 필요 시 Credit 구매**가 실제 서비스에서 끊기지 않는 것이다.
기능 개수가 출시 기준이 아니다. App/LAB의 기존 native/deep-work 역할과 동일 학생
identity를 유지하며 별도 독립 성적 시스템을 만들지 않는다. Academic/Mock 설계와
기존 구현을 먼저 재사용하되 현재 기본 채점/기록과 미래 분석 완성을 구분한다.

### Essay launch critical path

1. G1 Credit Core — Production 완료, [배포 근거](essay-lab-server-transactions.md#g1-credit-commercial-core--2026-09-29).
2. Essay LAB Live Integration — [owner status RPC](essay-lab-server-transactions.md#owner-status-projection) blocker 해소; L1 재개는 별도 Owner 확인 후.
3. AI Worker / Provider / Scaffolding 연결 — 별도 구현·운영 승인.
4. 실제 작성→첨삭→재작성→재첨삭 E2E.
5. IAP / Paywall.
6. Store Sandbox / 실제 기기 E2E.
7. App Store / Google Play 등록·심사·배포.

광고, 고급 attribution, Deferred Deep Link, 부가 Growth 기능은 이 경로를 지연시키지
않는다. 이 일정은 현재 privacy/삭제/retention/AI provider/rights/Store gate를 자동
통과시키지 않는다. Store 상품·Console 작업도 이번 문서로 실행하지 않는다.

출시 후 10월 말까지 AI 첨삭 품질, Scaffolding 우선순위, 과잉 첨삭 방지, 문장 다듬기,
오류·timeout·reconciliation, Credit 정책/결제 안정성, 재작성 loop, 모바일 UX,
AI 운영비용과 실제 사용자 이탈 지점을 운영 근거로 개선한다.

### Product and commercial structure

장기 기본 가설은 **FREE CORE + SUBSCRIPTION ANALYTICS / ADMISSIONS + ESSAY CREDITS**다.
아래 후보는 현재 구현 목록이나 확정 entitlement표가 아니다.

| 축 | 역할 / 후보 |
|---|---|
| FREE CORE | 학생 기본 생활·기록 공간: 입시자료, Study Timer, D-Day, 급식, 기본 학습/성적 기록, 지원 대학 관리, 기본 분석 |
| SUBSCRIPTION ANALYTICS / ADMISSIONS | 내신·모의고사·수능 LAB, 장기 성적 변화, 상세 비교, 대학/학과 분석, 입시 전략, 장기 리포트, 충분히 검증된 이후 Prediction |
| ESSAY LAB CREDITS | 직접 AI 비용이 발생하는 논술 첨삭·재첨삭·Scaffolding·문장 첨삭·대학별 논술 분석의 사용량 기반 서비스 |

Subscription은 지속적인 Analytics/Admissions 이용권, Essay Credit은 AI-intensive
Essay workload 이용권으로 **별도 commercial product**다. 구독이 Essay 무제한을 뜻하지
않으며 월 일부 Credit 제공은 향후 별도 검토한다. 구독 여부나 무료 Credit 여부로
Essay 평가 품질·Learning Loop 기능을 낮추지 않는다.

### Confirmed 2026 Essay prices

| 상품 | 승인 가격 | 역할 |
|---|---|---|
| 1 Credit | 4,900원 | 단건 / 가격 anchor |
| 3 Credits | 11,900원 | 첫 유료 진입 |
| 5 Credits | 17,900원 | 기본 추천 — 표시는 ‘추천’ |
| 10 Credits | 29,900원 | 반복 학습 |
| 20 Credits | 2026 출시 제외 | 실제 사용 데이터 후 2027 검토 |

별도 출시 할인 없음. **신규 가입 +3 Essay Credits**가 Launch Benefit이다.
실제 Store price point·세금·지역 가격 제약이 승인 금액과 다르면 임의 변경하지 않고
Owner에게 보고한다. 구매 데이터 없이 ‘가장 많이 선택’은 쓰지 않는다. AI 호출당
저가 환산을 기본 포지셔닝으로 사용하지 않는다.

[G1 canonical policy](essay-lab-product-v1.md#credits--g1-commercial-policy-2026-09-29)가
실행 계약을 소유한다. 동일 Learning Cycle에서 **paid → included → paid → included**
반복; 최초 첨삭과 그 다음 제출 재작성의 첫 재첨삭이 한 Credit 학습 단위다.
versioned server decision/parent paid decision/ledger가 authoritative하며 attempt_no
홀짝으로 계산하지 않는다. 다른 문제/새 cycle은 새 유료 단위이고 기존 v1/in-flight
history는 유지한다. 신규 +3은 동일 auth identity에 한 번, 기존 계정 소급 지급 아님.
학생 안내는 ‘첨삭권 1회로 같은 답안을 두 번 첨삭받을 수 있어요’처럼 단순하게 하되
현재 행동의 차감 여부는 서버 판단으로 표시한다.

### 2026 Mock / CSAT BETA and 2027 subscription

11월 수능 전후 수요 가능성을 고려하되 **2026 모의고사/수능·입시 분석은 BETA**로
운영하는 방향이다. 사용자 longitudinal/지원·합불 표본, 대학·학과 정보, 공식 입결
수집·정규화, 외부 입시기관 배치자료 사용 검토와 예측 검증에 시간이 필요하다.
BETA는 근거 없는 결과를 제공할 면책이 아니다.

발전 순서는 **FACT → STATISTICS → COMPARISON → EXPLANATION → 충분한 검증 이후
PREDICTION**. 초기에는 성적 한눈에 보기, 과목별 기록, 이전 시험 대비 변화,
백분위/표준점수, 강점·취약 과목, 최근 추세, 목표 대학 및 전년도 공식 입결과의 비교,
검증된 참고 정보에 집중한다. 근거 없이 ‘합격확률 73%’ 같은 정밀 예측을 제공하지 않는다.

2026 BETA는 무료 또는 제한적 무료를 우선 검토한다. 단기 매출보다 성적 데이터의
품질, 사용 패턴, 분석 정확도, longitudinal 축적, 지원/Outcome 연결 및 사용자 가치
검증이 목적이다. 무료 범위/가격은 **미확정**, 영구 무료나 저가 상품 약속이 아니다.
2027 정식 Subscription 전환을 검토한다. 월간/6개월/연간/학년도/고3 수능·정시 시즌
이용권은 retention·시즌별 사용 패턴에 따른 후보이며 가격·기간·상품 구성·Essay
Credit 포함 혜택 모두 Owner 최종 결정 전이다.

### Longitudinal value and evidence boundary

[상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의
**Learning History → Decision History → Outcome History**를 따른다.
고1 내신+Study → 고2 내신+모의고사+목표 대학 → 고3 상반기 내신+모의고사+수시+논술
→ 고3 하반기 9월 모평+논술+수능+정시 → 실제 지원+최초 결과+충원+최종 결과까지
학생에게 지속적 분석 가치를 돌려주는 것이 목표다. 구독의 가치는 데이터 수집 자체가
아니라 축적한 사실로 더 유용한 분석·관리를 제공하는 데 있다. History 없이 AI가
성장/입시 서사를 만들지 않는다.

학생 내신·모의고사·수능·학습 이력·목표 대학·실제 지원·응시·최초 결과·예비/충원·
추가합격·최종 결과와 대학 공식 입결·검토된 외부 자료를 단계적으로 연결한다.
자기보고/검증된 사용자 사실, 공식 자료, 외부 자료의 provenance를 구분한다.
외부 배치표나 전년도 입결은 LegendStudy 자체 Outcome Dataset이 아니다.
telemetry와 학습·선택·결과 사실, 금융 ledger를 혼합하지 않으며 개인정보/retention
경계를 보존한다. 이번 전략 기록은 새 수집·분석·DB·AI 실행 승인이 아니다.

## Historical strategy — precedence

아래 2026-09-19~24 tier/가격/구현 상태는 당시 기록이다. 최신 일정·상품 방향은 위 절,
현재 구현/배포는 [Current Status](current-status.md)와 G1 계약이 우선한다.

## Platform clarification — 2026-09-20

[Product architecture](product-architecture.md) and [platform boundaries](product-platform-boundaries.md)
now govern product family and delivery order. LAB is the multi-service deep-work
Web platform, not only Essay. Below, legendstudy.com means the public archive;
LAB is a separate Web surface for deep analysis/creation/management. App retains
quick actions, habit and notifications. Tier/credit examples remain undecided
planning and do not authorize payments or Teacher/School implementation.


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

## Longitudinal business strategy linkage — 2026-09-24

[Canonical data flywheel](longitudinal-learning-admissions-data-strategy.md)
links existing Web acquisition to App records, personal/cohort value, LAB and
future consulting. [Marketing/lifecycle](longitudinal-learning-admissions-data-strategy.md#acquisition-and-marketing-strategy)
and [monetization/incentive boundary](longitudinal-learning-admissions-data-strategy.md#monetization-and-incentive-boundary)
own these new strategic details. Raw student-data sale is not the default business
model; existing meaningful free access and undecided pricing/entitlements remain.
Academic raw data is not automatically available for advertising/model training.
No payment, ads, campaign, reward, telemetry or data sharing starts from this entry.
