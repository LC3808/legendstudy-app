# 평가 품질 관리 V1 — 2026-11-25

**PARTIAL — WEB 운영 반영, 전수 교육적 품질 판단·Q15 지속 저장은 미완료.** 기존 `/ql/`·검수 RPC·불변 이력을 재사용한다. 학생 결과·점수·상태·원장·Provider 실행 변경은 범위 밖이다.

## 보존 설계 검토

1. 품질 판단은 학생 첨삭 발생과 다른 검수 사건이다. 요청·완료·검수·정정 시각을 분리한다.
2. 답안·결과는 기존 run/question과 snapshot hash로 연결한다. 보고서에 원문을 복제하지 않는다.
3. 기존 `ql_exam_submit`의 추가·정정 이력을 유지한다. 과거 검수 UPDATE 금지.
4. 학생의 기존 account/run identity를 유지하며 계정 이름으로 학생/테스트를 확정하지 않는다.
5. 학생 Learning 결과와 운영자의 품질 Decision을 분리한다. 검수는 성적이나 합격 Outcome이 아니다.
6. quality_operators 및 기존 관리자 권한 경계를 유지한다. 보고서 본문도 서버 인증 후 전달하고 캐시하지 않는다. 원문은 Git·공개 정적 파일에 저장하지 않는다.
7. Q01–Q15 기술 검토는 Owner 최종 교육 판단과 별개다. 모르는 수치는 집계 불가, 미검증을 적합으로 변환하지 않는다.

## 운영 확인

11/25 22:44 KST: 회차70(완료58/실패10/reserved2), 답안118문항. 구형 essay_evaluations 0, 사람 검수0, 검증된 테스트 등록0. 완료58의 결과 문항 수 불일치0. 일반 탭은 구형 테이블 전용이므로 0이 정상이며 실제 회차 목록과 별개다.

계정 관리자 소속17건도 테스트로 확정하지 않는다. 나머지53건 역시 실제 학생 확정으로 간주하지 않는다. 이전 검토의 23건은 비관리자·심사계정 제외 후보 표본이며 전체 실제 학생 확정 모집단이 아니다. 분류 불확정 요청도 누락 없이 검수 목록에 포함한다.

## 기존 계약 재사용

운영 `ql_exam_cases/detail/submit` 존재 확인. HQP 문서의 단일 evaluation 설명만으로 신규 저장소 필요를 판단하지 않는다. 회차 검수는 `human_quality_judgments.exam_run_id/exam_question_id`, 기존 9항목 rubric을 사용한다. Q01–Q15와 기존 rubric은 서로 다르며 임의 일대일 변환하지 않는다. 기존 검수자 권한을 관리자 전체로 확대하지 않는다.

## 근거

[실제 결과·UX 검토](essay-lab-student-experience-review-20261125.md), [HQP 저장 계약](human-quality-persistence-implementation.md), [정확 인용·재시도](essay-retry-quality-20261122.md), [부분 재생성 비활성](essay-quality-followup-20261122.md).

## 실제 구현·배포·검증

WEB source `ecac36e5b31dbf980ee0eebbb433626bb33c477e`, Pages `6e4b8189-5a6c-4f28-8d16-e15bf4508500` success/production. 기존 API source81개 bytes 동일, 보고서 GET/data2개 추가. 비대상 정적3167경로 해시·Pages 설정 불변. 신규 무료2 안내를 포함한 비대상 변경은 배포하지 않았다. Worker·DB 변경0.

전체 자동2276 PASS/5 SKIP, 290 test files PASS/4 skipped. 변경 파일 lint·TypeScript·Next webpack·Functions build PASS. 별도 boundary 스크립트는 기존2실패 유지: payment-checkout의 TEST 안내 문자열, admin-members-view의 URL.searchParams.delete를 DB delete로 탐지. 두 파일과 검사기는 기준712ff3a와 동일하며 신규 실패로 해석하지 않는다. 전체 검사가 모두 PASS라고 보고하지 않는다.

Chrome 합성 긴답안·2문항390/768/1440px: 전체 가로 넘침0, 모바일/태블릿1열·PC2열(504.5px씩), 문항 전환·본문 열람 PASS. 임시 preview와 API 제거·next.config 원복. 운영 Owner 세션에서118문항/70요청, 보고서15기준·21개 상세 링크, 실제 성균관 문항/답안·학생 WEB 미리보기 진입, 저장 버튼 미확인 상태 비활성 확인. 실제 검수 저장0. 익명 직접 보고서 API401, 보고서 정적 HTML 노출0. 일반사용자 차단은 격리false/null/오류 테스트와 기존DB권한 정의 확인; 실제 일반사용자 JWT E2E는 NOT TESTED.

운영 전후 MD5: runs `8ced976d750a233c1a39553d9e5ae302`, Credit Ledger `c656ae230918b0fc937f43789cc5bb8f`, payment_orders `0078ed26b2c37c96a952d6ccc09908ed` 동일. 검수0→0, 대상q1 reserved 유지. 운영 첨삭·Provider·결제·환불 실행0.

보고서 canonical JSON은 [검증 snapshot](evidence/quality-console-report-20261125.json), WEB `functions/_data/quality-report.json`과 SHA256 `a94a0942b5508b3640b556209d59198efebd2e72b7b8edfdbf34238a98410548` 일치. `scripts/sync-quality-report.mjs <canonical JSON> check|sync`로 일치검증. Wiki narrative는 조사 방법·상세 근거이며 콘솔 게시 내용은 이 snapshot을 단일 원본으로 사용한다.

