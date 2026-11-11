# 네 대학 자연계열 운영 연결 사전 검증 — 2026-11-12

**1단계 비공개 적재 준비 DONE / 운영 적용 NOT APPLIED / Owner 실제 첨삭 검수 NOT TESTED.**
Owner 2026-11-11 지시와 기준 commit `536a2fc22c5fa763d31fa59fe239460cef93d794`를 이어받았다.
브랜치 `codex/essay-natural-expansion-20261111`. 현재 HEAD는 `git log -1`로 확인한다.
운영 SELECT 시각 **2026-11-12 00:05:50 KST**. 운영 DB/RPC 쓰기·Provider 호출·WEB/APP 배포·신규 공개 모두 **0**.
[이전 58문항 연결 검증](essay-four-university-connection-20261111.md) · [81문항 상세 근거](essay-four-university-question-review-20261111.md) · [기존 Owner 결정](decisions.md#2026-11-11--자연계열-네-대학-연결-범위).

## 58 대 81 및 이번 승인 요청안

**81 = 기존 운영7 + 신규 후보58 + NOT READY16. 후보58 = 이번 비공개 적재 제안53 + HOLD5.**
Registry ID = 기존 `essay_questions.id`. 신규 시험/Registry ID 생성0, 중복 후보0, 기존7 중복 적재0.
기존 운영7은 Math ACTIVE 연결을 뜻한다. 현재 Registry의 `is_active/is_published`는81개 모두 false여도 기존 Math release catalog의 별도 허용 목록으로 동작한다. 따라서 Registry 플래그만으로 기존7을 미연결/비공개라고 판단하지 않았다.
건국2026 Q1의 legacy leaf는 FK가 NULL이며 기존 release catalog의 UUID 별칭으로 연결됨을 확인했다.

|대학|검수 시험/문항|기존 보존|기존 후보|이번 DRAFT 시험/문항|HOLD 제외|NOT READY 제외|추가 조건|
|---|---:|---:|---:|---:|---:|---:|---|
|한국항공|6/12|0|12|4/7|5|0|2024 이학은1문항만 적재; 부분 공개 승인 아님|
|건국|7/28|4|24|6/24|0|0|기존2026 수시4 보존|
|경희|5/26|3|7|3/7|0|16|의약 수학4는 시험 전체 서비스 미완료|
|성균관|5/15|0|15|5/15|0|0|PDF 승인 대기15 유지|
|합계|23/81|7|58|18/53|5|16|신규 공개0|

53은 **Codex의 승인 요청안**이며 Owner가 이미 승인한 수가 아니다.
PDF 대기15 및 경희 partial4는 다른 상태와 겹치는 하위집합이며 별도19개를 더하지 않는다.
이번 적재안의 부분 시험 문항은 항공2024 이학1 + 경희 의약4 =5개다. 기존 전체58 WEB 후보를53문항 검수/공개 허용 목록으로 그대로 사용하지 않는다.
경희 부분4는 공식 근거·leaf 계약은 연결되었지만 의약 시험8문항 중 과학6개씩이 미완료다.
NOT READY16은 이 과학12 + 2022 모의 자연 공식 채점 기준 미확인4다. 예시답안만으로 채점 기준을 생성하지 않는다.
성균관15의 학생 PDF `VISUAL_REVIEWED/PENDING/PENDING`은 그대로 보존한다. 비공개 DB 자료 적재와 PDF 공개 승인은 별개다.
중앙대학교 과학11 HOLD는 이번81 분모 밖이며 관련 SQL0. 기존 중앙 Math 데이터도 전체 기존 행 보존 검사에 포함한다.

## 적용·검증·원복 산출물

[실행 절차와 파일](../supabase/candidates/natural_expansion_20261111/production-preflight/README.md) · [정확한 UUID 범위](../supabase/candidates/natural_expansion_20261111/production-preflight/scope.json) · [SQL SHA 영수증](../supabase/candidates/natural_expansion_20261111/production-preflight/sql-receipt.json).

추가 대상은 기존 Math 테이블8개 **687행**, 기존 비공개 Worker 테이블 **53행**, 총 **740행 INSERT**다.
신규 영구 객체/컬럼/RPC/정책/권한 변경0. `CREATE TEMP TABLE`은 transaction 내 보존 비교용이며 commit 시 삭제된다.
원본 공식 자료를 담는 정확한 SQL은 ignored `.local/natural-production-preflight-20261112/apply-draft.private.sql`에만 둔다.
전체 기존58 후보의 대학별 apply SQL을 합쳐 실행하지 않는다. 이번53 전용 단일 transaction 파일만 승인 대상이다.

|테이블|추가 행|
|---|---:|
|math_problem_sets|53|
|math_problems|53|
|math_subproblems|53|
|math_source_artifacts|212|
|math_evaluation_profiles|53|
|math_scoring_criteria|81|
|math_canonical_solutions|53|
|math_canonical_solution_steps|129|
|math_private.task20_hanyang_source_pages|53|

SQL은 Repeatable Read snapshot,5초 lock timeout,60초 등록 statement timeout(외곽120초),동일 작업 advisory lock을 사용한다.
일반 사용자 작업을 막는 전체 table lock은 사용하지 않는다. 운영 사용자 기록의 사전 고정 hash를 미래 적용 조건으로 사용하지 않고, **적용 transaction의 같은 snapshot 내 전후 불변**을 검사한다.
사전 조건116개: 함수7개 정의, 테이블9개 RLS/anon·authenticated 권한, Worker 직접 실행 차단, Registry81개, 기존 ACTIVE7, 신규 leaf 공개 목록 제외, 후보 ID/Worker/외부 leaf 중복 없음.
1개라도 다르면 쓰기 전에 중단한다. 기존 content/history/Registry·함수/owner/ACL·RLS·테이블 권한의 사후 차이는 전체 transaction ROLLBACK.
등록/Worker INSERT 후 정확한 개수·DRAFT·Worker exam/question/digest를 재확인한다. 자동 ON CONFLICT 덮어쓰기나 신규 후보 자동 활성화는 없다.

비파괴 원복은 이번53의 versioned4테이블 **212행만 DRAFT→RETIRED** 처리한다. Registry,공식 근거,Worker 이미지,학생 답안·첨삭·원장은 보존한다.
반복 원복은 무변경이다. 이미 ACTIVE가 된 경우에는 이번1단계 범위를 벗어났으므로 `ROLLBACK_SCOPE_CHANGED`로 중단한다. 이후 활성화 승인 단계에는 별도 비상 비활성화 절차가 필요하다.
RETIRED 데이터를 삭제하여 다시 적용하지 않는다. 재활성화/재적재는 새 범위 검토가 필요하다. 공용 RPC 권한 회수로 기존 대학을 중단시키지 않는다.

## 운영 읽기 검증 및 보존

[운영 SELECT116 결과](../supabase/candidates/natural_expansion_20261111/production-preflight/production-preflight-result.json) **116/116 PASS**.
신규 후보53 leaf/Worker0, 기존7 ACTIVE 유지(legacy1 포함),9테이블 모두 RLS=true,anon/authenticated의 직접 조회·쓰기 권한 없음. Worker 함수 직접 실행 권한 없음.
기존 helper MD5 `54acd2a1914f360e6ecd62e39acc8222`와 공개 catalog/input/submit/resolve 등 정의도 확인했다.
읽기 시점 보존 기준: Registry 시험450/문항1232,대학53,Math 답안69/평가13,credit_transactions649,private Worker103.
검사 범위의 함수346/RLS정책269/테이블 권한107 snapshot을 남겼다. 이 함수 수는 public/math_private/essay_private/account_private 내 일반 함수 분모이며 전체 프로젝트 함수 수가 아니다.
운영 원격 SELECT만 했으므로 **운영 적용 전후 데이터 동일성을 검증했다고 보고하지 않는다**. 기존 실제 사용자 답안 내용/계정 식별자는 반출하지 않고 집계/hash만 기록했다.

## 연결 근거·PDF·Source Registry

53개는 이전 검증 패키지의 SHA와 일치한다. 원문·문항 순서·수식·평가 기준·페이지를 재전사하거나 수정하지 않았다.
기존 Source Registry patch/additions,Math mapping,input mode,공통 결과/재작성 경로를 재사용한다. Source Registry 파일 반영/WEB 공개 scope 갱신은 이번 DB53 INSERT 승인에 포함하지 않는다.
공식 문제·기준·해설은 Source artifact SHA/physical page/role 및 Worker 이미지로 연결되며,53개 모두 기존 Worker 함수가 해당 자료를 해석함을 다시 검증했다.
평가 기준은 기존 page-level 기준이다. 구조화 `official_points=NULL`을 점수0 또는 새 배점으로 해석하지 않는다. 실제 AI 첨삭 품질 판단은 Owner/사용자 담당이다.

이번53은 기존 학생용 PDF18자산을 참조한다.38문항 기존 APPROVED,성균관15 PENDING 유지. 기존58/20자산의 로컬 SHA·페이지 검증을 계승한다.
PDF 교체·Storage 업로드·승인 flag 변경0. 현재 원격 Storage 읽기와 신규 운영 WEB/APP 실계정 화면은 **NOT TESTED**.
항공5 HOLD 자료는 이전 원문 그대로 로컬에 보존하고 이번 SQL에는 넣지 않는다.2024 공학Q2(마지막 소문항 불일치) 문제/해설 정정 및 공개 결정은 Owner 대기다. 나머지4는 기존 공식 자료 이슈의 검수 보류이며 새로 시험 전체를 HOLD한 것이 아니다.

## 공개 차단과 Owner 검수 경로 — 핵심 GAP

**1단계 안전한 비공개 적재:** parent/problem/profile/canonical은 DRAFT,기존 release_catalog 허용 목록 불변,Registry 플래그 불변,WEB Source/expansion/public scope 불변,학생 PDF 권한 불변.
DRAFT에서는 Owner와 일반 로그인 계정 모두 `CONTENT_UNAVAILABLE`. 이것이 이번1단계의 정상 결과다.

**2단계는 아직 운영 실행 불가:** 현재 `resolve_profile`은 ACTIVE만 검사하고 새 leaf별 Owner 권한을 검사하지 않는다.
`math_submit_attempt`도 해당 경로를 사용한다. 격리 환경에서 후보1개를 ACTIVE로 전환한 후 일반 두 번째 계정이 leaf ID로 직접 제출할 수 있음을 재현했다. Provider는 호출하지 않았다.
WEB의 `MATH_ALLOWED_SUBJECTS`는 WEB endpoint 보호이며 Supabase 직접 RPC의 인증 사용자까지 제한하지 못한다.
`ESSAY_E2E_SCOPE`는 새 Math expansion availability 분기 이후에 검사되어 이 문제의 보안 경계가 아니다.
**공개 목록에서만 숨긴 ACTIVE 전환을 Owner 전용 검수로 사용하면 안 된다.**

Owner 검수의 순서는 다음과 같다.
1. 이번1단계만 승인·적용한 뒤,DB verify와 신규 사용자 진입 차단을 확인한다.
2. 별도2단계 작업에서 지정 Owner subject UUID + 지정 leaf 범위를 DB 제출/평가/재작성 경로에서도 강제하는 최소 검수 허용 방식을 검토한다. 기존 엔진/Provider/Credit 정책은 바꾸지 않는다. 다른 계정 direct RPC 거부 및 기존7 회귀 검증이 선행되어야 한다.
3. 그 별도 승인 후에만 제한된 검수 WEB/APP에서 대학→시험→문항→답안→기존 Worker→결과→재작성으로 Owner가 실제 첨삭을 평가한다. 현 시점 접속 가능 URL이나 실계정 완료 결과를 제시하지 않는다.
4.3단계는 PDF·공식 자료·부분 시험 진입까지 승인된 문항에 대해서만 별도 공개 승인한다. HOLD/NOT READY/PDF 대기 자동 승격 금지.

이 GAP은 신규 기능을 이번에 추가 개발하라는 의미가 아니다. **이번 요청의1단계 승인과 향후2·3단계 승인을 구분하기 위한 확인 결과**다.

## 이번 검증 결과

|검사|결과|한계|
|---|---|---|
|운영 SELECT 사전 조건|116 PASS|운영 쓰기0,적용 직전 재조회 필요|
|정확한53문항 apply/retire SQL|238 PASS|격리 Unix-only PG17,운영 함수 정의 복제,synthetic 계정·이력|
|DRAFT 사용자 제출 차단|53×2계정 PASS|Owner도 차단,실제 운영 계정 테스트 아님|
|기존 Worker 자료 해석|53 PASS|공식 이미지/역할 반환,Provider 호출0|
|적용 실패 원자성|PASS|권한/RLS/함수/공개 drift,Worker 단계 실패,기존 데이터 변경 주입 시 전체 원복|
|기존7/결과/기록 및 롤백|PASS|목록·기존 결과 읽기,원장/답안 보존,53 RETIRED 재제출 차단,반복 원복|
|Python 연결 회귀|22 PASS|기존 패키지·정합성 검사|
|WEB 권한/진입/결과/재작성 회귀|65 PASS|5 test files,Mock만 사용,WEB tracked 변경0|
|APP 회귀·실기기|이번 NOT TESTED|앱 소스 변경0;직전77 PASS/4 SKIP 및Analyze PASS는 과거 증거|
|Owner 실제 첨삭 품질·운영 E2E|NOT TESTED|2단계 접근 제어 GAP 및 별도 승인 대기|

최초 새 하네스 실행에서 Connection 대신 Cursor를 사용해야 하는 psycopg 결과 수집 오류1건을 수정했다. 최종 검사 실패0. 서비스/운영 오류가 아니다.
이238은 명명된 검사 수이며 내부 assertion 전체 수가 아니다. [격리 결과](../supabase/candidates/natural_expansion_20261111/production-preflight/isolated-results.json).

## 보존 검토7항 및 승인 경계

[기존 보존 검토](essay-natural-expansion-20261111.md#보존-검토7항)와 [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)을 계승한다.
1. 학년도/시행일/검수·적용 시점 분리: 시행일 추정0,이번 적용 시각은 아직 없음.
2. 공식 원본 SHA·physical page·문항 UUID·Worker payload를 재현 가능하게 보존.
3. 기존 version/학생 이력 UPDATE 없음;신규 DRAFT 추가와 식별된 신규 상태만 RETIRED 원복.
4. 기존 계정·권한·탈퇴 정책 유지;실제 계정 쓰기 없이 synthetic 계정으로만 검사.
5. 학습/첨삭 기술 계약을 입시 결과나 AI 품질 사실로 전환하지 않음.
6. RLS/ACL 유지;원문·이미지 포함 SQL은 private ignored 파일,Git은 메타데이터/hash와 코드.
7. Provider/Credit/운영 공개는 별도 승인;현재 단계에서는 운영 쓰기0,기존 APP75·WEB 기능 변경0.

**Owner 승인 요청:** 이번18시험53문항의 DRAFT687행 + private Worker53행,총740행만 운영 Backend에 비공개 적재하는1단계.
성균관15 PDF 승인 대기 및 경희 partial4는 비공개 자료 저장만 포함한다. 기존7/HOLD5/NOT READY16/중앙 과학11은 변경하지 않는다.
RPC/정책/권한·활성화·WEB/APP 배포·실제 Provider 호출·사용자 공개는 승인 범위에 넣지 않는다.
