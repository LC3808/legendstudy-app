# Current Status

## APP·수리·상경 기존 서비스 통합 — 2026-11-03

현재 작업 기준은 [Owner/ChatGPT 종합 보고서](app-math-commerce-integration-report-20261103.md)다. Owner는 보고서 작성·기존 서비스 통합·수리/상경 차단 해제·배포용 빌드 진행을 지시했다. 과거 HOLD는 당시 이력으로 보존하며, 최신 승인과 실제 배포/적용 완료를 구분한다. 스토어 업로드·제출은 미실행이다.

- APP `codex/app-review-candidate-b-20261103`: 후보 A 인증·온보딩·MY·선택형 닉네임 + B 수리 UX 통합. 자연계 일괄 차단 대신 정확한 공개 Catalog와 서버 실행 상태를 확인한다. 혼합형 사진은 기존 Math 인식/확인 후 Essay 시험 회차 하나에 제출한다. 입력이 바뀌면 확인본 재사용 차단.
- WEB `codex/math-commerce-release-20261103`: 실제 운영 `c9bda913`을 기준으로 Math 후속23개 커밋을 통합. 기존 운영 관리/Analytics/결제 변경 보존. TEST 브랜치를 운영에 그대로 덮어쓰지 않는다.
- 현재 운영 읽기 확인: 기존16시험(인하 자연15·한양2026 상경1)의 canonical46문항과 공식 평가 패키지 조회 PASS. legacy 건국1leaf를 보존한47leaf 초기 공개 후보. 의예/미연결/합성 문제와 TEST 전용 한양2024 자연 ID는 제외. 시험 데이터 신규 생성/복제 없음.
- 운영에는 coaching/혼합 coaching/quote/continue 증분 RPC가 아직 없다. 운영 함수 원문·권한·run-table 구조를 보존한 증분 SQL을 로컬 PG17에서 검증 중이며 원격 미적용이다. 일일 베타 이용권을 제외하던 Math 선택 조건도 기존 claim/credit_source/eligible 계약으로 연결한다. 임의 유료 대체 없이 서버 선택 출처를 확인·동의한다.
- APP 통합1차 전체1,431PASS/7SKIP·Analyze0, signed iOS57 1차 빌드 성공. 이후 이용권 출처 연결·아래 용어 변경을 포함한 최종 회귀/배포 빌드는 종합 보고서 실행 마감 절에서 확정한다.
- 기존 APP41 소스·IPA·브랜치 및 A48 정식 설치 앱, TEST56 별도 앱 보존. 운영 DB/Auth/Credit/Ledger/결제/Provider/WEB 변경과 Store 제출을 완료했다고 주장하지 않는다.

## Owner 추가 결정 — 이용권 용어 통일

앱 전체 사용자 표시의 크레딧/Credit을 **이용권**으로 통일한다. 상품은 이용권1개·3개·5개·10개. 상품 구매 버튼 아래에 서버 확인/충전 지연 안내와 이용약관·환불조건 링크를 모으며 구매 전 같은 화면에서 접근 가능해야 한다. 내부 API/DB 필드, 상품 ID, 가격, 결제/영수증 계약은 유지한다. [종합 보고서](app-math-commerce-integration-report-20261103.md).

## 이미 확인된 실기기 범위

- [후보 A 검수](app-candidate-a-owner-qa-report-20261103.md): Kakao 시스템 인증 취소/재시도/홈·세션, 이메일 오류·재시도·세션, Google 기존 흐름, Apple48 온보딩·닉네임·재실행 PASS. 학교·대학·전공·MY 미설정·기존 PDF/인문 결과 조회 PASS. 모든 신규 가입 조합·iPad/Android 전체 PASS는 아님.
- [후보 B 검수](app-candidate-b-device-web-qa-20261103.md): TEST56 전체 체크(읽힌 uncertain 포함·미인식만 제외) Owner PASS. 긴 Q1 학생 근거 펼침/접기·문단/수식·개선 과제 복귀 Owner PASS. 현재 표시 구조 수용, 추가 실제 사례로 점진 개선 확정.
- 실제 카메라 촬영/크롭/원본 대조·전사 수정·키보드 닫기까지 확인. 동일 실제 사진의 확정→평가→무료 재첨삭→History 전체 실기기, 신규 Native 혼합 사진 전체 Provider E2E는 아직 별도다. WEB/Simulator 과거 PASS로 대체하지 않는다.

## 운영·품질 잔여

OCR 부호·지수·분수·수치 정확도, 공식 근거별 힌트/완성 해설 품질, 실제 기기 전체 제출, 최신 DB 증분/공개 설정 적용 후 기존 인문 회귀와 운영 스모크가 남아 있다. 미검증을 PASS로 올리지 않는다. 학습 정책은 하루1회·00KST·이월0, 유료1+무료1 반복·무료14일, 베타 종료2026-11-11 00KST를 유지한다.

## 재개·보존 경로

1. [종합 보고서](app-math-commerce-integration-report-20261103.md), [APP A/B 통합 상세](app-release-integration-20261103.md), [TASK16-K](task16k-beta-activation-20261103.md).
2. [Kakao](kakao-ios-system-auth-20261103.md), [온보딩 V2](onboarding-v2-final-integration-20261103.md), [APP41 배포/설정](final-store-rc-1.md).
3. [Task Routing](index.md#task-routing-map), [결정](decisions.md), [장기 데이터 보존](longitudinal-learning-admissions-data-strategy.md), [로그](log.md).

이전 B56 현재상태 전문은 [입력 스냅샷](history/app-review-b56-input-20261103.md)에 보존했다. A42~48/B49~56의 세부 검수는 해당 기능 문서가 근거다. 과거 Daily Sync/수집 상태는 [기존 스냅샷](history/app-review-candidate-a-input-20261103.md#daily-sync-status)과 [자료 마감](materials-final-closeout-2026-09-27.md)을 따른다. 이번 작업은 ingestion 변경을 포함하지 않는다.

## Daily Sync status

기존 수집·Daily Sync 상태는 [이전 입력 스냅샷](history/app-review-candidate-a-input-20261103.md#daily-sync-status)과 [자료 마감](materials-final-closeout-2026-09-27.md)을 따른다. 이번 통합에서 ingestion·수집 공개 정책은 변경하지 않았다.
