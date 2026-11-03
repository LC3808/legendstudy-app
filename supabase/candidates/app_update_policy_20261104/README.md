# APP 업데이트 정책 — 비활성 SQL 후보

**상태: 로컬 PG17 69개 검사 PASS. 2026-11-04 Owner 승인 후 격리 TEST에 초기 비활성 적용·postflight·실제 HTTP 조회 PASS. 운영 DB 미적용.**

Owner의 APP 업데이트 확인 범위를 위해 기존 결제 설정과 분리한 최소 릴리스 정책을 준비했다. 신규 DB 객체의 TEST 적용은 Owner 승인 완료, 운영 적용은 별도 검토·승인 대상이다. 이 SQL은 설치만으로 업데이트 안내나 필수 업데이트를 활성화하지 않는다. 후보 빌드 57/58을 스토어 최신 버전으로 지정하지 않았다.

## 계약

- private schema: `app_release_private`
- private table: `platform_policy`, 플랫폼당 1행(`ios`, `android`)
- private helper: `version_key(text, integer)`
- public read-only RPC: `app_update_policy(p_platform text)` → null 또는 `app-update-policy-v1` JSON
- 초기값: 양 플랫폼 `enabled=false`, `update_type=OPTIONAL`, latest/minimum 미설정, 스토어 확인·필수 승인 false

반환 JSON은 `platform`, `latest_version`, `latest_build`, `minimum_supported_version`, `minimum_supported_build`, `update_type`, `release_notes`, `store_url`, `enabled`, `store_release_verified`, `required_approved`, `verified_at`을 포함한다. 내부 확인·승인 근거 문자열과 내부 비교 tuple은 공개하지 않는다.

숫자 버전은 2~4개 구성요소(각 1~7자리)를 4개로 보정한 뒤 native build를 비교한다. `1.0.9 < 1.0.10`, 같은 버전의 `57 < 58`, `1.0 = 1.0.0.0`이다. build는 0~2147483647이다. minimum은 latest 이하만 허용한다. 출시 안내 문자열은 Flutter와 동일하게 UTF-16 2000 units 이하이다.

## 활성화 조건

공개 정책을 반환하려면 Owner가 아래를 별도로 확인해야 한다.

1. 해당 플랫폼의 실제 스토어에 공개된 정확한 버전과 빌드가 `latest_*` 및 `verified_store_*`에 동일하게 설정되어야 한다. `store_release_verified=true`, 과거/현재의 유한한 `verified_at`, 비어 있지 않은 `verification_reference`가 필요하다.
2. 필수 업데이트는 위 공개 조건과 별개로 `update_type=REQUIRED`, `required_approved=true`, `approved_minimum_*`와 실제 minimum tuple의 정확한 일치, 유효한 승인 시각 및 비어 있지 않은 `approval_reference`가 필요하다. 이 조건이 없으면 앱은 optional로만 처리하고 사용을 막지 않는다.
3. latest를 바꾸면 기존 스토어 확인 tuple은 자동으로 불일치하여 RPC가 null을 반환한다. minimum을 바꾸면 과거 minimum 승인이 자동으로 무효가 된다. 다른 플랫폼 정책을 가져오지 않는다.

스토어 URL은 [공식 홈페이지 Wiki](../../../wiki/official-home-launch-task12.md)의 고정 URL만 허용한다.

- iOS: https://apps.apple.com/us/app/레전드스터디/id6820826957
- Android: https://play.google.com/store/apps/details?id=com.legendstudy.app

현재 정책 없음·disabled·잘못된 값·미공개 상태에서는 null을 반환한다. 앱은 RPC 누락·네트워크 오류를 포함한 조회 실패 시 기존 서비스를 계속 사용할 수 있다. 이 DB 후보가 미적용이어도 앱 이용을 막지 않는다.

## 보안·보존

