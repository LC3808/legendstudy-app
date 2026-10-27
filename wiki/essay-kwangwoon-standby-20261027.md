# 광운대학교 인문 STANDBY — 2026-10-27

## 현재 결과

Owner의 “광운대 진행해”에 따라 기존 [전체 대학 연결 정책](essay-all-university-standby-20261026.md)을 실행했다. 대학 카드 비활성 원인은 인문 자료가 있어도 Registry/실행 연결이 없고 기존 등록은 자연 2022 모의 1회차뿐이었던 것이다. 버튼 강제 활성화가 아닌 인문 회차 전체 연결로 해결했다.

| 범위 | 대상 | 전체 문항 연결 | WEB 공개/STANDBY | APP 실기기 | 보류 |
|---|---:|---:|---:|---|---:|
| 인문 수시 2022~2026, 각 1·2교시 | 10 | 10 (20문항) | 10 | 미확인 | 0 |
| 인문 모의 2022~2027 | 6 | 6 (12문항) | 6 | 미확인 | 0 |
| 기존 자연 2022 모의 | 1 | 기존 상태 보존 | 비활성 유지 | 미확인 | 1 |

**신규 WEB 16회차·32문항. E2E PASS 및 Owner 품질검수 완료를 의미하지 않는다.** 실제 Provider 평가 0, Credit 차감 0. APP은 동일 Backend 조회 경로가 존재하나 현재 adb 연결 기기가 없어 설치 버전의 조회·입력·확인창은 검증하지 못했다. APP 완료로 집계하지 않는다.

## 재사용 및 운영 반영

- 공식 PDF 22개 조사, 중복 통합 후 원본 20개 재사용. 문제 부분만 추출한 학생 PDF 16개 생성. 공식 해설은 비공개 평가 패키지에 보존.
- 기존 자연 시험·문항 ID 보존, 누락 인문 시험 16개·문항 32개만 추가.
- 기존 Essay 평가 프로필·회차 1 Credit·무료 재첨삭 계약 재사용.
- 기존 runtime 197건 보존하고 신규 16건 추가. Worker registry 245→261, 공개 scope 195→211.
- 기존 평가 엔진·정산·인증 함수·Secret 변경 없음. Worker는 registry asset만 교체하고 다른 모듈·bindings·실행 설정 유지.
- WEB 변경: source registry, student PDF catalog, whole-exam release evidence 3개 JSON. 실제 DB package digest와 연결.

Production:

- Supabase: `stlhijzpjfgwwdgunlsd`
- WEB SHA: `a0b1bcf266c890556b81a1059e4fb90214bb219e`
- Pages 배포: `7eea1b34-3926-4fcd-a695-aeb5a3b4b3ea`, canonical production 성공 및 commit 일치 확인.
- Worker: `202f8f62-83ad-4ae8-9cc7-b4a576226e3b`
- [운영 페이지](https://lab.legendstudy.com/essay-lab/universities/kwangwoon/)

## 검사와 실제 화면

- 격리 사전 26/사후 7 PASS, 중복 적용·진행중 요청 차단·롤백 검사 PASS.
- 운영 사전 26/사후 7 true. 기존 정책·학생 기록 보존 검사 통과.
- Typecheck PASS, Lint 오류 0(기존 경고 4), 관련 3파일 8테스트 PASS, Production Build PASS.
- 일반 계정 운영 UI에서 11개 학년도·시험 그룹의 16회차를 모두 선택: 각 문제 1·2, PDF 버튼, 답안 입력 및 회차 첨삭 요청 영역 확인.
- 대표 2027 모의 PDF 실제 8페이지 뷰어 렌더 확인.
- 대표 2027 모의에 임시 연결확인 문구 입력·로컬 수동 저장 → 요청 버튼 활성 → 미작성 문제2 안내와 **서버 Credit 출처 확인창** 확인. 관리자 지급 104개 중 1개 사용 예정 표시. “계속 작성하기”로 취소하고 임시 입력은 빈 값으로 복원.
- 기존 잔액 104 유지. 실제 평가 제출·계정 답안 저장·History 생성은 실행하지 않음.
- 모든 회차의 PDF 실제 렌더 및 Credit 모달을 각각 반복하지는 않음: 16회차 연결 검사와 전체 선택 화면, 공통 경로 대표 확인으로 구분.

## SQL 재실행 금지 및 복구

[SQL 적용 명세와 해시](../supabase/candidates/kwangwoon_standby_20261027/README.md)

자료 루트: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/incomplete-recovery-20261027/kwangwoon/`

`registry.sql`, `owner-sql/apply.private.sql`는 이미 적용했다. 재실행하지 않는다. Storage 36객체 신규 업로드 완료, 기존 객체 덮어쓰기 없음. `APPLIED.json` 및 direct 결과 파일이 성공 근거다. Management API 413 결과는 적용 실패 기록이며 성공 근거로 사용하지 않는다.

복구 시 후속 배포/실행 중 요청부터 확인:

1. WEB 공개 범위에서 이번 16회차를 제외하고 배포한다. 다른 변경이 없다면 직전 WEB `04aa7a8ac4ff47cec370afb1eb3c441b1cc2c285`, Pages `b9e9fc31-691b-4e02-ad75-6952a42c6f3a`가 기준이다.
2. Worker registry의 이번 16개만 회수한다. 직전 버전 `18813be0-9543-4974-b6bc-fe53a66183b4`; 후속 변경이 있다면 전체 롤백하지 않는다.
3. `owner-sql/rollback.sql`은 해당 실행 분기/PDF 정책만 제거하며 Registry·자료 revision·학생 기록을 삭제하지 않는다. 진행 요청·변경된 digest 방어를 유지한다.
4. Credit·Ledger·History 및 기존 자연 회차는 수정하지 않는다.

## 보존 검토 및 다음 작업

학년도는 시험 원본 기준(2022~2027), 작업일 2026-10-27과 구분한다. 원본 hash와 파생 PDF 페이지 연결을 보존한다. 학생 데이터 UPDATE/DELETE가 없는 추가 연결이다. 기존 ID를 보존하고 미등록 시험만 새 ID를 쓴다. STANDBY는 학습 성과가 아닌 운영 상태다. 인증된 PDF 열람만 허용하며 새로운 개인정보를 수집하지 않는다. 평가 성공·품질 확인은 Owner 검수와 별도로 기록한다.

다음은 Owner의 광운대 실제 답안 검수와 APP 기기 재연결 후 Native 경로 확인이다. 가천대 시범 공개는 별도 범위이며 이번 광운대 완료에 포함하지 않는다.

### 자연계열 목록 노출 정책 보정
2022 모의 자연 1회차/2문항은 기존 Registry와 browse 응답에 존재한다. 다른 학년도 자연 등록은 없다. 전체 등록 계열 바로가기·준비 중 비활성 안내를 공통 WEB에 추가했다. [운영 확인·검증·복구](essay-all-university-standby-20261026.md#2026-10-27--자연계열-시험-목록과-첨삭-공개-분리). 인문 16회차 공개 정책 보존.
