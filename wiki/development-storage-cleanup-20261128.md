# Mac 개발 환경 정리 — 2026-11-28

**PARTIAL — 승인된 안전 정리 및 보존 검증 완료, 확보량 목표 미달.** Owner의 11/28 실행 지시에 따라 Phase A–I를 수행했다. 운영/DB/제품 소스/서명/PATH/FVM 설정 변경 및 전체 재빌드·재설치0. [현재 상태](current-status.md) · [원시 삭제 목록/측정 증거](evidence/development-storage-cleanup-20261128.json).

## 실제 디스크 확보

- APFS 물리 컨테이너 disk3/disk0s2: 총 994.66GB.
- 시작 여유 **15.12GB**, 정리 후 **152.16GB**, 실제 증가 **137.05GB**.
- APFS 사용률 **84.70%**; Data `df` 표시 **85%**.
- 최소 확보150GB보다 12.95GB, 기본200GB보다 62.95GB 부족. 여유152GB를 '150GB 확보'로 혼동하지 않는다.
- du 합계와 실제 확보량은 다르다. 특히 F 캐시9.43GB 제거 시 해당 관측 구간 APFS 증가는0.95GB였다. APFS 공유 블록/하드링크·시스템 비동기 회수·동시 쓰기 영향이 있어 개별 Phase 증가량을 전체 성과로 단순 합산하지 않는다.

## Phase별 결과

용량 단위 GB. '구간 증가'는 각 Phase의 시작/종료 APFS 관측차이며 독립 귀속 보증이 아니다. dyld 제거는 즉시0.22GB가 반환되고 후속 관측까지 지연 회수되었으며 최종 해당 캐시는0이었다.

| Phase | 실제 정리 | 대상 할당량 | 관측 구간 증가 | 보존/보류 |
|---|---|---:|---:|---|
| A | 66개 Dart/Android/Next/Gradle/npm/Xcode 캐시 + SHA 검증 api-source 중복2벌 | 73.41 | 73.39 | 기준 소스·lockfile·manifest·배포 기록·출시 출력 유지 |
| B | Xcode 중간 캐시16개, 초기 데이터 동일 시뮬레이터33개; 공식 dyld 캐시 제거 | 6.30 + dyld 약7.04 | 6.23 | 45→12개; 런타임3종·DeviceSupport·Archive·CoreDeviceService 유지 |
| C | SDK Sources4종·미참조 Platform4종, Gradle 캐시5개 | 4.79 | 4.86 | Platform35/36·NDK26.3/27.0/28.2·AVD2개·system-image36 유지 |
| D | 미참조 flutter-latest 1개 | 1.55 | 1.56 | 동일 HEAD/tree의 FVM3.47.6 유지; 활성 PATH/FVM 설정 변경0 |
| E | 과거 TEST Intermediates·SPM artifacts·백업 node_modules·iap 검수 캐시26개 | 19.70 | 19.77 | 고유 소스·DB·원본·검수 로그·모든 Archive/dSYM 유지 |
| F | 생성 의존성/Gradle 캐시39개, 종료 worktree3개 | 9.49 | 1.03 | 공통 .git·브랜치·미병합/미푸시/미커밋 작업 보존 |
| G | Claude HTTP/GPU/컴파일 캐시6개 | 0.90 | 0.93 | VM/sessiondata.img·세션·IndexedDB·설정 유지 |
| H | 삭제0: Docker daemon 종료 상태 | 0.00 | 0.00 | 서비스 시작0; Docker.raw·Volume·로컬DB 보존 |
| I | Dart/Adobe/pip/Homebrew/SPM/Manus/VS Code 캐시16개 + 빌드 캐시21개; conda 공식 clean | 20.14 + conda 논리0.73 | 21.41 | 개인 파일·영상 원본·프로젝트·설정·Python 환경·작업 이력 유지 |

정확한 삭제 경로·수량·명령별 결과는 JSON 증거에 있다. /private/tmp의 소규모 실행 기록에는 삭제 로그와 비공개 보존 해시가 있으며, 인증정보 값과 비공개 baseline 전체는 Wiki에 게시하지 않았다.

## Git와 출시 소스 보존

