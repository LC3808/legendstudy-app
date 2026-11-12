# APP83 최종 릴리스 빌드·Owner 인계

## 스토어 제출 후속 — 2026-11-12

Owner가 빠른 스토어 신청 진행을 요청해 기존 빌드 전용 인계 범위를 확장했다. 이후 iOS는 Owner가 직접 진행한다고 정정했고, IPA Transporter 업로드와 Android AAB 업로드 완료를 각각 보고했다. Codex는 iOS 제출을 대신하지 않고 Android 심사 전송을 진행했다. [기존 승인과 후속 범위](decisions.md#2026-11-12--app83-최종-릴리스-진행-승인).

- **Android 서버 수락 확인:** 기존 LegendStudy Play Console 앱에 `legendstudy-1.0.3-83.aab`, **83 (1.0.3)** 표시. API24+/target36, ReTrace·native symbols 첨부 확인. 출시 검토 화면에서 지원 제외/추가 기기 모두0, 신규 설치24.7MB·업데이트3.28MB 표시. 업로드는 Owner 수행이다.
- **심사 전송 요청 완료:** 한국어 출시 노트를 저장하고 변경사항1개(프로덕션83)를 전송했다. 18:08 KST 기록 시점 [게시 개요](https://play.google.com/console/u/6/developers/6807727077532562397/app/4972317086113621808/publishing)에 **검토 중인 변경사항 → 83 (1.0.3) / 전체 출시 시작** 표시를 확인했다.
- **자동 검사 진행 중:** 화면은 최대14분 남음과 검사 성공 후 심사 전송을 안내했다. 자동 검사 통과·심사 승인·실제 공개는 아직 확인하지 않았으며 완료로 기록하지 않는다. 관리형 게시 사용 중지, 기존 대상 국가 전체·출시율100%를 유지했다. 심사 승인 후 자동 전체 출시 설정이다.
- **iOS:** Owner가 Transporter 업로드 완료를 보고했고 App Store Connect1.0.3 제출 준비 화면과 업데이트 설명을 준비했다. 이후 Owner 직접 진행 지시에 따라 조작을 중단했다. 빌드83 선택·심사 제출·승인·실제 공개 결과는 **NOT TESTED / Owner 진행**이다.
- 제품 소스·바이너리 재빌드, 운영 DB/RPC/Auth/WEB, 사용자 데이터 변경0. 최종 스토어 바이너리 실기기 검증은 기존 **NOT TESTED**를 유지한다.

제출한 한국어 출시 노트:

> 더 편리하게 시작하고, 나에게 맞는 학습 공간을 만들어 보세요.
>
> • 이메일 인증과 재발송 안내를 개선했습니다.
> • 첫 가입 안내와 온보딩 진행·복원 흐름을 개선했습니다.
> • 온보딩에서 실제 지원 대학을 등록하고 MY에서 함께 관리할 수 있습니다.
> • 한국교원대학교 등 대학 검색 목록을 확대했습니다.
> • 홈 카드 구성과 설정 저장·복원을 개선했습니다.
> • 학습 순위, 알림 화면과 앱 시작 화면의 사용성을 개선했습니다.

## 승인·소스

Owner는 APP82 후속과 중앙 스플래시 `6962c0f`의 전체 검증·main 병합/Push·양 OS 릴리스 빌드를 승인했다. 최초 인계 당시 “빌드만 해주고 위치 알려줘. 그러면 내가 웹에서 업데이트할거야”로 Codex 범위를 빌드·설정/서명 검증·파일 인계까지로 한정했다. 이후 제출 범위와 결과는 위 스토어 제출 후속을 따른다. 최종 IPA/AAB의 기기 설치는 하지 않았다. [기존 결정](decisions.md#2026-11-12--app83-최종-릴리스-진행-승인), [후속 UI·실기기 격리 근거](app82-post-rc-ux-20261112.md)를 계승한다.

- 사전 원격main `02977efc1aa0a61d4e9d261d9e089879b2fbfba5`는 RC의 ancestor. 원격 신규 커밋0, 충돌0.
- `d6aa0d8` 후속 UX와 `6962c0f759a9bdc21277fb5448cbabe1ac7a4dbb` 중앙 배치 모두 포함.
- 릴리스 준비 브랜치 `codex/app83-release-20261112`; 제품 빌드 소스 **`dbbb52e134d59beb8b57f5485b7d07e5a5b25596`**. `6962c0f` 대비 제품 변경은 pubspec 버전 `1.0.3+82` → **`1.0.3+83`**뿐이다.
- 검증 소스 그대로 main fast-forward, 원격 Push와 `ls-remote` SHA 일치 PASS. 다른 작업 브랜치 변경/force Push 없음. 최종 문서 커밋은 제품 빌드 소스와 구분한다.
- 논술·모의고사·기존 타이머 소스, Worker, 운영 migration은 APP82 대비 변경0. 승인된 학습 순위·홈 UI 변경은 전체 자동 회귀로 확인했다.
- Push에 연결된 운영 배포 workflow 없음. 자료 동기화 workflow는 기존 schedule/dispatch를 유지하며 이번 작업에서 실행하지 않았다.

## 신규 RPC 필수 여부

운영 읽기 전용으로 `student_school_ranking_page`, `my_study_percentile` 부재와 기존3개 조회 함수 정의 해시를 재확인했다. **앱 업데이트의 필수 의존성은 아니다.** PGRST202일 때 기존 TOP10/내 학교/주변 순위 조회로 복귀하며 개인 백분위는 숨긴다. 따라서 이번 배포에서는 추가 페이지·타 학교 순위권 밖 목록·개인 백분위가 활성화되지 않는다. 프런트 추정값은 표시하지 않는다. 후보 SQL은 Git에 보존하지만 운영 적용0이며 이후 별도 승인 대상이다. 기존3/1 임계 유지.

## 최종 검증

|항목|결과|
|---|---|
|전체 Flutter test|**2,580 PASS / 8 SKIP / 0 FAIL**, 118.190초|
|Flutter Analyze|PASS — No issues found|
|Python 설정·자료 동기화 회귀|33 PASS|
|신규/기존 격리 SQL|71 / 42 checks+assertions PASS, 운영 변경0|
|Android JVM|2 PASS / 실패0|
|main 소스 정합성|검증 소스와 fast-forward 통합 제품 소스 동일|
|iOS IPA|빌드·버전·Apple Distribution 서명·설정 PASS|
|Android AAB|빌드·버전·기존 업로드 서명·권한·16KB ELF 정렬 PASS|
|최종 IPA/AAB 설치·실기기|**NOT TESTED** — 최신 Owner 빌드 전용 인계 지시, 설치본 보존|
|Android 업로드·서버 수락|Owner 업로드, Console83(1.0.3) 수락 확인|
|Android 심사 전송|요청 완료 / Google 자동 검사 진행 중 / 승인·공개 미확인|
|iOS 스토어 제출|Owner 업로드 완료 보고 / 심사·실제 업데이트 NOT TESTED|

[검증 영수증·SKIP8·로그/산출물 해시](assets/app83-store-handoff-20261112/release-validation.json). 이전 `6962c0f`의 iPhone17ProMax 격리6항목 PASS를 최종 배포 바이너리 설치 PASS로 바꾸지 않는다. 공개 버전은 Apple 공식 조회에서1.0.2였으며, 미공개 빌드83 점유 여부/서버 수락은 Owner 업로드 단계에서 확인한다.

## 산출물

위치: `/Users/woojinchang/.codex/worktrees/app-release-rc-20261113/legendstudy-app/build/releases/app83/`

|파일|버전/빌드|bytes|SHA-256|
|---|---|---|---|
|`legendstudy-1.0.3-83.ipa`|1.0.3 / 83|34459315|`f598f46e5df50f0654b54070a12acfe38fe4ee1f376ae0032311b0a41905c97e`|
|`legendstudy-1.0.3-83.aab`|1.0.3 / 83|101852736|`7396b2c0ca55247c593b97c9bd894f954690a52fc8a85fc9b43419a5374b67fe`|

같은 폴더에 `SHA256SUMS`, `README.txt`, `Runner.xcarchive`/dSYM, export 설정/결과를 보관한다. Owner가 IPA/AAB 업로드를 완료했다고 보고했다. Android는 Codex가 Console83 수락 확인과 심사 전송 요청을 완료했고, iOS는 Owner가 App Store Connect에서 계속 진행한다.

- iOS bundle `com.legendstudy.app`, iOS15+, SDK27.2, Distribution profile/Apple Sign in/Google URL/복구 scheme 확인. `get-task-allow=false`, codesign deep/strict PASS. archive와 IPA App.framework UUID 일치, privacy plist26개 정상.
- Android package 동일, minSDK24/targetSDK36, debuggable=false. APP82와 같은 업로드 인증서, 권한 변화0/Billing 유지/AD_ID 없음. arm64/x86_64 ELF12개 LOAD alignment≥16KB. 실제 Play split APK 검증과 구분한다.
- 기존 production 공개 설정과 로그인/계정 삭제/논술 쓰기·평가/Analytics 플래그를 보존했다. 컴파일 대상은 `lib/main.dart`이며 격리 테스트 entrypoint가 아니다. 비밀키·프로필·keystore는 Git/Wiki에 저장하지 않았다.

## 보존·한계

기존 iPhone1.0.2(82) 앱은 조회만 했고 설치/삭제/로그아웃/사용자 데이터 수정0이다. APP82 IPA/AAB SHA-256 동일, 원본 archive/dSYM은 덮어쓰기 전에 `build/releases/app82/Runner.xcarchive`로 옮겨 보존했다. 운영 DB/RPC/Auth·WEB·Credit·평가 엔진·Provider 호출 변경0.

두 릴리스 빌드 모두 성공했다. IPA 검증 스크립트의 최초 entitlement 파싱은 현행 codesign의 텍스트 출력 때문에 실패했고, XML 출력 옵션으로 수정해 최종 검증 PASS했다(앱 수정/재빌드 없음). 기존 AGP/Kotlin 지원 예고·CupertinoIcons·flutter_tts SPM 경고는 이전 APP82와 같은 상태이며 이번 범위에서 의존성을 업그레이드하지 않았다.

신규 RPC 미활성, 기존 알림 Backend 오류/재시도 상태, 미저장 폼 완전 복원 한계는 그대로다. Owner가 올릴 대상은 APP82가 아닌 **APP83** 두 산출물이다.
