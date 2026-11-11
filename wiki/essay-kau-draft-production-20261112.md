# 한국항공대 운영 DRAFT 적재 결과 — 2026-11-12

**DRAFT 적재 DONE / SERVICE READY 아님 / 실제 Owner 서비스 검수 NOT TESTED.**
[Owner 대학 순서·완료 기준](essay-natural-sequential-order-20261112.md)을 유지한다. 현재 대학은 한국항공대이며 다음 대학으로 진행하지 않았다.

## 승인과 실행 범위

Owner가 HOLD 제외 한국항공7문항·106행의 운영 DB 비공개 DRAFT 적재를 명시적으로 승인했다.
기존 Registry 유지,검증된 단독 SQL만 허용했다. HOLD5·53문항 일괄안·RPC 변경·Worker 활성화·사용자 공개·WEB/APP 배포·기존 데이터 수정/삭제는 승인에서 제외했다.
이번 실행은 이 명시적 승인에 따라 Codex가 수행했다. 기존 일반 원칙의 Owner 직접 SQL 실행 요청을 새로 요구하지 않았다.

- 운영 프로젝트: **LegendStudy / stlhijzpjfgwwdgunlsd**, ACTIVE_HEALTHY 확인. 다른 프로젝트 접속/변경0.
- 적용 원본 Git: `be7f519`. 현재 HEAD는 `git log -1` 참조.
- SQL SHA256: `c4fdfeb05aa785ff7ca6afd9da3c20a0dad69c7f0294d94bf065e84ad4a3da62`,3,088,782 bytes.
- 원본: `.local/kau-production-preflight-20261112/apply-draft.private.sql`. 원문·이미지 포함으로 Git 제외 유지.
- 운영 재조회: **2026-11-12 00:22:43 KST**,116개 조건 전부 PASS.
- 실행 시작 **00:23:31 KST**,성공 응답 수신 **00:27:07 KST**. 정확한 서버 commit timestamp는 별도 저장하지 않았으며 이 구간으로 기록한다.
- 사후122개 조건 확인 **00:27:26 KST**,대상/HOLD/공개 목록 명시 조회 **00:28:02 KST** 완료.
- 실행 방식: `execute_sql`,검증한 단일 Repeatable Read transaction 그대로1회. 영구 DDL/RPC 변경0,Migration history 등록0. 따라서 새 migration version을 만들어 적용됐다고 기록하지 않는다.

[실행 영수증](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/production-application-receipt.json) · [SQL·롤백 영수증](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/sql-receipt.json).

## 신규 적재 106행

|기존 테이블|신규 행|
|---|---:|
|math_problem_sets|7|
|math_problems|7|
|math_subproblems|7|
|math_source_artifacts|28|
|math_evaluation_profiles|7|
|math_scoring_criteria|9|
|math_canonical_solutions|7|
|math_canonical_solution_steps|27|
|math_private.task20_hanyang_source_pages|7|
|합계|106|

대상은4시험7문항. versioned4테이블28행 모두 DRAFT이며 기존 Worker **자료**7행만 저장했다. Worker 실행·활성화·Provider 호출·평가 요청은0.
원본 공식 근거/평가 기준/수식·문항 순서는 검증 패키지 그대로이며 신규 시험/Registry ID를 생성하지 않았다.

|Registry/문항 ID|시험 ID|상태|
|---|---|---|
|6eaec5d3-4786-55a2-8dc6-a457edd5b16b|6815943a-42c1-5eae-b711-449ac403b9fb|DRAFT / is_published=false / exam_active=false|
|8744f2ad-02c4-51d4-83de-6d5ab245cec5|85a8468d-2141-52b1-9d70-3bcf6f340f8e|DRAFT / is_published=false / exam_active=false|
|d3909209-b5ee-50ce-b5cb-5cbbb8e0a65a|6815943a-42c1-5eae-b711-449ac403b9fb|DRAFT / is_published=false / exam_active=false|
|ebd76ca2-dbb4-5c0f-a203-4c77650e8a77|3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af|DRAFT / is_published=false / exam_active=false|
|ed096a20-52a7-5f27-a71b-4c7c2401cdc9|51d7f36d-a011-5279-8c5d-f731b2900af3|DRAFT / is_published=false / exam_active=false|
|fccb2d75-d4e6-54ec-b0fe-f3eced268b36|85a8468d-2141-52b1-9d70-3bcf6f340f8e|DRAFT / is_published=false / exam_active=false|
|ff6226fc-32ac-5903-ab0f-b1560803efbb|3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af|DRAFT / is_published=false / exam_active=false|

## 실행 전·후 검증

[사전116조건·보존 snapshot](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/production-before.json) · [사후122조건·보존 snapshot](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/production-after.json) · [7문항/HOLD5/공개 조회](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/production-scope-postcheck.json).

