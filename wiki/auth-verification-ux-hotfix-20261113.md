# 로그인 인증 안내 P0 hotfix — APP84 후보 / 2026-11-13

## 범위와 기준

Owner는 iOS 1.0.3(83)의 일반 로그인에서 인증 안내가 상시 노출되는 UX 수정을 요청했다. 운영 서버 장애는 복구됐고 기존 계정 로그인은 Owner 확인 사항이다. 이번 작업은 서버 복구가 아니다.

- 기준 main/원격 main: `9f533d29773a8f5c28b45904c079fc4fe37417a8` (작업 시작 시 fetch 대조).
- [APP83 배포 산출물](app83-store-handoff-20261112.md)의 제품 소스: `dbbb52e134d59beb8b57f5485b7d07e5a5b25596`. 이후 기준 main까지 문서만 변경.
- 기존 이메일 브랜치 `codex/email-auth-stabilization-20261111`의 `1eb8e1f`는 기준 main에 포함돼 있다. 상시 재발송 UI는 `c5cd349`에서 도입됐다.
- 독립 hotfix 브랜치: `codex/auth-verification-ux-hotfix-20261113`. 시작 작업 트리 clean, 다른 작업 변경 없음.
- [기존 인증 안정화](email-verification-audit-20261111.md), [SMTP 기록](email-smtp-provider-plan-20261111.md), [인증/온보딩 정책](onboarding-auth-routing-fix-20261111.md), [인증 복구 계약](auth-recovery.md)을 재사용한다.
- 운영 DB/RPC/Auth/SMTP·프로필/사용자 데이터·LAB/평가/과금/학습·학교 순위 변경0. 이번에는 운영 조회나 테스트 메일도 보내지 않았다.

## 실제 원인과 수정

`AuthPage`는 미인증 상태와 무관하게 `!_signUp`이면 재발송 버튼과 인증 안내를 렌더했다. `authErrorMessage`는 `AuthRetryableFetchException`, `TimeoutException`, `SocketException`을 모두 인터넷 문제로 매핑했다. 설치된 GoTrue 2.25.0은 HTTP 5xx도 `AuthRetryableFetchException`으로 전달하므로 서버 장애가 사용자 인터넷 문제로 표시될 수 있었다. 이메일 요청에는 UI 대기 시간 상한도 없었다.

수정은 기존 화면의 조건/상태와 오류 처리에 한정한다. 디자인, 폰트, 색상, 버튼 크기, OAuth/Deep Link/Redirect/세션 저장 계약을 변경하지 않는다.

| 상황 | 인증 안내 및 재발송 |
|---|---|
| 일반 로그인, 기존 인증 회원 | 기본 숨김 |
| 가입 응답에 세션 없음 | 입력 이메일에 연결된 인증 대기 안내, 기존 60초 재요청 제한 |
| 비밀번호 로그인에서 실제 `email_not_confirmed` 코드 | 인증 안내, 재발송 표시; 이메일/비밀번호 유지 |
| 오류 메시지 문자열에만 Email not confirmed 포함 | 추측하지 않고 일반 오류; 인증 안내 없음 |
| 잘못된 비밀번호·네트워크·5xx | 해당 오류만 표시; 미인증으로 추정하지 않음 |
| 이메일 변경·가입/로그인 모드 전환 | 이전 주소의 인증 상태 폐기 |
| 정상 로그인/SDK signedIn | 인증 안내/오류 제거, 기존 라우팅 재사용 |
| Google/Kakao/Apple 시작 | 이메일 인증 안내 제거, 기존 로그인/취소 처리 유지 |

미인증 판별은 SDK `AuthException.code == email_not_confirmed`와 정상적인 인증 거절 응답(400/403/422 또는 SDK status 없음)만 인정한다. 5xx와 문구만 있는 오류는 제외한다. 상태는 현재 화면 메모리의 주소에만 연결하며 토큰/비밀번호/새 사용자 저장소를 만들지 않는다. 가입 직후에는 기존처럼 비밀번호를 지우고 이메일을 보존한다.

| 실제 오류 | 사용자 안내 |
|---|---|
| invalid_credentials | 이메일 또는 비밀번호를 확인해 주세요. |
| email_not_confirmed | 이메일 인증이 필요합니다. 메일함을 확인해 주세요. |
| SocketException / 응답 없는 SDK transport 오류 | 인터넷 연결을 확인한 뒤 다시 시도해 주세요. |
| TimeoutException / HTTP 408·504 | 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요. |
| HTTP 500 이상(504 제외) | 현재 서비스 연결이 원활하지 않습니다. 잠시 후 다시 시도해 주세요. |