- 시작 공식 APP main `d748abb3`, 출시88 `08345b69`, 후보89 `76cc4050` 및 후보 checkout `b894ffb`, 운영 작업 `6446075`, WEB 운영 checkout `513e641` 확인. 공식 main 원격 SHA 일치. 이번에 스토어·운영 배포 상태를 새로 검증하거나 변경한 것은 아니다.
- 정리 전61개 Git checkout 기록. 미참조 SDK1개와 종료 worktree3개 제거 후 **57개 유지**. 제품 공통 Git·브랜치·refs·남은 checkout HEAD 및 기존 tracked/untracked 상태는 Wiki 기록 전 대조에서 불일치0.
- 종료 worktree: `development/legendstudy-analytics-claude-20261030`, `development/legendstudy-app-ux-beta-20261028`, `development/legendstudy-admin-ui-20261023`. 최신 원격 main ancestry·clean 상태·ignored가 DS_Store뿐임·실행 CWD 없음 확인 후 `git worktree remove` 사용. force/reset/브랜치 삭제/push/제품 main 병합0. 해당 branch와 커밋은 공통 Git에 유지.
- APP89 AAB SHA256 `ec01a477de470036da208352dfd0b140b324c1d442ed6c06148bfb6a05c87567`, IPA `28bf4601491e0f5f0f35785e2240960a9fd10f970b1d643cc13e80cbe0c68e5d` 보존. 실제 release와 후보 Archive/dSYM은 모두 유지.
- Wiki 출판은 문서 전용 커밋으로 main HEAD를 전진시킨다. 이는 위 제품 소스 변경이나 미출시 제품 코드 병합이 아니다. 코드/설정 파일의 변경은 없다.

## 유지 개발 환경

- Flutter7개: `development/flutter`3.32.0, `development/flutter-3.47`3.47.5, `development/flutter-muselry`3.47.7, `fvm/versions/3.32.0`, `3.47.6`, `3.47.7`, `stable`3.47.7. `fvm/default`는3.32.0이며 기존 PATH와 프로젝트 설정 유지. 삭제한 flutter-latest는 FVM3.47.6과 HEAD/tree 동일·clean·원격 밖 커밋0·활성 설정 참조0. 2~3개 통합은 활성 참조 정리 계획이 필요하다.
- Android Platform35/36, NDK26.3.11579264/27.0.12077973/28.2.13676358, Build Tools 기존4종 유지. LegendStudy28.2·Muselry27.0, 구형 PATH SDK/scaffold26.3 참조 보존. SDK Manager의 기존 XML version 경고는 발생했으나 제거8종은 exit0 및 경로 부재 확인.
- AVD `LS_phone`, `LS_tablet`, 공통 Android36 google_apis arm64 이미지 유지. 내부 사용자 데이터의 폐기 가능성이 입증되지 않아 삭제하지 않았다.
- iOS Runtime18.6/26.5/27.0 모두 유지. 시뮬레이터는 사용 상태10개 + 초기 데이터 기준2개 =12개 유지(27.0:3,26.5:5,18.6:3,16.0:1). 마지막16.0은 런타임 없는 소규모 기준 기기다. 3~5개 목표는 QA 상태 확인 후 후속으로 둔다.
- Xcode Archives15개와 프로젝트/백업 내부 Archive·dSYM 유지. DerivedData는 약4.6MB로 감소. DB 덤프·논술 원본·환경/서명 파일 보존.
- conda clean dry-run 후 tarball714,889,455B와 미사용 패키지11,728,226B 후보만 공식 정리. 환경→패키지 캐시 symlink0 및 conda-meta 전후 일치. pkgs 전체 강제 삭제 없음.

## 추가 확보 후보와 보류 이유

| 대상 | 현재/기준 용량 | 필요한 확인·영향 |
|---|---:|---|
| Xcode DeviceSupport4종 |25.09GB|실기기가 unavailable이므로 현재 OS 확인 불가. Owner가 실제 기기/OS를 확인하면 구버전 지원 파일만 선별 가능|
| 남은 Simulator 데이터 |약29GB|앱/Draft/QA 상태의 폐기 여부 확인 필요. 삭제하면 로컬 상태 복구 불가|
| Android AVD2개 |8.49GB|모바일·태블릿 QA 필요성과 고유 userdata 확인 필요|
| Claude VM bundle |13.01GB|sessiondata.img 존재. 고유 작업/공식 재생성/기능 영향 미확인. 별도 승인 후보이며 이번 삭제0|
| Docker.raw |11.87GB 할당 /64GB 논리|daemon 종료. system df/컨테이너 조사 NOT_TESTED; 임의 시작0. 승인된 실행 상태에서 이미지/cache만 확인, Volume/DB는 별도 승인|
| SDK 통합·SPM 저장소 캐시 |추가 검증 필요|활성 참조와 SDK 버전 유지가 우선. 남은 SPM bare repository 캐시 약3.35GB는 고유 refs 전수 대조 없이 삭제하지 않음|
| CoreDeviceService |Owner 사전 조사 약3.7GiB|전체 삭제 금지, 지원되는 정리 방법 미확인으로 보존|
| Adobe Media Encoder2025/2026 |미측정|두 앱 설치 확인. 애플리케이션 제거는 별도 Owner 판단|

