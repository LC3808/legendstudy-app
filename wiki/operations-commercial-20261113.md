# 운영 안정화·상용화 순차 실행 — 2026-11-13

Owner 지시: 장애 안정화 → 결제 → 기존 PDF 다운로드 → 자료 UX → 공부시간 → 통합검증.
외부 승인/접근 대기는 BLOCKED로 기록하고 다음 단계 진행. 실제 검증 없는 DONE 금지.
가격4,900/11,900/17,900/29,900원,3개월,재첨삭14일과 원장 보존.
실결제/환불·LIVE 전환·스토어 제출·유료Compute 변경은 최종 Owner 승인 대상.
기존 PDF 다운로드 구현을 재사용하며 자료 이용 검토를 반복하지 않는다.
운영 SQL은 [AGENTS](../AGENTS.md)의 Owner 적용 원칙을 따른다.

## 복원·충돌 방지

시작 폴더 codex/material-service-app-20261022(b3336e0)는 오래된 APP 코드와
다른 작업자의 미커밋 변경을 포함했다. 변경0. 최신 main02996be(APP84 로그인
hotfix 포함)에서 독립 codex/operations-commercial-20261113 생성.
대학 브랜드/일정은 WEB 작업으로 보존하며 이 APP 브랜치에서 덮어쓰지 않는다.
[최신 로그인](auth-verification-ux-hotfix-20261113.md),
[기존 PDF 통합](app-update-final-audit-20261105.md),
[학습 통합](app67-learning-integration-20261111.md)을 재사용한다.

## PHASE 1 — PARTIAL / 인프라 원인 확인 BLOCKED

목표: 11/13 새벽 로그인 장애의 실제 증거와 재발 대응 확보.
[P0 후속 조사](supabase-temp-incident-20261113.md): exporter 동일 PID/SQL18건·cron/Edge 공백·EXPLAIN 확인. 진단 SQL은 showtext=false로 개선, 522 인과관계 미확정.
읽기 전용 Supabase MCP로 프로젝트 ref/region/Postgres를 확인:
LegendStudy / ap-northeast-2 / PostgreSQL17.6.1.166 / ACTIVE_HEALTHY.
운영 변경·재시작·통계 reset·RLS 변경0. 아래 시간은 KST이다.

|시각|확인 사실|
|---|---|
|03:23:28–03:50:28|postgres_exporter, supabase_admin의 pg_stat_statements 정규화 SELECT에서 temp_file_limit15360kB 초과18회|
|04:21:15–04:34:35|/auth/v1/token HTTP522 19건, origin_time 최대20073(로그 원시값)|
|04:22:44–04:33:52|/auth/v1/authorize HTTP522 3건|
|04:36:35–04:42:24|관리 API network-bans 조회 HTTP522 3건|
|04:44:54–04:46:54|Supavisor DB timeout / ECHECKOUTFAILED 반복|
|04:48:49–50|PostgREST localhost5432 연결 거절/PGRST000|
|04:48:50|Postgres improper shutdown·WAL recovery 후 ready to accept connections|
|04:52:10|Auth 로그 status200 재관측(모든 로그인/기기 성공 증명 아님)|
|13:50:19|DB SELECT 성공, 시작04:48:50, 크기682,093,715bytes, max_connections60; active1/idle22/background7|

로그조회 범위02:00–10:00. edge_logs7343/postgres1883/function_edge1597/
function1504/auth123/auth_audit97/pgbouncer52/postgrest42/supavisor34.
API52225건은 모두04시 구간. 시간별 API요청665→520→197→694로 관측되어
이 범위의 집계만으로 요청 폭증 증거 없음. 장애 중 누락로그를 성공으로 해석하지 않는다.
09시 Function Edge5xx2건은 별도 추적 대상. Health advisor 현재0건.

**원인 미확정**: DB 접근 불가/비정상 종료는 확인되지만 exporter 오류,
Disk IO warning, OOM/CPU/메모리/호스트 장애 사이 인과관계는 확인되지 않았다.
플랫폼 exporter 설정을 임의로 바꾸거나 temp_file_limit 상향으로 덮지 않는다.
CPU/RAM/Disk IO Budget/연결 시계열은 현재 MCP에 없어 미확인.
Owner에게 기존 지표/지원 답변을 요청했다. Supabase 지원 시 위 시각과 exporter
query_id -8285757822602875730을 전달하여 호스트/OOM/IO throttle 확인 필요.
지원 요청을 대신 전송하지 않았다.

