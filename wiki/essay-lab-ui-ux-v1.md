# Essay LAB Workspace UI v1

## L2-C1 CORE-first overview — 2026-09-30

Implemented narrow presentation correction. Live1.3 maps active core_focus explanations into
optional `overviewImprovements`; empty means no CORE, null preserves legacy presentation.
Top “보완할 점”/“아직 보완할 점” shows at most2 current CORE explanations. Three CORE retain
all detail/priority but overview caps2; zero does not fall back to minor roots. Detailed
improvements and non-core sentences remain intact. Resolved/improved/recurred/open historical
changes are not filtered by core status. No DB/RPC/output Contract change or technical labels.
Focused66 PASS including0/1/2/3 CORE, non-core history and360px/200%; analyze ASCII mirror PASS.
This resolves L2-B4's overview limitation below; no broader result redesign or mobile build.

L2-B4 mapping recheck: first priorities correctly filter core_focus; sentence detail preserves
quote/diagnosis/direction/optional example. However overview “보완할 점” takes the first two
ALL-active improvements and can include NON-CORE. [Exact limitation / DESIGN_ONLY follow-up](essay-lab-scaffolding-persistence.md#ui-compatibility-finding).
No Flutter/IA implementation or build in this prompt task. Internal issue keys remain hidden.

2026-09-28 · Phase 1 IMPLEMENTED / OWNER VISUAL REVIEW READY.
실제 Flutter 화면이며 **메모리 내 가상 자료만 사용**한다. Production 학생 저장,
AI 평가·생성, worker, 회차권 결제는 활성화하지 않았다. DB/RPC/migration 변경 없음.

## L2-B3 vNext UI compatibility review — design only

[Product concrete feedback](essay-lab-product-v1.md#l2-b3-concrete-feedback-contract--design)
and [root/storage proposal](essay-lab-scaffolding-persistence.md#l2-b3-vnext-contract-design--no-implementation)
retain the current overview/summary/strengths/dimensions/sentence review/improvements/priority/
checklist/direct rewrite/change sequence. No UI implementation or IA redesign here.

Verified `essay_live_gateway.dart` maps non-resolved core_focus actions into priority, progress
explanations into change groups and every stored sentence envelope into typed sentence items.
Thus genuine non-core local roots can display sentence advice without becoming CORE actions.
`EssaySentenceSection` already checks immutable attempt/evaluation ownership and exact quote,
then displays quote/diagnosis/direction/optional example with count/collapse behavior.
This supports student text → why → how for sentence-linked advice today.

Current CORE rendering relies on prose/actions; it is not a structured per-core anchor card or
a structured per-substep progress tracker. Use existing explanation/action/checklist semantics
first; do not claim a new student_anchor field is already mapped. If later Owner requests
separate per-core quote/why/how labels, reuse sentence presentation and add a minimal typed
association/layout in an explicitly authorized UI step. Do not infer links from text similarity,
show internal IDs or copy every sentence. No mandatory UI change for the recommended wire-
compatible prompt refinement; stronger per-core hierarchy is DESIGN_ONLY. Null root persistence
cannot be fixed by frontend-only changes. Future implementation must keep360px/200% scaling
and historical1.2/1.3/empty-observation behavior; no Flutter build is claimed in this design task.

## Canonical decisions and IA

[Product v1](essay-lab-product-v1.md), [history architecture](student-analytics-data-architecture.md),
[server transactions](essay-lab-server-transactions.md), [deployed security](essay-lab-security-resolution.md)를 재사용한다.
이번 Owner 지시가 승인한 Claude UX 결정을 이 문서로 복구한다.
기존 [design system](design-system.md)의 Navy/neutral/제한적 Orange, 공식 wordmark,
문서형 구분선과 themed editor/button을 사용한다. 별도 HTML concept은 만들지 않는다.

기존 LAB의 세 번째 논술 영역에서 `/lab/essay` → 대학/시험/문항 선택 →
`/lab/essay/write/:question`으로 진입한다. 기존 ‘논술 준비’ 카드와 외부 LAB 링크는
유지하고 ‘논술 화면 미리보기’를 추가했다. 새 최상위 탭·LAB 전체 재설계는 없다.
가람/누리는 가상 대학이며 모든 본문은 새로 작성한 화면 검토용 자료다.
공식 대학 답안이나 Pilot 학생 원문을 복제하지 않았다.

## Writing and responsive behavior

- Desktop: 폭 900px 이상, text scale 1.8 미만에서 문제42:답안58 독립 스크롤.
- Mobile/큰 글자: 문제↔답안 전환; 입력·스크롤 상태 유지. 360px 및 2배 글자 검증.
- compact 대학/시험/문항 header, 작성 중 글자 수·시간 고정, 제시문 빠른 탐색.
- 문제/제시문/분량/시험시간/선택적 이미지/공식 원문 및 자료 링크를 분리한다.
- 연습은 경과 시간, 실전은 확인된 **시험 전체** 시간의 남은 시간. 문항 제한시간으로
  오인하지 않게 표시한다. 시간 미확인 시 실전 전환 없음. Study Timer 기록과 무관하다.
  모드 변경은 시간 초기화를 명시하며, 시간 종료 시 자동 제출하지 않는다.
- 글자 수는 공백 포함 Unicode code point 수다. 대학별 원고지 산정과 동일하다고 주장하지 않는다.
- 입력 후 자동 저장 상태/실패 재시도, 충돌 시 내 글과 저장된 글 비교 후 명시적 불러오기.
  revision/CAS는 내부에서만 사용한다. 이전 제출본은 고치지 않고 재작성 시 새 제출본을 만든다.

**현재 저장은 화면 인스턴스 메모리뿐**이다. 나가거나 새로고침하면 사라진다는 안내를
표시한다. 실제 브라우저 복구/기기 간 동기화는 RPC adapter 연결 이후 범위다.
제출해도 입력한 글을 분석하지 않고 준비된 결과를 표시한다는 안내를 제출 전·결과에 둔다.

## Evaluation → rewrite → changes

1차 결과 순서: 종합 평가 → 잘한 점 → 평가 항목별 진단 → 보완할 점 → 먼저 고쳐야 할 부분
→ 다시 쓸 때 확인할 것 → 평가 근거 → 다시 써보기 → 선택적 예시 답안.
종합 별점은 없다. 항목은 정수1~5 + 한국어 상태 + 판단 이유 + 접근성 설명.
공식 배점은 별과 분리하고, 판단 불확실 시 빈 별 대신 판단 어려움으로 표현한다.

재작성 primary action은 FilledButton, 예시 secondary action은 OutlinedButton이다.
재작성에서 첫 답안/확인할 것은 접어서 참고한다. 최초 답안 snapshot은 유지한다.
2차 결과는 좋아진/좋아지고 있는/아직 확인할/다시 나타난 부분 및 항목 변화가 먼저다.
동일·상승·하락을 모두 표현한다. 평가 체계가 다르면 직접 성장 비교를 유보한다.
보완점은 같은 핵심 문제를 합치고 구체적 행동으로 설명한다. 내부 영문 용어는 노출하지 않는다.

첫 재첨삭 무료 안내는 결과의 이용 권한 필드에서 읽는다. 클라이언트 attempt 번호로
가격을 결정하지 않는다. 현재 해당 필드 또한 fixture이며 실제 차감은 없다.

## Optional example and provenance

예시는 기본 비노출. 1차 직후에는 직접 고쳐 쓰기를 먼저 권하는 대화상자를 표시하되
‘그래도 예시 답안 보기’를 허용한다. 2차 후 권장, hard lock 없음.
표시 이름은 ‘첨삭을 반영한 예시 답안’. AI 생성/대학 공식 답안 아님을 명시한다.
현재 본문은 화면 검토용 창작 예시라는 설명도 병기한다. 실제 생성은 수행하지 않았다.
향후 contract v1.2 학생 입장 보존/최소 수정과 on-demand 재사용 정책을 유지한다.

자료 상태는 명시적 값: 첨삭 가능/공식 평가 자료 기반/평가 자료 일부/문제만 제공.
분량 유무로 평가 가능 여부를 추측하지 않는다. 평가 기준 출처는 공식 시험/공식 모의/
공식 자료 정리/LegendStudy 기본을 구분한다. fixture label은 ‘표시 예시’로 한정한다.
공식 출처 URL과 delivery URL은 별도 필드이며, 가상 문제에는 거짓 공식 링크를 만들지 않는다.

## Implementation and backend boundary

`lib/features/essay/`의 models, memory gateway/fixtures, controller, pages로 구성한다.
기존 ShellPage/AppHeader/SectionHeader/EmptyState/ExternalLinkButton 및 theme를 재사용한다.
router와 LAB 진입 컴포넌트만 연결하며 기존 auth 경계는 변경하지 않는다.

| UI action | 기존 RPC 연결 대상 | Phase 1 |
|---|---|---|
| 자동 저장 | essay_save_draft | gateway expected revision CAS 모사 |
| 제출 | essay_submit_attempt | immutable memory snapshot + request key |
| 첨삭 요청/실패 재시도 | essay_request_evaluation | 같은 attempt 재사용, 준비된 결과 |
| 예시 보기 | essay_request_rewrite | 숨김/노출만; 실제 요청 없음 |
| 삭제 | essay_erase | 이번 화면 미구현; 별도 사용자 삭제 흐름 |

실제 adapter는 session ownership, revision, hash, writing metadata, request identity 등
[기존 서버 계약](essay-lab-server-transactions.md)을 그대로 매핑해야 한다. 인터페이스 준비를
실제 RPC 통합 완료로 간주하지 않는다. worker/finance RPC는 client에서 호출하지 않는다.
현재 Essay 기능에 Supabase/network 호출, 답안 로그, disk persistence, credential은 없다.

## Validation and visual review

`test/essay_workspace_test.dart`: 실제 공유 route, 대학/시험 선택, 모바일 전환/2배 글자,
독립 pane, timer, 저장 실패/충돌/복구, 중복 제출 방지, 처리/실패 재시도,
첫 답안 보존, 첫/두 번째 결과, 별 semantics, 출처/문제-only, 예시 기본 비노출/soft nudge.

재현: `./tool/flutterw test --dart-define=CORE_RENDER=true test/essay_workspace_test.dart`
(macOS AppleSDGothicNeo 사용). 아래는 실제 Flutter widget render이며 HTML 시안이 아니다.

- [Desktop 작성](../docs/previews/essay-lab-ui-phase1/essay-writing-desktop.png)
- [Mobile 작성](../docs/previews/essay-lab-ui-phase1/essay-writing-mobile-1x.png)
- [Mobile 2배 글자](../docs/previews/essay-lab-ui-phase1/essay-writing-mobile-2x.png)
- [1차 결과](../docs/previews/essay-lab-ui-phase1/essay-result-desktop.png)
- [재작성](../docs/previews/essay-lab-ui-phase1/essay-rewrite-mobile.png)
- [2차 변화](../docs/previews/essay-lab-ui-phase1/essay-comparison-desktop.png)
- [충돌 비교](../docs/previews/essay-lab-ui-phase1/essay-conflict-mobile.png)

Analyzer PASS; focused Essay/LAB/navigation/core 33 PASS. 전체 Flutter: **878 PASS / 1 skip / 5 failures**. 시작 HEAD `59831f0`의
독립 임시 코드 스냅샷에서 같은5개 실패를 재현했다(26 PASS/5 failures).
신규 회귀0: day6 projection 기대2개, day5 기존 badge 기대1개,
materials delivery load-more 기대2개. 관련 없는 기존 자료 정책/테스트는 수정하지 않았다.
전체 suite PASS라고 주장하지 않는다. Wiki handoff/diff check PASS, Owner iOS 파일 hash 보존.
Owner native device/browser 직접 검토는 미실행. 화면 검토 후 필요한 UI 수정 및 별도
AI/provider/privacy/retention rollout gate를 진행한다. 실제 학생 traffic은 여전히 NO.

## Owner visual polish — 2026-09-28

평가 정보 계층만 수정. 1차 Desktop은 항목명 왼쪽, 한국어 상태·별 오른쪽;
Mobile은 항목명 다음 행에 상태·별. 구체 진단은 ▶로 구분하며 기존 divider 유지.
2차 항목 변화는 항목명/별 변화 → 한국어 상태 변화 → ▶ 변화 이유 순서다.
종합 평가·잘한 점·보완할 점·우선순위·체크리스트는 진단/행동 설명을 ▶로 구분하되,
좋아진/좋아지고 있는/아직 확인할/다시 나타난 부분은 일반 본문을 유지한다.
Writing/Rewrite/IA/backend/DB/RPC 변경 없음. 새 기능 없음.

관련 widget 20 PASS (360/1120px, 1x/2x), analyze PASS; 전체 suite 재실행 없음.
아래 4개가 최신 검토 캡처이며 위 Phase1 초기 결과 캡처보다 우선한다.
긴 결과의 정보 계층을 보기 위한 세로1800px Flutter render다.

- [Desktop 1차](../docs/previews/essay-lab-ui-phase1/essay-result-desktop-polish.png)
- [Mobile 1차](../docs/previews/essay-lab-ui-phase1/essay-result-mobile-polish.png)
- [Desktop 2차](../docs/previews/essay-lab-ui-phase1/essay-comparison-desktop-polish.png)
- [Mobile 2차](../docs/previews/essay-lab-ui-phase1/essay-comparison-mobile-polish.png)

## Owner visual polish 2 — 2026-09-28

이번 Owner 결정이 이전 polish의 Desktop 우측 정렬을 대체한다. 항목명 직후18px
간격으로 상태·별 또는 별 변화를 묶는다. Mobile은 기존 줄 분리 유지.
결과 본문 #202124 / warm-white #FFFEFC; Navy는 heading/구조, Orange는 별/CTA.
잘한 점·좋아진/해결한 부분 green, 보완/우선순위/아직 확인할 부분 burgundy,
진행 중 blue. 본문 전체에 의미 색상을 적용하지 않는다.
변화 요약은 Desktop 2열/Mobile 1열의 옅은 tint·2px left rule·작은 아이콘 블록;
shadow 없음. 글자 크기가 커지면 1열. 큰 section은 여백·얇은 rule·굵기로 구분.
색상만으로 의미를 전달하지 않으며 제목은 접근성 header로 표시한다.
Writing/Rewrite/IA/기능/backend/DB/RPC는 그대로.

1440px와360px 각각100%/200% widget 검증20 PASS; analyze/Wiki/diff PASS.
전체 suite 재실행 없음. 아래 실제 Flutter 4개 캡처가 최신 Owner 검토본이다.

- [Desktop 1차](../docs/previews/essay-lab-ui-phase1/essay-result-desktop-polish2.png)
- [Mobile 1차](../docs/previews/essay-lab-ui-phase1/essay-result-mobile-polish2.png)
- [Desktop 2차](../docs/previews/essay-lab-ui-phase1/essay-comparison-desktop-polish2.png)
- [Mobile 2차](../docs/previews/essay-lab-ui-phase1/essay-comparison-mobile-polish2.png)

## Result overview — 2026-09-28

결과 상단(미리보기 고지 다음)에 ‘내 답안 한눈에 보기’를 추가한다.
잘한 점=strengths, 보완할 점=improvements, 가장 먼저 고칠 것=priorities,
다시 쓸 때 확인=checklist. 원본 순서/문장을 유지하고 빈 항목 제외 후 각각 최대2개.
2차 제목은 ‘이번 답안의 변화 한눈에 보기’: 좋아진 점=changes의 좋아진 부분,
아직 보완할 점=improvements, 해결한 부분=changes의 해결한 부분,
다음에 확인할 부분=checklist. 해결 명시가 없으면 미확인 안내; 별 상승이나
개선 설명으로 해결을 추정하지 않는다. comparable=false일 때 변화 판단을 보류한다.
기존 상세 결과는 모두 유지한다. 별도 AI 판단/호출·모델/DB/RPC 변경 없음.
Desktop 2×2, Mobile/큰 글자 1열. 옅은 의미 tint·icon·heading, 검정 본문, 그림자 없음.

21 widget PASS (데이터 선택/상세 보존/해결 비추론/1440·360px/200%), analyze PASS.
[Desktop 1차](../docs/previews/essay-lab-ui-phase1/essay-result-desktop-overview.png),
[Mobile 1차](../docs/previews/essay-lab-ui-phase1/essay-result-mobile-overview.png),
[Desktop 2차](../docs/previews/essay-lab-ui-phase1/essay-comparison-desktop-overview.png),
[Mobile 2차](../docs/previews/essay-lab-ui-phase1/essay-comparison-mobile-overview.png)가 최신 캡처다.

## Final result polish — 2026-09-28

상단 요약은 원본 순서의 핵심1개로 축소. 정해진 존대 어미만 표시용으로 압축
(설명해 보세요→설명하기 등), 임의 문장 생성/중간 말줄임 없음. 알 수 없는 어미는
원문 유지. 상세 평가 본문/데이터 불변. Desktop 항목명·상태 간격10px.
2차 중복 ‘무엇이 달라졌나요?’ 4개 블록 제거; 상단 변화 요약→항목 변화→종합/상세
평가→보완/확인→근거 순서. 해결 항목 미확인 시 gray/minus +
‘이번 평가에서 확인된 항목이 없어요.’. 해결 여부 추정 없음.
22 tests/analyze PASS, 1440/360px 및200% 포함; 전체 suite 재실행 없음.
최신 캡처: [Desktop1](../docs/previews/essay-lab-ui-phase1/essay-result-desktop-final.png),
[Mobile1](../docs/previews/essay-lab-ui-phase1/essay-result-mobile-final.png),
[Desktop2](../docs/previews/essay-lab-ui-phase1/essay-comparison-desktop-final.png),
[Mobile2](../docs/previews/essay-lab-ui-phase1/essay-comparison-mobile-final.png).

## Sentence review — 2026-09-28

평가 항목별 진단과 보완할 점 사이에 [문장 다듬기](essay-lab-sentence-review.md)를 추가.
항목 수/접기 UI, 정확한 자기 제출문 인용 검증. 미제공과0개 구분.
기존 preview는 임의 지적을 생성하지 않는다. 구조화 출력/persistence는 별도 리뷰 제안.

## Live integration L1 — 2026-09-29

**IMPLEMENTED / ISOLATED CLIENT + JWT VALIDATED; Production student/AI traffic OFF.**
This supersedes the earlier preview-only runtime status, not the frozen visual contract.
[Live gateway](../lib/features/essay/essay_live_gateway.dart),
[controller](../lib/features/essay/essay_live_controller.dart),
[live routes](../lib/features/essay/essay_live_pages.dart),
[sanitized result](../supabase/validation/essay_lab_product/l1_client_result.json).
Owner approved resume after the [status RPC](essay-lab-server-transactions.md#owner-status-projection)
was deployed. G1/Scaffolding/timing/security contracts are reused; no migration or RPC modification.

### Runtime boundary and identity

App `/lab/essay` uses live published question→exam→university records and the existing native
Workspace/result UI. Preview gateway/routes remain explicitly available for deterministic tests
and design QA; the App router never installs them or falls back to synthetic questions/results.
Empty Production question inventory shows preparation, not fake catalog content. Current schema
stores source references, not public extracted question/passage bodies; live reading links the
verified exam official source. Detailed extraction/Viewer delivery is not invented in the client.
Guests can inspect public metadata/original links; private writing/history needs existing Auth.

`ESSAY_LIVE_WRITES_ENABLED=false` and `ESSAY_EVALUATION_REQUESTS_ENABLED=false` by default.
These are rollout switches, not RLS/security controls; local tests explicitly enable them.
No real student write, AI provider call or Production worker credential was used. No IAP/Paywall,
Analytics/Ads, new dependency, table, column, migration, server function or Production mutation.

`essay_open_session` resumes an explicit owned session or the latest owned question cycle.
If no row exists, the default first-cycle UUID derives from owner/question so an ambiguous first
response and process restart cannot silently create a second cycle. Later explicit independent
new-cycle UX is not added here. Auth UID is SDK-derived, checked before/after each operation;
page auth changes revoke in-flight gateways and dispose all private controller state. Logging out,
switching accounts and returning to the same identity never revive that page's prior gateway.

### Submission and server decisions

- `essay_save_draft`: expected revision CAS, no silent stale overwrite. Network/stale errors retain
  local text; compare/reload is explicit. Leaving with dirty text requires explicit discard.
- `essay_submit_attempt`: stable session/revision/body-hash UUID and server body fingerprint;
  duplicate tap/network retry reuses the immutable submission. Server assigns attempt number.
  Device/mode transmitted; unknown active writing time stays NULL, never inferred from UI timer.
- `essay_request_evaluation`: explicit `essay-v1.3`, stable logical key, no balance precheck or
  attempt-parity billing. Paid/included comes from server. PT402 means no right for this request.
  Unknown transport outcome retries the same logical request; confirmed failed requests can use a
  new request key without overwriting the failed record. Changing attempt under an active request conflicts.
- `essay_evaluation_status`: periodic read, only server `processing/reconciling/completed/failed`.
  Network read failure offers status retry; no elapsed-time failure/release inference. Reconciling
  never asserts charged/free. Failed no-charge text requires authoritative `no_credit_consumed`.
  Credit reserved/included/settled/released/pending remain distinct from account balance.

### Results, scaffolding, revision and history

Completed status is checked before mapping owner-readable result facts; invalidated results,
answer-hash mismatch, unknown criterion version or fabricated sentence spans fail closed.
Map summary/strengths/criterion integer levels and nullable official numeric weights separately,
progress explanations/actions/core focus/checklist, uncertainty, official evidence references,
and already-completed optional AI examples. No generation is requested in L1; no empty/example
fallback. Official citations and local sentence quotes are separate, with no fabricated evidence IDs.

v1.2 NULL observation means not supplied. v1.3 zero roots / empty sentences means supported zero.
Sentence categories/priorities, Unicode code-point exact spans (no normalization), <=5 observations
and <=3 core tasks are preserved. Explicit progress links preserve open/improved/resolved/recurred;
`not_assessable` is not interpreted as unresolved/resolved and uncertainty remains visible.

Comparison uses `input_snapshot.scaffolding_context.selected_previous_evaluation_id` and explicit
progress links, never a moving latest lookup. Criterion/evidence versions and model/regime must
match; otherwise comparison is withheld. Changes derive from levels and linked observations, not
new AI narrative. Legacy results without a pinned comparison retain detail but do not invent growth.
Manual rewrite retains session, creates a new submitted attempt and requests server-decided credit.
History displays actual submissions, their evaluations and progress chronologically; no snapshot table.

### Verification and remaining gates

[Client tests](../test/essay_live_gateway_test.dart), existing Workspace/sentence tests cover CAS,
idempotency, payload conflict, owner/isolation/logout, disabled rollout, paid/included/PT402,
status/release, v1.2/1.3/Unicode quote mapping, pinned comparison, 360px/200% and unsaved text.
[Actual local Dart test](../test/essay_live_local_test.dart) uses the real Supabase client with
Auth-issued user JWTs and public PostgREST RPCs: open/resume, CAS/stale, duplicate submit,
paid→included, timeout/unknown, synthetic lease retry/stale rejection, completion, failure/release,
retry, legacy result, same-session history, other-user denial, erasure and ledger preservation.
Synthetic worker finalization is test-only, never an actual AI call.

Reproduce only in the guarded disposable Supabase environment:
existing `submit_timing_runtime.py --supabase` → `status_projection_runtime.py --supabase` →
[private fixture preparer](../tool/essay_lab/prepare_l1_client_fixture.py) →
`flutterw test test/essay_live_local_test.dart` with private `ESSAY_L1_CLIENT_FIXTURE` and
`ESSAY_L1_PYTHON` plus the existing disposable environment variables. Credentials remain in
chmod600 `/private/tmp` files. Numeric loopback and test-container identity are mandatory.
The local-only clock shift checks lease expiry deterministically and resets afterward.
Default CI skips this opt-in external test. Never point it at Production.

Android debug and iOS simulator debug builds PASS; real device/store acceptance is not claimed.
Full Flutter run: 925 PASS / 2 skips / 5 failures; the five are the same previously documented
Materials/search/badge baseline failures (see earlier UI validation), not Essay failures.
Focused final counts and analyze are in the sanitized result. Build tool warnings about the
existing Kotlin/Android SDK/CocoaPods setup remain separate maintenance, not changed here.

Seven preservation answers: (1) submitted attempts/evaluations/progress are existing facts;
(2) reconstruct UI from owner domain rows and pinned evidence; (3) only draft is mutable;
(4) same Auth identity with revoked stale page contexts; (5) learning and financial decisions
stay separate from Admissions Outcome; (6) RLS/erasure/private response/retention unchanged,
no answer telemetry; (7) no derived growth stored or invented.

**READY_FOR_WORKER_PROVIDER_INTEGRATION=YES**, subject to Owner review.
IAP live connection is NOT ready yet: worker/reviewer/evidence assembly, quality/privacy/retention
and full learning-loop E2E remain before purchase integration. Production published question/criterion
readiness and real-device acceptance remain rollout gates. Real student traffic stays NO.

## Approved Native operating data connection — 2026-10-14

Status: IMPLEMENTED / LOCAL_VALIDATED; OWNER_DEVICE_ACCEPTANCE_PENDING. P1 shared
photo Draft remains PARTIAL. This connects the existing approved design, not a new design.

- `EssayResultView` reused for actual humanities exam History; Math retains its
  existing view. Adapter changes display whitespace/short headings only; full labels,
  feedback, answer evidence and actual next actions preserved. No invented example,
  score, or growth claim. Details collapsed; same cards/stars/overview.
- Header uses canonical catalog metadata and actual question/date. History groups
  explicit parent IDs only; independent attempts at the same exam remain separate.
- Existing comparison: saved Hanyang initial/rewrite, utilitarian3→4, four unchanged.
  Resolved-feedback reasons come from stored previous_improvement_reviews.
- Explicit `나의 첨삭 기록`; writer saves before review, selected bundle confirmation,
  existing idempotent API and read-only status polling. Public HOLD is not bypassed.
- `다시 써보기` reads original from existing History RPC, fills empty Draft only,
  protects ongoing edits, locks original question set and reads server eligibility.
  No client billing or automatic new paid fallback.
- 42 university display records generated from existing LAB catalog and priority22
  through tool/essay_ux/export_catalog.mjs; no duplicate exam/question records.
  Existing validation-only Math selector removed from ordinary entry, routes/engine kept.
- Native pdfrx, image-first input and local image save/delete/restore remain.
  PDF original-bucket exception permits ONLY the previously approved Hanyang question
  UUID/hash; all other originals denied. No Storage permissions changed.
- Server text Draft is existing capability-gated CAS. Hanyang capability is not enabled.
  Shared WEB/APP source-exam photos remain unconnected: existing Math ownership/upload
  contract must not be repurposed without compatible source-question binding.

Validation: focused58 tests PASS with saved actual QA results (no Provider), separate
rewrite preservation/selection test PASS, Analyze clean, iOS simulator debug build PASS.
Native390dp at100/200% real-result rendering; writer360dp at100/200% PASS.
Real result fixture and PNG stay local, outside Git. Optional real-data tests require
ESSAY_QA_RESULT_PATH and are skipped in CI without private fixture. No new E2E run.

Owner device check on this branch's new build: review account → 논술 LAB → fullCatalog
and `나의 첨삭 기록` → Hanyang2024 afternoon2 → initial/rewrite. Check identifying
header, overview/cards/stars/collapsed detail, utilitarian3→4/four unchanged, original
and revised answers, `다시 써보기`, preserved edits, PDF close/reopen, balance10.
Do not submit a new evaluation. Final UX approval belongs to Owner physical iPhone.

Rollback: revert this UI connection commit and rebuild APP; no DB rollback, data
migration, Provider/Package/Prompt change or Credit transaction. Claude release/IAP
branch and WEB deployment untouched. Public HOLD retained.

## iPhone usability closeout — 2026-10-14

Owner physical iPhone acceptance of dc722315: Release launch, login, Credit10,
Hanyang selection, initial/rewrite History and comparison, criterion stars/change,
Native PDF and answer photo attachment PASS. This supersedes prior device-pending
status for that baseline. The changes below require next-workday device recheck.

Scope: existing Flutter UX only; no DB, Ledger, Provider, Package, Prompt, Math
engine, Payment/IAP, Claude release branch or public activation change.

| Owner finding | Implemented minimum change |
|---|---|
| 1. Duplicate problem actions | Problem tab alone offers `문제 PDF 열기`; external admissions link labeled separately. |
| 2. Submission CTA placement | Writer tab bottom only; bundle-selection notice, question count, initial/free mode and expected1/0Credit in existing confirmation. |
| 3. Writer identity | Registry university/year/type/track/session/campus/question, omitting absent fields. |
| 4. Small PDF | Existing pdfrx Smart fit-width sizing; zoom/page controls and saved page retained, no cropping. |
| 5. PDF bottom navigation | Root Navigator fullscreen; writer also uses focused root route, existing app shell unchanged. |
| 6. Repeated photo pickers | One camera/gallery set, ordered thumbnails, six-photo limit retained. |
| 7. Delete affordance | 48px thumbnail × with explicit confirm/cancel; existing storage callback preserves remaining order/text. |
| 8. Draft truthfulness | Distinguish local temporary save, confirmed matching account body, saving/failure and not-yet-submitted. accountDraftReady unchanged. |
| 9. Result hierarchy | Existing EssayResultView/overview/cards retained, verbose summary/strength/detail collapsed. |
| 10. Repeated feedback | Exact whitespace-normalized duplicates removed only at display level across related detail lists and overview cards; distinct feedback preserved. |
| 11. Long overview reasons | Long text excerpts with expand-to-full source; no AI paraphrase or new evaluation. |
| 12. Star meaning | Existing level mapping now explicitly N/5단계 + label; official-score disclaimer retained. |
| 13. Missing public evidence | Hide empty evidence section; never claim missing display means missing Package evidence. |
| 14. Comparison | Changed criteria first, unchanged count collapsed and expandable; actual Hanyang3→4/four unchanged preserved. Existing evaluation explanation is labeled as such, not invented causal reason. |
| 15. Button/navigation consistency | Existing navy token for main actions; outlined photo actions, text details,48px controls, local200% checks. |

Components: source_catalog_page.dart, answer_image.dart, question_pdf.dart,
essay_pages.dart. Existing Native renderer, writer/Draft/store and result adapters reused.
No new route framework, evaluation view or storage. No original evaluation modified.

Validation: 41 focused tests PASS including saved actual initial/rewrite renders at
390dp100/200%, writer tab/CTA and Draft at360dp100/200%, thumbnail cancel/delete/order,
existing image storage rollback/restore, comparison and shared History. Analyze PASS;
iOS simulator debug build PASS. These are local checks, not a new Provider E2E.
Provider calls0, Credit transactions0; balance10 is Owner-confirmed, not a fresh DB read.
Saved actual fixture remains private outside Git. No migration or production deployment.

Remaining: next-workday physical iPhone recheck of fit-width/fullscreen close/page
restore, keyboard/CTA placement, camera/gallery/add/delete, source metadata,
result fold/expand and comparison; no new submission. PDF restores page, not exact
pixel offset/zoom after process restart. WEB/APP shared photo Draft and AI quality
are expressly excluded from this closeout. No blocked implementation within the
15-item scope; UX final acceptance remains pending Owner device review.

Rollback: revert this UI commit and rebuild; no DB/data rollback. General public
HOLD and execution OFF maintained. Today stops after Wiki, Commit/Push/Remote Verify.
Next resumption priority is Owner device verification only; no extra development started.

## Mobile entry-to-submit UX phase 1 — 2026-10-15

Owner GO scope: university → exam/question selection → writer → submission review.
Result/comparison/History detail UX, Provider/Package/Prompt, DB/Ledger, Math,
Toss/IAP and Claude release branch are unchanged. Public HOLD remains.

Implemented using existing SourceCatalogPage, CreditBalanceCard, SourceDraftGateway,
Native QuestionPdfViewer, image picker and ExamSubmissionGateway:
- Entire university card opens selection; chevron replaces oversized CTA. 42 catalog
  entries and Owner22 order retained. Back restores list scroll; Hero balance remains
  cached during selection to prevent loading-state height shifts on return.
- Single Hero combines explicit History access and actual credit_summary balance.
  No purchase action; no balance repeated in selection/writer/review.
- Question rows select only; one 답안 작성하기 CTA opens the existing writer.
  Selected exam/question and text/photo Draft remain on return. Bundled review keeps
  existing per-question Draft collection and subset submission; rewrite set stays fixed.
- Writer defaults to answer input. 문제 보기 opens existing Native fullscreen PDF;
  removed duplicated tabs, official-material instruction and external page locator.
- Review separates exam identity, selected answers and Credit notice. Free rewrite 0
  is shown only for server eligibility and the exact original question UUID set.

Logos: all42 bundled from existing LAB official assets (read-only source shared branch
8518db67e80973b96e0bd5abaa738460bbc2d7a6). Previously missing11 (Hanyang, Ewha,
Hongik, Kyungpook, Seokyeong, Seoultech, Sookmyung, Dankook, Korea Polytechnic,
Kangnam, Eulji) now use Native-decodable PNG. SVG rasterized with rsvg-convert;
existing raster converted with sips. Official source URLs/source and bundle hashes
are retained in assets/university-logos/provenance.json. White variants use navy
background; proportions preserved in uniform100×52 slot. SKKU gets reduced padding
for a larger visual footprint. No invented logo or new remote asset collection.

Modified: lib/features/essay/{source_catalog_page,university_catalog}.dart,
pubspec.yaml, assets/university-logos/, tool/essay_ux/export_catalog.mjs,
test/source_catalog_widget_test.dart and test/essay_logo_assets_test.dart.

Validation: focused15 tests PASS (360dp and100/200% text, question selection/CTA,
Draft restore, rewrite/HOLD, Hero/scroll, image order/removal, PDF mapping,
Registry transport, all42 logo decoding). Flutter Analyze PASS. iOS simulator debug
build PASS; physical iPhone final acceptance remains Owner action. Tests use local
fixtures; no new Provider call, Credit trade, production DB/config or Store action.

PARTIAL: existing /api/essay/exam availability returns readiness only, no server
charge quote. Initial confirmation therefore says 사용 Credit: 서버 확인 필요 rather
than inventing an authoritative1-credit quote. Existing submit backend/ledger remains
unchanged. Completing exact initial cost display requires a separately scoped server
quote contract. Free rewrite uses existing server eligibility. No claim of new E2E.

Owner iPhone check: full-card navigation/back scroll;11 logos and SKKU scale; Hero
balance/History; question selection→CTA; writer keyboard/photos/Draft; Native PDF
open/close/page restore; review subset and eligible free-rewrite label. Do not submit
new evaluations for this UX acceptance. Rollback: revert UI/assets commit and rebuild;
no DB rollback required.

## Mobile UX phase 1 finishing fixes — 2026-10-15

Owner iPhone review accepted university→exam→writer flow. This follow-up is limited
to logo backgrounds, Hero title removal, multi-question checkboxes and navy actions.
No writer/result layout redesign. Existing42 universities/Owner22 and Registry IDs
remain. No DB/backend, Math, Ledger, Payment/IAP or Claude branch changes.

Root cause: AppTokens.primaryInk is actually brown (#A94B00), despite older Wiki
calling it navy. Source logo containers and explicit CTA overrides used that token.
Use existing AppTokens.textPrimary navy (#1B2A4A) for essay CTAs, chevrons and
selected checkboxes; result page changes only the 다시 써보기 button color.
Photo secondary buttons retain white fill and get navy border within writer scope.
Global brand/theme tokens and other product screens are not changed.

Logo containers are white; SKKU zero-padding compensation and aspect-ratio contain
are retained. Existing white-only assets would disappear on white, so9 official
light-background variants replace those assets without recoloring or generating:
Hanyang, Ewha, KNU, Seokyeong, Sookmyung, Dankook, Tukorea, Kangnam, Eulji.
Hongik and Seoultech already have suitable colored assets and are unchanged.
Ewha/Seokyeong/Kangnam use unmodified official admissions-office signatures (include
입학처 wording); KNU uses the official horizontal KNU signature. Provenance JSON
records official URLs, archive member where applicable, previous/new source hashes
and bundle hashes. Official downloads were visually inspected; all42 decode in Flutter.

Hero removes 나의 논술 LAB plus its spacing; existing History and actual server
Credit balance remain responsive. No hardcoded balance and no purchase addition.
Question rows are checkboxes, with selection count and no-selection CTA disabled.
Single-question exams default selected. Selection is stored per exam; original
rewrite question set remains fixed and foreign Registry IDs cannot be added.
An IndexedStack keeps the existing writer for each selected question alive; a
question selector saves before switching. Text/photo Draft keys and PDF state are
unchanged. Review receives the whole selected set and identifies blank answers
before execution; submit guard also names a missing question. Existing API/hash,
1-credit policy and14-day free-rewrite contracts are unchanged.

Files: source_catalog_page.dart, essay_pages.dart (one color), generated
university_catalog.dart,9 logo PNGs/provenance, source_catalog_widget_test.dart,
essay_logo_assets_test.dart, new essay_multi_selection_test.dart.
Validation:25 tests PASS,4 existing private actual-result fixture tests SKIP because
fixture is unavailable.360dp/100–200% selection/deselection/count/CTA, per-question
Draft switch/reopen, missing-answer review, fixed rewrite set, Hero/scroll, image
handling, Registry/PDF, request hash and14-day eligibility regression passed.
Flutter Analyze PASS; iOS simulator debug build PASS. No Provider/Credit transaction
or production setting/DB operation. Public HOLD.

Owner remaining device check: all11 logos on white (including official admissions
wording), SKKU scale, shorter Hero, multi-question selection→write→switch→Draft
restore, empty-answer notice and navy buttons including 다시 써보기. No new evaluation
submission needed. Earlier initial server cost-quote limitation remains outside
these four fixes. Rollback: revert follow-up UI/assets commit and rebuild; no DB rollback.
