# 관리자 분석 Phase 2 — 운영 적용 기록

2026-11-04. **핵심 분석·회차 검수 SQL/WEB APPLIED / 전체 설계 수용 판정 PARTIAL**. Owner의 구현·격리 TEST·운영 SQL/RPC·WEB 배포 승인을 적용했다. [Phase 1](admin-analytics-phase1-20261104.md), [정보 구조](admin-analytics-design-20261104.md), [품질 계약](admin-analytics-quality-20261104.md), [KPI 사전](admin-analytics-kpis-20261104.md)을 계승한다. APP58 통합·앱 빌드는 별도다.

## 적용 범위

- `/admin/data/essay-usage/`: 회차 요청/완료·원본 과금 근거의 무료 재첨삭·동일 회원/시험/문항 집합의 주간 완료 루프·대학/시험 집계. KST 기간과 요청/완료 시각을 구분한다. 기존 회차 원본만 집계하며 별도 Math/legacy를 이중 합산하지 않는다. 환경 UNKNOWN과 표본 보호를 표시한다.
- `/ql/`의 **회차·혼합형**: 기존 전체 회차의 문항별 목록·페이지네이션·미검토 필터·선택 상세·불변 사람 검토·정정 이력. 원본 `run_id + question_id` 참조, fake legacy 평가 없음. 일반 legacy/Math 경로 보존. Math 상세 일괄 선조회 제거, 선택한 평가와 확인된 이전 평가만 조회.
- 기존 `human_quality_judgments`에 exam subject·검토 증거 링크를 추가했다. 새 hq-exam-rubric-v1은 기존 6개 이름의 판단 항목과 OK/CONCERN/FAIL 앵커를 사용하며 학생 학습5단계와 다르다. 문장/성장/모범재작성은 해당 양식 범위 밖 NA. 당시 기준·근거/결과 결측은 NEEDS_REVIEW만 허용. 별도 세부 target 판정이나 검토자간 일치도까지 구현됐다는 뜻은 아니다.
- 검토 저장은 Q allowlist + 운영자/대상 lifecycle, 고정 search_path, 원본 hash, 글로벌 멱등키, 정정 head 잠금/unique, append-only 및 원본 삭제 cascade를 유지한다. 저장된 검토에 issue/회귀 URL을 연결하지만 외부 issue 생성·원문 전송·정책 배포·학생 알림·평가 실행은 없다.
- `/admin/analytics/`: D 이용권·매출·비용의 기존 원장/결제/운영 조회 진입점. 새로운 재무 원장을 만들지 않는다. overview/installs/students/satisfaction 중복 본문은 기존 URL에서 통합 화면 안내로 교체하고 query string을 전달한다. 다른 기존 분석 URL은 유지한다.
- GA4 본문은 ga4 focus에서만 로드한다. 학생 학습 집계와 방문 통계를 더하지 않는다. 공부 시간 페이지에서 무관한 대학/지원 순위 표를 제거했다.
- `analytics_api_cost`: exam attempt>0, legacy run_no>1로 첫 기술 재시도 누락을 수정. 전부 미상인 토큰/비용을 0으로 바꾸지 않는다. 비용 view 자체와 Provider 호출 정책은 변경하지 않았다.

## 보존과 배포

SQL hosted versions: **20261104091805** quality, **20261104091837** learning/cost. 저장소 파일명은 CLI 생성 시각인 085951/090610이다. 이미 설치됐으므로 재실행 금지. learning 적용 전 cost baseline MD5를 검사했다. 최초 guard 문자열 포장 오류는 구문 검사에서 실패해 적용되지 않았고 수정 후 성공했다.

WEB source **119caeadfe9057a666169ec9e4ce21cf5364b73e**, Pages **1312670e-30c4-4c58-b4cd-a375ca2b6668**, 18:20:33 KST success/canonical. 이전 Pages **4b089f75-b118-48a9-92d6-77a5ce1ed584**. 정적 교체 범위는 `/admin/data/*`, `/admin/analytics/*`, `/ql/*` 및 새 hashed assets. **기존 대시보드·문의·이용권·결제 및 학생 화면 산출물은 보존**했다. 따라서 그 화면의 기존 사이드바는 기존 배포 구성이다. 모든 관리자 화면의 공통 메뉴가 일괄 바뀐 것은 아니다.

운영 공개 빌드 설정 6개, 전체 운영 설정 49개와 대상 외 manifest 보존. 기존 API 기준 `a901568fa7b0acc752061d6fd7361ad5772875c8`의 Functions/Cloudflare/lockfile diff0, 입력138개, 운영 라우팅 동일. Worker는 같은 소스에서 재빌드했으므로 이전 번들 byte hash와 같다고 주장하지 않는다. 신규 bundle SHA256 `f71a235fb57c529b523ff579e74190eec52cb582cdb8b97aeb4b4110f4e3fe81`. 원래 임시 WEB clone 소실을 확인하여 이번 소스는 관리 작업트리와 원격 전용 브랜치 및 [patch](../supabase/candidates/admin_analytics_phase2_20261104/web.patch)에 보존한다.

