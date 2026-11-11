# 논술 자연계열 네 대학 연결 후보 — 2026-11-11

최신 Owner 기준: [한 대학씩 TECH READY·통합 Owner 검수](essay-natural-sequential-order-20261112.md). 아래 로컬 상태/일괄53 후보는 당시 증거이며 현재 완료·일괄 실행 승인을 뜻하지 않는다.

최신: [운영 사전 검증 및53문항 승인안](essay-four-university-production-preflight-20261112.md). 아래58문항 전체 SQL은 이번 적용 범위가 아니다.

**로컬 연결 후보 검증 DONE / 전체 운영 제공 PARTIAL. 운영 쓰기·배포·신규 공개·Provider 호출 0.**

최신 Owner 지시에 따라 항공→건국→경희→성균관 순으로 기존 Registry와 공식 자료를 연결했다.
[이전 연결 상태 감사](essay-connection-owner-verification-20261111.md)의 한국항공 Source Registry 진입 FAIL은 이번 **로컬 후보에서 해소**했다. 운영 반영 완료를 의미하지 않는다.
기준 APP commit `bfe7d4b81a9e3082cab11bc2ed73cc67cabe7cc7`, 작업 브랜치 `codex/essay-natural-expansion-20261111`.
참조 WEB `codex/task20-chungang-connection-20261107`, commit `745fbf325719288d9227cbfd13ccb493fc762ff4`의 실제 모듈을 검사했다. WEB tracked source·릴리스 브랜치 변경 없음.
최종 작업 commit은 `git log -1`로 확인한다. 현재 HEAD를 고정 정의하지 않는다.

## 범위와 상태

이번 분모는 **4개교·23시험·81문항**이다. 기존의 22개교/153시험/572문항 전체 확장 분모와 섞지 않는다.
기존 운영 연결7(건국4, 경희3)을 재생성하지 않았으며, 미연결74 중58을 후보로 연결했다.
나머지16은 경희 과학12 및 채점 기준 미확인4다. 빈 placeholder 시험, 이번 지시의 항공6시험 밖 시험은 제외했다.

|대학|기존 대상 시험/문항|기존 운영 연결 보존|연결 후보 시험/문항|DATA READY 누적¹|주 상태 LOCAL SERVICE READY|HOLD²|DATA READY만³|NOT READY|신규 PUBLISHED|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|한국항공|6/12|0|6/12|12|7|5|0|0|0|
|건국|7/28|4|6/24|28|24|0|0|0|0|
|경희|5/26|3|3/7|10|3|0|4|16|0|
|성균관|5/15|0|5/15|15|15|0|0|0|0|
|합계|23/81|7|20/58|65|49|5|4|16|0|

¹ DATA READY는 공식 근거가 연결된 누적 수(기존7 포함)이며 내용·공개 승인 수가 아니다. 다른 열과 중복된다.
주 상태는 운영 보존7 + 로컬 SERVICE READY49 + HOLD5 + DATA READY4 + NOT READY16 =81로 중복 없이 구분했다.
² HOLD5는 Owner가 명시한 2024 공학Q2 1개와 기존 공식 불일치4개의 자료 검수 보류 분류다. 시험 전체 공개 여부를 새로 결정한 것이 아니다.
³ 경희 의약 수학4는 leaf 단위 Worker/입력/결과/재작성 계약 PASS지만, 과학이 포함된 전체 시험 진입은 미완료이므로 SERVICE READY로 승격하지 않았다.

58개 후보의 leaf 기술계약은 모두 PASS다. 운영 SERVICE READY 신규0이며 기존 ACTIVE7은 읽기 재조회했다.
기존7의 현재 실계정 공개 API/기기 E2E는 NOT TESTED다. 과거 공개 증거와 현재 활성 leaf를 현재 사용자 공개 완료로 바꿔 보고하지 않는다.

