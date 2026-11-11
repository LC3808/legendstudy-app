# APP67 학습 홈·학교 순위·친구 초대 — 2026-11-11

Owner 작업02. 기준 `codex/app-update-final-integration-20261105` / `53b2a3a`,
APP67 `1.0.2+67`. 동일 지정 작업 폴더에서 `codex/app67-learning-integration-20261111`
브랜치를 분리했다. 기존 미추적 캐시·APP67 IPA/AAB/Archive·기존 브랜치는 보존했다.
WEB 기준은 운영 `9788a7ca` / 소스 `0eefc7d`이며 WEB을 수정/배포하지 않았다.

## 기존 결정과 일곱 보존 검토

[Study 기존 정책](study-v1.md), [저장 계약](day-8-study-storage-proposal.md),
[학교 저장](day-7-school-storage-proposal.md), [UI](ui-ux-v1.md),
[디자인 시스템](design-system.md), [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)을 따른다.
이번 Owner 지시는 과거 friends/ranking 보류 범위를 학습 통합 구현에 한해 승격한다.

1. 학습 발생·완료 시각은 기존 study_sessions에 유지한다. 초대 방문/가입은 기존 별도 Backend 사실이다.
2. 원본 active_segments와 지원 이벤트를 보존한다. 학교 순위는 현재 프로필 기준이며 과거 학교를 추정하지 않는다.
3. 이번 APP 코드는 기록 수정/삭제를 추가하지 않는다. SQL 후보도 기존 기록을 정리/병합하지 않는다.
4. 동일 Supabase auth 사용자에 연결하며 비동기 응답·초대 토큰을 다른 계정에 넘기지 않는다.
5. 공부는 Learning, 실제 지원은 Decision, 합격 이벤트는 Outcome으로 기존 분리를 유지한다.
6. 다른 학교 인원은 **, 서버에서 허용한 시간만 표시한다. 내부 UUID는 초대 URL에 넣지 않는다.
7. 서버 순위/합계를 재계산하거나 원본으로 저장하지 않는다. ms→시간/분은 표시 변환뿐이다.

## 구현

- 기존 공부/모의고사 탭, 타이머·시작/일시정지/재개/종료·복구·체크포인트·outbox는 변경하지 않았다.
- 학습 홈: my_study_summary의 오늘/이번 주, 기존 최근7일 차트, 기존 기록 최근5개,
  우리 학교 참여 순위·가입 학생 수, 학교 순위/초대 진입. 서버 완료 기록과 진행/미동기화 기록을
  더하지 않는다. 기존 차트의 기기 포함 집계는 기존 정책대로 유지한다.
- 서버 요약은 저장 기록 변경·분 경계·앱 복귀·명시 새로고침에 갱신한다.
- 학교 순위: 학생 전용 card/ranking RPC, 기본 all/participation, all/week/last_week/month,
  participation/total/average. TOP10 순서·공동순위·around 그대로, 중복 학교 ID만 제거한다.
  학교명은 기존 NEIS find 재사용. 미등록/비로그인/오류/미충족을 구분한다.
- 평균은 운영 PostgreSQL numeric의 소수 밀리초를 지원한다. 시간 단위 표시 시에만 내림한다.
- 학교 선택/변경과 계정 변경은 provider를 무효화한다. 자기 학교 인원만 표시하고 다른 학교는
  숫자가 잘못 넘어와도 **로 표시한다. 시간 3명 공개는 서버 계약이며 APP에서 threshold를 계산하지 않는다.
- 초대: 기존 invite_create/lookup/record_visit/attribute_signup/mark_school_confirmed 재사용.
  OS 공유·복사·만료·실패·재시도·보관·로그인 후 귀속·자기초대/기존회원 제외 결과 표시.
  방문 기록 실패가 귀속을 막지 않는다. 공유 창 열림을 가입 전환으로 표시하지 않는다.
- 초대 학교는 자동 UPDATE하지 않는다. 기존 학교 설정 화면을 확인한 뒤 명시 확인 버튼을 제공한다.
  첫 학습/D7은 기존 WEB Backend 집계가 study_sessions에서 계산하며 새 APP 집계 엔진은 없다.

## 링크 수신과 명확한 제한

- `com.legendstudy.app://invite?t=<64hex>` 전용 호스트를 Android에 추가했다.
  iOS는 기존 등록된 scheme을 사용한다. 기존 login-callback/auth-recovery와 SDK 세션 교환은 변경하지 않았다.
- 이미 설치된 앱의 해당 custom scheme 초기/실행 중 수신을 app_links로 처리한다.
  기존 resolve 버전 6.4.1을 직접 의존성으로 명시했으며 버전 업그레이드하지 않았다.
