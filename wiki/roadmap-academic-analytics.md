# Academic Analytics → Achievement → Admissions Engine Roadmap

## Platform and B2B clarification — 2026-09-20

LAB is a multi-service Web Intelligence / Deep Work Platform; Essay is one module.
App shows quick results/actions; LAB owns deep analysis. Student and school
analytics reuse one canonical academic model/engine: 1 student versus a batch
of N students plus cohort aggregation. B2B access and orchestration are future
work, not a second scoring engine. See [product architecture](product-architecture.md)
and [platform boundaries](product-platform-boundaries.md). Existing separate-score
scales, provenance and correlation-versus-causation constraints remain intact.


Recorded 2026-09-19 from a Product Owner decision. **Documentation only.**
Nothing described here is implemented, and nothing here promotes a feature into
v1.0 — `product-scope.md` still excludes the advanced achievement system and the
early-admission prediction service until `decisions.md` records a promotion.

## 1. Why this document exists

Study and Mock Exam are built and working, but as standalone features they end
at a timer and a result screen. The Owner's decision is that they are the first
two data sources of a longer chain:

```
Study  →  Subject Study Tracking  →  Mock Exam / Academic Record
                                              ↓
                                     Academic Analytics
                                        ↓          ↓
                        Achievement / Badge     Academic Profile
                              Engine                  ↓
                                            Target University / Department
                                                       ↓
                                              Admissions Engine
LAB Essay module (논술 학습·첨삭)  →  Achievement Engine, and → Academic Profile as context
```

Each arrow is a data dependency, not a release gate.

## 2. Study time analytics

Today only a total accumulated study time exists. It must be able to grow into
per-subject time without a rewrite. Candidate learning areas are 국어, 수학,
영어, 탐구, 논술, 기타; **the exact taxonomy is a separate later decision** and
is deliberately not fixed here.

Long-term capabilities: daily, weekly, monthly and cumulative study time;
per-subject study time; change in per-subject time; recent learning pattern.
Visualisation candidates are line, bar and trend charts. Not implemented.

## 3. Mock Exam academic record

A mock exam result must stop being a one-shot screen and accumulate into a
per-student Academic Record. Candidate score dimensions: `raw_score`,
`standard_score`, `percentile`, `grade`.

Two constraints: the current MCQ scoring contract is not broken by this, and a
manually entered score and an automatically scored LegendStudy attempt must be
analysable in the **same** Academic Record.

## 4. Score trend

From entered or generated scores, show score change by exam, by subject and by
period — for example 3월 → 6월 → 9월 → 수능. **Specific exam schedules and exam
types are not hard-coded**; the model carries whatever exams the student records.

## 5. Study time × score

Per-subject study time and per-subject score change are analysable together
(수학 시간 ↔ 수학 성적, 국어 시간 ↔ 국어 성적, …).

**Correlation is not causation, and the product must never say otherwise.**
Permitted expression: correlation, trend, observed change. An increase in study
time is never presented as the cause of a score increase.

## 6. Academic Profile

The user data model that ties learning analysis to admissions. Candidate
contents: basic learning context, 학교, 학년, 내신, 모의고사 성적, per-subject
study time, LS LAB 논술 학습 기록, 희망 대학, 희망 학과/모집단위. No Production
schema implements any of it.

## 7. Target university / department and gap analysis

A student may later set a target university and department/모집단위, and the
product compares it against current scores, recent trend, per-subject scores and
per-subject study time.

Gap analysis candidates: weak subjects; subjects whose score has plateaued;
subjects with high variance; areas short of the target; subjects receiving
relatively little study time.

**A score gap is not an admission probability.** Until a university's actual
반영방식 and admission rules are applied, the two must never be conflated.

## 8. Study priority guidance

From the same data the product may suggest where to allocate more study time and
which subject's improvement is likely to matter most for the stated target. This
is **learning diagnosis**, not a guarantee or a prediction of admission.

## 9. Achievement / Badge Engine

The badge idea from the earlier LegendStudy plan returns here as an **Achievement
Engine**, not a rewards gimmick. Badges are **not** granted for logging in,
watching an ad, or arbitrary activity; they are granted for real learning
behaviour and for confirmed growth.

Input data: Study / cumulative time · Subject Study Tracking · Mock Exam
attempts · Academic Record · Academic Analytics confirmed growth · LS LAB 논술
학습 및 첨삭 활동.

**Two kinds, kept separate:**

| kind | based on | examples (future design examples only) |
|---|---|---|
| Behaviour-based | what the student actually did | 첫 학습 기록; 누적 10 / 50 / 100시간; 7일 · 30일 꾸준한 학습; 특정 과목 누적 학습; 첫 모의고사 · 누적 응시; 첫 LS LAB 첨삭; 논술 학습 누적; 주간 학습목표 달성 |
| Growth-based | a confirmed change in recorded results | 개인 최고점 갱신; 확인된 성적 단계 향상 |

