# 자연·수리 통합 검수 준비 — 2026-11-12

최신 운영 상태: [건국 신규24문항 공개 완료](essay-konkuk-public-20261112.md). 아래 기술 후보/미적용 수치는 이전 검사 시점이며 현재 PUBLISHED 수를 뜻하지 않는다.
**PARTIAL. 대상10개교의 순차 기술 검토를 수행했으나 전체 REVIEW READY는 아니다.** [Owner 최신 결정](decisions.md#2026-11-12--tech-ready-순차-연결-후-owner-통합-검수)에 따라 대학별 실제 품질 검수 대기 없이 지정 순서대로 진행했다. 기완료 한양·중앙·고려·인하는 재작업하지 않았다.

## 정확한 집계

이번 연결/검수 대상은87시험234문항이다. 대학 전체 모든 연도·인문 Registry 수를 의미하지 않는다. 기존4대학 검수목록81문항과 후속6대학153문항을 기존 ID로 합쳤다. [문항별 통합 목록](../supabase/candidates/natural_tech_ready_20261112/integrated-review-scope.json)은 중복0, 상태가 상호 배타적이다.

|대학|TECH READY|부분|HOLD|NOT READY|기존 운영 보존|
|---|---:|---:|---:|---:|---:|
|한국항공|7|0|5|0|0|
|건국|24|0|0|0|4|
|경희|3|4|0|16|3|
|성균관|15|0|0|0|0|
|서강|11|0|0|0|0|
|숭실|16|3|1|0|0|
|숙명|44|0|0|0|6|
|동국|21|0|0|0|0|
|광운|42|0|0|0|0|
|서울여|3|0|0|6|0|
|합계|186|7|6|22|13|

한국항공7의2024이학Q2는 기존 승인 범위의 부분 시험 leaf1이다. TECH READY 기술 계약을 유지하되 whole-exam 진입 완료로 승격하지 않는다. 중앙 과학11 HOLD는 위234 대상 밖에서 별도 유지한다. 성균PDF15·서강PDF2보완·숙명신규38·광운신규42 = **97문항 PDF 승인 대기**는 TECH READY와 겹치는 승인 축이며 위 상태 합계에 더하지 않는다.

[대학별 상세/지면 검수/계약 결과](essay-natural-tech-ready-20261112.md). 실제 AI 품질 검수는0이며 Owner 통합 단계에 유예했다. 기존 연결13의 식별자를 재생성하지 않았고 기존 사용자 답안/평가/Credit를 수정하지 않았다.

## 운영 반영과 후보 행수

최종 [운영 SELECT](../supabase/candidates/natural_tech_ready_20261112/final-production-readonly.json): TECH186 Registry 존재, 공개문항0·활성시험0·Math연결7·Worker자료7. 기존 한국항공7 DRAFT만 존재한다. 이번 신규 운영 DB/RPC 쓰기0, Provider0, WEB/APP배포0, 사용자 공개0.

|대학 TECH 범위|문항|Math+Worker 후보 행|운영 상태|
|---|---:|---:|---|
|한국항공|7|106|기존 승인 적재 완료; 재실행 금지|
|건국|24|299|단독 승인안 준비·운영 미적용|
|경희 완성시험만|3|37|7leaf/92행 후보에서 별도 범위 SQL 분리 필요|
|성균관|15|243|미승인·미적용; PDF 승인 대기|
|서강|11|150|미승인·미적용; PDF 보완 승인 대기|
|숭실 완성시험만|16|200|20leaf/250행 fixture에서 HOLD·부분 제외 SQL 분리 필요|
|숙명|44|702|미승인·미적용|
|동국|21|286|미승인·미적용|
|광운|42|636|미승인·미적용|
|서울여 수리|3|36|미승인·미적용|

TECH186 대응2695행 중106행은 이미 적용됐다. 나머지179문항2589행은 **논리적 후보 합계이며 승인된 일괄 실행 SQL이 아니다.** 대학별 사전 조회/정확 범위/기존 권한·함수·데이터 snapshot/atomic apply·verify·비파괴 복구를 확정한 뒤 각각 승인을 받아야 한다. 기존53문항/숭실20문항 전체 SQL을 실행하지 않는다.

## 공통 Owner 접근 준비

[통합 접근 후보](../supabase/candidates/natural_owner_review_20261112/README.md)는 private table2/helper1, 기존 admission함수4의 로컬 수정안이다. 지정 계정은 기존 Owner 지정 identity를 사용하고 private 파일만 보관한다. 전역 enabled=false + 문항별 approved_for_review=false이며 두 조건과 만료/계정 lifecycle 조건을 모두 통과해야 한다.10대학에서 같은 정책을 사용하고 기존 엔진은 변경하지 않는다.

격리 PG17 **602 검사 PASS**:186개 leaf별 Owner허용/다른계정차단, 기본OFF, 문항별회수, 전역ON만으로 우회 불가, HOLD6/부분7/NOTREADY22 제외, 익명/권한, 만료, 탈퇴대기/삭제중, 회수후 큐claim차단, 이미수락한lease완료, 기존결과·ACL보존, 원래4함수 복구. 초기 fixture FK순서 실패는 기존8테이블 순서를 재사용해 수정했고 최종 실패0. Provider는 호출하지 않았다.

최종 운영 조회에서 신규 control/scope 테이블은 미존재,4개 기존 함수 MD5는 후보 baseline과 동일했다. **이 SQL은 운영 실행 준비 완료/승인 요청 대상이 아니다.**179문항 미적재와 승인·RLS/ACL 최종 snapshot 등 전제가 남았다. 설치/문항활성화/WEB·APP배포를 별도 승인한다.

WEB availability/evaluate/extract/upload/artifact의 public allowlist를 전역 확장하지 않는다. 서버가 확인한 Owner subject와 승인 scope로 제한한 preview 진입, 동일 Backend를 사용하는 APP 연결, 세션 wrapper/이미지 업로드/실제 계정 E2E가 아직 필요하다. 과거 읽기 전용 `/owner-review/essay/`는 이 기능이 아니다. 동시 회수·claim 경쟁과 정상 이미지 추출도 NOT TESTED다. 현재 실제 검수 시작을 안내하지 않는다.

## 남은 차단과 다음 실행 순서

1. [건국24/299행 단독 승인안](../supabase/candidates/natural_tech_ready_20261112/konkuk-production-preflight/README.md)을 준비했다. 운영 SELECT116 PASS·기존KAU106행을 포함한 격리 적용/원복124검사 PASS. Owner의 해당 범위 승인 후 실행 직전 재검증한다. 현재승인106행을 확대 해석하지 않는다.
2. PDF97문항 승인/서강 누락 보완 승인. 원본 변경 없이 기존 승인 자산을 보존한다.
3. 경희 부분4·숭실부분3·한국항공 부분1의 실제 검수 진입 범위를 확정한다. 부분 leaf를 전시험 완성으로 보이지 않게 한다.
4. 과학/공식기준 미준비22(경희16·서울여6)는 기존 경로와 근거를 보완한다. 새 엔진/Math·인문으로 강제우회 금지. 공식 불일치 HOLD6는 Owner 통합 목록에 유지하며 공개0.
5. 재사용 Owner 접근의 실제 WEB/APP 연결 및 운영 적용안·회수 절차를 완성한 뒤 별도 승인받는다.
6. 위 조건을 만족한 문항만 REVIEW READY로 전환하여 Owner에게 최종 통합 품질 검수 목록을 제공한다. 이후 문항별 공개 승인.

[보존 검토7항](essay-owner-review-access-20261112.md#보존-검토7항)을 계승한다. 검수 scope/권한은 현재 운영 projection이며 학생 학습 성취로 기록하지 않는다. 원본SHA·Registry·기존결과 유지, Mock을 실제 품질 사실로 승격하지 않는다.

최종 검증: 대학별 DB/Worker 합산3821·WEB298 PASS(비대상9SKIP)·Flutter196 PASS는 건국부터 서울여까지9개교 검사이며 한국항공의 기존 증거 재사용은 별도다. Python26·공통접근602·건국단독DRAFT124 PASS. 실제 AI/실계정 검수·기기 검증은 이번 범위에서 NOT TESTED. Git HEAD는 `git log -1`로 확인하며 Wiki 링크/인계검사와 `git diff --check`를 통과했다.