- 생성/공유 URL은 기존 `https://lab.legendstudy.com/invite/?t=...` WEB 랜딩이다.
  앱에서 받은 WEB 링크를 직접 입력해도 동일 검증·귀속 경로를 사용한다.
- HTTPS Universal/App Links의 도메인 파일·서명 연결은 이번에 배포하지 않았다.
  따라서 WEB 링크를 누르면 자동으로 앱이 열리는 운영 E2E를 완료했다고 하지 않는다.
  AASA/assetlinks, Associated Domains와 Play 앱서명 지문을 확인하고 별도 승인 후 연결해야 한다.
- 미설치→설치 후 토큰 자동 복원: NOT IMPLEMENTED. 외부 추적 SDK나 별도 서버를 도입하지 않았다.
- Native 공유/링크 실제 기기 E2E: NOT TESTED. OS별 컴파일과 합성 widget/서비스 검증과 구분한다.

## SQL 후보

[정확한 적용안·검증·원복](../supabase/candidates/app67_learning_20261111/README.md).
누적은 기존 private summary에 additive 필드만 추가하며 신규 RPC/집계 저장소 없음.
지원 중복은 기존 배타 lock 안에서 학년도·대학·학과·모집·전형을 비교한다.
기존 중복/이력/ACL/원장 삭제0. 현재 APP은 누적 필드를 사용하지 않으며 최근30일을 누적으로 표시하지 않는다.
운영 최대 이력의 성능 검증 및 WEB의 23505 안내 후속은 운영 승인 범위에서 다룬다.

## 파일과 검증 경계

- `lib/features/learning/learning_repository.dart`: 엄격한 계약·owner guard·학교/요약 providers.
- `learning_widgets.dart`: 학습 요약/최근 기록/순위 Native UI.
- `invite_controller.dart`: opaque token 보관·계정 경계·귀속 재시도.
- `invite_page.dart`: 생성/공유/입력 UI, 독립 링크 수신 및 앱 복귀 읽기 갱신.
- 기존 StudyPage/router/app root는 위 기능 연결만 변경했다.
- Android Manifest/MainActivity와 iOS AppDelegate는 invite host/공유 채널만 추가했다.
- `test/learning_integration_test.dart`: 격리 계약·오류·계정전환·마스킹·공유·UI.
- `test/auth_oauth_test.dart`: 기존 두 Auth 호스트와 새 invite 호스트를 각각 검사.
- `test/task19_cutoff_capture_test.dart`: 만료된 고정 fixture를 미래의 합성 만료 시각으로 변경.
  운영 베타 기간/이용권 로직은 바꾸지 않았다.
- `tool/test_app67_learning_sql.py`: 임시 Unix socket PostgreSQL만 사용, 운영 연결 옵션 없음.

검증 도구: APP67의 Flutter3.47.6 / Dart3.13.5. 시스템 기본 Flutter는 Dart3.8이므로 사용하지 않는다.
코드/DB runtime 조사는 읽기 전용이었다. 실제 초대 생성/방문/가입 귀속, 학습·지원 생성,
평가·지급·차감·결제·환불0. 운영 SQL/RPC/WEB/스토어 변경0.

## 마감 검증 및 후속 작업

- 신규 학습·초대 격리 테스트 24개 PASS. 프로필 생성 전에는 귀속하지 않고, 프로필 준비 후
  동일 토큰을 귀속하는 경계를 포함한다. 초기 링크 조회 중 도착한 링크도 유실하지 않는다.
- 순위 화면 360px, 글자 배율 1·2, 밝은/어두운 테마 캡처 및 overflow 검사 PASS.
  기존 공용 디자인 변경 없이 신규 학습 카드·섹션 제목의 다크 대비를 보완했다.
- 격리 PostgreSQL17: 42 SQL checks와 추가 assertions PASS. 적용·재실행 차단·원복 확인.
- 최종 전체 회귀·정적 분석·플랫폼 컴파일 결과는 아래 완료 기록을 참조한다.

### 다음 담당자의 순서

1. 이 브랜치와 APP67 기준 비교 후 학습 홈→학교 순위의 전체/이번 주/지난주/최근30일과
   세 지표를 확인한다. 학교 미등록·네트워크 실패·로그아웃에서 오류를 0으로 숨기지 않는지 확인한다.
2. 별도 내부 실기기 검수에서 공유 sheet·링크 복사/입력·custom scheme cold/warm 수신,
   신규 가입 프로필 준비·자기초대/기존회원 거절·학교 확인·계정 전환을 확인한다.
   운영 가입/학습 생성은 이번 작업에서 실행하지 않았다.
3. 누적 표시와 지원 중복은 후보 README의 SQL/검증/원복을 Owner에게 제시해 별도 승인을 받는다.
   운영 최대 이력 성능 확인 후 누적 필드를 APP에 연결한다. 현재 30일을 누적으로 대체하지 않는다.
