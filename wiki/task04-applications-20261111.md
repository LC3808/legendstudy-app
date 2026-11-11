# 작업04 — 실제 지원 대학 관리 / 공식 일정 조사

2026-11-11. IMPLEMENTED / OWNER_REVIEW_REQUIRED / 릴리스 미통합.
최신 메시지의 “실제 지원부터 구현, 일정은 조사·보고”를 이번 실행 범위로 적용했다.
첨부 통합 지시서 전체의 홈 일정/푸시/추가 온보딩 기능까지 완료했다는 의미가 아니다.

## 기준·통합·보존 (보고 1–8)

- 기준 APP75 build source `c9b483018bcada179050595cf78c8ca4a3d213ba`, 최신 검증문서 HEAD `633f982`.
- 별도 `codex/task04-applications-app75` 생성. 기존 worktree 재사용, 기존 미추적 .temp/__pycache__ 보존.
- 온보딩 d00ec696/74815f64 및 MY30edf235는 이미 APP75 조상. 재병합0.
- APP75의 닉네임 단계/검색 guard/Claude UI 후속 그대로 유지. 학교·온보딩·학습·채점·Auth 소스 변경0.
- MY 고3(student+3)/N수(retaker)에 ‘실제 지원 대학 관리’ 진입만 추가. 고1/2/기타/미설정/읽기실패/게스트 숨김.
- 학년 변경은 기존 지원 기록을 삭제하지 않는다. 재온보딩/필수 입력 없음. 신규 온보딩 등록 제안은 후속 범위.
- 프로필 수정 페이지 등 옛 파일로 덮어쓰지 않았다. [기존 대학 관리 정책](my-college-management-20261026.md)과 [APP75](task03-result-ux-20261111.md) 계승.

## 지원 구현 (보고 9–11,15–16)

Native MY 목록 → 대학 검색/선택 → 학년도·수시/정시·모집단위·전형·상태 입력.
기존 대학 Catalog를 재사용한다. 관심 대학을 실제 지원으로 자동 변환하지 않는다.
기존 기록 수정 시 revision/학년도/기존 모집구분을 보존한다. 목록 새로고침과 실패 재시도 제공.
지원 등록과 첫 상태는 기존 두 RPC로 저장하므로 원자적 트랜잭션이 아니다.
지원 저장 성공·상태 실패 시 부분 성공을 안내하고 같은 지원 ID/상태 요청키로 재시도한다.
삭제는 이력 포함 삭제 확인 후 기존 RPC 호출. 이력은 전체 페이지 읽기, 상태 변경은 append,
잘못된 결과는 supersedes로 정정하며 이전 기록도 표시한다. 합격→등록은 합격 이벤트를 지우지 않는다.
발생 시점은 임의로 현재 시각을 쓰지 않고 NULL(미입력), 서버 recorded_at와 분리한다.
현재 UI는 발생 일시 입력을 제공하지 않는다. 예비/예비번호는 기존 event enum에 없어 제공하지 않는다.

WEB과 동일한 my_applications/my_application_save/my_application_event/my_application_events/my_application_delete 사용.
계정 ID 일치 전후 검사, 계정 변경 시 편집 내용 표시 중단, busy guard 및 변경된 payload별 request_key.
실패 후 같은 payload 재시도는 같은 key를 재사용한다. 키 멱등성은 의미상 중복 판정과 별개다.
동일 사용자+학년도+대학+모집+모집단위+전형 중복은 기존 서버 lock 내 비교로 처리하며
23505는 중복 안내,40001은 새로고침/재편집 안내. 다른 학과/전형/모집/연도는 기존 계약상 허용.

운영 SELECT만 수행하여 함수 존재 및 정의 해시 확인:
my_application_save **65edac758433cde4a123b95be3da42ee** — [APP75 적용 영수증](app67-learning-integration-20261111.md)과 동일.
나머지 함수도 존재 확인. 실제 회원 CRUD/쓰기 RPC 호출0. APP↔WEB 실제 저장 동기화는 NOT TESTED.
새 schema/RPC/후보 SQL 없음. 기존 중복 방지 재적용 필요 없음.

### 7항 보존 검토

1. 자기보고 지원/결과의 occurred_at와 recorded_at를 구분한다.
2. 기존 created/details_changed payload와 event 원본을 재사용, 과거 사실 추정 없음.
3. revision 변경·event 정정을 구분, 합격 이력 단일 UPDATE 금지. 기존 삭제 RPC는 이력도 삭제하므로 확인 필요.
4. 기존 auth.users/profile identity를 유지, 학년 변경은 소유자/과거 기록을 바꾸지 않음.
5. 관심·실지원 Decision·Outcome·자동채점 Learning을 혼동하지 않음.
6. 본인 기존 RPC/RLS만 사용, 새 analytics/수집/공개 없음.
7. 최신 상태/D-Day는 파생 표시, 원본 성적·결과에 기록하지 않음.

## 발표 일정 조사·계약 후보 (보고 12–13)

