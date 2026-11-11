# 논술 LAB 기존 시험·문항 연결 — 2026-11-11

최신 [Owner 연결 상태 검증·12문항 전체표·집계](essay-connection-owner-verification-20261111.md): 운영 항공 연결0, 실제 Source 시험진입 probe1 FAIL. 기존 후보 PASS와 구분한다.

**전체 PARTIAL. 한국항공대6시험12문항 로컬 기술 연결 검증 DONE, 운영 연결·공개 NOT APPLIED.**
중앙20시험69수학은 기존 운영 연결을 보존하고 과학Q4 11문항 HOLD를 유지했다.
신규10개교는 기존 공통 Registry 연결28시험94문항을 검증했으며 새 첨삭 package·공개 완료는 아니다.

## 최신 Owner 범위

이번 작업은 기존 DB/Registry를 기존 WEB·APP 공통 Backend와 첨삭 서비스에 연결하는 작업이다.
정상·오답·부분답안 생성, 반복 Provider 호출, 품질 점수 판정은 중단했다.
기존 엔진·프롬프트·Provider/Credit 정책·결과 UX는 변경하지 않는다.
공식 원문·기준·배점·해설은 보존하고 의심 사항만 Owner 검수 대상으로 기록한다.
실제 품질 판단은 Owner/사용자 담당이며 기술 연결 완료 조건에 넣지 않는다.
신규 운영 DB/RPC 변경·WEB 배포·릴리스 병합·스토어 제출·사용자 공개는 별도 승인이다.

