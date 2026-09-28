# Essay LAB v1 Product Specification

2026-09-28 · **OWNER REVIEW READY / DESIGN ONLY**. No UI, AI run, payment integration,
student seed or Production migration. [Architecture and SQL](student-analytics-data-architecture.md)
implements this proposal's data contract; the [longitudinal strategy](longitudinal-learning-admissions-data-strategy.md)
remains the upper-level strategy, not a competing student master.

## Recommended MVP architecture

Reuse `profiles.id = auth.users.id`, platform `universities`, existing exam/resource mappings.
Add stable question + versioned criterion identities, session + mutable draft + immutable
attempts, versioned evaluation/dimensions/evidence and issue history. Use private DB text
for typed answers. Keep credit accounts/grants/decisions/ledger separate. **No overall star;
explain the overall answer in sentences, show levels only per criterion.**

Build text-first Desktop Web and fully writable Mobile. Primary action is **직접 다시 써보기**.
One credit covers the first evaluation and first revision evaluation in one question cycle.
AI examples are optional, collapsed, on demand and **CONDITIONAL** pending stance/minimal-edit
quality gates. Do not postpone core writing/evaluation for advanced analytics or images.

## Product principles and accepted evidence

[Foundation](essay-lab-data-foundation.md), [Sookmyung](essay-lab-evaluation-pilot-2025.md),
[Hanyang Run A](essay-lab-hanyang-2024-afternoon2-run-a.md) and [Rewrite Pilot](essay-lab-rewrite-pilot-v1.md)
are preserved historical evidence. Sookmyung rewrite PASS; Hanyang PARTIAL because an
unstated policy preference was added. Neither frozen result is rewritten or rerun.

1. Explain reasons before scores; identify what the student achieved first.
2. Ground criticism in actual university criteria; do not invent weights or conclusions.
3. Combine the same root issue into one improvement and one prioritized action.
4. Preserve the student's stance, wording, argument order and strengths.
5. Fix errors → supply missing logical links → compress repetition → clarify expression.
6. When the student's judgment is missing, ask them to choose; never choose for them.
7. Keep uncertainty explicit and explanations useful for the student's next draft.

[Contract v1.2 design](../tool/essay_lab/evidence/evaluation_contract_v1_2.json) inherits the
six v1.1 rules and adds only stance preservation and minimal editing. Old outputs/keys remain
unchanged. **Not executed or quality-validated.** Product levels require a separately reviewed
output adapter using criterion IDs/level explanations; no retroactive stars from old prose.

## Journey and screens

University → admission year/exam → question → question/passages → draft → submit → first
assessment → strengths/diagnosis/improvements → direct revision → second assessment →
changes → optional AI example → history. Guests can discover public materials; sign-in is
needed to save private drafts or request processing. Auth reuses the platform; App/Web
sessions remain independent. University targets prioritize navigation, not eligibility.

| Surface | MVP behavior | Failure/recovery |
|---|---|---|
| Home/selection | University, year, verified exam/question; target universities; recent sessions | Unknown time/length/criteria shown as unknown, never guessed |
| Desktop workspace | Split question/passages and answer; timer, count, save state, submit, official source | Restore server draft; failed save retains local draft and shows retry |
| Mobile workspace | Problem/writing switch, text entry, save, submit, assessment and revision | “PC에서 작성하면 더 편리합니다.” is guidance, never a write restriction |
| Draft recovery | One draft/session; revision compare-and-swap; device switch resumes same ID | Stale revision prompts reload/compare; never silently overwrite another device |
| Submission | Atomic draft revision capture into immutable attempt with submission key | Duplicate tap/network retry returns same attempt; editing creates new attempt |
| Result | The ordered sections below; saved result on return | Pending state can be resumed; no second charge on refresh |
| Revision | New draft/attempt in same session; previous answer/result available | First successful revision benefit reserved atomically; failed attempt doesn't spend it |
| Change view | What improved, remains, resolved or newly appeared, then full diagnosis | Incompatible evaluation regimes show side-by-side without growth claim |
| History | Recent sessions, question, attempts and successful evaluations | No deleting old answer to simulate a revision |

