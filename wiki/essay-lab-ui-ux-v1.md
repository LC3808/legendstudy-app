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

## iPhone logo, Hero and History follow-up — 2026-10-15

Owner scope: preserve accepted selection/writer flow; only logos, Hero spacing and
History readability. Paid-cycle extension is READ-ONLY analysis, not implementation.

Implemented in existing source_catalog_page.dart/shared_history_page.dart:
- Ewha, Seokyeong, UOS and Kangnam use official basic university PNG assets without
  입학처. Original pixels/proportions preserved, source URLs/hashes in
  assets/university-logos/provenance.json. No generated/recolored assets.
- SKKU wide 518×97 logo keeps aspect ratio; display width100→132, height52 unchanged.
  Its wide source aspect, not brown container or distortion, caused small lettering.
- Hero vertical padding16→6; History action and live server Credit unchanged.
- History shows university, exam identity, text badge, date and existing result
  actions. First-cycle badge navy; existing exam parent_id rewrite green (darkened
  success token for white-text contrast). Legacy/Math rewrites say 재첨삭, without
  inventing a free entitlement. Existing explicit parent grouping/dividers remain;
  independent same-exam submissions are never heuristically merged.
- Result/comparison screens, history queries, Drafts and all Backend contracts unchanged.

### Additional paid cycles — read-only findings

Evidence: supabase/migrations/20261014023133_essay_exam_operating_api.sql;
lib/features/essay/{source_catalog_page,shared_history}.dart;
LAB src/components/essay-exam-submit.tsx and functions/api/essay/exam.ts.
This is checked-in contract analysis, not a new production DB audit or transaction.

Existing reserve API accepts a new root (parent_id=null) with a new request key for
same exam/questions:1 Credit. One child of that successful paid root is included
at0 Credit. Window is measured from parent's successful completed_at +14days,
not submission date or free-child completion. A child cannot itself be a free
parent. Root refund, changed question set/snapshot context/version, expired window
or existing reserved/completed child blocks inclusion; failed child does not consume
it. Account row locks, account+request_key uniqueness and immutable terminal results
protect duplicate/concurrent same-intent calls. Failure releases reserved Credit;
completion consumes once. Distinct keys deliberately represent distinct paid intents.

Therefore existing Ledger can support repeated paid/free PAIRS without changing
Ledger rules. Full continuous paid-cycle UX/lineage is NOT currently implemented:
WEB and APP keep pending request IDs under exam+parent/initial, with changed-answer
conflict protection and no explicit new-paid-cycle transition. History only returns
parent_id within a pair, not previous paid cycle or billing reason. Same exam/date
cannot prove an additional paid relationship. Additional-paid badge must await that
reliable relation; it is not inferred or falsely displayed in this patch.

Minimum future implementation:
1. Shared server quote/eligibility and explicit additional-paid consent; preserve
   unresolved pending requests. Only after known terminal state start a new persistent
   cycle request ID; WEB/APP retry same intent with same ID, not a random retry ID.
2. Reuse reserve/finish/Ledger. Keep parent_id exclusively the free child→paid root.
3. For continuous history, optional previous_paid_run_id on the EXISTING runs table
   plus submit/history RPC fields and account/exam/exact-question-set validation,
   immutable link/cycle prevention, deletion lifecycle. No new History store.
   This minimal DB/RPC change needs separate Owner approval; no SQL applied now.
4. Both clients read that shared link to label additional paid navy and free green,
   preserve separate paid/free pairs and original results. Pair retains frozen
   evidence/rubric; any next-paid package-version change must be explicit.
5. Preserve immutable learning events, account identity, privacy/deletion policy,
   evidence versions, independent submissions, existing comparisons and audit facts.
   No guessed backfill or automatic growth comparison across incompatible rubrics.

Validation:13 relevant tests PASS across History/selection/Draft/logo decoding;
4 existing actual-result private-fixture tests SKIP (fixture unavailable).
360dp at100%/200% text: History badge/identity, Hero and multi-question Draft flow PASS.
Flutter Analyze PASS. iOS simulator debug build PASS (Runner.app).
No Provider call, Credit trade, production DB/config change or release-branch edits.
Public HOLD.

