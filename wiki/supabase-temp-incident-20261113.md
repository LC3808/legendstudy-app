# 11/13 temp_file_limit P0 조사

상태: **실패 SQL·호출 주체 확인 / 522·비정상 종료의 인프라 원인 미확정**.
[상위 운영 조사](operations-commercial-20261113.md), [원시 집계·계획](assets/supabase-temp-incident-20261113/evidence.json),
[오류 SQL 원문](assets/supabase-temp-incident-20261113/exporter-query.sql).
프로젝트 stlhijzpjfgwwdgunlsd만 읽기 전용 조회. 아래 시간은 KST, 증거 JSON timestamp는 UTC.
운영 데이터·설정·cron·인덱스 변경, 재시작, Compute 변경, 통계 reset 모두 0.

## 확인된 실패와 호출 경로

03:23:28.878–03:50:28.952의 오류 18건은 전부 동일하다.

|항목|값|
|---|---|
|오류|temporary file size exceeds temp_file_limit (15360kB), SQLSTATE 53400|
|query_id|-8285757822602875730|
|backend PID / session|2973075 / 6af60420.2d5d93|
|사용자 / application_name|supabase_admin / postgres_exporter|
|접속 주소|::1:18927 (loopback)|
|SQL|normalized_pg_stat_statements CTE에서 사용자 쿼리를 정규화·필터링하고 sum(calls)를 user_queries_total로 집계|

로그의 query 원문은 8,182자. extensions.pg_stat_statements의 query에
left(query,10000), regexp_replace, lower를 적용하고 시스템 SQL 패턴을 제외한다.
본문 속 cron 관련 문자열은 제외 패턴이며 cron을 실행하는 구문이 아니다.
확인된 직접 경로는 **로컬 postgres_exporter → PostgreSQL 통계 수집 SELECT**다.
학생 앱 요청이나 Edge Function이 이 PID의 직접 호출자라는 증거는 없다.
03:00–16:00 확장 조회에서도 해당 오류는 같은 18건만 관측됐지만 이후 정상 수집을 보장하지 않는다.

## pg_stat_statements 대조와 EXPLAIN

통계 reset은 04:48:50.664, postmaster 시작은 04:48:50.733이다.
사고 이전 쿼리별 비용은 현재 통계로 복원할 수 없다. 대상 query_id/분류 SQL은 현재 통계에 없다.
공개 exporter 서비스 템플릿은 pg_stat_statements.track=none을 사용한다.
이는 부재의 가능한 설명이며 해당 운영 인스턴스의 실행 옵션은 확인되지 않았다.

재시작 이후 별도 관측(장애 원인 순위가 아님):

|query_id / 사용자|호출|총 실행 ms|평균 ms|temp read/write blocks|
|---|---:|---:|---:|---:|
|-5708723254081763768 / postgres|5|60558.75|12111.75|122167 / 122193|
|8270099943726956572 / essay_worker, essay_exam_preflight|4019|118182.45|29.41|33915 / 33915|
|-3076875962393720596 / postgres|9|13360.51|1484.50|576 / 5058|

블록 크기 8192bytes. postgres 쿼리의 호출 경로는 이번 집계로 확정하지 않았다.
당시 후속 관측은 968개 통계 항목, query 텍스트 합 12,063,123bytes,
최대 단일 텍스트 10,113,919bytes였다. 이는 사고 시점 크기가 아니며 본문은 수집·공개하지 않았다.

오류 SQL 그대로 READ ONLY·5초 제한의 EXPLAIN(FORMAT JSON, COSTS), **ANALYZE 없이** 확인했다.
Aggregate → CTE Scan, CTE 내부 Function Scan(pg_stat_statements)과 작은 pg_authid 필터다.
Aggregate 예상 cost 55.65–55.66. 앱 데이터 테이블 JOIN/인덱스 탐색 대상은 없다.
함수 결과 및 CTE materialization과 텍스트 처리가 spill 후보이나, 실제 오류 당시 어느 노드가
몇 bytes를 썼는지는 이 계획으로 증명할 수 없다. left(...,10000)은 함수가 먼저 반환하는
전체 query 텍스트 자체를 줄인다는 보장이 없다. 앱 테이블 인덱스 추가 근거는 없다.

현재 조사 세션 work_mem=3500kB, temp_file_limit=-1이다. 이는 오류 당시 exporter 세션의
15360kB와 다른 실행 컨텍스트다. postgres/supabase_admin의 저장된 role 설정에도 해당 제한이
없어 exporter 접속 옵션·플랫폼 설정을 지원팀에서 확인해야 한다. 메모리/제한 상향은 하지 않았다.

## cron·Edge 상관관계

활성 cron은 매분 실행되는 legendstudy_feedback_notification_worker와
legendstudy_account_deletion_dispatch_worker 두 개다. net.http_post로 해당 worker를 호출한다.
03:23–03:50 각 28회 성공, 최대 DB 실행 시간 각각 0.056743초/0.054471초.
03:00–05:00 cron 이력의 exporter PID 일치는 0건이다. cron 성공은 HTTP 요청 enqueue 성공이며
비즈니스 처리 완료까지 증명하지 않는다.

03:20–03:49의 10분 집계에서 process-feedback-notifications,
account-deletion-worker/dispatch, account-ops-sink/checkpoint의 관측 응답은 모두 200이었다.
각 버킷에 경로당 9–10회, 최대 실행 시간은 각각 5815/4577/2057ms.
별도 delete-account 1회도 200. 이는 오류 구간을 포함하는 집계이며 정확한 분 단위 동시성 증명은 아니다.

