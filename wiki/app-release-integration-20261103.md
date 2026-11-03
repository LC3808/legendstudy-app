# APP Release Integration — 2026-11-03

상태: **후보 A BUILD_PASS / ONBOARDING_OWNER_PASS / 잔여 인증·기기 검수 PARTIAL; 후보 B CODE_PASS / BETA_HOLD; STORE_HOLD**.
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


### 후보 A 기존 자료·인문논술 조회 Owner 확인 — 2026-11-03

iPhone12ProMax Release1.0.1(42)에서 기존 자료실 PDF와 인문논술 History·첨삭 결과를 열고 뒤로 이동하는 확인 요청에 Owner가 “PDF·인문논술 History·결과·뒤로 이동 정상”으로 응답했다. 해당 계정에서 실제 조회한 자료·저장 결과 및 화면 이동을 **Owner 관찰 PASS**로 기록한다. 전체 자료/PDF 기능, 신규 인문 평가·재첨삭·차감이나 수리/혼합형 E2E PASS로 확대하지 않는다. 새 평가 요청은 하지 않았다. 다음 검수는 사용 가능한 기존 Google/Apple/이메일 계정 로그인 회귀다. 후보 A 전체 검수·Store 승인 및 후보 B/운영 베타 HOLD는 유지한다.


### 후보 A 이메일 로그인 Owner 확인 — 2026-11-03

iPhone12ProMax Release1.0.1(42), 기존 이메일 계정으로 로그아웃→로그인→홈·MY 확인을 요청했고 Owner가 “이메일 로그인·홈·MY 정상”으로 응답했다. 기존 이메일 로그인과 해당 계정 정보 표시는 **Owner 관찰 PASS**. Kakao와 이메일 계정의 실제 identity가 별개인지 확인하지 않았으므로 별도 계정 간 데이터 격리의 독립 검증으로 확대하지 않는다. 이메일 재실행 세션 유지·잘못된 비밀번호 오류/정상 재시도·신규 가입·Google/Apple은 미검증. 다음 확인은 이메일 세션 재실행과 오입력 1회 후 정상 재시도다. 비밀번호/이메일 원문 수집 없음. Store/운영 베타 HOLD 유지.


### 후보 A 이메일 세션·오입력 재시도 Owner 확인 — 2026-11-03

iPhone12ProMax Release1.0.1(42), 이메일 로그인 후 앱 완전 종료/재실행 시 동일 계정 유지, 로그아웃 후 비밀번호 1회 오입력 시 로그인 차단·오류 안내, 올바른 비밀번호 재시도를 요청했다. Owner 응답 “세션 유지·오류 안내·정상 재시도 모두 확인”에 따라 해당 흐름을 **Owner 관찰 PASS**로 기록한다. 신규 이메일 가입·비밀번호 재설정·장시간 토큰 갱신·rate limit 검증으로 확대하지 않는다. 다음 검수는 기존 Google/Apple 계정의 취소·재시도·로그인·홈/MY 확인이다. 비밀번호/계정 원문 수집, 코드·운영 설정·Store 변경 없음.


## Apple 신규 온보딩 학교 단계 이탈 보고 — 2026-11-03

Owner는 Google/Apple 질문에 “1) 정상, 애플로그인 새로 가입으로 온보딩 '학교 입력' 했는데, 학교 검색 누르고 나니까 그냥 화면이 넘어가버리네?”라고 보고했다. Apple 인증 후 신규 온보딩 진입은 관찰됐으나 학교 단계는 **FAIL(Owner 보고)/원인 조사 중**이다. “1) 정상”만으로 Google·Apple 각각의 모든 취소/재시도 흐름을 PASS 처리하지 않는다. 기존 MY 검색 PASS는 신규 온보딩 PASS가 아니다. 학교 누락 통계 전체의 원인이 이 사건이라고 단정하지 않는다.

### 재현·방어 수정

