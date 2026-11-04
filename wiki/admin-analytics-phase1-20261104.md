# 관리자 분석 개편 Phase 1 — 감사·설계 인수인계

2026-11-04. **AUDIT_COMPLETE / DESIGN_READY / OWNER_REVIEW_REQUIRED**. 이는 감사 산출물의 완료이며 운영 분석 기능 전체의 PASS가 아니다. 운영 DB·WEB·APP·GA4 변경 없이 코드, 운영 카탈로그/집계 SELECT, 로그인된 관리자 읽기 화면을 대조했다. 이번 요청은 이전 대시보드 배포 이후의 **별도 설계 단계**다.

## 결론

- 관리자 메뉴 **30개 / 6그룹** 전수 코드 감사. 이 중 일반 운영 6개(회원·이용권·결제·문의·자료 검수·공지)를 제외한 **분석·품질·베타 관련 24개**를 포함한다. 추가 연결 `/owner-review/essay/`와 학생 본인 경로 `/math-review/`는 별도로 조사했다. 메뉴 수는 독립 데이터 제품 수가 아니다.
- 완전히 같은 본문을 재사용하는 **4쌍**: analytics/overview, visitors/installs, members/students, essay-feedback/satisfaction. GA4 본문은 6개 URL에 반복된다. 다른 부분 중복은 [전수표](admin-analytics-inventory-20261104.md)에 기록했다.
- GA4 기존닷컴 보고서는 **CONNECTED**. LAB는 운영 화면에서 수집 비활성·보고서 미연결. 기존 v1 이벤트 31개 정의와 실제 수신은 다르다. 기존닷컴 앱 홍보 이벤트 3종은 보고서에 실제 수신됐으나 설치 완료를 증명하지 않는다.
- `admin_essay_beta_config/report`, `admin_essay_feedback` 등은 운영 카탈로그에 없고 베타 관리/오류 신고 UI에서도 미연결 오류를 확인했다. 운영 모니터링은 읽기 연결되지만 비용 추정 저장·경고 점검은 미연결이다.
- 일반 품질 RPC는 legacy `essay_evaluations`만 읽는다. 이 테이블 0건과 현재 회차 `runs` 56건을 혼동하면 안 된다. `/owner-review/essay/`는 **로그인 관리자 자신의 회차**를 조회하는 경로이며 전체 학생 품질 검수의 대안이 아니다.
- 수리 평가/전사·원본 연결·HQP 불변 검수 저장을 재사용할 수 있다. 회차/혼합형 품질 subject 연결, 검토→개선 과제→회귀→효과의 운영 기록은 보완이 필요하다. TASK16-L 저장을 새로 만들지 않는다.
- 운영 비용 view 185행 전부 비용·호출시각 미상이다. 이는 실제 청구 비용 0이나 전체 호출 포괄을 뜻하지 않는다. Math 전용 telemetry의 집계 범위도 보완해야 한다.

## 산출물 12개와 문서 위치

| 요구 산출물 | 위치 |
|---|---|
| 1 전수 감사 / 2 KPI·RPC·출처 / 3 중복 / 10 분류·보존 매핑 | [페이지 전수표](admin-analytics-inventory-20261104.md) |
| 4 GA4 역할·수집 조사 | [GA4 역할과 검증](admin-analytics-ga4-20261104.md) |
| 5 새 정보 구조 / 11 UI 아웃라인 / 12 Phase 2 | [정보 구조·화면·실행 순서](admin-analytics-design-20261104.md) |
| 6 품질 기능 / 7 데이터 계약 / 8 검토 프로세스 | [평가 품질 명세](admin-analytics-quality-20261104.md) |
| 9 핵심 지표 정의 | [KPI 사전](admin-analytics-kpis-20261104.md) |

## 검증 근거와 범위

| 증거 | 실제 확인 | 한계 |
|---|---|---|
| WEB 소스 | 배포 소스 `b0ed2b5eed6ab50c426e92e7d29b890399eafb1c`; navigation.ts·admin-data-page.tsx·admin-analytics.tsx·GA4 handler·각 client | 배포 파일 존재만으로 DB 설치를 추정하지 않음 |
| Production Supabase | 프로젝트 `stlhijzpjfgwwdgunlsd`, 11-04 16:35 KST 전후 pg_proc/pg_views/information_schema 및 제한된 aggregate SELECT | 관리자 JWT 위조/역할 SET 없음. DB 카탈로그는 실제 사용자 권한 E2E의 대체가 아님 |
| 로그인 WEB | visitors, overview, beta, essay-feedback, operations, ql 일반/수리, study 대표 경로 | 모든 필터·30개 URL의 개별 E2E를 완료했다는 뜻이 아님. 공유 구현으로 확인한 행은 전수표에 명시 |
| 기존 대시보드·Credit·문의 | 같은 날 승인 배포의 [대시보드](admin-dashboard-refresh-20261104.md), [Credit](credit-classification-20261104.md), [문의](feedback-admin-integration-20261104.md) 영수증 재사용 | 이번 감사에서 거래/답변 재실행하지 않음 |
| 최신 Analytics Wiki | `codex/analytics-phase1-wiki` HEAD `1bfc511`; analytics-v1-implementation-20261030.md / admin-integrated-analytics-task10.md / admin-data-task11.md | 과거 ‘미연결’과 이후 복구 기록의 시점을 구분. 현재 운영 확인 우선 |
| TASK16-L | APP 작업트리 `cc848f2`, 구현 `9d29f3b`; WEB `5375334`, TEST Preview `43aad34c` | TEST 보고서/코드 읽기 재사용. 이번 Provider·TEST 평가 실행 없음. Production 적용 아님 |