기존 정책: [공식 원본 보존](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30),
[TASK20 자연 연결](task20-priority-natural-connection-20261106.md),
[신규10개교 경계](app58-expanded-production-connection-20261104.md),
[최신 결정](decisions.md#2026-11-11--논술-lab은-기존-시험문항-연결-품질-평가는-owner).
착수 시 인수·Source93/현재90 매칭·390시험 감사·공식 출처 조사·이전 검사 상세는
[범위 정정 전 기록](history/essay-natural-expansion-before-scope-20261111.md)에 보존했다.
그 기록의 ‘수식 정규화/Provider 품질 미완료’는 최신 완료 기준을 의미하지 않는다.

## 브랜치·실제 상태

- APP 전용 `codex/essay-natural-expansion-20261111`, 이번 시작 커밋 `bcbee7267d94e351a4f4cbd89dd914feeb8ae47e`.
  APP75/task04 기반 `4489603ccb3359aa95857737cc06dc016e1150f1` 보존. 원래 task04 브랜치 병합/이동0.
- WEB 참조 `codex/task20-chungang-connection-20261107`, `745fbf3`. 추적 제품 코드 변경0.
  `.local`에 Mock 테스트만 만들었고 배포하지 않았다.
- 실제 운영 확인은 LegendStudy `stlhijzpjfgwwdgunlsd` **메타데이터 SELECT만**.
  TEST sandbox 원격 쓰기도0. 이번 후속 검사는 로컬 Unix socket 임시 PostgreSQL17이다.
- APP `lib/`, 플랫폼 설정, WEB 엔진/UX, 사용자 답안·첨삭 기록·원장·운영 RPC 변경0.
  기존 APP75/QA 설치본 삭제·업데이트0. 빌드·실기기 E2E는 이번에 실행하지 않았다.

## Provider 중단 기록

직전 지시에서 시작했던 실험을 범위 정정 직후 종료했다. 중단 시 요청25건 중 응답22건 완료,
실패/진행 중3건은 최종 과금·완료 여부 미확정이다. **중단 이후 추가 호출0**.
22건을 품질 PASS 또는 공식 검증으로 취급하지 않는다.
비공개 `.local/kau-quality-20261111-v2/STOPPED_OWNER_SCOPE.md`·`stop-receipt.json`에 영수증을 보존했다.
실험용 전사/배점·답안·Provider 스크립트는 같은 폴더의 archival 자료로 격리했다.
이번 후보는 해당 실험을 사용하지 않고 **이전 원문 보존 v1 package**에서 연결 정보만 고쳤다.

## 중앙대 및 기존 자연계열

현재 중앙20자연시험80등록문항: 수학69 ACTIVE, 과학Q4 11 미연결/HOLD.
[실제 운영 확인](../supabase/candidates/natural_expansion_20261111/central-live-verification.json).
이미 완료된69를 생성/수정하지 않았다. 기존20 PDF·원문 지면·기준·입력/결과 경로를 재사용한다.
2025/26수시16문항의 기존 `INTENT_SOURCE_NOT_PROVIDED` 승인 예외도 그대로다.
11문항은 새 후보·공개 scope·첨삭 대상 어디에도 추가하지 않았다.

|대학|등록 시험/문항|기존 직접 Math 연결|이번 신규 로컬 연결|남은 범위|
|---|---:|---:|---:|---|
|중앙|20/80|69|0|과학11 HOLD|
|한양|21/42|42|0|완료 보존|
|고려|5/20|20|0|완료 보존|
|인하|25/75|72|0|2021오후3 미연결; 의예27은 release catalog 밖, 자동 공개 금지|
|숙명|18/50|6|0|44 공식 근거·package 연결 후속|
|건국|7/28|3|0|기존 별칭Q1 포함4 보존, 나머지24 후속|
|경희|5/26|3|0|23 후속, 빈 placeholder4 별도|
|한국항공|10/20|0|12|2024–26 6시험 이번 검증, 2022–23 8문항 후속|
|숭실|5/20|0|0|공식 문항별 근거 연결 후속|
|동국|7/21|0|0|2026모의/후보파일2025 정합성 확인|
|성균관|5/15|0|0|연도·언어형 alias 및 근거 확인|
|서울여자|4/9|0|0|과학/서술 기준별 기존 엔진 구분|
|서강|9/11|0|0|문항·소문항 구조와 근거 연결|
|광운|21/42|0|0|복구ID 보존,2022모의 근거 확인|

직접FK 수는 공개 수/모든 기존 Essay 경로의 수가 아니다.
[시험별 ID와 누락 목록](../supabase/candidates/natural_expansion_20261111/natural-gap-inventory.json),
[실제 release catalog](../supabase/candidates/natural_expansion_20261111/release-catalog-metadata.json).

## 한국항공대6시험12문항 연결

[문항별 검수 목록](../supabase/candidates/natural_expansion_20261111/connection/kau-readiness.json)에는
대학·시험·문항·leaf ID, 순서, 기준/PDF/입력/요청/결과/재작성/공개 상태를 분리했다.

|시험|기존 문항 수|문제PDF쪽|로컬 기술 연결|공식 자료 검수 사항|
|---|---:|---:|---|---|
|2024 공학|2|4|2 PASS|Q1 중간 부호, Q2 마지막 소문항 거리/정의역|
|2024 이학|2|5|2 PASS|Q1 기준표·예시풀이 세부 배점|
|2025 공학|2|4|2 PASS|추가 발견 사항 없음; 품질 인증 아님|
|2025 이학|2|4|2 PASS|추가 발견 사항 없음; 품질 인증 아님|
|2026 공학|2|4|2 PASS|추가 발견 사항 없음; 품질 인증 아님|
|2026 이학|2|4|2 PASS|Q1 답 부호·배점, Q2 이차식 부호|

기존 v1의 `file / physical pages … / 문제` locator는 실제 Worker의 `file PDF 1,2쪽` 매칭 조건에
맞지 않았다. **locator 형식과 새 내부 version ID만 수정**했다. 기존 대학/시험/문항ID는 동일하다.
새 후보 `kau-connection-20261111-v1`: 기존8개 Math 테이블172행/DRAFT12,
공식 근거4role/문항, Worker 입력12, 문제전용PDF6개25쪽을 재사용했다.
원문·공식해설·기준·이미지·PDF hash 동일성을 검사했다. 임의 전사/배점 보정0.
공식 기준은 기존 중앙대와 같은 지면 참조 계약이며 `official_points=null`을 유지한다.
추출 PUA를 자동 품질 탈락으로 처리하지 않고, 공식 PNG+SHA+physical page가 정확히 연결되는지 검사한다.

기존 Worker 함수 `math_private.hanyang_worker_references(jsonb)`의 운영 정의 MD5
`54acd2a1914f360e6ecd62e39acc8222`를 읽기 확인하고 그대로 로컬 검사에 사용했다.
새 함수·프롬프트·평가 알고리즘은 없다. 잘못된 hash/page/문항/시험 및 이전 locator는 거부됨을 확인했다.
원문·이미지·SQL은 ignored `.local/natural-connection-20261111/kau/`에만 있다.
[공개 가능한 후보 명세/재현법](../supabase/candidates/natural_expansion_20261111/connection/README.md).

## 공식 자료 이슈와 소문항 분리

[5개 parent 문항의 알려진 불일치 목록](../supabase/candidates/natural_expansion_20261111/connection/official-source-issues.json)에
physical page, 원본SHA, 해당 소문항, Owner 판단 항목을 기록했다. 원문 오류를 확정하거나 해설을 대체하지 않았다.

2024공학 Q2의 마지막 소문항만 기존ID로 독립 공개하는 것은 현재 구조로 바로 할 수 없다.
실제 `essay_questions`는 Q1/Q2 parent ID만 있고 독립 child ID/parent 관계 필드가 없다.
후보는 parent1개→Math leaf1개, 공통 gateway는 questionId→leafId 단일 매핑이다.
기존 `math_subproblems`가 있다는 사실만으로 별도 공개·제출이 되는 것은 아니다.
새 child ID·중복 leaf·엔진 수정은 하지 않았다. **Q1을 포함한 다른 문항 연결은 계속 유지**하며,
Q2 전체 또는 해당 소문항의 공개 방침/추가 분리 범위는 Owner가 결정한다. 시험 전체 자동 HOLD0.

## 신규 서비스 후보10개교

기존 Catalog42/우선22 재사용.10개 대학 row 신설이 아니라 기존 Registry260문항의 서비스 확장이다.
11/11 읽기 조회에서 문항있는45시험260문항과 `source-registration-v1`을 확인했다.
기존 WEB·APP 공통 `connectPublishedQuestions`에 실제 메타데이터를 넣어
28시험94문항의 exact ID 매칭 및 `evaluationReady=false`/private draft 권한 비승격을 검사했다.
공개 metadata의 null ID를 독자적으로 덮어쓰지 않는다. 기존 서버 connector를 재사용한다.

|대학|기존 시험/문항|공통 source 매칭 시험/문항|신규 첨삭 package|다음 연결 조건|
|---|---:|---:|---:|---|
|가천|17/166|0/0|0|기존 별도 Registry, 국어/수학 문항별 근거·엔진 구분|
|경북|1/3|1/3|0|자연Ⅱ 과학/수학 구분·공식 기준 연결|
|부산|2/6|2/6|0|원본 문항별 문제/기준/풀이 지면 확보|
|이화|1/3|1/3|0|자연Ⅰ 문제/기준/풀이 지면 확보|
|세종|3/9|3/9|0|A/B·모의 회차별 공식 지면 확보|
|아주|6/12|6/12|0|자연6 우선, 인문6은 기존 Essay 계약|
|연세|12/47|12/47|0|기존 servicePreparing HOLD. source2025추가1시험3문항 ID 미일치 별도|
|홍익|1/7|1/7|0|세종 캠퍼스 보존·기존 servicePreparing HOLD|
|서울시립|1/4|1/4|0|2027모의 보존·기존 servicePreparing HOLD|
|가톨릭|1/3|1/3|0|기존 인문3, 자연 문항으로 전환 금지|

[대학별 준비 상태](../supabase/candidates/natural_expansion_20261111/connection/ten-university-readiness.json).
이번 검증은 새10개교의 평가 기준 연결 완료가 아니다. source metadata는 시험 identity/label만 검증했고
문항별 `sourceLocator`가 없는 경우가 있어 공식 근거를 추정 연결하지 않았다.
주요 로컬 원본 archive `essay-2026-10`에는 기존16개교만 있으며 신규 목록 중 가천 외9개교 원본은
그 경로에서 확보되지 않았다. 다른 보관소/공식 입학처 원본 확보·지면 연결은 잔여 작업이다.

## 검증 결과

|검사|결과|
|---|---|
|Python identity·원문 보존·HOLD·source 형식|18 PASS|
|로컬 PostgreSQL17 기존 Worker|12문항/120검사 PASS; 공식 이미지48role연결·ACL·틀린ID/hash/page/locator 거부|
|로컬 제출→Mock 결과|공통6+문항별72 PASS; DRAFT 거부·멱등성·기준ID·결과 조회/타계정 차단·기존답안/결과/원장 hash 보존|
|WEB 후보 연결|25 PASS;12문항·6시험·PDF 승인 차단·10개교 Registry connector|
|기존 WEB 결과/재작성|5 PASS; 실제 기존 bridge·rewrite Mock 검사|
|Flutter|31 PASS/4 SKIP;12문항 입력·공유 DTO, 기존 결과·History·재작성·수식.4개 private 승인결과 fixture 없음|
|Flutter Analyze|PASS|
|공식 원본/PDF|원본 v1내용·6학생PDF SHA 보존. 기존25쪽 육안 검수 재사용; 신규 기기 렌더는 미실행|
|신규 제품 실패|0. 초기 후보SQL FK순서, Mock HTTP request 누락, 신규 테스트 타입/style 진단은 수정 후 통과|
|실제 TEST/운영계정·기기/새 빌드|NOT TESTED/NOT RUN. 로컬 Mock과 구분|

[검증 영수증](../supabase/candidates/natural_expansion_20261111/connection/verification.json),
[Worker](../supabase/candidates/natural_expansion_20261111/connection/worker-contract-report.json),
[제출·결과](../supabase/candidates/natural_expansion_20261111/connection/contract-report.json).
APP 제품 코드 변경이 없어 새 설치/빌드를 하지 않았다. 기존 APP75 전체 FAIL5 재검증은 이번 범위 밖이다.

## 보존 검토7항

1. 사실은 원본 출처·학년도·문항 identity·연결 검수다. 학생 학습/성적 사실을 새로 만들지 않는다.
2. 원본SHA·physical page·기존 v1 package hash·새 connection version으로 재현 가능하다.
3. 기존 rows/원문을 UPDATE하지 않는다. 새 내부ID 후보이며 이전후보·의심사항·중단실험 이력을 구분한다.
4. 기존 대학/시험/문항/학생 identity 불변. 학생계정·현재학년과 과거 문항을 재귀속하지 않는다.
5. Learning용 공식 참고자료이며 지원·입시 Outcome이나 AI 품질 판정이 아니다.
6. 비공개 공식 지면 ACL·학생별 결과 권한을 재사용한다. 계정/답안/비밀키를 Git에 넣지 않는다.
7. 의심 사항·Mock 결과·파생PDF는 공식 정정/성적/실제 품질 사실로 저장하지 않는다.

## 운영 적용 필요 사항·Owner 인계

현재 실행 가능한 것은 **로컬 검수**이며 운영 변경 승인은 새로 요청하지 않았다.
Owner는 문항별 공개 목록과 공식 불일치 처리 방침을 먼저 결정할 수 있다.
신규 실제 적용은 그 범위가 확정된 뒤 다음을 사전 SELECT로 다시 비교해야 한다.

1. 기존 Registry·중복 Math binding·원본SHA·현재 함수/권한의 drift 확인.
2. 승인된 문항의 DRAFT172행 중 대상만 기존8테이블에 등록. 같은ID 다른내용이면 즉시 중단.
3. 기존 private source table에 해당 지면만 INSERT, 학생용PDF 별도 upload/hash·Storage 권한 검증.
4. 기존 release catalog/서버 scope/WEB metadata에 승인된 시험·문항만 추가. 신규 엔진 없음.
5. 실제 WEB·APP 계정에서 PDF·입력·제출·결과·재작성 확인. 품질은 Owner 검수.
6. 장애 시 새 공개/실행 scope만 회수하고 기존 사용자 답안·첨삭 기록·원본·DRAFT는 보존.

이번에는 activation/RPC 변경 SQL·배포를 실행하지 않았다. 검수용 SQL은 원본 전체 일괄 실행 대상이 아니다.
한국항공 공개, 중앙과학11 HOLD 해제, 연세/홍익/시립 HOLD 해제는 각각 별도 Owner 결정이다.
전체 확장 완료로 처리하지 않는다. 다음은 기존 자연계열 누락의 공식 지면 연결 및 신규10개교 미완료 package다.