- 검색 자체는 `_search`에서 탐색/저장을 호출하지 않는다. router도 현재 `/onboarding`을 profile 갱신으로 이동시키지 않는다.
- 검색어 입력 후 학교를 확정하지 않아도 하단 `다음`이 활성되어 다음 단계로 이동하는 경로를 실패 테스트로 재현했다. 이는 검색 버튼 자체 이동과 동일한 재현이라고 주장하지 않는다.
- 공용 picker에 선택적 pending callback 추가. 온보딩만 이를 사용해 검색어 입력·검색 중·빈 결과·검색 오류에서 앞으로 이동을 차단한다. 결과 임시 선택 후 기존 학교명 확인 CTA로 저장한다.
- 미입력/입력 삭제 시 선택 정보 없이 진행 및 명시적 건너뛰기 정책 유지. 이전 이동·계정 변경 시 pending 초기화. MY 저장/API 계약 변경 없음.
- 새 테스트: 미확정 검색어 이동 차단(수정 전 FAIL), pending/빈 결과 및 명시적 skip, iPhone428×926/keyboard336 조건의 키보드 검색·화면 검색 버튼 후 확인 전 저장0/학교 단계 유지.
- 전체1359PASS/7SKIP(추가 화면 버튼 테스트 이전 실행), 최종 집중30PASS, Analyze PASS. 화면 버튼 테스트 최초 실패는 lazy ListView에서 스크롤된 제목을 조회한 테스트 문제였으며 viewport 복원 후 확인하도록 정정했다. 실제 검색 버튼에 의한 단계 이탈은 자동 검사에서 미재현.
- 로그 `/tmp/app-review-school-{repro,focused-final,full,analyze}.log`. 신규 회원 생성/기존 profile 초기화/운영 SQL 없이 fake repository widget 검사.
- Owner에게 이동 목적지(홈/다음 온보딩/검색창 닫힘)와 검색어 입력·선택 여부를 질문했다. 답변 및 수정본 실기기 검수 전 incident 해결 PASS 금지. Release 수정본 준비, Store HOLD.

### 보존 검토

