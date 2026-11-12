# APP82 Post-RC UI/UX 개선

## 기준과 승인 경계

Owner 원문(2026-11-12): APP82 v1.0.3/82, main `02977efc1aa0a61d4e9d261d9e089879b2fbfba5` 기반 학교 순위·개인 공부시간 백분위·스플래시·홈 순위·첫 홈 메뉴 가이드. `codex/app82-post-rc-ux-20261112`에서 구현한다. 기존 [APP82 서명 산출물](app82-store-handoff-20261113.md)은 SHA-256 대조/별도 로컬 보관 완료. main 병합·새 릴리스 빌드·스토어 제출은 후속 Owner 승인 대상이다. 운영 DB/Auth/RPC·기존 회원/기록·논술 엔진 변경 금지.

## 사전 점검 — 운영 읽기 전용

LegendStudy 프로젝트 `stlhijzpjfgwwdgunlsd`의 실제 함수 정의를 확인했다. Git 파일로 운영 적용을 추정하지 않았다.

|항목|실제 계약|이번 처리|
|---|---|---|
|학교 카드|`student_school_card()`, 이번 주 기록자3명 이상 시간/순위, 자기 학교만 인원 노출|기존 계약 보존|
|학교 순위|`student_school_ranking(period,metric)`, 총/평균3명, 참여1명, 타 학교 인원NULL|지시서의 공개랭킹5명과 다름. Owner에게 즉시 보고/확인 요청|
|추가 순위|TOP10·자기 학교·주변만 반환, 페이지 인자 없음|기존 결과에서 전체 목록을 추측하지 않고 별도 읽기 후보 필요|
|순위권 밖|서버가 미충족 학교 목록을 반환하지 않음|학교 목록/인원을 client에서 역산하지 않음|
|개인 요약|`my_study_summary()` → `student_private.study_summary`, 완료/동기화된 유효 구간 합계|기존 원본·중복 구간 제거·누적/기간 계약 재사용|
|공부시간 백분위|기존 RPC 없음|서버 계산 후보·권한/동률/최소표본 검증 필요|
|온보딩|설치별 브랜드3슬라이드와 계정별 프로필 온보딩(유형별 단계)이 별도|두 흐름 모두 유지; 메뉴 가이드가 완료 marker를 바꾸지 않음|

## 설계 전 일곱 보존 검토

[장기 전략](longitudinal-learning-admissions-data-strategy.md), [기존 학습 통합](app67-learning-integration-20261111.md), [학습 원본](study-v1.md), [홈 개인화](task04-home-university-news-20261111.md), [스플래시](app-icon-splash-v1.md), [온보딩](personalization-onboarding.md)을 계승한다.

1. 학습 발생/저장 시각·구간은 원본 그대로. 조회 시점은 파생 응답에 명시한다.
2. study_sessions/active_segments·학교/프로필·Registry·결과 원본 보존.
3. 기록 UPDATE/DELETE·추정 backfill·완료시각 재설정 없음. 가이드 노출 상태만 로컬 presentation preference로 분리한다.
4. 동일 auth identity를 사용하고 계정 변경 시 늦은 응답/가이드를 폐기한다.
5. 공부시간은 Learning의 자기기록 지표다. 성적·합격 가능성·Decision/Outcome으로 표현하지 않는다.
6. 타 학생 시간 목록/소규모 학교 인원 미제공. 자기 백분위와 서버가 허용한 학교 집계만 제공한다.
7. 순위·백분위는 서버 파생값. 프런트 임의 계산·원본 덮어쓰기·표본 없는 숫자 표시 금지.

## 구현 결과

