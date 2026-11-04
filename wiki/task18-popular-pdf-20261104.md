# TASK18 인기 PDF 다운로드 Pilot

구현 후보·로컬 자동검증 완료. APP58 후속 기준 `92d8110`, 분리 branch `codex/popular-pdf-task18`.
운영 변경·배포·스토어 제출 승인 없음. 기존 APP58 산출물 보존.

## 보존 검토 7
1. 파일 권한 결정/관측 시각과 다운로드 클릭/저장 결과를 구분한다.
2. 기존 resource ID·원본 key·URL·파일 SHA256와 권한 근거를 보존한다.
3. 권한 변경은 append-only revision으로 남기며 최신 상태만 projection한다.
4. 신규 학생 identity/로그인 요구를 만들지 않는다.
5. 다운로드는 행동 관측이며 학습/성적/지원 결과가 아니다.
6. GA4 기존 허용 속성만 사용하고 URL·파일명·학생 데이터는 전송하지 않는다.
7. 인기 순위 기간 미확정, PDF 존재/Registry/권리 검증 수준을 분리한다.

기존 [자료 열람](day-9-c-resource-detail.md), [Analytics v1](analytics-v1-implementation-20261030.md), [장기 보존](longitudinal-learning-admissions-data-strategy.md), [APP58](app58-store-handoff-20261104.md) 계승.

## 조사 및 공개 상태

[게시글 실제 제목·846개 PDF 목록](task18-popular-pdf-inventory-20261104.md) / [JSON 원본 식별자](evidence/task18-popular-pdf-inventory.json).
18개 모두 수능·평가원 모의평가, 첨부 PDF 링크846개가 기존 공개 resource ID에 1:1 연결. 신규 Registry 등록0.
홈/카테고리 제외, Owner 후속 지시 “18개만해”로 최종18개 확정. 인기 집계 기간·지표는 미확인. 임의 대체/최근30일 표시 없음.
실제 PDF 바이너리는 미수집·미검증이며 링크 이름/기존 Registry 대조를 PDF 내용 검증으로 표현하지 않는다.

자료별 다운로드 권리 근거 미확보, 전체846 PENDING. ALLOWED0/OFFICIAL_LINK0.
교육청·평가원 문의 무응답은 허락이 아니다. 평가원 출제 문제와 사설 해설/인용 지문의 권리는 분리 검토해야 한다.
공식 정책 검색으로 이846개 파일의 앱 다운로드 허가를 입증하지 못했다. 임의 공식 링크 지정 없음.
기관/권리자 회신 또는 정확한 파일별 이용조건과 Owner 승인 후에만 revision 추가 가능.
공식 페이지 연결은 원본 PDF 복제/자체서버 재배포와 다르다. 이번 구현은 원본 CDN 직접 취득, 미러링0.

## 구현

기존 Content→Resource Registry·PDF Viewer·Safe Open·recent/saved 흐름을 유지하며 해당18개 자료 화면에 정책별 추가 버튼을 둔다.
ALLOWED는 다운로드, OFFICIAL_LINK는 공식 자료 페이지, VIEW_ONLY/PENDING은 추가 버튼 없음.
Guest/무료이며 로그인·이용권 요구 없음. 정책 서버 오류/미설치 시 숨김, 기존 열람 영향 없음.
기존 AnalyticsService에 click/success/failure/cancel 추가. 기존 허용 속성 platform/screen/source/status만 사용;
게시글·자료 ID/파일명/URL/학생 정보 전송0. APP 전용4개 이벤트를 계약 검사에 명시하여 공유31개 drift 검사를 보존.
클릭과 OS 저장·무결성 확인 후 성공을 구분, 취소를 성공/실패로 세지 않는다. GA4 실제 수신 미검증.

