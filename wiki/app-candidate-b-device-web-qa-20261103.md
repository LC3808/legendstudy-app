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

### B52 제출 버튼 Owner PASS·문제 본문 표시 GAP

후속 Owner가 두 버튼 간격·역할과 새로고침→기존 결과 열기에 “정상”이라고 확인했다. 이 확인 범위는 실기기 PASS이며, 앞서 대기였던 제출 버튼 검수는 종료한다.

동시에 “답안 입력 화면에서(첨삭 내용 확인) 왜 문제가 텍스트로 나열되어 있는가”를 질문했다. 방금 검수용으로 연 `MathWorkspacePage`의 실제 코드는 `math_catalog`의 `problem_statement`와 `statement`를 연속 `MathText`로 출력한다. 명시적인 LaTeX 구분자가 있는 수식만 렌더링하며, 문제 원본의 PDF 배치·표·그림을 재현하는 화면이 아니다. 기존 `SourceCatalogPage`에는 승인된 학생용 문제 자료를 사용하는 `EssayQuestionPdf` 연결이 있으나 이 단독 입력 화면에는 연결되지 않았다.

따라서 **문제 원문 표시 연결 GAP**으로 기록한다. OCR로 읽은 학생 답안과 시험 문제 본문은 별개다. 기존 문제 보기/PDF 기능을 재사용하는 보완 대상으로, 원본에 없는 수식·그림을 생성하거나 평가자료/해설을 문제 자료 대신 노출하면 안 된다. 이번 턴은 원인 확인과 검수 기록이며 UI 수정·재빌드·배포를 수행한 것은 아니다. 신규 사진 전체 E2E 및 품질·운영 HOLD는 유지한다.

## B53 원본 대조 높이·테두리 보완 — 2026-11-03