## 요청한 30항목 보고

|항목|상태·결과|
|---|---|
|1 검토 대상|DONE 목록70요청·118문항, 완료58/실패10/미완료2. 학생/테스트 확정은 PARTIAL|
|2 검토 완료 요청|PARTIAL 내용검토 후보20요청. 최종 교육적 승인0, 전체70완료 아님|
|3 검토 문항|DONE 구조103완료문항·199기준, PARTIAL 내용38문항·50기준|
|4 대학 기준|PARTIAL 후보50/50 문구 연결. 당시PDF전체·배점 적용 미검증|
|5 첨삭 내용|PARTIAL 후보20개 상세 기록, 나머지 내용 전수 미검증|
|6 점수|PARTIAL 내부1~5와 대학배점 구분, Owner 경계 검수 필요|
|7 강점·보완|PARTIAL 구체적 본문·action 확인, 전 모집단 적합판정 아님|
|8 소제목|DONE GAP 확인: strengths문자열→일반제목 반복. 학생UI수정0|
|9 인용|PARTIAL 답안20/20 exact offset 일치, 제시문 전체 의미 미검증|
|10 가이드|PARTIAL WEB 기존 개선 유지·APP 계층 차이 확인|
|11 무료재첨삭|PARTIAL 완료후보5건 included_revision/0Credit/ledger0. 실사용 제출QA 미실행|
|12 WEB UX|PARTIAL 코드·진입·관리자 미리보기, 실학생 전흐름 미검증|
|13 APP UX|PARTIAL 기존Native코드 대조, 실제 학생 양OS NOT TESTED|
|14 설계 차이|DONE 일반소제목·APP가이드·공식점수 설명 GAP 기록|
|15 V0 빈 목록|DONE legacy evaluation0 vs 회차70, 오류/전체결과0 아님|
|16 재사용|DONE ql_exam_*·HQP9·불변 이력·관리자Frame·학생렌더러|
|17 V1|PARTIAL 4탭·현황·검색·비교·보고서·개선 이력 운영. Q15지속저장/Owner판정집계 미구현|
|18 실제 연결|DONE 전체70/118 운영표시, 미완료 포함·원문은 상세만 조회|
|19 개별 검수|PARTIAL 기준·답안·결과·문항전환·부모비교. 공식문제/제시문 전체 한화면 연결 미완료|
|20 보고서|DONE 운영본문·15기준·후보20연결. Claude 이번 V1 신규보고서 미확보|
|21 Owner 검수|PARTIAL 기존9항목 저장/정정 재사용·테스트PASS. Q15저장 및 Owner특정역할·집계는 별도설계 필요|
|22 주요 문제|DONE QC01~04: 소제목·APP가이드·점수설명·q1미완료|
|23 해결책|DONE 하위호환제목·Native표현·Owner표본검수·승인복구, 원문보존|
|24 우선순위|P0 q1별도승인/상태조회, P1 Owner교육검수·APP가이드·제목계약, P2 분량설명|
|25 테스트|DONE 자동2276PASS5SKIP·build·브라우저. 기존boundary2실패/일반JWT·실학생양OS NT|
|26 DB|DONE 운영변경0. 현재 UI는 기존RPC 재사용. Q15 지속저장 확장은 승인 전 미적용|
|27 배포|DONE WEB6e4b8189; Worker미변경·비대상3167경로 보존|
|28 승인|학생재실행·엔진/제목계약·Q15DB/Owner역할 변경은 별도승인. 이번 실제 학생쓰기0|
|29 Git|WEB ecac36e5 구현배포, 후속문서커밋은 Git HEAD 참조|
|30 Wiki|본 문서·기존학생경험검토·canonical JSON·index/current/log 연결|

## 다음 단계와 구체적 한계

이번 결과를 PHASE1~3 전체 DONE으로 간주하지 않는다. 학생/테스트 분류 근거가 없어 제외할 수 없는 나머지38완료요청(65문항)의 내용/공식 기준 검수, Q01–Q15 개별 지속 저장과 최종 Owner 식별 계약, 공식 원문 비교, Claude의 이번 V1 UI 검토가 남았다. 현재 검증 보고서는 실재하는 내용을 게시했으며 제목·로컬파일 링크만 배포하지 않았다.

Q15 저장 권장 최소 확장: 기존 human_quality_judgments와 snapshot hash·멱등키·supersedes 유지, review_evidence의 버전형 Q15 결과/근거를 추가하는 RPC 검증 확장과 판정별 읽기 projection을 검토한다. 기존9항목을 Q15로 오역하지 않는다. Owner 특정역할은 서버 지정 정책 확정 전 클라이언트 문자열로 인증하지 않는다. 아직 실행 가능한 Migration 패키지로 검증한 것이 아니므로 설치 승인을 요청하지 않는다. 후속 승인 검토 전에 exact SQL/격리테스트/원복을 완성해야 한다.

운영 브라우저: 실제 모바일433px/scrollWidth433px·PC1825px/scrollWidth1825px, Q기준15개 표시. 로컬390/768/1440 검증과 구분. 임시 viewport 해제. 제공된 Claude d9c856b는 11/22 대시보드 설계이며 V1 신규 검토로 간주하지 않는다.
