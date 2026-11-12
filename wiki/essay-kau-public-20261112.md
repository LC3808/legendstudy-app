# 한국항공대 기존 DRAFT 7문항 공개 · 2026-11-12

최신 Owner 잔여51 정리 지시에 따라 기존4시험7문항106행을 재사용한다. 신규적재0, 상태28개 DRAFT→ACTIVE, 기존 내부함수 evaluation_admission/release_catalog 허용목록385→392. 기존 [DRAFT 적재 기록](essay-kau-draft-production-20261112.md)은 역사로 보존한다. HOLD5 및 나머지44문항은 제외. 2024이학은 Q2만 허용하고 Q1 Registry/문제표시는 보존한다.

## 적용 전 검증과 보존

[정확7문항·SQL SHA](../supabase/candidates/kau_public_20261112/scope.json), [운영 SELECT108검사](../supabase/candidates/kau_public_20261112/production-before.json), [격리 제출·결과·재첨삭·원복](../supabase/candidates/kau_public_20261112/isolated-results.json), [기존PDF4개 SHA/16쪽](../supabase/candidates/kau_public_20261112/pdf-audit.json).

원본 Registry/Worker106행의 내용·공식 기준과 기존 사용자 이력은 바꾸지 않는다. 원본 SHA·문항ID·기존 시간/버전·계정 식별을 유지하며, 학습 사실·모델 평가·합불을 합치지 않는다. 개인정보/보존기간/접근목적/Credit 의미 변경0. 공식 판단이나 AI 품질을 새로 생성하지 않는다. 21개 보존집계로 기존 내용/기록/함수owner·ACL/RLS를 비교한다.

WEB 변경은 Source Registry4시험8문항 메타데이터 추가와 첨삭허용7개만. UI·API소스·Worker엔진은 재사용한다. 배포 시 논술 경로만 교체하고 비논술 자산, Secrets, Preview, 라우팅을 보존한다. APP제품 코드 변경0. 새 RPC/Storage정책0, 업로드0.

## 원복

[비파괴 허용목록 원복](../supabase/candidates/kau_public_20261112/rollback-admission.sql)은 신규7leaf 진입만 닫으며 기존106행·새답안·결과·Credit를 삭제하지 않는다. WEB의 신규범위를 먼저 닫고 해당SQL의 함수해시 가드를 확인한다. 이미 시작한 결과 읽기와 이력은 유지한다. 격리 원복 PASS. 운영 적용 실패 시 transaction 전체 취소하며 드리프트가 있으면 원복SQL을 강행하지 않는다.

운영 적용 결과와 최종Git은 아래 후속 기록으로 확정한다. 실제Provider0, 로그인 제출/실기기/AI품질은 NOT TESTED. AI품질 검수는 Owner 담당이다.
