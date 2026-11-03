# APP Release Integration — 2026-11-03

상태: **후보 A BUILD_PASS / DEVICE_QA_PENDING; 후보 B INTEGRATING; STORE_HOLD**.
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
후보 A 실제 기기 검수는 기존 서비스 인증 설정으로 수행하며 **Owner가 이번 설치를 보류하고 빌드·통합 계속을 선택함**. 직접 설치용 export는 준비했으나 설치하지 않았다.
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
후보 B 추가 통합·검증 내용은 B 브랜치의 본 문서에 이어 기록한다.
