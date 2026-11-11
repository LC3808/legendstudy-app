# LegendStudy Wiki Index

[APP67 논술 공개 상태 · 출시 보류](app67-essay-admission-20261106.md)

[APP66 최종 빌드·운영 검증·스토어 인계](app66-final-release-20261106.md) · 실기기 최종 검수 진행.

[TASK08 통합·격리 검수·Analytics 계약·Owner 대기/HOLD](essay-beta-integration-task08-20261101.md).
[2026-11-01 TASK07 최종 통합 검수·HOLD·버전/자동/실환경 구분](essay-beta-release-readiness-task07-20261101.md).

[10/31 최종 피드백 UX·빈 재작성·명시적 원본 불러오기·Draft 보존·검증/미완료](final-feedback-ux-refinement-20261031.md). 학생 중심 결과 정책의 후속이며 평가·과금·이력은 유지한다.

## 학생 결과 표시·작성 가이드 라우팅

[학생 중심 첨삭 결과 정책·구현·검증·미완료](student-centered-essay-feedback-20261031.md) (APP/WEB 결과·기존 데이터 매핑·출력 확장 설계·검수 환경)

최신 마감: [외대·건국·서강 신규54 STANDBY / Owner QA·미완료·SQL·복구](essay-standby-expansion-20261026.md). [기존4대학82 인수인계](essay-handoff-20261025-final.md) 보존. 추가 개발 중단, Mac 종료는 Owner 담당.


P0 Claude 최종 인수인계(사용량5% 중단): [현재 배포·37묶음·17후보·재개순서](essay-lab-claude-handoff-20261024.md).


This directory is the canonical long-term development knowledge base for LegendStudy.

## Read order

1. `../AGENTS.md`
2. This Task Routing Map
3. [Current Status](current-status.md)
4. [Durable decisions](decisions.md)
5. [Product scope](product-scope.md)
6. Required task-domain documents below, then actual code/runtime/tests.

Search all Wiki with Korean/English aliases before proposing a new concept.
Newest explicit Owner decisions supersede historical scope; record exact scope,
not an inferred promotion of a whole roadmap. Current is not historical evidence.

## Task Routing Map

[자연·수리 대학별 순차 작업](essay-natural-sequential-order-20261112.md): 한양·중앙·고려·인하 재작업 제외. 한국항공→건국→경희→성균관→서강→숭실→숙명여대→동국→광운→서울여대. 현재 한국항공 NOT SERVICE READY: HOLD5/운영 승인/Owner 검수 접근 제어 대기. 단독7문항106행 DRAFT 승인 후보·격리55 PASS;후순위 착수0. 로컬 검증만으로 완료/다음 대학 진행 금지.

[이전 확장 감사와 범위 이력](essay-connection-owner-verification-20261111.md) · [공식 불일치·원문 보존·중앙 과학11 HOLD](essay-natural-expansion-20261111.md).

작업04 / 고3·N수 실제 지원 대학 / 합격 발표 일정: [04-C 실계정·기기 검수](task04c-device-verification-20261111.md) · [APP75 기반 지원 관리](task04-applications-20261111.md) · [홈 커스터마이징·나의 대학 소식·후보 SQL·검증](task04-home-university-news-20261111.md) · [작업04-B 운영 사전 검토](task04b-production-preflight-20261111.md) · [작업04-C 홈 A 운영 적용·UI 후속/C·D HOLD](task04c-home-production-20261111.md).

모의고사 결과/답안 UI·공식 기출 기본·예상/추정 등급: [학생 결과 UI 후속](task03-result-ux-20261111.md).

작업03-C 자동채점 운영 적용 / READY 공개 / 실기기 검수: [운영 결과·검증·보존·원복](task03c-production-rollout-20261111.md).

APP67 학습 통합 / 학교 순위 / 친구 초대: [구현·계약·검증·운영 미적용·후속](app67-learning-integration-20261111.md).

TASK20 건국·경희 자연 전체 문항 복구: [공식자료·실제12회·격리 적용/원복·운영 승인안](task20-priority-natural-connection-20261106.md).

TASK19 / LAB 베타 안내·건국 자연 상태·평가원 등급컷 / 자료·학습 공통 조회: [구현·데이터·검증·운영 승인 경계](task19-lab-ux-grade-cutoff-20261105.md).

평가 정확도/최초 보류/최종 산술 검산/실제 TEST: [11/4 품질 검증·새 오판·수정·미완료](task16-evaluation-quality-closeout-20261104.md).

TASK16-M / 최초 평가·5단계 실제 비교·토큰: [검증 결과·남은 품질 P0](task16m-evaluation-finalization-20261104.md).

TASK16-L / 학습 완성도 저장·재첨삭 비교·History: [구현·TEST 검증·운영 승인 경계](task16l-learning-persistence-history-20261104.md).

수리·상경 최종 품질/공식 해설/후속 APP: [TASK16 구현·검증·잔여 P0](task16-final-quality-20261104.md).

학습용 5단계·종합 별점·최초/재첨삭 비교: [Owner 승인·근거 계약·구현 전 검증](learning-completeness-policy-20261104.md).

APP58 운영 Registry 전체 조사·수리/상경 확대: [363시험 감사](app58-expanded-registry-audit-20261104.md), [운영 증분·배포·실제 검수](app58-expanded-production-connection-20261104.md).

APP58 IPA/AAB / Owner Store 업로드·심사·게시 인계: [최종 산출물·서명/설정·절차·미실행 범위](app58-store-handoff-20261104.md).

APP·수리·상경 기존 서비스 통합 / 차단 해제 / 배포 빌드 / 앱 이용권 용어: [Owner·ChatGPT 종합 보고서](app-math-commerce-integration-report-20261103.md).