Practice has no forced deadline; timed mode uses declared budget; exam simulation uses
verified exam time. An exam-level time must not be advertised as a per-question allocation.
If time is unknown, do not offer an “official timed” promise. v1 records browser foreground
active-writing intervals (coalesced, capped), with wall time separately; active time is a
client estimate, not proof of effort. No keystroke logging. Pause behavior is explicit; in
exam simulation wall countdown continues while the page is backgrounded. No hidden auto-submit.

## Results and five levels

Canonical order:
1. 종합 평가 (sentence, no overall stars)
2. 잘한 점
3. 평가 항목별 진단
4. 보완할 점
5. 먼저 고쳐야 할 부분
6. 다시 쓸 때 확인할 것
7. 평가 근거
8. **직접 다시 써보기**
9. Collapsed **첨삭을 반영한 예시 답안 보기**

| Stored level | Presentation | Meaning |
|---|---|---|
| 5 | ★★★★★ 매우 충실 | Meets this criterion very fully |
| 4 | ★★★★☆ 대체로 충실 | Generally meets this criterion |
| 3 | ★★★☆☆ 보완 필요 | Meaningful improvement needed |
| 2 | ★★☆☆☆ 부족 | Substantial parts missing |
| 1 | ★☆☆☆☆ 크게 보완 필요 | Major improvement needed |
| NULL | 판단이 어려워요 | Evidence/reading uncertainty; must include reason, never level 0 |

Numbers are educational fulfillment signals, **not satisfaction ratings, official scores,
or admission probability**. Store integer on dimension, render text plus stars with screen-reader
label; never rely on color/star glyph alone. Each result needs concrete answer-based explanation
and evidence reference. Official weight (e.g. Hanyang utilitarianism 30%) is separate from level.
No multiplying stars into an official score. Do not invent weight for Sookmyung's qualitative criteria.

Hanyang afternoon2's five official axes can be shown directly (10/25/25/30/10%). Sookmyung
uses its verified qualitative criteria with NULL weights. SKKU's question scores must not become
university-wide criterion weights. For a future 10–20-axis rubric, group presentation headings
while preserving individual criterion links; do not average unrelated axes into a new official
criterion. MVP adds no grouping table. Criteria not published: explicitly label a reviewed
`legendstudy_derived` definition **LegendStudy 기본 평가 항목**, show limited evidence/uncertainty;
never imply university endorsement. Unsupported evaluation stays unavailable.

## Second evaluation and changes

Start with **무엇이 달라졌나요?**: improved dimensions, resolved issues, remaining issues,
new issues, then full details. Compare the selected completed evaluation for each attempt
under the same `regime_key`, criterion identity/version, evidence completeness and writing
conditions. A 3→4 is not “+1 official point.” Explain the specific change, qualify difficulty/model
changes. Preserve all evaluations; “latest” means latest successful compatible result, not
latest failed request. Operator re-evaluation is separately reasoned/billed, not another student revision.

Store issue observations; compute level deltas/counts/funnel from facts. No extra growth snapshot
or AI-generated comparison essay in MVP. Persisting narrative later requires input evaluation IDs,
analytics version and generated-at. No single “논술 실력 4.2” across universities.

## AI example and student agency

Recommend after two submitted/evaluated attempts. First-result access is a soft nudge:
“먼저 직접 다시 써보는 것을 추천해요. 첨삭 내용을 반영해 한 번 직접 고쳐 쓴 뒤
예시 답안과 비교하면 더 효과적으로 학습할 수 있어요.”
Actions: **직접 다시 써보기** / **그래도 예시 답안 보기**. No hard lock or dark pattern.

Generate only on actual request, once per evaluation; repeated button clicks reuse the saved
result. No v1 regenerate button. Processing retries reconcile the same logical generation;
a successful result is never silently replaced. Don't generate examples for all evaluations in advance.

“위에서 안내한 보완점을 반영하면 다음과 같이 고쳐 쓸 수 있습니다.
이 답안은 하나의 예시입니다. 정답처럼 외우기보다는, 자신의 답안을 다시 작성할 때 참고해 보세요.”

