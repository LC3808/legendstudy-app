# LegendStudy Product Roadmap — Essay Lab / LS LAB

Status: **PLANNED**  
Target: **2026-10 Beta or initial public service**

This document records a product priority change. It is a roadmap, not an
implementation claim. No Essay Lab code, schema, AI evaluation, payment
integration or Production change is included in this entry.

The previous initial scope of approximately 5–10 universities and the latest
2–3 years is superseded by the research-first rules below. No university count
is assumed before the nationwide survey.

## 1. Product direction

LegendStudy is planned as one service with three connected surfaces:

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

The Web stack is **not decided** until editor, rich text, charts, SEO, public
admissions content, university comparison and payment requirements are
reviewed. The formal service name and domain remain TBD.

## 10. Commercial direction

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

## 11. Manus phases and milestones

Target: **October 2026 Beta or initial service release**.

Planned sequence:

1. Stabilize current LegendStudy.
2. Home Polish v2.
3. Minimum legacy subject-alias design.
4. **Manus Phase 0 — nationwide survey:** identify all 2027학년도 수시
   논술 실시 대학 nationwide from official sources.
5. **Manus Phase 1 — first-wave selection and inventory:** select Seoul
   universities broadly plus representative non-Seoul formats, then inventory
   the latest three years of official materials.
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

## 12. Non-goals for this roadmap entry

This entry does not implement Flutter UI, Web UI, database tables, RLS,
entitlements, AI prompts/evaluation, billing, OCR, ingestion or Production
changes. Those require separate approved design and implementation tasks.
