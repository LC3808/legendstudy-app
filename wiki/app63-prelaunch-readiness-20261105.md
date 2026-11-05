# APP63 출시 전 최종 점검 / 승인 요청

빌드 소스9fb4ea3 유지. 이번 제품코드·버전·빌드 재생성 없음. [통합 감사](app-update-final-audit-20261105.md), [서명/해시](app-update-final-build63-receipt.json) 계승. 운영 변경은 Owner가 정확한 SQL 범위를 승인한 후에만 실행. Store 제출은 Owner 직접.

## 현재 판정

RELEASE_READY=NO (TASK18 기반 완료 / TASK19 운영 권한 차이로 수정안 승인 대기 / APP63 설치 완료·기능 실검수 대기).

- TASK18 resource_download_policy 및 material_download_private 없음.
- TASK19 grade_cutoff_lookup/grade_cutoff_references 없음. 기존 대상시험11개, exam_subjects(id,content_item_id) UNIQUE 존재, 기존 grade_cutoff_versions0행. 수치 후보2457행/11시험/273과목조합 검증 재실행 PASS.
- support_mine/support_detail 설치·stable 확인. math_session_history 존재. 설치 사실은 실제 회원 문의/History 조회 성공을 뜻하지 않음.
- iPhone12ProMax 본앱1.0.1(58), MathTEST62, PDFTEST1 관측. APP63 archive는 이 기기에 설치 가능한 development profile. Android adb 기기없음.
- APP63 최종 실기기 메뉴/자료/GA4·문의/History 아직 NOT_VERIFIED. 이전 GA4 격리수신 결과를63 검증으로 대체하지 않음.

## 검토용 SQL 패키지

실제 파일은 현재 worktree `.local/app63-readiness/`에 준비했으며 SHA256.json으로 고정했다. 아래 초기 패키지 중 TASK18 기반만 Owner 승인 후 적용 완료. TASK19 초기 SQL은 실행하지 않음. 작업 source SHA를 유지하기 위해 제품코드 변경 없이 기존 검증 후보를 그대로 사용한다.

### A. TASK18 기반 설치 (다운로드 개방 아님)

`task18-precheck.sql` → `task18-apply.sql` → `task18-postcheck.sql`.

새 private schema/pilot18/append-only 권한 이력, Guest 읽기RPC만 추가. 기존resources/content/student/원장 UPDATE 없음. permissions seed0: **모든 다운로드 PENDING 유지**. 적용시18개 대상 ID/URL 일치·신규스키마/RPC 부재 확인, 불일치 중단. 원복 `task18-rollback.sql`: 읽기RPC를 PENDING으로 닫고 승인 이력은 보존.

설치만으로 실제 다운로드가 활성화되지 않는다. resource-download Edge 배포와 파일별 권리근거·원본SHA256·파일명 검증/ALLOWED 승인은 별도다. 이번 요청은 Edge 배포나 일괄 파일 허용을 자동 승인하지 않는다. 권리 미확인 파일을 열지 않는다.

### B. TASK19 설치·자료 등록·공개

`task19-preflight.sql` → `task19-schema.sql`(트랜잭션) → `task19-seed.sql` → `task19-publish.sql` → `task19-postflight.sql`.

새 부가 조회 테이블/RPC·정확히2457개 참조행. 기존 시험/과목ID·채점표·학생기록 수정없음. 2212행 점수확인, 미확인경계245행 NULL. 원점수2092행/표준점수대체120행; 추정·미확정 상태를 임의 승격하지 않음. 초안은 미공개이며 **publish는 별도 명시 승인 범위**다. 기존행/다른revision/출처 불일치시중단.

원복 `task19-withdraw.sql`: 정확히 일치하는 후보를 withdrawn/non-current로만 변경, 삭제하지 않음. 기존 채점/Registry/History 유지. 검증:11시험·2457행·anon/authenticated 읽기만·사용자쓰기불가·실제 공개HTTP 및 APP 자료/학습 동일조회. schema/seed/publish는 단계별 트랜잭션; 중간실패시 다음단계 진행안함.

### C. 보존 검증

승인 직전 고정 cutoff를 기록하고 기존 원장·결제·평가·문의 행의 ID/건수/내용hash 기준선을 읽기전용 저장한다. 적용후 cutoff 이전 동일집합을 대조하고 새 운영행은 별도로 구분한다. 민감원문/키 출력·Git저장없음. 실행SQL은 새 기능 객체/후보행만 접근한다. 역할·RLS·기존조회 정의도 전후비교. 이상시즉시중단·새기능만닫기. 과거원장복원UPDATE/삭제는 하지 않는다.

