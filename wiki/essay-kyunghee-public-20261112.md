# 경희대 자연·수리 공개 연결 · 2026-11-12

상태: **PUBLISHED — 신규3시험7문항92행 운영 연결·공개 완료. 기존2026자연3문항 보존.**

## Owner 결정·보존 기준

[건국 공개 전환 결정](essay-konkuk-public-20261112.md), [기존 네 대학 연결](essay-four-university-connection-20261111.md), [장기 데이터 보존 기준](longitudinal-learning-admissions-data-strategy.md)을 재사용한다. 검증된 문항의 운영 연결/공개는 승인 범위이며 실제 AI 품질은 전체 대학 후 Owner 통합 검수다. Owner 로그인/품질 검수를 대학별 진행 조건으로 요청하지 않는다. 공통7보존 질문의 답은 건국 문서와 동일하다: 공식 버전/Registry 유지, 새자료만 추가, 개인 이력 무수정, 기존 계정/학습 provenance 및 권한 유지, mock은 격리에만 존재한다.

## 공개 대상·제외

- 2027모의 자연3: 기존 공식 근거/PDF/기준/Worker 연결.
- 2026수시 의약 수학2 +2027모의 의약 수학2: 기존 부분 공개 `catalogQuestionIds` 계약으로 Registry8문항을 그대로 유지하면서 수학2문항만 admission 허용. 과학12문항은 NOT READY이며 평가 허용에 포함하지 않는다. 별도 시험/문항 ID를 생성하지 않는다.
- 2022모의 자연4: 공식 채점 기준 미확인 NOT READY. 예시답안을 임의 평가기준으로 변환하지 않는다.
- 기존 운영 경희3/건국28, 한국항공 DRAFT7/HOLD5, 중앙과학HOLD11은 불변.

## 검증·적용 범위

사전 운영 SELECT116 PASS, 기존20그룹 snapshot 준비. 격리 PG17은 기존 건국24 공개를 먼저 복원한 후 경희92행/ACTIVE28/기존2함수 허용목록7추가/21검사/7문항 제출·mock결과·재작성·재첨삭·원복을 검증했다. 별도 내부 resolve_profile 실행권한 없는 verifier SELECT PASS. Provider0.

기존 승인 PDF3개 일반계정 read PASS, 실제 SHA/8·3·3쪽 및 참조 검증. Storage 업로드/정책변경 없음. WEB396 PASS/1SKIP, TypeScript/lint/Next build/Functions compile PASS. APP와 WEB은 같은7UUID를 사용한다. 실제 새 AI 제출/실기기 검사는 하지 않는다.

실제 적용: 신규92행 → 정확한28버전행 ACTIVE → 기존 evaluation_admission/release_catalog의239leaf 보존+7 → Pages public268→271 / expansion98→101 / Math239→246. 비논술정적2166자산/Functions경로/기존설정/Secret/Preview 보존. 기존 엔진과 결제 규칙 불변, 신규RPC0.

## 원복

[허용목록 원복](../supabase/candidates/kyunghee_public_20261112/rollback-admission.sql)은 적용 후 함수 hash가 일치할 때만 실행한다. 먼저 WEB 신규3시험/7leaf scope를 회수하고 직전 배포를 복원한다. 신규자료·진행중작업·답안·결과·Credit 기록은 삭제하지 않는다. 후속배포가 있으면 전체 정의/설정을 덮어쓰지 않는다.

## 적용 결과

[운영 영수증](../supabase/candidates/kyunghee_public_20261112/production-receipt.json) · [7문항 격리 계약/원복](../supabase/candidates/kyunghee_public_20261112/isolated-results.json).

- 2026-11-12 02:48 KST: 운영92행 적재/28상태 활성화 완료. Migration `20261111174807_kyunghee_7_math_public_release`. 사전116/적재사후122/활성화21 PASS, 기존20snapshot 모두 동일. 기존 함수2개 허용목록만7추가, 새RPC/권한/정책 변경0.
- 02:49 KST: Pages `532977a6-fbac-4975-a96b-2b3e7f6513fa`, source `2f585c0d003fc5d7eaac9d723acfff4586ce794a`. 홈/논술/경희/catalog HTTP200. 소스catalog3시험19문항 metadata 유지, 평가 허용은 수학7개만 추가. 과학12의 열람용 메타데이터 존재를 첨삭 공개로 세지 않는다.
- 실제 authenticated 역할로 math_catalog(50) 신규7개 조회, 승인PDF3개 읽기 PASS. API의 p_limit=NULL은 기존계약상 오류이며 검사도 기존 APP 요청값50으로 확인했다. RPC를 수정하지 않았다.
- 비논술2166정적자산 hash·기존설정/Secret/Preview/Functions라우팅 동일. 경희 기존3/건국28·다른 공개문항 보존. APP 입력 계약8 PASS.
- Mac 잠금으로 실제 브라우저 UI 재검사는 NOT TESTED. iPhone/Android 신규 실기기 검사도 NOT TESTED. Owner에게 다시 로그인/잠금 해제나 품질 검수를 진행조건으로 요청하지 않았다. 실제 AI 제출/결과/재첨삭은 미실행, 동일7문항 격리 mock 계약으로 검사했다. Provider0.
- 미공개16: 의약 과학12(기존 과목별 서비스 연결 미검증),2022모의 자연4(공식 채점기준 미확인). 기존Registry/답안/평가를 삭제하거나 문제·기준을 임의 작성하지 않는다.
- 준비 APP Git783593d, WEB 배포 Git2f585c0. 다음 성균관대의 PDF 승인 대기는 별도로 확인한다.
