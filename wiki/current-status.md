# Current Status

## APP review integration — 2026-11-03

[통합 후보 A/B·빌드·검수·운영 차단](app-release-integration-20261103.md)이 현재 릴리스 작업 기준이다.
APP41 소스/IPA/기존 작업 폴더 미커밋 Xcode 설정 보존. 별도 `codex/app-review-candidate-a-20261103`.

- 후보 A: 지정 온보딩 V2 `30edf235` 병합, Kakao 시스템 인증 수정 `2c3ce78` 재사용, MY 미설정 안내 포함.
- Flutter Analyze PASS; 전체 1,356 PASS / 7 SKIP. iOS 1.0.1(42) signed Archive/IPA 및 Android42 signed AAB PASS.
- 바이너리 Supabase/Google 설정 포함, Apple entitlement/서명 확인. Store 업로드/재제출 없음.
- 후보 A42 iPhone12ProMax: Owner 확인으로 Kakao 인증창→취소·재시도→로그인·홈 복귀 및 앱 완전 종료 후 홈·MY 동일 계정 유지 PASS. MY 기존 정보 유지·빠진 정보만 안내도 Owner PASS. 학교 검색·카드·선택 확인 버튼도 Owner PASS. 기존 PDF·인문논술 History·결과 조회·뒤로 이동도 Owner PASS. 기존 이메일 로그인·홈·MY도 Owner PASS. 이메일 재실행 세션·오입력 차단/오류 안내·정상 재시도도 Owner PASS. Google/Apple 전체 인증 matrix·신규 온보딩 수정본은 검수 대기. MY 실제 학교 저장·재실행 복원·안내 해제는 Owner PASS.
- 현재 worktree는 후보 B `codex/app-review-candidate-b-20261103`. TASK16-K 후속 `d7d5bb1` 통합, 14개 충돌 해결, Analyze 및 전체1,383 PASS/7 SKIP. signed iOS43 Archive/IPA·Android43 AAB PASS. Native 혼합 신규 사진 제출·실기기 전체 loop는 미완료. 운영 수리·상경 활성화 HOLD.
- TEST Auth: email만 활성; Kakao/Google/Apple 비활성. 운영 Auth 설정 변경 없음. Owner 후속 정식 빌드 지시로 후보 A42를 iPhone12ProMax에 업데이트 설치·실행 PASS. 신규 온보딩 수정본 검수 대기.
- 베타 종료 2026-11-11 00:00 KST, 하루1회/이월 없음/사이클당 재첨삭1회·14일 정책 유지.

## P0 실기기 신규 발견

Owner 사진으로 학년 버튼 세로 확장→검색 버튼이 아래로 밀림→키보드 위 `다음`을 검색으로 오인하는 동선 확인. 학년 한 줄·입력창 내 검색·학교 키보드 동안 footer 숨김·미확정 검색어 이동 차단 적용. 집중32PASS/렌더2PASS, 신규45 Release·수정본 실기기 검수 준비. 기존42 MY 학교 저장·재실행 복원·누락 안내 해제와 안내 화면 계정 유지 Owner PASS. [상세](app-release-integration-20261103.md#owner-화면-근거배치-수정-및-후속-검수--2026-11-03).


## 재개 경로

1. [Kakao 구현·검수 항목](kakao-ios-system-auth-20261103.md), [온보딩 V2](onboarding-v2-final-integration-20261103.md).
2. [APP41 배포 이력·정의 복구](final-store-rc-1.md#task18-build41-owner-internal-recovery--2026-11-02).
3. 후보 A 실제 iPhone 검수, 후보 B Native 혼합 제출·OCR 품질·운영 연결 보완 후 별도 출시 판단.
4. Owner 승인 없이 운영 DB/Auth/Credit/Ledger/결제·WEB·Store 변경 금지.

## 기존 상태 보존

통합 전 현재상태 원문은 [입력 스냅샷](history/app-review-candidate-a-input-20261103.md)에 보존했다.
이 스냅샷의 과거 PASS·HOLD는 날짜별 증거이며 현재 배포 판정이 아니다.
[Task Routing](index.md#task-routing-map), [결정](decisions.md), [장기 데이터 보존](longitudinal-learning-admissions-data-strategy.md), [로그](log.md)를 함께 확인한다.

## Daily Sync status

기존 수집·공개 상태는 [통합 전 스냅샷](history/app-review-candidate-a-input-20261103.md#daily-sync-status)과 [자료 최종 마감](materials-final-closeout-2026-09-27.md)에 보존. 이번 릴리스 통합에서 ingestion/공개 데이터는 변경하지 않았다.

후속: Owner 정식 빌드 지시로 A42 Release를 iPhone12ProMax에 업데이트 설치·실행 PASS. Kakao 기본 흐름 Owner PASS, 온보딩/MY 검수 대기, B 미설치·Store HOLD. [기록](app-release-integration-20261103.md#후보-a-release-재빌드실기기-설치--2026-11-03).
