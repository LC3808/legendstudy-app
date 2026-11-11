# 작업04 홈·대학 소식 후보 계약

**CANDIDATE / PRODUCTION NOT APPLIED — 2026-11-11.**
자동 migration 디렉터리가 아니다. 기존 WEB/application RPC, profiles, Auth 설정,
Learning/Score/Credit/Payment를 수정하지 않는다. 앱 코드·격리 테스트만 승인된 범위다.
기능/검수/공식 출처: [작업04 확장 Wiki](../../../wiki/task04-home-university-news-20261111.md).

## 파일과 검증

- `candidate.sql`: 홈 설정 append-only revision + 두 RPC, 공식 소스 allowlist + immutable 공지 revision + 조회 RPC.
- `isolated_bootstrap.sql`: 빈 로컬 DB 전용 auth.users/auth.uid/roles/universities stub. 운영 실행 금지.
- `isolated_test.sql`: 가상 계정·가상 대학·example.edu 자료; transaction ROLLBACK. 앱/운영 seed가 아니다.
- `rollback.sql`: 후보 객체 제거. 향후 적용된 데이터가 있으면 먼저 export/retention 검토와 별도 승인이 필요하다.

로컬 PostgreSQL 17, `/tmp/task04-home-pg`, socket `/tmp`, port55449에서 실제 실행했다.
재현은 새 빈 scratch DB에 bootstrap → candidate → isolated_test 순서로 `psql -v ON_ERROR_STOP=1 -f` 실행.
운영 연결 문자열을 재사용하지 않는다. 테스트 종료 후 해당 로컬 pg_ctl만 stop한다.
테스트는 null 미설정, CAS conflict40001, lost-response 같은 config 멱등성,
다른 계정 조회, anonymous/client table 쓰기 차단, 이력 보존, 회원 삭제 cascade,
공식 공지 UPDATE 금지, 최신 withdrawn이 과거 verified를 되살리지 않는 조건을 검사한다.

## 운영 적용 전 확인할 계약

1. 기존 메타데이터 재조회: 동명 테이블/RPC 충돌, 기존 대학 PK 타입, auth.uid/권한, 보존·삭제 정책.
2. RPC 이름과 인자: `my_home_configuration()`,
   `save_my_home_configuration(p_config jsonb,p_revision bigint)`,
   `university_news_feed(p_universities uuid[],p_offset integer,p_as_of timestamptz)`.
3. 홈 version1/cards 배열 + revision CAS. ID 최대80자/100개/JSON64KB, unknown ID 보존.
   config 조회는 null을 미설정으로 반환. 같은 payload 재요청은 기존 revision 반환.
4. 공식 자료는 운영자가 **대학 공식 host를 검수**한 후 source allowlist에 등록.
   공식 원본 보존 key/SHA256/페이지·문단 locator/게시·수정·확인 시점이 필요하다.
   URL만 안다는 이유로 검증 완료 처리하지 않는다. source archive 업로드/수집기는 이번 범위에 없다.
5. 전형·모집단위는 실제 application 문자열에 정확히 대응하는 검수값. 학과 차이가 있으면
   `division` 범위로 각각 입력한다. 일부 학과 제외 자료를 대학/전형 공통으로 넣지 않는다.
6. 동일 공식 사실은 동일 series_key로 새 revision 추가. 수정/철회는 새 행, 기존 행 UPDATE/DELETE 금지.
   `verified`/`withdrawn` 최신 revision 선택 후 공개; 공개 RPC는 개인 지원 데이터에 접근하지 않는다.
7. 조회 첫 페이지 snapshot_at을 다음 p_as_of로 전달한다. append-only created_at 기준
   같은 snapshot/series_key 순서로100개씩 조회.10분 초과 snapshot은 실패하고 전체 재조회.
8. 발행일 published_at과 확인일 verified_at를 구분. expires_at은 검수자가 명시한 재확인 기한.
   마감이 임박한 일정은 일일 재검수 등 실제 운영 주기가 확정되기 전 자동 최신 보증 금지.
9. 모든 일정 academic_year 필수. `precision=date`는 starts_on/ends_on DATE,
   exact/after는 offset 있는 timestamptz. unknown은 날짜·시각 모두NULL.
   `precision`은 is_date_only보다 세분화된 계약이며 KST와 '이후'를 보존한다.

## 배포·원복 경계

현재 운영에는 위 RPC/테이블이 없다. 로그인 설정 저장·기기 간 복원은 후보 적용 전 이용 불가.
오류 시 앱은 기본 홈을 표시하고, 편집은 미저장으로 안내한다. 온보딩 다음에 하기는 독립 완료 가능.
대학 소식은 기본 OFF이고 실제 공식 일정0건 수집/배포. 준비 중·확인 중 상태가 정상이다.

승인 후에도 먼저 staging에서 두 테스트 계정/기기 동기화·세션 전환·공식 원본 검수·롤백을 확인한다.
운영에는 bootstrap/test fixture를 절대로 실행하지 않는다. Candidate 적용 자체도 별도 승인 필요.
원복 전 새 이력을 보존하며, APP75 원래 홈 코드로 복귀하는 경우 신규 데이터는 삭제할 필요가 없다.