두 cron은 03:50까지 실행 이력이 있고 **03:51–04:48 이력 부재**, 04:49 재개다.
Edge 경로들도 같은 공백이 관측된다. 03:00–05:00 각 cron 총 62회(51+11) 성공.
이력 공백의 시작이 마지막 exporter 오류 직후라는 시간적 관계는 있으나 중단 메커니즘은 미확정이다.
작업을 임의 중단하거나 누락된 로그를 정상 처리로 해석하지 않았다.

## 522·DB 연결 중단과의 인과관계

마지막 temp 오류 03:50:28.952 → 첫 관측 Auth 522 04:21:15는 약 30분46초 차이다.
04:44:54–04:46:54 Supavisor timeout, 04:48:49–50 PostgREST 연결 거절,
04:48:50 improper shutdown/WAL recovery/ready, 04:48:52 cron scheduler 시작이 뒤따른다.
**관측 순서는 확인됐지만 temp 오류 → 호스트 장애 → 522라는 인과사슬은 입증되지 않았다.**
temp 예산 초과는 해당 SELECT 실패를 설명한다. 이것만으로 OOM, 디스크 고갈, I/O throttling,
DB 프로세스 종료나 재기동 주체를 단정할 수 없다. Owner가 당시 CPU/RAM/IO 그래프·지원 답변은
없다고 확인했다. 장애 이전 통계도 reset되어 최종 인프라 원인 확정은 보류한다.

## 최소 개선·검증·원복

즉시 반영한 범위는 저장소의 [읽기 전용 진단 SQL](../supabase/verification/operations_20261113/snapshot.sql)
세 숫자 통계 조회뿐이다. view 대신 extensions.pg_stat_statements(false)를 호출하여
출력하지도 않을 query 텍스트 로딩을 피한다. DB 객체/데이터/기능 계약 변경은 없다.
수정 파일 전체를 운영 READ ONLY·5초 제한으로 실행해 오류 없이 완료했다.
숫자 조회 EXPLAIN ANALYZE는 974행, 실행 2.106ms, top-N heapsort 29kB,
temp read/write 0, shared read 0이었다. [검증 계획](assets/supabase-temp-incident-20261113/numeric-explain.json).
원복은 이 파일의 세 호출을 기존 view로 되돌리는 Git 변경이며 운영 롤백 SQL은 필요 없다.

이 변경은 **managed exporter 수정이 아니다**. exporter 분류 SQL은 query 텍스트가 필요하므로
false로 단순 치환하면 집계 의미가 깨진다. 다음 개선은 지원팀 검토 대상으로 제한한다:

1. 숫자 폴링과 텍스트 분류를 분리하고 userid/dbid/queryid별 분류 캐시를 검토한다.
2. 별도 검증 환경에서 기존 user_queries_total과 결과 동등성, 통계 reset/eviction·새 query 대응,
   권한 범위, temp bytes·실행 시간·CPU를 비교한다. 운영에 무거운 실패 SQL을 반복 재현하지 않는다.
3. 영향 범위는 monitoring 지표 수집이다. 합계 누락/과집계·수집 지연이 없을 때 플랫폼 담당자가
   제한적으로 적용하고 오류/지표를 비교한다. 회귀 시 기존 exporter 설정/쿼리로 복귀한다.
4. 운영 SQL/설정 변경이 필요하면 정확한 변경·검증·원복안을 먼저 제공하고 Owner 적용 원칙을 따른다.

temp_file_limit/work_mem 상향, cron 중단, 앱 인덱스 추가는 현재 근거로 제안하지 않는다.

## 지원팀 확인 요청 초안 — 미전송

프로젝트 stlhijzpjfgwwdgunlsd, 2026-11-12 18:23–19:49 UTC의 exporter PID2973075,
query_id -8285757822602875730 및 위 SQL/타임라인을 전달할 수 있다.
요청 사항: 당시 exporter 버전·queries.yml/DSN 옵션·15360kB 제한의 출처,
실제 temp spill/수집 실패 이력, 18:51–19:48 cron 공백, 호스트 OOM/kernel 이벤트,
CPU/RAM/Disk IO Budget·throttling, 19:48:50 재시작 원인·주체와 platform incident 여부.
지원팀 답변 전까지 인프라 원인과 exporter 재발 방지 완료는 미확정이다.

## 외부 근거의 범위

- [PostgreSQL17 pg_stat_statements 공식 문서](https://www.postgresql.org/docs/17/pgstatstatements.html): showtext=false와 쿼리 텍스트 캐시로 조회 I/O를 줄이는 방법.
- [Supabase exporter 서비스 템플릿](https://github.com/supabase/postgres/blob/12931793f8fa7ef7bd0eb0aea01e8a2c931a2c67/ansible/files/postgres_exporter.service.j2): localhost/supabase_admin/application_name 및 track=none. 실제 배포 버전 증거는 아님.
- [Supabase 공개 이슈52457](https://github.com/supabase/supabase/issues/52457): 동일 계열 분류 SQL의 spill 보고. 다른 환경의 보고이며 이번 522의 원인 증거나 메모리 상향 승인으로 사용하지 않는다.

기존 [운영 조사](operations-commercial-20261113.md)의 원인 미확정·Owner SQL 적용 원칙을 유지한다.
이번 조사에서 새로운 제품 정책이나 데이터 수집 정책을 도입하지 않았다.
