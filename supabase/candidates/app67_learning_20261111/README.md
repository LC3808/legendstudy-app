# APP67 학습 통합 SQL 후보 — 운영 미적용

Owner 2026-11-11 작업02: SQL은 적용안·검증·원복 계획까지만 작성한다.
이 폴더는 자동 migration 대상이 아니며 적용 승인이 아니다.

## 변경 범위

1. `student_private.study_summary(uuid,timestamptz)`의 기존 v1 반환에 `all_time_ms`,
   `all_time_source=completed_synced_sessions`를 추가한다. 기존 오늘/주/30일/daily7과
   2,000행 오류 계약은 그대로다. 기존 active_segments의 절대 구간 + range_agg 합집합을
   재사용하며, 완료·동기화·합산 대상 기록만 서버에서 합산한다. 진행/대기 기록을
   APP이 더하지 않는다. 전체 기간에서 `ended_at <= p_now`를 적용한다.
2. `my_application_save`의 기존 사용자별 배타 advisory lock 안에서 동일 지원의
   새 요청을 `APPLICATION_ALREADY_EXISTS` (23505)로 거절한다. 키는
   사용자+학년도+대학+trim(학과)+trim(모집구분)+trim(전형명)이다.
   다른 학과/모집/전형/연도는 허용한다. request_key 재전송 및 revision 검사는 보존한다.
   운영 `account_private.lock_subject`의 배타 lock과 salt 84612를 읽기 확인했다.

새 테이블·인덱스·RPC·GRANT·RLS·Auth·원장 변경 없음. 기존 지원과 이벤트를 정리하거나
병합하지 않는다. 희망 대학의 기존 UNIQUE 정책도 변경하지 않는다. 직접 INSERT 권한은
기존대로 없다. 관리자/DB owner의 직접 쓰기까지 의미상 중복을 강제하는 UNIQUE 인덱스는
이 후보에 없다. 기존 중복을 삭제하는 작업을 요구하지 않는다.

## 검증

`python3 tool/test_app67_learning_sql.py`는 운영 URL/자격 증명 인수를 받지 않는다.
임시 디렉터리와 Unix socket 전용 PostgreSQL17을 생성·종료한다. 합성 데이터로만 검사한다.
42 SQL checks 및 assertions: 겹침·다른 회원·비합산 제외, 기존 v1 값 동일, lifetime 합산,
익명/비공개 접근 차단, 동일 request 재시도, 다른 요청 동일 지원 차단, 다른 학과/모집/전형/
연도 허용, 동시 두 세션 중 1건만 저장, revision 충돌, ACL/학습자료/지원 이벤트 보존,
기준 해시 변경 시 적용 중지, 원복 후 원래 함수 해시 일치. 최종 결과는 기능 Wiki 참조.
운영 회원을 대상으로 신규 지원·초대·학습 기록을 생성하지 않았다.

## 적용 절차 — 별도 Owner 승인 후에만

1. 프로젝트 `stlhijzpjfgwwdgunlsd` 확인. `verify.sql`로 정의 해시·ACL·기존 중복 수 읽기 확인.
   `baseline.json`은 11/11 운영에서 읽은 함수 정의다. 이후 변경이 있으면 후보를 재검토한다.
2. 원래 함수 정의/ACL과 기존 study_sessions·student_applications·student_application_events의
   ID별 내용 증거를 보존한다. 동시 정상 사용자 신규행 증가와 기존행 변경을 구분한다.
3. `apply.sql` 트랜잭션 적용. 원본 함수 해시가 다르면 전체 중단한다. GRANT를 확대하지 않는다.
4. 기존 학생 세션의 `my_study_summary()`를 읽기 조회하여 오늘/주/30일이 동일하고
   누적 필드가 정확한지 검증한다. 직접 쓰기·실제 지원 생성으로 검증하지 않는다.
5. 운영 최대 이력 사용자 범위에서 쿼리 시간/statement timeout을 확인한다. 전체 누적은
   전체 기간 합집합이므로 로컬 소량 fixture PASS가 운영 최대 데이터 성능 보장은 아니다.
   성능 승인 전에는 APP의 전체 누적 표시를 활성화하지 않는다.
6. WEB의 지원 입력은 23505를 이미 등록된 지원으로 안내하는 후속 표시 보완이 필요하다.
   이번 APP 작업에는 WEB 수정/배포를 포함하지 않는다.

## 원복

`rollback.sql`은 후보 적용 후 함수 해시가 일치할 때만 이전 두 정의를 복원한다.
다른 후속 작업이 있으면 멈추고 해당 작업을 보존하는 원복안을 다시 만든다.
기존/신규 사용자 학습·지원·이벤트를 삭제하지 않으며 ACL 변경도 없다.
원복 후 verify와 기존행 대조를 반복한다. APP은 현재 누적 필드를 읽지 않으므로 원복과 호환된다.