Desktop·Documents/Downloads 개인 자료·클라우드 동기화 자료·Time Machine/APFS snapshot·Preboot/Recovery/VM 볼륨·휴지통 전체는 정리하지 않았다. Documents의 개발 checkout 내부 생성 캐시만 명시 목록대로 정리했으며 개인 파일은 대상이 아니다.

## 검증과 한계

- **PASS**: 보존 snapshot의 고유 파일 해시 11,569개 항목 및 Archive/symbol metadata 7,909개 항목을 승인된 checkout 제거 예외와 대조, 불일치0. 이는 모든 디스크 파일의 전체 해시 검증을 뜻하지 않는다.
- **PASS**: 남은 Git HEAD/refs/기존 변경 상태, APP89 실제 두 파일 SHA, DB·원본 자료, 활성 SDK/NDK/AVD/런타임 참조 보존.
- **PARTIAL**: 실제 증가137GB 수준으로 최소150/기본200GB 목표 미달. 불확실한 고유 상태를 삭제하여 수치를 맞추지 않는다.
- **NOT_TESTED**: 실제 앱 실행/전체 재빌드/의존성 재설치, Store/Production DB/API 재검증, Docker 내부 사용량. 캐시·node_modules 제거 후 다음 개발 시 기존 lockfile 기반 의존성 복원과 캐시 재생성이 필요하며 디스크 사용량이 다시 증가할 수 있다.
- 공식 main Wiki 출판 후 `python3 tool/check_wiki_handoff.py --official`로 링크/라우팅/원격 일치를 확인한다. 이 검사는 외부 서비스 정상성을 보증하지 않는다.

## 향후 개발 환경 관리 정책

기존 AGENTS 보존·공식 Wiki 규칙에 추가하는 운영 절차이며 제품 정책/권한 확대가 아니다.

1. 작업 종료 전 Git 작업 보존·미푸시/미병합/ignored 고유 파일과 공통 Git을 확인한다. 종료 조건 충족 worktree만 정식 remove로 정리하고 브랜치는 임의 삭제하지 않는다.
2. 최종 출시/현재 후보·DB/원본·검수 핵심 증거를 유지하면서 생성 캐시와 종료 TEST 산출물은 분리 정리한다. 의존성·DerivedData를 백업에 반복 포함하지 않는다.
3. 동일 목적 시뮬레이터/SDK를 추가하기 전에 기존 설치를 재사용한다. 활성 버전/PATH/FVM 변경은 별도 검증 계획을 따른다.
4. 대형 빌드 전후 APFS 실제 여유를 기록한다. **정상≥200GB, 주의<150GB, 경고<100GB, 긴급<50GB**. 150~200GB는 정상 목표 미달 구간이다.
5. 용량 부족 시 개인 자료·고유 상태·출시 복구 자료를 임의 삭제하지 않는다. 삭제량 합계 대신 APFS 전후 차이와 보류 목록을 공식 Wiki에 남긴다.


## Phase 3 — 잔여 환경 최적화 (2026-11-28, PARTIAL)

Phase 2 결과와 evidence를 재사용했다. 시작 공식 main/원격 main은 `d222c1e`. 아래 수치는 10진 GB이며 APFS disk3의 CapacityFree 차이로 평가했다. Phase 2 이후 환경 쓰기로 시작 여유가 달라졌으므로 단계별 증가량을 합산한다.

| 측정 | GB | bytes |
| --- | ---: | ---: |
| Phase 3 시작 | 151.809 | 151809454080 |
| Phase 3 종료 측정 | 154.600 | 154599690240 |
| Phase 3 실제 확보 | 2.790 | 2790236160 |
| Phase 2+3 누적 확보 | 139.836 | 139836317696 |
| 누적 200GB까지 부족 | 60.164 | 60163682304 |

추가62.95GB·권장80GB와 누적200GB 목표는 미달이다. 고유 데이터 기준은 완화하지 않았다. Owner 질문은 실기기/OS, 기기별 QA 상태, 런타임 유지 조합으로 분리하여 전달했으며 응답 전 관련 항목을 보류했다.

### 실행 항목

