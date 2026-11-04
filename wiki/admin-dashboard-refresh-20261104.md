# 운영 대시보드 개편 — 2026-11-04

Owner 요청: 대시보드만 재구성. 작은 카드·명확한 경계, 회원/활성 회원/학년/학교 우선,
학습 시간의 정의·기록자 평균·학년별 분석, 시험/문항 검수 지표는 전용 화면으로 연결.
이전 이용권 SQL/WEB 배포 승인은 이 신규 화면의 운영 배포 승인이 아니다.
**구현·로컬 검증 완료 / 운영 SQL·WEB 미반영 / APP 변경 없음.**

## 현재 구현

WEB 별도 브랜치 `codex/dashboard-refresh-20261104`, 작업 경로
`/private/tmp/legendstudy-feedback-web-20261104`. 이전 이용권 운영 배포를 기반으로 한다.

- 상단: 전체 가입 계정(auth.users), 학습 활동 회원(최근30일 공부·모의고사 기록),
  프로필 보유, 학교 입력 회원. 학교 입력 수는 profiles 전체−학교 미설정 수.
- 현재 학년 분포와 학교 상위20을 상단에 배치. NEIS 교육청+학교 코드 이름 조회 재사용.
  현재 프로필과 과거 학습 당시 학년을 혼동하지 않는다.
- 흰 카드, 청록·청색 차트, 명확한 외곽선, 작은 제목/숫자/여백. 대시보드 CSS module로 한정.
  공유 메뉴·타 화면·실제 서비스 기능의 디자인은 유지.
- KST 기간 선택(오늘/7일/30일/이번달/최대400일 직접선택), 새로고침.
  기간은 학습/운영에 적용; 회원 구성은 현재, 활동 회원은 최근30일 고정이라고 명시.
- 총 기록 학습시간/기록자 평균/고유 기록자와 학년 선택·상세 표.
  분 단독 표시 대신 시간·분, 1분 미만은 별도 표시. 평균 분모는 전체 회원이 아닌 기록자.
- 문의·인문/경제경영 첨삭·이용권 요약과 웹 결제 요약을 작게 배치.
  수리 상태는 기존 누적 집계라고 명시. TEST/LIVE와 모바일 구매를 섞지 않는다.
- 기존 DB 등록/게시 플래그/실행 승인 수치와 과거 단일문항 통계를 대시보드에서 제거.
  논술 자료 검수·첨삭 품질·학습 분석으로 링크한다. 검수 탭 자체는 이번 범위에서 수정하지 않음.

## 학습 시간의 실제 근거

기존 `admin_release_report`는 기간 내 started_at인 완료 세션의 duration_seconds를 합산.
`admin_learning_analytics`는 active_segments를 기간 경계에서 자르고 동일 회원의
기기/세션 중복 구간을 range_agg로 합친다. 새 화면은 후자를 재사용한다.

완료·동기화·include_in_study_total=true인 공부 타이머와 모의고사 풀이만 포함.
일시정지/합산 제외 모의고사/미동기화/접속시간/첨삭 처리시간은 포함하지 않는다.
실제 공부 여부의 객관적 증명이 아닌 사용자가 기록한 시간이다.
기존 analytics와 동일하게 lifecycle allowed인 profiles 회원만 대상.
전체 가입 계정, 30일 학습 활동 회원, 선택 기간 학습 합산 기록자는 서로 다른 모집단이다.

운영 **읽기 전용 SELECT**, 2026-11-04 16:17 KST:
- 기간 2026-10-06 00:00 이상 ~ 2026-11-05 00:00 KST 미만.
- 겹침 제거 13,457,752ms, 기록자7명 → 총 **3시간44분**, 기록자 평균 **0시간32분**.
- 학년별 소수 집단 존재로 세부 수치 비공개. 0이나 가짜 통계로 채우지 않는다.
- schema/기존 함수 정의 확인, 새 후보 SELECT 실행만 했으며 함수 설치/원본 변경 없음.
- 전체 모드 목록은 study와 mock_exam으로 확인. 개인 식별정보·답안은 조회하지 않음.

## 조회 SQL 후보와 호환성

[apply](../supabase/candidates/dashboard_study_20261104/apply.sql) / [preflight](../supabase/candidates/dashboard_study_20261104/preflight.sql) /
[verify](../supabase/candidates/dashboard_study_20261104/verify.sql) / [rollback](../supabase/candidates/dashboard_study_20261104/rollback.sql).

새 `admin_dashboard_study(from,to)` 하나만 추가하는 STABLE 읽기 함수.
기존 admin_operator + account lifecycle 검사, 빈 search_path, 8초 timeout,
authenticated EXECUTE, PUBLIC/anon/service_role EXECUTE 차단. 테이블/RLS/Auth/원장 로직 변경 없음.
학년은 현재 academic_status=student의 1/2/3, retaker, 미입력·기타로 분리.
기존 최소표본5 정책을 적용하고 작은 집단 차감 추론을 막기 위해 하나라도 5명 미만이면
학년 세부 전체를 숨긴다. 원본·분류값을 UPDATE하지 않는다.

