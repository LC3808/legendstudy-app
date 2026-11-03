# 후보 B 실기기·WEB 검수

기준일: 2026-11-03 KST. Owner의 “A 검수 보고서 작성, B 실기기 및 WEB 검수 시작” 요청에 따른 기록.

후보 A의 확정된 검수는 [ChatGPT 전달용 A 보고서](app-candidate-a-owner-qa-report-20261103.md)로 분리한다. 후보 B는 **TEST 검수 진행 중 / 전체 출시 HOLD**다. 이번 자동 검사·설치·저장 결과 조회를 실제 신규 사진 전체 E2E PASS로 확대하지 않는다.

## 검수 빌드와 격리

- 브랜치 `codex/app-review-candidate-b-20261103`, 초기 TEST49 실행 소스 기준 `82373a1`. 초기 검수 단계는 제품 코드 변경이 없었으며 TEST50/51의 Owner UI 후속 수정은 아래에 별도로 기록한다.
- 최신 통합 소스 Flutter 전체 **1,402 PASS / 7 SKIP**, Analyze **No issues found**. 이전 B43의 1,383 PASS와 최신 온보딩 통합 후 결과를 구분한다.
- iPhone 12 Pro Max에 **LS Math TEST 1.0.1(49)** signed Release 설치·실행 성공. 실제 설치 버전 49, Release AOT, 서명 확인.
- TEST bundle `com.legendstudy.app.task16f`. 기존 정식 앱 `com.legendstudy.app` 후보 A48 및 APP41 기준선은 보존한다.
- 런타임은 기존 격리 TEST Supabase와 `legendstudy-task16b.pages.dev`. 바이너리의 TEST 연결 및 publishable 설정 포함 확인. Provider Secret·계정 비밀번호를 빌드에 추가하지 않았다.
- TEST 전용 Info.plist/xcconfig/entitlements는 private 빌드 디렉터리에만 생성. 저장소의 정식 앱 식별자·Xcode 설정을 수정하지 않았다. TEST49는 기기 검수용이며 Store 제출 IPA가 아니다.
- 산출물 및 검사 로그: 로컬 private 백업 `app-review-integration-20261103/candidate-b/test49/`. Browser 화면 증거는 `.codex/legendstudy-candidate-b-qa-20261103/`에 보존하며 Git에 원본 답안 이미지를 추가하지 않는다.

## 이번 WEB 실제 화면 확인

기존 비공개 접속 코드와 TEST 계정으로 로그인했다. 인증 제한 해제·코드 발급·비밀번호 변경은 하지 않았다. Provider 재호출·새 평가·이용권 차감 없이 기존 결과를 재사용했다.

| 확인 항목 | 결과와 범위 |
|---|---|
| TEST 접근 | PASS — 비공개 gate 및 기존 TEST 계정 로그인 후 결과 조회 |
| 자연계 Q1 | PASS(조회) — 원본/영역별 인식·확정 전사, 학생 수정 흔적, 기존 종합 진단 표시. OCR 정확도 전체 PASS 의미 아님 |
| 자연계 Q2 | PASS(조회) — 개선 과제 1개, 연결 원본 영역, 기본 개념, 이미 공개한 힌트 재조회, 공개된 풀이 단계 및 History |
| 자연계 회차 | PASS(조회) — 기존 무료 재첨삭 회차에서 Q1·Q2 결과 확인. `확정 판정 불가` 안내와 우선 과제 0개를 정답 판정으로 바꾸지 않음 |
| 자연계 재작성 진입 | PASS(진입만) — 기존 회차에서 재작성 화면 진입, Q1·Q2 이전 답안 불러오기 및 수학 입력 준비 버튼 확인. 새 제출·다음 이용권 차감은 미실행 |
| 상경 최초 결과 | PASS(조회) — 2026 한양 상경, Q1 Essay + Q2 Math, 2문항 완료, 문항별 결과 통합 표시 |
| 상경 무료 재첨삭 | PASS(조회) — 기존 재첨삭의 두 문항 결과 및 완료 표시. 무료 재첨삭 현재 사용 불가/추가 첨삭 1 Credit 안내. 이번에 무료 요청을 새로 수행한 것은 아님 |
| 해설 공개 제어 | 기존 공개 상태 조회 PASS. 이번 세션에서 미공개 결과의 서버 응답 및 새 공개 기록은 재검증하지 않음 |
| APP↔WEB | 기존 공유 데이터 계약 재사용. 같은 Q2 evaluation 경로를 B49에 요청했으며 실제 iPhone 화면은 아래 Owner 표시 확인 참조 |