| 경로/대상 | 삭제 전 용량 | 용도·분류 | 판단 근거 | 삭제 방법·복구 |
| --- | ---: | --- | --- | --- |
| `~/Library/Android/sdk/ndk/26.3.11579264` | 3.176GB | 과거 NDK / SAFE_DELETE | 현재 APP28.2, Muselry27.0 명시. 26.3은 구 Flutter3.32 기본값의 과거 환경용이며 현재 공식 빌드 요구 아님 | sdkmanager `--uninstall ndk;26.3.11579264`, exit0·부재 확인. 필요 시 같은 버전 재설치 |
| 초기 iPhone18Pro/iOS27 `C38F2E2C…` | 0.018GB | 초기 seed / SAFE_DELETE | 이전 seed 해시 대조 + 현재 앱 bundle/data container 없음·25MB 미만 | `simctl delete` 해당 UUID. 같은 기기 재생성 |
| 초기 iPhone14ProMax/iOS16 `23463D3C…` | 0.014GB | unavailable 초기 seed / SAFE_DELETE | 같은 검증, 설치 런타임 없음 | `simctl delete` 해당 UUID. 필요 시 런타임·기기 재설치 |
| Docker logflare1.50.2 / studio2026.08.10-sha-5b68af1 / edge-runtime1.74.3 / vector0.53.0-alpine | 이미지 약2.67GB, 공유 layer 제외 추정 약2.42GB | 공식 재다운로드 이미지 / SAFE_DELETE | 전체9컨테이너의 Image ID와 대조하여 참조0 확인 | 4개 명시 tag `docker image rm`, force 없음. 동일 tag 재다운로드 |

파일/이미지 합계를 APFS 확보량으로 간주하지 않는다. Docker 내부 삭제가 가상 디스크 반환으로 즉시 연결되지 않았으며, 실행 중 시스템 쓰기도 차이에 포함된다.

### DeviceSupport

4개 모두 OWNER_REVIEW로 유지: iPhone13,4/iOS26.6 약5.965GB,26.6.1 약5.965GB; iPhone18,2/iOS26.4.2 약6.074GB,27.0.1 약7.087GB. `devicectl list devices`에서 iPhone12ProMax unavailable, 다른 연결 실기기 없음. 현재 기기·OS 확인은 NOT_TESTED이며 Owner에게 필요한 조합을 질문했다. DeviceSupport 경로는 실제 release Archive/dSYM 경로와 별개다. 삭제 전 OS 확인 조건이 충족되지 않아 이번 실행에서는 삭제하지 않았다. Archive/dSYM 보존 대조 PASS.

### 시뮬레이터 12→10개

| 기기 (UUID 앞부분) | iOS | 실제 GB | 최근 로그 날짜 | 설치 테스트 앱 | 판단 |
| --- | --- | ---: | --- | --- | --- |
| LegendStudy-Intro-QA-20261019 (`304FA839`) | 27.0 | 3.690 | 2026-10-19 | 설치 bundle 없음 | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPad Pro 13-inch (M5) (`9086E133`) | 27.0 | 2.778 | 2026-10-19 | com.legendstudy.app 1.0.0(19) | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPhone 17 Pro (`AEC17AF7`) | 26.5 | 4.467 | 2026-10-14 | dev.legendstudy.scaffold 0.1.0(1), com.legendstudy.app 0.1.0(1) | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| LegendStudy First Run QA (`565DF269`) | 26.5 | 3.801 | 2026-11-12 | 설치 bundle 없음 | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPhone 17 Pro Max (`0DF19D83`) | 26.5 | 3.384 | 2026-11-12 | com.legendstudy.app 0.1.0(1) | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPhone 17e (`2CDF0FCD`) | 26.5 | 2.799 | 2026-10-09 | com.legendstudy.app 0.1.0(1) | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPhone 17 (`E6311A43`) | 26.5 | 3.378 | 2026-10-09 | com.legendstudy.app 0.1.0(1) | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPhone 16 Pro (`24F2615D`) | 18.6 | 2.535 | 2026-11-26 | 설치 bundle 없음 | KEEP: 최근 인증 QA |
| iPhone 16e (`03926D8E`) | 18.6 | 1.168 | 2026-10-09 | 설치 bundle 없음 | OWNER_REVIEW: 미완료 QA·Draft 확인 대기 |
| iPad (A16) (`6FDB6A0C`) | 18.6 | 1.184 | 2026-10-09 | 설치 bundle 없음 | KEEP: 태블릿 QA |

최근 로그는 최종 사용 시각의 증명은 아니다. 제3자 앱 data metadata 조사에서 iPadM5·iPhone17Pro·17ProMax·17e·17에 0.89~1.64MB 앱 상태가 남아 있었다. DB 확장자 파일·draft라는 파일명은 없었지만 preferences/keychain 등에 고유 상태가 없다는 증명이 아니므로 폐기하지 않았다. 설치 bundle 없음도 QA 상태 없음으로 단정하지 않았다. First Run QA는 한국항공대 운영 검증 기록, iPhone17Pro는 기존 scaffold/학습 QA, iPhone16Pro는 최근 인증 렌더 QA와 연결된다. Muselry 현재 앱은 남은 simulator bundle에서 확인되지 않았다. 유지3~5개는 Owner가 종료 상태를 지정한 뒤 진행한다.

### 런타임