4. HTTPS 앱 자동 열기와 설치 후 복원은 아직 완료가 아니다. 도메인/서명 검증과 배포 범위를
   결정한 후 처리한다. 현재 WEB 랜딩 경로는 유지한다.
5. APP67 릴리스 파일을 덮어쓰지 말고 별도 승인된 새 빌드 번호로 출시 검증한다.
   이 작업의 산출물은 로컬 디버그 앱이며 정식 서명 IPA/AAB나 스토어 제출이 아니다.


### 완료 기록

- 앱 구현 커밋: `7df37c5`; 격리 SQL 후보/검증 커밋: `3016746`.
- `flutter analyze`: No issues found.
- 최종 `flutter test`: **1,580 PASS / 7 SKIP / 0 FAIL** (기존 제외 7개 유지).
- 신규 테스트 캡처 실행: **24 PASS**, 밝은/어두운 테마와 글자 배율2 확인.
- Wiki handoff 검사: PASS, current-status 2,792 bytes, 내부 링크 3,076개 확인.
- SQL: 임시 PostgreSQL에서 **42 checks + 보존/동시성/원복 assertions PASS**.
- 플랫폼: iOS simulator debug `--no-codesign`, Android APK debug 컴파일.
  릴리스 서명/실기기 검증 결과를 의미하지 않는다. 버전은 `1.0.2+67` 그대로다.
- 최종 판정: **PARTIAL**. 승인된 로컬 구현/격리 검증 완료. 누적 SQL 운영 적용·앱 누적 연결,
  Universal/App Links·설치 후 복원·실기기 E2E는 위 후속 범위로 남겼다.
- 원격 push·운영 DB/RPC·WEB 배포·스토어 제출 없음. 기존 미추적 캐시 두 폴더는 건드리지 않았다.

## 작업02 후속 — 2026-11-11 운영 승인 적용

Owner가 누적 공부시간·지원 중복 SQL 적용을 승인했다. 승인된 두 함수만 적용했으며
작업03의 DB 변경 금지 범위를 침범하지 않았다.
정확한 실행문: [production apply](../supabase/candidates/app67_learning_20261111/production-apply-20261111.sql).
Supabase migration 이름 `app67_learning_summary_application_dedupe`, 응답 success=true.
기준 함수 해시 일치 후 repeatable read 트랜잭션 안에서 적용 전후 검사:
학습·지원·지원 이벤트 전체 내용 해시 동일, 함수 ACL 동일, 기존28명 요약의 누적 외 필드 동일.
기존 데이터 UPDATE/DELETE 없음. 실제 지원/채점/지급/차감/결제/환불 실행 없음.
적용 후 study_summary md5 a1622f936527c48df8c24d35a2163650,
my_application_save md5 65edac758433cde4a123b95be3da42ee.
54개 학습 기록/28명 전체 누적 조회33.365ms, 누적 필드 누락0·음수0.
향후 대량 이력의 성능을 보장하는 수치는 아니다.

APP은 명시적 all_time_source/all_time_ms만 누적 시간·분으로 표시한다.
구 서버/누락 응답은 조회 미연결이며30일 합계나0으로 대체하지 않는다.
학습·초대 집중 회귀29 PASS, analyze 문제0. 기존 전체1580 PASS는 이전 커밋의 증거이며 이번 재실행 수치와 구분한다.
기존 rollback.sql은 새 함수 해시 확인 후 원함수 복원용으로 유지한다.

실기기: devicectl iPhone12/17 Pro Max unavailable, adb 연결0. 설치/실기기 PASS 주장 없음.
초대 후속: iOS Associated Domains와 WEB AASA/Android assetlinks가 아직 연결되지 않았다.
기존 WEB landing은 유지하며 자동 앱 열기/설치 후 복원은 미완료다.
기기 연결 및 도메인·Play 서명 검증을 이어가야 한다. Store 제출0.

## iPhone 내부 검수 빌드68 — 2026-11-11

기기 연결 후 기존 설정 release63-ios.local.json을 device-qa로 검증했다.
빌드1.0.2(68), APP source `2aa5fe1`, 기존 com.legendstudy.app/서명 팀 유지.
iOS release 디바이스 빌드·codesign 검증 PASS. devicectl 삭제 없는 설치 및 실행 성공.
APP67 원본 IPA/AAB 보존. 새 IPA/AAB나 스토어 제출 없음.
[설치 기록](../tool/app68-learning-device-receipt-20261111.json).
Owner에게 로그인 유지·오늘/누적/주 시간·학교 순위·초대 생성/복사/공유창 검수를 요청했다.
설치 성공은 기능 E2E PASS가 아니다. 사용자 회신 대기.