상경 재첨삭으로 전환한 직후의 임시 `전체 문항 여부 미확인`은 자료 로딩 완료 후 `문제 1/2 · 전체 문항 첨삭 완료`로 정상 변경됐다. 지속적인 데이터 오류로 기록하지 않는다.

## 화면에서 확인된 품질·사용성 문제

1. **수식 표현 PARTIAL:** Q2 기존 공개 풀이 단계 7의 `b-a=10/sqrt(n), d-c=6/sqrt(n)`이 일반 텍스트로 남는다. 다른 LaTeX 구간과 함께 보이며 전체 해설 수식 표시 PASS가 아니다.
2. **힌트 품질 PARTIAL:** Q2의 `결론과 경계 조건` 과제에 `동치 변형과 적용 조건`, `a=b ⇒ a+c=b+c`와 일반적인 조건 대조 안내가 연결된다. 문제별 수정 방향의 구체성이 부족하다. 과거 전사 누락에서 유래한 과제를 실제 우수 답안의 수학 오류로 간주하지 않는다.
3. **History 메타데이터 PARTIAL:** 자연계 회차 목록은 `대학 정보 미제공/수리논술 회차`로 나타나고 문항 상세에는 한양2024자연오전 정보가 표시된다. 목록 식별 개선 필요.
4. **빈 재작성 안내 UX:** 최초 빈 답안 상태에서 `첨삭 서비스 제공 예정`이 나온다. 기존 두 답안을 불러오면 수학 입력 준비로 바뀌므로 서버 활성화 실패로 판정하지 않는다. `ScopedExamSubmit`의 빈 included 분기와 실제 화면을 대조했다. 텍스트만 불러온 경우에도 준비 버튼명이 `사진에서 답안 추출하기`로 표시되어 입력 유형 안내가 부정확하다.
5. **단독 학습 화면 재작성:** 개별 evaluation의 독립 화면에서는 이용 조건 확인 버튼이 비활성이다. 회차 History에서는 재작성 화면 진입이 가능하다. 단독 화면에서 회차 경로를 찾기 쉬운지 Owner 검수 필요.

위 문제는 검수 발견 사항이다. 운영 플래그 변경·평가 엔진 수정·임의 데이터 정정으로 우회하지 않았다.

## 실기기 검수 순서와 미완료

1. B49에서 기존 Q2 결과 → 원본/전사 → 개선 과제 → 개념/힌트 → 공개된 풀이 → History를 우선 확인하도록 Owner에게 요청했다. 후속 Owner 응답은 아래에 기록한다.
2. 읽기 흐름 확인 후 기존 카메라 답안의 미확정 오독을 원본과 대조하고 수정·확정한다. 불명확한 수식을 에이전트가 임의 확정하지 않는다.
3. 자연계 실제 기기 확인→평가→무료 재첨삭→History는 이번 검수에서 아직 미완료다. 과거 카메라·크롭·OCR 복구·수정·키보드 닫기 Owner PASS를 반복하지 않는다.
4. **Native 상경 신규 사진 제출은 기존 BLOCKED 항목**이다. 저장 결과 조회나 WEB 혼합 E2E를 Native 전체 제출 PASS로 대체하지 않는다.
5. 운영 RPC·Provider·Registry 공개 범위 및 출시 승인은 [통합 보고서](app-release-integration-20261103.md), [TASK16-K](task16k-beta-activation-20261103.md)의 HOLD와 격차를 유지한다.

## Owner WEB 검수 경로

현재 Chrome 검수 탭은 기존 TEST 계정으로 열어 두었다. 기존 접속 코드 원문은 문서에 적지 않는다.