| 런타임 | 관리 도구 sizeBytes 기준 GB | 마지막 runtime 사용(UTC) | 판단 |
| --- | ---: | --- | --- |
| iOS18.6 | 8.838 | 11/25 13:24 | KEEP: 최근 인증 QA |
| iOS26.5 | 8.494 | 11/12 02:40 | OWNER_REVIEW: First Run 및 여러 QA 상태 연결 |
| iOS27.0 | 8.067 | 10/19 10:05 | OWNER_REVIEW: Intro QA·iPad 상태 연결 |

현재 코드의 최소 iOS는 양 앱15.0. Muselry 과거 build47의13.0 기록은 현재15.0 설정과 구분했다. 최소OS 자체가 3개 런타임 모두 설치해야 한다는 근거는 아니며, 현재18.6 + Owner가 필요한26.5/27.0 중1개로 2개 유지가 가능하다. iOS15 실기기 호환성 검증은 NOT_TESTED. Owner 응답 전 현재 런타임 제거0. 실행 시 Xcode 관리/`simctl runtime delete`를 사용하고 마운트/APFS 컨테이너를 직접 삭제하지 않는다.

### Flutter 7개 및 참조36개 재분류

참조 단위 집계 A=6, B=10, C=20, D=0, E=0. 전체36개의 경로·파일·분류는 기존 evidence JSON의 `phase3.sdk_references`에 포함했다. A는 공식 출시·후보, B는 현재 개발 또는 미병합 작업 보존, C는 과거 checkout 재현용(필요성 미확정), D는 종료가 입증된 생성 설정, E는 완전 미참조 중복을 뜻한다. 중복 버전이어도 활성 alias가 있으면 E로 단정하지 않는다.

| SDK | 버전 | 기존 실사용량 GB | 생성 설정 참조 수 | 추가 근거·판단 |
| --- | --- | ---: | ---: | --- |
| `~/development/flutter` | 3.32.0 | 4.71 | 2 | PATH 기본, 개인 Documents checkout 참조 유지 |
| `~/fvm/versions/3.32.0` | 3.32.0 | 2.04 | 0 | `fvm/default` 참조 있음. 위와 HEAD 동일 |
| `~/development/flutter-3.47` | 3.47.5 | 4.23 | 3 | ga4·feedback checkout 참조. main 밖 커밋51/10으로 종료 판정 불가 |
| `~/fvm/versions/3.47.6` | 3.47.6 | 3.11 | 23 | 공식 main·APP89 및 기존 작업, KEEP |
| `~/development/flutter-muselry` | 3.47.7 | 2.80 | 4 | Muselry 개발·출시 참조, KEEP |
| `~/fvm/versions/3.47.7` | 3.47.7 | 2.20 | 2 | 현재 service-app generated config 참조, KEEP |
| `~/fvm/versions/stable` | 3.47.7 | 6.09 | 2 | iap-fix 참조 + 현재 service-app `.fvm/flutter_sdk`가 직접 가리킴, KEEP |

같은 버전들의 tracked HEAD는 동일하고 tracked 변경0이었다. 전체 SDK 고유 ignored 파일 삭제 검증은 진행하지 않았으므로 삭제 승인 근거로 사용하지 않는다. 36개 generated 참조 외 PATH/FVM alias를 포함하니 **현재 참조 변경 없이 제거할 수 있다고 검증된 SDK는0개**다.

통합 계획: 3.32.0은 `development/flutter`,3.47.6은 FVM,3.47.7은 FVM으로 3개 유지한다. 이를 위해 (1) fvm/default를 같은3.32.0 보존 경로로 변경, (2) Muselry 두 checkout의 local.properties/Generated.xcconfig를 동일3.47.7 FVM 경로로 변경, (3) stable 설치를 동일3.47.7 alias로 통합하되 current service-app/iap-fix 참조를 검증해야 한다. 약10.93GB의 동일버전 중복이 후보지만 APFS 실회수량은 별도다. 3.47.5는 두 작업의 종료·재현 필요 확인 후 같은 버전 다운로드 재현으로 전환할 때 추가 약4.23GB 후보가 된다. 유지 SDK3개 달성에는 이 판단이 선행한다. 공식 버전 변경·제품 소스 변경은 계획에 포함하지 않는다. 활성 참조 변경은 별도 승인 전 실행0. 기존 SDK 크기는 Phase2 조사값이며 Phase3에는 HEAD·참조를 재검증했다.

### Android

NDK27.0(Muselry)·28.2(APP), 플랫폼35/36, 기존 Build Tools는 유지. Build Tools 개별 사용 여부는 추가 확정하지 못해 삭제하지 않았다. LS_phone6.603GB는 userdata11/26 기록으로 현재 QA 연관, LS_tablet1.883GB는 태블릿 UI 검증 환경으로 KEEP. 두 AVD는 Android36 google_apis arm64 공용 system image를 사용하므로 해당 image도 유지한다. Android 빌드 프로세스 없는 상태에서 NDK26.3만 공식 제거했다. 과거3.32 기반 Android 재현에는26.3 재설치가 필요할 수 있다. 현재 빌드 실제 재실행은 NOT_TESTED.

