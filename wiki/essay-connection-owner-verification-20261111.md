# Owner 연결 상태 검증 — 한국항공대 및 전체 확장

기준 소스 `f0c06b9`, 2026-11-11 운영 SELECT 재조회. 추가 기능·Provider·운영 쓰기·배포0.

**한국항공대12문항은 기존 Registry 등록 완료, 로컬 후보 기술계약 통과이며 운영 서비스 연결은0/12이다.**
이번 조회에서12개 모두 `is_active=false`, `is_published=false`, Math binding0, private Worker source 부재.
기존 Registry 데이터가 없다는 뜻이 아니라, 새 Math172행·Worker 지면·공개 설정이 반영되지 않았다는 뜻이다.

## 문항별 표

대학은 모두 한국항공대학교. 연도는 DB의 **학년도(admission_year)**이며 실제 시험 시행일의 달력 연도와 혼용하지 않는다.
Registry ID와 문항 ID는 모두 `essay_questions.id`로 같은 UUID다. 별도의 Registry UUID를 만들지 않았다.
아래 Registry key는 `question_key`, 추가 leaf UUID는 로컬 후보 내부ID다.
문제PDF 링크는 해당 학년도·계열의 공식 원본 파일명·SHA 명세이며 사용자 공개 URL이 아니다. 쪽수는 physical page.
학생용은 원본에서 해설이 섞인 부분을 제거한 기존6개25쪽 파생PDF로, Storage 업로드되지 않았다.
‘입력 PASS’=해당ID별 Mock Widget/요청 DTO. ‘Worker PASS’=해당ID별 로컬 기존함수.
‘결과/재작성 공통PASS’=공통 화면·라우팅 Mock 회귀이며 각 문항의 실제 기기 E2E는 NOT TESTED.

|대학|학년도|계열·문항|시험 ID|Registry key|Registry ID = 문항 ID|공식 문제PDF|공식 평가 기준|답안 입력 연결|기존 Worker 연결|기존 결과 화면|재작성·재첨삭|운영 DB 반영|사용자 공개|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|한국항공대|2024|공학계열 Q1|`00355b1e-744d-553c-bba3-2483d4d57d42`|`source:kau-2024-admission-engineering:q1`|`74e16370-a1be-57f9-b6c7-b2e035bfbb06`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p1,2|공식 지면 p4, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2024|공학계열 Q2|`00355b1e-744d-553c-bba3-2483d4d57d42`|`source:kau-2024-admission-engineering:q2`|`f0ae1ea0-6c50-5b7e-b42b-35f436849c6f`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p8,9|공식 지면 p11, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2024|이학계열 Q1|`51d7f36d-a011-5279-8c5d-f731b2900af3`|`source:kau-2024-admission-science:q1`|`2476c8dc-a8e4-599a-8cf2-1ffdddbb6f06`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p1,2,3|공식 지면 p5,6, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2024|이학계열 Q2|`51d7f36d-a011-5279-8c5d-f731b2900af3`|`source:kau-2024-admission-science:q2`|`ed096a20-52a7-5f27-a71b-4c7c2401cdc9`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p10,11|공식 지면 p13, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2025|공학계열 Q1|`3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af`|`source:kau-2025-admission-engineering:q1`|`ff6226fc-32ac-5903-ab0f-b1560803efbb`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p1,2|공식 지면 p4, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2025|공학계열 Q2|`3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af`|`source:kau-2025-admission-engineering:q2`|`ebd76ca2-dbb4-5c0f-a203-4c77650e8a77`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p10,11|공식 지면 p12,13, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2025|이학계열 Q1|`85a8468d-2141-52b1-9d70-3bcf6f340f8e`|`source:kau-2025-admission-science:q1`|`8744f2ad-02c4-51d4-83de-6d5ab245cec5`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p1,2|공식 지면 p5, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2025|이학계열 Q2|`85a8468d-2141-52b1-9d70-3bcf6f340f8e`|`source:kau-2025-admission-science:q2`|`fccb2d75-d4e6-54ec-b0fe-f3eced268b36`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p9,10|공식 지면 p12,13, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2026|공학계열 Q1|`6815943a-42c1-5eae-b711-449ac403b9fb`|`source:kau-2026-admission-engineering:q1`|`d3909209-b5ee-50ce-b5cb-5cbbb8e0a65a`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p1,2|공식 지면 p5, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2026|공학계열 Q2|`6815943a-42c1-5eae-b711-449ac403b9fb`|`source:kau-2026-admission-engineering:q2`|`6eaec5d3-4786-55a2-8dc6-a457edd5b16b`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p12,13|공식 지면 p15, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2026|이학계열 Q1|`3e312310-9393-5d7d-90d3-731aee13c360`|`source:kau-2026-admission-science:q1`|`8c11754b-d3af-56bf-9b66-d72092468f70`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p1,2|공식 지면 p5, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|
|한국항공대|2026|이학계열 Q2|`3e312310-9393-5d7d-90d3-731aee13c360`|`source:kau-2026-admission-science:q2`|`48512d94-959c-5a94-b985-7e1bd005c6b7`|[원본 파일·SHA 명세](../supabase/candidates/natural_expansion_20261111/kau-source-plan.json) p10,11|공식 지면 p14, 로컬 연결|Mock PASS|로컬 PASS / 운영 없음|공통 Mock PASS|공통 Mock PASS|Registry 기존등록 / 새연결 미반영|비공개|