## 실기기 승인 범위

iPhone12ProMax의 com.legendstudy.app을 기존58→63으로 **삭제없이 업그레이드 설치**하면 본앱 실행버전은 바뀐다. APP58 원본IPA/AAB/Archive는 그대로 보존하며 별도Math/PDFTEST앱도 유지한다. 기존58 기기설치 유지가 필요하면63 설치를 진행하지 않는다. 동일서명/번들 검증과 데이터 유지 확인 후에만 설치한다. 실제가입·평가·지급·차감·결제·환불·테스트답변은 실행하지 않는다.

설치후 Owner/기기 UI에서 기존로그인 유지·홈/자료/PDF열람·등급컷·LAB베타/자연상태·기존History·내문의답변을 확인하고, appVersion1.0.2 이벤트와 menu_id/content_item_id 수신을대조한다. 로그인/기기잠금/사용자입력이 필요하면 Owner에게 요청한다. Android 실제기기 부재는 NOT_VERIFIED 유지. 합성저장검증과 운영실자료다운로드검증을 구분한다.

## 승인 후 실제 적용·검증 (2026-11-05)

- Owner가 TASK18 기반(PENDING 유지)·TASK19 설치/2457행 공개·iPhone12ProMax 본앱63 업그레이드를 승인했다.
- TASK18: 정확한18 ID/URL 일치 및 객체부재 사전확인 후 `app63_task18_download_policy_foundation` migration 성공. pilot18, permission0, anon RPC PENDING, private schema USAGE=false 확인. Edge 배포·파일 ALLOWED0.
- TASK19: 운영의 anon/authenticated 모두 content_items/exams/exam_subjects SELECT=false. 초기 invoker 후보는 운영 조회에 실패하므로 schema/seed/publish 모두 미실행. 기존 권한 확대 없음.
- 수정 SQL은 `.local/app63-readiness/task19-schema-production-candidate.sql`: 신규 테이블 직접SELECT도 금지하고, 빈 search_path SECURITY DEFINER RPC에서 active Registry/과목·published/current/verified 조건을 직접 검사한다. 기존 서명·APP 코드 변경 없음. `task19-production-rollback.sql`은 RPC 실행권한만 회수하며 기존 withdraw 패키지는 자료 공개만 철회한다. 이 실행권한 변경안에 대한 Owner 승인을 요청했다.
- 운영과 같은 Registry SELECT 차단 조건으로 임시 로컬 PostgreSQL 검증 PASS:2457행·11시험, draft 은닉/공개조회/철회/직접조회·쓰기금지/비활성 은닉/중복·교차FK·불변근거·기존채점보존. TEST 파일 `.local/app63-readiness/test-production-schema.py`.
- 보호16테이블 pg_stat_user_tables의 insert/update/delete 누적 통계 적용 전후 동일. 전체행 내용해시 조회는 자동 승인 검토가 민감 파생데이터의 광범위 반출 위험으로 거절했고 우회하지 않았다. 통계 일치는 내용해시 동일 증명이 아니므로 전체내용 보존 대조는 NOT_VERIFIED. 실행 SQL은 기존 데이터 UPDATE/DELETE 없으며 실제 지급·차감·결제·환불0.
- iPhone12ProMax 본앱을 삭제 없이 기존 Archive로 설치·실행 성공. 설치조회 1.0.2(63), 별도 TEST62/PDFTEST1 유지. 로그인세션·PDF·문의답변·History 본문 UI는 Owner 확인 대기. Android 기기없음.
- GA4 APP 속성562560908 iOS stream에 appVersion/eventName/eventCount 조회 HTTP200, 기간11/4~현재 응답에 행 없음. 수집0으로 단정하지 않음(집계 지연 가능), 최종63 이벤트 수신 NOT_VERIFIED. 이전 DebugView 격리 수신을63 증거로 사용하지 않음.
- APP63 IPA/AAB 해시는 통합 receipt와 동일. APP58 IPA/AAB도 기존 해시와 동일. 빌드 소스9fb4ea3 대비 lib/ios/android/pubspec diff0, 재빌드·WEB 배포·Store 제출0.

### 다음 검수
수정 SQL 승인 후 TASK19 신규 객체만 적용·후보행 등록/공개·anon/auth HTTP조회·권한차단/운영통계 대조. Owner 실기기 기존 로그인/자료/PDF/등급컷/문의답변/History 확인 및63 GA4 이벤트 대조 후 RELEASE_READY 재판정. TASK18 실제 파일 다운로드는 별도 Edge/파일허용 전까지 PENDING으로 유지한다.
