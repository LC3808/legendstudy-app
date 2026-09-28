# Essay LAB Workspace UI v1

2026-09-28 · Phase 1 IMPLEMENTED / OWNER VISUAL REVIEW READY.
실제 Flutter 화면이며 **메모리 내 가상 자료만 사용**한다. Production 학생 저장,
AI 평가·생성, worker, 회차권 결제는 활성화하지 않았다. DB/RPC/migration 변경 없음.

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
