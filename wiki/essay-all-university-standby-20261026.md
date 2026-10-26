# 42개 대학 WEB/APP STANDBY 연결 감사 — 2026-10-26

## 판정 기준
운영 DB 읽기 전용 스냅샷 기준. 등록·패키지 연결·공개 조회 후보를 구분한다. 아래 후보 수는 실제 화면 STANDBY 완료 수가 아니다. Provider 호출/학생 제출/예약/정산/DB 쓰기 0. APP 실기기 확인 미완료.

|대학|Registry 회차|실행 패키지|전문항 공개 조회 후보|Math 신규 요청 보류|미연결/부분·기타|
|---|---:|---:|---:|---:|---:|
|가천대학교|17|0|0|0|17|
|가톨릭대학교|1|0|0|0|1|
|강남대학교|0|0|0|0|0|
|건국대학교|25|14|8|6|11|
|경기대학교|0|0|0|0|0|
|경북대학교|1|0|0|0|1|
|경희대학교|34|24|22|2|10|
|고려대학교|10|5|4|0|6|
|광운대학교|1|0|0|0|1|
|국민대학교|0|0|0|0|0|
|단국대학교|0|0|0|0|0|
|덕성여자대학교|0|0|0|0|0|
|동국대학교|16|0|0|0|16|
|동덕여자대학교|0|0|0|0|0|
|부산대학교|2|0|0|0|2|
|삼육대학교|0|0|0|0|0|
|상명대학교|0|0|0|0|0|
|서강대학교|32|23|22|0|10|
|서경대학교|0|0|0|0|0|
|서울과학기술대학교|0|0|0|0|0|
|서울시립대학교|1|0|0|0|1|
|서울여자대학교|11|1|1|0|10|
|성균관대학교|25|16|16|0|9|
|성신여자대학교|0|0|0|0|0|
|세종대학교|3|0|0|0|3|
|수원대학교|0|0|0|0|0|
|숙명여자대학교|8|2|0|0|8|
|숭실대학교|16|3|0|0|16|
|신한대학교|0|0|0|0|0|
|아주대학교|6|0|0|0|6|
|연세대학교|16|0|0|0|16|
|을지대학교|0|0|0|0|0|
|이화여자대학교|1|0|0|0|1|
|인하대학교|35|34|10|24|1|
|중앙대학교|26|21|11|10|5|
|한국공학대학교|0|0|0|0|0|
|한국기술교육대학교|0|0|0|0|0|
|한국외국어대학교|20|20|20|0|0|
|한국항공대학교|15|0|0|0|15|
|한신대학교|0|0|0|0|0|
|한양대학교|23|21|12|8|3|
|홍익대학교|1|0|0|0|1|

고려대 기존 Q2 한 문항 Owner 예외는 완전한 회차 수에 포함하지 않는다. 숙명 2회차/숭실3회차는 패키지 한 문항 연결 상태이므로 전체 회차로 승격하지 않는다.

## 연결 GAP
- APP 내장 PDF 목록: HEAD 487문항, 작업 폴더 524문항. WEB 승인 PDF 후보 862개와 불일치. 인증된 공통 PDF 메타데이터 조회로 보완 중.
- Native 기존 설치본은 새 API 사용 코드가 없어 개발용 빌드/기기 확인 필요.
- 신규 대학의 공식 근거와 전체 문항 패키지 생성/SQL 적용은 미완료. 대학명/등록 숫자만으로 승인하지 않는다.
- 기존 leaf 단위 Math 경로의 별도 공개 정책 확인 필요. 회차 게이트 차단을 전체 Math 경로 차단으로 보고하지 않는다.

## 보존 검토
Preservation review: (1) audit time is separate from historical learning events; (2) original answers/results/ledger remain immutable; (3) no student UPDATE/DELETE, catalog projections only; (4) canonical exam/question IDs retained; (5) service readiness is operational metadata, not learning/outcome evidence; (6) authenticated metadata and existing Storage RLS retained, no new personal fields; (7) STANDBY counts are derived, never E2E results. No new student storage selected.

## 2026-10-27 연결 수정/배포
- WEB `730d74a6b1a30b31596fa83147dba619db9ee7b2`: Native service-status를 WEB public-service-status와 동일 승인 목록으로 통합. Worker 개별 초기화 반복 제거.
- 기존 승인된 중앙 인문 회차 c7e17f5e-9037-5a78-8e77-7878a98230ca 전체3문항 discovery 누락 복구. 신규 Registry/정책 생성 아님.
- 실제 Math 입력 패키지50회차에 고정 ID 기반 신규 quote/submit 보류. 기존 retry 유지. WEB legacy Math fallback으로 보류를 우회하지 않도록 수정. 독립 legacy Math DB 요청 경로는 추가 확인 필요.
- 인증된 student-pdfs 메타데이터 API와 Native 동적 승인 PDF 조회 구현. 기존 Storage RLS·hash 검증 유지. 별도 DB 없음.
- Production Pages `62435975-f93d-4c65-8e01-d85f214c1cd8`, canonical deployment success/commit 일치 확인. Worker/Secret/Production SQL 변경0.
- WEB 관련55검사/Typecheck/Build PASS, Lint 오류0·기존경고4. stale DB-submit fixture에 실제 admission 응답 추가. Native10검사/대상분석 PASS, Android 개발용 APK 성공. 실기기 미연결이며 설치/스토어 배포0.
- 후보126회차는 전체 연결된 공개 조회 후보이며 WEB/APP 실사용 완료 수로 사용하지 않는다. 전체 대학 확대는 미완료.

## 재개/복구
1. 일반계정 WEB 실제 선택·PDF·저장·1Credit 확인창 기록. 제출 금지.
2. APP 기기 연결 후 개발용 환경 설정으로 동일 경로 확인. 현재 APK는 개발용이며 Production 설치본 완료 근거 아님.
3. 숙명/숭실 부분 패키지를 공식자료로 전체 회차 보완, 항공/광운/동국 신규 실행 패키지 준비. 기존 SQL 재실행 금지.
4. 자연 Math 독립 legacy 요청 경로의 신규 예약 차단 범위 확인. 기존 예약/재처리는 보존.
복구: WEB 이전 Pages `89246b7e-c283-499b-a849-5e1f1e6dbb3d`/commit584a914로 복귀 가능하나 Math 보류 정책이 사라지므로 Owner와 범위를 확인한다. Native 동적 PDF 실패는 기존 pinned 승인 목록으로 fallback. 이번 직접 SQL 없음, DB rollback 없음.
