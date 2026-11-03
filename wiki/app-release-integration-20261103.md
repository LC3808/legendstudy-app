# APP Release Integration — 2026-11-03

상태: **후보 A BUILD_PASS / DEVICE_QA_PENDING; 후보 B CODE_PASS / BETA_HOLD; STORE_HOLD**.
이번 Owner 승인은 병합/검증/신규 빌드까지이며 Store 제출·운영 베타 활성화 승인이 아니다.
[기존 APP41](final-store-rc-1.md#task18-build41-owner-login-acceptance--2026-11-02),
[온보딩 V2](onboarding-v2-final-integration-20261103.md), [Kakao 시스템 인증](kakao-ios-system-auth-20261103.md)의 통합 후속.

## 기준선·브랜치·보존

- APP41 실제 빌드 소스 `03b73e293ef08e0a8f87f105af60ebbecc3d831a`에서 새 managed worktree 생성.
- A `codex/app-review-candidate-a-20261103`: 온보딩 지정 `30edf235b693848a64ea4a170b502619d4ea1c22`를 merge `832eafe`, 인증 `2c3ce78` cherry-pick `d346e95`.
- 기존 APP41의 미커밋 Xcode patch를 새 후보에만 복사하여 `7c7ff27`로 기록. 원본 branch/dirty files 보존.
- B `codex/app-review-candidate-b-20261103`: A에서 분기, TASK16-K 최신 `d7d5bb1` 사용. 지정097397b 이후 OCR/전사/키보드 후속 포함.
- 온보딩 조상에 있던 notice SQL 후보는 파일 이력만 포함, DB 적용 없음.
- 별도 평가 엔진/History/결제/이용권 시스템을 만들지 않았다.

## 후보 A 검증

- Flutter3.47.6 고정. Analyze PASS; 전체 **1,356 PASS / 7 SKIP / 0 FAIL**.
- 기존 인증 집중53 PASS를 포함한 전체 통합 회귀. Mock PKCE/취소/콜백/중복교환/계정변경 검사이며 실제 Kakao 사용자 E2E가 아니다.
- iOS **1.0.1(42)** signed Archive/App Store IPA PASS; 별도 debugging export PASS(직접 기기 설치용).
- Android **1.0.1/versionCode42** signed AAB PASS, 95.5 MB; jarsigner PASS. 이번 실행 PDFium 다운로드 장애 없음.
- 검증된 기존 public config·서명 재사용. Supabase URL/publishable key, Google server/iOS ID가 실제 iOS AOT binary에 포함됨을 값 출력 없이 검사.
- Apple entitlement Default, com.legendstudy.app, codesign deep/strict PASS. 모든 OAuth flag true. Analytics 미설정=false로 APP41 동작 유지; 새 수집 없음.
- `tool/store-release` preflight는 기존 OAuth 검사에 Supabase 운영 host·publishable key 필수 검사를 추가했다. 잘못된 host/private key/누락은 빌드 전 거절. Python3 테스트3 PASS.
- 기존 Flutter TTS SPM, Gradle/Kotlin future support, Cupertino font 경고는 남음. 빌드 성공을 실기기 UI/심사 승인으로 간주하지 않는다.

산출물(로컬 private, Git 제외):
`/Users/woojinchang/development/legendstudy-private-backups/app-review-integration-20261103/candidate-a/`

| 파일 | SHA256 |
|---|---|
| legendstudy-candidate-a-1.0.1-42.ipa | 3d58fc4fc02a09832d284801aa9709cd3d652ab847346ae96c043d0c316dea9f |
| legendstudy-candidate-a-1.0.1-42.aab | 7498fc51eb7ef015c08cf892562e121386d00fbcb94dd21f86dad49e94149891 |

로그 `/tmp/app-review-a-{analyze,tests,ios,android,device-export,aab-signature}.log`.

## Apple 현재 상태와 재제출 절차

2026-11-03 ASC 읽기 확인: 제출 efd80130-07aa-4ea3-a1a4-11f7d5d06254,
**1.0.1(41) 심사 실패 / 4.0.0 Design: Preamble / 해결되지 않은 문제**.
심사 기기는 iPad Air11 M3·iPhone17ProMax. 사용자 로그인/가입이 외부 기본 브라우저로 이동하는 문제다.
최신 TestFlight 업로드41,42 미업로드. Store 버전1.0.1을 유지한 새42 후보로 준비.
Apple은 이번 문제를 후속 업데이트에서 해결하는 bug-fix submission 예외 가능성도 안내했으나,
Owner는 지금 수정하는 방향을 선택했다. Apple 메시지 회신/예외 요청을 보내지 않았다.

Owner 승인 이후: 새 빌드 업로드/처리 → 기존1.0.1의 Build를 새 빌드로 선택·저장 →
해결 내역/실기기 근거를 제공하고 unresolved submission 재제출. 제출 빌드 번호는 직전 재조회한다.
[Apple build 선택](https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit/),
[미해결 제출 관리](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/manage-a-submission-with-unresolved-issues).
현재 자동 재제출 버튼 비활성, 업로드/선택/저장/메시지 전송 모두 미실행.

## 실기기 검수와 인증 환경

격리 TEST 공개 Auth settings read: Kakao/Google/Apple=false, email=true.
기존 APP41 Auth settings read: 네 방식=true. 설정/redirect/Secret 변경 없음.
따라서 TEST에서 실제 소셜 E2E PASS를 주장하지 않는다.
후보 A 실제 기기 검수는 기존 서비스 인증 설정으로 수행하며 초기에는 Owner가 설치를 보류했다. 이후 정식 빌드·실기기 검수를 지시하여 아래 기록처럼 후보 A를 설치했다.
기존41 IPA·branch 보존. 회원 삭제/계정 통합/임의 신규 회원 생성 없음.

필수 Owner 검수: Kakao 기존 로그인/신규 가입/취소/인증창 자동 닫힘/앱 복귀/동일 세션 재실행,
Google·Apple·이메일 로그인·회원가입, 온보딩 저장 실패/건너뛰기/학교 확정/MY 미설정 카드.
iPad도 심사 기기이므로 해당 화면·인증창 검수가 별도 필요하다.
현재 이 matrix는 **NOT_VERIFIED**;41 로그인 PASS·Mock PASS로 대체 불가.

## 데이터 보존 검토

1. 기존 Auth session/프로필과 평가·재작성 facts만 재사용. 시간 필드·과거 이벤트 재기록 없음.
2. 기존 답안 원본/OCR/확정 전사 및 History immutable 계약 보존; 원본·계정 Git 제외.
3. 신규 UPDATE/backfill/migration 실행 없음. 온보딩 기존 dirty-field 저장 계약 유지.
4. 기존 auth.users identity, 계정 전환 방어 유지. 별도 계정/플랫폼 identity 없음.
5. Learning(첨삭)·Decision(프로필/관심 대학)·Outcome을 합치지 않음.
6. 기존 owner scope/Storage/권한/retention 유지. 새 개인정보 수집·동의 확대 없음.
7. AI feedback/OCR/성장 지표는 파생값이며 공식 사실·입시 결과로 저장하지 않음.

## 운영 연결 차단

읽기 확인: 운영 public에는 math_coaching, essay_math_coaching, math_session_quote,
math_session_continue가 없고 TEST에는 네 개 존재. essay_exam_history 함수 hash도 다름.
운영 RPC/Provider/Registry admission/Storage/Credit·History 연동의 증분 적용·rollback을 별도 승인해야 한다.
전체 TEST 설치 SQL을 운영에 적용하지 않는다. 베타 cutoff 2026-11-11 00KST 불변.
후보 B 추가 통합·검증 내용은 아래 기록한다.


## 후보 B 통합 결과

통합 merge `89e1f11`, 부모는 A 코드 `7c7ff27`와 TASK16-K `d7d5bb1`.
A 후속 release-config preflight도 동일하게 포함했다. 온보딩/Auth/Native AppDelegate는 A와 동일함을 diff로 확인했다.
기존 Academic Purple, Math Provider/Session/인식 확인/서버 공개/학습 loop 계약 재사용. LAB Backend 변경·배포 없음.

### 14개 충돌 처리

| 파일 | 원인과 선택 |
|---|---|
| lib/core/config/app_config.dart | Analytics 추가와 TEST origin 추가 충돌. Analytics 보존, exact TEST host+DB 일치 때만 TEST 경로 허용 |
| lib/features/essay/answer_image_crop.dart | 두 브랜치가 같은 인문 crop을 추가. TASK16-K의 공통 crop 확장을 사용, 인문 entrypoint/취소/첨부 계약과 Math 회전/원본 비교 모두 보존 |
| lib/features/essay/evaluation_report_view.dart | 최신 StudentFeedbackView와 수리 LaTeX/공개 wrapper 충돌. 인문은 최신 UI, 수리는 기존 math 표시/공개 분기로 분리 |
| lib/features/essay/shared_history_page.dart | 공통 결과 helper·Analytics와 MathCoaching 라우트 충돌. 공통 helper에 수리 라우트를 넣어 History·성장 양쪽에서 같은 경로 사용 |
| lib/features/essay/source_catalog_page.dart | 최신 제출/초안/준비중 정책과 Math 사진·재첨삭 충돌. 인문 제출/분석/오류 복구 유지, TEST에서 자연 MathSession만 연결, 운영 보류 유지 |
| pubspec.yaml | Firebase/uuid/SharedPreferences와 flutter_math_fork 추가 충돌. 기존 의존성 버전 유지, 수식 패키지만 합침 |
| test/answer_image_crop_test.dart | 동일 원본 테스트+Math 확장. 인문5 흐름 및 회전·원본불변 검사 유지 |
| test/math_gateway_test.dart | 원본 authenticated download와 최신 OCR 재시도 추가. 양쪽 검사 유지 |
| test/source_catalog_widget_test.dart | fixture import 충돌. 두 suite 보존, 최신 public-service/owner/이어쓰기 계약으로 fixture 갱신 |
| wiki/current-status.md | 양쪽 최근 상태 충돌. 두 입력 스냅샷 보존 후 후보 상태로 축약 |
| wiki/decisions.md | 독립 Owner 결정 추가. 두 정책 이력 보존, 이번 A/B 승인 범위 연결 |
| wiki/essay-beta-credit-design-20261027.md | 일일 베타와 Math 사이클 후속 링크. 양쪽 보존 |
| wiki/index.md | 운영 인문/온보딩 라우팅과 TASK16 라우팅. 모두 보존 |
| wiki/log.md | 동기간 독립 로그. 둘 다 보존하고 이번 통합 로그 추가 |

자동 병합으로 지나간 추가 결함도 수정:
- `exam_draft_actions.dart`: Math 재첨삭 새 초안에 이전 사진/전사가 자동 이관되지 않도록 기존 MathSession 정책 적용. 기존 인문 미완료 초안 복원은 유지.
- `math_mobile/math_coaching_page.dart`: 기존 새 owner 검증 계약에 맞춰 재작성 라우트에 rewriteOwner 전달.
- `math_exam_session_test.dart`: Production 자연 보류/격리 TEST Math 분기 및 진입만으로 제출·평가0 확인.
- 인문·수리 결과 별도 scroll 구조에 맞게 테스트 selector만 정정. 공개 전 수리 상세 없음 검사 유지.

### 통합 검사

- 후보 B Flutter Analyze **PASS**.
- 전체 **1,383 PASS / 7 SKIP / 0 FAIL**, 집중36 PASS. 테스트 로그 `/tmp/app-review-b-tests-final.log`, `/tmp/app-review-b-focused.log`, `/tmp/app-review-b-analyze.log`.
- 기존 인문 평가/제출/재첨삭/초안·계정전환/온보딩/MY/인증 회귀 포함. 기존 Owner PASS를 새 실기기 PASS로 계산하지 않음.
- 최초 전체 suite의5 실패는 Math list selector2, 이전 fixture의public-service/owner/이어쓰기3이며 수정 후 전체 재실행 PASS. 새 초안 이관과 owner 전달은 실제 통합 결함으로 별도 수정했다.
- Provider 신규 호출0; 운영 write0. 격리 TEST/운영 public RPC 존재/hash 및 Auth 공개 settings는 읽기만 수행.

### 기능 검증과 출시 차단 구분

| 영역 | 현재 근거 | 판정 |
|---|---|---|
| 온보딩 V2+MY | 지정 commit, 전체 회귀 포함 | CODE_PASS / DEVICE_PENDING |
| Kakao 시스템 인증 | PKCE/콜백/취소/중복/복원 Mock + signed native compile | CODE_PASS / DEVICE_PENDING |
| Math UI/사진 crop/LaTeX/키보드 | TASK16-K Owner 기존 사용성 PASS 재사용, 이번 전체 회귀 | CODE_PASS / 통합 실기기 미검수 |
| 자연 Q1/Q2 학습 loop | 기존 G Simulator, I/K WEB 실제 PASS 재사용 | TEST 기능 PASS 이력 / 이번 통합 E2E 미실행 |
| 실제 카메라 OCR | K 원본 비교·-1/6 수정·키보드 Owner PASS 재사용 | PARTIAL, 전사 확정→평가→재첨삭 실기기 미완료 |
| 상경 Essay+Math | I/K TEST WEB 실제 paid/free/History PASS 재사용 | 서버/WEB PASS 이력, Native 새 사진 혼합 제출 BLOCKED |
| Credit/History | 기존 TEST 서버1/0/다음1·중복 방지·교차 조회 이력 | 기존 PASS 재사용, 운영 승격 미적용 |
| 운영 공개 | Registry+admission+RPC/Provider gate 별도 | HOLD |

**Native 혼합 제출을 전체 PASS로 보고하지 않는다.** 실제 코드에서 MathExamSession은 선택 문항 전부 Math일 때만 연결되고,
기존 공통 Essay 제출은 텍스트만 허용하며 사진 포함/이미지 문항을 차단한다. A의 mixed 준비중 정책을 유지했다.
기존 I의 Native 혼합 endpoint gate/교차조회 성공은 APP 카메라 혼합 신규 제출 성공과 다르다.
이 연결을 강제로 우회하면 OCR 확인·시험 단위 과금·부분 완료 정책을 손상할 수 있어 후보 B의 출시 차단으로 명시한다.
이번 사용자 결정에 따라 B 미완료가 A 제출 준비를 막지 않는다.

### 기존 Registry·운영 승격 준비

[기존 K 시험별 감사](task16k-registry-audit-20261103.csv)와 [최신 K 차단](task16k-beta-activation-20261103.md)을 재사용한다.
신규 시험 DB/자료 복제0. 기존50개 package 연결은 시험별 실제 E2E READY 판정이 아니다.
대표 상경 `e8ea5bb3-0956-5fd6-b90e-4b7fb350b2f9`는 기존 운영 Registry에 존재하며 TEST WEB 검증됨.
자연2024 오전 TEST 시험 `b98fd0c9-8a84-5747-a35c-25755312aede`와 운영2024모의 시험을 같은 시험으로 대체하지 않는다.

Owner 승인 이후의 순서:
1. 후보 A 실기기 소셜 matrix와 온보딩/MY 검수. 승인된 후보만 Store 업로드·검수.
2. B는 Native 혼합 사진·확정 전사 제출 계약 연결 및 실제 통합기기 loop 먼저 검증.
3. 운영 현재함수/ACL에 맞춘 coaching/disclosure/quote/continue 증분 SQL+rollback 작성·TEST 검증. TEST 전체 install SQL 실행 금지.
4. 운영 Registry 공개 범위/공식 evidence/Provider·Worker 실행/admission leaf 제한·Storage/RPC 권한 점검, Credit/History 기존 이력 보존.
5. Owner 별도 승인 후 필요한 Backend→WEB→APP 공개 순서를 조율. 이번에 운영 flags/Provider/WEB 변경 없음.
6. 베타11/11 종료·일일1회·14일/1회 무료 재첨삭 정책과 기존 인문 정상 동작 재검증.

후보 A: **BUILD_PASS, 실기기/Owner 승인 전 제출 HOLD**.
후보 B: **NOT_READY** — 통합 빌드가 성공해도 혼합 Native·OCR 품질·실기기·운영 연결 게이트가 남는다.


## 최종 빌드 기록

| 후보 | iOS | Android | 검수/제출 |
|---|---|---|---|
| A | 1.0.1(42), signed Archive/IPA + debugging export PASS | 1.0.1(42), signed AAB95.5MB PASS | Owner 설치 보류, 미업로드 |
| B | 1.0.1(43), signed Archive/IPA18.7MB PASS | 1.0.1(43), signed AAB99.3MB PASS | 베타 출시 NOT_READY, 미업로드 |

B code source `89e1f11667ac45ace86b5ec3999b382e8145c311`; 이후 Wiki만 갱신.
실제 양쪽 iOS/Android binary에서 기존 Supabase/Google public values 포함 확인.
iOS codesign deep/strict·Apple entitlement PASS, Android jarsigner PASS/merged manifest42·43 확인,
AD_ID/ACCESS_ADSERVICES_AD_ID 없음. Analytics 기존 OFF 유지. PDFium 환경 오류 없이 빌드 완료.

B 산출물 private 경로:
`/Users/woojinchang/development/legendstudy-private-backups/app-review-integration-20261103/candidate-b/`

| 파일 | SHA256 |
|---|---|
| legendstudy-candidate-b-1.0.1-43.ipa | d95b2622995e73318dce3c8acd8894848a296a8d14c9476d89a68776ccb7766f |
| legendstudy-candidate-b-1.0.1-43.aab | 994954345a31b71c750c7abab8882f356ad42d7536dede90a0e006722bbdbe67 |

각 후보 `logs/`에 빌드/검사 로그 보존. IPA/AAB/archive/인증 설정/손글씨 원본 Git 제외.
위 hash는 이번 산출물 hash이며 최종 Wiki commit과 빌드 당시 code SHA는 구분한다.
Wiki handoff/internal links PASS, current-status 약2.5KB. 옮겨진 TASK16 감사의 sibling 저장소 링크는
실제 존재하는 로컬 자료 절대 경로로 수정했으며 원문 내용·자료 파일은 변경하지 않았다.

Owner 검수 재개: A의 별도 development-signed export로 지정 iPhone에 설치한 후 본문의 인증/온보딩 matrix 진행.
초기 마감 당시 설치 보류였으며 이후 후보 A 업데이트·Owner 로그인 검수는 아래 후속 기록을 따른다. Store 메시지·업로드·재제출0.
B TEST Preview는 기존 https://legendstudy-task16b.pages.dev 를 유지하며 이번 WEB 배포0.


## 후보 A Release 재빌드·실기기 설치 — 2026-11-03

Owner가 설치 보류 이후 실제 검수와 정식 빌드를 지시하여 후보 A를 재빌드했다.
A 소스 기준 `6ab5010`; 앱 기능 변경 없이 `tool/store-release`와 기존 검증 설정으로
1.0.1(42) signed Release Archive/App Store IPA 생성 PASS.
같은 Release archive를 기기 설치용 development signing으로 export했다.
Flutter Debug 빌드가 아니며 AOT 포함/kernel_blob 없음, codesign deep/strict,
iPhone12ProMax provisioning 포함을 확인했다.

- iPhone12ProMax 기존 `com.legendstudy.app` 업데이트 설치 및 devicectl 실행 **PASS**.
- 기존 앱 삭제 없음. 실제 사용자 데이터 유지·Kakao 인증창·취소·복귀·세션 유지 판단은 Owner 검수 대기.
- 기존 APP41 소스/백업과 별도 LS Math TEST 유지. Store 업로드/심사 제출·운영 설정 변경 없음.
- 후보 B 설치/실기기 검수로 간주하지 않는다. B 베타 차단은 그대로다.
- 재빌드 산출물은 기존 산출물을 덮어쓰지 않고 private `candidate-a/device-release-rebuild/`에 보관.
- App Store IPA SHA256: `4bd63ee9858677bd05dc028004e6d39a7e8ddd9492af61ff1af1bc72feebf208`.
- 기기용 IPA SHA256: `17090f42a5079dfc6d231cc0e9b130ff3720bd6d49dcd091cde39f8aa32027ba`.
- 기존 A 전체1356PASS/7SKIP 재사용. 이번 변경은 재빌드/설치/기록이며 테스트 PASS를 실기기 인증 PASS로 확대하지 않는다.

첫 검수: Kakao 시스템 인증창 → 취소 → 재시도 → 로그인 → 창 자동 종료/홈 복귀.
후속: 앱 재실행 세션, Google/Apple/이메일, 신규 계정 온보딩 및 MY, 기존 인문 LAB.


### 후보 A Kakao 실기기 Owner 확인 — 2026-11-03

기기 iPhone12ProMax, Release1.0.1(42). Owner 응답: “인증창 → 취소·재시도 → 로그인·홈 복귀 정상”.
질문에 포함한 외부 Safari 대신 앱 위 인증창 표시·취소·재시도·인증창 자동 종료·홈 복귀를 **Owner 관찰 PASS**로 기록한다.
서버 로그/녹화 독립 검증으로 표기하지 않는다. 실제 신규 가입 여부·강제 종료 후 세션 유지·Google/Apple/이메일·온보딩/MY·iPad는 아직 미검증.
다음 확인은 앱 완전 종료 → 홈 아이콘 재실행 → MY 동일 계정 유지다.
후보 A 전체 QA 및 Store 제출 승인을 뜻하지 않으며 후보 B/운영 베타 HOLD 유지.


### 후보 A 재실행 세션 Owner 확인 — 2026-11-03

iPhone12ProMax Release1.0.1(42)에서 앱 전환 화면으로 완전 종료한 뒤 홈 아이콘으로 재실행하는 확인 요청에 Owner가 “홈·MY 동일 계정 유지”로 응답했다. 재로그인 없는 동일 계정 유지 **Owner 관찰 PASS**. 독립 서버 로그 검증·신규 가입·다른 Provider·다른 기기 검증으로 확장하지 않는다. 다음 검수는 MY 기존 정보 및 누락 안내와 프로필 수정 화면이다. Store/운영 베타 HOLD 유지.


### 후보 A MY 누락 안내 Owner 확인 — 2026-11-03

iPhone12ProMax Release1.0.1(42)의 MY·프로필 수정 화면 확인 요청에 Owner가 “기존 정보 정상·빠진 정보만 안내됨”으로 응답했다. 해당 계정의 기존 정보 표시 및 누락 정보 안내 **Owner 관찰 PASS**. 모든 정보가 설정된 계정에서 카드 숨김, 실제 프로필 저장/재조회, 학교 검색, 신규 온보딩은 이 응답으로 PASS 처리하지 않는다. 다음 검수는 MY 학교 검색의 고등학교 기본·중학교 명시 검색·주소 없는 카드·학교명 확인 버튼이다. 검수용 허위 프로필 변경은 요청하지 않았다. Store/운영 베타 HOLD 유지.


### 후보 A 학교 검색 Owner 확인 — 2026-11-03

iPhone12ProMax Release1.0.1(42), MY 학교 검색의 고등학교 기본 검색·중학교 명시 검색·주소 없는 학교 카드·선택 후 학교명 확인 버튼을 확인하는 질문에 Owner가 “검색·학교 카드·선택 확인 버튼 정상”으로 응답했다. 요청한 검색/선택 화면 범위를 **Owner 관찰 PASS**로 기록한다. 프로필 저장은 요청하지 않았으며 저장·재조회, 최초 결과 임시 선택, placeholder 애니메이션, 초등학교 제외의 별도 검증이나 신규 온보딩 전체 PASS로 확대하지 않는다. 다음 확인은 기존 PDF와 인문논술 History·결과 조회/뒤로 이동이며 신규 평가 요청은 하지 않는다. Store/운영 베타 HOLD 유지.
