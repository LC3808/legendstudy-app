# LegendStudy Product Roadmap — Essay Lab

Status: **PLANNED**  
Target: **2026-10 Beta or initial public service**

This document records a product priority change. It is a roadmap, not an
implementation claim. No Essay Lab code, schema, AI evaluation, payment
integration or Production change is included in this entry.

## 1. Product direction

LegendStudy is planned as one service with three connected surfaces:

1. LegendStudy Mobile App
2. LegendStudy Web App (working name: Lstudy.com)
3. Shared Supabase backend

The App and Web share Supabase Auth, profiles, essay submissions, evaluations,
usage/credits, bookmarks/recent data and, later, academic profile data. Essay
authoring and detailed analysis are Web-primary. Mobile focuses on problem
discovery, result review, accumulated progress, notifications and continuing
on the Web.

The priority after current product stabilization is AI essay feedback (Essay
Lab), ahead of grade analysis and admission prediction. The timing is driven
by the 2026 admissions calendar and the concentration of university essay
exams after the November CSAT. Academic Profile and Admission Simulator remain
later initiatives.

## 2. Essay Lab MVP

Initial user flow:

`university → year/track/question → question and passages → text answer → submit → AI feedback → result → cumulative profile update`

The MVP supports typed answers only. Handwriting OCR and photo answers are
LATER scope.

The first content inventory must review the existing `legendstudy.com` assets:

- university-specific essay past questions
- questions and passages
- explanations
- model/example answers
- intended reasoning
- scoring criteria/rubrics

Inventory comes before implementation. Start with approximately 5–10
universities with sufficient material, prioritizing the latest 2–3 years;
do not attempt all universities at once.

## 3. Structured AI evaluation contract

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

## 4. Credits and abuse policy

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

## 5. Personal essay pattern and conversion

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

## 6. Coach and university analysis extensions

Future coaching can provide “what to focus on in this answer” before writing,
based on prior weaknesses, then measure whether that weakness improved after
submission. The long-term loop is:

`diagnosis → weakness → practice goal → writing → feedback → improvement measurement`

With enough answers across universities, the service may show university-
specific strengths, weaknesses, recent evaluations and rubric differences.
It must continue to avoid admission-probability claims.

## 7. Web-first experience

The Web is the primary Essay Lab authoring environment. MVP Web capabilities:

- side-by-side question/passages
- long-form editor
- character count
- submission and AI evaluation
- result review
- model-answer comparison
- cumulative analysis
- credit purchase/payment

Mobile capabilities focus on problem discovery, result review, compact charts,
cumulative weaknesses, notifications and “continue on Web.”

Next.js/React with the existing Supabase backend is a leading candidate, while
Flutter Web remains possible. The Web stack is **not decided** until editor,
rich text, charts, SEO, public admissions content, university comparison and
payment requirements are reviewed.

## 8. Commercial direction

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

## 9. Milestones and priority

Target: **October 2026 Beta or initial service release**.

Planned sequence:

1. Stabilize current LegendStudy.
2. Home Polish v2.
3. Minimum legacy subject-alias design.
4. Essay content inventory.
5. Select the first 5–10 universities.
6. Define the essay data model.
7. Build an AI evaluation proof of concept.
8. Build the Web MVP.
9. Add cumulative essay profile/patterns.
10. Add server-side free-credit entitlements.
11. Add Web payment.
12. Closed Beta.
13. October Beta/initial public release.

Academic Profile (school grades, subject grades/credits, mock exams and trend
charts) and Admission Simulator are explicitly **LATER**, after Essay Lab.
Any reuse of Selty assets requires a legacy-system audit before implementation.

## 10. Non-goals for this roadmap entry

This entry does not implement Flutter UI, Web UI, database tables, RLS,
entitlements, AI prompts/evaluation, billing, OCR, ingestion or Production
changes. Those require separate approved design and implementation tasks.
