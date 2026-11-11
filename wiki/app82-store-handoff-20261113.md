# APP82 릴리스 결과·스토어 제출 전 인계

## 승인과 범위

Owner 승인 RC: `975b3c026960c6cf89ec67db43f222e3474ffb21`, 브랜치 `codex/app-release-rc-20261113`. [RC 기능별 커밋·APP75/78 대조·실기기 검증](app-release-rc-20261113.md)을 유지한다. 이번 단계는 main 통합/Push와 스토어용 빌드까지이며 업로드·심사 제출·게시를 수행하지 않는다. 운영 DB/RPC/Auth·WEB·기존 회원 데이터·Credit·논술 평가 엔진 변경0, 신규 기능0.

|Owner 결정|처리|
|---|---|
|로그인 정상 작동 확인|기존 RC 실기기 로그인 근거 유지|
|추가 Apple·Google 실기기 로그인|WAIVED — 실행/PASS로 기록하지 않음|
|추가 논술 LAB 실사용 첨삭|WAIVED — Provider 호출/차감/품질 검증 없음|
|기존46개 회원의 온보딩 재노출|ACCEPTED — marker 판별 유지, 별도 보호/backfill 없음|
|main 병합·원격 Push·양 OS 빌드|승인됨|
|스토어 업로드·심사 제출·게시|미수행; 산출물 인계 후 Owner 단계|

## 소스·버전

- 최종 대조 원격main: `aeb8be2dade4dfd39ea6c98eba2d738a83fb7a85`. RC의 ancestor이며 충돌 없음. 기존 main25파일 보존 근거는 RC source-alignment 영수증에 있다.
- 스토어 제품 소스: `ce24bfddd4abe379dd975117f54a51f94c58eaa5`. 승인RC 대비 `pubspec.yaml` 버전 한 줄만 `1.0.2+67` → `1.0.3+82`로 변경했다. 설치 검수 APP82는 명시 빌드 옵션의1.0.2(82)/`eab4563`이고 최종 배포 버전과 구분한다.
- Apple 공식 iTunes 조회(앱ID6820826957/KR)의 현재 공개 버전1.0.2, 2026-11-06 공개를 확인했다. 새 스토어 산출물은 **1.0.3(82)**. 최종 문서 커밋과 바이너리 빌드 소스는 별도로 기록한다.
- 로컬main fast-forward 통합 후 전체 회귀2557 PASS/8 SKIP/0 FAIL·Analyze PASS. 원격main Push 성공, `git ls-remote`에서 빌드 소스 `ce24bfddd4abe379dd975117f54a51f94c58eaa5` 일치 확인. force Push/다른 작업 브랜치 수정 없음.
- `.github/workflows/materials-daily-sync.yml`은 schedule/workflow_dispatch이며 Push 배포 트리거가 없다. 워크플로/운영 적재 수동 실행 없음.

## 최종 검사·산출물

|검사|결과|근거|
|---|---|---|
|Flutter Analyze|PASS|No issues found|
|main 통합 후 전체 Flutter test|PASS|2,557 PASS / 8 SKIP / 0 FAIL, 128.648초|
|기존 main 자료 동기화 Python|PASS|21+5=26건|
|Store production config 회귀|PASS|3건, 실제 iOS/Android --check 통과|
|Wiki handoff|PASS|3,389개 내부 링크·routing, current-status 10,715 bytes/12KB 이내|
|Android Native JVM|PASS|집중 모드 기존 단위 테스트2건, 실패0|
|iOS IPA·Android AAB|PASS|배포용 산출물 생성·실제 버전·서명 검증 완료|

[검증 영수증·SKIP8 이름·로그 해시](assets/app82-store-handoff-20261113/release-validation.json). SKIP은 외부 opt-in2/격리 Auth fixture1/저장 결과 fixture5이며 실행 성공으로 대체하지 않는다. 기존 RC의 실제 신규/기존 회원 로그인·온보딩·저장·MY·재실행·홈·검색/PDF 검수 근거를 보존한다.

## 최종 배포 산출물

보관 디렉터리: `/Users/woojinchang/.codex/worktrees/app-release-rc-20261113/legendstudy-app/build/releases/app82/`. 바이너리는 Git에 넣지 않는다. 아래 파일과 `SHA256SUMS`를 함께 인계한다.

|산출물|버전/빌드|크기(bytes)|SHA-256|
|---|---|---|---|
|`legendstudy-1.0.3-82.ipa`|1.0.3 / 82|34435608|`3eac3acc16deb5020d113169eed3f6722afd1205a12cb01467ed2d860f707a05`|
|`legendstudy-1.0.3-82.aab`|1.0.3 / 82|101708897|`8b19edfb69a2d8d5f9dd8baf89e98f235839242e64bae964022c6bcc0e2d4d80`|