새 resource-download Edge 후보는 resource_id만 받고 private 정책·기존 Registry 공개성·선정 게시글·원본 key를 검증한 뒤
기존 resource-resolver의 canonical lookup/HTML parser/SSRF 방어/쿼터를 재사용한다. 기존 resolver 교체/변경0.
source resolve 뒤 권한을 다시 확인한다. 다운로드마다 새 승인과 최신 URL을 받으며 로컬 권한/URL 저장 없음.
32MiB·30초·리다이렉트 차단·PDF header 검사에 승인 SHA256 검증을 더하고 변경된 원본은 저장하지 않는다.
같은 프로세스 동시 저장은 차단, 취소 시 후속 저장을 막는다. 전송 중 취소는 논리 취소이며 기존 loader timeout까지 전송이 남을 수 있다.
백그라운드 다운로드/프로세스 종료 후 자동 재개는 지원하지 않으며 성공으로 기록하지 않는다. 복귀 후 재시도한다.

iOS: 별도 MethodChannel + UIDocumentPickerViewController(forExporting:asCopy:)로 파일 앱 위치·파일명 선택.
임시 파일은 완료/취소/실패 후 정리, picker 완료 후 실제 저장 파일 바이트를 읽어 원본과 비교한 뒤 성공.
Android: ACTION_CREATE_DOCUMENT/application/pdf, 위치·파일명 선택, 작업 스레드에서 저장/다시 읽기 SHA256 대조.
실패 시 생성 문서 삭제를 시도, 광범위 저장소 권한 추가0. 기존 export 채널(성적/결과 내보내기)은 그대로 유지.
공급자가 저장 후 읽기를 거부하면 검증 실패로 안내하므로 파일이 일부 남을 수 있다; 재시도 전 파일 앱 확인.
파일명은 승인 시 검증된 시험 정보 또는 원본 이름으로 지정, 학년도와 시행연도를 혼동하지 않는다.
한글/안전 문자150자 제한, path injection 차단. Android OS가 충돌명 번호를 붙이며 iOS는 OS 충돌 UI를 사용한다.