### Docker

Docker Desktop 시작 전/후 APFS를 별도 evidence로 기록했다. 설치 버전의 desktop CLI가 지원되지 않아 `open -a Docker`로 시작했다. 기존 restart policy에 따라 로컬 Supabase8컨테이너 자동 시작됨; 별도 DB 질의·마이그레이션·Supabase start 명령0. 전체 컨테이너9개(restore-test 포함), 볼륨30개(약1.534GB)를 보존했다. 고유 writable layer도 삭제0. 삭제 후 이미지8개 모두 기존 컨테이너가 참조한다. Build cache0B, prune 불필요.

Docker.raw 논리64GB/실할당 약11.87GB. 공식 [Mac 공간 회수 안내](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/macfaqs/)를 확인하고 `docker run --rm --privileged --pid=host docker/desktop-reclaim-space`를 시도했으나 이미지 다운로드 단계에서 응답 없이 대기하여 해당 요청만 중단했다. helper 실행/공간 반환 완료는 NOT_TESTED. 가상 디스크 크기 축소·reset·전체삭제는 수행하지 않았다. 기존 컨테이너는 실행 상태로 유지했다. `system prune`/volume prune/컨테이너 삭제0.

### 보존 검증·추가 승인

Phase2 보호 기준 대조: 기존57 Git 저장소 HEAD/refs/전체 dirty 상태 불일치0; 보호 파일 기준11,569개 중 승인된 Phase2 삭제 경로 제외 나머지 해시 불일치0; Archive·dSYM7,909개 metadata 불일치0; SDK 참조36개 유효. APP89 IPA SHA256 `28bf4601491e0f5f0f35785e2240960a9fd10f970b1d643cc13e80cbe0c68e5d`, AAB `ec01a477de470036da208352dfd0b140b324c1d442ed6c06148bfb6a05c87567` 유지. DB·논술 원본·환경설정·서명 보호 해시 유지. 문서 게시만 official main의 허용 변경이며 별도 사후 검증한다.

Claude VM·sessiondata.img, Desktop·개인 파일, 제품 소스·운영 DB·배포·서명 설정은 변경0. 대규모 재빌드·신규 백업0. 앱 실행/실기기/전체 테스트·Docker DB 내용 논리검증은 NOT_TESTED. 기존 정리 보고서와 evidence에 추가했으며 별도 관리 문서는 생성하지 않았다.

보류 순서: 실기기 OS 답변 후 구 DeviceSupport → 기기별 종료QA 답변 후 simulator → 필요한 런타임2개 확정 → 동일버전 SDK 참조 통합 승인. 각 단계 후 APFS 차이·기존 보존 기준을 다시 검증한다. 현재 승인 전 확보 가능량을 확정 수치로 더하지 않는다.


## Phase 4 — 최종 통합 및 대규모 정리 종료 (2026-11-28)

**승인 범위 실행 종료. 용량 목표는 PARTIAL이며 추가 목표를 맞추기 위한 삭제는 하지 않는다.** 기존 Phase2/3 조사와 보호 기준을 재사용했다. 시작 공식 main/원격 main `5561b62`, 제품 출시88·미출시89 관계 유지. DeviceSupport는 이번 요청 직전 Owner가 iPhone12ProMax26.6.1 / iPhone17ProMax27.0.1을 명시했으므로 해당 확인을 적용했다.

### APFS 결과

| 항목 | GB | bytes |
| --- | ---: | ---: |
| Phase4 시작 여유 | 153.953 | 153952948224 |
| Phase4 종료 측정 여유 | 192.211 | 192211443712 |
| Phase4 실제 추가 확보 | 38.258 | 38258495488 |
| Phase2+3+4 누적 확보 | 178.095 | 178094813184 |
| 누적200GB 대비 부족 | 21.905 | 21905186816 |

APFS disk3 CapacityFree의 단계별 차이를 합산했다. 단계 사이 시스템 쓰기로 여유가 달라지므로 최초15.12GB와 최종 여유의 단순 차이로 누적치를 바꾸지 않는다. 디렉터리 용량 합계·runtime 논리 크기를 실제 확보량에 더하지 않는다. 약40~50GB 추가 목표에는 조금 못 미치지만 고유 SDK 파일을 보존하고 종료한다.

### iOS 정리 및 유지

