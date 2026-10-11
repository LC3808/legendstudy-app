# LegendStudy LAB — Essay Service Module Roadmap

## Current delivery target — 2026-09-29

[2026–2027 canonical roadmap](roadmap-monetization-and-in-app-learning.md#20262027-roadmap-and-monetization--owner-decision-2026-09-29)가 일정·가격·상품 전략의 단일 원본이다.
10월 중순 App + Essay LAB Store 등록·배포 목표 → 10월 말 Essay 안정화 →
모의고사/수능 LAB BETA 우선. G1 및 owner status RPC는 Production 완료;
[현재 서버 상태](essay-lab-server-transactions.md#owner-status-projection),
[Product 계약](essay-lab-product-v1.md)이 과거 미구현/체험/모바일 범위 설명보다 우선한다.
L1/worker/E2E/IAP/Store 순으로 별도 승인 후 진행하며 이 문서는 구현을 재개하지 않는다.

## Historical roadmap context

Status at 2026-09-27: **P0 NEXT AFTER MATERIALS OWNER QA — canonical model first; public entry implemented**

[Owner decision2026-09-27](materials-closeout-essay-lab-handoff.md) supersedes
older priority/three-year inventory rules below. This is a handoff, not LAB implementation.
Historical target: **2026-10 Beta**, not a renewed release commitment.

This document records a product priority change. It is a roadmap, not an
implementation claim. No Essay Lab code, schema, AI evaluation, payment
integration or Production change is included in this entry.

The previous initial scope of approximately 5–10 universities and the latest
2–3 years is superseded by the research-first rules below. No university count
is assumed before the nationwide survey.

## Current app integration — 2026-09-20

Owner-supplied public Web: `https://lab.legendstudy.com/`; separate actual Web
repository **LC3808/legendstudy-lab** (supersedes the earlier repository candidate).
Flutter Home/MY now provide a shared external-browser entry for Guest/account.
The public site is an introduction/foundation; app copy promises discovery only.
Shared auth, payments/entitlements and record sync remain **NOT IMPLEMENTED**;
**WebView NOT USED**. Future architecture below is a direction, not deployed app
integration. See [implementation/evidence](core-app-improvements.md#legendstudy-lab-production-entry--2026-09-20).

## 1. Product direction

LegendStudy is planned as one service with three connected surfaces. The
Owner-provided context is that the existing service has operated for roughly
13 years and averages 20,000+ daily visits/pageviews; this is business context,
not an independently audited analytics metric.

1. LegendStudy Mobile App
2. LegendStudy Web App (working title: **LS LAB**)
3. Shared Supabase backend

The service is **LegendStudy LAB**, canonical `https://lab.legendstudy.com/`.
Earlier domain candidates are historical; no additional purchase is decided.

LegendStudy LAB is the multi-service Web Intelligence / Deep Work Platform;
Essay is one module alongside Academic Analytics and other future services.
[Product architecture](product-architecture.md) owns the family and current
cross-product priority; [platform boundaries](product-platform-boundaries.md)
owns App/Web allocation. This document owns Essay research/evaluation details.
Historical 2026-09-27 priority (superseded by the current target above): Essay LAB → internal-grade analysis → mock-score analysis →
admissions strategy/prediction. Shared canonical identity/data is required;
implemented integration must still be verified independently.

## 2. Official evidence and service-university inventory

Phase0 first models the available corpus and canonical university/field/track
relationships. When selecting service universities, consult official current
논술고사 admissions evidence; the older nationwide survey is not a prerequisite
to starting that canonical model.
The inventory must be grounded in official 2027 admissions plans,
전형계획, university admissions-office materials and other official sources.
Any additional research/delegation requires its own scope. Do not assume a
university count or implement admissions ingestion during Materials closeout.

After the survey:

- Prioritize broad coverage of Seoul-based universities that conduct 논술.
- Add representative non-Seoul universities such as 부산대 and 경북대 when
  their formats warrant inclusion.
- Confirm each university's actual 2027 format from research; do not infer a
  format from the university name.
- Treat materially different formats as separate tracks or taxonomy extensions
  instead of forcing them into the general long-essay contract.

## 3. Essay Lab MVP and material inventory

Initial user flow:

`university → year/track/question → question and passages → text answer → submit → AI feedback → result → cumulative profile update`

The MVP supports typed answers only. Handwriting OCR and photo answers are
LATER scope.

The first content inventory must review the existing `legendstudy.com` assets
and official university admissions materials for each selected university.
The Owner target is **2020 onward, at least five years**, preferably2020–2025,
with source publication year kept separate from admission year:

- university-specific essay past questions
- questions and passages
- explanations
- model/example answers
- intended reasoning
- scoring criteria/rubrics
- official PDFs and other official essay guides

Inventory comes before implementation. Record each material type and year
separately. If an official item is unavailable, mark it as unavailable; do not
fill the gap with inferred or unofficial material.

## 4. Problem taxonomy and evaluation contracts

The initial taxonomy must support at least two evaluation tracks:

### `long_essay`

General long-form essay evaluation, including passage analysis, thesis,
argumentation, organization, expression and university-specific rubric items.

### `short_response`

Short-answer or near-short-response evaluation, emphasizing required answer
elements, core-concept accuracy, requirement coverage, omissions, expression
accuracy and relatively explicit partial-credit structures.

부산대, 경북대 and other representative universities are assigned only after
the 2027 format and past questions are researched. The taxonomy may expand if
the inventory shows another materially different format.

`long_essay` and `short_response` must not be forced to share one AI prompt or
schema. Candidate dimensions for `long_essay` include question understanding,
passage use, thesis, argumentation, structure, expression, university rubric,
overall feedback and improvements. Candidate dimensions for
`short_response` include required elements, concept accuracy, requirement
coverage, omissions, expression accuracy, partial score and comparison with
the official answer/example answer. The final contract follows research and
benchmarking.

## 5. Structured AI evaluation contract

Essay Lab must not score by simple string or sentence similarity between a
student answer and a model answer. Each question needs a structured
`EssayEvaluationPackage` containing, at minimum:

- university, year and track
- question and passages
- prompt requirements
- intended reasoning and required concepts
- official rubric where available
- model/example answer
- common mistakes
- deduction criteria

Evaluation input is the question, passages, intended reasoning, rubric,
example answer and student answer. University-specific official criteria take
priority when available.

Initial result dimensions may include:

- overall evaluation
- topic/question understanding
- use of passages
- logic and argumentation
- structure
- expression
- requirement coverage
- strengths and weaknesses
- missing key points
- weak reasoning
- concrete improvements
- structural comparison with the model answer

Results must never be presented as an actual university admission probability
or admission decision. Preferred language is “current answer evaluation” and
“university-specific essay adaptation,” not “pass probability.”

## 6. Credits and abuse policy

The default free offer is three initial AI feedback uses per account, not a
monthly recurring allowance. Credits and usage are server-side entitlements;
the client cannot increase the allowance.

The request lifecycle should be designed as:

`credit check → reserve → evaluation → success settlement`

Failure must support safe credit restoration or settlement. Candidate data
concepts include `essay_entitlements` and `essay_usage`, but no schema is
approved or implemented by this roadmap.

Initial anti-abuse posture:

- three initial uses per account
- abnormal-usage detection and rate limiting
- device-level abuse signals only if needed
- phone verification considered later

Do not make high-friction identity verification mandatory at launch or collect
excessive fingerprints/personal data. The primary long-term retention lever is
the value of accumulated personal essay data, not aggressive blocking.

## 7. Personal essay pattern and conversion

Each evaluation should contribute to a cumulative “My Essay Pattern” profile
rather than ending as an isolated result. The profile can surface strengths,
repeated weaknesses and improvement trends, for example repeated lack of
passage comparison, insufficient counterargument review or unsupported
conclusions.

The intended free-to-paid progression is:

1. First use: initial essay diagnosis.
2. Second use: repeated-pattern analysis begins.
3. Third use: first personal essay pattern is generated, followed by a paid
   CTA based on continued tracking.

Free evaluations must not be intentionally degraded. The value proposition is
that later paid work preserves and extends a real personal improvement history.

For every evaluation, retain item-level score/history where the final data
model permits it. Future views may include growth graphs, repeated weaknesses,
improvement/stagnation, university differences and before/after answer
comparison.

## 8. Coach and university analysis extensions

Future coaching can provide “what to focus on in this answer” before writing,
based on prior weaknesses, then measure whether that weakness improved after
submission. The long-term loop is:

`diagnosis → weakness → practice goal → writing → feedback → improvement measurement`

With enough answers across universities, the service may show university-
specific strengths, weaknesses, recent evaluations and rubric differences.
It must continue to avoid admission-probability claims.

## 9. Web-primary and Mobile roles

The Web is the primary Essay Lab environment. Web capabilities include:

- side-by-side question/passages and long-form writing
- character count
- submission and AI evaluation
- result review
- model-answer comparison
- cumulative analysis
- My Essay Pattern

Mobile capabilities focus on discovery, result review, notifications and
simple record/connection flows. Long-form writing remains Web-primary.

The public service is LegendStudy LAB at `https://lab.legendstudy.com/`.
The production Web architecture
decision is recorded below; the existing Manus React/Vite/Express/tRPC build
remains a mock foundation and is not a Production architecture commitment.

## 10. Production Web architecture decision

Status: **APPROVED / DOCUMENTATION ONLY**.

The canonical Production direction for **LS LAB by LegendStudy** is:

- separate Next.js Web repository, App Router and TypeScript;
- public catalog pages with SEO, SSR/SSG, metadata and structured data;
- authenticated private workspace with server-only evaluation boundaries;
- shared Supabase Auth identity with clearly isolated LS LAB schema/RLS;
- server-side AI execution that can later move to a background worker/queue;
- future streaming and Web credit/payment integration.

The earlier repository candidate was `LC3808/legendstudy-lab-web`; the actual
Owner-confirmed Web repository is `LC3808/legendstudy-lab`. The
existing `LC3808/legendstudy-app` remains Flutter Mobile-only. The projects are
not merged into a monorepo. Deeper Web capabilities remain a separate task;
the app integration above only opens its public entry.

### Public and private data boundary

The minimum four-layer boundary is:

1. `PUBLIC_METADATA`: university, campus, year, track, exam metadata,
   provenance and official Quick Links.
2. `PRIVATE_SOURCE_DERIVED_ASSET`: normalized question/passage structure,
   official-intent extraction, source page/hash and review notes.
3. `PRIVATE_EVALUATION_ASSET`: LS LAB rubrics, answer elements, scoring logic,
   benchmarks, prompts, calibration and evaluator versions.
4. `USER_PRIVATE_DATA`: student answers, revisions, evaluations, history and
   My Essay Pattern.

LS LAB does not mirror or re-distribute official exam originals by default.
Public Web links users from university/year/track metadata to the university's
official source or download Quick Link. Source provenance is shown clearly.
Private source-derived and evaluation assets must not be shipped in a public
browser bundle.

Official and derived material must remain distinguishable as
`OFFICIAL_SOURCE`, `LSLAB_DERIVED`, `MODEL_DERIVED` and `HUMAN_REVIEWED`.
LS LAB learning scores or criterion statuses must not be represented as
official university scores unless a mapping has been independently validated.
Rights/use risk, source readiness and evaluation readiness remain separate
registers; private architecture is not a way to evade rights restrictions.

### Evaluation, jobs and credits

Candidate question-level taxonomy is `long_essay_document_analysis`,
`structured_short_response`, `math_proof`, `science_response` and
`mixed_aat_structured_response`. Final taxonomy follows question-package QA;
special-format universities such as 부산대 and 경북대 are not forced into a
generic long-essay prompt.

An MVP evaluation may run through a Next.js server endpoint, but the product
contract is job-oriented: `CREATED → CREDIT_RESERVED → PROCESSING →
COMPLETED`, with `PROCESSING → FAILED` and safe credit release/restore.
The credit contract is server-authoritative `CHECK → RESERVE → EVALUATE →
SETTLE`; the initial free-use direction is not hard-coded as a client counter.

### Prototype reuse and non-goals

Manus foundation assets that may be reused include IA, UI concepts, route flow,
TypeScript types, research metadata, fixtures, design tokens, Essay Workspace,
Evaluation Result and My Essay Pattern UX. Its Express backend, tRPC contract,
mock Auth, localStorage-only persistence and mock evaluator are not Production
contracts.

Phase 2 is **Next.js Web Foundation Migration**: separate repository candidate,
App Router shell, public metadata catalog, official Quick Link UX,
synthetic/mock workspace and evaluation, My Essay Pattern mock, and public /
private server boundaries. Production Supabase integration/Auth, DB migration,
live AI, payment, real student data, domain purchase and public deployment are
explicitly prohibited until separate approval.

## 11. Commercial direction

The initial model should prefer credit/packages over subscription or unlimited
plans:

- free initial 3 uses
- candidate 3-, 5- and 10-use packages
- possible intensive essay pass

Pricing remains undecided pending real inference cost, payment fees, user
response, competing-service pricing and conversion data. Web payment is the
initial direction for the October MVP; selling digital credits inside the
mobile apps requires separate Apple/Google policy review. A Web-purchase / App-
review model may be considered.

## 12. Manus phases and milestones

Target: **October 2026 Beta or initial service release**.

Planned sequence:

1. Stabilize current LegendStudy.
2. Home Polish v2.
3. Minimum legacy subject-alias design.
4. **Manus Phase 0 — nationwide survey: COMPLETE:** identified all
   2027학년도 수시 논술 실시 대학 nationwide from official sources.
5. **Manus Phase 1 — first-wave selection and inventory: COMPLETE:** audited
   Seoul universities broadly plus representative non-Seoul formats and
   inventoried2020 onward (at least five years) of source/official materials where available.
6. Define the taxonomy, data model and track-specific evaluation contracts from
   the researched formats.
7. Build an AI evaluation proof of concept and benchmark it by track.
8. **Manus Phase 2 — LS LAB Web MVP foundation:** build the Web-primary shell
   and Essay Lab authoring/result foundation using researched content only.
9. Add cumulative essay profile/patterns.
10. Add server-side free-credit entitlements.
11. Add Web payment.
12. Closed Beta.
13. October Beta/initial public release.

The milestone list above is the historical Essay-module plan, not current
cross-product ordering. The2026-09-27 Owner decision puts Essay before analytics;
Admission Simulator remains a separately gated candidate.
Any reuse of Selty assets requires a legacy-system audit before implementation.

## 13. Historical Exam Expansion — LegendStudy App

The separate LegendStudy App materials expansion proceeds in stages:

1. Phase 1: 2020 to present.
2. Phase 2: 2015 to 2019.
3. Phase 3: 2010 to 2014.

Each phase follows `inventory → mapping → quarantine → validation →
publication`. Legacy subject aliases and historical taxonomy are preserved.
The full 2010-present range is not ingested in one batch.

## 14. Home canonical order

The canonical Home order is D-Day → 나의 공부 시간 → 급식 → 자료 검색 →
최근 본 자료 → 최근 업데이트. Recent views are behavior-based personal
information and therefore precede the global new-content feed. Home
personalization is not implemented as a temporary local-only preference; user
type, Home visibility and cloud persistence belong together in Day 13-A.

## 15. Non-goals for this roadmap entry

This entry does not implement Flutter UI, Web UI, database tables, RLS,
entitlements, AI prompts/evaluation, billing, OCR, ingestion or Production
changes. Those require separate approved design and implementation tasks.

## 16. 2026-09-18 product decisions — essay-centric model and Core-first depth

Recorded here so the roadmap and `current-status.md` do not drift. Detail and
current state live in [current-status.md](current-status.md).

- **Within the Essay module: essay-centric, not 전형-centric.** A university's administrative 전형명
  (논술우수자전형, 논술전형, 논술일반전형 …) is provenance metadata. To a
  student the product is **ESSAY (논술)**. Canonical hierarchy: University →
  Essay → Essay Track → QuestionSet → Question.
- **Track candidates:** HUMANITIES, BUSINESS_ECONOMICS, NATURAL_ENGINEERING,
  MEDICAL_PHARMACY, ARTS_SPORTS, UNKNOWN.
- **Four separate axes.** Track ≠ problem format ≠ answer format ≠ input mode.
  They are modelled independently and must not be merged.
- **Core-first depth.** CORE / NEXT / CATALOG_ONLY / UNDECIDED. Deep AI
  evaluation begins with roughly 10–15 Core universities instead of covering
  all 42 shallowly; the full 42-university catalog is preserved regardless.
  Core membership is a Product Owner decision only.
- **Reference University #1 sequence** (after Core is fixed): recent approved
  years → Track → QuestionSet → Question → problem/answer/input format →
  공식 출제의도 → 공식 해설 → 공식 채점기준 → 대학 제공 우수·합격자 답안 →
  private Gold Evaluation Package → evaluator benchmark.
- **Gold Evaluation Package is private.** It never enters the Public Catalog,
  and 우수·합격자 답안 are evaluation references, not sentence-level answers.
- **Multimodal is staged.** `answer_format` and `input_mode` are distinct;
  input modes are TEXT_EDITOR, HANDWRITTEN_IMAGE, TEXT_AND_IMAGE, SHORT_TEXT,
  UNKNOWN. Handwritten maths/science flows through 촬영 → quality gate →
  ordered multi-page upload → Vision interpretation → structured answer, with
  image provenance kept and OCR never the sole source of truth. A PC↔Mobile QR
  upload session is short-lived, attempt-scoped and single-purpose, and carries
  no user id, JWT, service-role key or permanent token. Current implementation
  is NONE; V1 is text-first.
- **LS LAB for Schools** (institutional credits, per-student assignment,
  teacher/admin management, usage monitoring) follows B2C, with Education
  Office / institutional expansion beyond it. Not implemented.
- **Status on 2026-09-18: Core selection is HOLD until the Owner review next
  week.** This historical entry does not override the 2026-09-20 product/platform decision.

### 2026-10-11 Owner final policy — 22 focus / 30 retained / 42 public

This explicit named decision supersedes prior uncertainty about the first focus set;
it does not reduce the existing30 preparation cohort or42-university/49-offering
Public Catalog. The Owner designates the following22 as the first development focus,
described as2027 applicants top22. That approval is a planning authority, not independent
verification of numerical applicants/rates. The retained Master contains no verified
applicant/competition fields, so the UI must not invent numbers or statistical ordering.

1. 가천대학교
2. 중앙대학교
3. 성균관대학교
4. 경희대학교
5. 한양대학교
6. 한국외국어대학교
7. 고려대학교
8. 국민대학교
9. 건국대학교
10. 서강대학교
11. 이화여자대학교
12. 숭실대학교
13. 인하대학교
14. 동국대학교
15. 세종대학교
16. 연세대학교
17. 홍익대학교
18. 아주대학교
19. 삼육대학교
20. 경북대학교
21. 경기대학교
22. 부산대학교

GROUP A: 가천·삼육·경북·부산 (short-answer-oriented development planning).
GROUP B: the remaining18 (long-answer-oriented development planning). These are
internal UX/work groups, not official admission labels, rubric definitions or evaluator
routing. E.g. Pusan official integrated-humanities/math labels remain unchanged;
Math questions always retain the existing Math contract. Unknowns are not guessed.

The existing30 research preparation rows below remain intact. 고려·국민·삼육 are
additional Owner focus members outside that preserved cohort: union33, not a forced
replacement of three earlier universities. Evidence gaps do not remove any member.
강남·을지 remain deferred special-format review and stay public. No autonomous
university removal, ranking or future cap is permitted.

Public display: all42 remain the default searchable, name-sorted view. A separate
주요 대학 view includes exact22 + universities with verified Seoul offerings.
The additional>=8000-applicants rule awaits verified counts, not invented values;
all potentially qualifying universities remain discoverable in the complete view.
No GROUP/CORE or Owner rank is shown as university quality/prestige to students.

### Catalog/detail UX and public data projection — Oct11

Reuse one generated Catalog, shared original university/offering/source IDs and
27 actual DB UUIDs/15 nulls. UI does not create a second database or guess missing IDs.
White cards sit on a muted surface, with restrained shadow, type/status badges,
Dark Navy44–48px actions, equal-row button alignment, keyboard focus and reduced motion.
Intrinsic rem-based columns reflow4/2/1 and at enlarged text. Detail has university
Hero, section navigation, structured admissions facts, scoped characteristics,
intake/schedule facts, actual past questions, honest AI availability and separate
source cards. Dates are original verification dates; admissionyear and examyear stay
separate. No forced fixed heights or clipped long campus names.

APP `tool/essay_lab/public_catalog.py` extends the existing projection with per-Master
row facts: intake/time/date/answer-format/CSAT/weights when recorded, unknowns omitted.
Separate recruitment tracks are never summed (e.g. Pusan general/regional21).
Source status and document basis travel with each row; implementation-plan material
is labelled as such. Existing10 Manus official-source inventories supply reference
links only. Private Evidence Packages, PDF bodies, model prompts, answers and
rights-gated content are not copied into the public bundle. Verified literal 약술/단답
may add a discovery badge, never an engine rule. Applicants/rates remain null.

Preservation review: source/recorded dates separate; raw Master/research kept immutable;
projection regenerated with hashes; no learning/history UPDATE; no Auth UID change;
Learning/Decision/Outcome data untouched; public admissions facts only/no new personal
collection; derived UI labels and Owner priority never treated as raw official facts.
Existing42:58 writer/mobile tabs, five-level results/rewrite/growth/History, Math,
Credit Ledger, Auth, Quality and evaluation GATE remain untouched. Public AI HOLD.
Release verification belongs in the existing task evidence/current log, not duplicated
here. Future applicant sorting requires scoped official2027 statistics first.

### 2026-10-11 Owner scope correction — current service preparation scope

**Current authority: priority service preparation at least20 universities, at least15
in Seoul/Gyeonggi/Incheon, with Pusan National and Kyungpook National required.
20 is a floor, not a ceiling.** The historical10–15 Core strategy above is retained
as the original validation strategy; it MUST NOT limit current preparation scope.
Scope/A-stage membership is distinct from CORE assignment and production activation.

#### Restoration basis and correction

The previous11-entry note incorrectly used the10 deeply reviewed Manus universities
plus Owner-priority Pusan as the service preparation queue. It was not an implemented
catalog/API limit: all42 universities/49 offerings were already deployed. Nevertheless,
the planning scope was too narrow and is superseded here, preserving all11 entries.

Unified Wiki/current/Daily, APP roadmap and historical Owner checkpoint, Git strategy
history, Manus V2 policy/research and2027 Master were compared. The retained policy
records15 **candidates** with Owner decisions blank, not a later approved named list.
No complete previously approved expanded membership was found in the available
records; do not invent its approval. The Owner's current correction takes precedence.

Manus `research/essay-lab-research-report.md` §1/§4 explicitly names a **30-university
inventory**:10 detailed research entries +20 less-reviewed candidates. Restore ALL30
as the current A-stage preparation set, not an arbitrary new top20 or ranking.
The old research label `Hold` for20 candidates means insufficient evaluation evidence,
not removal from A-stage. Compare each with the existing public Catalog/Master source
IDs, campus, type and verified official admissions links; unknowns stay unknown.

**Current30 / unique metropolitan28**: Seoul offerings21, Gyeonggi/Incheon offerings11,
with4 universities present in both (경희·성균관·중앙·한국외대). These regional counts
are overlapping university counts, not32 unique metropolitan universities. Pusan and
Kyungpook add2. Campus distinctions for Yonsei/Kyunghee/HUFS/etc remain unchanged.
No university is deleted from the full42. Further Owner-approved membership is added
without a20/30 cap; the remaining12 public entries are retained, not declared excluded
from future service. Gangnam/Eulji retain explicit special-format deferred review.

Previously missing from the11-entry preparation note (19 restored):
가천대학교, 가톨릭대학교, 경기대학교, 상명대학교, 서강대학교, 서경대학교, 서울과학기술대학교, 서울시립대학교, 서울여자대학교, 성신여자대학교, 세종대학교, 숭실대학교, 아주대학교, 이화여자대학교, 인하대학교, 중앙대학교, 한국외국어대학교, 한국항공대학교, 홍익대학교.

#### Readiness contract (independent evidence states A–H)

A = preparation target; B = official material evidence; C = structured questions;
D = rubric; E = private Evidence Package; F = production Worker connection;
G = actual Provider proof for the exact official question/runtime; H = public activation.
A never requires B–H completion. B admissions URL ≠ official question/rubric acquired.
Research `READY` ≠ rights cleared, structured/imported, Worker deployed or Provider
verified. Existing historical pilots/Math E2E are retained but not relabelled as
30-university official Humanities production verification. No new Provider call.

All30 have verified-at2026-09-18 admissions source links in the existing49-offering
projection.10 have retained detailed research;5 have scoped official inner-content/
rubric findings (경희·동국·성균관·한양·광운).3 historical private packages are retained
(SKKU2025, Hanyang2024 afternoon2, Sookmyung2025), not newly published. SKKU2025 has
3 locally structured questions/9 criteria/1 package; Q1 remains the first runtime
integration target, Q2/Q3 stay graph-blocked. Hanyang canonical-exam mapping remains
unverified. Other unknown/unstructured questions and rubric gaps are not marked PASS.
F/G current official Humanities production-ready count0; H HOLD for every row.

| University / source ID | Region / campus scope / verified public types | A | B official material | C questions | D rubric | E package | F Worker | G Provider | H |
|---|---|---|---|---|---|---|---|---|---|
| 가천대학교 (`gachon`) | 경기·인천; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://admission.gachon.ac.kr/upload/BBS0021/20260522154511HBZYTW.PDF) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 가톨릭대학교 (`catholic`) | 경기·인천; 1 전형; 수리·인문 | 대상 | [전형 출처](https://cdn013.negagea.net/dgsmidc/omr/seoul/web/univ_info2025/%EA%B0%80%ED%86%A8%EB%A6%AD%EB%8C%80%ED%95%99%EA%B5%90/%EA%B0%80%ED%86%A8%EB%A6%AD%EB%8C%80%ED%95%99%EA%B5%90_2027%ED%95%99%EB%85%84%EB%8F%84_%EB%8C%80%ED%95%99%EC%9E%85%ED%95%99%EC%A0%84%ED%98%95%EA%B3%84%ED%9A%8D.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 건국대학교 (`konkuk`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](https://admission.konkuk.ac.kr/admission/37981/subview.do) · 상세 연구/미추출 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 경기대학교 (`kyonggi`) | 경기·인천; 1 전형; 수리·인문 | 대상 | [전형 출처](https://enter.kyonggi.ac.kr/ajaxfile/FR_SVC/FileDownload.do?FILE_ORG_NM=%EA%B2%BD%EA%B8%B0%EB%8C%80_2027%EC%88%98%EC%8B%9C%EB%AA%A8%EC%A7%91%EC%9A%94%EA%B0%95%28%EA%B3%B5%EC%A7%80%EC%9A%A9%29.pdf&FILE_NM=202606/1781506250597_0.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 경북대학교 (`knu`) | 기타 지역; 1 전형; 인문 | 대상 | [전형 출처](https://ipsi1.knu.ac.kr/mojib/?m_type=SUSI) · 상세 연구/미추출 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 경희대학교 (`kyunghee`) | 경기·인천 / 서울; 2 전형; 과학·수리·인문 | 대상 | [전형 출처](https://iphak.khu.ac.kr/file/download.do?sfn=20260826010029371_2027%ed%95%99%eb%85%84%eb%8f%84+%ea%b2%bd%ed%9d%ac%eb%8c%80%ed%95%99%ea%b5%90+%ec%88%98%ec%8b%9c+%eb%aa%a8%ec%a7%91%ec%9a%94%ea%b0%95-%ec%b5%9c%ec%a2%85_20260811%28%ea%b3%b5%ec%a7%80%29.pdf&ofn=2027%ed%95%99%eb%85%84%eb%8f%84+%ea%b2%bd%ed%9d%ac%eb%8c%80%ed%95%99%ea%b5%90+%ec%88%98%ec%8b%9c+%eb%aa%a8%ec%a7%91%ec%9a%94%ea%b0%95-%ec%b5%9c%ec%a2%85_20260811%28%ea%b3%b5%ec%a7%80%29.pdf) · 범위 한정 원문 확인 | 원문 확인/구조화 대기 | 범위 한정 확인/정규화 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 광운대학교 (`kwangwoon`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](https://iphak.kw.ac.kr/upload_data/mojib/20260526155135_27.pdf) · 범위 한정 원문 확인 | 원문 확인/구조화 대기 | 범위 한정 확인/정규화 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 단국대학교 (`dankook`) | 경기·인천; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://ipsi.dankook.ac.kr/jukjeon/notice/list.html?bbsid=juk_info&bltn_seq=50954&mode=view&ctg_cd=01) · 상세 연구/미추출 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 동국대학교 (`dongguk`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](https://ipsi.dongguk.edu/upload/file/20260623144248DQV7LA.PDF) · 범위 한정 원문 확인 | 원문 확인/구조화 대기 | 범위 한정 확인/정규화 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 부산대학교 (`pnu`) | 기타 지역; 1 전형; 수리·인문 | 대상 | [전형 출처](https://go.pusan.ac.kr/college_2016/pages/index.asp?p=3&mj=01) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 상명대학교 (`sangmyung`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](http://admission.smu.ac.kr/_seoul/board/bbs.html?bbsid=seoul_dataroom&ctg_cd=susi) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 서강대학교 (`sogang`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](http://admission.sogang.ac.kr/upload/GUIDES/20250430181056FTR2FK.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 서경대학교 (`seokyeong`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://cdn013.negagea.net/dgsmidc/omr/seoul/web/univ_info2026/%EC%84%9C%EA%B2%BD%EB%8C%80%ED%95%99%EA%B5%90/%EC%84%9C%EA%B2%BD%EB%8C%80%ED%95%99%EA%B5%90_2027%ED%95%99%EB%85%84%EB%8F%84_%EC%88%98%EC%8B%9C%EB%AA%A8%EC%A7%91%EC%9A%94%EA%B0%95.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 서울과학기술대학교 (`seoultech`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://cdn013.negagea.net/dgsmidc/omr/seoul/web/univ_info2025/%EC%84%9C%EC%9A%B8%EA%B3%BC%ED%95%99%EA%B8%B0%EC%88%A0%EB%8C%80%ED%95%99%EA%B5%90/%EC%84%9C%EC%9A%B8%EA%B3%BC%ED%95%99%EA%B8%B0%EC%88%A0%EB%8C%80%ED%95%99%EA%B5%90_2027%ED%95%99%EB%85%84%EB%8F%84_%EB%8C%80%ED%95%99%EC%9E%85%ED%95%99%EC%A0%84%ED%98%95%EA%B3%84%ED%9A%8D.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 서울시립대학교 (`uos`) | 서울; 1 전형; 수리 | 대상 | [전형 출처](https://file.uos.ac.kr/upload/admission/2027%ED%95%99%EB%85%84%EB%8F%84%20%EC%88%98%EC%8B%9C%EB%AA%A8%EC%A7%91%20%EC%8B%A0%EC%9E%85%EC%83%9D%20%EB%AA%A8%EC%A7%91%EC%9A%94%EA%B0%95.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 서울여자대학교 (`swu`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://www.swu.ac.kr/bbs/swu/157/138473/artclView.do?layout=unknown) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 성균관대학교 (`skku`) | 경기·인천 / 서울; 2 전형; 수리 | 대상 | [전형 출처](https://admission.skku.edu/admission/html/rolling/guide.html) · 범위 한정 원문 확인 | 2025 3문항 로컬 | 9기준 로컬 | 기존 비공개 보존 | 어댑터 계약만/미배포 | 운영 미검증 | HOLD |
| 성신여자대학교 (`sungshin`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://ipsi.sungshin.ac.kr/guide/dataroom.htm?bbsid=notice&ctg_cd=all&mode=view&bltn_seq=36050) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 세종대학교 (`sejong`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](https://ipsi.sejong.ac.kr/ipsi/early/notice.do?mode=view&articleNo=2785) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 숙명여자대학교 (`sookmyung`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://admission.sookmyung.ac.kr/admission/html/counsel/noticeView.asp?p_board_idx=54119) · 상세 연구/미추출 | 보존 패키지/운영 미연결 | 기존 패키지 범위/재검증 | 기존 비공개 보존 | 운영 미연결 | 운영 미검증 | HOLD |
| 숭실대학교 (`soongsil`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://iphak.ssu.ac.kr/upload/2027_plan.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 아주대학교 (`ajou`) | 경기·인천; 1 전형; 과학·수리·인문 | 대상 | [전형 출처](https://www.iajou.ac.kr/_common/new_download_file.php?menu=boardfile&file_no=4601) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 연세대학교 (`yonsei`) | 기타 지역 / 서울; 2 전형; 과학·수리·인문 | 대상 | [전형 출처](https://mirae.yonsei.ac.kr/wj/2349/subview.do) · 상세 연구/미추출 | 미구조화 | NEEDS_RUBRIC | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 이화여자대학교 (`ewha`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](https://admission.ewha.ac.kr/admission/html/ewharo/noticeView.asp?idx=14986) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 인하대학교 (`inha`) | 경기·인천; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://cdn013.negagea.net/dgsmidc/omr/seoul/web/univ_info2025/%EC%9D%B8%ED%95%98%EB%8C%80%ED%95%99%EA%B5%90/%EC%9D%B8%ED%95%98%EB%8C%80%ED%95%99%EA%B5%90_2027%ED%95%99%EB%85%84%EB%8F%84_%EB%8C%80%ED%95%99%EC%9E%85%ED%95%99%EC%A0%84%ED%98%95%EA%B3%84%ED%9A%8D.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 중앙대학교 (`cau`) | 경기·인천 / 서울; 2 전형; 유형 미확인 | 대상 | [전형 출처](https://admission.cau.ac.kr/) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 한국외국어대학교 (`hufs`) | 경기·인천 / 서울; 2 전형; 유형 미확인 | 대상 | [전형 출처](https://cdn013.negagea.net/dgsmidc/omr/seoul/web/univ_info2025/%ED%95%9C%EA%B5%AD%EC%99%B8%EA%B5%AD%EC%96%B4%EB%8C%80%ED%95%99%EA%B5%90/%ED%95%9C%EA%B5%AD%EC%99%B8%EA%B5%AD%EC%96%B4%EB%8C%80%ED%95%99%EA%B5%90_2027%ED%95%99%EB%85%84%EB%8F%84_%EB%8C%80%ED%95%99%EC%9E%85%ED%95%99%EC%A0%84%ED%98%95%EA%B3%84%ED%9A%8D.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 한국항공대학교 (`kau`) | 경기·인천; 1 전형; 수리·인문 | 대상 | [전형 출처](https://cdn013.negagea.net/dgsmidc/omr/seoul/web/univ_info2025/%ED%95%9C%EA%B5%AD%ED%95%AD%EA%B3%B5%EB%8C%80%ED%95%99%EA%B5%90/%ED%95%9C%EA%B5%AD%ED%95%AD%EA%B3%B5%EB%8C%80%ED%95%99%EA%B5%90_2027%ED%95%99%EB%85%84%EB%8F%84_%EB%8C%80%ED%95%99%EC%9E%85%ED%95%99%EC%A0%84%ED%98%95%EA%B3%84%ED%9A%8D.pdf) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |
| 한양대학교 (`hanyang`) | 서울; 1 전형; 유형 미확인 | 대상 | [전형 출처](https://site.hanyang.ac.kr/documents/11081467/141054756/2027%ED%95%99%EB%85%84%EB%8F%84+%ED%95%9C%EC%96%91%EB%8C%80%ED%95%99%EA%B5%90+%EC%8B%A0%EC%9E%85%ED%95%99+%EC%A0%84%ED%98%95%EA%B3%84%ED%9A%8D.pdf/027468c2-d69a-e7b4-9437-1e66d12f76f4?t=1745975250171) · 범위 한정 원문 확인 | 보존 패키지/운영 미연결 | 기존 패키지 범위/재검증 | 기존 비공개 보존 | 운영 미연결 | 운영 미검증 | HOLD |
| 홍익대학교 (`hongik`) | 서울; 1 전형; 수리·인문 | 대상 | [전형 출처](https://www.hongik.ac.kr/kr/admission/recruitment.do?mode=download&articleNo=152315&attachNo=91150) · 문항 원문 미검증 | 미구조화 | 미확인/추출 대기 | 미준비 | 운영 미연결 | 운영 미검증 | HOLD |

#### Scope preservation and next work

Keep the existing11 universities' evidence and completed runtime/UI work. First close
SKKU2025Q1 rights/content/host dependencies, while the30-row A-stage list remains
intact. Reuse Hanyang/Sookmyung packages; prioritize Pusan/Kyungpook official evidence;
continue scoped Kyunghee/Dongguk/Kwangwoon structure review and remaining source/rubric
gaps. This is work ordering, never an A-stage cap or automatic CORE designation.
Demand/intake/engine-fit/cost inform review, not prestige or region alone. Existing
Master Pusan048/049 intake scopes may overlap: never sum them. Unknown demand and
rubric facts remain unknown. No repeated research or invented university IDs/URLs.

Gangnam and Eulji: special-format deferred review, still public. The other retained
Catalog entries without this30-university research inventory are not removed or
assigned CATALOG_ONLY by an agent. Public UI never displays internal tiers.

Read-only public metadata projection remains42/49 with no11/20/30 service cap.
Student answers/history, canonical ID/null boundaries, private evidence, dates and
raw source records are preserved. No new personal/decision/outcome data collection.
Evaluation still requires exact question/rubric/evidence + Provider/Worker + existing
Credit/History + allowlist and server GATE; catalog release grants no execution.

## 2026-09-23 App entry and future preparation data

App LAB labels the existing safe public Web entry 논술 준비. Existing LAB public
coverage/university content is reused; no new university/essay schema. Read-only
LAB repository inspection found public information and product foundations, not a
verified persistent personal target/answer/evaluation API for this App. No App
session/token passes through URL and no WebView is added. Target universities are
future Essay domain data (university, questions, authored answers, evaluation
history, preparation status), not Profile fields. MY essay counts/summary stay
hidden until real data and an App/Web contract exist. LAB repo unchanged.