기존 [상위 전략](longitudinal-learning-admissions-data-strategy.md#preservation-and-architecture-review) 및 V2 정책 유지: (1) 새 시점/사실 수집 없음, (2) 기존 답안·학습 원본 불변, (3) UI 임시 상태만 추가하며 프로필 UPDATE payload/history 변경 없음, (4) 기존 owner guard 유지, (5) 자기보고 프로필을 학습/입시 결과와 합치지 않음, (6) 새 개인정보/권한/retention 없음, (7) 미설정 학교 추정·backfill 및 미확정 결과 자동 저장 없음.


### Owner 화면 근거·배치 수정 및 후속 검수 — 2026-11-03

Owner 설명과 `/Users/woojinchang/Desktop/IMG_1336.PNG`에서 학년 선택4개가 각 전체 너비로 세로 배치되어 있고, 키보드 위 고정 `다음`이 학교 입력 바로 아래에 표시되는 것을 확인했다. 실제 검색 버튼은 아래 스크롤 영역에 있어 검색 대신 `다음`을 누르는 동선이었다. 검색 네트워크가 자동으로 단계를 이동시킨 사건이 아니다. `AnimatedContainer(alignment: center)`가 Wrap의 가용 폭으로 늘어나는 코드와 화면이 일치한다. 기존 전체 학교 누락 통계의 원인까지 입증한 것은 아니다. Owner 원본 사진은 Git에 추가하지 않았다.

Owner의 한 줄 학년·입력창 내 검색 제안을 적용했다. 학년 라벨+1/2/3학년을 Row/Expanded로 배치, 선택한 학년을 다시 누르면 미설정으로 돌아가 선택권을 유지한다. 학교를 바로 아래에 두고 온보딩 picker만 `inlineSearch`로 입력창 오른쪽에 검색을 표시한다. 기존 MY picker 배치는 유지한다. 학교 단계에서 키보드가 열린 동안 하단 다음/이전/건너뛰기 footer를 숨겨 입력창 검색과 혼동하지 않게 했다. 키보드 닫힘 후 선택 학교명 확인 CTA 또는 명시적 건너뛰기를 사용한다. 앞선 pending 이동 차단도 유지한다. 수리 UX/전역 디자인 변경 없음.

- 집중32PASS: iPhone428×926·360폭/글씨200%에서 학년3개 같은 y, 검색 버튼이 입력창 사각형 안, 키보드 동안 다음/skip 없음, 검색 후 확인 전 학교쓰기0.
- mock 화면 캡처2PASS: `/private/tmp/legendstudy-core-ui/school-{compact,keyboard,result}-{1.0,2.0}.png`. 실기기 스크린샷/OS 키보드 이미지가 아니며 widget viewInsets를 사용한 렌더 검사다.
- Owner는 기존42에서 “안내·홈 복귀·계정 및 프로필 유지 정상”, “학교·학년 유지, 학교 미설정 안내 사라짐” 응답. 안내 흐름 및 MY 실제 학교 저장→재실행 복원·카드 갱신 **Owner 관찰 PASS**. 설정 메뉴에 안내 진입이 없다고 한 에이전트 설명은 철회했다. `/app-guide` route는 있으나 사용한 정확한 진입 위치는 미확인이다.
- 신규 온보딩 수정 화면의 실기기 확인은 별도 대기. 신규 계정/기존 profile 초기화는 수행하지 않는다.
- 방어 수정만 있던44 빌드는 새 배치가 없어 검수 대상에서 제외. 새45 Release로 준비하며 기존42 실기기 PASS를 새45 전체 PASS로 자동 이전하지 않는다.

최종 배치 수정 후 전체 Flutter1362PASS/7SKIP·Analyze PASS. 이전1359/집중32/렌더2와 실행 범위를 구분한다.


### Release45 빌드·설치 마감 — 2026-11-03

- A 기능 소스 `f5c6da4`, B 동일 수정 `1189dc7`. B current-status 충돌1건은 B 기존 통합/HOLD 기록과 A 최신 QA를 함께 보존하여 해결.
- A 전체1362PASS/7SKIP, Analyze PASS, 집중32PASS·mock렌더2PASS. B 온보딩/학교/MY 집중47PASS; 이전 B 전체1383은 수정 전 결과이므로 구분한다.
- A iOS1.0.1(45) signed Release Archive/App Store IPA·기기용 export PASS, codesign deep/strict PASS, iPhone12ProMax provisioning/AOT 포함 확인. 실제 binary에 Supabase URL/publishable·Google server/iOS ID 포함을 값 출력 없이 검사.
- Android1.0.1(45) AAB PASS(95.5MB), jarsigner verify PASS. Android 실기기 설치는 미실시.
- iPhone12ProMax `com.legendstudy.app` 업데이트 설치·실행 PASS. 앱 삭제·프로필 초기화 없음. 기존 `/onboarding` route에 custom-scheme URL을 전달했으나 실제 열린 화면과 수정 UI는 Owner 확인 대기. URL launch 성공을 route/UI 성공으로 간주하지 않는다.
- private 산출물 `candidate-a/release45/`, Store IPA SHA256 `2bbebbc720a77f9364cfb8540908035d92a9bb9f6ffddb815dc1a0568965a09f`, 기기 IPA `06727721db270a9a0cfcb05399d5c6cfca6c553dfd9e9fa7ea13b94cb52f6d7b`, AAB `454bbcd0f7291790a21fa8cd8904e28d7ee45c15536c77aaacf1406a2e2070a6`.
- 로그 `/tmp/app-review-a45-{ios,android,device-export,android-signature}.log`, 테스트 `/tmp/app-review-school-layout-{tests,full,analyze}.log`, B `/tmp/app-review-b-school-layout-focused.log`. Private logs에 사본 보관, 기존42/44 산출물 보존.
- 후보 A DEVICE_QA_PENDING, B BETA_HOLD, Store HOLD. 운영 DB/Auth 설정/Credit/Ledger/결제/WEB 변경·Store 업로드0.


## 관심 대학 검색 동선 후속 — 2026-11-03

Owner가 A45 실기기에서 “학교 검색 잘 되었음”을 확인했다. 학교 검색 정상 **Owner 관찰 PASS**로 기록하며 신규 온보딩 전체 저장/완료 PASS로 확대하지 않는다. 이어 관심 대학에서도 `[대학 이름 [검색]]` 형태를 요청했고 하단 `나중에 설정할게요`를 무의식적으로 누르는 문제를 보고했다. 기존 학교 검색 분리 정책의 동일 적용이다.

- 공용 `InterestedUniversitiesField` 입력창 오른쪽에 검색 버튼 추가. 키보드 검색과 기존 `_runSearch`/검색 provider를 재사용한다. 입력 변경 시 버튼 상태 갱신, 빈 입력/저장 중/최대 개수/관심 목록 로딩·오류에서는 비활성. 동일 검색어 재검색에서도 키보드는 닫힌다.
- 온보딩 관심 대학 단계도 키보드 동안 footer 숨김. 미검색 입력이 있으면 앞으로 이동을 차단하고 입력창 검색 안내. 검색 실행/입력 삭제 시 잠금 해제; 실제 선택은 기존 결과 행 탭으로만 저장한다. 검색으로 임의 저장/자동 선택하지 않는다. 기존 관심0개 허용·명시적 skip·최대개수·source/priority/학과·MY 저장 계약 유지.
- 집중42PASS: 입력창 안 검색 버튼, 검색만으로 쓰기0·명시 선택 시 쓰기1, 기존 관심 편집/삭제/계정계약, 428/360폭·글씨100/200% 키보드 footer숨김·미검색 CTA차단·검색이동없음/선택안하고 다음 허용. fake repository 검사이며 실기기 대학 검색 수정본은 대기.
- 변경: onboarding_page.dart, interested_universities_field.dart, onboarding_page_test.dart, first_run_personalization_test.dart 및 Wiki. 새46 빌드 준비. 45학교 PASS와46대학 미검증을 구분한다.

보존 검토7항목: (1) 새 발생/기록 시점 없음, (2) 학교·학습 원본 불변, (3) 관심 대학 기존 저장 payload·이력 변경 없음/UI pending만 추가, (4) 동일 owner/provider 사용, (5) 관심은 실제 지원/합격 결과와 구분, (6) 새 수집·권한·보존기간 없음, (7) 검색 결과를 자동 선택/실제 관심으로 추정해 저장하지 않음. 기존 [관심 대학 계약](personalization-onboarding.md)·[상위 보존 원칙](longitudinal-learning-admissions-data-strategy.md#preservation-and-architecture-review) 유지. 운영 설정/DB/Credit/Store 변경 없음.

최종검사: 전체1365PASS/7SKIP, Analyze PASS, 집중42PASS, mock 렌더2PASS(100/200%). `/private/tmp/legendstudy-core-ui/university-{keyboard,result}-{1.0,2.0}.png` 시각 확인: 입력창 내 검색·키보드 때 footer없음. 렌더 첫 실행은 전체 검사와 native PDFium 산출물 경합으로 실패했고 순차 재실행 PASS; 코드 오류와 구분.


### Release46 관심 대학 수정본 설치 — 2026-11-03

A 기능 소스 `9092d4e`, B `d528a62`에 동일 수정 포함. A전체1365PASS/7SKIP·Analyze PASS·집중42PASS·mock렌더2PASS, B집중42PASS. A iOS1.0.1(46) signed Release Archive/App Store IPA·기기 export·codesign PASS, Android46 signed AAB95.4MB·jarsigner PASS. iOS 실제 AOT에 기존 Supabase URL/publishable·Google server/iOS ID 포함을 값 출력 없이 확인. 새 키/권한/환경 변경 없음.

iPhone12ProMax 업데이트 설치/실행 PASS. 기존 onboarding route 열기를 요청하고 Owner에게 대학 검색·선택→전공→완료→MY·재실행 정보 유지 검수를 요청했다. 46 실제 화면/저장 검수는 답변 대기이며 설치 성공만으로 UI PASS를 선언하지 않는다. 앱 삭제·신규 계정 생성·profile 초기화·Store 업로드 없음.

private `candidate-a/release46/`: Store IPA SHA256 `7003ecd0aec0c35a285112b70ccaaf146697b87121aab40c12809481e3991d83`, device IPA `38b9d7fecd8f66258f9c323d8d0a55fe8f22a2c8764ac963b69473a896122427`, AAB `fa0e201ad49f9c9ff1498df2b40b3fdada2e32e84e03430562a09323e1ad2786`. `/tmp/app-review-a46-*.log`, `/tmp/app-review-university-*.log`, `/tmp/app-review-b-university-focused.log`를 private logs에 보존. 기존45/APP41 산출물 보존. 후보 A Owner 검수/Store HOLD, 후보 B 베타 HOLD 유지.


### A46 온보딩 전체 흐름 Owner PASS·닉네임 제안 — 2026-11-03

Owner는 A46 대학 입력창 검색/키보드 footer숨김→대학 선택→희망 전공→설정 완료→MY·완전 종료/재실행 후 학교·학년·대학·전공 유지 질문에 “1)pass.”로 답했다. 해당 기기·계정에서 요청한 흐름 **Owner 관찰 PASS**. 같은 응답이 두 메시지로 전달됐으며 독립된 두 차례 검증으로 세지 않는다. 새46에서 다른 모든 Provider 신규 가입/다른 기기/Store 심사까지 PASS로 확대하지 않는다.

Owner는 마지막 닉네임 온보딩 추가의 적절성을 질문했다. 제안 검토이며 아직 신규 코드 구현/빌드 또는 필수 입력 정책 확정이 아니다. 기존 [프로필 닉네임](core-app-improvements.md)과 [향후 커뮤니티 identity](product-platform-boundaries.md)에 따르면 `profiles.display_name`은 직접 입력하는 선택형·중복 허용 닉네임이며 MY 편집/저장/홈 표시가 이미 있다. 커뮤니티 작성자는 같은 닉네임을 재사용할 계획이나 공개 조회/API·게시판은 현재 제공 기능이 아니다. 권고: 전공 다음 마지막 선택 단계, 기존 이름 복원·변경분만 기존 저장 계약으로 저장, 저장 성공 후 완료, 건너뛰기 시 기존 이름 보존, MY에서 변경 가능. 새 DB/중복 확인/커뮤니티 구현은 이번 제안에 포함하지 않는다.


### 마지막 선택형 닉네임 승인·구현 — 2026-11-03

Owner가 전공 다음 마지막 선택형 닉네임 단계 추가, 기존 저장 기능 재사용, 테스트·정식 빌드·iPhone 설치 및 실기기 검수 계속을 승인했다. 앞선 제안 상태를 대체한다. 운영 DB 변경·Store 제출은 금지한다.

- 기존 4단계 뒤 5단계 닉네임 추가. 기존 이름을 복원하고, 빈 입력/나중에 설정하기/변경 없는 이름은 닉네임을 쓰거나 삭제하지 않는다. 명시적으로 입력한 변경분만 기존 `upsertCurrentProfile(displayName:)`로 저장한다. 저장 성공 후 기존 온보딩 완료 처리를 한다. MY에서 계속 변경 가능.
- MY와 온보딩의 기존 1~80 rune·제어문자 금지 검증을 공용 helper로 재사용한다. 중복 허용·선택형 유지. 기존 저장 payload/DB/API/권한 변경 없음. 사회 로그인 이름 자동 복사, 닉네임 중복 확인, 커뮤니티 공개/API 구현은 추가하지 않았다.
- 저장 실패 시 입력 유지·재시도; 닉네임 저장 후 완료 기록만 실패하면 재시도 시 닉네임 중복 저장 없음. 중복 탭 방지·계정 전환 owner guard 유지. 키보드 닫기 제공. 작은 폭/큰 글씨에서 마지막 보조 버튼이 줄바꿈되도록 footer 조정.
- 변경 파일: `onboarding_page.dart`, `profile_edit_page.dart`, 신규 `nickname_validation.dart`, `onboarding_page_test.dart` 및 Wiki. fake repository 집중63PASS: 빈값/skip/기존값 보존, 실패/재시도/중복 탭/계정 전환, 키보드100/200%, 잘못된 입력 차단. 초기 360폭·글씨200% footer overflow를 재현 후 수정했으며 최종 집중 검사 통과. 전체 회귀·Release47 빌드 및 실기기 결과는 후속 기록한다.

보존 검토7항목: (1) 새 사건/시점 수집 없음, (2) 기존 학습/답안 사실 불변, (3) 기존 자기보고 현재 닉네임 필드만 기존 sparse 저장 경로로 갱신·이력 생성 없음, (4) 동일 로그인 owner guard, (5) 닉네임을 실제 성명·지원·합격 사실로 추정하지 않음, (6) 새 개인정보 종류/공개 권한/보존기간 없음, (7) 빈값·skip을 삭제/추정 backfill로 해석하지 않음. [기존 닉네임 정책](core-app-improvements.md), [플랫폼 경계](product-platform-boundaries.md), [보존 전략](longitudinal-learning-admissions-data-strategy.md#preservation-and-architecture-review)을 계승한다.

최종 로컬 검증: 전체 Flutter **1375PASS/7SKIP**, Analyze PASS, 집중63PASS, mock 키보드 렌더2PASS(100/200%). 로그 `/tmp/app-review-nickname-{all,analyze,focused,render}.log`; 화면 `/private/tmp/legendstudy-core-ui/nickname-keyboard-{1.0,2.0}.png`. OS 키보드/실기기 캡처가 아닌 widget viewInsets 검사다. mock 캡처의 명시적 버튼 TextStyle은 테스트 기본 폰트 때문에 한글이 사각 문자로 표시되는 한계가 있다. 버튼 문구·터치·layout은 widget assertions로 검증했으며 실제 글리프 표시는 Owner 기기에서 확인한다. 제품 폰트는 변경하지 않았다. Release47 및 Owner 실제 저장 검수 대기.


### Release47 닉네임 온보딩 빌드·설치 — 2026-11-03

- 기능 소스 A `a14a23c`, B `541a335`. B에도 동일 수정 병합, 집중63PASS. A 전체1375PASS/7SKIP·Analyze PASS·집중63PASS·mock렌더2PASS. B 이전 전체1383은 이번 닉네임 변경 전 검사이므로 구분한다.
- A iOS1.0.1(47) signed Release Archive/App Store IPA 및 같은 Archive의 기기 export PASS. Android47 AAB95.5MB·jarsigner PASS. codesign deep/strict·기기 provisioning·Release AOT PASS. 실제 iOS binary에 기존 Supabase URL/publishable·Google server/iOS ID 포함을 값 출력 없이 검증.
- iPhone12ProMax `com.legendstudy.app` 업데이트 설치·실행 PASS, 기존 `/onboarding` URL 전달. 앱 삭제·계정/profile 초기화 없음. 실제 열린 화면 및 닉네임 입력→저장→홈/MY→완전 종료·재실행 복원은 Owner 응답 대기. 설치/launch 성공을 실제 UI·저장 PASS로 확대하지 않는다.
- private `candidate-a/release47/`: Store IPA SHA256 `d5470af6dab1ef90bb289c8ef9a2c72b6fed4386e1d44f364e1e60f08e89af55`, 기기 IPA `4a23f77c75777e434d61ee3c55cf457a3f974eaf19a030a819e7a4f4a58f5d98`, AAB `0fc90734662ee02f5ef7597210e2c8d077727cfe6234d8c230512e8467bd9520`. Archive/로그 private 보존. 기존46/APP41 산출물 보존.
- 로그 `/tmp/app-review-a47-{ios,android,device-export,android-signature}.log`, `/tmp/app-review-nickname-{all,analyze,focused,render}.log`, `/tmp/app-review-b-nickname-focused.log`. Wiki handoff/link 검사 A/B PASS.
- 후보 A 닉네임 DEVICE_QA_PENDING, B BETA_HOLD·운영 활성화 HOLD. 운영 DB/Auth 설정/Credit/Ledger/결제/WEB 변경 및 Store 업로드/제출 없음. APP41 HEAD `367bfab`와 기존 dirty Xcode 파일/untracked supabase temp 그대로 보존 확인.


### A47 진행 문제 보고·재빌드 요청 — 2026-11-03

Owner가 닉네임 검수에 “진행 문제 있음 재빌드”로 응답했다. 기기 설치 목록으로 1.0.1(47)을 확인했고 온보딩/프로필 집중63PASS를 재확인했다. 구체적인 실패 화면/오류는 아직 식별하지 못했으므로 닉네임 실기기 검수는 PASS가 아니다. Owner 후속 “db에서 아이디 삭제 후 다시 진행”은 이미 직접 삭제했는지 또는 삭제 요청인지·대상 환경/계정이 불명확하여 확인 중이며 에이전트는 계정을 삭제/초기화하지 않았다. 기존 `/onboarding` 경로는 계정 삭제 없이 재진입 가능하다.

Owner 요청에 따라 동일 기능 소스를 iOS1.0.1(48) Release로 재빌드한다. 원인 확인 전 임의 기능 변경/DB/Auth 변경은 하지 않는다. 재빌드 자체를 오류 해결로 간주하지 않으며 설치 후 실제 진입/저장 검수가 필요하다. Android47 및 기존1375PASS/7SKIP·Analyze 결과는 기능 소스가 같은 기존 증거로 유지한다.

Owner는 후속 선택지2(“내가 이미 계정을 삭제했음”)로 확인했다. Owner 직접 삭제 신고이며 실제 삭제 범위/DB 상태를 에이전트가 검증한 것은 아니다. 에이전트 추가 삭제/초기화 없음. 48 설치 후 이전 세션이 남으면 Owner 로그아웃→의도한 로그인 방식으로 재로그인/가입→온보딩 검수한다. 기존 계정의 정보 보존 테스트와 새 계정 온보딩 테스트를 혼동하지 않는다.


### Release48 재빌드·재로그인 검수 — 2026-11-03

- 앱 기능 소스는47의 `a14a23c`와 동일(재빌드 기준 A HEAD `b2eb647`). 실패 증상 미확정으로 임의 코드 변경 없음. 온보딩/프로필 집중63PASS 재확인. 전체1375PASS/7SKIP·Analyze는 동일 기능 소스의47 결과를 재사용한다.
- iOS1.0.1(48) signed Release Archive/App Store IPA·기기 export PASS. provisioning/AOT/codesign deep-strict PASS, 실제 binary 기존 Supabase/Google 인증 설정 포함 확인(값 미출력). Android는 동일 기능의47 AAB를 유지하며 이번 iPhone 재검수에서 재빌드하지 않았다.
- iPhone12ProMax 업데이트 설치·실행 후 설치 목록에서 build48 확인. `/auth` URL로 로그인 화면 열기 요청. Owner 직접 계정 삭제 신고에 따라 재로그인→신규 온보딩→닉네임 저장→홈/MY→재실행을 요청했다. 화면/저장 확인은 응답 대기, 원인/해결 및 실기기 PASS 미확정.
- private `candidate-a/release48/` Archive/로그/IPA 보존. Store IPA SHA256 `8fb1ce106ea477a60a0743e5bde4ff5c76869bba77f76f639cd8f2efdb546925`, device IPA `d18ab6203d4978f28bf9821de6d09aac305ce802ceafdbc60b7e3e993b8de590`. 로그 `/tmp/app-review-a48-{ios,device-export,preflight-tests}.log`.
- 에이전트 운영 DB/Auth 설정/계정 삭제·초기화/Credit/Ledger/결제/WEB/Store 변경 없음. 기존 APP41 및47 산출물 보존. 후보 A DEVICE_QA_PENDING, 후보 B 베타/운영 HOLD 유지.


### A48 온보딩·닉네임 실기기 Owner PASS — 2026-11-03

Owner는 iPhone12ProMax Release1.0.1(48) 재로그인 후 상태→학교/학년→관심 대학→전공→닉네임 저장→홈/MY→완전 종료·재실행 확인 요청에 “온보딩·닉네임 저장·재실행 모두 정상”으로 응답했다. 요청한 온보딩 및 닉네임 저장/표시·재실행 유지 흐름을 해당 기기·계정의 **Owner 관찰 PASS**로 기록한다. 직후 Owner가 로그인 방식 질문의 선택지1(Apple 로그인)을 확인했다. 따라서 해당 A48 로그인·온보딩·닉네임 저장 및 재실행 흐름을 Apple 경로로 식별한다. 서버 Auth identity 생성/삭제 상태를 독립 검증한 것은 아니다.

A47 진행 문제의 원인은 확인되지 않았으며48은 동일 코드 재빌드다. Owner 직접 계정 삭제 후 다시 수행한 흐름의 성공이고, 재빌드가 A47 문제를 코드 수정으로 해결했다거나 삭제 전 기록 보존을 검증했다고 주장하지 않는다. 현재 닉네임 진행 차단은 재보고되지 않았다. 코드/빌드 변경 없이 검수 기록만 갱신했다.

| 구분 | 확인 상태 / 다음 범위 |
|---|---|
| 온보딩 학교·대학 검색 / 닉네임 저장·재실행 | A45/46/48 Owner PASS. 불필요한 재검수 없음 |
| Kakao 취소·재시도·홈 복귀·세션 / 이메일 오류·재시도 | A42 Owner PASS. 기능 변경 없음, 기존 결과 재사용 |
| Apple 로그인·온보딩·닉네임·재실행 | A48 Owner PASS. Apple 취소/재시도 및 Auth 신규 identity 생성의 독립 확인과 구분 |
| Google 취소·재시도·홈/MY·세션 | Owner “Google도 모두 정상 확인함”으로 해당 흐름 PASS. 기존 확인 결과 재사용; 실행한 정확한 빌드/시각은 이번 응답에 미명시 |
| 기존 PDF·인문논술 History·결과 조회 | A42 Owner PASS. 신규 평가/차감 E2E와 구분 |
| Android/iPad 실제 기기 | 미검증; 빌드/위젯 검사와 구분 |
| 후보 B 수리·상경 / 운영·스토어 | 기존 BETA_HOLD 및 별도 Owner 승인 유지 |

기존 전체1375PASS/7SKIP·Analyze, 집중63PASS·iOS48/Android47 서명 빌드 증거 재사용. 에이전트 DB/Auth 설정/계정 삭제/운영/Store 변경 없음.

Owner 후속 “1”은 Apple 로그인 선택지를 가리킨다. A48 PASS의 Provider를 확정했으며 다른 Provider 결과로 확대하지 않는다. 다음은 기존 Google 계정 취소→재시도→홈/MY→재실행 범위의 기존 확인 여부를 구분한다. 계정 삭제·신규 가입은 재검수 조건으로 요구하지 않는다.


### Google 기존 계정 인증 검수 Owner PASS — 2026-11-03

Owner는 Google 기존 계정의 인증 취소→재시도→홈/MY 확인→앱 완전 종료·재실행 후 계정 유지 범위를 묻는 질문에 “Google도 모두 정상 확인함”으로 응답했다. 해당 Google 인증·계정 표시·세션 유지 흐름 **Owner 관찰 PASS**. 이미 수행한 검수 결과를 재사용하며 새 호출/계정 삭제/가입/재빌드를 하지 않았다. 실행한 정확한 빌드와 시각은 미명시이므로 새48에서 별도로 다시 실행했다고 추정하지 않는다.

현재 확인된 실기기 범위: Kakao 시스템 인증 취소/재시도/복귀·세션, 이메일 기존 로그인·오입력 방어/재시도·세션, Apple48 온보딩·닉네임 저장·재실행, Google 기존 인증·세션, 학교/대학 검색·프로필 유지 및 기존 PDF/인문 결과 조회. 이 흐름은 중복 검수하지 않는다. 별도 미확인 범위는 Provider별 신규 가입의 상세 경우, Apple 취소/재시도, Android/iPad 실제 기기, 후보 B 수리·상경 전체 기기 흐름이다. 전체 릴리스/운영 활성화 및 Store 제출 승인으로 확대하지 않는다.

이번 변경은 Wiki 검수 결과 갱신만이며 기존 자동 테스트/빌드 결과를 재사용한다. 운영 DB/Auth/Credit/Ledger/결제·WEB·APP41·Store 변경 없음.


## 후보 A 보고서·B 검수 시작 — 2026-11-03

Owner 요청으로 [ChatGPT 전달용 A 검수 보고서](app-candidate-a-owner-qa-report-20261103.md)를 분리했다. B는 [TEST49 실기기·WEB 검수 기록](app-candidate-b-device-web-qa-20261103.md)에 설치/격리/자동1402PASS/저장 결과 UI/미완료 및 Owner 경로를 기록한다. 기존 PASS를 재호출하지 않으며 A 수용이 B 출시·운영 승인을 뜻하지 않는다.
