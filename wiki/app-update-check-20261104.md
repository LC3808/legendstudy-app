# APP 업데이트 확인 — Native 통합 및 비활성 정책 후보

기준일: 2026-11-04. Owner의 업데이트 확인 지시를 후보 B 통합 브랜치에 구현했다. 기능·정책 코드 검증을 완료했고, 실제 스토어에 공개된 최신 버전 확인과 정책 활성화, 실기기 스토어 이동 검수는 남아 있다. 후보 57/58이나 TestFlight 빌드를 최신 공개 버전으로 지정하지 않았다. 운영·TEST 정책 DB는 변경하지 않았다.

상위 기록: [릴리스 통합](app-release-integration-20261103.md), [수리·상경 통합 보고](app-math-commerce-integration-report-20261103.md), [기존 공유 프로필·온보딩](personalization-onboarding.md), [공식 스토어 링크](official-home-launch-task12.md).

## 구현 및 재사용

- 기존 `com.legendstudy.app/info` Native 채널의 설치 버전·빌드를 재사용한다. `appVersionProvider`는 MY/문의 화면의 기존 `version (build)` 표시를 유지한다.
- 버전은 2~4개 숫자 구성요소를 4개로 보정해 비교하고, 버전이 같으면 build를 비교한다. 문자열 사전순 비교를 사용하지 않는다. iOS와 Android 정책을 분리한다.
- 기존 Supabase 클라이언트로 `app_update_policy(p_platform)`를 읽는다. 앱에서 정책·계정·학생 DB를 쓰는 경로는 없다.
- 기존 SharedPreferences에 해당 설치의 플랫폼/공개 버전/build별 ‘나중에’ 시각만 저장한다. 24시간 뒤 재안내하고, 다른 최신 tuple은 새로 안내한다. 학생 identity나 학습 기록을 추가 수집하지 않는다.
- 기존 Native 테마·라우터·외부 링크 실행기를 재사용한다. 강조색은 Owner 지정 `#FFAC14`, 본문은 기존 navy, Native `AlertDialog`다. 별도 WebView·패키지 의존성은 추가하지 않았다.

## 표시와 차단 정책

| 조건 | 결과 |
| --- | --- |
| 설치 버전/build가 공개 최신 이상 | 안내 없음 |
| 승인된 공개 정책이며 설치본이 최신보다 이전 | OPTIONAL, ‘나중에’와 ‘업데이트하기’ |
| 서버 REQUIRED와 exact minimum 승인, 설치본이 minimum 미만 | REQUIRED, ‘업데이트하기’만 제공 |
| REQUIRED 정책이지만 설치본이 minimum 이상 | OPTIONAL |
| REQUIRED 승인 없음/불일치 | 사용을 차단하지 않는 OPTIONAL |
| 정책 미설치·disabled·미공개·잘못된 값·조회 오류 | 기존 서비스 계속 이용 |
| 네트워크 응답 지연 | 3초 제한 후 기존 서비스 계속 이용 |

선택형 문구는 ‘새로운 업데이트가 있어요.’와 ‘더 편리한 학습을 위해 최신 버전으로 업데이트해 주세요.’다. 필수형은 ‘업데이트가 필요해요.’와 ‘최신 버전으로 업데이트해야 서비스를 계속 이용할 수 있어요.’로 구분한다. 표시 버전은 서버가 확인한 공개 최신 버전이며 내부 후보 build를 노출하지 않는다.

인증(`/auth*`), 기기 소개, 온보딩, 앱 사용 안내, 계정 삭제 화면에서는 안내를 미룬다. 인증/프로필 조회가 끝난 뒤 기존 공유 프로필을 재사용한다. `onboardingCompletedAt`이 없는 과거·WEB 가입자도 기존 canonical 온보딩 규칙대로 인정한다. 실제 누락 프로필·조회 중/실패 상태에서는 안내로 온보딩을 가로막지 않는다.

root Navigator의 단일 route로 중복 팝업을 막는다. 필수형은 뒤로가기와 다른 서비스 경로 이동으로 해제되지 않는다. root 표시 위젯 또는 controller 해제 시 진행 중 deadline 타이머도 취소한다. 앱 복귀 시 정책을 새로 조회하며, 실패·timeout이면 오래된 필수 안내를 남기지 않는다. 스토어 실행도 3초 제한을 두고 실패 시 다시 시도할 수 있다. 선택형 스토어 이동의 비동기 완료가 background 전환 뒤 도착해도 성공을 기억한다. 느린 설정 읽기 중 ‘나중에’를 눌렀을 때 안내가 다시 생기거나, 이전 스토어 실행이 새 버전 안내를 숨기거나 같은 버전에 새로 승인된 필수 안내를 해제하는 경합도 차단했다.

## 서버 계약과 미적용 SQL

[비활성 정책 후보 패키지](../supabase/candidates/app_update_policy_20261104/README.md)에 SQL, 읽기 postflight, 기대값, HOLD-only 중단 SQL, 로컬 검증 결과를 보관한다.

- 신규 private 정책 저장소: `app_release_private.platform_policy`, 플랫폼당 1행.
- 공개 읽기 RPC: `public.app_update_policy(p_platform text)` → null 또는 `app-update-policy-v1`.
- 공개 필드: platform, latest_version/build, minimum_supported_version/build, update_type, release_notes, store_url, enabled, store_release_verified, required_approved, verified_at.
- 공개 확인에는 latest tuple과 검증 tuple 일치, 유효한 과거/현재 검증 시각, 별도 검증 근거가 필요하다.
- 필수 승인은 minimum tuple, 승인 시각·근거를 별도로 확인한다. 최신 버전이나 minimum이 바뀌면 이전 승인을 재사용해 차단할 수 없다.
- 공식 App Store/Google Play URL만 허용한다. 임의 URL·query/token을 제공하지 않는다.
- 초기 iOS/Android 모두 `enabled=false`, OPTIONAL, latest/minimum 미설정이다. 실행 권한은 anon/authenticated의 읽기 RPC로 제한하며 private 직접 읽기/쓰기는 막는다.

