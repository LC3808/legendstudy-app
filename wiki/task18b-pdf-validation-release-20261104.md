# TASK18-B PDF 검증·후속 릴리스 준비 — 2026-11-04

[기존 구현](task18-popular-pdf-20261104.md)과 [18개 게시글 목록](task18-popular-pdf-inventory-20261104.md)의 후속이다. Owner는 기존 구현을 승인하고 Commit/Push 및 격리 TEST 검증을 요청했다. 운영 DB·공개 다운로드·Auth/Credit/Ledger/결제 변경, 전체 브랜치 병합, APP58 대체, 스토어 제출은 금지한다.

## Git 보존

- 전용 `codex/popular-pdf-task18`, 기준 `92d8110ecd66891debff6528d0287858b7a2dc1e`에서 시작했다.
- TASK18의 30개 파일을 `8f83f3f6b6f1198e86d743c3a133a96cda9f6218`로 독립 커밋하고 같은 원격 브랜치에 Push 완료했다. 타 작업 파일을 포함하거나 삭제하지 않았다.
- 이전 구현의 전체 1,505 PASS/7 SKIP, 서버46 PASS, 양OS 빌드 기록을 확인했다. 커밋 직전 서버46 재실행·Wiki 검사·diff/민감정보 검사 PASS. 테스트 URL의 credential=test/x는 합성 fixture이며 실제 서명 URL/비밀키는 없다.
- 후속 변경은 다운로드 이벤트의 요청된 공개 자료 컨텍스트, 합성 QA 진입점, 검증 기록으로 제한한다. 최종 SHA는 Git 이력과 완료 보고를 참조한다.

## 인벤토리 정합성

[재계산 JSON](evidence/task18b-inventory-reconciliation-20261104.json)은 기존 원문·Registry 조사 JSON 전체 행을 재계산했다. 이번 작업에서 Registry 변경/파일 복제/운영 PDF 다운로드는 0이다.

| 항목 | 수 |
|---|---:|
| 게시글 | 18 |
| 게시글–PDF 연결 | 846 |
| 고유 원본 source key / unsigned URL / Registry resource ID | 각 846 |
| 동일 원본 key/URL의 중복 참조 | 0 |
| 문제지 | 420 |
| 정답·해설 | 416 |
| 기타(듣기대본) | 10 |
| Registry 미연결 | 0 |
| 고유 파일명 | 845 |
| 바이너리 내용 기준 실제 고유 PDF | NOT_VERIFIED |

846은 연결 건수이며 원본 식별자 기준으로도846개다. 원본 바이너리 해시를 수집하지 않아 내용 기준으로 서로 다른 파일846개라고 단정할 수 없다. 게시글1618의 `2025학년도 6월 s_생활과윤리 문제.pdf`는 같은 이름으로 두 번 존재하나 source key는 `7hOKZ/btsH1DtW933`, `upcYM/dJMcafBoTJm`로 다르다. 임의 삭제·합치기·복제하지 않는다. 내용 중복 판정은 허용된 후속 바이너리 검증에 남긴다.

## 다운로드 권한·회귀

- 전체 PENDING/공개 다운로드0 유지. 앞선 운영 RPC read-only 관측은404/PGRST202로 후보 미설치. 저장소 SQL/Edge 존재를 운영 배포로 간주하지 않는다.
- Edge46 PASS(다운로드8+기존 resolver38): PENDING/VIEW_ONLY/OFFICIAL_LINK/unknown은 원본 fetch 전에 거절, ALLOWED만 허용, resolve 뒤 철회 재확인, 임의 target 요청 거절.
- 기존 격리 PostgreSQL fixture PASS: 기본 PENDING, ALLOWED, 원본 key 변경/비활성/대상 게시글 제거 시 PENDING, VIEW_ONLY, 권한·이력 보호. 운영에서 정책을 변경하지 않았다.
- Flutter 전체 **1,506 PASS / 7 SKIP / 0 FAIL**, Analyze0. 후속 Android debug APK 빌드 PASS, iOS 별도 QA Release 빌드 PASS. 기존 PDF Viewer/loader/resource delivery 회귀 포함. 자동 회귀 PASS를 실제 저장·파일앱 열람 PASS로 대체하지 않는다.
- 운영 서버 다운로드 E2E는 미배포/권리 미확정으로 NOT_VERIFIED. 실제 공개를 위한 ALLOWED 전환은 하지 않는다.

## 실제 기기와 격리 검수

iPhone12ProMax 연결·개발모드·설치 목록 조회 성공. 본앱1.0.1(58)과 LS Math TEST1.0.1(56) 확인. 별도 `com.legendstudy.app.task18qa` / LS PDF TEST1.0.0(1)의 Release AOT 빌드·codesign strict/deep 검사·실기기 설치·실행 PASS. 설치 후 본앱58·Math TEST56 보존 확인. 실제 출제 자료 대신 직접 만든1페이지 합성 PDF를 사용한다.