Owner iPhone recheck: four official basic logos and SKKU visual size, shorter Hero
with live Credit and working History, navy 최초 첨삭 / green 무료 재첨삭,
exam identity/date, result and existing comparison navigation. No new submission.
Rollback: revert this UI/assets commit and rebuild; no DB rollback required.

## APP/WEB result consistency and paid cycles — 2026-10-15

Latest Owner GO supersedes the earlier READ-ONLY paid-cycle restriction for LOCAL
implementation only. Existing approved result/Writer/PDF components retained.
No Provider Prompt/schema, original Package/result, Math, Ledger body, Toss/IAP,
Claude branch, production settings or data changed. General public HOLD.

### Implementation and preserved contracts

- APP `shared_history*.dart`, WEB `my/essay-history.tsx` and existing report adapters:
  full card/badge navigation, latest completion order, canonical exam + sorted exact
  question-set grouping, thin dark dividers. Grouping does not create billing lineage.
- Navy 최초 첨삭/추가 첨삭, green 무료 재첨삭; submission labels show Credit only at
  request. Server `submission_index` is used when present; legacy rows retain
  unnumbered 수정 제출 답안 rather than inferred ordinals from a paginated list.
- Result header separates university/exam/track/type/date; existing stars retained,
  comparisons explicitly N/5, changed first and unchanged collapsed. WEB shares APP
  short criterion headings. Raw result remains immutable.
- Existing contract1.3 already stores optional `sentence_feedback`; both adapters
  now connect it to exact Unicode span checks. Only stored matching quotes and
  optional examples appear; examples collapsed. No Prompt/schema change.
- Rewrite drafts are isolated by account/question/source run/free-vs-additional.
  Restore existing scoped draft; otherwise blank. Unfinished legacy local text
  (different from submitted answer) and photos are preserved. Explicit previous
  answer view/import with overwrite confirmation. Original history unchanged.
  IMPORTANT: cycle-scoped drafts remain device/browser local: existing server Draft
  has no cycle namespace. Original question Draft sync stays intact; cross-platform
  rewrite Draft sync is NOT claimed. Submitted results/History stay shared.
- Request replay reuses persisted key and bypasses a new eligibility quote: a
  committed free reservation must not be blocked by its own consumed eligibility.
  New intent obtains server quote first; unavailable quote fails closed.
- Additional paid cycles: candidate `supabase/candidates/essay_continuous_cycles/`;
  existing reserve/finalize reused, paid predecessor/exact set/sequence stored on
  existing runs. New paid/free pair, four-way concurrency, failure release, quote,
  role denial and erasure/Rollback tested locally. NOT_APPLIED. LAB extra cycle flag
  defaults OFF. Candidate quote deployment must precede enabling new client submit.
- Native `essay_voice.dart` + pinned flutter_tts4.2.5: section/element titles, stored
  feedback and comparison only; full/section listen, pause/resume/stop, dispose and
  background stop. No AI Provider. iOS uses CocoaPods fallback (SPM warning).
  WEB existing local Korean voice controls retained, explicit stop added. Native
  voice availability/audio and route transitions require physical acceptance.
- Earlier checkpoint (superseded by Owner logo delivery below): no invented
  replacement or change to currently accepted assets in this task.

### Read-only operating evidence and quality preparation

Read existing review account runs `5b636cda-9915-42e1-b209-9934c7c0fcb1` and
`414a207b-2c51-48e6-97ea-2ddf49b77c9e`, and verified material revision17. Package
`40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae` matches both.
Actual utilitarianism3→4, four maintained. Both sentence_feedback arrays EMPTY:
existing results cannot demonstrate populated quotation/example UX. Synthetic
exact-quote fixtures validate rendering only, not Provider quality.

10/25/25/30/10% occur in verified official criteria evidence text and copied runtime
labels, not generated Provider levels. Structured `criterion_weights` is null;
UI hides raw percentages pending a verified structured display binding. Official
source provenance: existing hanyang_afternoon2_source.json, criteria guide52–53 /
registered evaluation PDF5–8. The AI change analysis is explicitly labelled as such.
Package model_answer has a page reference without extracted text. Reuse existing
private PDFs; do not ask Owner to reupload all materials or claim A/B executed.