최신 다른 작업 문서의 고정 참조: [Analytics v1](https://github.com/LC3808/legendstudy-app/blob/1bfc511/wiki/analytics-v1-implementation-20261030.md), [TASK10](https://github.com/LC3808/legendstudy-app/blob/1bfc511/wiki/admin-integrated-analytics-task10.md), [TASK11](https://github.com/LC3808/legendstudy-app/blob/1bfc511/wiki/admin-data-task11.md), [TASK16-L](https://github.com/LC3808/legendstudy-app/blob/cc848f2/wiki/task16l-learning-persistence-history-20261104.md), [품질 실사례](https://github.com/LC3808/legendstudy-app/blob/cc848f2/wiki/task16-evaluation-quality-closeout-20261104.md). 로컬 해당 commit에서 읽었으며 원격 링크의 게시 상태는 이 감사에서 별도 검증하지 않았다. 다른 작업트리를 이 브랜치에 임의 통합하지 않았다.

## 운영 읽기 스냅샷

16:35 KST: legacy 평가0 / exam runs56(완료45) / Math evaluation13(COMPLETED12) / Math session runs2 / HQ 판단0·finding0 / 공부 세션22. `analytics_private.evaluations`56은 exam runs와 legacy의 union이며 **별도 Math 평가13을 포함하지 않는다**. Math session2와 evaluation13은 서로 다른 단위이므로 더하지 않는다. 업무 평가와 과거 검증용 기록을 식별하는 승인된 제외 계약이 아직 없어 전체 행 수를 ‘실제 학생 이용량’으로 명명하지 않는다.

비용 view185 / UNKNOWN185 / called_at NULL185. 비legacy attempt=1 호출22행인데 Analytics `reprocess_calls`는 `>1`만 센다. exam 영수증 attempt는0부터, legacy run_no는 별도 계약이어서 첫 재시도 누락 위험이 **코드와 운영 행으로 확인**됐다. 재첨삭(parent)과 기술 재시도(attempt/generation)는 별개다.

Math extraction24 / region239 / hint 저장0·노출0 / mixed hint0. `math_evaluations.learning_judgement` 운영 컬럼 없음, checkpoint의 직접 `payload.evaluation.learning_judgement` 경로0. 마지막 수치는 그 JSON 경로의 조회 결과이지 모든 JSON/TEST에 해당 자료가 없다는 증거가 아니다. 원본 답안/학생 identity는 감사 Wiki에 복제하지 않았다.

## 보존 검토 7개

1. 요청/완료/거래/검토/관측 시점을 별도 정의한다. 현재 프로필 학년을 과거 평가 당시 학년으로 바꾸지 않는다.
2. 기존 evaluation/run/question/attempt·Registry·Evidence digest·OCR/확정 전사를 연결 참조한다. 원본을 새 분석 테이블에 복제하지 않는다.
3. 과거 결과 UPDATE, 5단계 backfill, 불변 검토 덮어쓰기 금지. 정정은 기존 supersedes 방식 계승.
4. 기존 auth.users/profiles/credit_accounts 소유 연결 유지. 새 학생 ID 체계 없음.
5. 학습 활동, 운영 품질 판단, 자기보고 지원, 실제 Outcome을 구분한다. 학습5단계를 대학점수·합격 확률로 바꾸지 않는다.
6. admin_operator와 quality_operators의 역할을 합치지 않는다. 학생 원문은 품질 권한으로만, 집계는 최소 표본 및 삭제/제한 계정 정책 유지. 가명도 개인정보다. 새 수집/보존기간 승인 없음.
7. 파생 지표에는 formula_version·관측시각·출처·범위·분모·결측을 표시한다. GA4/서버 수치나 UNKNOWN 비용을 임의 합산하지 않는다.

## 작업 격리와 완료 검사

전용 브랜치 `codex/admin-analytics-phase1-20261104`, 시작 `a007705`. 현재 채팅 외 APP58/TASK16 및 결제 작업의 별도 작업트리와 채팅 상태를 읽기 확인했다. 조회 당시 idle 표시는 다른 환경의 변경이 없다는 보장이 아니며 해당 소스/브랜치는 수정하지 않았다.

이번 변경은 Wiki만이다. 운영 SQL 적용·배포·평가·Credit 지급/차감·결제/환불·실사용자 답변·GA4 설정 변경0. 문서 구조·링크·분류 수·Git diff를 검사했다. Task Routing 10개 PASS, current-status 11,871bytes로12KB 미만. 새 산출물 링크 오류0. 기존 Wiki 전체 검사에는 TASK16 사전감사 파일의 외부 상대경로20개 오류가 시작 시부터 있었으며 이번 산출물의 새 링크 오류와 분리한다.

Owner 검수 순서: 전수표의30개 분류 → 4영역 메뉴 및 기존 운영 보존 → 품질 검수 권한/대상 범위 → KPI의 주간 루프·무료 재첨삭·보류 분모 → Phase2 우선순위. 이 검수는 설계 승인용이며 운영 배포 승인은 포함하지 않는다.
