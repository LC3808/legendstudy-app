# 작업04-C 실제 계정·기기 검증 — 2026-11-11

상태: **핵심 홈 저장·복원 DONE / 전체 검수 PARTIAL / 신규 온보딩 NOT TESTED**.
[운영 적용 영수증](task04c-home-production-20261111.md)과 [04-B 검증](task04b-production-preflight-20261111.md)의 후속이다.
작업 브랜치 `codex/task04-applications-app75`, 홈 기능 검수 소스 `efb6b59e884de110254397be3318c9710ea3c754`.
최종 기록 커밋은 이 문서의 Git history로 확인한다. 현재 HEAD를 영구 정의하지 않는다.

## 운영 상태와 보존

Migration `20261111103058_task04c_home_configuration`은 19:30:58 KST 적용 완료로 Owner가 확정했다.
홈 table1/RPC2, 기존371함수·119정책 불변, 주요9개 table1,168행 보존, 탈퇴 대기3계정 접근 차단은 기존 영수증의 결과다.
이번 검수에서 SQL을 재적용하거나 schema/RPC/Auth 설정을 변경하지 않았다. 운영 ERASING 계정은 만들지 않았다.
기존 테스트 계정 A/B만 사용했고 비밀번호는 Owner가 기기에서 직접 입력했다. 서버 변경은 A의 정상 인증된 홈 저장 RPC뿐이다.
읽기 전용 SELECT로 A revision8 및 기본 구성 복원, B 이력0행을 확인했다. 사용자 UUID·세션·메일 원문을 증거 파일에 남기지 않았다.

## 실제 계정 검수

| 항목 | 결과·근거 | 상태 |
|---|---|---|
| 로그인 후 조회 | iPhone A 실제 세션으로 홈 RPC 조회 | DONE |
| 카드 표시·숨김·드래그·저장 | iPhone 네이티브 터치 후 운영 RPC 재조회가 UI 구성과 일치 | DONE |
| 완전 종료·재실행 복원 | 앱 재설치 없이 프로세스 종료/실행, 세션·서버 구성 복원 확인 | DONE |
| 로그아웃·동일 계정 로그인 | Owner 직접 A 재로그인 후 저장된 구성 복원 | DONE |
| 다른 계정 격리 | 동일 iPhone A→B 전환, B 기본 구성이 B 서버 값과 일치하고 A 구성이 섞이지 않음. B 저장0 | DONE(이 범위) |
| 기본 구성 초기화 | 일반 QA 앱에서 Owner ‘숨김 저장과 기본 구성 초기화 모두 정상’ 회신. A revision8 20:48:51.636608 KST, 기본6개 ON·선택3개 OFF | DONE |
| 조회 실패 시 설정 보호 | 실제 기기 캐시를 쓰는 repository에 로컬 실패 주입, 기존 캐시 보존. 운영 장애 유발 없음 | DONE(주입 검증) |
| 저장 실패 | 자동 테스트에서 기존 저장값/실패 상태 확인. 실기기 서버 저장 장애 유발 안 함 | PARTIAL |
| 신규 온보딩 선택/건너뛰기 | A/B 모두 기존 공유 프로필이 있어 재온보딩 강제하지 않음. 신규 가입 시도는 이메일 인증 장애로 진입하지 못함 | NOT TESTED |
| 두 계정 모두 비기본 설정·다기기 동시 수정 | B 설정을 변경하지 않아 이 조합은 수행하지 않음 | NOT TESTED |

초기 A의 설정 미저장 상태는 검수 후 명시적 기본 설정으로 저장됐다. 화면 구성은 원래대로 복원했지만 DB를 최초0행 상태로 되돌리지는 않았다.
A 이력8행을 보존하고 삭제하지 않았다. B의 onboarding 완료 시각은 NULL이지만 기존 프로필이 있으므로 신규 계정으로 취급하지 않는다.

## 실기기와 UI

별도 `com.legendstudy.app.task04c.qa` / **LS04C QA 1.0.2(76)**를 사용했다. 네이티브 프로젝트의 QA ID·서명·개발 설정은 임시 복사본에만 적용했다.
일반 `main.dart` 앱으로 복원했으며 테스트 harness가 기본 실행 경로에 들어가지 않는다. 이메일 로그인 검수용으로 OAuth/Analytics 등 QA 플래그는 꺼져 있어 네이티브 OAuth 회귀 PASS로 확대하지 않는다.

