# PDF 다운로드 운영 활성화 (수정본 845개)

대상은 LegendStudy `stlhijzpjfgwwdgunlsd`만이다. 운영 SQL은 Owner가 실행한다.
최초 846개 패키지는 Registry 사전검증에서 중단됐고 변경되지 않았다.
현재 비활성인 `78960745-ee6a-5045-842f-08738ac1fe44`를 제외했다.
원본 자료의 비활성 상태를 해제하지 않는다.

1. SQL Editor의 기존 본문을 모두 지우고 최신 [apply.sql](apply.sql) 전체를 새로 붙여 실행.
   첫 줄 `-- PACKAGE: PDF845-R2`를 확인한다. 성공 결과도 `PDF845-R2 / 845 / 845`이다. 단일 transaction으로 파일명 제약 수정,
   이번 Owner 결정 기록 및 검증된845개 ALLOWED revision을 추가한다.
2. [postcheck.sql](postcheck.sql): 최신 state ALLOWED845 / policy_allowed845 기대.
3. 기존 앱 자료 상세에서 대표 PDF 저장·파일명·재열람을 양OS에서 확인한다.
   이 브랜치 Viewer 하단 버튼/MY 완료목록은 새 바이너리가 필요하다.
4. 문제가 있으면 [rollback.sql](rollback.sql) 실행 후 postcheck policy_allowed0 확인.
   원복은 VIEW_ONLY revision 추가이며 이전 허용 이력은 삭제하지 않는다.
   filename 정규식 수정은 원복하지 않는다.

`Permission history changed` 또는 `Registry mismatch`면 실패한 transaction을
부분 실행하지 말고 현재 Registry/권한을 재대조한다. 이미 허용한 패키지를
중복 실행하지 않는다. 별도 자료 이용 재검토를 요청하는 절차가 아니다.

`baseline-*.sql`, `fixture-resources.sql`, `test_isolated.py`는 **격리 로컬 검증 전용**.
운영 SQL Editor에 실행하지 않는다. macOS PostgreSQL17 설치 환경에서
`python3 supabase/candidates/pdf_activation_20261113/test_isolated.py`로 재현.

[운영 결과·전체 인계](../../../wiki/operations-commercial-20261113.md).

후속 Registry mismatch 재신고 후 Codex가 운영에 최신 파일의 정확한 JOIN 조건을
읽기 전용 실행: input845/matched845/executor postgres/권한0. 현재 불일치는 재현되지
않았으며 실행본문·실행시점 차이는 미확정. R2는 같은845개와 같은조건을 유지하고
실패 메시지에 input/matched/role/database를 추가한다. 새 실패 메시지 전체를 전달하면
환경·본문 차이와 Registry 변경을 구분할 수 있다. 검증 우회나 운영 쓰기 대행 없음.