`tool/essay_lab/quality_scenarios.json`: A–G types, pinned IDs/package, criteria,
PASS/PARTIAL/FAIL/NOT_VERIFIED, required case fields and approval-gated execution
plan. `quality_review.py` creates a private HTML from existing runs/package, with
original/revised answers, official evidence, results and Owner notes. Real private
inputs/output are outside Git. Quality remains NOT_VERIFIED until Owner review.
No new admin system/table. Later test plan: at most14 Provider calls for seven
cases with independent review, zero Credit, costs recalculated before approval.
No repeated evaluation has been executed.

### Validation and acceptance boundary

- Local PostgreSQL integration/cycles PASS; only synthetic transport/fixtures.
- Stored actual results rendered through Native and WEB adapters; no new calls.
- APP 360dp/200% related tests, Analyze and iOS simulator build checked; final
  counts recorded in current-status/log. Full suite exposes four pre-existing
  account_deletion_test pumpAndSettle timeouts, reproduced on unchanged HEAD.
- WEB complete suite, ESLint, TypeScript and production build checked on Node22.
- Local browser 360px result rendering + native widget screenshot inspected;
  these are render checks, not a new authenticated production E2E.

Owner device checklist: card/badge result entry; canonical groups/latest sorting;
header/question/type/date; actual3/5→4/5; answer expansions; empty/restore/import
rewrite with photos; full/section voice pause/resume/stop and back navigation;
200% text. New paid cycle operating activation requires separate SQL/config and
Provider/Credit approval. Rollback is documented and refuses nonempty cycle data.

## Owner supplied SKKU/UOS logos — 2026-10-15

Only two logo assets replaced: `assets/university-logos/skku.png` from Owner
`n_2.jpg` (1136×271, original white background); `assets/university-logos/uos.png`
from `logo_horizontal_2.png` (900×900, only transparent margins cropped to
809×112). No recoloring/generation; source/bundle hashes in provenance.json.
Both use the existing 100×52 card logo box, centered BoxFit.contain, zero inner
padding for these two only. Earlier SKKU-only132px width removed to match existing
card geometry. Other logos, card padding/touch behavior and catalog IDs unchanged.
Validation: related7 tests (all42 assets decode; real supplied assets at360px and
100%/200% text, whole-card navigation), Flutter Analyze. iPhone final visual
approval remains Owner action; no build/deploy/DB/Provider/Credit changes.

## Result badges and speech follow-up — 2026-10-15

Owner device PASS: History sorting/card and badge navigation, answer versions,
rewrite/import/Draft preservation, Native voice playback/controls. These remain
unchanged; SKKU/UOS assets at3f28529 also unchanged.

- APP/WEB result identity uses separate Registry track/session bordered badges;
  wraps without parsing or inventing identity from display strings.
- Existing comparable level deltas now say 이전 첨삭보다 평가 수준이 한/두/세/네
  단계 높아졌습니다/낮아졌습니다, or 동일한 평가 수준을 유지했습니다.
  Secondary text: 평가 단계:3단계→4단계(5단계 기준); stars retained.
  Previous is intentionally used because the comparator may be a later paid cycle,
  not always the initial submission. No invented change reason or official score.
- Speech uses separate structured-level sentences (5단계 평가 중3단계입니다),
  never generated slash fractions. Native comparison overview first; then visible
  summary/strengths/criteria/weaknesses/actions/checklist order. WEB follows its
  existing report then comparison layout. Changed criteria precede unchanged.
  Section and criterion titles lead their bodies; repeated identical lines are
  suppressed in whole reading. Existing controls/navigation stop unchanged.
- Folded criterion explanations remain included in whole reading; submitted
  answer and optional rewrite examples are not automatically spoken.
- APP files: evaluation_presentation.dart, approved_result_adapter.dart,
  essay_pages.dart, essay_voice.dart, shared_history.dart/shared_history_page.dart.
  WEB: my/evaluation-presentation.ts, exam-history.ts, essay-dashboard.tsx/CSS,
  evaluation-report.tsx. Source reports/Schema/Prompt/Ledger/Draft untouched.
