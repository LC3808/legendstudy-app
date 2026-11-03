# Current Status

## APP review integration — 2026-11-03

[ChatGPT 전달용 후보 A 검수 보고서](app-candidate-a-owner-qa-report-20261103.md) 작성. A48 확인 흐름 PASS·전체 CONDITIONAL_READY·Store HOLD. Kakao/이메일/Google/Apple의 확인 범위를 구분하며 미검증 항목을 전체 PASS로 올리지 않는다.

[통합 후보 A/B·빌드·검수·운영 차단](app-release-integration-20261103.md)이 현재 릴리스 작업 기준이다.
APP41 소스/IPA/기존 작업 폴더 미커밋 Xcode 설정 보존. 별도 `codex/app-review-candidate-a-20261103`.

- 후보 A: 지정 온보딩 V2 `30edf235` 병합, Kakao 시스템 인증 수정 `2c3ce78` 재사용, MY 미설정 안내 포함.
- Flutter Analyze PASS; 전체 1,356 PASS / 7 SKIP. iOS 1.0.1(42) signed Archive/IPA 및 Android42 signed AAB PASS.
- 바이너리 Supabase/Google 설정 포함, Apple entitlement/서명 확인. Store 업로드/재제출 없음.
- 후보 A42 iPhone12ProMax: Owner 확인으로 Kakao 인증창→취소·재시도→로그인·홈 복귀 및 앱 완전 종료 후 홈·MY 동일 계정 유지 PASS. MY 기존 정보 유지·빠진 정보만 안내도 Owner PASS. 학교 검색·카드·선택 확인 버튼도 Owner PASS. 기존 PDF·인문논술 History·결과 조회·뒤로 이동도 Owner PASS. 기존 이메일 로그인·홈·MY도 Owner PASS. 이메일 재실행 세션·오입력 차단/오류 안내·정상 재시도도 Owner PASS. A48 Apple 로그인·온보딩·재실행은 아래 Owner PASS. Google 기존 계정 취소·재시도·홈/MY·재실행 세션도 Owner PASS(기존 결과 재사용). 전체 Provider별 신규 가입/기타 미확인 항목은 별도. A46 온보딩 후속 결과는 아래 참조. MY 실제 학교 저장·재실행 복원·안내 해제는 Owner PASS.
- 현재 worktree는 후보 B `codex/app-review-candidate-b-20261103`. TASK16-K 후속 `d7d5bb1` 통합, 14개 충돌 해결, 통합 기준 전체1,404 PASS/7 SKIP·Analyze PASS, 제출 버튼 후속16PASS. 기존 signed iOS43 Archive/IPA·Android43 AAB PASS. 가독성·제출 버튼 및 LAB 진입·원본 대조·일괄 확인/필수 번호 보완 TEST56 signed Release를 별도 LS Math TEST에 설치, 기기 잠금으로 자동 실행 대기·기존 A48 보존. Native 혼합 신규 사진 제출·실기기 전체 loop는 미완료. 운영 수리·상경 활성화 HOLD.
- TEST Auth: email만 활성; Kakao/Google/Apple 비활성. 운영 Auth 설정 변경 없음. Owner 후속 정식 빌드 지시로 후보 A42를 iPhone12ProMax에 업데이트 설치·실행 PASS. A46 온보딩 후속 결과는 아래 참조.
- 베타 종료 2026-11-11 00:00 KST, 하루1회/이월 없음/사이클당 재첨삭1회·14일 정책 유지.

## 후보 B TEST 검수 시작

