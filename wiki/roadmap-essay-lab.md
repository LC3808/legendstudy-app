# LegendStudy Product Roadmap — Essay Lab / LS LAB

Status: **RESEARCH COMPLETE / DEEP INTEGRATION PLANNED; PUBLIC APP ENTRY IMPLEMENTED**
Target: **2026-10 Beta or initial public service**

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

The formal service name and domain are **TBD**. `ls-lab.com` is already in use;
domain selection is not a blocker for Web MVP work, which may use localhost,
temporary development URLs or previews.

LS LAB should be a Web service shell that can later expand to Essay Lab,
grade analysis, Academic Profile and admission prediction. Essay Lab remains
the first product area; grade analysis and admission prediction are later.
The App and Web may share Auth, profiles, essay submissions, evaluations,
usage/credits, bookmarks/recent data and later academic-profile data. Essay
authoring and detailed analysis are Web-primary.

The priority after current product stabilization is AI essay feedback (Essay
Lab), ahead of grade analysis and admission prediction. The timing is driven
by the 2026 admissions calendar and the concentration of university essay
exams after the November CSAT. Academic Profile and Admission Simulator remain
later initiatives.

## 2. Research prerequisite and nationwide inventory

Before building the Essay Lab university inventory, perform a nationwide
survey of universities conducting 논술고사 in the 2027학년도 수시모집.
The inventory must be grounded in official 2027 admissions plans,
전형계획, university admissions-office materials and other official sources.
This is the prerequisite for selecting the first service universities and is a
Manus Research task. Do not assume a university count in advance.

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
The default coverage target is the latest **three years**, subject to what is
officially available:

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
   inventoried the latest three years of official materials where available.
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

Academic Profile (school grades, subject grades/credits, mock exams and trend
charts) and Admission Simulator are explicitly **LATER**, after Essay Lab.
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

- **Essay-centric, not 전형-centric.** A university's administrative 전형명
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
  week.** Sections 1–15 above are unchanged by this entry.