[81문항 검수 표](essay-four-university-question-review-20261111.md) · [문항별 필수20항목 JSON](../supabase/candidates/natural_expansion_20261111/four-university/question-review.json) · [검증 집계](../supabase/candidates/natural_expansion_20261111/four-university/technical-results.json).
학년도와 실제 시행일은 구분한다. Registry ID와 문항 UUID는 동일한 기존 `essay_questions.id`다.

## 연결 내용

- 한국항공: 기존12 Registry UUID와 원문 보존 v1 패키지172행을 재사용. Source Registry6시험 추가 후보로 대학→시험→문항 진입 누락 보완. Math 확장6시험, 기존 Worker 공식자료12, 기존 입력/결과/재작성 계약 검증.
- 건국: 기존2026 수시4문항 보존. Q1은 `essay_question_id=NULL`인 legacy leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3`이므로 새로 생성하지 않았다. 2024 수시A/B, 2024/2025/2026 모의, 2025 수시24문항만 추가 후보.
- 경희: 기존2026 자연3 보존. 2027 모의 자연3, 2026 수시 의약 수학2, 2027 모의 의약 수학2 연결. 의약 시험8문항의 Registry 구조를 그대로 유지하고 수학만 있는 별도 시험 ID를 만들지 않았다. 미완성 의약2시험은 확장 목록에서 제외.
- 성균관: 2023 모의3, 2026 수리형1/2/3 각3, 2027 모의3. DB slug `sungkyunkwan`과 WEB Catalog의 `skku` 별칭을 실제 대학 UUID로 연결했다. 초기 진입 검사에서 드러난 별칭 불일치를 수정한 뒤 PASS.

기존 math-v1 테이블8개에 **DRAFT760행**, 기존 `math_private.task20_hanyang_source_pages`에58행을 추가하는 후보다. 신규 테이블/컬럼/함수/평가 엔진 없음.
문항당 기존 parent UUID→leaf1 구조를 유지한다. 소문항 분할, 점수 재계산, 기준 생성, 공식 해설 정정은 하지 않았다.
배점 원문은 공식 이미지/추출문에 보존했다. page-level 기준의 `official_points=NULL`은 추정 수치를 입력하지 않았다는 뜻이며 배점이0이라는 뜻이 아니다.
다중 PDF의 같은 physical page 번호는 `(source SHA, page)`로 구분한다. 공유 페이지는 대상 문항 라벨을 명시하고 원문 전체를 보존한다.
문제의 제시문이 앞 페이지에서 시작되는 건국2024 A Q3/Q4·B Q3, 건국2026 모의Q2, 경희2027 자연Q2·의약Q2도 포함했다.
성균관2023/2027의 소문항별 채점 기준이 이어지는 여러 페이지를 누락하지 않았다.

## PDF 재사용 — 기존 승인을 덮어쓰지 않음

최종 WEB 실제 메타데이터 대조에서 **58문항/20개 기존 학생용 PDF 자산**을 확인했다.
43문항은 기존 `VERIFIED/APPROVED/APPROVED`, 성균관15문항은 `VISUAL_REVIEWED/PENDING/PENDING`이다.
공식 원본 또는 기존 storage-readback 파일로20개 자산의 SHA/쪽수와58개 문항 시작 페이지 범위를 재확인했다.
메타데이터의 승인 표시는 현재 Storage/서비스 상태를 재확인한 결과와 다르며 **현재 원격 조회는 NOT TESTED**다.

기존 asset ID·시작 페이지·승인 상태를 그대로 재사용하는 `web-pdf-existing-reuse.json`이 최종 연결 기준이다.
앞서 생성한14개55쪽 PDF와 기존 항공6개25쪽 파생PDF는 로컬 대조 자료로만 남긴다. 새14개55쪽은 원본 raster와 픽셀 일치 및 숨김 텍스트/주석 부재를 검사했고 crop 경계를 육안 확인했다.
**기존 승인 PDF를 새 후보로 교체하거나 승인 플래그를 회수/승격하지 않는다. Storage 업로드0.**
[기존 자산 검증 명세](../supabase/candidates/natural_expansion_20261111/four-university/existing-pdf-reuse-verification.json).

## 공개 정책과 HOLD

한국항공2024 공학Q2 마지막 소문항의 공식 자료 불일치와 기존 이슈4를 그대로 보존했다.
[공식 이슈 원본](../supabase/candidates/natural_expansion_20261111/connection/official-source-issues.json).

실제 `beta-expansion.ts`는 선언된 `mathQuestions` 매칭을 검사하며 DB의 전체 문항 수를 자동 검증하지 않는다.
따라서 배열에서 Q2를 빼는 것만으로 안전한 부분 공개가 구현됐다고 판단할 수 없다.
기존 `public-service-status.ts`에는 별도 partial evidence 경로가 있지만 새 Math expansion 항목은 `partial:false`로 분류된다.
기존 Registry를 변경하지 않고 Q1만 준비할 수는 있으나, **Q1만 공개하는 Math→공개 상태→입력 경로의 일관성은 아직 검증되지 않았다.**
이번에는 Q2를 자동 제외하거나 Q1만 공개하지 않았다. Owner가 Q2만 보류하는 정책을 결정하면 기존 partial 경로를 별도 확인한다.
그 확인 전2024 공학 시험 전체 공개 보류가 안전한 검토안이며, 최종 선택은 Owner 담당이다. 다른 시험도 임의로 전체 HOLD하지 않는다.

경희 의약2시험은 과학12문항의 기존 엔진·과목 라우팅 검증이 없어 확장 목록에 넣지 않았다.
2022 모의 자연4는 예시답안7쪽과 출제취지까지 확인했지만 공식 채점 기준을 확인하지 못했다. 풀이를 채점 기준으로 임의 변환하지 않았다.
중앙 자연 ACTIVE69는 이번 읽기 조회에서도 자연4+자연계열65로 확인했다(경영경제10은 별도). 과학11 HOLD 및 기존 상태 유지, 중앙 관련 SQL0.

## 기술 검증

|검사|결과|범위/한계|
|---|---|---|
|Python 정합성·중복·해시·역할 음성검사|22 PASS|네트워크/Provider 없음|
|격리 PG17 기존 Worker|58문항×10=580 PASS|운영에서 읽은 동일 함수 MD5 검증, 공식 image/role/page/UUID 매칭|
|격리 PG17 입력·평가·결과·재작성|58문항×10=580 PASS|Mock 결과, 제출/평가/재작성 멱등성, lineage·재첨삭 결과 연결|
|대학별 공통 적용/롤백 검사|9×4=36 PASS|정확한 적용 SQL, 내용 drift/중복 거부, ACL, RETIRED 재실행/기존 답안·결과·원장 보존|
|WEB 후보 연결|81 PASS /3 SKIP|3개 SKIP은 해당 후보에 없는 과거10개교 회귀 fixture; 실패 아님|
|WEB 기존 결과/재작성|5 PASS|기존 모듈 Mock 회귀|
|Flutter 입력·결과·이력·재작성|77 PASS /4 SKIP|58문항 입력 선택 포함. SKIP은 기존 비공개 결과 fixture 부재|
|Flutter Analyze|PASS|No issues found|
|현재 운영 전체 사용자 흐름 / WEB·APP 실계정·실기기|NOT TESTED|신규 후보 운영 미반영; Provider/품질평가 안 함|

총 격리 DB 계약1196개 PASS. 검사 수는 assertion 전부를 세는 것이 아니라 보고서에 명명된 계약 항목 수다.
격리 과정에서 후보 SQL 보존 비교의 집합 연산 우선순위 오류1건과 성균관 Source slug 오류1건을 발견해 수정했다. 최종 관련 검사 실패0.
기존 Worker 함수 MD5 `54acd2a1914f360e6ecd62e39acc8222` 재조회 일치. 운영 private source의 anon/authenticated SELECT=false 유지.
원격 DB는 SELECT만 사용했다. 운영 사용자 기록에 대한 쓰기/삭제0이며, 원격 전체 사용자 데이터 해시를 전후 비교했다고 주장하지 않는다.

## 적용 후보와 복구

[정확한 파일·생성/검증 절차](../supabase/candidates/natural_expansion_20261111/four-university/README.md).
Owner 승인 이후에도 DRAFT 등록과 사용자 공개는 서로 다른 단계다.

1. 대상 문항, 공식 이슈, 성균관 PDF 승인, 경희 partial 범위를 먼저 확정한다.
2. 대학별 `preflight.sql`로 최신 기존 객체/Registry/leaf/Worker/권한 확인. 다른 작업의 연결이 있으면 중단·대조한다.
3. 승인된 비공개 `apply-draft.private.sql`만 한 transaction으로 실행하는 검토안. 기존 함수/정책/답안/결과/원장은 변경하지 않는다. 원본 register/worker SQL을 별도로 중복 실행하지 않는다.
4. `verify.sql`의760 DRAFT+58 private source 예상행, 원문 해시, 기존 helper/ACL, 기존 기록 보존 확인. 이는 활성화/출시가 아니다.
5. 기존 release catalog/실행 허용 범위, Source Registry·Math 목록, 학생 PDF 승인과 실제 계정 접근의 **별도 통합·검증 승인**이 필요하다. 현재 후보는 이 운영 scope나 RPC를 변경하지 않는다. 파일 존재만으로 운영 가능 상태를 선언하지 않는다.
6. 장애 시 우선 신규 승인 범위만 닫고 `rollback-retire.sql`로 후보 자체의 versioned4테이블을 RETIRED 처리한다. Registry·원문·Worker 이미지·답안·결과·원장 DELETE 없음. 이미 생긴 사용자 결과는 읽기 보존한다. 공용 RPC 권한을 회수하여 기존 대학을 중단시키는 방식은 쓰지 않는다.

WEB Source patch에는 기존값/후보값을 함께 기록했다. 적용 때 현재값이 기존값과 다르면 자동 덮어쓰지 않는다. 역변환도 후보값 일치 확인 후 해당20시험만 되돌린다.
Math 확장18개 완성 시험 후보와 수학 leaf-only2시험을 분리했다. 기존 승인 PDF58문항과 input mode는 그대로 재사용한다.

## 보존 검토7항과 인계

[기존7항 검토](essay-natural-expansion-20261111.md#보존-검토7항), [상위 원칙](longitudinal-learning-admissions-data-strategy.md)을 계승한다.
1. 학년도/원본 파일/로컬 작업일을 분리하고 시행일을 추정하지 않는다.
2. 원본 SHA·physical page·공식 이미지와 원문을 재현 가능하게 남긴다.
3. 기존 version/학생 history를 UPDATE로 덮지 않는다. 추가 DRAFT와 RETIRED 복구만 후보화한다.
4. 기존 auth identity·계정 정책 유지. 격리 검사만 synthetic 계정 사용.
5. 공식 근거와 Learning 결과를 Admissions Decision/Outcome 사실로 혼용하지 않는다.
6. 비공개 공식 근거/학생 데이터 접근권한 유지. 원문·이미지·SQL본문은 ignored `.local`, Git에는 메타데이터/해시만 저장.
7. Mock 결과와 모델 품질 판단을 공식 사실로 보고하지 않는다. 실제 첨삭 품질은 Owner/사용자 검수 담당.

새 엔진·prompt·Provider·Credit·결제·결과UX 변경0, APP75 자동채점/학습 코드 변경0.
실기기 설치·스토어 제출·릴리스 병합·운영 WEB 배포0.
Owner는 [문항별 목록](essay-four-university-question-review-20261111.md)에서 주 상태와 공식 근거를 확인한 뒤, 별도 운영 반영/공개 범위를 승인할 수 있다. 지금 운영 LAB에 새 문항이 보인다고 보고하지 않는다.