- [자연계 Q1 원본·확정 전사](https://legendstudy-task16b.pages.dev/math-review/?evaluation=480055c9-1966-4067-9e78-f6792cccb360)
- [자연계 Q2 개선 과제·힌트·공개 풀이](https://legendstudy-task16b.pages.dev/math-review/?evaluation=24fee771-ea23-4cb3-93cc-62f4aeada9a6)
- [자연계 무료 재첨삭 회차](https://legendstudy-task16b.pages.dev/my/essays/result/?source=math&id=20ff28c3-3a18-4bc0-a5a1-faf6ffab5513)
- [상경 최초 통합 결과](https://legendstudy-task16b.pages.dev/my/essays/result/?source=exam&id=7fd28980-cf88-4382-baf9-4434ca7556b1)
- [상경 무료 재첨삭 통합 결과](https://legendstudy-task16b.pages.dev/my/essays/result/?source=exam&id=dd5b335f-4a08-4025-993e-c4482b7bdbf2)

운영 DB/Auth/Credit/Ledger/결제/WEB/APP41 및 Store 제출은 변경하지 않았다. WEB에서 이전 답안 불러오기로 생성한 재작성 초안은 현재 브라우저 로컬 저장 범위이며 새 서버 평가를 요청하지 않았다.


## B49 Owner 화면 확인·가독성 보완 — 2026-11-03

Owner는 요청한 화면에 대해 “화면은 모두 구현 됨”이라고 확인하면서 가독성, 버튼·줄 간격, 설명 강조, 소제목과 본문 및 항목 구분 보완을 요구했다. **저장 결과 화면 표시 확인**으로 기록한다. 실제 신규 사진→평가→재첨삭 전체 E2E 또는 수학적 품질 승인으로 확대하지 않는다.

기존 [Academic Purple 및 F/G 구조 유지 결정](decisions.md#2026-11-02--task16-g-디자인-pass--학습-루프-통합)을 계승한 Flutter 표현 보완이다. WEB UI, 평가 문구 생성, 서버 계약, 이용권·공개 정책은 변경하지 않는다.

- 본문 16 / 줄높이 1.65, 보조문구 13 / 1.5, 제목·소제목 크기·굵기 구분. 기존 글꼴과 색상 유지.
- 카드 외곽선·단락 간격, 수식의 옅은 보라색 영역, 개념의 핵심 공식/설명/조건/주의/관계 레이블을 분리했다.
- 과제 상세의 점검 내용·서버가 제공한 수정 방향을 구분하고 힌트 단계 제목을 강조했다. 설명을 새로 생성하거나 정답을 추가하지 않는다.
- 관련 개념/풀이 수정 버튼 간격 12, Filled·Outlined 버튼 최소 높이 52 및 여러 줄 레이블 여백. 결과 탭 상단 시험명 영역은 글자 확대에 대응한다.
- 전체 풀이의 수식·단계 설명 및 History의 시각/상태/힌트/해설 공개/이용권/학습 안내를 구분했다.
- 변경 코드: `academic_purple.dart`, `math_coaching_screen.dart`. 기존 인문 전역 테마는 수정하지 않았다.
- 기존 Widget 검사를 1배/2배 글자 과제·수정 버튼 도달, 해설·History로 확장. History 레이블 분리/스크롤을 반영해 기존 두 회귀 테스트 탐색을 변경하며 공개 갱신·이용 불가 차단 assertions는 유지한다.

### 보존 검토 7문항

1. 새 학습 사실을 생성하지 않으며 기존 시각/공개 기록을 그대로 표시한다.
2. 기존 DTO·원문·원본 자료는 변경하지 않아 재현 근거가 유지된다.
3. DB UPDATE·정정·삭제·migration이 없다.
4. 기존 사용자·evaluation·attempt identity와 접근 경계를 유지한다.
5. Learning 결과 표시만 변경하며 Decision/Outcome을 만들지 않는다.
6. 새 개인정보 수집·전송·보관·권한 부여가 없다. 화면 검수 예제는 실제 평가 품질 근거가 아니다.
7. 새 점수·힌트·설명·derived metric을 생성하거나 저장하지 않고 기존 서버 값만 표현한다.

### TEST50 빌드·설치 결과

- 최종 전체 Flutter **1,404 PASS / 7 SKIP**. 첫 실행의 두 실패는 분리된 History 레이블과 스크롤 밖 버튼을 찾던 테스트였으며, 새 배치에 맞춰 동일 동작 assertions를 유지한 뒤 전체 재실행 PASS.
- 집중 **15 PASS**, 그중 화면/인식·공개 방어 **11 PASS**. 기본/2배 글자에서 힌트와 수정 버튼 도달, 전체 풀이와 History 표시 확인. 렌더 캡처는 Widget 예제이며 실제 Provider 품질 검증이 아니다.
- Flutter Analyze PASS; Wiki 링크/라우팅/current-status 예산 및 diff 검사 PASS.
- **LS Math TEST 1.0.1(50) signed Release** 빌드·서명·AOT·TEST 서버 설정·새 UI 코드 포함 확인. 한글 AOT 문자열은 UTF-16LE로 확인.
- iPhone 12 Pro Max에 업데이트 설치·실행 성공, 기기 설치 목록 50 확인. 기존 `레전드스터디+` A48도 동일 목록에서 보존 확인.
- 기존 Q2 evaluation 딥링크로 실행을 요청하고 Owner에게 간격·구분·잘림 재검수를 요청했다. **후속 Owner: 제출 화면 버튼을 제외한 가독성 수정 수용**, 신규 평가·재첨삭 실기기 전체 E2E는 별도 미완료다.
- 산출물/로그: private `app-review-integration-20261103/candidate-b/test50/`. 화면 예제: `.codex/legendstudy-candidate-b-qa-20261103/b50-after/` (`concepts-1.0.png`, `task-actions-1.0.png`, `solution-2.0.png` 등).
- Provider 추가 호출 0, DB/Auth/Credit/Ledger/결제/WEB/APP41/A48 변경 및 Store 제출 없음. Android 신규 빌드는 이번 iPhone 가독성 검수 범위에 포함하지 않았다.


## B50 가독성 수용·제출 버튼 정리 — 2026-11-03

Owner는 “답안 제출 화면의 버튼 간격이 없어서 붙어 있는 것 말곤 적절히 수정됨”이라고 확인했다. 결과/과제/개념/힌트/풀이/기록의 가독성 보완은 해당 확인 범위에서 수용으로 기록하고, 제출 화면 버튼 간격·모호한 용어는 별도 후속으로 수정한다. 전체 E2E·OCR 품질·운영 활성화 승인이 아니다.

기존 버튼과 실제 함수의 연결을 확인한 뒤 표현만 바꿨다.

| 표시 문구 | 실제 역할 | 이번 변경 |
|---|---|---|
| 첨삭 상태 새로고침 | 기존 evaluation의 `read_learning_state` 조회, 잔액·History 표시 갱신. 새 첨삭 요청/차감 없음 | `결과·크레딧 다시 확인` 대체. 새로고침 아이콘·설명 툴팁 |
| 첨삭 결과 보기 | 기존 `MathCoachingPage`로 이동하여 진단·과제·힌트·해설 조회 | `수리논술 첨삭 결과 보기`를 간결하게 정리. 결과 아이콘 |
| 접수한 첨삭 다시 처리 | REQUESTED 상태에서 기존 evaluation ID로 처리를 재개. 단순 조회와 구별 | `같은 첨삭 처리 다시 요청` 대체. 기존 조건·handler 유지 |

기존 새로고침 함수는 잔액을 **조회**하는 `credit_summary`를 다시 불러오므로 버튼에 ‘크레딧’이 들어가 있었으나, 학생이 해야 할 행동은 첨삭 상태 조회다. 잔액 확인·차감 동작으로 오인하지 않도록 주된 역할을 이름으로 표시했다. APP 전체 Credit 명칭이나 금융 계약을 변경하지 않았다.

- `lib/features/essay/math_workspace_page.dart`만 제품 코드 변경. 조회·재처리·결과 이동·History 버튼 사이 12px, 입력 영역과 조회 영역 사이 16px 간격.
- 기존 버튼의 실행 함수와 활성화 조건을 유지했다. 평가·RPC·잔액/원장·Provider 코드 변경 없음.
- 관련 기존 검사 **16 PASS**, Analyze PASS. B50 전체1,404PASS/7SKIP는 이전 통합 기준 증거로 유지하며 이번 작은 표현 수정 후 전체 재실행으로 보고하지 않는다.
- [보존 검토 7문항](#보존-검토-7문항)을 그대로 적용한다. 저장·정정·새 데이터 수집은 없다.
- TEST51 signed Release 빌드·서명·AOT·TEST 설정·새 버튼 문구 포함 확인 PASS. iPhone12ProMax 업데이트 설치·실행 및 설치 버전51 확인, 기존 A48 보존. Q2 기존 결과 경로로 실행을 요청했고 Owner 버튼 간격·새로고침/결과 이동 확인은 대기다. 운영/WEB/APP41/A48/Store 변경 없음.


TEST51 산출물·검사·설치 로그는 private `app-review-integration-20261103/candidate-b/test51/`에 보존했다. Wiki handoff/diff 검사 PASS. 이번 후속의 Provider 호출·새 평가·차감은 0이며 기존 TEST 기록을 재사용한다.

## B51 LAB 대학 진입 실패·TEST 연결 수정 — 2026-11-03

Owner가 결과 화면을 벗어나 일반 논술 LAB으로 돌아왔을 때 한양대 카드가 `서비스 확인 중`으로 잠기는 문제를 보고했다. 제출 버튼 간격·역할의 Owner 확인은 아직 대기이며, 딥링크 결과 조회 성공을 일반 진입 성공으로 대신하지 않는다.

### 확인된 원인과 수정

- 실제 TEST 계정 JWT로 브라우저 cookie 없이 조회: `public-service-status`와 `service-status`는 **HTTP401 / 접속 코드 HTML**, `availability`는 **HTTP200 / 정상 Math JSON**이었다. 공개 범위·평가 Provider 실패가 아니라 Native 조회 경로가 TEST gate의 기존 API 허용 경로에서 빠져 있었다.
- WEB `cloudflare/test-preview-access.ts`: 정확한 `legendstudy-task16b.pages.dev` 호스트의 두 GET 경로만 기존 Bearer 인증 handler로 전달한다. 실제 JWT와 시험 공개 근거 검증은 기존 handler가 수행한다. 접속 코드/Secret/환경 설정, 일반 브라우저 gate 및 운영 경로는 변경하지 않았다.
- APP `math_gateway.dart`: 공개 대학·시험 수의 두 FutureProvider가 실패 후 자동 재시도하며 로딩을 유지하지 않도록 했다. 기존 실패 안내와 사용자의 `다시 시도`/상단 새로고침을 재사용한다. 서버에서 승인한 ID만 진입을 허용하며 하드코딩 활성화는 없다.
- 이 변경도 위 [보존 검토 7문항](#보존-검토-7문항)을 따른다. 기존 세션·원본/전사·평가·History·공개 기록/시각·원장은 변경하지 않는다. 신규 저장·DB UPDATE·수집·과금 로직이 없다.

### 검증과 TEST 배포

- Native **29 PASS**: 실제 provider chain에서 오류 즉시 표시, 자동 반복 요청 없음, 명시적 재시도 후 카드 활성화; 기존 gateway/카탈로그/인문 준비중·선택 동작 포함. Analyze PASS.
- WEB **31 PASS**: gate 경로·호스트·메서드·토큰 형태 제한, handler 인증 거절 보존, 공개 시험/문항/근거 검증, 기존 서비스 상태 계약. TypeScript 및 격리 TEST static build PASS.
- WEB 소스 **`8939034`**, TEST Pages **`626fa92d-84f9-41d4-8f2b-5c15cc0b2308`**. 기존 `f9d0fdc7`에서 TEST만 갱신. 배포 전후 `deployment_configs` 동일성 확인, Secret/설정 재저장 없음.
- 실제 API: Native 방식의 두 상태 조회 **200 / checked=true**, 한양대 기존 상경 시험·문항 ID 반환. Math availability도 **200**, 기존 자연2024오전 Q1/Q2 및 상경 Q2 allowlist 유지. 익명 상태 조회·사이트 접근은 **401**, 잘못된 JWT는 **checked=false**로 거절된다.
- 시험 수 응답은 기존 전체 시험 공개 정책의 범위다. 이 변경에서 자연계 시험을 임의로 공개 목록에 추가하지 않았다. 자연계 Math 평가 경로는 기존 별도 allowlist를 유지한다.
- Provider 새 호출·평가 요청·이용권 차감 0. 운영 DB/Auth/Credit/Ledger/결제/WEB/APP41/A48/스토어 변경 없음.
- 실제 API 증거: private `.codex/legendstudy-candidate-b-qa-20261103/b52-live-discovery.json`.
- TEST52 signed Release 빌드·서명·Release AOT·TEST Supabase/Pages 설정 확인 PASS. iPhone12ProMax의 별도 `LS Math TEST` 업데이트 설치·실행 및 버전52 확인, 기존 정식 A48 보존. 기존 결과 딥링크 대신 `/lab/essay` 일반 대학 목록을 열도록 요청했다. 후속 Owner 응답으로 일반 LAB → 한양대 시험 선택 → 기존 결과 조회 PASS 확인(아래).
- 빌드/검사/설치/launch 로그와 바이너리 확인은 private `app-review-integration-20261103/candidate-b/test52/`에 보존. 전체 신규 사진 E2E 및 기존 B 품질·운영 HOLD는 그대로다.

### B52 일반 LAB 진입·기존 결과 조회 Owner PASS

Owner가 iPhone12ProMax `LS Math TEST` 1.0.1(52)에서 “한양대 진입·기존 결과 조회 정상”이라고 확인했다. 일반 논술 LAB의 한양대 카드 → 시험 선택 → 나의 첨삭 기록의 기존 Q2 결과 조회를 **실기기 PASS**로 기록한다. B51의 대학 진입 차단은 이 검수 범위에서 해소됐다.

다음은 미확인 제출 화면의 `첨삭 상태 새로고침`/`첨삭 결과 보기` 간격과 역할, 기존 결과 재조회 확인이다. 새 평가·무료 재첨삭·OCR 품질까지 PASS로 확대하지 않는다. 이번 응답 반영은 Wiki 기록이며 재빌드·서버/DB 변경은 없다.