[실기기·WEB 검수 기록과 Owner 경로](app-candidate-b-device-web-qa-20261103.md). TEST WEB 로그인·Q1/Q2 저장 결과·원본/전사·과제/힌트/공개 풀이·상경 최초/무료 결과 조회 및 자연계 재작성 진입 확인. 새 Provider/차감 없음. 수식 일반 텍스트 잔존·일반적 힌트·목록 메타데이터·빈 입력 안내 문제는 PARTIAL. B49 저장 결과 화면 표시 Owner 확인, 가독성·버튼/줄 간격·소제목 구분 보완 요청→Native 표현 보완·TEST50 설치/실행 및 집중15/전체1404PASS, 제출 화면 버튼 외 가독성 Owner 수용. 버튼 간격/용어 후속16PASS·B52 두 버튼 간격/역할·새로고침→결과 열기 Owner PASS. 단독 입력 화면의 문제 본문 텍스트 나열/공식 PDF 미연결 GAP 확인; Native 혼합 신규 사진 제출 및 전체 루프 미완료, 운영 HOLD.

## P0 실기기 신규 발견

Owner 요청으로 원본 대조 고정230 높이를 실제 수식/본문 높이(기본96~최대320)로 조절하고 Primary 1.5px 테두리·기존 원본 전체 화면 확대 연결. 관련25PASS·Analyze/Wiki PASS, TEST53 signed Release·iPhone 설치/실행 확인(A48 보존), 대조 높이/테두리/확대 복귀 Owner PASS. 문제 원문 PDF 미연결은 별도 GAP. [B53 범위](app-candidate-b-device-web-qa-20261103.md#b53-원본-대조-높이테두리-보완--2026-11-03).

[B54](app-candidate-b-device-web-qa-20261103.md#b54-답안-확인진행-표시결과-근거-정리--2026-11-03): 인문 진행 바 보라색 재사용·실제 OCR/첨삭 상태 읽기 폴링·간결한 버튼/완료 결과 연결·학생 근거 문단/수식/펼침·정상 영역 일괄 확인 구현. 불확실 영역 개별 확인/최종 동의 유지, Provider0. 전체1,418PASS/7SKIP·Analyze/Wiki PASS·TEST54 signed Release iPhone 설치/실행(A48 보존), B54 일괄 확인 무반응 Owner 보고로 아래 B55 후속 진행; 나머지 새 UI 전체 검수는 별도 대기.

[B55](app-candidate-b-device-web-qa-20261103.md#b55-일괄-확인-동작필수-영역-번호--2026-11-03): 일괄 확인 가능0개에서도 실행 결과·필수 번호 표시, 미식별 수정/기호·값 대조 구분, 번호 이동/복귀·남은 개수 갱신·반복 클릭 체크 보존. 관련24PASS(저장 한양대 재현 포함)·Analyze/Wiki PASS, TEST55 signed Release iPhone 설치·실행(A48 보존). 불확실 영역 개별 확인/최종 동의 유지·Provider0. Owner가 일괄 체크 의도 불일치를 정정함. 아래 B56이 최신 요구다.

[B56](app-candidate-b-device-web-qa-20261103.md#b56-owner-정정전체-내용-체크--2026-11-03): Owner 정정에 따라 읽힌 모든 영역(uncertain 표시 포함)을 한 번에 체크하고 미인식/빈 영역만 제외·번호 안내. 모두 읽혔으면 최종 체크 및 답안 입력 완료 활성화, 자동 저장/평가 없음. 관련25PASS·Analyze/Wiki PASS·TEST56 signed Release iPhone 설치 확인(A48 보존). 기기 잠금으로 자동 실행 미확인, Owner 잠금 해제 후 전체 체크 검수 대기.

B51 일반 LAB 복귀 시 한양대 `서비스 확인 중` 정체: 두 상태조회 API가 TEST gate에서 HTML401을 반환함을 확인. TEST WEB `8939034`/Pages `626fa92d`로 정확한 인증 GET 경로만 연결, 실제 두 조회200·익명/잘못된 JWT 거절·환경 설정 보존 확인. Native 실패 자동 재시도 대신 기존 오류/재시도 표시, 관련29PASS·WEB31PASS·Analyze/type/build PASS. TEST52 signed Release·iPhone 설치/실행 확인(A48 보존), 일반 LAB→한양대→기존 Q2 결과 조회 Owner PASS. 제출 버튼 간격·동작도 Owner PASS, 단독 입력 화면 문제 원문 표시 연결은 보완 필요. [상세](app-candidate-b-device-web-qa-20261103.md#b51-lab-대학-진입-실패test-연결-수정--2026-11-03).

Owner 사진으로 학년 버튼 세로 확장→검색 버튼이 아래로 밀림→키보드 위 `다음`을 검색으로 오인하는 동선 확인. 학년 한 줄·입력창 내 검색·학교 키보드 동안 footer 숨김·미확정 검색어 이동 차단 적용. A전체1362PASS/7SKIP·Analyze PASS·집중32PASS/렌더2PASS, B집중47PASS. A45 signed iOS/Android PASS·iPhone 업데이트 설치/실행 PASS. A45 학교 검색 정상 Owner PASS. 관심 대학에서도 하단 나중에 설정 오인 보고→입력창 검색·키보드 footer숨김·미검색 단계이동 방어 적용, 전체1365PASS/7SKIP·Analyze PASS·집중42PASS·mock렌더2PASS. A46 signed iOS/Android PASS·iPhone 설치/실행 PASS. A46 대학 검색→선택→전공→완료·MY/재실행 정보 유지 Owner PASS. Owner 승인으로 마지막 선택형 닉네임 5단계 추가·기존 저장/검증 재사용. 빈값/skip은 기존 이름 보존, 집중63PASS·전체1375PASS/7SKIP·Analyze PASS·mock렌더2PASS. A47 signed iOS/Android PASS·iPhone12ProMax 설치/실행 PASS, B 집중63PASS. Owner A47 진행 문제·재빌드 요청 후 동일 기능 iOS48 Release 빌드·서명·iPhone 설치/실행 확인. Owner 직접 계정 삭제 신고 확인(에이전트 삭제 없음). A48 Apple 로그인 후 온보딩·닉네임 저장·홈/MY·재실행 유지 Owner PASS(Owner 로그인 방식1 확인). A47 원인 미확정·동일 코드 재빌드이며 Provider별 인증 matrix는 PARTIAL. 기존42 MY 학교 저장·재실행 복원·누락 안내 해제와 안내 화면 계정 유지 Owner PASS. [상세](app-release-integration-20261103.md#owner-화면-근거배치-수정-및-후속-검수--2026-11-03).


## 재개 경로

1. [Kakao 구현·검수 항목](kakao-ios-system-auth-20261103.md), [온보딩 V2](onboarding-v2-final-integration-20261103.md).
2. [APP41 배포 이력·정의 복구](final-store-rc-1.md#task18-build41-owner-internal-recovery--2026-11-02).
3. 후보 A는 별도 보고서로 검수 범위 전달. 후보 B TEST52 일반 진입·기존 결과/제출 버튼 PASS 후 문제 원문 표시 연결→미확정 전사·전체 루프, Native 혼합 제출·OCR 품질·운영 연결 보완 후 별도 출시 판단.
4. Owner 승인 없이 운영 DB/Auth/Credit/Ledger/결제·WEB·Store 변경 금지.

## 기존 상태 보존

통합 전 현재상태 원문은 [입력 스냅샷](history/app-review-candidate-a-input-20261103.md)에 보존했다.
이 스냅샷의 과거 PASS·HOLD는 날짜별 증거이며 현재 배포 판정이 아니다.
[Task Routing](index.md#task-routing-map), [결정](decisions.md), [장기 데이터 보존](longitudinal-learning-admissions-data-strategy.md), [로그](log.md)를 함께 확인한다.

## Daily Sync status

기존 수집·공개 상태는 [통합 전 스냅샷](history/app-review-candidate-a-input-20261103.md#daily-sync-status)과 [자료 최종 마감](materials-final-closeout-2026-09-27.md)에 보존. 이번 릴리스 통합에서 ingestion/공개 데이터는 변경하지 않았다.

이전 A42 설치·검수 시작 기록은 [통합 보고서](app-release-integration-20261103.md#후보-a-release-재빌드실기기-설치--2026-11-03)에 보존한다. 현재 A48/B56 검수 상태는 위 항목을 따른다. Store HOLD.