- **iOS**: bundle `com.legendstudy.app`, 최소iOS15.0. Apple Distribution 서명과 `codesign --verify --deep --strict` PASS. App Store 배포 profile(기기목록 없음), `get-task-allow=false`, 만료2027-10-19. Apple Sign in entitlement·Google reversed URL·비밀번호 복구 scheme 확인. 실제 AOT의 public 운영 클라이언트 설정 확인. archive와 IPA App.framework UUID 일치, privacy plist 파싱 PASS. `build/ios/archive/Runner.xcarchive`와 dSYM도 보존한다.
- **Android**: package `com.legendstudy.app`, minSDK24/targetSDK36, debuggable=false. `jarsigner` 서명 무결성 PASS, 기존 업로드 인증서SHA256 `C00F4260D5B95A084335576C03BF36B8914A2F33CB3DA701403E0ADBACFB8EF1` 일치/유효기간2054-03-02. Billing 권한 유지, AD_ID 없음, APP67 대비 권한 추가/삭제0. arm64/x86_64의12개 ELF LOAD alignment가 모두16KB 이상이다(실제 Play split APK 검증으로 확대하지 않음).
- Android JAR의 self-signed 인증서·timestamp 없음·JarInputStream manifest 순서 경고는 같은 도구로 APP67에도 재현했다. Android 업로드 인증서/기존 패키징과 같은 상태이며 무결성 검사 exit0. 스토어 서버 수락은 업로드 전 **NOT TESTED**다.
- 소스 `ce24bfd` 이후 이번 변경은 Wiki/검증 영수증뿐이다. 산출물에 임의 Git SHA가 내장됐다고 주장하지 않으며 빌드 로그·고정 소스·파일 체크섬으로 추적한다.

## 설정·데이터 보존

검증 APP82의 public client 설정을 그대로 사용한다. 운영 Supabase 프로젝트, Apple/Google/Kakao, 계정 삭제·기존 논술 쓰기/평가 플래그, 관측/Analytics 플래그를 유지한다. `tool/store-release`가 production/소셜 설정/공개 publishable key를 검사한다. 비밀번호·업로드 keystore·API secret은 Git/Wiki/바이너리 설정에 추가하지 않는다. 기존 Android 업로드 키와 Apple Distribution 인증서를 재사용한다. `config/store-rc.local.json`, `android/key.properties`, `ios/Flutter/Auth.local.xcconfig`는 ignored이며 커밋하지 않는다.

기존 iPhone 설치본·사용자 데이터의 삭제/교체 설치는 이번 빌드 단계에서 하지 않는다. Android Play App Signing 키와 로컬 업로드 키는 역할이 다르므로 기존 Play 설치본을 삭제해 로컬 APK로 교체하지 않는다.

## 빌드 환경 복구 이력

Android 최초 빌드는 `No space left on device`로 실패했고 후속 서비스 종료 과정에서 Gradle 캐시 잠금이 남았다. 현재 작업 트리의 재생성 가능한 iOS 의존성·중간 빌드·자동 테스트 캐시만 삭제했다. 배포 IPA·xcarchive·기존 설치 앱·사용자 데이터는 보존했다. 공간 확보 후 재시도에서 남은 잠금을 확인하고 해당 작업 트리 잠금을 가진 IDLE Gradle daemon 하나만 정상 종료했다. 제품 코드/서명/설정 변경 없는 최종 재시도가79.2초에 성공했다. 실패한 두 시도는 영수증에 FAILED로 보존하고 최종 성공을 별도로 기록한다.

AGP/Kotlin 지원 종료 예고, SDK XML·CupertinoIcons 경고는 APP66 빌드 로그에서도 확인한 기존 경고다. iOS `flutter_tts` Swift Package Manager 지원 예고도 현재 archive/export를 막지 않았다. 이번 릴리스에서 의존성·평가 엔진을 업그레이드하지 않는다.

## 제출 전 남은 확인

- 새 배포 IPA/AAB의 스토어 서버 처리·심사·실제 업데이트: NOT TESTED, 업로드 전이다.
- 새 배포 바이너리 자체의 설치/실기기 재검수는 기존 APP82 QA 검수와 구분한다.
- Android Play 경유 업데이트·기존 로컬 데이터 보존: NOT TESTED, 기존 앱 삭제0.
- Store Connect/Play Console의 미공개 빌드 번호 점유 여부는 서버 업로드 검증 전 확정하지 않는다.
- 알림 Backend 미구현 오류/재시도, 앱 강제 종료 시 미저장 폼 전체 복원 후속 범위는 기존 RC의 알려진 한계다. 이번 승인으로 기능이 구현되었다고 기록하지 않는다.
