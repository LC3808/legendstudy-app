# TASK16-G 품질 검수 / TASK16-H 준비

2026-11-03. **기능 E2E Owner PASS (`b52ab42`), 품질 PARTIAL / 운영 HOLD.** 이번은 저장된 실제 결과·공식 자료 대조, 격리 TEST 읽기 검사와 H 계약/UX 준비다. 신규 Provider 호출0, 신규 평가0, 원장/결제/schema/배포/릴리스 변경0. 추가 구현은 회귀 검사·오프라인 감사 도구뿐이다.

근거: [G 기능 E2E](task16g-learning-loop-20261102.md#최종-결과), [C 원본 검수](task16c-hanyang2024-handwriting-validation-20261102.md), [E 공개·확인 게이트](task16e-recognition-disclosure-p0-20261102.md), [B 혼합형 대표 시험](task16b-commerce-social-integration-20261102.md#대표-시험-및-공식-근거), [F 승인 UI](task16f-native-math-ux-20261102.md), [Mobile First 결정](decisions.md#2026-11-03--task16-g-mobile-first--task16-h-web-분리).

## 1. 보존 검토와 자료

기존 일곱 답변을 계승한다: (1) 발생/확인/공개 시점은 서버 원본 시각, (2) 공식 PDF·사진·후보·확인본 hash/ID 보존, (3) 평가/수정은 기존 lineage를 유지하고 UPDATE/삭제하지 않음, (4) 동일 TEST Auth owner, (5) 학습과 Credit 판단/입시 Outcome 분리, (6) 학생 사진·계정·원시 결과 Git 제외 및 기존 비공개 권한, (7) AI 판정과 자동 신뢰도를 원문 사실로 취급하지 않음. 새 수집·저장 구조는 만들지 않는다.

C의 공식 문제·출제 의도 및 평가 지침·예시답안·합격자 우수답안 4개 PDF SHA-256을 다시 계산해 모두 일치했다. C manifest의 파일 경로와 쪽 번호를 재사용한다. Q1 평가표는 급수/미적분/극댓값·급수, Q2는 확률분포·기댓값/최단경로 확률/신뢰구간·자연수 경계를 요구한다. 문제50점과 내부 평가표100점 척도를 혼합해 점수를 생성하지 않는다.

재현: `python3 tool/audit_task16g_saved_quality.py --c-evidence <비공개 hanyang2024 폴더> --g-evidence <비공개 task16g-test 폴더>`. 네트워크/키 접근 없는 읽기 전용 도구이며 전체 품질 PASS를 출력하지 않는다. 개인 증거는 `~/.codex/legendstudy-task16g-test/quality-*.json`에 보존했다.

## 2. 실제 OCR 정확도

**Q1 FAIL / Q2 PARTIAL. 정확도 %는 산출 불가**: 독립 이중 검수된 전체 정답 전사와 고정 분모가 없다. 영역 수·confidence·구조 validator 성공을 문자 정확도로 환산하지 않는다.

| 원본 대조 | 확인된 문제 | 판단 |
|---|---|---|
| Q1 C order3 | −1/6,70/3 → −1/4,20/3 | 분수/숫자 의미 변화 |
| Q1 C order6/7 | 1/4의 부호 반전, ±16/17의 ± 누락 | 부호 확인 필수 |
| Q1 C order12/13 | 9α→α², e⁻ˣ→eˣ 및 −cos x의 부호 누락 | confidence0.90도 원문 일치 보장 아님 |
| Q1 C order17 | 최종 지수/분모 변경, 페이지 밖 bbox1개 | 수식·원본 위치 품질 FAIL |
| Q2 C | 표/최종값 일치, k/l·U 식별자 혼동 | 그 호출의 숫자 성공만 인정 |
| Q2 G 신규 사진 | 22/140→20/140,13/140→15/140 | 이전 Q2 성공을 보편 정확도로 일반화 불가 |

원본 Q1 확대·Q2 전체와 검수 내역을 대조했다. Q1 일반항 π 등 불명확 표기는 원본 성공으로 확정하지 않는다. G의 TEST 검증자 수정본은 학생 원본과 별도다. 학생 확인 게이트는 PASS지만 틀린 전사를 자동 탐지/정정하는 엔진으로 보고하지 않는다. 표/그래프 수치 재생성과 읽기 순서의 전체 정확도는 미통과다.

## 3. 실제 첨삭 품질

| 사례 | 저장된 실제 결과 재검수 | 범위/판정 |
|---|---|---|
| C Q1 우수답안 | 12단계 VALID, CORRECT였지만 불확실 π를 보충 | 과거 실패 증거 보존; 이를 품질 PASS로 사용 금지 |
| C Q2 우수답안 | 11단계, CORRECT, 오류0 | 올바른 풀이 인정 PASS. X/Y 표기 보완 누락 |
| C Q2 대안 풀이 | 독립성 E[k/l]=E[k]E[1/l], 조건부 합산 수용, 오류0 | 이 대조군만 PASS; 모든 대안 수용 보장 아님 |
| C Q2 경계 오류 | CONCLUSION/ROOT, 마지막 단계 연결, 힌트0/1/2 | 해당 오류 탐지·구체 힌트 PASS(저장 진단 결과) |
| G 신규 최초 Q1 | 11단계, NOT_DETERMINABLE/HUMAN_REVIEW_REQUIRED | 확정 오답/정답 대신 보류. 오류0을 성공으로 해석 금지 |
| G 신규 최초 Q2 | 10단계, CORRECT, 오류0 | 수정·확정 전사에 대한 정상 풀이 인정 |
| G 무료 Q1 | 12단계, CORRECT | 검증자가 작성한 수정 답안; 원본 OCR 품질과 별개 |
| G 무료 Q2 | 8단계, ALGEBRAIC_TRANSFORMATION ROOT + CONCLUSION PROPAGATED, PARTIALLY_CORRECT/HUMAN_REVIEW_REQUIRED | 의도한 경계값 오류 탐지. 실제 우수답안의 오류가 아님 |

현재 실제4평가 모두 criteria1개이며 공식 평가표 전체를 묶은 근거다. 세부 배점별 판단/근거와 독립 연결된 완성도는 부족하다. 단계는 생성되지만 분할 수가 C/G에서 다르며 전부 교육적으로 적절한 단위라는 보장은 없다. 사진 최초 평가 단계에는 region 참조가 있고 typed 재작성에는 없다. typed 답안에 원본 위치를 추정해서 연결하지 않는다.

Q2 수치는 L의 초기하분포와 k의 균등분포를 정수조합/Fraction으로 독립 재계산해 합1, E(W)=69/56, P(U≤10)=19/28 및 25<n<100의 자연수26…99를 확인했다. 기존 계산 오류 CALCULATION/개념 오류 THEOREM_MISUSE PASS는 **2026 상경 Q2 대조군**이며 2024 자연 Q1/Q2에서 계산·개념 오류를 각각 독립 실호출한 증거는 아니다. 동일 시험 오류 분류 범용 품질은 NOT_VERIFIED로 둔다.

## 4. 개선 과제·개념·힌트·공개

- 최대5개 제한은 로컬 SQL/실제4응답 모두 PASS. 실제 응답 과제수는 최초Q1/Q2·무료Q1 각각0, 무료Q2는1이다. 실답안에 5개 이상 오류가 있는 품질 표본을 검증한 것은 아니다.
- 현재 `coaching_projection`은 ROOT 오류만, MATERIAL_ERROR 우선 후 오류 UUID 순서로 자른다. 전파 오류 중복 제외는 적절하나 동일 중요도에서 학습 우선순위·공식 기준 영향 순위는 **미구현**이다.
- 기본 개념은 오류가 있으면 일반적인 ‘동치 변형과 적용 조건’1개, 오류0이면0개다. 확률/신뢰구간/급수 등 문항별 개념 카탈로그가 연결됐다고 볼 수 없다.
- 서버 hint1/2는 일반적인 조건 대조·검산 문구다. C의 구체적 경계 힌트가 현재 학생 응답에 그대로 연결되는 것은 아니다. 내용 안전과 교육적 유용성을 구분한다.
- 새 Q2 오류 과제의 source_regions는0개(typed 재작성), 전체 학생 확인 전사본 표시. 단계 위치 자동연결 성공으로 세지 않는다.
- 공개 전 생성된 steps/explanations/generated_solution 등은 projection에서 제외. 실제 비공개3응답에 full_solution 없음, 공개된 최초Q1만 있음. 기존 Simulator 명시 공개/취소·History 증거 재사용. SQL 전체 generated sentinel/우회 차단, 혼합형 Math masking/인문 불변 검사 PASS.
- 학생 자신의 전사본에 있는 정답 수치는 계속 표시한다. AI가 만든 정답 누출과 학생이 이미 쓴 답안 재표시는 다르며 H도 동일 정책이다.

## 5. 전체 풀이 수식 표현

분수·지수·적분·긴 신뢰구간·행렬을 320px 화면/280px 컨테이너에서 명시적 LaTeX 구분자와 함께 Native 렌더링·수평 스크롤·오류 없음 검사 PASS. WEB 기존 KaTeX 분수/지수/첨자/적분/행렬 및 원문 fallback 검사 PASS. 이는 렌더러 능력이며 모든 실제 응답의 표현 완료를 뜻하지 않는다.

실제 최초Q1 공개 응답은 references=[]이고 generated_solution 없음. 평가 steps만 존재한다. 따라서 ‘전체 풀이’가 대학 공식 완성 해설인 것처럼 표시하면 안 된다. Q2 무료 결과의 생성 풀이도 공식 해설과 구분해야 한다.

**표현 GAP:** WEB `MathText`는 명시적 구분자만 렌더링하나 `ServerCoaching`은 구분자 없는 representation/formula도 전달한다. Native `MathStudentText`의 고립 수식 추정도 구분자 없는 pmatrix 환경을 일반 텍스트로 남긴다. 이번 실패 검사로 확인했고 자동 수식 추정 범위를 넓히지는 않았다. 명시 구분자를 준 렌더러 검사는 통과했다. 전체 답안을 강제로 TeX로 감싸는 예전 문제로 되돌리지 않는다.

## 6. 상경·사회 혼합형

대표: 한양2026 수시 상경 exam `e8ea5bb3-0956-5fd6-b90e-4b7fb350b2f9`, Q1 Essay/Q2 Math 및 공식 Package는 B의 고정 자료를 재사용한다.

| 검사 | 결과 |
|---|---|
| 두 Worker 연결·시험 단위 차감 설계 | 기존 Essay 부모가 청구, Math 자식 별도 청구 없음; 새 엔진 없음 |
| 완료 누락/중복/외부 문항 검출 | WEB 회귀 PASS; 전체/일부 제출 범위 구별 |
| 혼합 Math 공개·힌트·History/인문 불변 | 로컬 disposable PG 실제 함수 검사 PASS; 합성 fixture |
| 실제 TEST 혼합형 이력 | 0건 |
| 실제 TEST admission/quote | 기존 비공개 접속 절차 인증 후 모두503 EVALUATION_UNAVAILABLE |
| TEST 계정 잔액 | 0, 예약0. 새 지급·원장 변경 없음 |
| Native TEST 혼합형 접근 | bearer-only /api/essay/exam은 비공개 gate401; Math 전용 경로와 달리 cookie 예외 없음 |
| 실제 혼합형1Credit 차감·전체 Worker 완료 | **BLOCKED / 미실행**, PASS로 보고하지 않음 |

최초 API 점검은 비공개 gate의 HTML401을 JSON으로 해석해 진단 스크립트가 실패했다. 기존 접속 코드로 정상 인증 후503을 확인했다. 인증 설정을 변경하거나 gate를 우회하지 않았다. 실행 스위치 변경과 TEST 잔액 지급 없이 현 상태를 기록한다. TEST 혼합형 실행 readiness와 별도 native 인증 경로를 먼저 해결한 뒤, 기존 합성 답안으로 최초3 Provider 요청(Essay생성/독립검수/Math)만 검증하는 후속이 필요하다. 기존 성공 평가 재호출은 하지 않는다.

## 7. APP↔WEB 공통 계약과 확인 수준

동일 TEST owner·2024 자연 exam·Q1/Q2·최초/무료 run을 사용했다. Native와 WEB의 실제 코드가 호출하는 `math_coaching`을 반복 읽어 `rewrite_policy.as_of`만 제외한 전체 응답 일치를 확인했다. 이는 공통 서버 계약 확인이며 **APP↔WEB 양방향 실제 브라우저 화면 PASS가 아니다**. 별도 플랫폼 평가 엔진 없음.

추가 실제 읽기 검사: Native Dart/브라우저 User-Agent 각각으로 같은 계정의4개 attempt 입력·History와2개 회차 견적을 조회해 일치했다. 최초Q1/Q2의17/18개 confirmed_regions 및 selected_extraction_id 일치, 수정 typed 답안 일치, 두 원본 이미지 bytes SHA-256도 일치했다. 무료 사용 후 다음 견적은 모두1개. `quality-shared-reads.json`에 보존. Native 실제 코드처럼 artifact POST에도 Origin을 포함해야 하며, 초기 진단에서 빠뜨린 요청은404로 거부됐다. 설정을 완화하지 않고 실제 클라이언트 헤더로 재확인했다.

| 정보 | 공통 식별자/읽기 계약 | 현재 차이 / H 요구 |
|---|---|---|
| 원본 답안 | attempt→artifact_id, 인증 `/api/math/artifact`, hash/page/bbox | Native 지원, WEB ServerCoaching 원본 로딩 미연결. 과제0개여도 `math_input.read_input`으로 원본 접근 필요 |
| 확정 전사 | selected_extraction_id/CONFIRMED successor, 원래 후보 별도 | steps 표현으로 대신하지 않음. WEB 완료 화면의 독립 원문 비교 뷰 미구현 |
| 첨삭/개선 과제 | `math_coaching` read, mixed는 `essay_math_coaching` read + run/question | 같은 DTO·최대5개. 공식기준별 세부 연결은 양쪽 공통 GAP |
| 힌트 공개 상태 | 같은 hint 요청키·History exposed_hint_levels | 서버 이벤트 공유. WEB hints는 화면 메모리, 재진입 공개 이력 읽기 미연결 |
| 전체 해설 상태 | read.disclosed, 명시 reveal(client_submission_id), History | 서버 공유. 최초Q1공개/나머지3비공개 상태 재확인 |
| 수정 답안 | previous_run_id/predecessor/lineage, 기존 draft 및 새 attempt | APP 제출 무료 run/확정 답안 저장. WEB 조회 API 가능, 실제 교차 UI 미검증 |
| 무료 사용 여부 | math_session_quote/continue, credits_required/next_quote | 현재 최초→무료 사용 후 다음1개. UI 자체 계산 금지 |
| History | math_session_history/read, coaching history; mixed 기존 essay_exam_history | 서버 저장 공통. WEB 개별 ServerCoaching에 학습 History 표시 미연결, APP도 이용권 표시 미제공 |

## 8. TASK16-H UX 준비 명세

**설계·계약 작업 착수 가능. 전체 구현/운영 활성화 승인 아님.** Academic Purple 토큰과 승인된 Mobile First 흐름을 유지한다. 서버 안전 DTO·기존 이미지 조회·History·견적을 재사용한다.

| 좌측: 원본 답안 | 중앙: 첨삭·개선 과제 | 우측: 기본 개념·힌트·해설 |
|---|---|---|
| 페이지/사진 선택, 확대·축소, 원본/확정 전사 비교 | 대학·연도·회차·문항·시도 헤더, 종합진단/잘한점/최대5과제 | 선택 과제의 개념·적용조건·주의점, 단계 힌트 |
| 후보→학생수정 차이와 확인 상태 | 과제 선택 시 같은 artifact/page의 검증 bbox만 강조 | 기존 공개 상태 복원, 명시 확인 후만 전체 해설 요청 |
| 미확정 위치는 전체원본·위치미확정 문구 | 완료/부분완료/보류/실패를 서버 상태대로 | 공식/검수/AI생성 출처 구분, 해설 없음은 없음 표시 |

- 초안 viewport 기준: 데스크톱1200px 이상 3열(좌/중/우 대략30/40/30), 900–1199px는 원본+결과와 선택형 보조 패널, 더 좁으면 기존 모바일 흐름에 맞춘 탭. 이는 H 검수 후보이며 Owner 승인 F 모바일 화면을 변경하지 않는다.
- 각 열 `min-width:0`, 수식 컨테이너 `max-width:100%`·수평 스크롤, 본문은 자연 줄바꿈. 수식을 임의로 잘라 줄바꿈하거나 전체 페이지 가로 overflow를 만들지 않는다. 1280/1440/1920px 및200%확대·키보드 접근 검수 예정.
- 기존 DTO 필드를 임의 rename/version-up하지 않는다. identity는 owner/exam/question/run/attempt/evaluation/lineage로 고정; 같은 화면의 비교 대상도 동일 기준 version인지 확인한다.
- H 표시 어댑터는 **명시적 math/prose segment**를 일관되게 처리해야 한다. 원문을 UPDATE하지 않고 기존 raw source/fallback을 보존한다. 길이6000/명령 제한과 HTML trust 금지를 유지한다. 새 DB 필드가 필요하다면 별도 검토하며 현재 존재한다고 가정하지 않는다.
- hint/read/reveal/history는 같은 서버 요청과 기존 idempotency 키 사용. 조회 중 재공개 이벤트를 생성하지 않는다. hint0/1/2와 학생 단계0/1/2 매핑을 명시하고, 클릭하지 않은 단계는 가져오지 않는다.
- 원본 로딩 실패·인증 만료·미확정 전사·평가 처리 중·판정 보류·해설 없음·무료 소진/만료를 독립 상태로 표시. raw AI 응답 fallback으로 안전 경계를 우회하지 않는다.
- 완료 검수: APP 제출→WEB 동일 원본/전사/결과/공개 상태/무료사용 조회, WEB 수정→APP 동일 History 조회. 서버 중복 차감·인문 회귀를 함께 확인해야 H 완료다.

## 9. P0와 검증 기록

1. OCR 의미 변화·불확실 원문을 학생 확인 없이 채점하지 않기; 전체 정답 전사 이중 검수 없이 정확도% 금지.
2. 공식 세부 기준·문항별 개념·구체 힌트 연결, UUID 대신 설명 가능한 과제 우선순위. 새 엔진 개발이 아니라 기존 결과의 안전한 검수/표현 연결이다.
3. 공식 완성 풀이 부재/AI 출처·구분자 없는 수식의 표현 문제 해결.
4. TEST 혼합형 실행503·잔액0·Native gate401 해결 후 실제1Credit/전체 완료 검증.
5. WEB 원본/확정 전사/힌트 이력/History 연결 및 APP↔WEB 실화면 교차검증.

검사: WEB60개 PASS(공개·수식·혼합 회차/결과·인문 경계), Native15개 PASS(320px 수식 추가 포함), disposable PG runtime131+coaching18 및 mixed 공개/힌트/History/인문 불변 PASS. 기존 PASS인 Provider를 반복하지 않았다. 최초 Native 실행의 없는 테스트 파일 지정·SQL 실행 Python의 psycopg 미설치는 올바른 기존 파일/LegendStudy venv로 정정했다. 행렬 자동 인식 실패는 숨기지 않고 5절 GAP로 기록한다. Analyze PASS, Wiki handoff 2,122링크/11,980bytes PASS, git diff --check PASS.

수정 범위: 이 Wiki·index/current-status/decisions/log, `tool/audit_task16g_saved_quality.py`, `test/math_student_text_test.dart`. LAB 소스/TEST 서버 배포는 변경하지 않았다. 현재 TEST Preview `https://legendstudy-task16b.pages.dev`, backend SHA `52f62a6`/배포 `9ffd0510` 유지. 운영 DB/Credit/Ledger/결제·APP1.0.1(41) 릴리스 브랜치 변경 없음.