The example list above is **not a canonical badge catalogue**; it is a set of
future design examples. The real catalogue is a later decision.

Long study hours never by themselves earn a growth-based achievement: as in §5,
correlation is not represented as causation.

**Prediction badges are forbidden.** No achievement may assert or imply an
admission outcome — "서울대 합격 가능", "합격 유력", "상향지원 성공" and
anything of that shape are out of scope by decision. Achievement records what
happened; it does not forecast.

Long term, MY can present these as a learning growth record / portfolio.

## 10. Admissions Engine and its boundary

The existing long-term backlog item (수시 지원 분석 / 합격예측) connects at the
end of the chain, with a hard boundary:

| data | belongs to |
|---|---|
| 공부시간 | 학습 진단 (learning diagnosis) |
| 성적 변화 | Academic Analytics |
| 내신 + 모의고사 성적 + 대학별 반영 규칙 + 모집단위 + 수능최저 + 과거 입결 + 공식 전형 데이터 | Admissions Engine |

**Study time is not a direct predictor of admission probability.** A structure
such as "100시간 공부 → 합격확률 +10%" is explicitly rejected. Study time is used
for behaviour analysis, per-subject investment analysis and as context for score
change. Admission probability / fit analysis is computed from real admissions
data and per-university rules, or not at all.

**Achievement Engine and Admissions Engine are separate systems.** An
achievement is never an input to an admission probability, and an admission
estimate is never surfaced as a badge.

Future Admissions Engine data candidates, none of which are collected today:
내신, 대학별 교과 반영방법, 학년별·과목별 반영 규칙, 진로선택 반영, 수능최저,
모집인원, 경쟁률, 과거 입결, 전형요소, 논술·면접 여부.

## 11. LS LAB relationship

LS LAB 논술 기록 joins the Academic Profile as learning context and feeds the
Achievement Engine. **Essay evaluation results and 모의고사/내신 scores are never
summed onto one score scale.** Each domain stays independent and is combined only
as context inside the Academic Profile. The Essay module's roadmap is
[roadmap-essay-lab.md](roadmap-essay-lab.md).

## 12. Visualisation roadmap

Candidates for later UI/UX design: cumulative study time; per-subject study time;
mock exam score change; study time + score trend together; subject gap against a
target; study priority; long-term growth. The chart library and UI are decided in
a later UI/UX task, not here.

## 13. Development sequence

Recommended order. **Data dependency, not a forced release sequence** — the
Achievement Engine in particular may ship parts earlier once the data it needs
exists.

| step | scope |
|---|---|
| P1 | Keep the current Study / Mock Exam foundation |
| P2 | Academic Record — manual score entry, automatic mock-exam linkage, score history |
| P3 | Subject Study Tracking — subject tagging on study sessions, per-subject totals |
| P4 | Academic Analytics — study-time graphs, score graphs, combined trend, subject gap |
| P5 | Achievement / Badge Engine — behaviour-based first, growth-based once analytics is trustworthy |
| P6 | Target University / Department — target setting and gap against it |
| P7 | Admissions Engine — per-university rules, 입결 data, 수시 지원 분석, fit analysis |

## 14. Current implementation status

| capability | status |
|---|---|
| Study core | **existing implementation** |
| Mock Exam / scoring | **existing implementation** |
| Academic Record | NOT IMPLEMENTED |
| Manual score entry | NOT IMPLEMENTED |
| Subject Study Tracking | NOT IMPLEMENTED |
| Academic Analytics | NOT IMPLEMENTED |
| Achievement / Badge Engine | NOT IMPLEMENTED (PLANNED) |
| Target University / Department | NOT IMPLEMENTED |
| Admissions Engine | NOT IMPLEMENTED |
| Admission prediction | NOT IMPLEMENTED |

This document is a roadmap record. It does not mean any of the above was built.

## 15. Not in this entry

No Flutter code, DB migration, Supabase schema, RLS, RPC, AI, admissions
calculation, university data collection, UI, charts, score input or Study schema
change. Those each require their own approved design and implementation task.

## In-App Exam V1 dependency

[In-App Exam architecture](architecture-in-app-exam.md) requires a basic Academic
Record and score history for its V1 closed loop; that foundation is still NOT
IMPLEMENTED. Deep Analytics and study-time/score/admissions analysis stay V2+;
the roadmap dependency chain above is preserved.

## Paper-first retention refinement

Academic Record → Analytics → Study Strategy remains the long-term value chain.
V1 now explicitly includes basic historical score comparison after paper-first
answer submission, without requiring Viewer access. USER ACADEMIC HISTORY is the
retention asset; advanced weakness/AI strategy/admission predictions remain later,
not features implemented by this decision. Existing separate scales and
correlation-versus-causation boundaries remain in force.