`tool/qa/pdf_download_main.dart`는 기존 다운로드 위젯·서비스·Native MethodChannel·PDF Viewer를 재사용한다. Supabase/Firebase 초기화가 없고 네트워크 loader/권한은 fixture로 대체한다. OFFICIAL_LINK 버튼만 사용자 선택 시 공개 페이지로 이동한다. 실패 스위치는 모의 loader 오류이며 실제 통신 단절 시험이 아니다. GA4는 Noop이므로 이 앱의 클릭을 GA4 실수신 증거로 사용하지 않는다.

Owner가 실제 iPhone12ProMax에서 아래6개 검수 묶음에 “모두 성공”으로 응답했다. 관측 주체는 Owner이며 에이전트가 화면을 직접 관측했다고 기록하지 않는다. Simulator 빌드(기존 TASK18)·이번 device Release 컴파일과 실제 파일 앱 저장 검증을 구분한다. Android adb 연결 기기0: 실제10항목 모두 **NOT_VERIFIED**. 불필요한 저장소 권한을 추가하지 않았다.

### iOS Owner 실제 기기 결과

| 요청 검증 항목 | 결과 |
|---|---|
| 다운로드 버튼 표시 | PASS — ALLOWED |
| 저장 위치 선택 | PASS — Native 파일 저장 UI |
| 파일 앱 저장 | PASS — 합성 PDF |
| 저장 완료 안내 | PASS |
| PDF 정상 열람 | PASS — 파일 앱에서 합성 문구 확인 |
| 파일명 확인 | PASS — `레전드스터디_합성_검수.pdf` |
| 중복 다운로드 | PASS — 동일 PDF 다시 저장·중복 처리 확인 |
| 네트워크 실패 | 모의 loader 오류 안내 PASS / 실제 통신 단절 NOT_VERIFIED |
| 재시도 | PASS — 실패 스위치 해제 후 저장 |
| 기존 PDF Viewer | PASS — 합성 PDF 표시 |

추가: PENDING·VIEW_ONLY에서 다운로드 버튼 없음, OFFICIAL_LINK에서 공식 페이지 버튼 표시도 Owner PASS. 서버 권한은 별도 자동 검사로 검증했으며 이 fixture UI를 실제 운영 서버 ALLOWED E2E로 간주하지 않는다. OFFICIAL_LINK 실제 외부 페이지 도착은 버튼 표시 확인과 구분해 NOT_VERIFIED다.

### 완료 기준별 판정

| 기준 | 판정 |
|---|---|
| A Git Commit·Push | PASS — 기존8f83f3f, 검증후속38062bc 및 최종 문서 커밋 |
| B 인벤토리 정합성 | PASS(원본 식별/연결), 바이너리 내용 고유성 NOT_VERIFIED |
| C iOS 실제 다운로드 | PASS(합성 PDF Owner 검수), 실제 통신단절 제외 |
| D Android 실제 다운로드 | NOT_VERIFIED — 연결 기기 없음 |
| E 다운로드 권한 | PASS(격리 SQL/서버/클라이언트), 운영 E2E NOT_VERIFIED |
| F GA4 실제 수신 | NOT_VERIFIED |
| G 기존 Viewer 회귀 | PASS(전체 자동검사 + iOS 합성 PDF Owner 확인), Android 실기기 제외 |
| H 후속 병합 계획 | PASS(계획), 실제 전체 통합은 충돌 해결 필요 |

## Analytics v1 및 실제 수신

요청 이벤트명은 `pdf_download_click`, `pdf_download_success`, `pdf_download_failure`이며 기존 취소 이벤트도 유지한다. 실제 native 저장 완료 뒤에만 success를 기록한다. 기존 AnalyticsService를 재사용한다.

기존 TASK18은 platform/screen/source/status만 보냈다. 이번에 공개 게시글 경로 `post_id`, Registry UUID `resource_id`, 열거형 `resource_type`을 추가하고 허용 형식을 검사한다. 파일명/URL/원문/학생 정보는 추가하지 않는다. WEB 공통31 이벤트·14키는 유지하고 Native4 이벤트·3키 확장을 명시한다. 계약 검사 PASS(35이벤트/17키), sanitizer·위젯 컨텍스트 테스트 PASS.

2026-11-04 GA4 기존 속성396674471을 읽기전용 조회했다. ALL 목록의3개 스트림은 모두 WEB(legendstudy.com, lab.legendstudy.com, home.legendstudy.com)이며 native iOS/Android 스트림은 관측되지 않았다. DebugView는 디버그 기기0·최근30분 인기 이벤트0. 저장소에 native Firebase 설정 파일도 없고 기본 Analytics는 비활성/Noop이다. **클릭·성공·실패 및 요청 컨텍스트의 실제 GA4 수신은 NOT_VERIFIED**다. 스트림/설정/동의 상태를 변경하거나 가짜 성공 이벤트를 주입하지 않았다. 기존 웹 트래픽은 Native PDF 수신 증거가 아니다.

