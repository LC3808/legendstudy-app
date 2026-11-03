# Kakao iOS 시스템 인증 세션 — 2026-11-03

상태: **IMPLEMENTED / OWNER_REVIEW_REQUIRED / 릴리스 미통합·미배포**.
별도 `codex/kakao-ios-system-auth`, 기준 `30edf235`. APP 1.0.1(41) 보존.
기존 [Native Auth 계약](auth-native-owner-acceptance.md), [회복/세션](auth-recovery.md),
[41 빌드·Owner 로그인 확인](final-store-rc-1.md#task18-build41-owner-login-acceptance--2026-11-02)의 후속이다.

## 원인과 이전 수정의 차이

읽기 감사에서 보존된39/41 IPA SHA256이 기존 기록과 일치함을 확인했다.
39 `a0aa6184`와41 `03b73e2`의 인증 소스·의존성 잠금·추적된 iOS 설정은 동일하며,
실제 두 IPA의 URL scheme/Scene/지원기기도 같다. Google은 GoogleSignIn9.2/AppAuth2.1의
ASWebAuthenticationSession, Apple은 ASAuthorizationController, Kakao만 externalApplication이다.
Owner Google Safari 미실행 확인과 Apple의 외부 브라우저 지적은 모순되지 않는다.
Apple이 누른 실제 버튼은 확인되지 않았고 exact review 기기 재현은 하지 못했다.

2026-09-22 `2f414b0`는 로그인 성공 후 **SFSafariViewController가 닫히지 않아**
Home을 가리는 문제를 externalApplication으로 우회했다. 이번에는 platformDefault/inAppBrowserView로
롤백하지 않는다. **ASWebAuthenticationSession이 콜백 수신 시 인증창 종료를 관리**한다.
외부 Safari/기본 브라우저 fallback을 추가하지 않는다.

## 구현 경로와 보존 계약

1. iOS Kakao만 기존 Supabase `getOAuthSignInUrl`로 URL/PKCE challenge·verifier 생성.
2. 기존 `scope=account_email`, 기존 `com.legendstudy.app://login-callback` 유지.
3. MethodChannel → Swift ASWebAuthenticationSession. foreground active key window를 presentation anchor로 사용하여 iPhone/iPad 동일 경로 적용.
4. 시스템 callback 반환 후 scheme/host/path/port/userinfo/fragment/단일 code/error를 검증.
5. Supabase `exchangeCodeForSession`을 1회 호출. SDK가 session 저장·signedIn 이벤트를 발생시키고 기존 UI/지속 저장 구독자가 처리.

콜백은 시스템 인증 세션이 소비한다. app_links에 수동 전달하거나 getSessionFromUrl을 중복 호출하지 않는다.
Google·Apple·이메일과 Android Kakao의 기존 경로는 유지한다. 새로운 Provider/토큰 저장소/서버 교환 구현 없음.
Supabase redirect allow-list/Provider 설정/DB/Auth/Credit/결제/서명·bundle 설정 변경 없음.

- 서비스 busy + 프로세스 내 Kakao guard로 provider 재생성 시에도 두 번째 PKCE 생성 차단.
- Swift도 세션을 강하게 보유하고 중복 요청 거절. 완료/취소/시작 실패 후 해제, 늦은 이전 callback은 generation으로 무시.
- 취소는 기존 `NativeAuthCancelled` 안내로 연결, 오류 후 재시도 가능.
- 인증 URL 생성 뒤와 callback 뒤 계정 변경 검사; 이전 계정 요청의 code 교환 차단.
- callback URL/code/token/error 원문을 로그나 UI에 출력하지 않는다.
- 새 회원/기존 회원의 판정·생성은 기존 Supabase/Kakao 계약 그대로다. 앱이 별도 계정을 만들거나 병합하지 않는다.
- 실제 로그인된 기기에서 앱 강제 종료 시 완료되지 않은 인증은 완료로 간주하지 않는다. 성공 후 세션 복원은 기존 SDK에 맡긴다.

공식 근거: [Apple 시스템 인증 세션](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession).
API 동작은 설치된 supabase_flutter2.15.4/gotrue2.25.0 소스에서 확인했다. Changelog 조회 후 SDK 업그레이드 없이 기존 잠금 버전을 사용한다.

## 자동 검증

- 인증 집중 테스트 **53 PASS**: 시스템 URL/PKCE·1회 exchange/signedIn, 중복 요청,
  cancel/start 실패 후 재시도, 잘못된 callback 차단, 교환 실패, 계정 변경, 기존 Google/Apple/이메일/SDK 저장 복원.
- 신규 테스트는 Mock HTTP/MethodChannel만 사용. 운영 인증·회원 생성 요청 없음.
- 전체 Flutter: **1,356 PASS / 7 SKIP**, `./tool/flutterw test --no-pub`.
- 정적 분석: 동일 Flutter3.47.6 SDK `dart analyze lib test`, **No issues found**. 기존 flutter analyze LSP 실행 오류와 구분.
- iOS: **profile/no-codesign compile PASS**, 1.0.2(42), `build/ios/iphoneos/Runner.app` 51.4MB. 서명/설치/업로드 없음.
- Wiki handoff/diff check PASS, current-status 11,939 bytes.
- 로그 `/tmp/kakao-system-auth-test.log`, `/tmp/kakao-system-auth-full.log`, `/tmp/kakao-system-auth-analyze.log`, `/tmp/kakao-system-auth-ios.log`.
- 기존 flutter_tts SPM 경고 유지. Android 경로는 기존 테스트로 확인했으며 이번 iOS 전용 변경의 Android 신규 빌드는 하지 않았다.
- 자동 검증은 실제 Kakao 화면 종료·앱 foreground·기기 Keychain/UserDefaults 복원 결과가 아니다.

## 실기기 결과와 Owner 검수

**이번 실기기 로그인/신규가입/취소/앱복귀/재실행은 NOT_RUN.** APP41 설치를 덮어쓰지 않았다.
연결 조회상 iPhone12ProMax paired, 심사 iPhone17ProMax unavailable, 해당 iPad Air 실기기 없음.
Owner 검수 전까지 성공/심사 적합성을 확정하지 않는다.

서명된 다음 검수 빌드를 승인된 배포 경로로 예비 기기에 전달하고 버전/빌드 번호를 기록한다.
기존 APP41을 보존할 기기 분리가 우선이다. unsigned profile 산출물은 직접 설치 가능한 IPA가 아니다.

| 검수 | 확인할 실제 결과 |
| --- | --- |
| 기존 Kakao | 로그인 버튼 → 시스템 인증 UI → 승인 → 창 자동 종료 → Home/MY, 별도 Safari 앱 전환 없음 |
| 신규 Kakao | 신규 테스트 계정 동의 → 앱 복귀 → 기존 온보딩 진입·Supabase 세션; 다른 계정과 병합 없음 |
| 취소 | OS 취소/닫기 → 앱 로그인 화면·취소 안내·버튼 재사용 가능 |
| 실패/재시도 | 네트워크 끊김 또는 인증 실패 후 허위 로그인 없음, 복구 후 새 요청 성공 |
| 앱 복귀 | 성공 시 X를 수동으로 닫을 필요 없음, iPhone·iPad 각각 확인 |
| 세션 생성 | 기존 MY 로그인 상태/서버 인증 읽기 성공, 브라우저 닫힘만으로 합격 처리 금지 |
| 재실행 유지 | 성공 후 강제 종료/다시 실행 → 같은 계정 유지 |
| 중복 요청 | 빠른 연속 탭 → 인증창1개·계정1개, 취소 뒤 재시도 |
| 기존 로그인 회귀 | Google·Apple·이메일 로그인/취소, 기존 계정 유지 |

가능하면 Kakao 앱 설치 유무와 기본 브라우저 Safari/타 브라우저를 구분해 촬영한다.
Provider 페이지 내부 외부 링크/앱 전환까지 코드 검증만으로 단정하지 않는다.
로그인 화면부터 앱 복귀까지 녹화하고 민감한 이메일/인증번호는 공유본에서 가린다.

## 변경 파일 및 릴리스 통합

- `ios/Runner/AppDelegate.swift`: 시스템 세션 bridge/수명/anchor/취소.
- `lib/features/auth/ios_web_auth_session.dart`: channel 및 취소 매핑.
- `lib/features/auth/auth_oauth.dart`: iOS Kakao PKCE 생성·검증·교환·중복 방지.
- `lib/features/auth/presentation/auth_page.dart`: 반환 의미 설명 주석 갱신(동작 동일).
- `test/ios_kakao_auth_test.dart`: iOS 세션 계약 검사.
- `test/kakao_oauth_scope_test.dart`: 기존 Android browser 계약 유지 (iOS는 신규 검사로 대체).
- Wiki 본 문서·native acceptance·index·current-status·decisions·log.

최종 SHA는 완료 응답/Git 로그 참조. 원격 push/릴리스 merge/배포/Store 제출 없음.
브랜치에는 앞선 온보딩/MY 개발 이력이 있으므로 **브랜치 전체를 무조건 merge하지 않는다**.
Owner 실제 기기 합격 후 다음 릴리스 브랜치에서 이번 단일 커밋을 cherry-pick하고,
승인된 온보딩 변경 포함 여부는 별도로 결정한다. 다른 수리·상경 미검증 변경을 섞지 않는다.
통합 상태에서 인증/전체 회귀와 signed Release 빌드를 다시 검증하고 Store 번호 중복을 확인한다.
현재 로컬 후보1.0.2(42)는 미예약 번호이며 APP41을 교체/업로드하지 않는다.
롤백은 이번 commit만 되돌린 다음 후보를 새 번호로 빌드하는 방식이며 운영 데이터 rollback은 없다.