Native 근거: [Apple export picker](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init(forexporting:ascopy:)),
[Android SAF·충돌 처리](https://developer.android.com/training/data-storage/shared/documents-files).

## 운영 변경 필요 범위와 Owner 절차

[SQL 후보·검증·복구](../supabase/candidates/popular_pdf_task18/README.md): private pilot_posts18, append-only permissions(초기0),
public resource_download_policy(uuid) 읽기 RPC. 기존 자료/학생/결제 테이블 변경0.
운영 적용 **NOT_APPLIED**. Owner 승인 후 Owner가 precheck→apply→postcheck, 별도 Edge 배포 승인과 파일별 권한 승인 필요.
정책 이력은 UPDATE/DELETE trigger로 보호. 롤백은 이력을 지우지 않고 RPC를 PENDING으로 닫는다.
Owner가18개로 범위를 확정했으므로 추가 후보 선정은 하지 않는다. 일괄 개방하지 않는다.
후속 APP 빌드·검수 필요. APP58/현재 심사 앱/서명·스토어 제출·운영 배포0.

## 검증 경계

- 합성 PDF 서비스9: 저장 완료 지연, 한글명/바이트 보존, 거절/ID불일치, HTML/해시불일치, 취소, 네트워크 실패·재시도, 저장 실패·재시도, 중복 차단.
- 서버8: 비허용4상태, 승인, resolve 도중 철회, 정책 서버 실패, client URL 주입 차단.
- 격리 PostgreSQL17: fixture/precheck/apply/postcheck/test. Guest 조회, 미등록/비대상/비활성/변경원본 차단,
  철회, 근거 없는 허용 거부, 클라이언트 쓰기 거절, 이력 UPDATE 거절. 운영 JWT/스키마 전수 검증의 대체가 아님.
- 기존 자료 검색/열람·Analytics 포함 집중109 PASS. 최종 전체/빌드 결과는 아래에 기록.
- OS 실제 파일 저장·취소·중복명·공간 부족·외부 공급자·백그라운드/강제종료·저장 PDF 열기: 실기기 NOT_RUN.
- iOS Simulator/Android 빌드는 실제 OS picker E2E와 구분한다. 공개 PDF 다운로드0, GA4 DebugView 수신 NOT_VERIFIED.

## Owner 검수와 남은 차단

파일별 권리 근거·원본 PDF SHA256·파일명/과목 대조, SQL/Edge 운영 승인,
iOS/Android 실기기 A–J 저장 체크, GA4 승인된 Firebase 설정/실수신, 후속 릴리스 빌드/제출 결정.
공개 가능 파일0이므로 기능 후보 구현과 운영 공개 가능성을 별도 판정한다. RELEASE_READY=NO.

## 최종 검증과 판정

Owner 후속 “18개만해”: 최종 대상18개, 추가2개 불필요. 집계 기간을 추정하지 않는다.
공개 Registry 시험연도·월·학년·유형도18/18 원문과 일치. 정책 RPC 운영 GET은404/PGRST202(미설치) 확인.
문제420/정답·해설416/듣기대본10=846 첨부, 모든 과목 파서 관측값 존재. 본문/원본 바이너리 검증은 별도.

- Flutter3.47.7 Analyze: 0 issues.
- 전체 Flutter: **1,505 PASS / 기존7 SKIP / 0 FAIL** (다운로드13 추가 포함).
- iOS Simulator debug build: PASS, Android debug APK build: PASS. 실제 OS 저장 E2E는 NOT_RUN.
- 서버8 및 기존 resolver38: PASS. 격리 SQL: PASS, 원본 보호/철회/Guest 계약 테스트 rollback 완료.
- Wiki routing/links 및 current-status 12KB budget: PASS. git diff --check PASS.
- GA4: 이벤트 연결·위젯 관측 PASS, 실제 DebugView 수신 NOT_VERIFIED. 새 Firebase 설정/콘솔 변경0.

IMPLEMENTED: YES (후속 앱 후보). TEST_VERIFIED: LOCAL_AUTOMATED_ONLY.
OWNER_REVIEW_REQUIRED: YES. RELEASE_READY: NO (권리·실기기·운영승인·GA4 게이트).
소스 변경은 전용 작업 트리에 미커밋으로 보존; 기준 Git SHA `92d8110` (APP58 이후 앱 브랜치의 시작점).
새 정식 앱 버전/서명 산출물/스토어 제출은 만들지 않았다. 디버그 검증 산출물은 전용 작업 공간 build 아래에만 존재한다.

## 변경 파일

- Flutter: `lib/features/resources/data/pdf_download.dart`, `presentation/pdf_download_action.dart`, `presentation/resource_section.dart` 및 `lib/features/analytics/domain/analytics_events.dart`.
- Native: `ios/Runner/AppDelegate.swift`, `android/app/src/main/kotlin/com/legendstudy/app/MainActivity.kt`.
- Server: `supabase/functions/resource-download/index.ts`, `index_test.ts`, `supabase/config.toml`.
- SQL: `supabase/candidates/popular_pdf_task18/{README.md,apply.sql,precheck.sql,postcheck.sql,rollback.sql,fixture.sql,test.sql}`. fixture/test는 격리DB 전용.
- 검증 도구: `test/pdf_download_test.dart`, `test/pdf_download_action_test.dart`, `tool/audit_popular_pdf_task18.py`, `tool/check_analytics_contract.py`.
- Wiki: 본 문서, 목록 문서, evidence JSON, current-status/index/decisions/log, 기존 resource-detail/analytics-v1 후속 링크, history 입력 스냅샷.

원래 checkout의 미커밋 변경을 이동하거나 덮어쓰지 않았다. 작업 branch `codex/popular-pdf-task18`, 기준 전체 SHA `92d8110ecd66891debff6528d0287858b7a2dc1e`, 새 커밋/Push 없음.
