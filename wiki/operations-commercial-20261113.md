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