Visible label **첨삭을 반영한 예시 답안 · AI 생성**, internal origin `ai_generated`.
Separate university model/example/high-scoring answers. Generation uses student's original
answer + confirmed improvements + necessary official question/intent/criteria, excludes official
reference answers, source-quality labels, expected band and other students' answers.
Unstated stance: guide student to decide, do not invent a completed policy argument.

## Credits: approved product meaning, proposed transaction behavior

| Action | Basic `essay_cycle_v1` decision |
|---|---|
| View, write, save | 0 |
| First evaluation | 1 credit reserved; consume only on valid successful result |
| First rewritten answer evaluation in same cycle | Included, 0; record decision and parent paid/granted cycle |
| Change analysis / example | 0 extra student credits; AI cost still measured |
| Third or later evaluation | Normally new credit; application policy decides, not attempt number CHECK |

Evaluation request → locked account/session eligibility check → decision/reservation → AI →
atomic validated result + settlement. Retry reuses request key/payload hash. Definitive technical
failure releases reservation and included benefit. Timeout is **unknown**, reconcile before release.
Late output from a cancelled/released lease cannot publish/settle; safe retry requires authorization
again. Never show a usable completed result without settled/authorized-zero decision. A third paid assessment in that same session does not reset its already-used included-revision
benefit under the basic v1 policy. A new independent practice session starts a new paid cycle. Exact limits,
prices, free allocation, expiration and subscription remain separate Owner commercial review.

Student wording: “첨삭을 완료하지 못했어요. 회차권은 차감되지 않았습니다.” only after
release is confirmed. While status is unknown: “처리 상태를 확인하고 있어요. 다시 요청하지 않아도 됩니다.”
No raw provider errors. Paid policy changes, school sponsorship and future subscriptions change
entitlement logic; learning sessions/evaluations remain unchanged.

## Sources, language and privacy

**출처 · ○○대학교 입학처 / 원문 자료 보기 ↗**. Stable official post/library URL is distinct
from viewer/delivery URL. Never substitute the LegendStudy blog or a signed PDF URL as official
origin. Cite natural labels and a precise viewer location, not raw UUID/locator. Attribution is
not rights clearance; source/rights review remains necessary before full public release.

Student Korean: 평가 기준, 평가 항목, 첨삭/진단/조언, 잘한 점, 보완할 점, 먼저 고쳐야 할 부분,
평가 근거, 다시 쓰기. Explain like a kind, specific 논술 teacher. Do not surface rubric/criterion/
benchmark/ground truth/hallucination/calibration or PASS/PARTIAL/FAIL. Necessary 논술 vocabulary
(논제/제시문/논거/추론) stays, briefly explained if useful.

Answers, assessments, examples private by default. Provider input excludes profile/name/email/
school/phone. No body in product analytics/logs. Account data sharing with School/Analytics
requires future explicit relationship/permission; same identity alone grants no access.
Privacy/legal review: minors, consent, provider retention/region/training terms, rights to AI processing,
export, deletion/backup retention, financial retention. No legal conclusion or invented duration.

## Scope and implementation gates

**MVP:** text draft/restore/timer/count, submit/version, one-question cycle, versioned evaluation,
criterion levels/reasons/sources, consolidated issue history, direct revision/included re-evaluation,
changes/history, targets, credit ledger and minimal events. AI example design included conditionally.

**FUTURE:** image upload/OCR, school/organization memberships, internal grades, broader Mock
analytics, common competencies, admissions outcomes, subscription/provider integration, advanced
cohorts and dashboard narratives. **OPTIONAL:** materialized caches/snapshots after query profiling.
No data reingestion, UI or provider work in this phase.

Next: Owner schema/policy review → revised migrations/local tests → Production authorization + RLS
runtime verification. Web UX detail may follow design approval in parallel; actual writes require
validated server APIs. Then writing → v1.2 evaluation → revision/changes → optional examples →
commercial payment/operations → E2E/release. Productization-ready does not mean release-ready.
