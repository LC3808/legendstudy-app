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

## PHASE 2–6

아직 실행 중이며 완료 판정 없음. 단계별 기존 구현·수정·테스트·운영 적용·
잔여·Owner 결정·Git/Wiki 증거를 아래에 추가한다.

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

기존 학년/학년도/월/기관/과목/자료유형 검색과 시험 상세의 과목별 실자료 묶음,
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
