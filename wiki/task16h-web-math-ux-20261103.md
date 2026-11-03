# TASK16-H — WEB 수리논술 UX (2026-11-03)

## 범위 및 판정

Owner가 G `bdfea00` 기능 검증을 확인하고 WEB 구현을 승인했다. [G 품질·공통 계약](task16g-quality-closeout-task16h-preparation-20261103.md), [G 학습 루프](task16g-learning-loop-20261102.md), [F Native UX](task16f-native-math-ux-20261102.md), [E 공개 제어](task16e-recognition-disclosure-p0-20261102.md)를 재사용했다. WEB 구현·TEST 화면 검증 PASS, 신규 WEB 평가/무료 재첨삭 완료 E2E는 미실행이다. OCR·평가 품질·혼합형 E2E는 PARTIAL, 운영 HOLD.

Academic Purple(#6340C8/#5032A8/#F5F2FF/#F8F9FC/#1B2B49)을 유지했다. 새 평가 엔진/Backend/차감 정책/DB migration은 없다. 운영 DB·Auth·Credit·Ledger·결제·운영 WEB·APP 1.0.1(41) 릴리스와 Secret 설정을 변경하지 않았다.

## 구현

- `/math-review/?evaluation=<id>` 전용 비교 화면: 원본/결과/개념·힌트·해설. 컨테이너 폭 1120px 이상 3열, 740px 이상 2열, 그 미만 1열.
- 기존 owner 인증과 `math_input.read_input`으로 원본/전사 조회. 인증된 artifact endpoint에서 Blob을 읽고 화면 해제 시 URL 폐기. 원본 페이지 이동·확대·축소·90도 화면 회전/초기화, 원본 파일 불변.
- OCR 후보와 학생 확정 전사 구분, 수정 전 내용 보존, 불확실 표기. 실제 artifact/정규화 bbox가 있는 과제만 영역 강조하고 없으면 위치 미제공을 표시한다. 신뢰도를 원문 일치 보증으로 사용하지 않는다.
- 서버가 정한 최대 5개 개선 과제 순서를 유지한다. 종합 진단·잘한 점·기본 개념·단계 힌트·진행·기존 재작성기를 연결했다. 과제별 공개 상태는 기존 learning state의 error/core ID로 연결한다.
- `math-coaching-v1` read/hint/reveal/history 계약을 그대로 사용한다. 명시적 확인 전에는 전체 풀이 요청을 보내지 않는다. 힌트는 누적 표시하고 재접속 시 공개 상태를 복원한다. 이미 공개한 힌트 본문은 다시 보기로 조회한다.
- 전체 해설은 공식/내부 검증/AI 출처를 구분하며 공식 근거가 없으면 공식 예시답안으로 표시하지 않는다. 기존 Formula/MathText로 LaTeX, 행렬/연립/여러 줄 계산을 표시한다. 긴 수식은 독립 가로 스크롤, 렌더링 실패는 오류와 원문 보존.
- 기존 ExamRewrite와 서버 견적/재첨삭 정책을 재사용한다. WEB 자체 차감 로직은 없다. 혼합형 기존 coaching도 공통 공개 컴포넌트를 사용하나 원본 attempt 연결과 전체 E2E는 미완료다.

## 보존 검토 (7개)

1. 원본 이미지와 인식 후보를 변경하지 않는다.
2. 학생 확정 전사/수정 입력은 기존 attempt로 구분한다.
3. 평가·힌트·공개 시각은 기존 서버 History가 소유한다.
4. 동일 사용자·시험·문항·평가 ID를 플랫폼 공통으로 사용한다.
5. 학습 상태를 Credit/진학 성과로 재해석하지 않는다.
6. 원본 접근은 기존 인증을 따르며 자료/비밀을 Git에 넣지 않는다.
7. 파생 UI 상태와 실제 평가 사실을 구분한다. 새로운 수집·저장·운영 배포는 없다.

## 실제 TEST 검증

격리 Supabase `kpqbedylxlyntrrfybpn`, Pages `legendstudy-task16b`만 사용했다. 해당 프로젝트의 `task16b` 기본 배포 브랜치는 운영 서비스 브랜치가 아니다.

| 항목 | 결과와 범위 |
|---|---|
| 반응형 | Chromium 실제 배포: 1440×1050 3열, 1000×1100 2열, 390×844 1열. 페이지 가로 넘침/JS 오류 없음 |
| 원본/전사/History | APP에서 저장한 한양2024 자연 오전 Q1/Q2를 WEB에서 조회, 비공개 원본 로딩·확대/초기화 PASS |
| 힌트/공개 | 기존 Q2 무료 결과에서 실제 힌트 1·2 누적 표시, 취소 시 미공개, 명시 확인 후 full_solution 반환, 새로고침 후 공개/History 유지 PASS |
| 공개 전 응답 | 실제 read/hint에 full_solution 없음, reveal 후에만 반환. 기존 서버 계약 회귀도 PASS |
| WEB→APP | 기존 WEB 작성기에서 Q1/Q2 수정 텍스트 attempt 2개 저장. Simulator Native gateway가 같은 ID/텍스트를 실제 조회 PASS. WEB 공개 해설/힌트 1·2 이력도 Native에서 조회 PASS |
| 다음 회차 | 서버 견적 이용권 1개 확인 후 제출 전 취소. 새 평가·이용권 차감 없음 |
| Provider | 이번 H 신규 호출 0. 기존 G 실제 최초/무료 결과 재사용 |
| 영역 연결 | 실제 선택 자료에 대응 과제 bbox가 없어 live 강조 성공은 미검증. 유효/없는/잘못된 좌표 처리는 컴포넌트 테스트 PASS |

대표 평가: Q1 `8036dd10-4938-47e6-a1b8-db53f62abd1c`, Q2 무료 `d4acd0aa-b434-4015-9458-eeceb7335563`.
WEB 입력(미평가): Q1 `e4f52881-fcb5-4ef9-87c2-c4128484de6d`, Q2 `e1df0333-8e11-4243-b723-bef17370de67`. 신규 완료 평가나 무료 재첨삭 결과가 아니다. 미제출 브라우저 초안은 기존 로컬 저장이며 플랫폼 자동 동기화를 주장하지 않는다.

## 코드/회귀 검증

- LAB 전체: 1578 PASS / 기존 4 skip (222 파일 PASS/3 skip). 인문논술 포함 기존 회귀 유지.
- 최종 영향 범위 18 PASS, TypeScript/ESLint/정적 TEST build PASS.
- Native 실제 Simulator 통합 테스트 PASS: 기존 Q1/Q2 결과·개념·힌트·History 및 위 WEB 입력/공개 이력. Flutter analyze PASS.
- 수식 분수·지수/첨자·적분·극한·행렬·연립·여러 줄·긴 식/실패 원문 보존은 fixture 컴포넌트 검증이다. 실제 Q1/Q2에 없는 모든 수식 형태를 실제 학생 E2E로 검증했다고 보지 않는다.

## 변경 파일 및 배포

LAB 저장소 `/Users/woojinchang/development/legendstudy-service-lab-20261022`:

- `src/components/math-learning/server-coaching.tsx`, `server-coaching.test.tsx`
- `src/components/math-learning/study-evidence.tsx`, `study-evidence.test.tsx`
- `src/components/math-learning/study-math.tsx`, `math-study.css`, `math-review-page.tsx`
- `src/app/math-review/page.tsx`
- `src/components/my/essay-dashboard.tsx`

APP: `integration_test/task16g_saved_history_test.dart`의 선택적 WEB 입력/공개 이력 검증 및 Wiki. Native 제품 UI/릴리스 설정 변경 없음.

WEB 코드 `63f73b7` + 긴 전사 패널 보완 **`6f5d726`**, TEST 배포 **`4aaecbbc`**.
[TEST Preview](https://legendstudy-task16b.pages.dev/math-review/?evaluation=8036dd10-4938-47e6-a1b8-db53f62abd1c) / [고정 배포](https://4aaecbbc.legendstudy-task16b.pages.dev).
기존 비공개 접속 gate와 TEST 로그인을 유지했다. 코드/비밀번호 재생성 없음.

비공개 증거 폴더: `/Users/woojinchang/.codex/legendstudy-task16h-test/`.
`final-pc.png`, `final-tablet.png`, `final-mobile.png`, `final-solution.png`, `rewrite.png`, `web-input-prepared.png`, `native-cross-captures/`.
실행 요약: `browser-result.json`, `browser-final-result.json`, `web-input-result.json`.
원본/사진/인증 정보는 Git에 추가하지 않았다.

## 남은 P0 / 운영 차단

1. 기존 Q1 손글씨 핵심 수식 오류, Q1 판정 보류, Q2 첨삭/대안 풀이·개념·힌트 품질은 G 품질 보고의 PARTIAL을 유지한다. UX 완료가 품질 승인이 아니다.
2. 혼합형 Essay+Math 전체 제출·통합 완료·시험 단위 차감 실제 E2E는 기존 차단을 해소하지 않았다. 혼합형 원본 attempt 연결도 추가 검증 필요.
3. 신규 WEB 수정 입력→실제 평가→무료 재첨삭 완료는 이번에 실행하지 않았다. 기존 G 성공과 구분한다. 기존 TEST 잔액/혼합형 환경 제약은 G 보고를 따른다.
4. 실제 과제 bbox 연결 성공, 더 많은 실제 긴 수식/다중 페이지 검수 필요. 문장 안에 delimiter 없이 섞인 TeX는 원문 표시가 남을 수 있다.
5. 개념/공식 예시답안의 대학별 근거 충실도는 평가 데이터 품질 과제다. 없는 공식 풀이를 UI가 만들지 않는다.
6. Owner Preview 검수 및 위 품질·혼합형 검증 전 운영 활성화 금지. TASK16-H WEB 검수는 가능하다.
