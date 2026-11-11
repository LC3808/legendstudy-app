# Owner 통합 검수 접근 제어 준비 — 2026-11-12

**PARTIAL / 운영 미적용 / REVIEW READY 아님.** [최신 TECH READY 순차 기준](essay-natural-sequential-order-20261112.md)을 따른다. Owner가 지정한 기존 계정은 읽기 조회에서 존재·이메일 인증·탈퇴/삭제 제한 없음·프로필 존재를 확인했다. 실제 이메일/subject 바인딩은 ignored private 파일로만 유지한다. 계정 선택은 운영 권한 부여 승인이 아니다.

[비공개 DRAFT 적용](essay-kau-draft-production-20261112.md)은 완료 상태를 유지한다. 신규 DB/RPC 변경·Worker 활성화·Provider 호출·WEB/APP 배포는 이번 작업0건이다.

## 확인한 경계와 로컬 후보

현재 ACTIVE 전환만 하면 일반 계정이 직접 제출할 수 있으므로 화면 숨김만으로 Owner 검수를 열 수 없다. 기존 `resolve_profile`/`release_catalog`에서 신규 제출과 목록을, 기존 evaluation/extraction claim에서 큐 작업의 실제 답안 소유자를 확인하는 로컬 후보를 만들었다. 기존 `current_subject`와 account lifecycle helper를 재사용한다. 기존 엔진·Provider·Credit·최종 결과 저장·재작성 구조는 변경하지 않는다.

[SQL 차이·원복·검사](../supabase/candidates/kau_owner_review_20261112/README.md): private table1/helper1, 기존 함수4 제한 추가, 기본 disabled/만료 필수. 7문항 대상으로 격리 PG17 **53검사 PASS**. 대상 계정·문항 격리, 일반/익명 접근, 만료/탈퇴 대기, 권한 회수 후 신규 claim 차단, 기존 ACL/자료/원장/결과 보존, 원복을 확인했다. Provider0이며 실제 AI 품질 검수가 아니다.

권한 회수 전에 승인된 Worker lease는 기존 finalizer로 완료될 수 있다. 회수 후 이미 받아들인 idempotent 요청은 기존 결과를 돌려줄 수 있지만 신규 작업을 생성하지 않는다. 동시 claim/회수 경계, 삭제중 계정/이미지 추출 성공, 운영 session wrapper 전체와 실제 UI는 이번 검사에서 NOT TESTED다.

## 통합 검수까지 남은 일

- 위 후보는 한국항공7 leaf의 경계 검증용이다. 대학마다 RPC를 덧붙여 설치하지 않는다. 지정 계정과 명시된 시험/문항의 reusable private scope, 만료/회수 정책으로 통합한다.
- WEB `availability` 및 evaluate/extract/upload/artifact의 공개 allowlist는 Owner도 걸러낸다. 전역 공개 범위를 넓히지 않고 서버에서 검증된 subject+승인 scope를 사용하는 별도 preview 진입이 필요하다.
- 과거 `/owner-review/essay/`는 읽기 전용 결과 preview의 rollback 이력으로, 현재 제출/첨삭 검수 경로가 아니다.
- APP도 동일 Backend의 검증된 scope를 사용해야 한다. 현재 실제 WEB/APP Owner 진입·첨삭 요청·재작성 E2E는 NOT TESTED다.
- 운영 DRAFT, 통합 검수 권한/활성화, 배포, 사용자 공개를 별도 승인한다. 검수 기능 미완료를 대학별 자료 연결 중단 이유로 사용하지 않는다.

## 보존 검토7항

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의 선행 질문을 적용한다.
1. 이번 추가 사실은 검수 계정 지정/권한 정책이며 학생 학습 결과가 아니다. 로컬 검증일과 과거 운영 적재 시각을 분리했다.
2. 기존 함수 원문/hash·exact diff·SQL receipt·테스트로 검토 당시 상태를 복원한다. Owner 식별자는 private 보관한다.
3. control enabled/expiry는 현재 권한 projection이다. 실제 운영 권한 변경은 별도 승인 영수증을 남겨야 하며 과거 답안·평가를 덮지 않는다.
4. 기존 auth subject를 사용하고 동일 사용자의 과거 학습 identity를 바꾸지 않는다. 격리 계정 데이터만 합성했다.
5. 접근 제어는 학습 서비스 운영 정책이며 입시 Decision/Outcome 데이터로 전환하지 않는다.
6. private table/helper 직접 접근을 제한하고 탈퇴 lifecycle을 계승한다. 새로운 학생 수집/외부 공유/retention 정책은 만들지 않는다.
7. Mock 결과·53검사 PASS는 기술 경계 증거다. AI 품질이나 실제 서비스 사용 가능성으로 보고하지 않는다.

## 10개교 공통 후보 후속

[통합 검수 준비](essay-natural-integrated-review-20261112.md): TECH186 exact scope, private control/scope2테이블·helper1·기존4함수 후보를 기본OFF로 준비했다. 격리602검사 PASS, 문항별승인·회수 및 삭제중 차단 추가. 기존7leaf53검사는 역사적 경계 증거로 보존한다. 운영 적용·실제 WEB/APP 진입은 여전히 미완료이며 대학별 자료 연결과 분리한다.