|영역|변경|경계|
|---|---|---|
|학교 순위|총 시간→참여→평균, 기본all/total, 진한1.75dp 선택 테두리·은은한 그림자, 기존 하단 문단 제거|기간 선택 유지, 기존 tie rank 보존|
|더 보기·순위권 밖|서버10개 단위 페이지, 공유 timestamp/revision, 중복 제거, 실패 시 기존 목록/재시도, 필터 변경 초기화|신규 조회 RPC 미적용이면 기존TOP10/주변 목록으로 복귀. 가짜 추가 목록 없음|
|홈 카드|중복 ListTile padding 제거,16dp+border1, 제목18/w700, teal 순위20/w800|상세 기본값과 동일 provider. 미등록/오류면 숫자 없음, 미충족은 순위권 밖|
|개인 공부시간|누적 지표 아래 서버 백분위,0기록/집계/실패/표본부족 상태|새 RPC 미적용은 백분위 숨김. 프런트 추정/다른 학생 기록 다운로드 없음|
|스플래시|로고와 이름을 그룹으로 상단1/3,20dp 간격, navy+, 기존 Pretendard/심벌 보존|원본 PNG의 투명 여백만 Flutter 레이아웃에서 제외. 에셋 재제작 없음. 기존1.8초 cold-start 예산/게이트 보존|
|첫 홈 가이드|실제 NavigationDestination 좌표 강조·화살표·5단계 Next/Skip/Start, 작고 큰 화면/글자2배 스크롤|브랜드3페이지/계정 온보딩/하단 탭 구조와 MY 재진입 규칙 보존|

### 백분위 후보 계약

[SQL/적용/검증/원복 패키지](../supabase/candidates/app82_post_rc_ux_20261112/README.md). 신규 RPC는 `student_school_ranking_page`와 `my_study_percentile` 2개다. **운영 미적용**이며 기존 함수/테이블/RLS/학습 원본 변경은 없다.

- 유효 완료·동기화 구간을 사용자별 합집합으로 합산한다. 제외기록·미래 종료기록·0시간 사용자 제외, 계정 상태는 기존 `account_private.allowed`를 재사용한다.
- 같은 statement timestamp에서 전체 비교를 수행한다. 표본 후보 최소20명. 부족하면 숫자 보류.
- 순위=`더 오래 공부한 사람 수+1`, 상위%=`ceil(100×(더 오래 공부한 사람 수+동률 인원)/전체 비교 인원)`.
- 예:20명 중1등2명 동률이면 둘 다 상위10%,40명 중1등3명 동률이면 둘 다 상위8%,모두 같으면 상위100%. 동률을 낙관적으로 상위1%로 포장하지 않는다.
- 승인 후에도 운영 부하 측정 필요. 현재 랭킹과 같은 전역 집계를 매 페이지 수행하므로 페이지 크기10이 DB 전체 집계량을 줄인다는 의미는 아니다. 신규 materialized table·인덱스는 제안하지 않았다. 주기적 분 단위 백분위 재계산은 하지 않고 기록 동기화/명시 새로고침/화면 재진입 시 조회한다.

### 가이드 신규 사용자 판별

기기별 로컬 preference에 이 기능의 최초 관측 시각과 fresh guest 여부를 저장한다. 기존 브랜드 인트로가 완료된 설치는 신규 guest로 간주하지 않는다. 로그인 사용자는 SDK의 계정 생성 시각이 최초 관측 시각 이후이고, 같은 계정 프로필의 온보딩 완료가 확인될 때만 대상이다. 과거46개 marker 누락 계정도 계정 생성 시각으로 제외하므로 완료 marker를 backfill하거나 기존 온보딩 결정을 변경하지 않는다.

가이드 표시 전에 설치별 consumed를 저장한다. Skip/Start/앱 종료/재로그인 시 자동 반복 없음. 이 presentation flag는 서버 온보딩 완료와 별개다. 저장 실패/판별 불가면 자동 노출하지 않는다. 재설치·로컬 데이터 초기화 후 익명 사용자를 과거 사용자와 식별할 수 없는 한계는 있다. 로컬 기기 시계가 서버보다 크게 앞서면 새 계정도 보수적으로 미노출될 수 있다. 계정/프로필/학습 기록을 수정해 보정하지 않는다. 재생 화면을 추가할 때는 `HomeMenuGuide`를 직접 호출할 수 있고 이번 범위에 설정 메뉴는 없다.

