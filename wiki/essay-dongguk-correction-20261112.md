# 동국대 2026 모의 Q1 공식 정정 연결 · 2026-11-12

[기존 20문항 공개](essay-dongguk-public-20261112.md) 후 잔여51 정리 Owner 승인 범위다. 기존 Registry `49ea9aaa-1c46-51e7-b148-a03aef20ae4e`와 학생용 문제 PDF를 유지한다. 신규 시험/문항0, 새 RPC/Storage정책0, Provider0. 공개 적용 범위는 Q1 13행, 기존 두 내부 허용목록에 leaf1 추가(392→393), 기존 WEB 시험의 Q1 진입 허용이다.

## 공식 정정 근거

[공식 게시물](https://ipsi.dongguk.edu/admission/html/counsel/dataView.asp?BOARD_IDX=34784)의 [문제1 해설 수정 HWP](https://ipsi.dongguk.edu/upload/file/20250822131429MDPC5L.HWP)는 SHA `7843457d01caaac1e5e7f560b39197e632988cbbbfc750ffa603c9656d141df1`이다. 한컴 한글 Viewer에서 읽고 PDF로 출력해 11쪽을 얻었다. 출력본 SHA `5ada1e6e7b68e4477a9c00b711bc1fb0cbc8308325248d8ebca82bff0dc38e17`, Q1 공식 평가·예시답안은 PDF2–3쪽이다. 이전 LibreOffice 출력은 계속 사용하지 않는다.

문제의 장축2/단축1과 수정식 x²+4y²=1, 공식 최댓값 3√3/8을 원문·렌더로 대조했다. 과거 x²/4+y²=1 및 3√3/2를 쓴 미공개 후보의 기준만 별도 버전으로 교체한다. 기존 Q2·Q3와 다른 20문항 자료/학습 이력은 수정하지 않는다. 2025년 시행/2026학년도 Registry 일치 확인은 유지한다. AI 품질 판정은 하지 않았다.

## 적용 전 검증

[범위·SQL SHA](../supabase/candidates/dongguk_correction_20261112/scope.json), [14개 사전 SELECT·21개 보존집계](../supabase/candidates/dongguk_correction_20261112/production-before.json), [격리 실제 RPC·Mock 결과·재첨삭·원복](../supabase/candidates/dongguk_correction_20261112/isolated-results.json). 기존392 공개 문항과 RLS272개 보존을 확인한다. WEB399 PASS/1SKIP, APP 실제 원본 PDF 포함4 PASS, typecheck·정적빌드·Functions빌드 PASS. 최초 격리 fixture가 모의를 admission으로 저장해 사전 가드에서 중단했으며, 실제 Registry와 같은 mock fixture로 고친 뒤 통과했다. 테스트의 런타임 미노출 속성 참조도 정정해 타입 검사 통과했다. 운영 실패가 아니다.

## 비파괴 원복

[허용목록 원복 SQL](../supabase/candidates/dongguk_correction_20261112/rollback-admission.sql)은 Q1 신규 평가 진입만 닫는다. 공식 자료13행·사용자 답안·결과·Credit는 삭제하지 않는다. WEB Q1 범위를 먼저 닫고 함수 해시 가드를 검증한다. 격리 원복 후 기존 결과 조회/이력·기존 catalog 보존 PASS.

실제 로그인 제출·결과 화면·실기기·AI 품질은 NOT TESTED. 운영 적용 영수증은 아래 확정 기록에 추가한다.

## 운영 적용 확정

**PUBLISHED**. Migration `20261112092154_dongguk_mock_q1_official_correction_public`, WEB 배포 `844798cb-e04b-4f2c-82ec-16fc45cc200a`, 소스 `7987a4639dcb18fbbf3a8a9e771a0bcaa8e68c5c`. 운영 검증 2026-11-12T18:26:12.241558+09:00, 공개 HTTP 확인 2026-11-12T18:26:54.555567+09:00. [적용 영수증](../supabase/candidates/dongguk_correction_20261112/activation-transport-receipt.json) · [운영 사후 검증](../supabase/candidates/dongguk_correction_20261112/production-receipt.json) · [WEB 보존 검증](../supabase/candidates/dongguk_correction_20261112/web-production-receipt.json).

사후 3개/보존21개 PASS, RLS272개·기존 사용자 데이터·함수 ACL 보존. 일반 authenticated 역할의 공개 catalog 조회 PASS이며 실제 로그인 브라우저 검수와 구분한다. 비논술 정적 자산 2192개 보존, API 소스·Secrets·Preview·함수 라우팅 불변. /essay-lab, /api/essay/catalog, /login HTTP200, 비로그인 PDF API401. 운영 Provider 호출0, 실제 로그인 제출·결과·재첨삭·실기기는 NOT TESTED. 원복은 실행하지 않았다.