**홈 일정·자동 매칭은 미구현**, 이번 요청대로 공식 출처·연결 구조 조사만 수행.
[서울대 공식 2027 수시 안내 페이지](https://admission.snu.ac.kr/undergraduate/early/guide)와
[공식 모집요강 PDF](https://admission.snu.ac.kr/webdata/admission/files/2027susi.pdf)를 11/11 확인했다.
인쇄2쪽(PDF6번째)의 일반전형(음악 제외) 1단계는11/20 18시 이후,
인쇄3쪽 음악대학은10/8 18시 이후로 서로 다르다. 변경 가능 주석과 단과대 공지도 존재한다.
이 자료는 후보 조사 근거이며 현재 확정 일정 전체를 수집/검수/배포한 것이 아니다.
서울교대 공식 PDF는 검색에서 발견했으나 본문 fetch timeout으로 채택하지 않았다.
검색된 대학원/template 페이지는 학부 지원 일정으로 채택하지 않는다.

연결 후보:
- source_document: 공식 URL, 대학, 제목/학년도, 발행·확인 시점, 문서 해시/보존 사본, 페이지·정정 출처.
- schedule_revision: 학년도+university_id+모집+검증된 전형 키+모집단위 적용/제외 범위,
  일정 유형/차수, 시작·종료, Asia/Seoul, 시간 정밀도(date/exact/after), 원문·source ID·supersedes.
- mapping: 사용자 입력 자유문자열 → 검수된 전형/모집단위 key. 유사 문자열 자동 확정 금지.
  exact mapping 없음/여러 후보/출처 미확인/폐기 revision이면 ‘발표 일정 확인 중’.
- 지원 ID는 기존 것을 사용하고 일정 출처/버전과 연결. 지원 결과를 일정 도래로 자동 생성하지 않음.
- 변경 시 이전 revision을 유지하고 최신 유효본으로 재계산. ‘18시 이후’를18시 정각 확정으로 바꾸지 않음.
- 홈 최근3건/D-Day는 기존 KST 계산 재사용 후보. 기존 day_targets는 application/source/round 관계가 없으므로
  label 문자열로 연결키를 대체하지 않음. 새 저장 구조는 후보 설계 검토 후 별도 승인.
- 푸시 고려용 event ID/revision/timezone만 설계에 포함, 발송/예약 구현0.

## 검증·제한 (보고 14,17)

- 지원 관리 집중 **11 PASS**: 노출/계정 변경/페이지네이션/멱등키/상태 append·정정/API payload/360px 큰 글씨/부분 성공 재시도.
- 정적 분석 `dart analyze lib test`: **No issues found** (Flutter3.47.6 SDK).
- 전체 테스트 1차 **2,470 PASS / 8 SKIP / 5 FAIL**. 최종 재실행 결과 아래 추가.
- 5개 실패는 APP75 원본633f982를 임시 경로로 추출해 별도 패키지에서 재현: **56 PASS / 동일5 FAIL**.
  grade_runner_navigation의 ‘다시 학습으로’와 mobile_ia_render mock 과목 선택 key를 찾지 못하는 기존 기대값 문제.
  해당 학습/채점 구현이나 기존 검사를 임의 수정하지 않았다. 전체 green을 주장하지 않는다.
- iOS profile/no-codesign·Android debug 1차 빌드 PASS, 최종 소스 재빌드 결과 아래 추가. 서명/설치/배포0.
- Wiki checker/diff check PASS. 로그 `/tmp/task04-{tests,analyze,full-final,baseline-tests-correct,ios-final,android-final}.log`.
운영 사용자 데이터 생성/수정/삭제0.
실기기 iPhone/Android, 실제 JWT 저장/APP↔WEB 재조회, 취소·복귀 실사용: **NOT TESTED**.
APP75 설치/서명본을 덮어쓰지 않고 로컬 unsigned/profile·debug만 사용한다.
후보76은 스토어 예약/정식 APP76 출시가 아니다.
운영 DB/RPC/릴리스 merge/스토어 제출/푸시/결제 변경0.

## 파일·Git·Wiki·후속 (보고 18–20)

lib/features/applications/application_repository.dart, applications_page.dart,
lib/features/profile/presentation/profile_page.dart, test/application_management_test.dart 및 Wiki.
최종 SHA는 완료 응답/Git 로그 참조. 현재 브랜치에서 로컬 commit만, push/merge 없음.
Owner 검수: MY 고3/N수 노출 → 동일 대학 다른 전형2건 → 완전 동일 중복 → 수정 충돌/재시도 →
최초합격→등록→이력 보존 → 잘못된 결과 정정 → 삭제 취소/확인 → APP/WEB 재조회.
기존 학교 변경/로그인/자동채점/학습 타이머도 동일 기기에서 회귀 확인.
일정 저장/전형 매핑은 별도 설계 검토 후 진행. 현재 지원 관리에는 추가 운영 SQL 필요 없음.

최종 재실행: 전체2,471PASS/8SKIP/동일5FAIL, 집중11PASS, analyze PASS, iOS profile PASS. Android debug 1차PASS, 최종 재빌드 진행. 확장 지시 후 홈 개인화는 별도 후속 commit으로 계속한다.