| 기기 | 확인한 범위 | 상태 |
|---|---|---|
| iPhone12 Pro Max / iOS26.6.1 | 설치·실행, 실제 A/B 계정, 홈 편집이 종 왼쪽 같은 행, 카드16dp, 표시/순서/저장·복원. 학교 급식 카드와 학습·D-Day 표시 | DONE(범위 내) |
| Galaxy S8 / Android9 / 약360dp | 네이티브 guest 앱: 숨김·드래그·저장·로컬 저장 재조회·초기화,16dp/아이콘 위치, 스크롤·터치, LAB/수능/논술/학습/학교순위/MY 진입 | DONE(범위 내) |
| Android 실제 B 계정 | Owner 로그인 후 홈·편집 화면 확인. B 서버 설정은 수정 안 함 | PARTIAL |
| 작은 화면·큰 글씨 | 실제 Android360dp와 widget320px/2배 등 배치 검사. 작은 iPhone 실기기는 없음 | PARTIAL |

[Android guest 홈 스크린샷](assets/task04c-final-20261111/android-guest-home.png) · [비식별 검증 결과](assets/task04c-final-20261111/verification.json).
기존 iPhone `com.legendstudy.app` **1.0.2(75)** 설치 메타데이터와 Android 기존 앱 **1.0.2(67)**의 version/설치 시각/경로가 동일함을 확인했다. Android 기존 앱을 APP75라고 보고하지 않는다. 삭제·덮어쓰기0.

## 자동 검증과 실기기 한계

- 홈 검수 시 전체 **2,510 PASS / 8 SKIP / 5 FAIL**, analyze PASS. iOS profile/no-codesign 및 Android debug 빌드 PASS.
- 온보딩42, 홈 설정14, 복원1, 간격4, 대학 소식12 PASS. Auth/프로필/타이머·offline/outbox/학교순위·초대/채점/결과/논술/PDF 회귀는 전체 suite에 포함했다.
- 기존 FAIL5: D3 runner의 이전 ‘다시 학습으로’ 기대값1, mobile IA mock360/428×글씨1/2의 과거 과목 dropdown 기대값4. [APP75 동일 조건 비교](task04b-production-preflight-20261111.md#기존-fail5--app75-동일-조건-비교)와 동일하다. 제품 신규 실패0; 전체 green 아님.
- 실제 수능 답안 제출·채점 결과 재조회, 오프라인 학습 업로드, 친구 초대 수신, PDF 전체 흐름을 이번에 실기기로 재수행하지 않았다. 자동 테스트와 화면 진입을 실제 운영 E2E로 확대하지 않는다.
- 이후 [알림 안정화](notification-loading-fix-20261111.md)의 전체 suite는 2,532 PASS/8 SKIP/동일5 FAIL이다.

검수 harness의 첫 단계는 PASS. 두 번째 단일 스크립트 전체는 PASS가 아니다. Owner 수동 로그인 대기·테스트 종료 상태 때문에 splash에서 대기했고 일반 앱으로 복원했다.
A 재로그인과 B 격리 checkpoint는 통과했다. 마지막 A 비교가 고정 revision2를 기대했으나 검수 중 별도 정상 저장2건으로 최신 revision4가 반환돼 assertion이 실패했다.
읽기 전용 이력과 화면 값으로 최신 서버 구성 반환을 확인했고 finally의 revision5 복원 및 Owner 수동 초기화 revision8로 마무리했다.
후속 harness는 A 복귀 시 최신 서버와 비교하도록 정정했으나 이 수정 후 전체 수동 시퀀스를 다시 실행하지 않았다. 최종 수동 확인과 단일 스크립트 결과를 구분한다.

## 남은 범위와 종료 판단

- **04-A DONE**: 홈 커스터마이징 구현. **04-B DONE**: 운영 사전 검증.
- **04-C PARTIAL**: 운영 적용·기존 계정 핵심 저장/복원 DONE. 신규 온보딩과 위 미검증 조합을 남긴 이번 검수 결과를 기록한다. 모든 항목 PASS 또는 작업04 전체 완료로 처리하지 않는다.
- **04-D HOLD**: C 대학 소식 동시 적재 중 페이지 중복/누락 구조 보완, D 공식 자료 검수·별도 적재 승인 대기.
- 대학 소식은 UI/매칭/빈 상태·이동의 테스트 환경 검사와 실제 카드 표시까지만 확인했다. 실제 공식 일정 제공 완료가 아니다. C/D SQL·운영 일정 적재0.
- 신규 온보딩 재시도는 [이메일 인증 조사](email-verification-audit-20261111.md)의 발송 경로 확인 후 기존 계정을 재설정하지 않고 수행한다.
- 운영 WEB 배포·릴리스 병합·스토어 제출0. 추가 운영 승인이나 신규 데이터를 이번 문서로 승인하지 않는다.

[장기 데이터 보존 전략](longitudinal-learning-admissions-data-strategy.md) 및 [04-B 7항 검토](task04b-production-preflight-20261111.md#보존-검토와-owner-승인-항목)를 계승한다. 설정 revision/계정 identity/소속 이력/Interest·Application·Outcome 분리는 변경하지 않았다.