원문·해설·기준·배점은 보존한다. 배점 수치를 임의 추론하지 않았으며 기존 page-level 계약의 `official_points=null`을 유지한다.
문항별 leaf UUID·원본SHA·문제전용PDF SHA는 [후보 명세](../supabase/candidates/natural_expansion_20261111/connection/manifest.json),
[개별 검수 상태](../supabase/candidates/natural_expansion_20261111/connection/kau-readiness.json)에 있다.

## 서비스 흐름 검증

|구간|확인 결과|한계|
|---|---|---|
|사용자→대학 선택|기존 Catalog에 한국항공대 대학UUID 존재|실기기 클릭 미실행|
|대학→대상6시험|**실제 참조 소스 연결 검사 FAIL**: Source Registry 항공0, 기존 Math 확장목록 항공0|DB browse 등 다른 경로의 존재 자체를 부정하지 않음. 현재 미공개 대상6시험 전체 흐름은 미완료|
|후보 시험→12문항→Registry ID|후보 주입 Mock PASS, 운영 SELECT로12개 기존UUID 확인|운영 Math 등록/공개 아님|
|문제 표시|로컬6문제PDF/25쪽 기존hash 보존, 후보 페이지범위·승인 차단 검사 PASS|실제 WEB/APP PDF 렌더·Storage 제공 NOT TESTED|
|답안 작성|12문항 각각 기존 Flutter Workspace 선택·이미지 입력·공유 제출DTO PASS|공개/평가 권한은 여전히 차단|
|기존 Worker 전달|원문SHA/role/physical page/문항·시험ID 검사120 PASS|기존함수를 복제한 로컬 임시DB. 운영 Worker 자료0|
|제출→결과 저장·조회|공통6+12문항×6=78 PASS, 모의결과/멱등성/타계정차단|실제 Provider0, 품질 판정 없음|
|결과 화면→재작성|기존 History/Coaching/MathExamSession Mock 회귀 PASS|한 앱에서 위 전구간을 연속 실행한 통합 E2E는 NOT TESTED|

이번 재실행: 로컬PG198 PASS, Flutter24 PASS, WEB 후보25 PASS.
대학 선택→실제 Source Registry까지 이어져 있다고 가정한 추가 검사1건은 FAIL이다.
이는 운영 연결이 이미 완료됐다는 가정이 성립하지 않음을 확인한 결과다. 숨기거나 기존25 PASS에 합치지 않는다.
추가 기능/소스 등록은 요청 범위에 따라 하지 않았다. 앞선 ‘기술 연결 PASS’가 서비스 제공 완료로 읽히지 않도록 구분한다.
증거: [현재 조회·검증 결과](../supabase/candidates/natural_expansion_20261111/connection/owner-status-verification.json).

## 2024 공학 Q2 공개 영향

마지막 소문항2-4의 거리·정의역과 공식 풀이 결론 불일치 의심은 **내용 검수/공개 판단 사항**이다.
Registry 매칭이나 기존 Worker 전달의 기술적 실패는 아니다. 공식 원문·해설을 바꾸지 않았다.
현재 Q2 전체가 한 `essay_questions.id`와 한 후보 leaf로 묶여 있어, 기존 승인 단위도 Q2 parent다.
Registry 변경 없이 가능한 우선 선택지는 다음과 같다. 모두 Owner 결정 전 적용하지 않는다.

1. Q2 공개 결정을 보류하고 Q1만 검토. 시험 전체 자동 제외는 하지 않는다.
   다만 현재 whole-exam 확장 계약은 문항2개 모두를 요구하므로 Q1만 공개하려면
   기존 partial-exam 승인 방식 및 서버 공개 scope가 Math 전용 경로에서도 일관되게 작동하는지 별도 확인해야 한다.
2. Owner가 원문 전체 공개를 승인하면 Q2를 기존ID 그대로 제공한다. 불일치 고지를 어디에 둘지는 기존 안내 기능 범위에서 별도 결정한다.
   원문을 유지한 기술 연결만으로 Q2의 내용상 공개 승인이 난 것은 아니다.