## 후속 APP 통합 계획 (병합하지 않음)

원격 fetch 후 candidate B HEAD는 `92d8110`으로 이번 작업의 조상이다. 이 기준에 TASK18을 올리는 것은 Git상 fast-forward 가능하다. 온보딩 V2, 수리·상경논술, 학습용5단계, 앱 업데이트 안내, 기존 Viewer 구현은 이미 기준 브랜치에 있으며 자동 회귀에 포함한다. 기존 품질/실기기 HOLD를 해제하지 않는다.

별도 최신 `origin/codex/admin-analytics-phase2-20261104` (`f3cb366`)의 이용권 표시·문의 답변 변경까지 포함하는 전체 병합은 **충돌 있음**. `git merge-tree --write-tree` 계산만 수행했고 브랜치/작업 파일/index는 병합하지 않았다.

충돌 파일:
- `lib/features/credits/credit_history.dart`
- `test/credit_history_test.dart`
- `wiki/current-status.md`
- `wiki/decisions.md`
- `wiki/essay-beta-credit-design-20261027.md`
- `wiki/index.md`
- `wiki/log.md`

이는 candidate B와 관리자 브랜치의 기존 분기 차이이며 PDF 기능이 Credit을 변경해서 발생한 충돌이 아니다. 후속 승인된 통합에서 현재 이용권 표시 규칙과 `credit_display.dart`의 reason_code 기반 표시를 대조하고, 원본 Ledger/집계 의미를 유지하며 UI·테스트를 함께 해결해야 한다. Wiki는 양쪽의 유효한 결정/증거를 보존하고 current-status 예산을 지킨다. feedback_page는 자동 합쳐지지만 문의→내 문의·답변→상세 흐름과 계정 전환 회귀가 추가로 필요하다. 이번 작업에서는 Credit/문의 코드를 수정하지 않았다.

진행 순서: 통합 대상 SHA 고정 → 지정 기능 변경만 검토·충돌 해결 → 전체 Flutter/Native·권한/Viewer 회귀 → 양OS 실기기 → 승인된 Native Analytics 설정 및 실수신 → 파일별 권리/서버 후보 별도 승인 → 새 릴리스 버전/산출물. 기존 APP58 파일·심사 상태는 보존한다. 실제 기존 IPA SHA256 `88ecaf7e91dd9fe05b79113e5e0119295bb9dbeac2f043a2592a87261a28a01e`, AAB `5ac0a0448a9f65c49d90f69cf4c0b393e9cd655ee2514d77e424fc6d1e5c7987`을 재계산해 인계 기록과 일치 확인했다. 이 문서는 실제 운영 DB 적용 상태를 타 브랜치 문서만으로 재확인했다고 주장하지 않는다.

## 판정·남은 차단 요소

현재 **PARTIAL / RELEASE_READY: NO**. Git 보존·정합성·자동 권한/Viewer 검사와 통합 계획은 완료했다. Android 실제 기기 저장 E2E·실제 네트워크 단절, GA4 Native 실제 수신, 원본 내용 고유성, 파일별 권리/배포 승인은 별도 증거가 필요하다. Android 실기기 미연결과 관리자 후보 충돌도 후속 조건이다. 운영 DB 변경0, 공개 다운로드0, 스토어 제출0.


## TASK18-B 변경 파일

기존30파일은 [TASK18 변경 목록](task18-popular-pdf-20261104.md#변경-파일)을 참조한다. 후속 변경은 다음18파일이다.

- `lib/features/analytics/domain/analytics_events.dart`
- `lib/features/resources/presentation/pdf_download_action.dart`
- `lib/features/resources/presentation/resource_section.dart`
- `test/analytics_event_test.dart`, `test/pdf_download_action_test.dart`
- `tool/check_analytics_contract.py`
- `tool/qa/README.md`, `tool/qa/pdf_download_main.dart`, `tool/qa/pdf_download_fixture.dart`
- `wiki/analytics-v1-implementation-20261030.md`, `wiki/current-status.md`, `wiki/decisions.md`, `wiki/index.md`, `wiki/log.md`
- `wiki/task18-popular-pdf-20261104.md`, `wiki/task18-popular-pdf-inventory-20261104.md`
- `wiki/evidence/task18b-inventory-reconciliation-20261104.json`, 본 문서

Wiki routing/내부링크 검사 PASS(current-status12KB 미만). 최종 Git diff/민감정보 검사 PASS. 기기 식별자/개인 계정/서명 프로필은 Git에 추가하지 않았다.