APP 업데이트 확인 / OPTIONAL·REQUIRED / 스토어 공개 버전 / 24시간 미루기: [Native 구현·정책·검증](app-update-check-20261104.md) → [비활성 SQL 후보](../supabase/candidates/app_update_policy_20261104/README.md).

후보 A ChatGPT 보고 / iPhone 검수 종합: [A 검수 보고서](app-candidate-a-owner-qa-report-20261103.md).

후보 B 실기기·WEB 검수 / Native 가독성·제출 버튼·원본 대조·진행 표시/일괄 확인·필수 확인 영역 번호·결과 근거 문단·LAB 서비스 조회 복구: [설치·결과 조회·품질 문제·Owner 경로](app-candidate-b-device-web-qa-20261103.md).

APP41 심사 수정 / 온보딩 V2 / TASK16 통합 후보 A·B: [빌드·실기기·제출 게이트](app-release-integration-20261103.md).

Kakao iOS 외부 브라우저 / App Review Guideline4 / 시스템 인증 세션: [11/3 수정·검수·릴리스 통합](kakao-ios-system-auth-20261103.md).

온보딩 프로필 누락 / MY 정보 보완 / 학교 검색 V2 / 고등학교 기본·중학교 명시: [최종 통합 준비·측정·실기기 검수](onboarding-v2-final-integration-20261103.md) → [11/3 구현·A–R·최종 리뷰 보완·Owner 검수](onboarding-school-search-v2-20261103.md#final-review-fix) → [Claude 원문 진단](onboarding-profile-integrity-20261103.md).

스토어 빌드·업로드·TASK14 심사 차단: [릴리스 후보·검증·운영 격차·후속](final-store-rc-1.md#task14--beta-store-release-candidate-2026-11-01).

공식 홈페이지 / home.legendstudy.com / Copa 출시 배너 / 공식 스토어 배지: [TASK12/B 구현·운영 배포·검수·롤백](official-home-launch-task12.md).

통합 분석 / GA4 두 속성 / 만족도 1~5 / 품질 검수: [TASK10 단계별 구현·연결·검증·미완료](admin-integrated-analytics-task10.md).

WEB 안전 검수 / 동일 도메인 / 관리자 실계정 / 배포 백업·롤백: [Owner 읽기 검수 경로·실제 배포·권한·검증](web-safe-owner-preview-20261031.md).

채점기준 표 / 숭실 배점 혼합 / 공식 근거 / 정정 후보 / APP·WEB: [10/31 구조 복원·숭실 최종 검증: 내용 PASS / 운영 기준 불일치 BLOCKED](rubric-structure-fix-20261031.md#숭실-v3-최종-검증--2026-10-31).

출시 전 안정화 / 원문 정정 후보 / WEB18실패 / APP·WEB 표시 계약: [10/30 검증·위험·복구](pre-release-stabilization-20261030.md).

APP 29 실기기 / 평가 원문 구조 / 재처리 애니메이션 / 답안 확인 동선: [Round29 수정·원본 진단](app-device-round29-20261030.md).

APP 결과·History·성장 UI / TTS / 본문 펼침 / 페이지 전환: [28 실기기 후속 수정](app-device-followup-20261030.md). 기존 UI / 5개 이전·다음 페이지: [최종 UI 정리·디자인 Addendum·검수 빌드](app-lab-refinement-20261029.md).

논술 P0 / 경희2024 반복실패 / 서울여 재첨삭 응답 / 문항 상태 동기화 / partial result / 요청키 복구: [근거·운영 RPC·Worker 배포·Observation iOS25·경희복구기록·서울여무료경로수정·iOS26·롤백](essay-evaluation-stability-p0-20261029.md).

APP 10/29 실기기 **2차** / 실패 재처리·재첨삭·Draft·Push·소문항: [2차 수정·운영 승인 대기](app-device-qa-fixes-20261029.md).

APP 10/29 실기기 오류 / 소셜 버튼 / 계열·진행 / 광운 Draft: [수정·운영 근거·미완료](app-owner-fixes-20261029.md).

APP 전체 인수 / 재작성 / paid learning round / 성장 / 사진 OCR: [최종 통합·검증·운영 적용 게이트](app-final-integration-20261028.md) → [성장 기존 정책](essay-growth-history-ui-20261026.md) → [사진 OCR 설계](essay-photo-ocr-design-20261028.md).


사진 답안 OCR → TEXT 입력 보조: [기술 비교·로컬 인쇄 PoC·Claude 연동 설계](essay-photo-ocr-design-20261028.md) — [10/28 APP 구현·검증범위](app-final-integration-20261028.md), 실제 학생 손글씨 미검증.

건국 APP 첨삭 정체 / Worker claim·checkpoint P0: [원인·수정·운영 승인/복구](essay-worker-incident-20261028.md).

[관리자 베타 운영 TASK04·설정/권한/집계/승인 패키지](admin-beta-operations.md).

무료 베타 Credit: [일일 1회 v2·11/11 종료·Owner SQL 후보](essay-beta-daily-v2.md) — 운영 비활성; [기존 출처 계약](essay-beta-credit-design-20261027.md).
TASK16-K / 수리·상경 베타 활성화 준비: [기존 DB·시험별 판정·수학 답안 표시·실기기·운영 승인 경계](task16k-beta-activation-20261103.md).

TASK16-J / 수리·상경 베타 출시 준비: [NOT_READY·Owner 접속·기능 판정·운영/TEST 차이·적용 목록](task16j-beta-release-readiness-20261103.md).

TASK16-I / 수리논술 통합 품질: [Owner 검수 경로·접속·기지 문제](task16i-owner-review-20261103.md) → [실제 WEB·혼합·교차 조회·A–J 판정](task16i-integration-quality-20261103.md).

TASK16-H / WEB 수리논술 UX: [구현·실제 TEST·교차 조회·미완료](task16h-web-math-ux-20261103.md).

TASK16-G 품질 마감 / TASK16-H 준비: [실제 품질·혼합형 차단·공통 계약·PC UX 명세](task16g-quality-closeout-task16h-preparation-20261103.md).

TASK16-G / Mobile First 학습 루프 (WEB UX는 후속 H): [서버 공개·반복 사이클·TEST 실제 검증·미완료](task16g-learning-loop-20261102.md).

TASK16-F / Flutter 수리논술 UX: [Native 구현·실기기·공통 계약 후보·검증·차단](task16f-native-math-ux-20261102.md).

TASK16-E: [손글씨·정답 공개 P0 수정/검증/잔여 차단](task16e-recognition-disclosure-p0-20261102.md).

TASK16-C / 수학 인식·스캐폴딩·수식: [재사용·Preview·품질 검증과 미완료](task16c-math-recognition-scaffolding-20261102.md).

TASK16-B / 상경·사회 실제 첨삭 통합: [격리 Preview·대표 시험·검증·차단 요소](task16b-commerce-social-integration-20261102.md).

TASK17 Toss TEST 복구: [전용 심사권한·Finance 복구대기](payment-app-foundation.md#task17--2026-11-02-test-결제-복구).

건국 APP 첨삭 정체 / Worker claim·checkpoint P0: [원인·수정·운영 승인/복구](essay-worker-incident-20261028.md).

무료 베타 Credit: [11/3 실측·기존 설계](essay-beta-credit-design-20261027.md#2026-11-03--task16-j-운영-읽기-전용-정정) — 운영 활성/하루1, 인문160시험·수리0. 수리 베타 연결 미검증.

WEB MY 프로필·관심 대학·지원 현황: [대학 관리 통합·배포·복구](my-college-management-20261026.md).

[광운 인문 16회차 운영 연결·복구](essay-kwangwoon-standby-20261027.md). 전체 대학 WEB/APP 공개 연결: [42개 대학 현황·플랫폼 GAP·Math 보류](essay-all-university-standby-20261026.md).

수리 코칭 MATH-5/6 필수 후속: [수리 코칭 필수 후속](math-technical-review-20261026.md#2026-10-27--owner-필수-후속-ai-풀이-코칭성장) (출시 준비 후, 운영 연결 미확인).
수리논술 기술 한계/대안·출시 검토: [현재 코드·실패 경계·권고 (조사만)](math-technical-review-20261026.md).

42개 대학 브랜드 히어로/공식색 근거: [분류·설정·배포·복구](university-brand-hero-20261026.md).
인하대 인문·자연·의예 STANDBY/대학별 브랜드 히어로: [대상·연결·배포·복구](inha-standby-20261026.md).
WEB 결과·근거 통합/비교·재작성: [10/30 구현·검증·미배포](essay-web-result-refinement-20261030.md).

WEB 작성·사진·회차 제출·진행 모달·History/시험 재진입·독립 초안: [2026-10-26 UI 배포/검사/복구](essay-web-studio-ui-20261026.md).

상경 정책·고려 자료 업데이트: [운영 상태·대표평가·승인대기](commerce-korea-20261026.md).

한양2027모의 상경 혼합형 장애: [사진 확인 복원·예약 상태·Owner 다음 단계](hanyang-mixed-incident-20261026.md).

논술 전체 대학 최신 기준: [STANDBY / OWNER QA PENDING — 실제 평가 호출 없이 연결](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책). 이전 평가 검수 선행 지시보다 우선.

논술 최종 성균PDF·한양 STANDBY 및 1-A(중앙·성균·경희), APP 중단: [시험 회차 전체 연결·보류·원본 명세](essay-group-1a-20261025.md).

2026-10-25 Native APP 통합 업데이트: [Owner 범위·현재 검증·실기기·스토어 승인 경계](app-release-20261025.md).

사용자 Credit 내역: [예약 숨김·사용 확정·빌드 보류](payment-app-foundation.md#2026-10-25-사용자-크레딧-내역-표시-정책).

JWT 복구/30일·자동갱신 검토: [계약·만료·Owner 절차·장기 설계](essay-jwt-lifecycle-review-20261023.md).

P0 전체512문항 묶음 연결: [Owner 최종 구조·분류·보존 원칙](essay-batch-service-20261023.md).

P0 11대학 연속 실행 / 실기기: [진행 현황·Owner 권한·미완료](essay-p0-direct-execution-20261023.md).

고려대 v12 / Owner 운영 SQL: [한 문항 Owner 적용·운영 E2E·검증·복구](korea-operating-owner-sql-20261023.md).

University Evaluation Profile 구현: [PHASE2 결과·잔여검수](university-evaluation-profile-phase2.md).

University Evaluation Profile / 대학별 첨삭 프로필: [PHASE1 표준 및 Owner 게이트](university-evaluation-profile-phase1.md).

대학별 프로필 실제 운영: [신규3문항 E2E·11대학 PARTIAL](university-profile-production-e2e-20261023.md).

PHASE3 Essay connection: [current local integration / execution gates](phase3-service-20261022.md).

Essay service implementation: [Oct11 contract-verified partial result](essay-full-service-implementation-20261011.md).

Current APP branch integration: [Oct10 local closeout](production-integration-2026-10-09.md#local-app-branch-integration--2026-10-10); historical Production/IAP: [Oct09 integration](production-integration-2026-10-09.md), superseding prior SDK/access and IAP-server-missing checkpoints.

Admin Credit: [목록](admin-credit-directory-20261026.md) → [만료일 지급·회수](admin-credit-operations-20261027.md). Admin member management: [directory009](admin-member-directory.md). Essay Web activation: [current activation](essay-runtime-activation-2026-10-09.md) → [four-type gap/contract](essay-mixed-mode-foundation.md); no provider activation.

WEB 통합 Oct25: [배포·집계 정정](phase3-service-20261022.md#2026-10-25-web-통합-배포-및-집계-정정).

WEB MY Oct25: [운영 반영·보존·검증 한계](phase3-service-20261022.md#2026-10-25-web-my-재설계-운영-반영).

MY/Application/Study/Student360 Oct08 follow-up: [shared foundation](my-shared-foundation.md) (006–008 Production-applied; authenticated acceptance pending;005 HELD).

Payment / Toss / purchased Credit: [APP payment foundation](payment-app-foundation.md) — [Oct25 모바일 구매 운영 집계·스토어 준비](payment-app-foundation.md#2026-10-25-관리자-모바일-구매-집계-정정스토어-준비); 이전 TEST-only 기록은 역사적 상태.

Account deletion / ADR-2D: [Ownership correction and Owner retry checklist](account-deletion-ownership-compatibility.md) — isolated verified; failed Production attempt rolled back; retry requires Owner review.

Human Quality / HQP: [HQP-3 implementation/Owner gate](human-quality-persistence-implementation.md) — isolated verified, Production NOT_APPLIED; [historical HQP-2](human-quality-persistence-canonical-review.md).

Quality authorization / LSA-2C / ql_list_cases / ql_case_detail: [canonical read contract and Owner application gate](essay-lab-worker-provider-l2.md#lsa-2c-shared-quality-authorization--2026-10-01) → [sentence/CORE persistence mapping](essay-lab-scaffolding-persistence.md#lsa-2c-quality-read-mapping--2026-10-01). Production gateway VERIFIED; no case for full-answer verification; web UI remains separate.

Architecture / DB cross-domain changes: [Cross Review A — live inventory, debt and foundation freeze](platform-architecture-health-review-a.md). Review findings before new foundation schema; [Owner alignment](product-architecture.md#post-audit-owner-alignment--2026-09-30) and [bounded ACL fix](day-7-dday-storage-proposal.md) are the current follow-up.

DATABASE / Study / Score / Mock / MY / LAB / Admissions / Essay / Application /
Outcome / Onboarding / Marketing / Achievement / Notifications / Analytics /
Monetization / B2B 설계는 아래 상위 Longitudinal Strategy를 먼저 읽고 domain
문서를 읽는다. [Learning / Decision / Outcome 구분과 지원·결과 이력](longitudinal-learning-admissions-data-strategy.md#learning-decision-and-outcome-history--owner-clarification-2026-09-29),
설계 전 일곱 preservation 질문을 확인한다. 이 전략은 구현 승인이나 현재 기능 목록이 아니다.

| Task / aliases | Required canonical reading |
|---|---|
| 평가 비용 / 장애 / monitoring / TASK06 | [운영 모니터링](essay-operations-monitoring.md) → [관리자 베타](admin-beta-operations.md) → [Analytics](analytics-v1-implementation-20261030.md) |
| LAB 피드백 / 오류 신고 / satisfaction / feedback TASK05 | [피드백·오류 신고](essay-feedback-reports.md) → [기존 Inbox](day-11-b3-admin-inbox.md) → [장기 데이터](longitudinal-learning-admissions-data-strategy.md) |
| BETA / 베타 운영 / 무료 이용 현황 / 복구 / 매일 무료 첨삭 / KST 자정 / beta daily | [관리자 베타 운영](admin-beta-operations.md) → [베타 v2](essay-beta-daily-v2.md) → [기존 원장](essay-beta-credit-design-20261027.md) → [공지](notices-system.md) → [데이터 보존](longitudinal-learning-admissions-data-strategy.md) |
| NOTICES / 공지사항 / 알림 종 / 무한 로딩 / notification timeout / 공지 읽음 / notice admin | [알림 안정화](notification-loading-fix-20261111.md) → [공통 공지사항](notices-system.md) → [데이터 보존 전략](longitudinal-learning-admissions-data-strategy.md) → [관리자 접근](admin-member-directory.md) |
| LONGITUDINAL / DATABASE / SCORE / ANALYTICS / ADMISSIONS / 공부시간 데이터 / 공부시간과 성적을 분석하자 / 성적 기록 / 성적 추이 / 모의고사 결과 / 내신 분석 / 수능 성적 / 지원 대학 / 수시 / 정시 / 논술 지원 / 합격/불합격 / 합격 데이터를 모으자 / 합격 예측 / 비슷한 학생 / cohort / 빅데이터 / 컨설팅 | **먼저 [Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md)** → 해당 domain 문서. [Data preservation](longitudinal-learning-admissions-data-strategy.md#preservation-and-architecture-review), [cohort/privacy](longitudinal-learning-admissions-data-strategy.md#cohort-analytics-and-minimum-cohort), [prediction gate](longitudinal-learning-admissions-data-strategy.md#admissions-evidence-and-prediction-gate); DATABASE는 이어서 [Database](database.md), SCORE는 [Academic roadmap](roadmap-academic-analytics.md) |
| ONBOARDING / 온보딩 / 정보 입력 / 마케팅 / MARKETING / MONETIZATION / B2B / 데이터 사업화 / 학생 데이터 판매 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Progressive profiling](longitudinal-learning-admissions-data-strategy.md#progressive-profiling-and-onboarding), [acquisition](longitudinal-learning-admissions-data-strategy.md#acquisition-and-marketing-strategy), [B2B boundary](longitudinal-learning-admissions-data-strategy.md#external-sharing-and-b2b-boundary), [Monetization](roadmap-monetization-and-in-app-learning.md), [Privacy](account-deletion-privacy.md) |
| DESIGN / HOME / UI v2 / UI 다시 수정하자 | [Owner Device PASS / frozen surfaces](design-system.md#ui-v2-owner-device-closeout--2026-09-24), [Current design system](design-system.md), [v2 approved specification](design-system-v2-proposed.md), [UI conventions](ui-ux-v1.md), [Home policy](day-10-b-home-polish.md) |
| APP ICON / 앱 아이콘 / SPLASH / 스플래시 / 런처 / launcher / 첫 화면 | [App icon & splash review — DESIGN REVIEW](app-icon-splash-v1.md) → [visual concept](brand-icon-splash-review/icon-splash-concept.html), [brand assets](../assets/brand/README.md) |
| AUTH / 로그인 / 이메일 인증 / SMTP / logout / account / Kakao | [이메일 인증 조사](email-verification-audit-20261111.md) → [Decisions — login philosophy](decisions.md#2026-09-12--login-philosophy), [native acceptance](auth-native-owner-acceptance.md), [recovery](auth-recovery.md), [deletion/privacy](account-deletion-privacy.md), [current account UX](core-app-improvements.md) |
| STUDY / TIMER / 공부 추이 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Study v1 and current chart overrides](study-v1.md), [Study UI and Owner overrides](day-8-study-ui-review.md), [Study storage](day-8-study-storage-proposal.md), [current UI convention](ui-ux-v1.md) |
| MOCK EXAM / SCORING / 모의고사 / 모의고사 완성하자 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Mock Exam](day-8-mock-exam.md), [Current foundation and Phase2 gaps](day-8-d2-answer-scoring.md#end-of-day-foundation-and-phase2-gaps--2026-09-24), [Official/free dual modes](day-8-d2-answer-scoring.md#owner-follow-up-3--dual-practice-modes), [scoring](mock-exam-scoring-v1.md), [current exam→subject→key→result workflow and gaps](day-8-d2-answer-scoring.md#current-exam-selection-and-scoring-handoff--2026-09-24), [grade result](day-8-d3-grade-result.md), [scoring storage](day-8-scoring-storage-proposal.md), [작업03 5개년·단답형·검수 상태](task03-mixed-scoring-20261111.md), [작업03-A 공식 검수](task03a-official-ready-20261111.md), [작업03-B 최신 READY·운영 후보·미해결](task03b-ready-candidate-20261111.md) |
| ACHIEVEMENT / BADGE / 배지 / Level | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Achievement decision](decisions.md#2026-09-19--achievements-record-behaviour-and-confirmed-growth-never-prediction), [Achievement / Badge Engine](roadmap-academic-analytics.md#9-achievement--badge-engine), [current product scope](product-scope.md) |
| MEAL / SCHOOL / NEIS / 급식 다음 제공일 | [NEIS](day-7-neis.md), [current time/fallback/Home expanded policy](day-10-b-home-polish.md), [school storage](day-7-school-storage-proposal.md), [school/profile UX](core-app-improvements.md) |
| MY / PROFILE / SETTINGS / 프로필 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [UI conventions](ui-ux-v1.md), [design system](design-system.md), [database/private avatar](database.md), [current profile/account UX](core-app-improvements.md), [personal ownership](day-9-c-personal-state.md), [Design System v2 — IMPLEMENTED](design-system-v2-proposed.md) |
| PERSONALIZATION / ONBOARDING / 개인화 / 최초 설정 / 재학생 N수생 / academic status / 첫 로그인 | [Personalization Foundation & first-login onboarding — IMPLEMENTED / migration PASS](personalization-onboarding.md) → [canonical profile](database.md), [profile/account UX](core-app-improvements.md) |
| ESSAY LAB DATA FOUNDATION / OFFICIAL EVIDENCE / OWNER PDF ARCHIVE / 논술 canonical / 2025 Pilot schema | [Official evidence archive strategy](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30) → [Essay LAB foundation — APPLIED; Pilot mapped](essay-lab-data-foundation.md) → [Database](database.md), [Personalization](personalization-onboarding.md); [3-university Pilot](essay-lab-pilot-2025.md); [Evaluation Pilot](essay-lab-evaluation-pilot-2025.md):5/21/134 preserved; Sookmyung Run A execution PASS/benchmark PARTIAL, Owner review; Hanyang PARTIAL/SKKU v1 preserved |
| ESSAY PRODUCTIZATION / CREDIT G1 / SCAFFOLDING / 문장 첨삭 / STUDENT ANALYTICS / 회차권 / 재작성 | [Essay v1 Product Spec / G1 Credit](essay-lab-product-v1.md) → [Student architecture / ERD / 15 cases / SQL review](student-analytics-data-architecture.md) → [Final history review / KEEP19](essay-lab-final-schema-review.md) → [Phase2A runtime](essay-lab-runtime-validation.md) → [Phase2B RPC / actual JWT PASS](essay-lab-server-transactions.md) → [Identity2C Owner PASS](essay-lab-shared-identity.md) → [Migration promotion history](essay-lab-migration-promotion.md) → [Production preflight](essay-lab-production-preflight.md) → [Baseline ADOPTED](production-migration-baseline-reconciliation.md) → [Product apply history](essay-lab-production-apply.md) → [Security PASS / DEPLOYED](essay-lab-security-resolution.md); [L2-C3 original + calibration Owner quality PASS](essay-lab-model-bakeoff-l2-b.md#l2-c3-hanyang-investigation-and-sequential-gate--2026-09-30) → [L2-B3 Owner review / GPT candidate only](essay-lab-model-bakeoff-l2-b.md) → [L2-B4 Option A / offline prompt / UI gap](essay-lab-scaffolding-persistence.md#l2-b4-option-a-implementation--2026-09-30) → [L2-A3 reviewer design / next Pilot gates](essay-lab-worker-provider-l2.md#l2-a3-reviewer-architecture) → [L2-A2 binding/telemetry — isolated PASS, NOT_APPLIED](essay-lab-provider-provenance-l2-a2.md); [Workspace / L1 live client, rollout OFF](essay-lab-ui-ux-v1.md#live-integration-l1--2026-09-29), [문장 다듬기](essay-lab-sentence-review.md), [Scaffolding/submit Production apply](essay-lab-scaffolding-production-apply.md): PASS; [private AI Pilot1.3 Run A](essay-lab-scaffolding-ai-pilot-1-3-run-a.md):2 frozen runs, quality PARTIAL; Production student/AI/payment NOT_ENABLED |
| LAB / ACADEMIC ANALYTICS | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [platform boundaries](product-platform-boundaries.md), [product architecture](product-architecture.md), [academic roadmap](roadmap-academic-analytics.md), [Essay roadmap](roadmap-essay-lab.md), [App LAB details](core-app-improvements.md) |
| MATERIALS ROLLOUT / 최신 글 업데이트 / HISTORICAL BACKFILL / 2020 자료 / 과거 자료 / 논술 자료 연결 | [Materials final closeout](materials-final-closeout-2026-09-27.md) → [Owner source rule / Essay LAB P0](materials-closeout-essay-lab-handoff.md) → [Exam full-set policy](exam-full-set-canonical-policy.md) → [Materials rollout and historical backfill](materials-data-rollout.md) → [Current ingestion handoff](ingestion.md#daily-sync-current-handoff--2026-09-24) → [Current status](current-status.md#daily-sync-status); current closeout supersedes historical wave/audit holds; device QA then STOP |
| MATERIALS / 자료 | [search](day-9-search-explore.md), [resources](day-9-c-resource-detail.md), [personal state](day-9-c-personal-state.md), [saved/recent](day-9-c-personal-lists.md); [Resolver parser correction and diagnostics](day-9-c-resource-detail.md#scoped-duplicate-attribute-correction--2026-09-25) |
| MATERIALS RESOURCE / PDF / 자료 바로 보기 / 문제지 / 정답 / 해설 / SAFE OPEN | [Resource detail + Safe Open](day-9-c-resource-detail.md) → [product scope](product-scope.md#core-content-experience); [Owner PDF PASS and presentation cleanup](day-9-c-resource-detail.md#materials-detail-cleanup-and-owner-pdf-acceptance--2026-09-25); failure source fallback retained |
| D-DAY / D-Day 여러 개 / CALENDAR / 달력 / 일정 / 여러 일정 / 수행평가 일정 | [Home personalization and event collection](home-personalization-and-events.md) → [D-Day storage](day-7-dday-storage-proposal.md), [Home policy](day-10-b-home-polish.md) |
| HOME CUSTOMIZATION / 나의 대학 소식 / university_news / 홈 카드 Registry / 홈 커스터마이징 / 학생 / N수생 홈 / 학부모 홈 / 교사용 홈 / 학원 / 홈 화면 설정 / 홈 메뉴 숨기기 | [04-C 기기 검수](task04c-device-verification-20261111.md) → [작업04-C 홈 설정 운영 결과](task04c-home-production-20261111.md) → [작업04-B SQL·권한·실기기 사전 검토](task04b-production-preflight-20261111.md) → [작업04 홈·대학 소식 구현](task04-home-university-news-20261111.md) → [Home personalization and event collection](home-personalization-and-events.md) → [Home policy](day-10-b-home-polish.md), [product architecture](product-architecture.md) |
| ANALYTICS PLATFORM / analytics.legendstudy.com / 관리자 / 빅데이터 / cohort / 데이터 분석 | [Longitudinal strategy](longitudinal-learning-admissions-data-strategy.md) → [product architecture](product-architecture.md#analytics-platform-direction--2026-09-25) → [academic roadmap](roadmap-academic-analytics.md) |
| ANALYTICS MEASUREMENT / GA4 / Firebase / event / KPI / funnel / attribution / North Star / 지표 측정 | [P0 launch data contract — audit/gap/design](analytics-p0-launch-contract.md) · [Measurement architecture v1 — 외부 리뷰 (advisory)](analytics-architecture-review-v1.md) · [v1 구현·TASK03 APP/WEB 계측·운영 집계 GAP](analytics-v1-implementation-20261030.md#task03-existing-integration-verification--2026-10-31) → [longitudinal strategy](longitudinal-learning-admissions-data-strategy.md), [Essay LAB product](essay-lab-product-v1.md) |
| SCHOOL HISTORY / 학교 변경 / 쿠폰 / COUPON / VOUCHER / 첨삭권 쿠폰 / B2B 학교 / campaign / redemption | [School History & Coupon/Voucher design](school-history-and-coupon-design-v1.md) → [longitudinal strategy](longitudinal-learning-admissions-data-strategy.md), [monetization roadmap](roadmap-monetization-and-in-app-learning.md), [Essay G1 credit](essay-lab-product-v1.md) |
| ADMISSIONS DATA / ANALYTICS / 입시 데이터 / 합격 가능성 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Owner allocation](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24), [roadmap / research gate](roadmap-academic-analytics.md#research-boundary--2026-09-24), [Manus registry](research-registry.md), [decisions](decisions.md) |
| DAILY SYNC / INGESTION / Daily Sync 시작하자 / 사이트에 새 글 올렸는데 앱에 안 보여 / Pilot C / quarantine | [Current ingestion handoff](ingestion.md#daily-sync-current-handoff--2026-09-24) → [Phase 1 deterministic delta package](daily-sync-phase-1-deterministic-delta-package.md) → [Research synthesis](research-2026-09-24-product-operations-synthesis.md) → [Current baseline/status](current-status.md#daily-sync-status); [historical pipeline](day-9-ingestion.md), [source provenance and reconciliation](research-registry.md#owner-provided-manus-exports--source-acquired) |
| COMPLIANCE / RELEASE / App Store 출시 | [Privacy/deletion](account-deletion-privacy.md), [Auth acceptance](auth-native-owner-acceptance.md), [current release gates](current-status.md), [Community safety](product-platform-boundaries.md), [research audit boundary](research-registry.md) |
| PRODUCT STRATEGY / 2026~2027 출시 일정 / Subscription / Essay 가격 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Product architecture](product-architecture.md), [scope](product-scope.md), [2026–2027 canonical roadmap](roadmap-monetization-and-in-app-learning.md#20262027-roadmap-and-monetization--owner-decision-2026-09-29), [Manus registry](research-registry.md) |
| COMMUNITY / 커뮤니티 | [monetization/learning roadmap](roadmap-monetization-and-in-app-learning.md), [Community decision](decisions.md#2026-09-19--community-is-a-free-retention-feature-not-a-launch-blocker), [Profile privacy and safety gates](product-platform-boundaries.md), [private profile](database.md), [research/compliance registry](research-registry.md) |

[Policy/code evidence audit](mobile-policy-audit.md) distinguishes gaps from
implemented/local-tested/Owner-verified claims. Existing document directory below
is preserved; historical checkpoints are accessed only when evidence is needed.

## Latest end-of-day handoff

- [2026-11-04 APP58 운영 연결·실제 검수 마감](app58-expanded-production-connection-20261104.md) — 15대학202시험 연결, 인하 사진 무료 재첨삭/서강 Essay 결과, APP58 본문 공백·전체 해설·혼합형 P0와 재개 순서. [Owner Store 인계](app58-store-handoff-20261104.md); APP58 원본 보존·Codex Store0.

- [2026-09-25 EOD closeout](eod-2026-09-25.md) — Materials PDF Owner PASS, Daily Sync Phase1 closeout, OAuth local runtime recovery, Multi D-Day/Home/Analytics planned state, deferred UI polish, and Owner top-level minimum-cost/simple/lightweight engineering rule.

## Product/platform canonical entry points

- [Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md) — **HIGH / CANONICAL PRODUCT STRATEGY**, event 보존·cohort·지원/결과·사업화의 상위 원칙; architecture PLANNED

- [Product family and B2B architecture](product-architecture.md) — App/LAB/Teacher/School, shared data/engine, future access/security, priority
- [App/Web platform boundaries](product-platform-boundaries.md) — quick action vs deep work, public IA, domain strategy
- Essay and Analytics roadmaps below retain module-specific detail; they do not redefine the product family.

## Documents

- [Flutter toolchain and dependency audit](flutter-toolchain.md) — canonical SDK/helper, constrained upgrades and deferred native migrations

- [App native Auth and shared-account Owner acceptance](auth-native-owner-acceptance.md) — platform paths, console coexistence, debug comparison and physical checklist

- `core-app-improvements.md` — Materials/account improvements, evidence and Owner release gates

- `current-status.md` — current implementation status, blockers, next actions
- `overview.md` — product purpose and project boundaries
- `product-scope.md` — v1.0 and later scope
- `architecture.md` — app/system architecture
- `database.md` — data model and Supabase policy
- `day-7-school-storage-proposal.md` — school persistence migration, owner deployment report and validation/rollback reference
- `day-7-neis.md` — server-key policy, deployed proxy and completed runtime acceptance
- `ingestion.md` — legendstudy.com ingestion strategy
- `ui-ux-v1.md` — approved UI/UX v1.1 canonical implementation specification; required before UI changes
- `study-home-ui-polish.md` — Study/Home polish, visual review and iPhone physical acceptance subset
- `design-system.md` — visual identity and UI design tokens
- [Design System v2 — IMPLEMENTED](design-system-v2-proposed.md) — Owner-approved Palette A, implemented UI mapping and device-review gate
- `decisions.md` — durable product/architecture decisions
- `log.md` — chronological development log
- `roadmap-essay-lab.md` — Essay service-module research-first roadmap
- `day-10-b-home-polish.md` — Home meal and expandable recent sections

- [Historical checkpoint: Flutter 3.47.5 / Dart 3.13.4 and Owner E2E](history/status-checkpoints.md#2026-09-21-end-of-day-canonical-checkpoint)

## Canonical-source rule

There must be only one canonical `current-status.md` for the repository. Notion, chats, external documents, Claude notes, Manus reports, and ChatGPT plans may support the project, but they do not replace this repository-local wiki.

- [D-Day storage — applied and runtime verified](day-7-dday-storage-proposal.md)

- [Study v1 — Day 8 approved design and UI contract](study-v1.md)
- [Day 8 Study storage — deployed migration / JWT acceptance PASS](day-8-study-storage-proposal.md)

- [Day 8 Study migration — copy-ready Owner SQL package](day-8-study-migration-package.md)

- [Day 8 Claude Study UI review and Owner overrides](day-8-study-ui-review.md)

- [Day 8-C Mock Exam — Guest/Auth runtime PASS / physical checks pending](day-8-mock-exam.md)

- [Day 8-D Mock Exam scoring — architecture proposal](mock-exam-scoring-v1.md)
- [Day 8-D1 Scoring storage — COMPLETE, actual JWT/RPC PASS](day-8-scoring-storage-proposal.md)

- [Day 8-D1 Scoring — applied SQL execution package](day-8-scoring-migration-package.md)

- [Day 8-D1 Scoring — actual JWT acceptance PASS and fixture cleanup](day-8-scoring-jwt-acceptance.md)

- [Day 8-D2 Answer Entry + Raw Score — COMPLETE, Guest/Auth Flutter PASS](day-8-d2-answer-scoring.md)

- [Day 8-D3 Grade + Result UX — COMPLETE, actual A/B Flutter PASS](day-8-d3-grade-result.md)

- [Day 9-A Search / Explore — COMPLETE / validation environment](day-9-search-explore.md)

- [Day 9-B Ingestion — survey, pipeline, dry-run; production gate open](day-9-ingestion.md)

- [Subjects taxonomy v1 — canonical subjects and raw-label mapping](day-9-subjects-taxonomy.md)

- [Day 9-B2 Pilot C — production apply package, not executed](day-9-pilot-c-package.md)

- [Day 9-C1 Resource Detail + Safe Open Target](day-9-c-resource-detail.md)
- [Day 9-C2 Bookmark + Recent Views](day-9-c-personal-state.md)
- [Day 9-C3 Saved / Recent UI + MY Integration](day-9-c-personal-lists.md)
- [Day 9-D1 Pilot C publication package — implemented; publication COMPLETE](day-9-d1-publication-package.md)

- [LAB Essay Service Module Roadmap — research complete; Phase 2 Web architecture recorded](roadmap-essay-lab.md)
- [Academic Analytics → Achievement → Admissions Engine Roadmap — PLANNED, not implemented](roadmap-academic-analytics.md)
- [2026–2027 Roadmap & Monetization — Owner targets; Essay prices fixed, Subscription planned](roadmap-monetization-and-in-app-learning.md#20262027-roadmap-and-monetization--owner-decision-2026-09-29)
- [Day 10-B Home Polish v2 — implemented; device launch follow-up](day-10-b-home-polish.md)
- [Day 10-C Legacy Subject Alias — minimum foundation implemented](legacy-subject-aliases.md)
- [Day 11 Account, Personal and Feedback Operations — foundation / Production pending](day-11-account-personal-feedback.md)
- [Day 11-B1 Feedback production security closeout — COMPLETE / Production verified](day-11-b-feedback-production.md)
- [Day 11-B3 Admin Inbox — implemented; Production E2E pending](day-11-b3-admin-inbox.md)
- [Day 11-B4 Feedback Email — worker deployed; delivery E2E pending](day-11-b4-feedback-email.md)
- [Day 12 Home visual hierarchy — implemented](day-12-home-visual-hierarchy.md)

- [Auth Recovery — code verified; Production E2E pending](auth-recovery.md)
- [Account Deletion & Privacy — foundation implemented; Production deletion pending](account-deletion-privacy.md)
- [ADR-1 — 14-day account deletion architecture; design only](account-deletion-14-day-architecture.md)
- [ADR-2 — Local lifecycle implementation; Production NOT_APPLIED](account-deletion-14-day-implementation.md)
- [ADR-1B — Erasure/retention/rejoin boundary; ADR-2 external gates](account-deletion-erasure-retention-boundary.md)

- [In-App Exam architecture — paper-first engine / independent Viewer gates](architecture-in-app-exam.md)

- [Mobile IA / Profile / Learning handoff](core-app-improvements.md#mobile-ia-profile-and-learning--2026-09-23)

- [MY dashboard / Study Trends / private avatar refinement](core-app-improvements.md#my-dashboard-study-trends-and-lab-refinement--2026-09-23)

- [MATH-2B — Canonical DB/security cross-review; corrections required, no implementation](math-essay-canonical-db-security-review.md)

- [MATH-2R — Shared HQ/Billing/deletion/worker contract; implementation authorization next](math-essay-shared-integration-contract.md)
- [MATH-2C — Math persistence isolated verified; Owner apply package, Production NOT_APPLIED](math-essay-persistence-implementation.md)
- [MATH-2D — Runtime consumer contract; isolated verified, Production NOT_APPLIED](math-essay-runtime-consumer.md)
- [MATH-2E — Learning runtime and MATH-5B/6B physical handoff; isolated, NOT_APPLIED](math-essay-learning-runtime.md)

- [APP release closeout / Store handoff](app-release-closeout.md) — current local evidence, privacy map and remaining RC gates.

- [Essay runtime completion follow-up](essay-runtime-completion.md) — PARTIAL / gated.

- 인하 다중 사진 추출 장애/재개/사진 UI: [운영 복구](inha-photo-extraction-20261026.md).

WEB 성장 대시보드·통합 History/결과: [정책·배포·검증범위](essay-growth-history-ui-20261026.md).

- [TASK09 공통 TEST / 비공개 Preview / 선행 스키마·Gateway 차단](essay-shared-test-task09-20261101.md) — TASK08 후속, PARTIAL/HOLD.

- Admin analytics / 학습·입시 빅데이터 TASK11: [통합 현황·집계 정의·검수·TASK11-G 운영 배포](admin-data-task11.md#task11-g-production-integration--2026-11-01)

## TASK19 후속 업데이트

[TASK19-C TEST60 빌드·실기기·격리 DB 적용](task19c-device-verification-20261105.md).

[Owner 등급컷 표시 정정·대학 공통 공개 범위 확인](task19-owner-ui-followup-20261105.md).

[LAB 베타 안내·건국 자연 상태·평가원 등급컷](task19-lab-ux-grade-cutoff-20261105.md). 기존 Mock 채점/자료/PDF/Analytics 경로를 함께 따른다.

[APP GA4 이벤트·DebugView 검증·릴리스 준비](app-ga4-usage-20261105.md).

2026-11-05 [후속 앱 최종 통합 감사·1.0.2(63)](app-update-final-audit-20261105.md): APP58 보존, 누락 PDF/문의/이용권 통합, 운영·Store 변경 없음.

[APP63 출시 전 점검·TASK18 적용·TASK19 권한 차이·실기기](app63-prelaunch-readiness-20261105.md).

[TASK21 자연계 상태·최종 빌드/기기 검수](task21-final-release-readiness-20261105.md).

[작업03 최근5개년 운영 커버리지·확보 계획](task03-mock-five-year-audit-20261111.md).

[작업03 mixed-v2 구현·격리 검증·과목별 미완료](task03-mixed-scoring-20261111.md).

[작업03-A 공식 정답·배점·등급컷 검수/READY 후보/미완료](task03a-official-ready-20261111.md).

[작업03-B 2025수능 검수·별칭/코드·원점수/백분위·승인용 SQL](task03b-ready-candidate-20261111.md).