- Validation: related Native32 tests including stored actual results and360px/200%
  layout; Analyze/iOS simulator build PASS. WEB102 related tests plus
  Lint/Typecheck/Build PASS. Actual iPhone pronunciation/reading alignment and
  visual badges await Owner. No Provider/Credit/DB/deployment execution; HOLD.

### Final bounded mobile polish — 2026-10-15

Owner requests only three identity badges on one wrapping line and actual
screen/speech order alignment. `EssayExamBadges` now includes the existing Registry
question label alongside track/session, sharing bodyMedium/padding/border style.
360px normal scale fits one row;200% wraps. No separate question text row.
First result visibly begins with 내 답안 한눈에 보기 but speech skipped it:
added that existing summary before 종합 평가. Rewrite already begins with
이번 답안의 변화 한눈에 보기; unchanged. All playback controls unchanged.
Files: shared_history_page.dart, essay_voice.dart; related3 test files.
11 related tests PASS (stored actual first/rewrite,360px/200%, badges and speech),
Flutter Analyze PASS. No new build/deploy/WEB/Provider/Credit/DB/IAP change.
Further UX development stopped per Owner; release preparation is next.

## Oct16 launch preflight — additional cycle READY LOCALLY / operating E2E pending

Owner scope: existing engine, Prompt/Schema, Package, Ledger and Payment/IAP preserved.
No production DB/config/deployment/Provider/Credit changes in this task.

Read-only production at about14:00 KST:
- `essay_exam_quote`/`essay_exam_submit_cycle`: postgres SECURITY DEFINER;
  essay_worker EXECUTE. Registry234, completed runs2, new cycles0.
- review account `ddc5ae63-acbb-490b-a423-c996b811dea8`: credit_summary spendable10,
  reserved0. Quote returns additional/1 Credit for exam
  `345d3caa-3438-58c3-8f80-62a6242179ec`, question
  `4cbe8b69-2ccc-5c4e-9e77-0644f90e2cde`, previous paid run
  `5b636cda-9915-42e1-b209-9934c7c0fcb1`. Free child
  `414a207b-2c51-48e6-97ea-2ddf49b77c9e` remains completed.
- Package17 digest40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae;
  VERIFIED_MANIFEST, both sources OpenAI rights approved. Stored runtime_ready=false
  is not an activation grant; material_runtime derives readiness from evidence and
  the separately authorized host policy. Preflight binding remains gpt-5.6-sol,
  scaffolding-1.3-v3 / contract1.3 / hanyang-2024-afternoon2-pilot-v1.
- Cloudflare same LegendStudy account b9d221b20fdf8b9a9a8df0971a6b2347: Pages
  ESSAY_EXAM_RUNTIME_ENABLED=false; continuous flag absent/OFF; Worker
  ESSAY_EXECUTION_ENABLED=false. Five existing Secret names present (values unread).
  Previously verified Worker JWT/Queue preserved; no new Queue/auth probe repeated.
- Production Pages canonical source8518db6 is the earlier rewrite gateway, missing
  quote/submit_cycle. DB installation alone does not enable the new client path.

Minimal implementation: LAB functions/api/essay/exam.ts extends existing single-E2E
scope with previousPaidRunId; quote/submit must match pinned predecessor, parent,
subject/exam and server request key. Default OFF, mixed/invalid scope denied.
No new API/engine/UI. The existing Codex branch already has quote/submit_cycle;
new endpoint tests cover the additional bounded E2E. Before live testing deploy
only the reviewed gateway delta over current deployment, preserving other surfaces.
No deployment was performed. Rollback: previous gateway deployment + all flags OFF;
retain any completed/pending run, checkpoint, Ledger and History.

APP/WEB both submit via /api/essay/exam and read essay_exam_history; both consume
canonical credit_summary. Existing actual2 results pass both display adapters.
Native rendering:360px and200% first/rewrite; no new result creation.

