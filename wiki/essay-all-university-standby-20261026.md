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

## 일반 계정 운영 확인 (2026-10-27 00:11 KST)
Owner 일반 계정 로그인 후 관리자 메뉴 없음/잔액104 확인. Production 대학 목록에서 서강·고려·건국·경희·서울여·성균·중앙·외대·한양·인하 첨삭 시작 링크 표시. 중앙2026모의 인문사회 선택 시3문항/문항별 작성·저장/기존 1Credit 안내/회차 제출 컴포넌트 표시, 실제 PDF7페이지 뷰어 열람 확인. 답안0자인 상태로 버튼 비활성은 정상. 가상 답안 생성 없이 종료했으므로 답안 입력 후 버튼 활성·서버 quote 확인창은 아직 미확인이며 STANDBY 완료로 계산하지 않는다. 실제 제출/Provider/Credit변동0.
Native 코드 commit db71238. WEB commit730d74a 원격 일치 확인. APP 대학 카드 공통 상태 연동 관련 기존 미커밋 변경은 별도로 보존했고 이번 commit에 섞지 않음; 개발용 빌드는 작업 폴더 전체 기준이므로 해당 변경을 포함한다. 배포용 APK로 취급하지 않는다.

## 2026-10-27 — 동국·숙명·숭실 미완료 연결 복구 (진행 중)

Owner 2026-10-27 P0/P1 지시에 따라 전체 회차 연결을 진행한다. Provider 평가·학생 제출·Credit 차감 0. 아직 전체 STANDBY 완료가 아니다.

- 신규 실행 연결 9회차/24문항 적용: 동국 인문6회차/18문항, 숙명2026수시2·2027모의2회차/4문항, 숭실2025모의1회차/2문항. 운영 사전23/사후7 true; 격리 중복·진행중 적용 차단 및 롤백 검사 통과.
- Owner 별도 승인한 과거 패키지 reader 호환 변경 적용: 숙명2026수시1 revision3, 숭실2024수시·2026수시·2027모의 revision2의 정확한 digest만 추가 허용. 기존 서울여·성균 허용 및 현재 승인/자료 권한 검사는 유지. 격리22검사, 운영 baseline/exact_reader true.
- 위 기존 부분 연결4회차/8문항의 전체 문항 패키지 확장 적용. 기존 자료 rights/documents를 병합하여 과거 평가자료 조회 보존. 격리 사전18/사후8·중복/진행중 차단·롤백 통과. 운영 사전18/사후8 true(과거4패키지 조회 포함). 제출/예약/정산 함수 불변 확인. WEB 공개 evidence 배포는 아래 최종 상태를 따른다.
- 광운대: 기존 Registry1회차는 자연2022모의이며 인문 회차 없음. 기존 공식 인문 PDF22개(중복/분할 포함)를 확보했지만 신규 인문 Registry·실행 연결은 아직 미완료. 가천 시범 및 국민/상명/경북/을지 자산 점검도 미완료.

### 로그인 장애와 복구
WEB `6a3592924c51640025944d7646e77d0b417e4d8b` 최초 배포 `83bb60ca-383f-4a30-adcd-8f4d7fdd9c0c`에서 NEXT_PUBLIC 인증 빌드 설정을 빠뜨려 로그인 화면이 작동하지 않았다. 기존 Production 공개 설정으로 Node22 재빌드 후 `d73911d3-7085-40b2-a478-8a339096e134`에 재배포해 복구했다. Owner 일반 계정 로그인 완료, 관리자 메뉴 없음·잔액104·논술 LAB 카드 확인. Secret 재설정 없음. 앞으로 배포 전 올바른 Supabase 공개 URL/키 존재 검사와 빌드 산출물 확인을 수행한다. 잘못된83bb 배포로 롤백하지 않는다.

일반 계정에서 동국·숙명·숭실 카드가 `첨삭 시작하기`로 표시됨. 동국2027모의 인문 전체3문항, 입력·저장 영역, 문제 PDF7페이지 뷰어 확인. 빈 답안으로 제출 버튼 비활성은 정상. 가상 답안/실제 제출 없이 확인했으므로 입력 후 버튼 활성·서버 quote 완료로 확대 보고하지 않는다. APP 실기기 미확인.

### 적용 파일·재실행 금지·복구
자료 작업 폴더: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/incomplete-recovery-20261027/humanities/`.

- `new-connections/owner-sql/apply.private.sql`: 적용 완료, 재실행 금지. 해당 `rollback.sql`은 이번9회차 신규 실행만 차단하며 revisions/학생 기록 보존.
- `historical-reader/apply.sql`: 적용 완료, 재실행 금지. **부분 패키지 확장 후 reader만 롤백 금지** — 기존 요청의 과거 digest 조회가 필요하다.
- `partial-expansion/owner-sql/apply.private.sql`: 적용 완료, 재실행 금지. 해당 `rollback.sql`은 정확한 기존4실행 정책으로 복귀하고 revisions·학생 기록 보존. 새 reader 호환성은 유지한다.
- 각 폴더 `APPLIED.json`, `isolation-result.json`, 사전/사후 SQL 참조. 후속자가 기존 성공 적용을 반복하지 않는다.
- Worker registry-only 버전 `036cd19e-0789-4ad3-aaba-242661e160c4`. 기존 비Registry 코드·Secret binding 보존. 숙명2026수시1의 공개 scope 누락을 추가 발견하여 기존 전체문항 Registry/실행 코드와 모든 다른 binding을 보존한 scope-only Worker `7ae670f6-dc10-4f6b-bd14-6ffce69639cf`로 반영했다.

최종 WEB `4a95387a2e534a68013fc7948916d5196913474e`, Pages `eb6de62a-54d4-465a-afd9-28a7bb40a659` success 확인. 4확장 회차 모두 공개 scope 포함. 관련9검사·Typecheck·Production Build PASS. 일반계정 숭실2026수시 인문2문항/입력·저장/1Credit 안내 표시 확인, 실제 제출 없음. 기존 잔액104 유지. 광운 신규 연결 및 전체 WEB/APP STANDBY 미완료.

### 일반 계정 최종 확인 추가
숙명2026수시 인문1회차: 소문항1-1·1-2/2-1·2-2를 포함한 전체2답안단위, PDF4페이지, 텍스트 입력·수동 저장·다음 문항 펼침, 첨삭 버튼 활성, 서버 quote 기반1Credit·부분제출 확인창까지 실제 WEB에서 확인했다. 가상 학생 답안 대신 UI 연결 확인용 문구42자를 빈 초안에 입력했고 최종 ‘첨삭 진행하기’는 누르지 않았다. 확인창 취소 후 직접 입력한 문구만 제거하여 원래 빈 초안으로 복원했다. Provider 호출·예약·차감 없음. 이 회차는 WEB STANDBY 확인, APP 및 Owner 평가 QA는 미확인이다. 현재 adb 연결 기기0으로 APP 실기기 검증은 진행하지 못했다.

Git 원격 확인: WEB `4a95387a2e534a68013fc7948916d5196913474e`, SQL/Wiki 선행 commit `392fb950f463e7c4cd69f585a560a2f0befced62` 각각 origin branch와 일치했다. 본 추가 기록의 최종 SHA는 Git을 따른다.
