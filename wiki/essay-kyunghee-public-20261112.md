# 경희대 자연·수리 공개 연결 · 2026-11-12

상태: 운영 적용 전. 신규3시험7문항92행을 공개 연결하며 기존2026자연3문항을 보존한다.

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

운영 계획: 신규92행 → 정확한28버전행 ACTIVE → 기존 evaluation_admission/release_catalog의239leaf 보존+7 → Pages public268→271 / expansion98→101 / Math239→246. 비논술정적2166자산/Functions경로/기존설정/Secret/Preview 보존. 기존 엔진과 결제 규칙 불변, 신규RPC0.

## 원복

[허용목록 원복](../supabase/candidates/kyunghee_public_20261112/rollback-admission.sql)은 적용 후 함수 hash가 일치할 때만 실행한다. 먼저 WEB 신규3시험/7leaf scope를 회수하고 직전 배포를 복원한다. 신규자료·진행중작업·답안·결과·Credit 기록은 삭제하지 않는다. 후속배포가 있으면 전체 정의/설정을 덮어쓰지 않는다.

## 적용 결과

실제 운영 적용과 공개 수는 사후 검증 후 기록한다. TECH READY/후보파일을 운영 완료로 취급하지 않는다.
