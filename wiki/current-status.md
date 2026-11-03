# Current Status

## APP·수리·상경 기존 서비스 통합 — 2026-11-04

현재 작업 기준은 [Owner/ChatGPT 종합 보고서](app-math-commerce-integration-report-20261103.md)다. Owner는 보고서 작성·기존 서비스 통합·수리/상경 차단 해제·배포용 빌드 진행을 지시했다. 과거 HOLD는 당시 이력으로 보존하며, 최신 승인과 실제 배포/적용 완료를 구분한다. 스토어 업로드·제출·게시는 Owner 직접 실행으로 역할이 정정됐다. [APP58 산출물·절차 인계](app58-store-handoff-20261104.md), Codex 업로드/제출/게시0. 기존16시험으로 제한하지 않고 전체363시험을 조사했다. [확대 감사](app58-expanded-registry-audit-20261104.md), [운영 연결 실행](app58-expanded-production-connection-20261104.md)이 최신 근거다.

- APP `codex/app-review-candidate-b-20261103`: 후보 A 인증·온보딩·MY·선택형 닉네임 + B 수리 UX 통합. 자연계 일괄 차단 대신 정확한 공개 Catalog와 서버 실행 상태를 확인한다. 혼합형 사진은 기존 Math 인식/확인 후 Essay 시험 회차 하나에 제출한다. 입력이 바뀌면 확인본 재사용 차단.
- WEB `codex/math-commerce-release-20261103`: 실제 운영 `c9bda913`을 기준으로 Math 후속23개 커밋을 통합. 기존 운영 관리/Analytics/결제 변경 보존. TEST 브랜치를 운영에 그대로 덮어쓰지 않는다.
- 전체 데이터 READY211/NEEDS_REVIEW73/BLOCKED79. 기존160+신규42=15대학202시험464문항 연결 범위다. 신규42는 혼합26·Math15·서강Essay1. 의예9/부분승인2는 신규 전체시험 활성화 제외, 기존ID·review·자료 보존.
- 운영 core/scope/beta/혼합전체문항 guard4개 적용·postflight PASS. 기존 보호13테이블 count/hash 동일, beta160행/캠페인 그대로 보존하고42행만 추가. Math catalog72·APP58 limit50호환, coaching/quote/continue·일일무료 출처·무료1회 반복 연결. 신규 혼합26은 일부문항 제출을 차감 전에 차단한다.
- 호환 WEB d8b0d2de/소스172c5e1을 Math HOLD로 선배포, 기존 인문 History3문항 실조회 PASS. 최종 공개설정/Worker/WEB 연결 및 신규 Provider 실제 검수 진행 중. 운영 설정 완료를 실제 첨삭 품질 PASS로 보고하지 않는다.
- APP 이용권 표시/출처 연결까지 전체1,434PASS/7SKIP, signed iOS57 완료·보존. 11/4 업데이트 확인을 포함한 최종 전체1,480PASS/기존7SKIP·Analyze0. 동일소스5b5e5a8의 정식1.0.1(58) iOS IPA/Archive·Android AAB 서명/실제버전/운영설정 PASS. 스토어 업로드·기기58 설치0. 산출물/해시는 종합 보고서에 기록했다.
- 기존 APP41/58 산출물 및 A48 설치 앱·별도TEST56 보존. 운영 Auth·결제·기존 이용권/History 사실 변경0, Store업로드/제출/게시0. Owner계정 실제검수 승인: 일일무료 우선·추가최대3개, 아직 신규차감0.

## Owner 추가 결정 — 이용권 용어 통일

앱 전체 사용자 표시의 크레딧/Credit을 **이용권**으로 통일한다. 상품은 이용권1개·3개·5개·10개. 상품 구매 버튼 아래에 서버 확인/충전 지연 안내와 이용약관·환불조건 링크를 모으며 구매 전 같은 화면에서 접근 가능해야 한다. 내부 API/DB 필드, 상품 ID, 가격, 결제/영수증 계약은 유지한다. [종합 보고서](app-math-commerce-integration-report-20261103.md).