공개 RPC는 명시적 빈 search_path의 SECURITY DEFINER이며 owner는 postgres다. anon/authenticated는 이 읽기 RPC만 실행할 수 있다. service_role에는 실행 권한을 주지 않는다. private schema/table/helper는 PUBLIC·anon·authenticated·service_role 직접 접근을 모두 차단하며 테이블 RLS와 FORCE RLS를 적용한다. 쓰기 RPC는 없다. Owner의 서버 관리자 postgres만 별도 SQL로 정책을 변경한다.

이번 데이터는 학생의 학습·선택·입시 사실이 아닌 서비스 릴리스 설정이다. 기존 장기 보존 검토의 7항목에 따라: (1) 스토어 확인/최소 버전 승인 시각을 별도 기록하고, (2) 확인·승인 tuple과 근거를 분리하며, (3) 기존 학생 원본/과거 기록을 변경하지 않고, (4) 새로운 학생 identity를 수집하지 않으며, (5) 릴리스 정책을 Learning/Decision/Outcome과 섞지 않고, (6) 공개 응답을 필요한 정책 필드로 한정하며, (7) 후보 빌드나 확인되지 않은 스토어 상태를 실제 공개 사실로 취급하지 않는다. 기존 Auth·Credit·Ledger·결제·프로필·History 테이블은 참조/변경하지 않는다.

## 검증

`validation.log` / `verification.json`: 임시 Unix socket PostgreSQL17에서 실제 후보 SQL을 **NOSUPERUSER postgres**로 설치했다. 외부 네트워크, 원격 DB, Provider, 스토어 변경 없이 69개 검사를 통과했다.

- 전체 transaction 실패 원복 및 재설치 시 기존 정책 덮어쓰기 방지
- 초기 2행 disabled/OPTIONAL/latest·minimum null
- anon/authenticated RPC 읽기, private 직접 SELECT/INSERT/UPDATE/DELETE/helper 접근 금지
- 광범위 default ACL이 있어도 명시적 회수, RLS/FORCE RLS, 빈 search_path
- 숫자 버전/빌드 비교와 잘못된 문자열·음수·상한·부분 tuple 거부
- 플랫폼 분리, 공개 확인 exact tuple/시각/근거, latest 변경 시 과거 확인 무효
- 필수 승인 exact minimum tuple/시각/근거, minimum 변경 시 과거 승인 무효
- 최소 버전 역전·임의 URL·무한 timestamp·미확인 스토어·긴 안내 차단
- UTF-16 기준 1000개 이모지 허용 / 1001개 거부

이는 DB 로컬 검증이다. 실제 App Store/Google Play 공개 확인, 원격 RPC 설치, 실제 기기 업데이트 팝업/스토어 이동 검수는 이 결과에 포함되지 않는다.

## 적용·중단

Owner 승인 후 신규 후보 파일을 적용하고 `postflight.sql` 및 `expected-postflight.json`을 확인한다. 설치 직후 두 플랫폼 RPC 결과는 null이어야 한다. 실제 공개 버전과 최소 지원 정책 승인 전에는 활성화하지 않는다. 문제 시 `hold-only.sql`의 disabled 전환으로 안내를 중단하고 정책 근거를 보존한다. 이 패키지 작성 중에는 해당 SQL도 실행하지 않았다.


## 실제 TEST 적용 영수증

[11/4 TEST 적용·검증 결과](test-applied-postflight.json), [Wiki 상세](../../../wiki/app-update-check-20261104.md#2026-11-04--owner-승인-후-격리-test-비활성-적용). 대상은 `kpqbedylxlyntrrfybpn`, 원격 migration은 `20261103154005_app_update_policy_disabled_candidate_test_20261104`. 승인된 원본 SQL의 SHA256은 그대로다. 두 플랫폼 disabled/OPTIONAL, RPC HTTP200/null, 함수 정의/ACL/RLS 일치, 기존11종 데이터 건수 보존을 확인했다. 운영 적용·정책 활성화·실제 기기 팝업 검수는 하지 않았다.