IAP integration READ-ONLY: Claude local HEAD3b4e220 (newer than b97e833), unchanged.
IAP controller matches Codex. Shared credit_summary contract unchanged. Production
postgres and essay_executor both have internal credit_post_grant EXECUTE.
Codex-only edits to preserve during selective integration: billing_providers.dart,
purchase_verification.dart (TEST session guard), credit_purchase_page.dart,
purchase_history.dart, credit_balance.dart (compact essay Hero). Claude's
verify-iap-purchase/{core.ts,index.ts,core_test.ts} adds isolated Apple Sandbox gate;
these protected files were not copied/changed. Do not merge whole branches.
Google TEST success is not Apple Sandbox or Production IAP approval. Apple/refund
acceptance and final combined signed store build remain release-owner gates.

Quality: existing results reference exactPackage17, utilitarianism3→4 and four
maintained. Official criteria include pure-pleasure total, justification strengths
and rights criticism; revised feedback addresses these. No newly detected major
criterion mismatch in this narrow review; NOT final quality approval. Both stored
sentence_feedback arrays empty: quotations/examples remain NOT_VERIFIED, never
fabricated. Existing quality_review.py regenerated private Owner review HTML at
/private/tmp/legendstudy-launch-quality-review.html; inputs outsideGit, no Provider.

Validation Oct16: APP50 related PASS (initially4 optional fixture skips); rerun actual
stored-result6 PASS including all4 skipped render cases. Flutter Analyze clean;
iOS simulator debug build PASS (existing flutter_tts CocoaPods fallback warning).
WEB26 files/133 PASS + actual stored-result1 PASS; ESLint, TypeScript, Node22 build
135 static pages PASS. Local disposable PostgreSQL continuous paid/free sequence,
same-intent concurrency, unique successor, failure recovery, sequence immutability,
role denial and async Package→fake Provider→Ledger→History PASS. Not live E2E.

Remaining launch BLOCKERS: bounded additional-paid real E2E; operating gateway
promotion/config approval; final APP/WEB live result comparison; Apple/Production
IAP and protected branch integration acceptance; Owner quality/public release approval.
Multi-question runtime synthesis and source-exam photo submission remain unsupported:
launch must be restricted to verified single-question text exams unless completed
and separately tested. Do not label all234 questions service-ready.

Proposed next approval: review@legendstudy.com, exact exam/question/Package17 above,
reuse existing revised text once, evaluation1+independent review1 (max2 Provider
calls, requested capUSD2, estimateUSD0.25–0.80 based on prior same-size test plan,
not a billing guarantee), reserve/settle1Credit (10→9). One pinned request/predecessor;
no free follow-up or extra retry. Include recovery of only this run. Normal failure
releases reservation; ambiguous Provider/finalization checks existing checkpoints
without a second Provider call. Finish by disabling Pages/Worker/continuous flags.
DB schema/RLS unchanged. Owner approval required before deploy/enable/execute.

### Oct16 approved bounded deployment — waiting for account login

Owner approved gateway-only promotion and one additional-paid E2E (max2 Provider
calls/USD2/1Credit plus this run recovery). Promoted only functions/api/essay/exam.ts
from LAB14e7612 over actual deployed source8518db6; no UI/Math/Payment delta.
Pages deployment3b99d254-692b-405d-bdf4-574e75178ab3 SUCCESS. Gateway SHA256
d0640668a83904f966d98dd1da584734c09cad0fe4f12c7b72d3dba83a9020ab.
Webpack build135 pages PASS (Turbopack staging symlink root restriction avoided).
Pages/continuous/Worker all OFF; public request503 EVALUATION_UNAVAILABLE.
Prior deployment rollback45c3935b-c8c8-4fd4-94fc-5c1e31bb51a8.

No Provider or Credit submission yet. The current live UI predates additional-cycle
controls. Owner terminal-login helper /private/tmp/legendstudy-additional-e2e.py
uses the actual review account, keeps password/JWT only in memory, waits for an
operator readiness marker and sends one exclusive local intent. Request key
a4d46895-ed93-4c67-a685-902b6d5368d7 pins the already approved predecessor.
No marker created; waiting for Owner login, no need to seek execution approval again.
If login times out, rerun helper before submission; never remove a sent intent to
retry. Reconcile same request from DB/checkpoints on unknown outcome. Public HOLD.

