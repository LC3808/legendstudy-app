# 관리자 페이지 전수 감사·기능 보존표

[Phase 1 인수인계](admin-analytics-phase1-20261104.md). 기준: 2026-11-04 운영 WEB navigation30개. `U`=이번 로그인 화면 실수신 확인, `C`=운영 DB 카탈로그/정의 확인, `S`=소스 확인, `R`=같은 날 기존 배포 영수증. U가 없는 URL의 개별 화면 성공을 주장하지 않는다. `A`=기존 admin_operator(관련 lifecycle 검사 유지), `Q`=quality_operators, `O`=본인 소유권. 기간 `W`=KST [시작00:00, 종료 다음날00:00), max400일. `M`=현시점 projection. 각 행의 소스와 아래 RPC 사전이 집계 기준의 일부다.

## 30개 URL과 분류

| # | 메뉴·실제 URL | 목적·현재 KPI / 출처·RPC | 기간·권한·연결 | 판정 → 보존할 기능·목적지 / GAP |
|---|---|---|---|---|
| 1 | 대시보드 `/admin/` | 회원·학교/학년·기록 공부시간·요약; D/L/C/P/S | W 기본30일, 회원M·활성30일 고정; A; R+C | REDESIGN → A 서비스 현황. 최신 작은 카드·정의 보존, 활성 정의 통일 |
| 2 | 회원 `/admin/members/` | 계정/프로필 검색·학년/학교/상태·Student360; M | M·offset; A; R+C | KEEP → 기본 운영 회원. 개인정보 상세 권한 유지 |
| 3 | 이용권 `/admin/credit/` | 유형별 지급·예약·소비·해제·보유; C | W/회원·유형·거래필터/5건page; A; R+C | KEEP → 기본 운영. D의 원장 드릴다운 재사용 |
| 4 | 결제 `/admin/payment/` | WEB 주문·상태·IAP 지급; P | 주문조회/검색·offset, 보고기간; A; R+C | KEEP → 기본 운영. TEST/LIVE·KRW/기타 분리 |
| 5 | 사용자 행동 분석 `/admin/analytics/` | kpi/funnel/revenue/cost/university +GA; V/G | W 기본7일; A; S+C(동일본문 U #15) | MERGE → A 및 GA 참조. URL 유지, 서버 학습을 행동 이벤트로 부르지 않기 |
| 6 | 평가·비용 모니터링 `/admin/operations/` | 요청·성공·실패·재처리·원장·토큰/비용; E | 오늘 기본/max93일/25건, 이전 legacy keyset; A; U+C | REDESIGN → 운영 기능 유지, C 품질·D 비용에서 링크. readonly:true/추정·경고 미연결, beta 출처 분류 불일치 |
| 7 | 베타 테스트 관리 `/admin/beta/` | 캠페인/한도/버전/감사25; B | 설정M; A; U+C | KEEP → 운영 설정 유지. config/report/save RPC 없음, 미연결 오류. 실제 베타 정책 미작동을 뜻하지 않음 |
| 8 | 베타 이용 현황 `/admin/beta/usage/` | 참여자·무료/유료·회차; B | 누적기본/from/to(to exclusive)·25건; A; S+C | MERGE → B 학습의 베타 필터. RPC 없음, URL/필터 보존 |
| 9 | 평가 실패·복구 `/admin/beta/failures/` | 실패/예약/정산·복구; B | 위와 같음; A; S+C | MERGE → 운영 #6 장애 탭. 원장과 실패이력 보존, RPC 없음 |
| 10 | 피드백·오류 신고 `/admin/essay-feedback/` | 평가별 의견/이진만족/오류·상태; F | 직접조회, 시작포함/종료다음날미만·offset; A; U+C | REDESIGN → C 신고 접수. 읽기/상태변경 RPC 없음. 일반 문의와 별도 계약 |
| 11 | 공지사항 `/admin/notices/` | 목록·게시/수정; N | M·기존 관리필터; A; S+C | KEEP → 기본 운영. 분석으로 이동하지 않음 |
| 12 | 1:1 문의 `/admin/inquiries/` | APP/WEB 통합 문의/답변·미처리; S | 접수일 desc·검색/유형/상태·offset; A; R+C | KEEP → 기본 운영. 원본2종·답변·알림 유지, 평가신고를 자동복제하지 않음 |
| 13 | 첨삭 품질 `/ql/` | 사례/불변 검토/근거·원문·비교; QL | keyset50/max100·미검토 loaded 범위; Q; U+C | REDESIGN → C 핵심. 일반 목록0/Math 읽기됨, 회차 누락/메타데이터 불완전 |
| 14 | 논술 자료 검수 `/admin/materials/` | 대학/시험·공식원본·검수revision; T | M·대학필터; Q 기반 별도검사; S+C | KEEP → 기본 운영 전용 검수. 업로드/분석/승인 기능 보존, 이번 미실행 |
| 15 | 통합 분석 `/admin/data/overview/` | #5와 동일 V/G 전체 | W7; A; U+C | MERGE → A `/admin/`. 임시 호환 URL 유지 |
| 16 | 방문자·유입 `/admin/data/visitors/` | GA 방문·세션·PV·채널·페이지·promo; G | W7→GA inclusive/속성timezone; A; U | KEEP → GA4 참조. Data API 유지, LAB미연결 표시 |
| 17 | 가입·전환 `/admin/data/conversion/` | kpi/funnel/revenue +G | W7; A; S+C | MERGE → GA 행동 퍼널 참조 + A 서버 확정 코호트. 순차 전환율로 오해 금지 |
| 18 | 앱 설치 유입 `/admin/data/installs/` | #16과 같은 G, 설치NOT_AVAILABLE | W7; A; S(동일본문U #16) | MERGE → #16 앱홍보 구역. 클릭/설치 분리, URL 유지 |
| 19 | 학습·입시 종합 `/admin/data/learning/` | targets/saved/recent/applications/study6지표; L | W30·top10·최소5; A; S+C | REDESIGN → B의 기타 학습·진학 탭. 자기보고·현재projection 한계 보존 |
| 20 | 대학 선호도 `/admin/data/universities/` | L 전체6지표 + targets순위 | W30; A; S+C | MERGE → #19 목표대학 탭. 실제 논술 대학이용과 별도 |
| 21 | 인기 시험·자료 `/admin/data/materials-data/` | L 전체6지표 + saved/recent | W30; A; S+C | MERGE → #19 자료 탭. recent는 학생·자료 쌍, PV아님 |
| 22 | 공부 시간 `/admin/data/study/` | L study_users/study_ms +무관한4종순위 | W30; A; U+C | REDESIGN → #19 공부 탭. ms 표시 개선, dashboard study 집계 재사용 검토 |
| 23 | 성적·학습 `/admin/data/scores/` | NOT_IMPLEMENTED 안내; academic_performance null | 해당없음; A; S+C | DEPRECATE_CANDIDATE → 메뉴 정리 검토, URL 안내 유지. 점수자료 신규수집 승인 아님 |
| 24 | 입시 지원 `/admin/data/applications/` | L 전체6지표 + 자기보고지원순위 | W30; A; S+C | MERGE → #19 지원 탭. 합격/등록 Outcome으로 해석 금지 |
| 25 | Student360 `/admin/data/students/` | #2 AdminMembersView 동일 | M/검색·offset; A; S+C | MERGE → 회원 상세. 북마크/개인별조회 유지 |
| 26 | 개인화 인사이트 `/admin/data/insights/` | L +저장자료 DRAFT문장1개 | W30; A; S+C | DEPRECATE_CANDIDATE → 실험/준비중 안내로 보존. 저장/승인/발송 없음 |
| 27 | 논술 LAB 이용 `/admin/data/essay-usage/` | university/cost +G | W7; A; S+C | REDESIGN → B 논술 학습 분석. 최초/재첨삭·문항·5단계 구분 부족 |
| 28 | 사용자 답안 샘플 `/admin/data/samples/` | QL/Owner review 링크만 | 자체데이터없음; A→Q/O; S | MERGE → C 검토 목록 입구. 권한을 링크로 확대하지 않음 |
| 29 | 만족도·피드백 `/admin/data/satisfaction/` | #10 AdminEssayFeedback 동일 | #10동일; A; S+C | MERGE → C 신고/경험 탭. 이진값을1~5점으로 환산 금지 |
| 30 | 베타 검증 결과 `/admin/data/verification/` | NOT_TESTED 정적안내·베타/실패링크 | 기간없음; A; S | REDESIGN → C 회귀 증거 인덱스. 자동 테스트와 실제 E2E 구분 |

분류 합계: **KEEP8 / MERGE12 / REDESIGN8 / DEPRECATE_CANDIDATE2 =30**. 분류는 제안이며 이번에는 메뉴/URL을 변경하지 않았다.

### 별도 연결 경로

- `/owner-review/essay/`: 실제 본인 답안·재첨삭 비교, GET `/api/owner-review/essay` → auth user + admin_operator → `essay_exam_history`. **본인 account_id, 최근50회차**. feedback 경로는 `admin_essay_feedback_result`를 요구하지만 현재 운영에 없다. 전학생 회차 검수 권한을 제공하지 않는다(S+C). 화면에서 다른 학생 ID를 시험해 우회하지 않았다.
- `/math-review/?evaluation=...`: `OwnerArea` + `ServerCoaching`, 학생 본인 결과 화면(S). 관리자 품질 페이지가 아니다. `/ql/` 수리 소스의 qlm_quality와 구분한다.
- Native `/my/admin/analytics`: 기존 Analytics v1의 별도 소비자. WEB30개에는 포함하지 않으며 APP58/후속 빌드 범위에서 계약 호환 검증 필요.

## RPC·데이터 출처 사전

| 코드 | 호출 / 원천 / 집계 단위 및 연결 |
|---|---|
| D | `admin_dashboard`, `admin_dashboard_study`, `admin_learning_summary`, `admin_release_report`; auth.users/profiles, study_sessions, Registry 공개범위. 계정≠profile, 게시≠실행허용. 학년은 현재profile |
| M | `admin_member_list/search/detail`, `admin_student360`; auth.users/profiles·학교코드·기존학습/지원/원장. 목록 페이지와 전체계정수 구분 |
| C | `admin_credit_member_list/snapshot/member_credit/report`; credit_accounts/grants/transactions +지급분류helper. `credit-report-v2`의 grant 최초reason/일일연결로 beta 분류; reserve와 consume 이중소비 금지 |
| P | `admin_payment_orders`, `admin_mobile_purchase_report`, `analytics_revenue`; payment_orders/payment operations 및 IAP 지급 근거. IAP 과거 금액/통화/환경 결측, 구매지급을 매출로 환산 금지 |
| S | `support_metrics`, `support_admin_list/detail/reply/status`; inquiries+feedback_submissions 및 원본별 답변/처리정보. legacy admin_inquiry_*만 쓰는 계약과 구분 |
| N | `notice_editor_capability`, `notice_admin_list/save/save_rich`; 공지 게시 상태. 조회/수정 운영 기능 유지, 학습 KPI 없음 |
| V | `analytics_kpi_overview/funnel/revenue/api_cost/university_usage`; analytics_private sessions/attempts/evaluations(legacy+exam), essay_ops_private.calls, auth.users, credit/payment. free_credit/reliability도 기존RPC 있으나 이 본문은 직접 표시하지 않음 |
| G | GET `/api/admin/ga4` → 기존 GA4 Data API; 고정property396674471/mainstream5829568136·host. 관리자 server검증, no-store. 6페이지 중복읽기 |
| L | `admin_learning_analytics`: profiles + student_target_universities/bookmarks/recent_views/student_applications/study_sessions. top10·5명 threshold, 현재남은행기준. 공부는 기간잘림+사용자별interval union, ended기록/합산대상 |
| E | `admin_essay_operations(p_from,p_to,p_filters,p_offset,p_run)` → runs/checkpoints/retries+Ledger+cost view. legacy overload/`admin_math_operations`/`admin_operations_summary` 별도존재. request코호트와 transaction발생일 혼합 섹션 명시 |
| B | `admin_essay_beta_config/report/save` 운영 **없음**. 파일/위키 후보 존재를 적용으로 간주 금지. 조회용report 부재와 실제 일일무료 서버정책은 별개 |
| F | `admin_essay_feedback/update`, `admin_essay_satisfaction`, `admin_essay_feedback_result` 운영 **없음**. 일반 APP feedback 원본 저장·문의 통합과 동일 시스템으로 오인 금지 |
| QL | `ql_list_cases/case_detail`, `ql_review_state/list_human_judgments/submit_human_judgment`; legacy평가·HQP. Math는 `qlm_quality` read actions→qlm_* +math tables, 같은HQP 판단/FK 재사용. 실제 쓰기시험 없음 |
| T | `essay_material_list/detail/documents/save/register` +`/api/materials/analyze`; 공식자료/Registry·essay_material_private.reviews. 분석은 Provider 호출 가능하므로 이번 실행금지 |

## 중복·오해·오류 우선 목록

1. 본문 완전중복4쌍과 GA4 6회 반복을 공통 목적지/탭으로 통합. 현재 단순 링크뿐인 samples도 동일 검수 입구로 연결한다.
2. L6개 페이지의 큰 범용 카드가 각 페이지와 무관한 지표를 반복한다. study에는 targets/saved/recent/applications 순위까지 나온다. 지표 정의는 같아도 목적에 맞는 표를 선택해야 한다.
3. dashboard 활성은 study_sessions 최근30일, Analytics 활성은 제출/완료 trailing1/7/30일. 같은 ‘활성’ 이름으로 비교 금지.
4. ‘전체 루프’는 현재 가입코호트 이후전체기간 도달 수이며 새 주간완료학생 NSM이 아니다. 무료완료사용자는 무료최초·재첨삭 혼합이다.
5. 품질 일반0은 서비스평가0이 아님. 독립 Math 평가와 exam parent/child 중복·포함 여부를 명시해야 한다.
6. costs 시각미상·미상금액 및 Math누락, retry0/1base 혼재. 서버 완료율100%를 정확도100%로 표시 금지.
7. operations의 `essay_beta_daily` origin 직접검사는 실제 `promotion + essay_beta_daily reason/binding`과 불일치. 11-04 운영 Credit분류helper를 읽기집계에 재사용해야 한다. 원장 source 변경 금지.
8. 학습EMPTY/SUPPRESSED를 개별metric null 하나로 합치는 현재계약, 성적NOT_IMPLEMENTED/검증NOT_TESTED/설치NOT_AVAILABLE를 [새 상태계약](admin-analytics-kpis-20261104.md)으로 명확히 투영한다. 근거 없이0으로 바꾸지 않는다.

## URL·권한 보존 조건

Phase2에서 기존 URL을 같은 authenticated shell의 호환 진입점으로 유지한다. 승인 전 영구redirect/삭제 금지. query/filter/page·선택member/run/source를 가능한 그대로 전달하고 지원불가필터는 안내한다. 403을 빈0으로 바꾸지 않고, Q권한이 없는 A사용자의 품질 원문 접근은 기존대로 거절한다. 모든30행과 추가경로의 이전/이후 기능 매핑·북마크·키보드·권한 회귀가 통합 완료 조건이다.
