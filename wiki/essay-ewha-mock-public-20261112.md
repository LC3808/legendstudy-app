# 이화 모의 24문항 운영 연결·공개 · 2026-11-12

[이화 종료·잔여43](essay-ewha-closure-20261112.md): 이화29시험87(63+24,중복0) DONE/CLOSED. 기존3 ID·실제Math공개 확인. 전체265공개43잔여; Owner AI통합검수 별도. 종료 운영쓰기/Provider0.


**PUBLISHED / 8시험24문항(Math12·Essay12).** 평가 요소·package24, 운영 신규218행. DB 2026-11-12T20:10:22.142356+09:00, 공개 검증 2026-11-12T20:13:41.119994+09:00. 모의 미완료0. 전체265공개/43잔여(308분모). 성균관15 HOLD 등 범위 밖 문항 변경0.

## 평가 요소와 기존 계약

공식 원문·Registry를 유지하고 문항별 출제의도/평가 설명을 기존 geometry 추출기로 연결했다. 서비스 평가 요소는 평가목표·요구내용·근거·논리/풀이·예시 사용·기존 결과/재작성의6측면으로 구성했다. 문항별 공식 맥락이 각 package에 포함된다. 예시와 다른 타당한 표현/풀이를 자동 오답으로 간주하지 않으며 서비스 구성을 대학 공식 채점 규칙으로 표시하지 않는다. 공식 수치 배점은 NULL, 임의 배점0. Math의 공식 풀이/이미지와 Essay의 공식 의도 이미지·문제/제시문을 기존 Worker 계약으로 재사용한다. AI 품질 판정은 수행하지 않았다.

`prepare_ewha_mock_candidates.py` → 기존 Math v1/Essay1.3 → `prepare_ewha_mock_math_public.py`/`prepare_ewha_mock_essay_public.py`. 새 엔진0. Worker는 Registry 파일1개만 추가, 기존72모듈·prompt·SDK·13바인딩 보존. Source Registry의 기존2024자연Ⅰ은 중복생성 없이 null DB ID만 확인된 기존 UUID로 연결했다. 운영 기존3문항 불변, 신규7시험21문항.

## 운영 및 검증

- Migration `20261112110747_ewha_mock_24_service_connections_public.sql`; 신규218행 = Registry28 + Math/자료174 + Essay16. 내부 허용목록3함수 확장, 새RPC0. 문제8SHA exact SELECT 정책1. 공식 해설 학생공개0.
- 단일REPEATABLE READ TX: Registry12/28,Math26/56,Essay9/7 사전/사후138검사. 기존359함수본문·362함수ACL·273RLS·127테이블권한·13개private이력·Credit681행보존. 기존 공개241 유지.
- Math 격리 제출/결과/재첨삭132검사·원복후기존결과조회/신규진입차단 PASS. Essay12문항·24모의결과/재작성cycle·80이미지·4변조거부 PASS. 운영 실제4package/12문항 digest·Worker 매핑·4preflight PASS.
- 운영 정상계정PDF8,익명/미확인/UID없음0,탈퇴대기3계정0. 삭제중 계정은 격리검증PASS, 운영 대상없음. Provider/운영테스트답안0.
- WEB 관련27테스트PASS·타입/Next webpack/Functions PASS. 전체 최초1966PASS/12FAIL/5SKIP 중 신규 목록수치2건 수정·해당테스트재검증PASS. 잔여10실패+비동기오류1은 기존aaeb700 보관본에서도 동일재현(관리자/Credit),신규잔여FAIL0.
- APP 기존5PASS/1SKIP(기존원본경로 미지정),신규24문항 매핑/잘못된 manifest거부/실제8PDF 바이트3PASS.
- 실제 공개 API8시험24질문·입력방식/순서·source identity PASS. 기존181시험 보존(그중1시험DB ID 연결만추가),새7시험으로188시험530문항. 비논술2206정적자산·API소스·라우팅·Secret·Preview보존.
- 브라우저/실기기/실제로그인후제출·결과·재첨삭/AI품질은 **NOT TESTED**. 격리 기술계약PASS를 실제AI검수PASS로 바꾸지 않는다.

## 배포·원복

WEB source `b5a5ac527052d342faca11fc1b4bc5d4fd200d92`, Pages `2b6e0c2d-9ded-4033-af87-3abf543ae330`. Worker `c3795154-697d-4448-a044-c0dbfcc05150`. 원복은 먼저 신규8시험·12Math leaf WEB 허용범위를 닫고, 현재 버전/배포 드리프트 확인 후 기존 Pages/Worker 버전을 복원한다. 기존Math/Essay의 신규 허용목록만 회수하는 SQL 및 신규PDF 정책 회수 SQL을 사용한다. Registry·자료·답안·결과·이력·PDF 객체삭제금지. 격리원복PASS/운영원복실행0. 다른 배포가 개입하면 전체 이전설정을 덮어쓰지 않는다.

[최종 영수증](../supabase/candidates/ewha_mock_public_20261112/final-status.json) · [SQL 범위/해시](../supabase/candidates/ewha_mock_public_20261112/production-sql-plan.json) · [운영 적용·보존](../supabase/candidates/ewha_mock_public_20261112/production-application-receipt.json) · [공개 사후](../supabase/candidates/ewha_mock_public_20261112/web-production-receipt.json) · [Owner265목록](../supabase/candidates/ewha_mock_public_20261112/owner-integrated-review.json) · [잔여43](../supabase/candidates/ewha_mock_public_20261112/remaining-43.json).

Owner 검수: https://lab.legendstudy.com/essay-lab/universities/ewha/ → 2024/2027 모의 인문Ⅰ·Ⅱ/자연Ⅰ·Ⅱ → 문제1~3 → 답안·첨삭 → 기존이력/결과 → 재작성·재첨삭. 기존 Credit 정책 적용. 최종 Git HEAD는 완료 보고와 git log 참조.