### 플랫폼 시작 화면 차이

iOS LaunchScreen의 심벌 중심은 Flutter 그룹의 표준 크기 중심과 맞추고, 상단 안전 여백 제약을 추가했다. 흰 배경/기존 심벌/180dp 원본 렌더 크기를 유지한다. 스플래시 문자의 fallback 디버그 밑줄도 명시적으로 제거했다.

[Android 공식 시스템 스플래시](https://developer.android.com/develop/ui/views/launch/splash-screen)는 OS 중앙 아이콘 배치이므로 Android 시작 테마는 보존한다. 공통 Flutter 화면은 양 OS 모두 상단1/3이다. **Android OS→Flutter 구간 위치 이동 예외는 Owner 확인 대상으로 남긴다.** 완전히 같은 시작 위치라고 주장하지 않는다. native→Flutter cold-start 전환/실물 Dynamic Island는 NOT TESTED다.

## 검증

|검사|상태|근거|
|---|---|---|
|최종 Flutter Analyze|DONE / PASS|No issues found|
|전체 Flutter 자동 회귀|DONE / PASS|2,580 PASS / 8 SKIP / 0 FAIL. 기존2,557에 신규23. 기존 SKIP8 유지|
|신규 화면·상태|DONE / PASS|기본/필터/페이지/동률/개인정보/재시도/이전 학교 늦은 응답/백분위 상태/가이드1회/320·440폭·글자2배/스플래시|
|Python 기존 배포설정·자료 동기화|DONE / PASS|33 tests|
|신규 RPC 격리 PostgreSQL17|DONE / PASS|71 SQL checks+권한/3·1임계/동률/스냅샷/구간중복/표본/원복 assertions|
|기존 학습 SQL 격리 회귀|DONE / PASS|42 SQL checks+데이터/ACL/계약 assertions|
|Android JVM 집중 모드|DONE / PASS|Debug unit2, 실패0. 제품 Kotlin 변경0|
|iOS 시뮬레이터 Native|DONE / PASS|전용iPhone17Pro/iOS26.5, 운영 호출0, 스플래시/가이드5단계/홈/10→20개/백분위/재진입|
|Android 에뮬레이터 Native|DONE / PASS|기존LS_phone AVD read-only, 운영 호출0, 동일6시나리오|
|실제 iPhone·Android|NOT TESTED|iPhone17ProMax 연결불가, 실물Android 미연결. 연결 요청 상태이며 설치 앱/데이터 변경0|
|운영 신규 RPC·실계정 E2E·부하|NOT TESTED|후속 운영 적용 승인 필요. 가상 fixture 통과를 운영 PASS로 쓰지 않음|
|새 릴리스 빌드/스토어|NOT TESTED / HOLD|디버그 격리 빌드만 사용, 기존APP82 IPA/AAB 보존. main merge/Push0, 업로드/제출0|

초기 실패는 숨기지 않는다: 전체 테스트1건은 NavigationShell의 Provider 의존성 추가에 맞춰 MY 탭 테스트 harness에 ProviderScope를 추가하여 해결(기존 검증문 유지). 가이드 접근성 `explicitChildNodes`·초기 Auth loading 경합을 수정했다. Android 최초 Native smoke는 테스트 스크린샷 Surface 중복 전환으로 실패하여 1회 전환으로 수정. Android release JVM 시도는 동시 integration 플러그인 generated 등록과 release 의존성 불일치로 실패했으며 최종 동일 Kotlin 테스트를 Debug 구성에서 통과했다. iOS 초기 캡처는 이미지 디코딩 전 프레임을 수집하여 precache/네이티브 프레임 대기 후 정상 심벌·탭 그림을 다시 확인했다. 손상된 예전Brand AVD 대신 기존LS_phone을 read-only 실행했다. 이 실패들은 운영/제품 데이터 변경으로 우회하지 않았다.

[검증 영수증](assets/app82-post-rc-ux-20261112/validation.json). 아래 화면은 **격리 테스트 데이터**이며 실회원·실기기 스크린샷이 아니다.

- [iOS 메뉴 가이드](assets/app82-post-rc-ux-20261112/ios-guide.png)
- [iOS 홈 카드](assets/app82-post-rc-ux-20261112/ios-home.png)
- [iOS 순위](assets/app82-post-rc-ux-20261112/ios-ranking.png)
- [iOS 개인 백분위](assets/app82-post-rc-ux-20261112/ios-percentile.png)
- [iOS 스플래시](assets/app82-post-rc-ux-20261112/ios-splash.png)
- [Android 메뉴 가이드](assets/app82-post-rc-ux-20261112/android-guide.png)
- [Android 개인 백분위](assets/app82-post-rc-ux-20261112/android-percentile.png)
- [Android 스플래시](assets/app82-post-rc-ux-20261112/android-splash.png)
- [작은 화면·글자2배 가이드](assets/app82-post-rc-ux-20261112/guide-320-2x.png)
- [순위 기본 화면](assets/app82-post-rc-ux-20261112/ranking-360.png)

## 수정 파일

- `lib/features/learning/{learning_repository,learning_widgets,school_rank_feed,study_percentile,invite_page}.dart`: 기본값·카드/페이지·조회상태·백분위·학교 변경 후 무효화.
- `lib/features/home/customization/home_registry.dart`, `lib/features/home/guide/home_menu_guide.dart`, `lib/app/navigation_shell.dart`, `lib/main.dart`: 홈 카드·가이드·기기 로컬 초기화.
- `lib/features/brand/{brand_frame,brand_wordmark}.dart`, `ios/Runner/Base.lproj/LaunchScreen.storyboard`: 시작 화면 그룹/배치/텍스트 장식. Android 시작 테마 보존.
- `test/app82_post_rc_ux_test.dart`, `test/learning_integration_test.dart`, `test/my_tab_reset_test.dart`: 신규23+기존 기대 기본값/Provider harness 갱신.
- `integration_test/app82_post_rc_device_test.dart`, `test_driver/app82_post_rc_driver.dart`: 명시적 격리 Native 검증/스크린샷. 운영 인증·네트워크 초기화 없음.
- `tool/test_app82_post_rc_sql.py`, `supabase/candidates/app82_post_rc_ux_20261112/`: 새 읽기 후보·운영 기준 정의·격리 테스트·원복.
- 이 문서, index/current-status/log/decisions 및 증거 파일.

## 운영 승인·릴리스 게이트

로컬 구현 및 격리 검증은 완료한 후보로 보존한다. 전체 제품 출시 준비는 **PARTIAL**: 새 조회 함수 운영 적용과 실기기/live 서비스 확인이 남았다.

Owner 최종 판단 항목:
1. 현재 운영 총/평균3명·참여1명 기준 보존(5명 변경은 미포함).
2. additive 조회 RPC2개 적용: 위 최소20/동률 상한 백분위·masked 순위권 밖/스냅샷 계약. 원복은 두 함수만 제거.
3. Android OS 중앙 시작 화면 예외 허용 여부.
4. 적용 후 실계정 읽기 전용/실기기 확인, 그 다음 main 통합·새 빌드 번호 릴리스 후보 승인.

지금 기존APP82 배포 바이너리를 교체하거나 main을 변경하지 않는다. 인증·온보딩 저장·자료/PDF·LAB·Credit·학습 기록·기존 회원 데이터 변경0. [기존 릴리스 승인](decisions.md#2026-11-12--app82-릴리스-승인검수-면제기존-회원-영향-수용)과 [이번 후속 결정](decisions.md#2026-11-12--app82-post-rc-학습홈-ux-개선)을 구분한다.