### 재시작 이후 쿼리와 조치

pg_stat_statements.stats_reset=04:48:50.664. 장애 전 부하의 증거로 사용 불가.
13:50 관측 DB temp321파일/3,393,506,553bytes, deadlock0(관측 구간 주의).
누적1위 essay_exam_preflight3391회/91.1초/평균26.9ms/읽기47691블록/
임시쓰기26775블록. admin_learning_analytics131회/13.7초/104.8ms,
admin_dashboard_study136회/9.7초/71.2ms. 대규모 원본행 hash 검사7회가
일부3초 평균과 다수 디스크읽기를 차지. Dashboard migration열람2회는
평균6초/임시쓰기41226블록. 현재 통계만으로 인덱스 추가 필요 확정 불가.

[재발 진단 SQL](../supabase/verification/operations_20261113/snapshot.sql)을 추가:
READ ONLY,5초 제한, 원본답안/회원/쿼리본문 없이 ID·집계만 출력.
재시작 전 스냅샷을 보존하고 같은 reset시각의 두 관측 차이로 부하를 판단한다.
불필요한 전체 학생/원본행 hash 감사를 반복하지 않고 변경 대상과 계약을 검증한다.
통계 reset/무조건 재시작/대량 EXPLAIN ANALYZE는 대응 기본값이 아니다.

모니터링: Health/로그/DB 통계 조회는 가능. 외부 지속 감시·알림 수신 채널,
CPU/RAM/IO 시계열 수집 및 알림 전달은 아직 검증되지 않았다.
보안 advisor의 private RLS/no-policy56개는 자동 공개 사유가 아니다.
성능 advisor 미인덱스FK108개도 즉시108개 인덱스 생성 사유가 아니다.
[공식 인덱스 advisory](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys).
Compute 증설 필요성과 비용 비교는 실제 병목 확인 전 미완료, 유료 변경0.

## 후속 단계

단계별 실제 구현·검증과 외부 대기를 아래에 구분한다. 모든 단계의 운영 완료를 의미하지 않는다.

## 보존: 작업 시작 시 APP82 이력

[APP82 릴리스 승인·main Push·빌드 완료](app82-store-handoff-20261113.md): 최신main 보존 fast-forward/원격 Push 완료. 1.0.3(82) 배포 IPA·서명 AAB 생성·버전/서명/운영 연결 설정 확인. 통합 후2557 PASS/8 SKIP/0 FAIL·Analyze·Python29·Android JVM2 PASS. 기존 [RC 실기기 근거](app-release-rc-20261113.md) 유지. 추가 소셜 로그인/논술 실사용 검증 WAIVED, marker 없는46개 회원 재노출 ACCEPTED(보호/backfill 없음). 운영 DB/RPC/Auth·회원 데이터·평가 엔진 변경0. 스토어 업로드/제출0, 새 배포 바이너리 설치·Play 업데이트 NOT TESTED. Owner 제출 전 인계.

## PHASE 2 — PARTIAL / 실제 상점 검증 BLOCKED