## Owner 빌드68 검수 후 UX 수정

공부시간 설명 문구 삭제. 학습 화면 초대하기 한 번으로 기존 invite_create 후 OS 공유창을 연다.
별도 초대 만들기/복사 단계·수동 받은 초대 확인 화면 제거, 기존 route는 학습으로 보낸다.
안내 문구와 버튼 사이20px. 중복 탭 차단·계정 전환 보호·공유 실패 재시도 유지.
실제 수신 링크의 내부 귀속은 유지하며, 학교 자동 변경 없이 해당 수신자에게만 학교 확인을 표시한다.
공유 본문에 기존 초대URL과 공식 iOS/Android 앱 설치 링크를 함께 포함한다.
HTTPS 자동 앱 열기/설치 후 토큰 복원은 여전히 미완료이며 앱 링크 완전 연결로 주장하지 않는다.
집중48테스트 PASS. 실제 전송/가입/과금 실행 없음.

빌드69 source a008605, 서명 iOS release 컴파일·codesign·삭제 없는 설치·실행 PASS.
[설치 증거](../tool/app69-learning-share-receipt-20261111.json). Owner 재검수 대기.
정적 분석 오류/경고0, 중괄호 스타일 info1은 기능 실패와 구분한다.
공유 자동 앱 열기 및 설치 후 귀속은 이번 UI 수정으로 해결됐다고 주장하지 않는다.

## 빌드69 Owner 검수 후 수정 — 빌드70 준비

저장 완료/기기 저장 완료 라벨을 학습 화면에서 숨긴다. 실패·동기화 대기 경고와 재시도는 유지한다.
최근 학습 기록 중복 섹션 제거, 최근7일 차트의 링크를 학습 추이 자세히 보기 하나로 통합.
기존 기록 저장·타이머·합산 정책은 유지한다.
학교 카드는 학교명/강조한 전체기간 참여순위/참여 인원/총 공부시간과 하단 버튼으로 축소.
서버 pub_ms 미공개는 비공개로 표시하며0으로 변환하지 않는다. 가입 인원 중복 조회 제거.
공유 장애:09:46:02 KST 서버 토큰 생성 확인. 앱은 FlutterSceneDelegate인데 공유창만
AppDelegate.window를 참조했다. 기존 PDF 정상 경로와 같은 foreground UIWindowScene의
keyWindow rootViewController를 사용하도록 수정. 정확한 실제 복구 판정은 새 빌드 Owner 검수 대기.
공유창 재시도는 현재 계정의 미만료 링크를 재사용해 토큰 중복 생성 방지.
집중49테스트 PASS(큰 글자 학교 카드/기존 타이머/공유 재시도 포함).

빌드70(1.0.2), source9c23c49: iOS서명/컴파일/codesign 검증 PASS, 삭제 없는 설치·실행 PASS.
[기기 설치 증거](../tool/app70-learning-qa-receipt-20261111.json). Owner 공유창 재검수 대기.
flutter analyze No issues found. Store 제출0, 운영 DB변경0.

## 학교별 순위 카드 정리 — 빌드71 준비

Owner는 빌드70 검수에 “다 확인했어”로 회신하고 학교 순위 UI 변경을 요청했다.
기존 학습 통합 결정에 이어 총 공부 시간/1인당 평균 공부 시간 띄어쓰기를 통일한다.
시간 지표에서는 가입 인원을 숨기고 참여 학생 수 탭의 가입/참여 및 비공개 정책은 유지한다.
순위·우리 학교·학교명을 한 제목으로 묶고 학교명20px 굵게, 시간26px 굵게 표시한다.
총 시간은 청록, 평균은 보라색이며 어두운 테마 대비를 별도 적용한다.
긴 학교명/접근성 글자 확대에서는 잘림 대신 자연 줄바꿈한다.
서버 순위·기록자3명 기준·학교 프로필·원장·운영 SQL 변경 없음.
검증: 학습 통합28테스트 PASS, analyze No issues found. 360px 밝은/어두운 테마와
글자1배/2배 렌더링 검사 PASS. 기존 순위 테스트의 독립 순위 텍스트 탐색을 합쳐진 제목 탐색으로 갱신했다.
빌드71 서명·기기 설치는 아래 후속 증거로 구분한다. 스토어 제출 없음.

빌드71(1.0.2), source a15711f: iOS release 빌드·codesign 검증 PASS.
iPhone12 Pro Max 삭제 없는 설치·실행 PASS. [설치 증거](../tool/app71-learning-rank-receipt-20261111.json).
학교 순위 실기기 최종 모양은 Owner 재검수 대기. APP67 원본/운영 데이터 보존, 스토어 제출0.