| 원본 | 적용 전 | 적용 후 |
|---|---|---|
| Credit 거래 | 284행 · `73cb5604029fcec6289537e25e3f939f` | 동일 |
| 평가 회차 | 56행 · `600880b2a5f3394c010e5f753a102ee5` | 동일 |
| 사람 검토 | 0행 | 0행 — 운영 시험 저장 없음 |

신규 public RPC4개 모두 authenticated EXECUTE만 허용, anon/service_role=false. 실제 역할은 함수 내부 기존 A/Q gate에서 추가 검사. 기존 RLS 정책/allowlist 변경0. Security advisor의 기존 항목 유지, authenticated definer 목록은 신규4개로127→131; 이것을 공개 원문 허용으로 해석하지 않는다. [Supabase advisor 설명](https://supabase.com/docs/guides/database/database-linter).

## 검증 결과와 한계

- 격리 임시 PostgreSQL 합성 테스트 PASS: 실제 HQ validator/불변 trigger와 신규 RPC, 원본 ID/공식 label, 조회/저장, 같은 키 replay·변경 충돌, stale hash, 정정 head 충돌, 권한/lifecycle 거절, 원본 해시 보존, 삭제 cascade, 5명 표본 보호, 비용 retry 0/1 기준, UNKNOWN 비용/토큰.
- WEB 품질 회귀34 + 신규 회차 UI2 = **36 PASS**. 선택 전 답안 미조회, 원문 상세/이력 회귀, 계정 전환 정리, 저장 버튼 확인 전 비활성, 권한 오류와 빈 목록 구분. lint 및 TypeScript PASS, **163경로 Webpack build PASS**. Turbopack은 외부 node_modules symlink 제한으로 사용하지 않았다.
- 운영 실제 관리자 세션 READ PASS: 회차 문항 **85건**, 첫50/다음35 페이지, 기존 인하 평가 상세의 당시 답안·기준·결과·검토 양식 연결. 검토 저장/실사용자 답변은 실행하지 않았다. 학습 집계 SUPPRESSED 및 학습5단계 NOT_CONNECTED 표시, 비용 진입점 확인.
- 로컬 DB/UI 테스트를 hosted TEST Gateway 또는 실제 Provider E2E로 부르지 않는다. 1280/1440/1920 및 태블릿/200% 확대 전체 행렬은 미완료다. 현재 데스크톱 화면은 시각 확인했다. Wiki handoff routing10개 PASS, current-status11,899bytes, 신규 링크 오류0. 기존 TASK16 외부 상대경로20개 오류는 유지되어 전체 checker는 FAIL이다.

## 전체 설계의 잔여 GAP

1. 별도 Math/legacy까지 통합한 활성/최초완료/NSM 및 정책 호환 학습5단계 비교는 아직 전체 통합하지 않았다. TASK16-L의 승인된 운영 저장 연결 전에는 NOT_CONNECTED이며 값 추정·backfill 없음.
2. 베타 설정/평가 신고의 기존 미설치 RPC 복구, 운영 monitoring의 raw beta 분류, 정교한 품질 후보 detector·정책 비교·회귀 상태 집계는 이번 배포에서 해결되지 않았다. 오류/미연결 상태를 성공0건으로 바꾸지 않았다.
3. 회차 원본 사진의 별도 권한 임시열람, OCR/확정전사 전용 비교 UI, source/대학/정책별 고급 검색과 전체 품질 coverage는 후속 보완 필요. 이번 상세는 저장된 answer/input/result/criteria/version 참조를 그대로 표시한다.
4. 모든 관리자 화면의 공통 메뉴 통일과 12 MERGE URL 전체 통합은 부분 적용이다. 이전 대시보드/이용권/문의의 소실된 WEB 소스를 복원하지 않은 채 이전 기능을 덮어쓰지 않도록 원본 배포 산출물을 보존했다.

이는 운영 배포 성공과 전체 Phase 2 완료를 구분하기 위한 기록이다. 실제 지급·차감·결제·환불·Provider 실행0, 학생 결과 변경0, 운영 검토 시험 저장0, APP58/앱 빌드0.

## Owner 검수

1. [논술 학습 분석](https://lab.legendstudy.com/admin/data/essay-usage/)에서 기간/표본 보호/출처 확인.
2. [품질 관리](https://lab.legendstudy.com/ql/) → 회차·혼합형 → 검토 시작. 원본/결과 확인 후 실제 업무 판단일 때만 저장. 테스트 판정은 운영에 작성하지 않는다.
3. [이용권·매출·비용](https://lab.legendstudy.com/admin/analytics/)에서 기존 원장/결제/운영 조회 이동.
4. 복구 시 [패키지](../supabase/candidates/admin_analytics_phase2_20261104/README.md)대로 이전 Pages로 복귀하고 새 RPC 접근만 회수. 추가된 검토 기록·columns를 삭제하지 않는다.