SQL은 설치만으로 안내를 활성화하지 않는다. 새 DB 객체 적용과 실제 공개 tuple 설정은 Owner 확인 후 별도 작업이며, 이번 구현에서 실행하지 않았다. 현재 RPC가 없어도 앱은 기존 서비스 이용을 계속한다. 공개 최신 버전을 확인하기 전에는 정책을 활성화하지 않는다.

## 검증 결과와 한계

Flutter SDK는 기존 빌드의 FVM 3.47.6을 사용했다. 집중 검사 45개, 기존 프로필·온보딩 회귀 13개, 기존 실기기 검수 shell 회귀 10개, 총 **68개 PASS**다. 전체 통합 검사에서 발견된 위젯 종료 후 pending 타이머 문제를 수정한 뒤 기존 4개 shell 실패 사례도 그대로 통과했다. 실행 명령:

```sh
flutter test test/app_update_test.dart test/personalization_onboarding_test.dart test/owner_device_qa_test.dart --reporter expanded
```

| Owner 항목 | 코드/Mock 검증 | 실제 검수 |
| --- | --- | --- |
| A 최신 설치본 안내 없음 | PASS | 공개 정책 활성화 후 검수 |
| B 이전 버전 OPTIONAL | PASS | 같은 조건 |
| C 나중에 후 정상 이용 | PASS, 24시간 재시작 지속 | 기기 검수 필요 |
| D 업데이트 버튼 → 공식 스토어 | URI 전달·성공/실패/timeout·복귀 PASS | 실제 스토어 이동 미검수 |
| E minimum 미만 REQUIRED | 뒤로가기·서비스 이동 방어 PASS | 승인된 TEST 정책 검수 필요 |
| F 서버 오류 시 기존 이용 | 실패·누락·3초 timeout PASS | 정책 미적용 상태는 fail-open |
| G 플랫폼 분리 | PASS | iOS/Android 기기 검수 필요 |
| H 같은 tuple 24시간·중복 방지 | PASS, 비동기 경합 포함 | 기기 시간 경과 검수 미실시 |
| I 새 공개 tuple 재안내 | PASS | 실제 새 공개 버전 미설정 |
| J 인증·온보딩 보존 | auth/intro/onboarding 미표시·legacy/완료/누락/조회오류 PASS | 기존 인증 실기기 PASS를 재사용, 이 기능 실기기 미검수 |
| K 인문·수리 회귀 | 기능은 읽기·표시만, 공통 프로필 13개 PASS | 전체 통합 회귀와 빌드 결과는 상위 보고에서 확정 |

로컬 PG17 정책 SQL 검증은 **69개 PASS**다. anon/authenticated 읽기, private 쓰기 차단, exact 공개·minimum 승인, 잘못된 값·URL·무한/미래 timestamp, 초기 비활성, UTF-16 길이 제한을 검증했다. 원격 정책 DB·실제 스토어·실기기 PASS와 구분한다.

Native Mock 화면은 390×844에서 실제 위젯을 렌더링해 한글·간격·버튼을 육안 확인했다. 320×568, 글자 1.5배도 overflow 없이 검증했다. 이미지의 `1.0.2`/build 60은 **테스트 fixture**이며 실제 공개 버전이라는 뜻이 아니다. 로컬 산출물:

- `/private/tmp/legendstudy-app-update-preview/optional-mock.png`
- `/private/tmp/legendstudy-app-update-preview/required-mock.png`
- `/tmp/legendstudy-app-update-focused.log`
- `/tmp/legendstudy-app-update-render.log`

## 변경 파일 및 후속 검수

- `lib/core/config/app_information.dart`: 기존 Native 정보 채널 재사용, 숫자 버전 모델.
- `lib/features/app_update/app_update_policy.dart`: 공개 정책 검증·비교.
- `lib/features/app_update/app_update_controller.dart`: 읽기·timeout·24시간·중복/경합 제어.
- `lib/features/app_update/app_update_gate.dart`: Native 안내·라이프사이클·인증 지연.
- `lib/app/legendstudy_app.dart`: 공통 root 표시 연결.
- `lib/features/onboarding/onboarding_gate.dart`: 기존 공유 프로필 판정 공용화, 동작 유지.
- `test/app_update_test.dart`: 숫자 비교·정책·라이프사이클·프로필·화면 회귀.

최종 통합 전체1,480PASS/기존7SKIP·Analyze0, 동일소스5b5e5a8의 정식 iOS IPA/Archive·Android AAB1.0.1(58) 및 서명/운영설정 검증 PASS. Git SHA와 파일 산출물은 [수리·상경 통합 보고](app-math-commerce-integration-report-20261103.md)에 기록한다. 실제 기기 안내·공식 스토어 이동은 정책 후보 적용과 실제 공개 정보 확인 이후 검수한다. 기존 APP41에는 이 클라이언트 기능이 없어 안내·필수 업데이트가 소급 설치되지 않는다. 해당 코드를 포함한 버전부터 작동하며, 기존 APP41을 서버에서 강제로 제한하는 별도 정책은 이번 범위가 아니다. 스토어 제출과 운영 활성화는 이번 작업의 완료로 간주하지 않는다.