|확인|결과|
|---|---|
|사전 SQL·대상·롤백 SHA|PASS;기존 격리55검사에서 실행한 동일 SQL|
|현재 운영의 중복·충돌·Registry·권한 조건|116/116 PASS;조건 변화 없음|
|대상7·99 Math+7 Worker 행 및 Worker identity/digest|122/122 사후 조건 PASS|
|기존7 운영 Math 연결|ACTIVE 유지;legacy NULL FK 별칭 포함|
|HOLD5|Registry ID/비공개 유지,Math leaf0·Worker 자료0|
|후순위46|Math leaf0·Worker 자료0;이번 실행 대상 제외|
|신규 공개 차단|7문항 is_published=false,4시험 is_active=false,release_catalog 신규 leaf0|
|직접 자료 접근|9테이블 RLS 및 anon/authenticated 권한 불변,private Worker 직접 execute 차단 유지|
|기존 데이터·함수·권한|20개 보존 snapshot 모두 count/hash 동일|
|복구 필요 여부|실패0,롤백 미실행|

20개 보존 snapshot은 신규 ID를 제외한 기존 Math8테이블/private Worker1,대학/시험/문항 Registry3,Essay 답안·평가/원장/Math 답안·평가5,함수 정의·소유자·ACL1,RLS 정책1,테이블 소유자·RLS·ACL1이다.
사전/사후 기존 데이터 비교에는 대학53,시험450,문항1232,원장650,Math 답안69/평가13,기존 Worker자료103이 포함된다. 범위 내 일반 함수346,RLS정책269,테이블 권한107도 동일하다.
초기 준비 시 원장649에서 이번 승인 실행 직전650으로 늘어난 것은 과거 snapshot과의 차이이며 기존 검증 조건은 고정 원장 수가 아니다. 이번 실행의 사전/사후650행 전체 hash는 동일했다. 기존 데이터를 과거 수에 맞추려 수정하지 않았다.
SQL 내부에서도 같은 Repeatable Read snapshot으로 기존 데이터/보안 객체 변경 시 전체 취소하도록 검사했고,운영 사후 별도 SELECT에서도 변화0을 확인했다.
이 보존 근거의 테이블/함수 범위를 넘어 모든 외부 시스템/전체 프로젝트 객체를 검사했다고 확장하지 않는다.

실제 사용자 로그인·앱 화면·Owner 첨삭은 실행하지 않았다. 비공개 유지 결과는 실제 운영 상태/정의/권한/공개 catalog 조회와 기존 격리 제출 차단 증거에 근거하며,실계정 UI E2E 완료가 아니다.

## 롤백 준비 상태

[사전 검증한 비파괴 원복](../supabase/candidates/natural_expansion_20261111/kau-production-preflight/rollback-retire.sql)의 SHA256은 `9d5012c703de88a77a51a3d2ba89c708d512918b588c52c40449c9574752f71f`로 일치한다.
신규28개 version행은 모두 DRAFT여서1단계 원복 조건을 충족한다. 이 SQL은 해당28행만 RETIRED로 바꾸고 Registry/공식 자료/Worker 자료/학생 이력을 보존한다. 반복 실행도 격리 검증했다.
현재 사후 검증 PASS이므로 운영 롤백을 실행하지 않았다. 향후 ACTIVE 전환/범위 변화가 있으면 기존1단계 rollback을 강행하지 않고 Owner에게 보고한다. 기존 데이터 영향 가능성이 있으면 임의 복구하지 않는다.
**현재 apply SQL 재실행 금지.** 대상 존재 검사는 재실행을 거부하도록 유지한다. 복구 뒤 DELETE/재등록으로 우회하지 않는다.

## 다음 단계 — 한국항공 Owner 전용 검수 접근 제어

1. 현재7문항 DRAFT를 유지하고,HOLD5 및 중앙 과학11은 그대로 둔다.
2. [확인된 접근 제어 GAP](essay-four-university-production-preflight-20261112.md#공개-차단과-owner-검수-경로--핵심-gap)을 기준으로 지정 Owner subject·7 leaf에 한정한 검수 경로를 준비한다. WEB 허용 목록만으로 직접 RPC 접근을 막는다고 가정하지 않는다.
3. 기존 제출/평가/재작성·계정 제한·기존 사용자 결과 읽기·동일 요청 재처리를 보존하는 최소 변경안을 설계하고 격리 검증한다. 새 첨삭 엔진이나 Provider/Credit 정책은 만들지 않는다.
4. 실제 운영 RPC/권한/활성화/서비스 배포가 필요한 변경은 정확한 SQL·검증·롤백안을 제시한 뒤 별도 승인받는다. 이번106행 승인을 확대 해석하지 않는다.
5. 승인된 실제 서비스에서 Owner가 검수할 수 있을 때만 해당 범위를 SERVICE READY로 보고한다. 현재는 **DRAFT 단계 DONE**,대학 전체 완료 아님. 건국대 등 다음 대학으로 넘어가지 않는다.

기존 보존 검토7항과 공식 원문 불변 원칙을 계승했다. 이번 승인에서는 저장 구조/평가 엔진/기존 이력 UPDATE를 추가하지 않았다.
