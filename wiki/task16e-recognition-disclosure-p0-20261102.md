# TASK16-E — 손글씨 인식·정답 공개 P0 수정

2026-11-02. 상태: 구현 및 저장 결과 회귀 검증 완료, 격리 Preview 검수 대상. 운영 활성화 금지. 전체 학습 E2E 완료를 의미하지 않는다.

## 근거와 범위

[실제 Q1·Q2 검증](task16c-hanyang2024-handwriting-validation-20261102.md), [기존 TASK16-C](task16c-math-recognition-scaffolding-20261102.md), [TASK16 감사](task16-commerce-social-predevelopment-audit-20261102.md), [격리 TEST](task16b-commerce-social-integration-20261102.md)를 재사용했다. 새 엔진·Provider 모델·결제·Credit 정책 변경 없음. 이번 Provider 호출 0회, 신규 토큰·Provider 비용 0.

Owner 2026-11-02 지시: 신뢰도와 무관한 기호 원문 확인, UNCERTAIN 임의 보충 금지, 학생 확인 전 평가 금지, 정답 포함 상세 출력은 명시적 요청 뒤 공개. 기존 Math Session/확인 RPC/History를 재사용한다.

## 구현

- WEB `recognition-safety.ts`: 수학 기호/숫자가 포함된 영역을 원본 확인 대상으로 분류. UNCERTAIN·판독 불가 표식을 유지하며 확인 버튼과 Worker 진입을 차단한다. 오류를 자동 정답으로 교정하지 않는다.
- 추출 finalize 전 critical 기호는 `uncertain=true`로 기존 RPC에 전달. 기존 후보의 raw_text·normalized_math·confidence는 보존한다. 기존 DB의 후보→CONFIRMED successor 구조를 유지한다.
- WEB/Native 원본 이미지와 영역 강조를 전사본 옆에 표시. 범위를 벗어난 좌표는 추측해 보정하지 않고 전체 원본 대조를 안내한다. PDF는 해당 페이지 링크. WEB 페이지 번호의 1-based/0-based 변환 수정.
- 학생 수정은 기존 confirm_extraction으로 별도 확인본에 저장. 편집 시 이전 UI 확인을 해제한다. 평가 전 fresh read 및 Worker authoritative claim 검사. 본문에 불명확 표식이 남으면 Provider 호출하지 않는다.
- WEB `AnswerDisclosure`, Native `MathAnswerDisclosure`: 생성된 요약·단계 설명·오류 설명·힌트·평가 기준·강점/약점·재작성·비교·성장 피드백·음성/내보내기 진입은 기본 닫힘. 상세 평가 공개 버튼을 명시적으로 눌러야 렌더링한다. CSS 숨김만 사용하지 않는다.
- 공개 전 개념/해결 방향은 고정된 안전 안내. 단계 위치는 숫자 position으로 연결한다. AI 자유 문장을 정규식으로 일부 지워 안전하다고 판정하지 않는다. 기존 참고 풀이 공개 RPC/학습 기록은 유지한다.
- 인문 report에는 공개 gate를 적용하지 않는다. 혼합 시험의 Math 문항은 domain metadata로 gate를 적용한다.

## Q1·Q2와 기존 검증 재사용

| 사례 | 이번 결과 |
|---|---|
| Q1 영역13: confidence 0.90, uncertain=false인데 지수·부호 오류 | 기호 검출로 학생 확인 대상. 원본과 일치한다고 표시하지 않음 |
| Q1 영역17 범위 밖 bbox | 유효하지 않다고 검출, 전체 원본 대조. 좌표 추정 금지 |
| 미확인 Q1 / UNCERTAIN 전사본 | Provider 이전 차단, spy 호출 0 |
| 학생 수정 전사본 | 원본 후보 보존, 확인본 검사 통과 |
| Q2 기존 18영역 | 원문 값 유지·좌표 정상 유지. 기존 1회 영역 확인 흐름 재사용, 추가 반복 확인 단계 없음 |
| Q2 경계 오류의 정답 선공개 | 저장된 단계/CORE/힌트 결과 재생. 상세 공개 전 생성 본문 DOM 미출력 |
| 정답·계산 오류·개념 오류·대안 풀이 | TASK16-B/C 실제 API 결과 보존·재사용. Provider 재평가하지 않음. 기존 엔진 회귀 테스트로 영향 확인 |

검증: WEB 전체 1,557 PASS/4 기존 skip, Native 관련 29 PASS, TypeScript PASS. 최종 빌드·Preview·검증 SHA는 아래 배포 기록 참조.

## TEST 확인과 보존 검토

Supabase `kpqbedylxlyntrrfybpn`에서 함수 정의만 읽었다. math_confirm_extraction의 UNCERTAINTY_NOT_CONFIRMED 및 CONFIRMED successor, math_request_evaluation의 CONFIRMED 선택을 확인했다. TEST `math_session_submit`은 여전히 없음. DB 쓰기·Provider 호출·운영 Secret 변경 없음.

