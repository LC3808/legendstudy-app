# 자연·수리 논술 대학별 순차 작업 — 최신 Owner 결정


최신 Owner 기준은 **검증된 문항의 운영 연결·사용자 공개**다. AI 품질은 전체대학후Owner통합검수하며 다음대학진행조건이 아니다. [건국24](essay-konkuk-public-20261112.md),[경희7](essay-kyunghee-public-20261112.md),[서강11](essay-sogang-public-20261112.md),[숭실19](essay-soongsil-public-20261112.md),[숙명44](essay-sookmyung-public-20261112.md),[동국20](essay-dongguk-public-20261112.md) 공개결과를 확인한다. 아래 TECH기준은 후속개발자료의 준비상태이며 공개완료를 뜻하지 않는다. 한대학씩진행,Provider반복호출·AI품질대행·엔진변경금지.

## 확정 순서와 현재 상태

기완료: **한양대학교·중앙대학교·고려대학교·인하대학교**. Owner가 완료 대학으로 지정했으며 작업을 반복하지 않는다. 이 기록은 오늘 네 대학의 전체 운영 상태를 새로 검사했다는 의미가 아니다. 중앙대 과학11 HOLD 예외는 계속 보존한다.

|순번|대학|현재 상태|다음 행동|
|---|---|---|---|
|1|한국항공대학교|7문항 운영 DRAFT / HOLD5|후속공개연결미완료;재적재금지|
|2|건국대학교|신규24 PUBLISHED / 기존4 보존|DONE|
|3|경희대학교|신규7 PUBLISHED / 기존3 보존 / NOT READY16|공개대상DONE,미준비16별도|
|4|성균관대학교|15 TECH READY / PDF RIGHTS_HOLD|권한확인전공개금지|
|5|서강대학교|9시험11 PUBLISHED|DONE|
|6|숭실대학교|5시험19 PUBLISHED / 2024Q2 HOLD1|공개대상DONE,HOLD유지|
|7|숙명여자대학교|16시험44 PUBLISHED / 기존6 보존|Owner확인DONE|
|8|동국대학교|7시험20 PUBLISHED / 2026모의Q1 HOLD1|PARTIAL;공식수정근거보완,다음광운|
|9|광운대학교|42 TECH READY|다음순서:공식PDF·권한·운영범위재검증후공개연결|
|10|서울여자대학교|수리3 TECH READY / 과학6 NOT READY|36행 운영 승인 별도·과학 기존 경로 결합 미완료|

후순위 대학의 기존 산출물은 폐기하거나 다시 만들지 않는다. 실제 차례에 기존 운영/Registry/공식 근거를 대조해 미완료만 처리한다. 현재 뒤 대학 개발·운영 적용은 진행하지 않는다.
HOLD 또는 운영 승인으로 막히면 즉시 Owner에게 보고한다. HOLD를 해제하거나 대학 전체 완료로 표시하지 않는다. TECH READY가 확인된 범위와 HOLD/NOT READY를 분리해 다음 순번으로 진행한다. Owner 품질 검수 대기만으로 중단하지 않는다.

## TECH READY / REVIEW READY 기준

- TECH READY: 확정 Registry/시험/문항 ID, 공식 PDF·평가 기준·Math package·기존 Worker 자료 계약, WEB·APP 입력/결과/재작성 흐름 계약 및 기존 데이터/권한 보존을 증거로 확인한다. HOLD/NOT READY/부분 시험은 제외·별도 표기한다. 로컬 후보 파일 존재만으로 완료 처리하지 않는다.
- TECH READY는 운영 적재·실제 AI 품질·실계정 접근·사용자 공개를 뜻하지 않는다. 대학별 검증 결과를 보고한 후 다음 순번으로 진행한다. 운영 승인 대기는 별도 상태로 기록한다.
- REVIEW READY: 전체 대상의 승인된 실제 검수 경로에서 지정 Owner 계정이 대학→시험→문항→입력→기존 Worker→결과→재작성 흐름을 사용할 수 있는 상태다. 실제 AI 품질은 이후 Owner가 통합 검수한다.
- 운영 DRAFT, 검수 접근/활성화, 배포, 사용자 공개는 별도 승인이다. 검수 기능은 공통 재사용 구조로 준비하며 대학별 연결을 막지 않는다.
- 일반 진행 보고는 생략하고 대학별 TECH READY, 운영 승인 필요, 공식 자료 불일치/차단을 보고한다.

## 한국항공대 — DRAFT 적용 결과와 남은 HOLD

현재12문항 중7문항·106행은 Owner 승인 후 운영 비공개 DRAFT로 적재했고5문항은 HOLD다. **현재 실제 SERVICE READY 확인0**,실제 WEB/APP 계정 검수 NOT TESTED다. [적용 결과·전후 검증](essay-kau-draft-production-20261112.md).
[기존 공식 이슈5개](../supabase/candidates/natural_expansion_20261111/connection/official-source-issues.json) · [문항별 근거](essay-four-university-question-review-20261111.md).