### Oct16 authenticated transport stop before submission (14:36–14:39 KST)

Owner login succeeded. Scoped activation deployment46122cd1 was verified for the
approved subject/exam/predecessor/request key only. The terminal Python request
stopped at quote with HTTP403; no submit intent was created and the fixed request
key has no run in Production. Unauthenticated reproduction identified Cloudflare
error1010 for urllib, while curl reaches the gateway normally. Terminal transport
now uses curl with credentials supplied through stdin only (not argv/files/logs);
syntax and expected OFF503 response verified. No application/auth policy changed.

Worker OFF and Pages runtime/continuous OFF restored; deployment
5869f421-93d0-460f-a341-2aa7f1796258 SUCCESS. All36 unrelated Pages bindings and10
unrelated Worker bindings preserved. Provider calls0, Credit reservations/charges0.
Readiness marker removed; request key unchanged. Owner terminal re-login is needed
because credentials were memory-only and the first script exited. Existing E2E
approval remains valid; do not request approval again or create a second request.
Public HOLD. This is a transport interruption, not a completed paid E2E.

### Oct16 additional-paid operating E2E — completed, public HOLD

Owner-approved review account/Hanyang2024 humanities afternoon2/question1/Package17,
request a4d46895-ed93-4c67-a685-902b6d5368d7: run
346083f3-1e9c-4cbb-8cf2-cdf7d25bfef9 completed 2026-10-16 14:48:27 KST.
Previous paid run5b636cda-9915-42e1-b209-9934c7c0fcb1, submission_index3,
parent_idNULL (new paid cycle), identical existing1174-character revised answer.
Registry234 and both Oct14 completed runs preserved. No DB schema/RLS changes.

- Actual Provider evaluation1 + independent review1; signed review checks all pass.
  Evaluation12968 input/1734 output; reviewer12229 input/3823 output tokens.
  Total30754 tokens. Cost/currency fieldsNULL: actual USD charge NOT_VERIFIED;
  do not report estimate as measured cost. No extra Provider retry/free evaluation.
- Billing settled1: reserve(+1 reserved), consume(-1 balance/-1 reserved), exactly
  one consume. credit_summary spendable9/reserved0 (before10/0).
- Owner-authenticated History RPC HTTP200 contains completed result, index3,
  previous_paid_run_id and free_rewrite_available=true.
- Next same-set free quote included0; window ends Oct30 14:48:27 KST.
  Old paid predecessor quote rejects PAID_CYCLE_ALREADY_STARTED. These checks
  are read-only; no fourth submission or duplicate paid submission was executed.
- Live WEB History/result and balance9 verified. Summary starts
  “논제의 세 요구를 모두 충실히 수행한 강한 답안이다.” Five criteria all4/5,
  matching the prior revised answer levels; no invented sentence feedback/examples.
- Operating WEB remains old8518db6 UI, so it labels this paid-cycle result as
  “최초 평가” and lacks the approved additional-cycle controls. Gateway-only
  deployment did not promote UI. This is an outstanding launch display GAP.
  APP device readback of this new result requested; not yet confirmed.
- The first/free-only QA harness cannot be reused as an additional-cycle comparison:
  parent_id is intentionallyNULL. It rejected that mismatched fixture before
  rendering. Separate stored additional-result QA now checks server index3,
  paid predecessor/free entitlement and actual output without inventing lineage.
  APP Native360px/200% test1 PASS; WEB stored-result render1 PASS. These are
  actual-result local render checks, not APP device acceptance.

Two pre-submit interruptions caused no Provider/Credit operation: urllib403/error1010
corrected by curl stdin transport; INVALID_ANSWERS caused by stored rubric/evidence
metadata corrected by projecting questionId/body/revision only. Body unchanged.
The rejected local intent is preserved separately; the successful intent remains
exclusive. No second run was created for the fixed key.

Enabled deployment288f82e3; after completion WorkerOFF and Pages runtime/continuous
OFF restored, deployment433141d6-b33b-4473-993c-7069697f3b75 SUCCESS. All other
36 Pages bindings/10 Worker bindings preserved. Public endpoint503 hold checked.
No Math/Payment/IAP/Claude branch change. Production UI promotion, APP device result
acceptance, measured API cost and final quality/public-release approval remain open.