가입·로그인·재발송 UI 대기는 20초, 기존 로그인 후 프로필 보장 호출은 최대8초로 제한한다. timeout/failure는 finally에서 busy를 해제한다. SDK 네트워크 호출 자체를 취소하거나 세션을 삭제하지 않으며 늦은 signedIn 이벤트도 기존 라우팅 정책으로 수용한다. 프로필 호출의 UPDATE 내용·완료 marker는 그대로다. 재발송 60초 간격, 중복 요청 방지, 실제 전달을 보장하지 않는 성공 문구와 rate-limit 안내를 보존한다.

근거: [Supabase 오류 코드](https://supabase.com/docs/guides/auth/debugging/error-codes)와 설치된 `gotrue-2.25.0/lib/src/fetch.dart`, `supabase_flutter 2.15.4`. SDK 업그레이드 없이 기존 lock을 유지한다. [Flutter v3 공지](https://supabase.com/changelog/supabase-flutter-v3)는 별도 버전이며 이번 수정에 포함하지 않는다.

## 변경 파일

- `lib/features/auth/presentation/auth_page.dart`: 표시 조건·이메일별 UI 상태·대기 상한.
- `lib/features/auth/auth_errors.dart`: 실제 코드/status/예외에 따른 오류 분류.
- `test/auth_login_verification_ux_test.dart`: 새 UI/SDK 응답/timeout·재진입·소셜 회귀.
- `test/email_verification_test.dart`: 실제 미인증 응답 이후 재발송, 기존 cooldown/중복/PKCE 계약.
- `test/auth_recovery_test.dart`: 변경된 오류 카피/명시적 코드 기대값.
- Wiki: 본 문서, index/current-status/log/decisions/auth-recovery/기존 이메일 조사 후속 링크.

## 검증

- 전체 `tool/flutterw test --no-pub --reporter expanded`: **2601 PASS / 8 SKIP / 0 FAIL**, 94초. 기존2580 대비 새21개.
- `tool/flutterw analyze --no-pub`: **PASS**, 이슈0.
- 신규 테스트 작성 중 const 생성자/ellipsis 기대값/lifecycle fixture 순서를 보정했다. 최종 전체 실행 신규/기존 실패0. 기존 제품 결함으로 분류하거나 실패 테스트를 제외하지 않았다.
- `python3 tool/check_wiki_handoff.py`: **PASS**. 내부 링크/Task Routing 및 current-status 12KB 예산 검사.

| Owner 필수 시나리오 | 격리 검증 | 근거 |
|---|---|---|
| TEST01 기존 인증 회원 로그인·안내 숨김 | DONE | 새 UI 테스트 + 실제 SDK password contract |
| TEST02 가입 직후 인증 대기·재발송 | DONE | email_verification의 signup session 없음/60초/PKCE redirect |
| TEST03 미인증 계정만 안내 | DONE | 실제 GoTrue Mock HTTP400 email_not_confirmed + UI |
| TEST04 인증 후 재로그인 | DONE | 성공 재시도/늦은 signedIn 시 안내 제거·기존 라우팅 |
| TEST05 비밀번호 오류 | DONE | invalid_credentials400 + 입력 유지·안내 숨김 |
| TEST06 네트워크 장애 | DONE | SocketException·재시도 가능·중복 요청 차단 |
| TEST07 서버 지연/장애 | DONE | 20초 무응답/앱 재진입·HTTP500/502/503/504 분리·재발송 timeout |
| TEST08 Google/Kakao/Apple | DONE (계약) | 세 공급자 시작/취소·기존 native/OAuth/Kakao SDK seam 테스트 |
| TEST09 세션 복원 | DONE (SDK) | auth_lifecycle_sdk의 저장 세션 재시작/refresh/logout identity |
| TEST10 온보딩·개인화 보존 | DONE (Repository/라우터) | personalization_onboarding의 login upsert/진행/완료/계정 전환, 기존 홈/관심/지원 회귀 |

전체 8 SKIP은 기존 live/local-fixture opt-in 테스트이며 자동 PASS에 포함하지 않는다.

격리 대상은 실제 SDK Mock HTTP 및 Flutter widget/repository 테스트다. 운영 계정 로그인·신규 가입/메일 수신·실제 Google/Kakao/Apple 인증·iPhone 최종 IPA 설치·앱 재실행은 **NOT TESTED**다. 과거 APP82/83 Owner 검증이나 면제를 이번 빌드 PASS로 전용하지 않는다. 기존 계정/프로필/세션의 운영 값을 읽거나 수정하지 않았다.

## 빌드·Git·남은 승인

이전 로그인 차단 시점: 코드/자동 검증/독립 브랜치 Push DONE, 최종 배포 빌드 PARTIAL. 최신 재개 결과는 아래 참조.

- 구현 소스 커밋 `5059c884f86df6a96f822f72697fd59c8d1b6533`, 해당 hotfix 브랜치 원격 Push 및 `git ls-remote` 일치 확인. 문서 후속 SHA는 Git HEAD로 확인한다.
- iOS `tool/store-release ios --check` PASS, `tool/store-release ios --no-codesign --no-pub` PASS. Xcode archive75.7초, arm64 Release 컴파일/설정 검사 성공.
- 컴파일 검증 산출물: `build/releases/auth-hotfix-validation-only/Runner.xcarchive` (**unsigned / 업로드·설치 금지**). 기존 metadata1.0.3(83)를 유지한 컴파일 검증이며 새 출시본이 아니다. IPA export0.
- Bundle ID `com.legendstudy.app`, Minimum iOS15.0 보존. signing 설정/Entitlements/URL schemes/SDK lock 파일 변경0. 새 배포용 서명 검사는 최종 번호 확정 후 수행한다.
- 예상 **1.0.4(84)는 미확정**. App Store Connect가 로그인 만료 화면이라 실제 기존 버전/TestFlight 빌드 중복 여부를 확인할 수 없다. Owner에게 직접 로그인을 요청했고, 지시서13항에 따라 조회 전 번호를 확정하지 않았다.
- 기존 APP82/83 archive 및 APP83 IPA/AAB SHA256 보존 PASS. [검증 영수증](assets/auth-verification-ux-hotfix-20261113/validation.json). 설치/삭제/스토어/운영 변경0.

당시 남은 순서: ASC 로그인/번호 확인 → 버전 확정 → 서명 IPA → Owner 최종 검증/승인 → main/스토어 단계. 이 브랜치에는 SDK/서명/기능 추가 없이 해당 UI 수정만 포함한다.

Owner는 hotfix 구현·테스트·커밋·해당 브랜치 Push·긴급 iOS 빌드 준비를 승인했다. **main 병합·Push 및 업로드/스토어 제출은 별도 최종 승인 전 금지**다. 수정 소스만으로 이미 제출한 APP83 바이너리가 바뀌지는 않는다.

## ASC 확인 후 서명 빌드 재개

2026-11-13 Owner 로그인 후 LegendStudy ASC 배포 화면에서1.0.3(83) 배포 준비됨, TestFlight 버전 목록과 생성일 내림차순 전체 상태 업로드 목록에서 최신83(11/12 18:03) 확인. 1.0.4/84 업로드·처리 중 항목 없음. 번호1.0.4(84)를 확정하고 기존 서명 설정으로 IPA 생성한다. ASC 변경/버전 생성/업로드/제출0. 앞의 로그인 차단은 해소됐으며 빌드 완료 결과는 아래에 기록한다.

## 최종 서명 IPA 완료

- **빌드 준비 DONE**: iOS **1.0.4(84)**, 제품 소스 `8195bb07e1f545f0876378b94ebf218b9a00cd77`. 검증된 제품 코드에 버전 metadata만 변경했다. 전체2601 PASS/8 SKIP/0 FAIL·Analyze PASS는 앞선 코드 검증 결과이며 버전만 변경한 뒤 반복 실행한 것은 아니다.
- `tool/store-release ios --no-pub --export-options-plist=build/releases/app84/ExportOptions.plist` PASS.
- IPA: `build/releases/app84/legendstudy-1.0.4-84.ipa` (34,459,920 bytes). Archive: `build/releases/app84/Runner.xcarchive`.
- SHA256: `98cd976b32ccfc658f69d11f80d5bff1391832d06347c02d6644c7453ac3ab12`.
- Apple Distribution / Copacabana / VUKFS69GB4, App Store profile, codesign deep/strict PASS. get-task-allow false, 서명 entitlement 전체가 APP83과 동일. Google redirect/이메일 복귀 scheme·공개 런타임 설정·main target·IPA/archive UUID·privacy manifest26개 PASS.
- APP83 IPA/AAB 해시 재확인 PASS, 기존 앱·APP82/83 archive 보존. 실기기 설치·실제 Auth E2E·스토어 업로드/처리/심사 **NOT TESTED**.
- ASC 로그인/번호 차단 해소. 남은 사항은 Owner 실기기 최종 검증 및 main 병합/스토어 제출 승인이다. 원격 Push는 hotfix 브랜치에만 수행한다.

## iPhone17 업데이트·로그인 UI 및 Android 빌드 후속

Owner가 기존 앱 데이터를 유지한 iPhone17 Pro Max 설치/로그인 화면 확인과 Android 빌드를 승인했다. 스토어 제출 금지는 유지한다.

- 설치 전 실제 기기는 App Store1.0.3(83). 같은 Bundle ID/팀의 archive Release app(기기용 development 서명)을 `devicectl install app`으로 업데이트했다. 제거/초기화/로그아웃0. 설치 후1.0.4(84)·실행 성공 확인. 배포 IPA 직접 설치 검증과 구분한다.
- Owner 마이크 사용 종료/잠금 후 iPhone Mirroring에서 홈→로그인 진입 확인. 일반 로그인 화면에서 재발송 버튼과 인증 안내 미노출 **PASS**. 이메일/비밀번호·로그인·회원가입/복구 링크·Google/Kakao/Apple·비회원/약관 표시 확인. 로그인 화면을 그대로 남겼다.
- 실제 로그인/가입/재발송 요청은 하지 않았다. 기존 Store 앱 컨테이너가 접근 불가라 사용자 데이터 전체의 전후 해시 비교는 **NOT TESTED**. 삭제 없는 OS 업데이트 경로를 사용했고 운영 데이터/기존 세션 저장소를 임의 수정하지 않았다.
- Android1.0.4(84) `tool/store-release android` **PASS**. 첫 `--no-pub` 시도는 이전 integration_test 자동 생성 registrant 잔여 참조로 실패; Git 미추적 생성 파일만 재생성하고 동일 소스로 정상 빌드. 제품 코드/SDK/의존성 변경0.
- AAB `build/releases/app84/legendstudy-1.0.4-84.aab` (101,876,067 bytes), SHA256 `ae91211c8cb62a60d6b68e85899d7836f94ab9baca0544b2f25489c75f5b2727`.
- 기존 업로드 인증서·jarsigner·package/version·release non-debuggable·운영 공개 설정·모든64bit ELF16KB 정렬 **PASS**. min24/target36, 기존 권한 유지/AD_ID 없음. Android 실기기·Play 업로드/설치 **NOT TESTED**.
- APP83 IPA/AAB 해시 보존 재확인. main 병합·운영 변경·양쪽 스토어 업로드/제출0. 이 후속은 hotfix 브랜치의 Wiki/영수증만 갱신한다.

## Owner 확인 후 main 통합 — 2026-11-13

Owner가 로그인 화면 확인 완료와 main 병합·Push를 승인했다. 스토어 업로드는 Owner가 직접 수행한다.

- fetch 후 원격/로컬 main `9f533d29773a8f5c28b45904c079fc4fe37417a8`는 hotfix의 조상. 다른 main 전용 변경/충돌0, fast-forward 통합 가능 확인.
- hotfix5개 커밋은 로그인 오류/안내 UI2파일·테스트3파일·버전·Wiki만 포함한다. 운영DB/SDK/Native/LAB 변경 없음.
- 최종 제품 트리는 배포 소스 `8195bb0`와 lib/android/ios/pubspec/lock 모두 동일. 기존2601 PASS/8 SKIP/0 FAIL·Analyze 및 빌드 검증을 재사용하며 문서/fast-forward만을 이유로 테스트를 재실행했다고 기록하지 않는다.
- IPA/AAB 파일 존재·SHA256 재확인 PASS. 신규 바이너리 생성/스토어 업로드·제출0. 실기기 실제 계정 로그인·Android 실기기 NOT TESTED 유지.
- main을 fast-forward하고 일반 Push(강제 Push 없음) 후 원격 SHA와 로컬 HEAD 일치를 확인한다. 최종 통합 SHA는 Git main을 조회한다.