- 공식 `xcrun simctl delete <UUID>`로 Intro-QA-20261019/iOS27, iPadPro13M5/iOS27, iPhone17e/iOS26.5, iPhone17/iOS26.5, iPhone16e/iOS18.6 제거. 과거 matrix QA는 [10/9 QA](app-release-finalization-2026-10-09.md#device-matrix-qa--simulator--emulator-only-no-physical-device) 및 기존 Wiki 기록을 재사용. 전 기기 shutdown, 현행 current-status 및 UUID/기기명/OS 검색에서 해당 기기를 사용하는 미완료 장애 재현·예정 검수 근거 없음. 앱 preferences의 Draft/pending 키, 앱/공유 컨테이너의 고유 문서 존재 여부를 점검했다. 남아 있던3개 `study-state-v1.json`의 `owners`는 모두 빈 값이며 앱 cache·로그인/intro 상태는 Owner 승인한 재생성 가능 종료QA 범위다. 고유 Draft 발견0. 역사 QA 문서는 보존했다.
- **시뮬레이터5개 유지:** iPhone16Pro/iOS18.6, iPadA16/iOS18.6, FirstRunQA/iOS26.5, iPhone17Pro/iOS26.5, iPhone17ProMax/iOS26.5. 기존 유지 기기 데이터 변경0.
- iOS27 관련 simulator0 확인 후 `simctl runtime delete 57C01475-65C3-40BB-9B46-3D1F4ABF8088 --dry-run`으로 정확한 대상 확인, 같은 UUID 공식 삭제 성공. **런타임18.6·26.5 유지**, 둘 다 Ready. 마운트/APFS 볼륨 직접 삭제0. 두 앱의 현재 최소iOS15.0 유지, 제품 설정 변경0.
- **DeviceSupport:** iPhone13,4/iOS26.6(23G71) 약5.966GB 및 iPhone18,2/iOS26.4.2(23E261) 약6.074GB 삭제. 현재26.6.1(23G83)·27.0.1(24A446) 유지. 실제 Archive/dSYM과 분리된 경로이며 보호 파일 overlap 검사와 삭제 후 Archive 대조 PASS.

### Flutter 통합 결과 — SDK 실체7→5

| 보존 SDK 경로 | 실제 실행 버전 | 종료 시 du 할당량 GB |
| --- | --- | ---: |
| `~/development/flutter` | 3.32.0 | 4.709 |
| `~/fvm/versions/3.32.0` | 3.32.0 | 4.712 |
| `~/development/flutter-3.47` | 3.47.5 | 4.235 |
| `~/fvm/versions/3.47.6` | 3.47.6 | 6.085 |
| `~/fvm/versions/3.47.7` | 3.47.7 | 6.138 |

`development/flutter-muselry`는 SDK 실체가 아닌 `fvm/versions/3.47.7` 호환 symlink로 유지한다. `fvm/versions/stable`은 제거됐으며 그 자리에 임의 링크를 만들지 않았다.

통합 검증: Muselry/stable SDK의 tracked 변경0·untracked0·동일HEAD 확인. source Git refs/reflog의97,492/98,298 commit 객체 모두 보존 SDK에 존재. 공통 cache 파일1,842/1,841개 해시 일치, 차이는 재생성된 flutter_tools.snapshot 및 버전조회 stamp뿐. ignored 파일은 .DS_Store·Dart/Gradle 생성 cache·도구 lock 등이며 별도 고유 패치 없음. stable에만 있는 동일엔진 macOS/Web 지원658파일을 보존 SDK로 **이동**, 개별 해시/심볼릭링크 대조 PASS. 신규 SDK 다운로드·의존성 재설치·대규모 백업 없이 플랫폼 지원 유지.

삭제 전 보존3.47.7 SDK의 `flutter --version --machine` 실행 확인. Muselry 중복 실체는 한정 경로 제거 후 호환 symlink 연결·같은버전 재실행 PASS. stable은 활성 참조 전환 후 **`fvm remove stable` 성공**. FVM 채널 관리 경로에 임의 alias 생성0.

### 로컬 참조 변경

- `development/muselry-app`, `development/muselry-app-release`: 각 `android/local.properties`, `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`의 `development/flutter-muselry`를 `fvm/versions/3.47.7`로 변경(6파일).
- `development/legendstudy-iap-fix`: 같은3개 생성 설정의 `fvm/versions/stable`을 `fvm/versions/3.47.7`로 변경(3파일).
- `development/legendstudy-service-app-20261022`: 기존 **Git 비추적** `.fvmrc` 및 `.fvm/fvm_config.json`을 공식 `fvm use 3.47.7 --skip-pub-get --skip-setup`으로 갱신. `.fvm/flutter_sdk`도 FVM이3.47.7로 연결. 실제 기존stable버전3.47.7을 유지한 것이며 다른 Flutter 버전으로 업그레이드하지 않았다.
- `.fvmrc`의 updateGitIgnore/updateVscodeSettings/updateMelosSettings/runPubGetOnSdkChanges를 false로 두어 tracked 설정·IDE 자동 변경·pub get을 방지했다. [FVM 설정 근거](https://fvm.app/documentation/getting-started/configuration).
- PATH는 기존 `development/flutter/bin` 유지(아래 보류 사유). `fvm/default`는 기존FVM3.32.0 유지. 개인 Documents checkout 변경0. 관련 shell/IDE 설정 검색에서 제거할muselry/stable 경로 추가 활성 참조 없음. 공식 빌드 helper·tracked 설정 변경0.

### 보류된 SDK1개 — 고유 파일 보존

`development/flutter`3.32.0은 HEAD/추적 소스가 보존FVM3.32.0과 같지만 **미추적 파일2,005개**가 있었다. 다른 보존SDK와 해시 대조해1,999개는 동일 내용을 확인했지만 아래6개 소스/테스트 파일은 동일 보존 사본을 확인하지 못했다. 이전 tracked-clean 기록을 SDK 전체clean으로 확대하지 않는다.

- `dev/integration_tests/widget_preview_scaffold/lib/src/widget_preview_rendering.dart`
- `packages/flutter_tools/lib/src/ios/lldb.dart`
- `packages/flutter_tools/lib/src/widget_preview/lsp_preview_detector.dart`
- `packages/flutter_tools/test/general.shard/build_system/targets/web_dry_run_test.dart`
- `packages/flutter_tools/test/general.shard/ios/lldb_test.dart`
- `packages/flutter_tools/test/integration.shard/isolated/native_assets_flutter_build_test.dart`

따라서 이 SDK 실체4.709GB와 기존 PATH·개인 checkout 참조를 유지했다. 고유 파일을 임의 이동·삭제·다른 SDK에 주입하지 않았다. 향후 Owner가 이6개 파일의 작업 목적을 판단할 수 있으나 **이번 대규모 정리의 추가 실행 단계로 남기지 않는다**. 미병합 작업이 있는3.47.5도 승인대로 유지한다.

### 최종 보존·환경 검증

- 각 보존SDK의 실제 `flutter --version --machine` PASS(3.32.0 두 설치,3.47.5,3.47.6,3.47.7). FVM4.1.0 `fvm list`에서 Global3.32.0·Local3.47.7 확인, `fvm flutter --version --machine`3.47.7 PASS. PATH·FVMdefault·호환 symlink 해석 PASS.
- 기존57개 저장소 HEAD/refs/dirty 상태 대조: 허용 SDK 통합 경로의 refs 변경만 제외하고 불일치0. 통합 source의 모든 Git commit 객체 존재를 별도 검증했다. 제품 tracked 소스·미커밋 작업 변경0. 공식Wiki 게시만 별도 허용 변경.
- 기존 보호 파일 중 Phase2 승인 삭제 경로를 제외한 **11567개** 해시 확인. 승인 로컬 참조11개는 변경 후 해시 및 변경 범위로 대조, 나머지 불일치0. Archive/dSYM7,909개 metadata 불일치0. DB·논술 원본·인증·서명·개인 파일·작업 이력 보존.
- APP89 IPA SHA256 `28bf4601491e0f5f0f35785e2240960a9fd10f970b1d643cc13e80cbe0c68e5d`, AAB `ec01a477de470036da208352dfd0b140b324c1d442ed6c06148bfb6a05c87567` 유지.
- 전체 앱 재빌드·실기기 설치/기능검수·실행 중 IDE 화면 재해석은 **NOT_TESTED**. SDK 버전 실행·경로 검증을 앱 전체 빌드 PASS로 간주하지 않는다.

### Docker·Claude 및 작업 종료

Phase4 실행 전 판단 자료 단계에서 관련 로컬 작업/클라이언트 연결이 없어 자동 시작8컨테이너를 정지하고 Docker 앱·backend·VM 종료를 확인했다. 컨테이너9개/Volume30개 보존. **Kong은60초 대기 후 exit137, PostgreSQL 정상 종료 완료 메시지는 확인하지 못했음**을 유지한다. DB 자체 종료 요청을 했으나 정상 종료 완료·데이터 논리 상태는 NOT_TESTED. 다음 로컬 Supabase 개발 재개 시 DB 기동·복구 로그·기존 데이터 상태를 확인한다. 이 기록을 정상 종료 PASS로 정정하지 않는다.

이번 Phase4에서는 Docker 재실행0, 컨테이너/Volume/DB 삭제0, Claude VM·sessiondata.img 변경0. Owner가 확인한 실기기OS는 기록 완료이며 추가 기기 질문 없음. 대규모 정리는 여기서 종료한다. 별도 중복 관리 문서 생성0.