|HOLD|이유/Owner 판단|
|---|---|
|2024 공학Q2|마지막 소문항 문제·공식 풀이 불일치;기존 Owner HOLD 유지|
|2024 공학Q1|공식 풀이 중간 로그 전개의 부호 검수|
|2024 이학Q1|공식 기준표와 예시풀이 배점 차이 검수|
|2026 이학Q1|공식 풀이 부호·배점 차이 검수|
|2026 이학Q2|공식 풀이 이차식 부호 차이 검수|

원문·해설을 고치거나 HOLD를 임의 해제하지 않는다. 부분 시험의 공개/진입 정책도 자동 결정하지 않는다.

새 순서에 맞춰 [한국항공 단독 적용 후보](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/README.md)를 기존53 후보에서 분리했다.
**4시험7문항 / 기존 Math8테이블99행 + private Worker7행 =106행 DRAFT INSERT**만 승인받아 적용했다.2024 이학Q2는 해당 시험의 부분1문항이며 공개 승인과 다르다.
HOLD5,후순위 후보46,기존 운영7,중앙 과학11은 적용 대상에서 제외한다. 기존53 일괄 SQL은 역사적 검증 자료로 보존하지만 현재 실행 대상으로 사용하지 않는다.
정확한 단독 apply/verify/retire SQL로 **격리 PG17 명명 검사55 PASS**:7문항×2계정 DRAFT 차단,Worker 자료 해석,기존 기록/함수/권한 보존,실패 시 전체 취소,후순위46 미적재,반복 원복·결과 읽기.
원복은 신규 versioned4테이블28행 DRAFT→RETIRED만 변경하며 공식 자료·사용자 이력은 삭제하지 않는다.
위55개는 격리 승인 준비 증거다. 이후 승인 실행에서 운영 사전116/사후122조건 PASS 및20개 보존 snapshot 동일을 확인했다. DRAFT 적재는 DONE이나 SERVICE READY 완료 보고는 아니다. apply 재실행 금지,Provider·배포0.

별도 미해결 사항: [Owner 전용 검수 접근 제어 GAP](essay-four-university-production-preflight-20261112.md#공개-차단과-owner-검수-경로--핵심-gap).
DRAFT는 Owner도 제출 불가. 현재 ACTIVE만 켜면 다른 로그인 계정의 직접 RPC 제출을 차단하지 못한다. 숨김 목록/WEB allowlist만으로 우회하지 않는다.
따라서106행 DRAFT 적재 승인만으로 실제 서비스 검수나 사용자 공개까지 승인된 것으로 보지 않는다. Owner 전용 검수 경로를 별도 준비·검증하고,운영 RPC 변경이 필요하면 정확한 변경안을 다시 승인받는다. 평가 엔진은 유지한다.

## 결정·검증 인계

[기존 보존 검토7항](essay-four-university-production-preflight-20261112.md#보존-검토7항-및-승인-경계)을 그대로 계승한다. 선택된 UUID 범위만53→7로 축소했고 새로운 저장 구조/이력 UPDATE/점수 추정은 없다.
승인된 운영 DRAFT106행 INSERT 완료. RPC 변경·활성화·사용자 공개·WEB/APP 배포0. 이는 한국항공 적재 당시 기록이며, 최신 순차 검토 집계는 상단 표와 [통합 검수 준비](essay-natural-integrated-review-20261112.md)를 따른다. **승인/HOLD 보고만으로 TECH READY로 간주하지 않는다**.
Git HEAD는 `git log -1`로 확인한다. SQL 실행 파일·SHA·대상 UUID·검증 결과는 아래 후보 README에서 추적한다.

## 2026-11-12 검수 일정 변경 반영

한국항공7문항은 기존 Registry/공식 자료/Math·Worker/WEB·APP Mock 계약과 운영 DRAFT106행 보존 증거를 갖춘 TECH READY 범위다. HOLD5는 제외한다. 실제 Owner 검수 경로는 아직 REVIEW READY가 아니며 [접근 제어 준비](essay-owner-review-access-20261112.md)로 분리한다. 대학별 상세 기술 검증 증거와 후순위 진행은 후속 항목에 기록한다.

[대학별 TECH READY 결과·검사 수·서강 PDF 누락](essay-natural-tech-ready-20261112.md): 한국항공→건국→경희→성균관→서강 순차 검증, 실제 품질 검수는 통합 단계로 유예. 숭실16/부분3/검수보류1을 후속 확인했고 다음은 숙명.

현재 지정10개교 순차 검토 결과와 다음 실행은 [통합 검수 준비](essay-natural-integrated-review-20261112.md)에 있다. TECH186/부분7/HOLD6/NOTREADY22/기존보존13. 전체 REVIEW READY 아님.
