# Essay LAB v1 Product Specification


2026-09-29 implementation update: [Scaffolding persistence](essay-lab-scaffolding-persistence.md)
implements the approved1.3 direction with one nullable column and versioned RPC dispatch.
[Production apply PASS](essay-lab-scaffolding-production-apply.md): persistence and submit timing
DEPLOYED; AI/student traffic NOT_ENABLED. Historical review sections remain design context.

2026-09-29 · **Scaffolding APPROVED / PERSISTENCE RUNTIME VALIDATED / AI NOT EXECUTED**.
Base schema/RPC deployed: [security acceptance](essay-lab-security-resolution.md).
UI is a fixture preview; persistence is Production deployed. Live AI/payment and real-student traffic are not enabled. [Architecture and SQL](student-analytics-data-architecture.md)
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

## 단계별 첨삭 — canonical product contract (2026-09-29)

**대학의 평가 기준에 따라 지금 가장 먼저 고쳐야 할 부분을 찾고,
구체적인 첨삭과 재작성을 통해 한 단계씩 더 나은 답안을 완성하도록 돕는다.**
오류 개수가 목표가 아니다. 이 원칙은 향후 평가·재작성·문장 다듬기 구현의 기준이다.

기본 지도 순서는 논제 요구 → 제시문/자료 정확성 → 공식 기준의 핵심 요구 →
논증·근거·결론 연결 → 구성/전개 → 문장 구조/의미 → 문법/표현이다.
**대학 공식 기준이 우선**이며 이 순서를 모든 대학에 기계적으로 강제하지 않는다.

한 회차의 집중 과제는 기본1~3개, 문장 관측은0~5개(필요할 때 보통2~5개)다.
0/1개도 정상이다. 같은 근본 원인은 한 과제로 묶고 문장 관측이 그 과제를 구체화한다.
핵심 과제 밖의 중요한 진단은 상세 평가에 남긴다. 개수 제한을 이유로 중요한 오류를
감추거나 다음 결제를 유도하지 않는다. 모든 공식 평가 항목의 진단은 계속 제공한다.

재작성 평가는 **이전 핵심 과제 확인 → 변화 근거 기록 → 이번 집중 과제 선택** 순서다.
OPEN/UNCHANGED는 아직 확인할 부분, IMPROVED는 좋아지고 있는 부분,
RESOLVED는 해결한 부분, RECURRED는 다시 나타난 부분이다. 판독/비교 근거가 부족하면
판단이 어렵다고 알린다. 관측 없음은 해결됨이 아니다. 모델/기준이 달라 비교할 수 없거나
같은 답안을 재평가했을 뿐이면 학생의 성장으로 표현하지 않는다.

아직 해결하지 못했다면 같은 조언을 반복하지 않고 실제 문장, 더 쉬운 원인 설명,
작은 수정 단계 또는 짧은 최소 수정 예시로 안내를 구체화한다. 입장·문체·강점을 보존하며
답안 전체를 대신 쓰지 않는다. 해결/개선이 확인되면 다음 우선순위로 진행할 수 있다.
새로 나타난 중대한 오류는 먼저 다룰 수 있지만 그 이유를 설명한다.

문장 최소 수정 예시는 위 과정을 돕는 수단이다. 전체 **첨삭을 반영한 예시 답안**은
계속 선택 기능이며 **직접 다시 써보기**가 기본 행동이다. 유료 재첨삭의 가치는 새로운
작성본의 개선 확인과 다음 지도·누적 이력에 있다. 필요한 첨삭을 숨기는 데 있지 않다.

관측은 evaluation-local 사실로 보존한다. 반복 관측·비교 가능한 평가·관측 기간에서
장기 패턴을 도출하며, 한 번의 문제를 학생의 영구 약점으로 확정하지 않는다.
[문장/저장/검증 설계](essay-lab-sentence-review.md)와
[Evaluation 1.3-review.1](../tool/essay_lab/evidence/evaluation_contract_v1_3.review.json)이
승인된 구현 입력이다. **기존v1.2와 Pilot은 변경하지 않았고 새 AI 실행도 없다.**

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

Current preview order (details retained):

1. 내 답안 한눈에 보기 (second result: 이번 답안의 변화 한눈에 보기, then 평가 항목 변화)
2. 종합 평가 (sentence, no overall stars)
3. 잘한 점
4. 평가 항목별 진단
5. 문장 다듬기 · N개 (existing optional, collapsible UI)
6. 보완할 점
7. 먼저 고쳐야 할 부분
8. 다시 쓸 때 확인할 것
9. 평가 근거
10. **직접 다시 써보기**
11. Collapsed **첨삭을 반영한 예시 답안 보기**

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

Start with **이번 답안의 변화 한눈에 보기**, then **평가 항목 변화**, overall summary and
full details. The duplicate four-block “무엇이 달라졌나요?” section was removed in the
[accepted preview polish](essay-lab-ui-ux-v1.md). No resolved observation means a neutral empty state. Compare the selected completed evaluation for each attempt
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
No data reingestion, UI change or provider execution in this contract-review phase.

Next: Owner/ChatGPT Production result review → separately approved AI Pilot.
Persistence/versioned adapter is deployed; existing security acceptance is preserved. Real-student writes require privacy/provider/retention and integration
gates, independent of this review. Productization-ready does not mean release-ready.