3. 마지막 소문항만 채점 대상에서 제외하는 방법은 현재단위에서 단순 스위치가 아니다.
   PDF 일부삭제/기준 부분제거/프롬프트로 무시시키기 등은 하지 않는다. 별도 계약 변경 검토 없이 가능하다고 보고하지 않는다.

현재 선택된 공개 방안은 없다. Q1의 로컬 준비는 유지하며 Q2를 임의 HOLD/공개/정정하지 않았다.
[기존 공식 이슈 목록](../supabase/candidates/natural_expansion_20261111/connection/official-source-issues.json).

## 전체 진행 수치 — 중복 제거

현재 연결 작업 대상은 **22개교·153시험·572문항**이다.
중앙 전체80, 기존15개교 중 실제 연결이 빠진11개교232, 신규 서비스10개교260을 합친 값이다.
한양/고려 완료분 및 자연시험 없는 한국외대는 이번 추가 연결 분모에서 제외한다.
기존 자연계열 누락은 직접FK만 보면233이나, 이미 운영되는 건국 legacy Q1을 제외하여232/88시험이다.
한국항공6/12는 기존 누락11개교/232 안에 포함되어 중복 합산하지 않는다.
빈 placeholder시험과 ID 미해결 연세source1시험3문항은 이 확정 Registry 분모 밖이다.

- DATA READY: 공식 문제·기준·해설을 기존 계약에 연결한 증거가 확인된 수. 단순 DB 등록/ID매칭은 제외. 품질·공개 인증 아님.
- SERVICE READY: 현재 운영 Backend의 기존 Math 연결·release catalog 확인 수. UI 실계정 E2E와 구분.
- PUBLISHED: 실제 사용자 공개 경로의 증거. Registry `is_published`만으로 판단하지 않는다.
- HOLD는 명시적 기존 보류 정책만 집계. 한국항공 공식 이슈5개를 임의 HOLD에 더하지 않는다.
- 미완료는 운영 Backend 연결 미완료 수이며 HOLD와 로컬 DATA READY를 포함한다. 열들은 상호 배타적이지 않다.

|구분|대학|시험|문항|DATA READY 확인|SERVICE READY 운영Backend|PUBLISHED|HOLD|운영연결 미완료|
|---|---:|---:|---:|---:|---:|---|---:|---:|
|중앙 자연 전체|1|20|80|69|69|69 기존11/7 증거; 현재 사용자경로 재검증 안 함|11|11|
|기존 자연계열 누락(항공 포함)|11|88|232|12 확인 / 나머지220 미판정|0|0 이번 신규공개|0 별도 확인분|232|
|신규 서비스10개교|10|45|260|0 확인 /260 미판정|0|0 이번 신규공개|58|260|
|합계|22|153|572|81 확인|69|기존69 증거 / 신규0 / 현재 전체 NOT TESTED|69|503|

신규10개교 HOLD58은 연세47+홍익7+서울시립4의 기존 servicePreparing 정책 적용 문항이다.
신규10개교의28시험94문항은 공통 Registry 매칭만 PASS이며 DATA READY94가 아니다.
중앙의 운영 `is_active/is_published` 조합은0이지만 custom Math release catalog69가 존재한다.
따라서 boolean만 보고 ‘중앙 미공개0’ 또는 Backend 수만 보고 ‘현재 사용자 공개69’로 단정하지 않았다.
현재 인증된 공개 상태 API는 실제 사용자 세션이 필요하며 이번에는 실행하지 않았다.

기존 누락별 시험/문항: 동국7/21, 인하1/3, 항공10/20, 건국6/24, 광운21/42,
경희4/23, 서강9/11, 숙명16/44, 숭실5/20, 성균관5/15, 서울여자4/9.
신규10개교: 가천17/166, 경북1/3, 부산2/6, 이화1/3, 세종3/9, 아주6/12,
연세12/47, 홍익1/7, 시립1/4, 가톨릭1/3. 이미 등록된 ID를 재사용한다.

## 결론과 남은 승인 경계

한국항공12문항은 **로컬 DATA READY·계약검증 완료 / 운영 SERVICE READY0 / PUBLISHED0**다.
기존 Worker/결과/재작성 모듈을 재사용할 수 있다는 근거는 있지만 전체 사용자 흐름 완료 근거는 없다.
실제 적용에는 승인된 문항 범위의 DB 자료 연결, 기존 서버 scope, 학생PDF Storage/권한,
WEB/APP 공유 metadata 연결과 실제 사용자 기술검증이 남는다. 이번 작업은 조회·Mock 검사·문서 기록만 수행했다.
Provider 품질 평가는 Owner/사용자 담당이며 이번 완료 조건에 넣지 않는다.
중앙 과학11 HOLD, 공식 원문 보존, 운영 DB/RPC·배포 금지를 유지한다.