Final checks: additional QA Flutter Analyze clean; WEB ESLint/Typecheck PASS;
public503 verified; Registry234/prior completed2/fixed-key runs1 confirmed.
No application runtime source changed this turn; QA and Wiki only. Prior iOS/WEB
build evidence remains applicable; no redundant rebuild for documentation/tests.

### Oct16 Owner device confirmation — additional paid result

Owner confirmed the requested APP check: review@legendstudy.com, Hanyang result
completed14:48, balance9, summary “논제의 세 요구를 모두 충실히 수행한 강한 답안이다.”
match WEB. Additional paid result/History readback and Credit balance parity PASS
by Owner device evidence. This supersedes the pending APP device check above.
No new submission, Provider call, Credit transaction, deployment or DB change.
Operating WEB additional-as-initial label GAP, measured USD cost and final release
approval remain open. All execution flags remain OFF; general public HOLD.


## Oct18 release candidate / material expansion inventory

Local evidence: existing material-coverage.json (registered76 exams/234 questions,21 universities) and canonical Catalog42 / Owner22. This is a source-candidate inventory, not a new live database audit or approval of all234. No downloads, uploads or redistributions performed.

| Owner order / University | Registered exams/questions | Source files | Intent / scoring / explanation / example candidates (exams) | Reviewed / rights |
|---|---|---|---|---|
| 1. 가천대학교 | 0/0 | 0 | 0/0/0/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 2. 중앙대학교 | 24/75 | 24 | 20/23/22/23 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 3. 성균관대학교 | 2/6 | 2 | 1/2/2/2 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 4. 경희대학교 | 2/7 | 2 | 0/0/2/2 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 5. 한양대학교 | 3/5 | 3 | 2/1/2/0 | Hanyang2024 afternoon2 Package17 only reviewed; two-source Provider rights recorded, student problem access scoped |
| 6. 한국외국어대학교 | 1/3 | 1 | 1/1/1/1 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 7. 고려대학교 | 0/0 | 0 | 0/0/0/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 8. 국민대학교 | 0/0 | 0 | 0/0/0/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 9. 건국대학교 | 3/8 | 3 | 3/3/3/3 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 10. 서강대학교 | 1/1 | 1 | 1/1/1/1 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 11. 이화여자대학교 | 1/3 | 1 | 1/0/1/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 12. 숭실대학교 | 1/2 | 1 | 1/1/1/1 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 13. 인하대학교 | 3/9 | 3 | 3/3/3/3 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 14. 동국대학교 | 6/18 | 6 | 6/6/6/6 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 15. 세종대학교 | 3/9 | 3 | 2/3/3/3 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 16. 연세대학교 | 12/47 | 12 | 12/1/12/1 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 17. 홍익대학교 | 1/7 | 1 | 0/0/0/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 18. 아주대학교 | 6/12 | 6 | 0/5/1/5 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 19. 삼육대학교 | 0/0 | 0 | 0/0/0/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 20. 경북대학교 | 1/3 | 1 | 0/1/1/1 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 21. 경기대학교 | 0/0 | 0 | 0/0/0/0 | Not certified by this inventory; redistribution/provider rights require per-source evidence |
| 22. 부산대학교 | 2/6 | 2 | 0/2/2/2 | Not certified by this inventory; redistribution/provider rights require per-source evidence |

A zero means no matched registered candidate in this snapshot, not proof that the university has no official materials. `scoring_criteria` is a candidate role, not proof of an approved rubric. Official excellent-answer status is not separately attested by this manifest; example-answer candidates must not be relabelled excellent answers. Original holdings20ZIP/~1030PDF/581candidate groups are historical ingestion totals, not approved student redistribution.

Expansion order: finish Owner quality review of existing Hanyang17 first; reuse Sookmyung/SKKU holdings next per earlier first-wave policy; then retain the Owner22 order above. Match exact exam/question UUIDs and source hash/pages; inspect existing candidates before requesting only genuinely missing PDFs. Reuse automatic extraction and Owner approval workflow, never repeat approved Hanyang review.