## 긴급 추가 — 앱 업데이트 확인

[Native 업데이트 확인](app-update-check-20261104.md)을 통합했다. 플랫폼별 숫자 버전/build, 공개 확인된 정책만 안내, OPTIONAL24시간 미루기, 승인된 minimum 미만 REQUIRED, 조회3초 timeout/fail-open·인증/온보딩 지연을 구현했다. 집중68PASS, SQL69PASS. Owner의 TEST 적용 승인 후 기존 후보와 동일한 SQL을 격리 TEST에 설치했다. 양 플랫폼 disabled/OPTIONAL, 실제 HTTP200·null 및 anon/auth 읽기 권한·private 차단·기존 데이터11종 count 보존 PASS. 운영 미적용·안내/필수 정책 비활성이다. 스토어 실제 공개 tuple과 실제기기 팝업/이동은 아직 미검수. 기존APP41에는 소급 적용되지 않는다.

## 이미 확인된 실기기 범위

- [후보 A 검수](app-candidate-a-owner-qa-report-20261103.md): Kakao 시스템 인증 취소/재시도/홈·세션, 이메일 오류·재시도·세션, Google 기존 흐름, Apple48 온보딩·닉네임·재실행 PASS. 학교·대학·전공·MY 미설정·기존 PDF/인문 결과 조회 PASS. 모든 신규 가입 조합·iPad/Android 전체 PASS는 아님.
- [후보 B 검수](app-candidate-b-device-web-qa-20261103.md): TEST56 전체 체크(읽힌 uncertain 포함·미인식만 제외) Owner PASS. 긴 Q1 학생 근거 펼침/접기·문단/수식·개선 과제 복귀 Owner PASS. 현재 표시 구조 수용, 추가 실제 사례로 점진 개선 확정.
- 실제 카메라 촬영/크롭/원본 대조·전사 수정·키보드 닫기까지 확인. 동일 실제 사진의 확정→평가→무료 재첨삭→History 전체 실기기, 신규 Native 혼합 사진 전체 Provider E2E는 아직 별도다. WEB/Simulator 과거 PASS로 대체하지 않는다.

## 운영·품질 잔여

OCR 부호·지수·분수·수치 정확도, 공식 근거별 힌트/완성 해설 품질, 실제 기기 전체 제출, 최종 공개 설정 후 신규 Provider 운영 스모크가 남아 있다. 미검증을 PASS로 올리지 않는다. 학습 정책은 하루1회·00KST·이월0, 유료1+무료1 반복·무료14일, 베타 종료2026-11-11 00KST를 유지한다.

## 재개·보존 경로

1. [종합 보고서](app-math-commerce-integration-report-20261103.md), [APP A/B 통합 상세](app-release-integration-20261103.md), [TASK16-K](task16k-beta-activation-20261103.md).
2. [Kakao](kakao-ios-system-auth-20261103.md), [온보딩 V2](onboarding-v2-final-integration-20261103.md), [APP41 배포/설정](final-store-rc-1.md).
3. [Task Routing](index.md#task-routing-map), [결정](decisions.md), [장기 데이터 보존](longitudinal-learning-admissions-data-strategy.md), [로그](log.md).

이전 B56 현재상태 전문은 [입력 스냅샷](history/app-review-b56-input-20261103.md)에 보존했다. A42~48/B49~56의 세부 검수는 해당 기능 문서가 근거다. 과거 Daily Sync/수집 상태는 [기존 스냅샷](history/app-review-candidate-a-input-20261103.md#daily-sync-status)과 [자료 마감](materials-final-closeout-2026-09-27.md)을 따른다. 이번 작업은 ingestion 변경을 포함하지 않는다.

## Daily Sync status

기존 수집·Daily Sync 상태는 [이전 입력 스냅샷](history/app-review-candidate-a-input-20261103.md#daily-sync-status)과 [자료 마감](materials-final-closeout-2026-09-27.md)을 따른다. 이번 통합에서 ingestion·수집 공개 정책은 변경하지 않았다.
