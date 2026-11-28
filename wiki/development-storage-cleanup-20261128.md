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