7가지 보존 검토: (1) 원본/확인 시점은 기존 run timestamp 유지, (2) 후보 원문 재현, (3) 수정은 기존 successor이며 원본 UPDATE 없음, (4) 기존 canonical student/owner 검사 유지, (5) 재생 fixture를 실제 학습/성과로 기록하지 않음, (6) 원본 사진은 로컬 미리보기만·Git 제외·별도 수집 없음, (7) confidence/자동분류를 정답이나 학습 성과 사실로 취급하지 않음.

## Preview와 검수 순서

전용 TEST Pages `legendstudy-task16b`의 `/internal/math-recognition-preview/`.
기존 Owner 접근 코드를 사용한다. Q1/Q2 선택 → 해당 원본 사진 또는 PDF 로컬 선택 → 기호·원본 영역 대조 → 수정/확인 → 전사본 확정 검사. 그 아래 Q2 저장 결과에서 개념 힌트·해결 방향·상세 평가 공개를 검사한다. 이 화면은 저장 결과 재생이며 새 평가·DB History 저장이 아니다.

## 남은 차단 요소

1. 기존 read_result/History RPC는 원시 평가를 반환한다. 이번 공개 제어는 학생 UI 범위이며 네트워크 응답 자체의 정답 비공개까지 보장하지 않는다. 서버 출력 projection 및 명시적 공개 이벤트 계약 보완 전 운영 승인 불가.
2. 상세 평가 공개 버튼 상태는 화면 메모리다. 기존 참고 풀이 공개 RPC와 달리 상세 평가 공개 자체의 durable History 이벤트는 신규 저장하지 않았다.
3. 고정 개념 힌트는 안전 우선으로 일반적이다. 대학·오류 유형별 검수된 힌트와 안전한 본문 projection은 후속 품질 과제다.
4. 손글씨 OCR 정확도가 개선되었다고 주장하지 않는다. 원본 대조/학생 확인은 오판 예방 장치이며 Q1 핵심 오인식 자체를 자동 복구하지 않는다. 불명확 표식이 없는 잘못된 전사까지 자동 판별하는 검증기는 아니다.
5. 별도 TEST의 회차 RPC 부재 때문에 실제 제출→재첨삭→History 연속 E2E는 이번에 수행하지 않았다. 기존 모의 RPC 회귀와 실제 Provider 결과 재생을 구분한다.
6. Native는 코드·widget 검증이며 APP 릴리스·기기 배포 없음. 원본 영역 대응은 실제 Owner 사진 선택으로 추가 확인 필요.

운영 DB·Credit·결제·APP 릴리스 브랜치 변경 없음. Owner 검수 전 운영 활성화 금지.

## 최종 배포·검증 기록

- WEB 구현 SHA: `847a14166c792d81d87cabb9891f88d518469d25`.
- Native 구현 SHA: `68d8bbb` (feature branch만). Wiki restore budget 보존: `914aa9d`.
- 고정 Preview: https://2356c0f7.legendstudy-task16b.pages.dev/internal/math-recognition-preview/
- 기본 TEST Preview: https://legendstudy-task16b.pages.dev/internal/math-recognition-preview/
- 배포 메타데이터의 commit_hash 일치. 인증 후 두 URL HTTP200/검수 제목 확인, 비인증 기본 URL401, no-store/noindex 확인.
- Provider 호출 스위치 false, Essay 실행 스위치 false, TEST Supabase ref 일치. 실행 활성화·Secret 변경 없음.
- WEB 전체 1,557 PASS/4 skip 후 마지막 확인 버튼 변경 관련 5 PASS. TypeScript·정적 빌드 PASS. Native 29 PASS 및 변경5파일 analyze 무경고. Wiki 링크/Task Routing/12KB budget 검사 PASS.
- 브라우저 UI 제어는 `browser.user is unavailable`로 실행 불가. 실제 배포는 HTTP/Cloudflare 메타데이터 확인, 동작은 DOM/widget 회귀 검증이다. Owner 실브라우저 검수는 남아 있다.

주요 수정 파일(WEB 저장소): `functions/api/math/extract.ts`, `src/lib/math-eval/runtime/physical-contract.ts`, `src/lib/math-input/recognition-safety.ts`, `src/lib/math-input/runtime/mapping.ts`, `src/components/math-input/math-input-flow.tsx`, `src/components/math-input/source-region.tsx`, `src/components/math-learning/answer-disclosure.tsx`, `src/components/math-learning/learning-guidance.tsx`, `src/components/math-release/student-route.tsx`, `src/components/my/evaluation-report.tsx`, `src/components/my/essay-history-growth.tsx`, `src/app/internal/math-recognition-preview/` 및 회귀 fixture/tests.

주요 수정 파일(APP 저장소): `lib/features/essay/math_answer_disclosure.dart`, `evaluation_report_view.dart`, `math_learning_panel.dart`, `math_workspace_page.dart`, `shared_history_page.dart`, `test/evaluation_report_test.dart` 및 Wiki. 기존 미커밋 파일은 별도 보존했다. 원본 이미지·Secret·개인 인증 파일은 Git에 추가하지 않았다.