현재 DB configuration LIVE, Toss TEST20(완료10/준비10), TEST지급0,
LIVE1 FAILED/지급0. 기존11/4 실패 이후 성공 LIVE 근거 없음.
최신 WEB 결제 기록은 원래 작업 브랜치의
[payment-live-activation](https://github.com/LC3808/legendstudy-app/blob/codex/material-service-app-20261022/wiki/payment-live-activation-20261104.md)에 있으며 APP main에 없는 문서를 과거 TEST-only 상태로 오인하지 않았다.
11/4 INVALID_UNREGISTERED_SUBMALL 후 PAUSED 기록. 이번 공개 runtime GET은
환경에서403으로 현재 WEB 설정 미확인. 마지막 Finance 만료기록11/11은
갱신 여부 확인 필요이며 새키/권한/Secret 변경0.

기존 Apple4상품 ID와 가격은 요청과 동일. Google도 같은 catalog 사용하지만
현재 Console 등록·상품상태를 코드만으로 확정하지 않는다.
운영 verify-iap-purchase v23 ACTIVE. iap-refund-notifications는 실제 함수
목록에 없음: 저장소 구현 존재와 운영 환불 수신을 구분한다.
기존 공통 credit_summary 및 서버 영수증 검증/지급을 재사용한다.

검증: Flutter 구매/생명주기/계정격리/잔액/내역6파일35 PASS.
Deno 영수증검증19 + 환불수신10 =29 PASS. 합성 검증이며 실제 상품조회·
구매·복원·환불·WEB↔APP 실계정 잔액 E2E의 대체 근거가 아니다.
운영 주문·지급·환불·Store 제출0; 가격·유효기간·상품ID 변경0.
Owner 잔여: 카드사 등록 완료 확인, 대상/금액을 지정한 실결제·환불 승인,
기존 Console 및 토큰 갱신 상태 확인. 외부 확인 대기 중 PHASE3 진행.

## PHASE 3

PARTIAL: 기존 다운로드 코드8f83f3f/통합9fb4ea3, 검증6df9a68/파일명53b2a3a
재사용. 운영 resource-download v1 ACTIVE/권한0/18게시글 확인.
정상 PDF명을 거절하는 DB 이중 backslash 정규식 결함 확인(읽기 SELECT false),
[수정·846개 활성화 SQL](../supabase/candidates/pdf_activation_20261113/apply.sql) 준비.
Owner가 자료이용을 별도 처리한다는 이번 결정을 그대로 기록하며 허위 권리자
명칭을 채우지 않는다. 기존 private 원장의 정확한 Owner 결정에만 대체 경로를
허용하고 기존 권한·RLS·RPC·원본·사용자 기록은 보존한다.
[원복](../supabase/candidates/pdf_activation_20261113/rollback.sql)은 VIEW_ONLY
revision 추가이며 이전 허용 근거를 삭제하지 않는다.
[사후조회](../supabase/candidates/pdf_activation_20261113/postcheck.sql).

기존 PdfDownloadAction을 PDF Viewer 하단에 연결, 원본 resource ID 전달.
서버 ALLOWED일 때만 표시하고 매 다운로드 서버재승인·SHA256·PDF검사 유지.
기존 iOS UIDocumentPicker/Android ACTION_CREATE_DOCUMENT·파일명 유지·
중복진입 방지/취소·저장완료 후 안내를 재사용. 저장 실패 안내에 네트워크/
기기 공간 확인 추가. MY 저장 및 열람/캐시는 변경하지 않았다.

격리 PostgreSQL17: 정확846 활성화/Guest조회/재실행거절/846원복/
원본846 revision보존 PASS. 기존 Flutter 다운로드/열람/Resolver67 PASS.
운영 적용0. 양OS 실파일 저장·저장공간부족 실기기·오프라인 캐시 NOT TESTED.
기존 파일명 후보는 원본 메타데이터 기반이며 학년도/시행기관 미상값을 추정하지 않음.
다음: Owner가 apply.sql 적용→postcheck ALLOWED846 확인→양OS 저장·재열람.
기존 설치앱도 서버 활성화 후 상세페이지 다운로드 가능; Viewer 연결은 다음
승인 스토어 업데이트 대상. 로그인APP84·브랜드·일정 작업 보존.

### 보존 검토7 — PDF/MY/Study 공통

1. 다운로드 완료 시점과 학습 세션 실제 시각 분리; 기존 시각 수정0.
2. 기존 resource ID/source key/검증 SHA와 세션 interval 원본으로 재현.
3. 권한은 append-only revision; 과거 자료·학생기록 UPDATE/삭제0.
4. 기존 auth.users identity 유지, 사용자 전환 시 로컬 상태 분리.
5. 공부시간은 Learning, 목표는 계획이며 다운로드는 서비스 이용 사실.
6. 기존 본인조회/RLS와 보존 정책 유지, 새 외부 공유/개인정보 수집 없음.
7. 기간/과목 합계는 원본 interval에서 계산; 과거 미분류는 미분류로 유지.

## PHASE 4 — PARTIAL / APP 구현·회귀 완료

기존 학년/시행연도/월/시험유형/과목 검색과 문제·정답·해설 토큰, 시험 상세의 과목별 실자료 묶음,
bookmarks/recent_views를 재사용. 서버 검색/Registry/WEB 계약 변경0.
MY에 다운로드한 자료 추가: 실제 네이티브 저장 성공 후 resource ID/slug/파일명/
완료시각만 계정별 기기 로컬 최근100개 보관. 중복 파일은 최근 위치로 이동.
다운로드는 실제 파일, MY 저장은 기존 bookmark로 명확히 구분.
목록에서 자료로 복귀, 목록 삭제는 OS 파일을 삭제하지 않으며 계정탈퇴 시
로컬 목록 정리. WEB 또는 다른 기기로 동기화되는 목록이라고 표시하지 않는다.

PHASE3/4 Flutter 다운로드·MY·검색·탈퇴11파일 **109 PASS/1 SKIP**.
SKIP은 기존 자격증명 기반 public 검색 통합검증이며 실제 WEB E2E가 아니다.
운영 자료/회원 기록 변경0. 실기기 다운로드 및 WEB 실제 이용 흐름은 NOT TESTED.
Owner: PHASE3 SQL 적용과 다음 바이너리 범위 승인 필요.

### PHASE3 운영 사전검증 중단 후 수정

Owner가 첫 apply.sql 실행 시 `Registry mismatch` 보고, 사후 policy_allowed=0.
운영 전체846 후보를 읽기 전용 재대조하여 **1개만 비활성** 확인:
78960745-ee6a-5045-842f-08738ac1fe44 (1618 게시글 생활과윤리 문제).
다른845개는 ID/key/source/pilot/활성 계약 일치. 이전846개 이력은 보존하되
현재 apply/postcheck는 이1개를 제외한 **845개** 기준. 원본 재활성화/삭제0.
`test_isolated.py`는 운영 비활성 상태를 반영한 PostgreSQL17에서845개 허용,
비활성자료 제외,Guest 조회,재실행 거절,append-only 원복/기존845 revision보존 PASS.
첫 패키지가 오래된 활성 상태를 현재 상태로 대조하지 못한 점을 수정했다.
Owner 수정본 적용 결과 대기이며 운영 활성화 완료 아님.

### Owner 후속 회신

장애 시점 CPU/RAM/IO 그래프·지원 답변은 없음. 원인 미확정 유지.
학교 순위는 **현행 총·평균3명/참여1명 유지** 재확정. 공개5명 변경하지 않는다.

### PHASE4 추가 검색 보완

`2027학년도`는 기존에는 제목 문자열 검색이었다. 실제 academic_year 필드로
구조화 검색하도록 보완하고 `2026년` 시행연도와 분리했다. UI 힌트에 노출.
기존 filter chip/페이지 크기5/활성 자료 기준 유지. 관련54 PASS.
기관별 독립 facet은 현재 없음: 기존 시험유형 및 제목 검색까지만 지원하며
기관·학년도 데이터 완전성이나 WEB UI 동시 적용으로 과장하지 않는다.

## PHASE 5 — PARTIAL / APP 구현·회귀 완료

기존 monotonic clock/원자적 로컬 저장/완료 INSERT/outbox/계정 epoch/
KST interval union 유지. 시작 전 과목 선택 추가, 시작한 세션의 과목 고정,
checkpoint·pause·복원·종료에 보존. 기존 NULL 과목은 미분류이며 backfill0.
운영 study_sessions subject nullable/40자, study mode planned NULL 제약 확인:
기존 필드로 전송 가능, 신규 schema/RPC 불필요. 실제 사용자 INSERT0.

기존 추이 페이지에 오늘/이번주/이번달, 월요일~오늘 하루 평균, 완료된 지난주와
현재 누적 차이, 선택 현재 기간의 과목별 합계 추가. 서로 다른 과목의 동시
interval은 ‘과목 겹침’으로 한번만 계산하여 전체 합과 일치. 추정 분배0.
일일0~1440분/주간0~10080분 목표는 기존 원자적 owner namespace에 append
revision 저장. 0은 해제, 현재 목표를 이번 기간에 적용한다는 UI 명시.
목표는 기기 로컬 계획이며 WEB/cloud 동기화·실제 공부 기록으로 표시하지 않는다.
기존 계정탈퇴 owner purge가 목표 이력도 정리. 저장 실패 시 이전 목표 유지.

Flutter 핵심/복원/네트워크/계정격리/포커스/추이/학교/UI + 신규 과목/목표
8파일 **84 PASS**. 새 검증은 KST 자정·교차기기 과목 겹침·복원·목표 실패/
계정전환/폼 범위 포함. 초기 큰글자 UI 회귀는 과목 선택을 한 줄 dropdown으로
축소하여 기존360x640/2배 텍스트 타이머 테스트 재통과.
운영 학교함수 정의 재조회: 카드3,총·평균3/참여1,본인학교만 인원 노출,
range_agg 중복제거 유지. Owner가 현행3/1을 재확정하여 변경0.
학교 month는 기존 최근30일, 개인 ‘이번달’은 KST 달력월: 동일 기간으로
오인하지 않는다. 기존 네이티브 초대/공유 재사용. 실계정 학교집계 E2E는 미실행.
실기기 재시작/백그라운드·신규 과목 WEB 실계정 조회는 NOT TESTED.

## PHASE 6 — PARTIAL / 통합 회귀·컴파일 PASS

목표: 로그인APP84·온보딩·자료·MY·Study·학교·LAB·원장 보존 및 출시 분리.
원격 main 재fetch: 시작 기준02996be와 동일. 기존 작업 폴더의 미커밋 변경0,
main 병합/Push0; 독립 브랜치만 Push. 웹 브랜드·대학일정 변경0.

- 전체 Flutter **2609 PASS / 8 SKIP / 0 FAIL**, Analyze PASS.
- Deno 결제/환불29 PASS(앞선 PHASE2), Python 공개 Resolver/출시설정5 PASS.
- 격리 PostgreSQL17 수정845개 활성화·Guest·비활성제외·재실행거절·원복 PASS.
- iOS simulator debug `--no-codesign` 빌드 PASS; Android debug APK 빌드 PASS.
  두 산출물은 production dart-define 없는 컴파일 확인용. 실기기/Store 배포 금지.
  release IPA/AAB·새 빌드번호·운영 설정·서명 검증은 이번 범위에서 미실행.
- 기존 AGP/Kotlin/SDK XML 및 flutter_tts SPM 전환 경고 관측; 현재 빌드는 통과.
  별도 의존성 업그레이드를 이 변경에 섞지 않았다.
- 최초 Python 묶음 명령은 격리DB 전용 helper/모듈경로를 잘못 선택해 import
  오류가 났다. 순수 계약5개를 올바른 PYTHONPATH로 재실행해 PASS. 계정삭제
  전체DB harness를 실행했다고 주장하지 않는다(Flutter 탈퇴 회귀는 통과).
- 재발 진단 snapshot.sql 전체를 운영 READ ONLY/ROLLBACK으로 실행 PASS.

[검증 영수증](assets/operations-commercial-20261113/validation.json).
시험 대상 소스 c0aed17; 이후 인계 문서만 추가. 스토어 제출/유료Compute/
LIVE 결제·환불/운영 사용자 기록 쓰기0. PDF는 첫 Owner 실행 rollback 및
권한0을 재확인했고, 수정845개 Owner 적용 결과 대기.

### 단계별 9항목 인계

|단계·상태|목표/기존 구현|실제 변경|검증|운영 적용|잔여/Owner 항목|Git(기능 검증 기준)|Wiki|
|---|---|---|---|---|---|---|---|
|1 PARTIAL|522·DB 장애/기존 로그·통계|제한시간 READ ONLY 진단SQL|로그·Health·SQL PASS|변경0,복구 확인|원인·IO/CPU/RAM 미확정; 지표 없음. 지원확인 필요|6e9ce31|본 문서 PHASE1|
|2 PARTIAL|기존 Toss/IAP/Play/원장 재사용|검증·LIVE/환불배포 차이 기록|Flutter35/Deno29 PASS|결제·지급·환불0|가맹점·상점·Finance 상태 확인 및 실결제/환불·LIVE 승인|91cc9d8|본 문서 PHASE2|
|3 PARTIAL|기존 네이티브 PDF 다운로드|Viewer 연결·정규식수정·845활성화 후보|Flutter 다운로드·격리PG PASS|Owner 적용845·운영전수대조 PASS|양OS 실파일 검수,바이너리 승인|4e433f4 / 6fc39b8|본 문서 PHASE3·SQL README|
|4 PARTIAL|기존 검색·시험묶음·최근·저장|학년도 검색·MY 다운로드 완료목록|자료/MY109(+기존SKIP1),검색54 PASS|APP미배포|기관 facet 없음; WEB/실기기 이용흐름 미검증|4e433f4 / c0aed17|본 문서 PHASE4|
|5 PARTIAL|기존 timer/outbox/union/학교|과목·일주목표·기간/과목합계|학습84 PASS·운영제약/함수읽기|DB쓰기0,APP미배포|실기기 복원·WEB 조회·학교 실계정 E2E 미검증. 학교3/1 유지 확정|c0aed17|본 문서 PHASE5·study-v1|
|6 PARTIAL|APP84 보존·기능별 출시 분리|전체 회귀·양OS컴파일·인계|2609 PASS/8 SKIP,Analyze/빌드 PASS|Store/main/LIVE변경0|양OS 실사용→출시범위·main통합·서명빌드·Store 최종승인|c0aed17(시험 소스)|본 문서 PHASE6·검증영수증|

다음 순서: 수정PDF SQL 확인 → 양OS 실제 저장/파일명/재열람 → 과목 타이머
백그라운드·재실행/목표/MY 검수 → 기능별 출시범위 확정. 결제는 별도 외부
상점/가맹점 gate를 통과한 뒤 실결제·환불 승인과 LIVE전환을 진행한다.

### PDF 후속 재실패 신고 — PDF845-R2 진단 보완

Owner가 수정본에도 같은 Registry mismatch/policy0을 보고했다. 현재 파일의
845개 전체를 운영에서 읽기 전용 대조: input845/valid845/mismatches[]/권한0.
apply.sql의 정확한 JOIN/EXISTS 조건을 별도로 실행해 matched845,executor postgres
확인. 현재 오류는 재현되지 않음. 이전 본문/중간버전/다른 실행 역할/시점차 중
어느 것인지 확인할 증거가 없어 사용자 실수나 새 Registry 오류로 단정하지 않는다.

같은845개·동일 활성/출처 조건을 유지하고 첫 줄 **PDF845-R2**, 실패 시
expected/input/matched/role/database, 성공 시 package/activation_rows/policy_allowed
영수증 추가. 격리PG에서 일부러 후보1개 비활성→matched844 오류·권한0,
복원→845허용/Guest/재실행차단/append-only원복 PASS. 운영쓰기0.
Owner는 SQL Editor 기존본문 대신 최신 apply.sql 전체를 붙여 첫 줄 PDF845-R2
확인 후 실행. 결과/새 오류 대기. [정확한 절차](../supabase/candidates/pdf_activation_20261113/README.md).

### Owner Success 회신 후 운영 사후조회

Owner `Success. No rows returned` 회신 후 2026-11-13 14:34:48 KST 운영
읽기전용 확인: permissions0/ALLOWED0/policy_allowed0. 제외자료는
is_active=false/PENDING/권한0 유지. 활성화 완료 아님. PDF845-R2 전체 실행은
마지막 SELECT에 package/activation_rows/policy_allowed 행을 반환하므로,
실행 프로젝트와 전체본문/선택영역 여부를 Owner에게 확인 요청. 원인은 미확정.

### SQL Editor 실제 화면으로 원인 확인

Owner가 전체 실행했다고 회신하여 열린 브라우저를 읽기전용 확인했다. 프로젝트는
stlhijzpjfgwwdgunlsd/main PRODUCTION으로 정확했으나, 선택된 실행 탭 본문은
`-- Excludes currently inactive ...; never reactivate it.` 주석1줄과 빈2행뿐이었다.
동일 화면의 결과가 Success/0rows임을 확인. 이번 Success는 활성화 SQL 실행
근거가 아닌 주석만 실행한 결과로 설명된다. UI 편집/Run/운영쓰기0. 파일 링크가
변경부분을 보여준 전달경로 혼동 가능성(추정)을 줄이기 위해 Git 밖 전체 텍스트
파일을 생성·원본 바이트 일치 확인 후 전달. 앞선 Registry mismatch 원인과는
구분하며 이번 Success의 화면만 확인한 것이다.

### PDF 운영 활성화 확인 — 2026-11-13 15:36 KST

Owner가 `42P01 pdf_activation_input does not exist`를 보고했으나 운영 사후조회에서
permissions845/policy_allowed845가 확인됐다. 이 오류가 어느 실행·범위에서
발생했는지는 미확정이며 현재 적용 상태와 구분한다. 추가 적용/원복 금지.

현재 R2 파일의845개 전체를 직접 대조하여 **expected845 / exact_permission_matches845 /
active_policy_matches845** PASS. resource ID/source key/파일명/SHA256/정확한 Owner
결정/state 모두 일치. 제외한78960745-ee6a-5045-842f-08738ac1fe44는 비활성,
PENDING/권한0 유지. anon 역할로1700/1435 대표2게시글92개 정책조회 PASS.
운영 변경은 Owner 실행, Codex는 읽기전용 검증. 초기 검토한 단일DO R3 실험은
운영 반영이 확인되어 폐기했으며 기존 R2·원복 패키지를 유지한다.

**서버 권한 활성화 DONE, PHASE3 전체 PARTIAL**: 양OS 실제 PDF 저장·재열람은
아직 NOT TESTED. 기존 앱 상세페이지는 활성 정책을 받을 수 있고 Viewer 하단/
MY 완료목록은 미배포 새 앱 변경이다. 다음 단계는 대표 PDF 실제 파일 저장 검수.