Quality gate: compare official intent/criteria/example with existing first/free/additional results; verify literal student quotes, stage rationale and no invented weights/examples. Use existing A–G fixtures (excellent/example/general/error/revised/partial/unchanged), mark absent official answers NOT_VERIFIED. Require documented PASS/PARTIAL/FAIL/NOT_VERIFIED reasons and Owner approval; Provider simulation requires separate budget/transaction approval. No new engine or production table.


## Oct18 WEB and speech audit — READ-ONLY, implementation approval required

Live anonymous browser: /essay-lab/ displays42 university catalog and logos;
Hanyang→2024→수시 논술→인문계열 opens question1 writer. No typing,submission,
login or account write performed. Public HOLD displays disabled 첨삭 준비 중.
Result/rewrite/History are code-reviewed here; prior authenticated E2E is retained,
not reported as newly exercised.

WEB gaps / minimum follow-up: university name and separate 첨삭 시작하기 links
lead to the same page; reuse existing card with one clear action. SourceExamSelection
shows a question tab AND inclusion checkboxes; single question opens its writer but
is not included by default. Align selection/count/답안 작성하기 flow with approved
APP policy, keeping exact question-set contract. PDF2–3쪽 is still on writer, and
History appears both above and below. Preserve writer/Draft/PDF and simplify only
redundancy; do not interpret disabled public submission as a bug to activate.
UniversityEssayStart has a separate DB-backed selection path and serial question
reads; keep fallback identity binding and review loading/retry before UI unification.
Existing History sort/group/card,stored-result comparison and rewrite empty/Draft/
optional-copy components should be reused. SourceExamSelection reset and owner keys
remain data-isolation boundaries. No WEB code change/deployment this task.

Speech evidence: APP flutter_tts4.2.5→iOS AVSpeechSynthesizer, Android TextToSpeech
(default device engine; actual installed voice quality not inspected). essay_voice.dart
sets ko-KR but no explicit voice/rate/pitch; plugin iOS uses default speech rate and
pitch1. APP splits at fixed1500 UTF-16 code units, potentially inside a sentence/word;
no explicit Markdown/formula normalization or paragraph-pause scheduling. Pause
stops speech and resumes from latest progress offset, potentially repeating a word
or a chunk if the OS callback is delayed. Screen/lifecycle stop remains implemented.
Native voice selection does not explicitly enforce Android offline voice even though
code comments say device speech; confirm engine/voice network requirement before any
claim that arbitrary installed Android engines are strictly offline.

WEB voice-feedback.tsx uses browser SpeechSynthesis, first localService Korean voice,
rate0.8/1/1.2 (default1),default pitch. Entire prepared text is one utterance; native
pause/resume/cancel,unmount cancellation. No paragraph queue or cross-player owner
coordination: each section player controls the shared browser synthesizer. An old
player may display stale playing state when another section cancels it. Human
speech builder adds section titles/deduplicates lines and speaks5단계; it has no
Markdown/unit/formula preprocessing. Business path directly joins feedback strings.
Existing Math voice exclusion/science gate stays in force; this audit does not enable
formula reading. Stage values are learning levels, not official scores: preserve
5단계 중3단계; only actual score fields may be spoken as5점 만점에3점.

Code-supported causes to test: sentence-midpoint chunking,raw punctuation/Markdown,
OS-dependent default voices,one long WEB utterance and callback-based resume. No
fresh listening experiment was conducted, so perceived naturalness is not certified.
Minimum proposal (approval pending): shared semantic speech policy→sentence-aware
chunks→explicit section/paragraph boundaries→safe Markdown cleanup and known-unit
pronunciation→unknown formula verbal fallback without interpretation→one playback
owner and stable resume position. Preserve text/results and all controls. First test
existing stored humanities text on both devices; use synthetic formula strings for
normalization tests, not a paid Provider. Cloud TTS is deferred: adds network latency,
usage cost and transmission of student answer/feedback. Compare Korean continuity,
math/science accuracy,latency/cost/privacy/platforms only if local improvement fails;
no vendor/pricing or API adoption decision is made here.