새 함수 미설치 때만 기존 `admin_learning_analytics`로 총시간·평균을 조회하고 학년별 연결 준비 중으로 표시.
권한 오류·네트워크·잘못된 응답을 미설치로 둔갑시키지 않는다. 새 함수 없어도 화면 전체가 실패하지 않음.

운영 적용은 별도 Owner 승인 후: 새 함수 미존재/의존성·schema 확인 → 후보SQL → ACL/실제 관리자
조회 → 최신 운영 WEB과 diff/설정 보존 확인 → 대시보드 WEB 배포 → 실제 로그인 읽기 검수.
그때 CLI로 migration을 생성/기록하며, 후보와 migration을 중복 실행하지 않는다.
rollback은 WEB 복원 후 새 조회 함수만 제거한다. 과거 데이터 복구 작업은 필요하지 않음.

## 보존 검토 7문항

기존 [상위 전략](longitudinal-learning-admissions-data-strategy.md), [Study 저장 계약](day-8-study-storage-proposal.md),
[MY 공통 기반](my-shared-foundation.md), [공부시간 정책](study-v1.md)을 계승한다.

1. 새 historical fact 없음. started_at/ended_at/segments로 학습 발생 시각, as_of로 조회 시각 분리.
2. 원본 세션과 profile을 수정하지 않고 SELECT로 재계산. 현재 학년이며 과거 학년은 복원하지 않음.
3. UPDATE/이전/복제/집계 테이블 없음. 원본 history 보존.
4. 기존 study_sessions.user_id=profiles.id canonical identity 사용, 별도 사용자 생성 없음.
5. Learning 파생 지표만 제공, 성적/입시 Decision/Outcome 추정 없음.
6. 기존 내부 운영자·lifecycle·최소표본5 경계 유지. 학교+학년 교차 개인 식별/외부 공유 없음.
7. 총시간/평균은 파생값, 저장하지 않음. 분모/기간/중복 제거/미기록 한계를 화면에 명시.

## 검증

- WEB 관리자 관련 31파일: **189 PASS, 1 기존 gated SKIP**. 신규 집계 파서, 기록자 평균,
  학년 선택, 미설치 fallback, 권한 오류 fallback 금지, 기간 오류 시 이전 값 제거 포함.
- TypeScript/변경 파일 ESLint PASS. 정적 production build **163 routes PASS**, 배포 실행0.
- [격리 PostgreSQL 테스트](../tool/test_dashboard_study.py) PASS: KST 자정 경계, 모의고사/기기 겹침,
  일시정지·합산 제외, 고유 분모, 학년·전체 표본 보호, lifecycle/권한, 기간 한계, 원본 hash, rollback.
- 실제 운영 SELECT는 위 수치까지만. 새 RPC 실제 로그인 acceptance는 운영 설치 후 검증할 항목.
- 실제 React 컴포넌트와 CSS로 합성 데이터 디자인 검수 HTML 생성. 학교명만 fixture로 대체.
  데스크톱 및390px 폭, 상세 펼침/가로 넘침 없음 확인. 정적 미리보기의 필터는 동작하지 않으며
  필터 실제 동작은 React 통합 테스트로 검증했다. 운영 계정 우회 경로/preview route를 제품에 추가하지 않음.
- Wiki handoff:10개 경로 PASS; 기존 TASK16 외부 상대경로20개 missing은 기존 실패로 유지.

## Owner 검수

1. 상단에서 회원·활동·학년·학교 정보를 즉시 비교할 수 있는지 확인.
2. 공부 시간 정의, 시간·분 표기, 기록자 평균이 이해되는지 확인.
3. 새 RPC 적용 후 학년 표본 충분한 격리 fixture에서 학년 선택/표를 확인. 운영 소수 집단은 숨김 유지.
4. 오늘/30일/직접선택, 미설치·빈 표본·권한 오류 상태 확인.
5. 문의/이용권/결제/검수 링크 이동 확인. 실제 지급·차감·결제·평가·시험 답변은 실행하지 않음.

사용자 새 요청은 기존 [이용권 작업](credit-classification-20261104.md)의 운영 적용과 별개이며,
이번 새 WEB/SQL 운영 적용·APP58 통합·앱 빌드는 수행하지 않았다.

## 변경 위치 / Git

WEB 구현 SHA: `b2b3e69268a1f763c7ab924bc7d3367d2b4a187f`.
WEB 변경 파일: `src/app/admin/page.tsx`, `src/components/admin/admin-dashboard-view.tsx`,
`dashboard.module.css`, `admin-console.test.tsx`, `src/lib/admin/client.ts`,
`dashboard-study.ts`, `dashboard-study.test.ts`, `docs/dashboard-refresh-20261104/README.md`.
APP checkout은 후보 SQL4개·로컬 PG 테스트·canonical Wiki만 변경. Flutter 코드 변경 없음.

로컬 검수 산출물(합성 데이터):
`/Users/woojinchang/.codex/visualizations/2026/11/04/01a1a3e0-e3df-7dd3-b013-1c9e9fd65314/dashboard-refresh/`
의 `index.html`, `dashboard-desktop.jpg`, `dashboard-mobile.jpg`.
정적 예시는 필터를 조작하는 E2E 화면이 아니다. 실제 운영 배포 상태로 해석하지 않는다.