Owner가 한양대 답안의 원본 대조 영역이 커서 스크롤 부담이 크다고 보고하고, 인식 수식 길이에 맞춘 크기 조절과 진한 테두리를 요청했다. 기존 [Academic Purple/F·G 구조 유지 결정](decisions.md#2026-11-02--task16-g-디자인-pass--학습-루프-통합)과 영역별 학생 확인 정책을 유지한 Native 표현 보완이다. 위 문제 원문 PDF 연결 GAP과는 별개다.

- `MathRecognitionPanel`의 영역별 고정 높이230을 제거했다. 실제 렌더링된 수식·본문 높이를 측정하므로 줄바꿈/분수/여러 줄 수식/글자 확대를 반영한다. 기본 글자 크기의 최소96, 최대320 안에서 조절하며 긴 내용은 내부 스크롤로 끝까지 읽을 수 있다. 학생이 전사를 수정하면 높이도 다시 측정한다.
- 인식 수식/원본 이미지 탭은 동일 높이를 사용하고 기존 탭 전환·스와이프를 유지한다. 큰 글자에서는 탭 레이블도 잘리지 않도록 조절한다.
- 각 대조 카드에 기존 Primary `#6340C8` 1.5px 테두리를 적용했다. 다른 MathCard는 기존 테두리를 유지한다.
- 각 영역의 확대 아이콘 `원본 크게 보기`는 기존 `MathSourceRegion`을 전체 화면에서 재사용한다. 원본 bytes·유효한 영역 좌표 강조·확대 기능을 유지하며, 닫으면 기존 확인 화면으로 돌아온다. 원본이 없으면 버튼을 비활성으로 둔다. 원본 이미지/좌표를 새로 생성하거나 변경하지 않는다.
- 수정 파일: `math_recognition_panel.dart`, `academic_purple.dart`, 기존 `task16f_mobile_test.dart`의 회귀 보완. 평가/확인 DTO, 불명확 기호 차단, 원본/최초인식/학생 수정본 저장 및 이용권 계약은 그대로다.

보존 검토 7문항: (1) 새 학습/정정 사실을 만들지 않는 화면 크기 조절, (2) 기존 원본 bytes/전사/좌표 보존, (3) DB UPDATE·삭제·새 저장 없음, (4) 기존 사용자/attempt identity 유지, (5) Learning 표시만 변경, (6) 새 수집·권한·전송 없음, (7) 계산한 높이는 로컬 표시값이며 평가 사실로 저장하지 않는다.

검증: 관련 **25 PASS**, Flutter Analyze PASS. 기본/2배 글자의 짧은 분수·여러 줄 수식·긴 본문, 탭 동일 높이, 전체 원본 확대 후 복귀, 긴 본문 끝까지 스크롤, 전사 수정에 따른 높이 증감, 기존 UNCERTAIN/수정 후 확인 취소·Q2 결론 보존·사진/History/선택 회귀를 포함한다. 초기 검사의 이미지 디코드 대기 타이밍과 줄바꿈 없는 수식 fixture를 고쳐 실제 비동기 이미지 로딩/여러 줄 수식으로 검증했다. 화면 캡처는 Widget 예제이며 실제 OCR 정확도 재검증이 아니다.

검수 화면 예제는 private `.codex/legendstudy-candidate-b-qa-20261103/b53-adaptive/`에 보존. TEST53 signed Release 빌드·서명·AOT·TEST Supabase/Pages 설정·새 adaptive widget/확대 레이블 포함 확인 PASS. iPhone12ProMax `LS Math TEST` 업데이트 설치·실행 및 버전53 확인, 기존 정식 A48 보존. 일반 LAB에서 기존 답안 대조 화면으로 진입해 높이·테두리·확대 복귀를 확인하도록 Owner에게 요청했다. 실제 iPhone 가독성/스크롤 부담은 Owner 확인 대기이며 선제 PASS로 기록하지 않는다. 산출물/로그는 private `app-review-integration-20261103/candidate-b/test53/`에 보존. Provider 추가 호출·새 평가·차감 및 운영 DB/Auth/Credit/Ledger/결제/WEB/APP41/A48/Store 변경 없음.


## B54 답안 확인·진행 표시·결과 근거 정리 — 2026-11-03

Owner IMG_1341~1350 실제 화면에서 입력/첨삭 진행 표시 누락, 중복·모호한 버튼, `0 크레딧` 및 긴 안내, 학생 답안 근거 전문 나열을 지적했다. 기존 [인문 진행 표시 정책](app-device-followup-20261030.md)과 [Academic Purple 유지 결정](decisions.md#2026-11-02--task16-g-디자인-pass--학습-루프-통합)을 재사용한 Native 후속이다. 작업 중 Owner가 B53 대조 높이·테두리·확대 복귀 “정상”을 확인했고, 전체 내용 한 번에 체크를 추가 요청했다. **B53 해당 실기기 PASS**, OCR 정확도/전체 신규 제출 PASS 의미는 아니다.

### 반영

- 기존 인문 `StepProgressBar`를 재사용해 Math 경로만 Primary/Lavender를 지정한다. 사진 준비·입력 인식·내용 확인, 제출 완료·첨삭 중·결과 준비를 실제 호출/서버 상태로 표시한다. 예상 퍼센트나 시간을 생성하지 않는다. 큰 글자에서도 레이블을 줄바꿈한다. 인문 기본 색/처리 정책은 유지한다.
- `math_session_read`와 기존 `read_input`을 foreground에서3→10→30초 간격으로 조회한다. 완료/조회 오류/백그라운드/화면 폐기 시 중지한다. 단순 폴링과 `첨삭 상태 새로고침`은 평가·차감 요청을 호출하지 않는다. 기존 request/run/evaluation ID, 응답 유실 후 같은 키로 이어가기 및 실패 문항 재처리를 유지한다.
- `저장한 답안 확인`을 주 동작, `답안 수정`을 보조 동작으로 동일 너비/16dp 간격에 배치한다. `0 크레딧`과 불필요한 입력 과금 설명을 제거했다. 실제 이용권 사용/무료 여부는 기존 서버 quote와 제출 확인창에서 명확히 안내한다.
- 처리 중/접수 후에는 준비 화면·선택 목록을 숨겨 중복 출력을 줄인다. 완료 시 `문제 N 첨삭 결과 보기`로 직접 기존 MathCoachingPage를 연다. 혼동되던 `새 답안 준비`는 제거하며 다음 사이클은 기존 History/수정 답안 경로를 사용한다. 미제출 답안 수정은 준비 키만 초기화하고 서버 원본·기존 기록을 삭제하지 않는다.
- 격리 TEST의 실제 Math catalog에 연결된 자연 문항만 `수리논술 · 답안 확인 후 첨삭`으로 안내한다. 인문용 운영 보류 문구가 TEST Math 가능 상태와 함께 표시되던 충돌을 수정했다. 운영 공개 제한/Registry/RPC를 해제하지 않았다.
- `MathStudentText`는 원래 줄·빈 문단·번호/경우 구분을 보존해 별도 줄로 렌더링한다. 여러 줄의 일반 수식이 단일 TeX로 합쳐지던 표시를 수정했다. 명시 TeX 환경/행렬/표는 분리하지 않으며, 긴 식 가로 스크롤/오류 시 원문 보존은 유지한다. `mathAnswerBlocks(...).join()`은 원문과 정확히 일치한다. 숫자·부호·조건을 수정하거나 미확정 값을 추정하지 않는다.
- 강점의 긴 `학생 답안 근거`는 미리보기와 `답안 근거 전체 보기/접기`로 제공한다. 전체 본문·표·마지막 문장까지 펼쳐 읽을 수 있으며, 같은 원문을 요약하거나 별도 평가 결과로 생성하지 않는다. 저장된 한양대 근거 재사용 렌더 검수와 예제 캡처를 구분한다.
- 2개 이상 인식 영역에 `전체 내용 확인` 체크를 추가했다. 원본 대조 후 일반 영역을 한 번에 체크/해제한다. `uncertain=true` 또는 불명확 기호가 남은 영역은 일괄 체크에서 제외하고 개별 대조/수정이 필요하다. 최종 동의와 `답안 입력 완료`는 별도이며, 전사 수정 시 해당 체크와 최종 동의를 취소한다. 신뢰도 수치로 원본 일치를 보장하지 않는다.

### 보존 검토 7문항

1. 기존 입력/평가/학생 확인 facts와 시각을 유지하며 새 사실을 합성하지 않는다.
2. 사진·최초 OCR·확정 전사·공식 근거는 원래 저장소/ID에서 재현한다.
3. DB UPDATE/새 migration/삭제 없음. 문단 나누기와 펼침 상태는 로컬 표시값이다.
4. 기존 Auth owner/attempt/run/lineage 연결을 유지한다.
5. Learning 표시만 보완하며 평가 오류를 학생의 영구 특성이나 입시 결과로 바꾸지 않는다.
6. 새 수집·권한·전송 없음. 실제 답안/인증정보/원본 이미지를 Git에 넣지 않는다.
7. 진행 단계는 실제 호출·서버 상태, 형식 분리는 문자열 경계다. AI 품질·완료율을 추정하거나 원본에 저장하지 않는다.

### 검증 및 인계

- 집중 회귀32PASS: OCR 처리 중 표시/읽기 전용 폴링, 불확실 전사 평가 차단, 일부 문항 미완료, 오류 후 수동 복구, background pause/resume, 완료 후 정지, 재시도 동일 키, 일괄 확인/최종 동의/수정 무효화, 원문 보존·표·여러 줄/긴 수식·1배/2배 레이아웃.
- 전체 회귀/Analyze/TEST54 Release·실기기 설치 결과는 아래 최종 영수증에 기록한다. 최초 전체 실행의 유일 실패는 기존 테스트가 `MathText` 1개를 가정한 부분이며, 새 문단별 출력의 전체 원문 일치 검증으로 갱신 후 집중 회귀 통과했다. 미검증을 PASS로 숨기지 않는다.
- 화면 캡처는 private `.codex/legendstudy-candidate-b-qa-20261103/b54/`에 보존한다. Widget 예제는 인식/평가 품질 증거가 아니고, 기존 한양대 저장 근거 렌더는 Provider 재호출이 아니다.
- 변경: `math_exam_session.dart`, `math_gateway.dart`(안내만), `source_catalog_page.dart`, `math_text.dart`, `math_mobile/math_coaching_screen.dart`, `math_mobile/math_answer_evidence.dart`, `math_mobile/math_recognition_panel.dart`, 공통 `shell_widgets.dart`(진행 색상 옵션/줄바꿈) 및 관련 테스트.
- Provider 추가 호출/새 평가/이용권 차감0. 운영 DB/Auth/Credit/Ledger/결제/WEB/APP41/A48/Store 변경 없음. 신규 사진 전체 실기기 루프, Native 혼합 신규 제출, 실제 OCR 의미 오류·대학별 첨삭/힌트 품질, 단독 입력 화면의 공식 문제 PDF 연결은 기존 P0/GAP으로 남는다. 이번 표현 보완을 전체 품질/출시 승인으로 확대하지 않는다.


최종 영수증: **전체 Flutter Test1,418PASS / 기존7SKIP / 0FAIL**, Analyze0issues, Wiki handoff PASS. 기본/2배 Widget 캡처2PASS와 기존 한양대 저장 근거 렌더1PASS(끝까지 스크롤/원문 동일성 포함). 최초 전체 검사1건의 단일 위젯 가정 수정 후 전체 suite를 다시 통과했다. 이는 코드/표시 검증이며 새 Provider OCR/평가 E2E가 아니다. 저장된 한양대 근거에는 원래의 인식 손상/일반 텍스트 수식이 남아 있으며 형식 보완으로 OCR 정확도 PASS를 선언하지 않는다.

TEST54 signed Release1.0.1(54) 빌드·codesign deep/strict·AOT·격리 Supabase/Pages 설정·신규 UI 코드 포함 검증 PASS. iPhone12ProMax 설치·실행/일반 LAB 열기 요청 및 설치 목록의 **LS Math TEST54 / 기존 레전드스터디+ A48** 확인. 산출물·검사 로그는 private `app-review-integration-20261103/candidate-b/test54/`. Owner에게 기존 한양대 저장 답안의 짧은 확인 버튼·일괄 확인·근거 펼침/문단 검수를 요청했다. B54 실제 가독성/진행 바 전체 사용자 검수는 아직 대기다. 운영/Store/HOLD와 기존 품질 P0는 유지한다.


## B55 일괄 확인 동작·필수 영역 번호 — 2026-11-03

Owner는 B54에서 `전체 내용 확인`이 작동하지 않는다고 보고하고, 가능한 영역을 한 번에 체크한 뒤 제외된 필수 확인 영역 번호를 안내하도록 요청했다. [기존 일괄 확인 결정](decisions.md#2026-11-03--수리-입력-진행근거-가독성과-일괄-확인)과 [TASK16-E 원본 확인 정책](task16e-recognition-disclosure-p0-20261102.md)을 이어간다.

### 원인과 변경

B54는 `uncertain=true` 또는 미식별 문자열이 남은 영역을 제외한 결과가 0개이면 일괄 체크 UI를 비활성화했다. 실제 저장된 한양대 입력 한 건은 18개 모두 uncertain이어서 버튼이 작동하지 않았고, 제외된 번호도 없었다. 이 플래그는 읽을 수 없는 문자뿐 아니라 부호·값의 원본 대조 요구도 포함한다. 따라서 18개 전부를 미식별이라고 해석하지 않는다.

- `전체 내용 확인`은 busy 중이 아니면 실행되며, 체크 가능한 영역만 추가 선택한다. 다시 눌러도 기존 체크/개별 확인을 해제하지 않는다. 신규 체크가 없는 재실행은 이미 한 최종 동의도 임의 해제하지 않는다.
- 실행 직후 `확인 완료 N개 · 남은 영역 M개`를 보여준다. 가능한 영역이 0개여도 사유와 필수 번호가 나타난다. 새 안내가 추가되면서 버튼이 아래로 밀리지 않도록 결과 위치를 화면에 유지한다.
- `반드시 수정 · 미식별 내용이 남아 있어요`와 `반드시 확인 · 원본의 기호·값을 대조해 주세요`를 구분한다. 기존 reading_order와 동일한 번호를 사용하며, 없는 경우 현재 목록 순서로 표시한다. 번호를 누르면 해당 원본 대조 카드로 이동하고 `남은 확인 목록으로` 돌아올 수 있다.
- 개별 확인한 번호는 남은 목록에서 즉시 빠진다. 전사를 다시 수정하면 해당 체크/최종 동의가 해제되고 목록에 돌아온다. 일괄 선택 이후 일반 영역을 수동 해제한 경우에도 별도 목록으로 안내한다.
- 학생의 최종 동의와 `답안 입력 완료`는 계속 별도다. 미식별 내용 수정 전 체크/최종 제출 차단, uncertain 영역 개별 확인, 원본/최초 인식/수정 전사 구분, 기존 확인본 전달 계약을 유지한다. confidence로 확인을 생략하지 않는다.

### 보존 검토 7문항

1. 기존 입력·확인 facts만 사용하며 체크 개수를 인식/평가 정확도로 해석하지 않는다.
2. 원본 사진·최초 OCR·확정 전사/ID는 변경하지 않는다.
3. DB UPDATE·migration·삭제 없음. 체크/번호 목록은 기존 로컬 상태의 표시다.
4. 기존 사용자·시험·입력·History 연결과 onConfirm payload를 유지한다.
5. 확인 상태는 학습 조작 상태이며 학생 능력/입시 결과로 전환하지 않는다.
6. 새 수집·권한·Provider 전송 없음. 실제 답안/이미지·키는 Git에 추가하지 않는다.
7. 필수 분류는 기존 uncertain/미식별 판정에서 파생하며 영역 좌표·수식·조건을 생성하지 않는다.

### 검증

- 관련 Flutter **24 PASS**: 기존 Native18개 + 신규5개 + 로컬 저장 한양대 재현1개. 기본/2배 글자 크기, 일반 영역만 선택, 0개 가능 안내, 모든 필수 번호, 위치 이동/복귀, 개별 확인 후 목록 감소, 미식별 수정·별도 확인·최종 동의, 반복 클릭 멱등, busy/새 입력 초기화 포함. 저장 한양대 18개 원본 region JSON은 전후 동일, Provider 호출0.
- Analyze 0 issues. Widget 캡처의 기본/2배 레이아웃과 실제 저장 입력 안내를 직접 확인했다. 캡처의 수식 폰트도 앱의 기존 KaTeX 자산을 로드했다. 코드/표시 검증이며 새로운 OCR·평가 E2E 증거가 아니다.
- B54 전체1,418PASS/기존7SKIP을 기준선으로 재사용한다. 이번 작은 Native 범위에서는 관련 회귀를 실행했으며 전체 suite를 다시 실행했다고 보고하지 않는다.
- 변경 파일: `lib/features/essay/math_mobile/math_recognition_panel.dart`, `test/math_bulk_confirmation_test.dart` 및 Wiki. 판정 엔진·저장 API·APP/WEB 공통 계약·Provider·차감·공개 정책 변경 없음.
- 실제 iPhone의 B55 일괄 선택/번호 이동은 설치 후 Owner 확인 대상으로 남는다. 서버가 모든 수학 영역을 대조 대상으로 표시할 수 있는 기존 정책/확인량과 실제 OCR 의미 오류는 별도 품질 과제다. 이번 UI 수정으로 OCR 정확도나 전체 출시 PASS를 선언하지 않는다.

최종 영수증: TEST55 signed Release **1.0.1(55)** 빌드 PASS, deep/strict 서명·AOT·별도 TEST bundle/표시명·격리 Supabase/Pages·새 일괄 안내/번호 이동 코드 포함 확인. iPhone12ProMax 설치·실행 및 LAB 열기 요청 성공. 설치 목록에서 **LS Math TEST55 / 기존 정식 A48 보존** 확인. 산출물·로그·캡처는 private `app-review-integration-20261103/candidate-b/test55/`에 보존했다. Wiki handoff PASS.

Owner에게 기존 한양대 답안에서 일괄 확인 개수/필수 번호→해당 영역 이동→남은 목록 복귀를 요청했다. 모든 영역이 대조 대상인 경우 0개 체크 사유가 표시됨을 안내했다. 실제 B55 화면 확인은 Owner 응답 대기이며 자동 검증과 구분한다. 새 촬영/평가/최종 확정 없이 검수 가능하다. 운영 DB/Auth/Credit/Ledger/결제/WEB/APP41/A48/Store와 실제 Provider 호출은 변경하지 않았다.
