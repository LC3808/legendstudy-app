# 이메일 인증 후 온보딩 미노출 — 2026-11-11

## 범위와 설치 근거

독립 `codex/email-auth-stabilization-20261111`, 시작 HEAD `fe36cc6`.
기존 `c5cd349` 이메일 UX 보존. LAB 브랜치 수정·병합·cherry-pick 없음.
Owner는 Resend 인증 메일 수신→인증→이메일 로그인 성공, 일반 iPhone 앱에서 온보딩 미노출을 보고했다.
SMTP 성공은 Owner 실기기 보고이며 이번 에이전트가 운영 설정을 변경하거나 발송하지 않았다.

연결된 **iPhone 12 Pro Max**의 `devicectl device info apps` 읽기 결과:
`com.legendstudy.app`, **레전드스터디+ 1.0.2(75)**. 별도 LS04C QA는76이다.
[APP75 설치 영수증](task03-result-ux-20261111.md)의 소스는
`c9b483018bcada179050595cf78c8ca4a3d213ba`. 소스 SHA는 설치 영수증 매핑이며
현재 실행 바이너리 안에서 추출한 SHA는 아니다. 함께 연결된 iPhone17 Pro Max는 잠겨 조회 실패;
Owner가 그 기기를 의미했다면 설치본 식별은 추가 확인 필요.
APP75에도 최신 닉네임/학교 검색 온보딩은 포함하지만 아래 gate 결함이 존재한다.
이 브랜치의 홈6단계 및 이메일 UX 후속은 APP75 설치본과 구분한다.

## 원인과 최소 수정

이메일 로그인 성공 → `AuthPage._passwordAuth`의 id-only profile upsert →
`currentProfileProvider`의 계정별 조회 → router의 `onboardingRedirect`.
기존 gate는 profile 행만 있으면 준비 완료로 판단하여 NULL 완료 marker를 무시했다.
APP75와 현재 코드 모두 같은 조건이다. Auth 가입/인증 성공이 온보딩 완료를 의미하지 않는다.

`onboardingProfileReady`를 `hasCompletedOnboarding` 기준으로 수정했다.
- 인증 전/guest: 온보딩 대상 아님.
- 인증된 계정, profile 없음 또는 완료 marker NULL: 온보딩 시작/재개.
- profile에 일부 정보 있음, marker NULL: 진행 중일 수 있으나 시작 여부를 별도로 확정할 데이터는 없음.
- `onboarding_completed_at` 있음: 완료 또는 허용된 명시적 건너뛰기. 선택 정보가 없어도 홈 진입.
- 조회 중/오류: 신규 계정으로 오인하지 않고 대기. 계정 변경 시 기존 provider 재조회/owner guard 유지.
- auth 복구·온보딩 route 예외 유지. 공유 gate를 사용하는 앱 업데이트 팝업도 온보딩 완료까지 대기.

수정 소스: `lib/features/onboarding/onboarding_gate.dart`.
회귀: `test/personalization_onboarding_test.dart`, `test/app_update_test.dart`.
Auth SDK/공급자/토큰 교환/프로필 생성·저장 계약 변경 없음.

## 기존 회원 영향 / 입력 보존

운영 SELECT 집계만 수행: 삭제되지 않은 비익명 Auth 계정553, profile534,
완료/skip marker471, profile은 있으나 marker 없는 계정63. 개별 식별자 취득/노출 없음.
471계정은 완료 상태 유지. 63계정과 profile 없는19계정은 인증 상태에 따라 온보딩 대상이 될 수 있다.
marker 없는 오래된 WEB 계정도 예외로 추정하지 않는다. 현재 Owner의 “profile 존재만으로 완료 판단 금지”를 적용한다.
과거 backfill 기록은 [기존 설계](personalization-onboarding.md)에 보존하며 재실행하지 않는다.

학교·대학·전공·닉네임 등 선택 입력을 새 필수 항목으로 만들지 않는다.
완료 또는 허용된 skip이 성공해야 gate를 통과한다. 저장 실패 시 기존 재시도 UX 유지.
단계 이동으로 저장된 상태/학년/닉네임과 기존 학교·대학·전공은 재조회로 복원하고 지우지 않는다.
**제한:** 아직 확인/다음을 누르지 않은 화면 내 임시 입력, 단계 번호, 저장 전 홈 카드 draft는
현재 메모리 상태이므로 프로세스 강제 종료 후 보존되지 않는다. 이 최소 gate 수정에 새로운 로컬
개인정보 저장소를 추가하지 않았다. 저장 전 draft까지 포함한 완전한 중단 재개는 미완료이며 릴리스 검수 항목이다.

데이터 보존7항목: 발생/기록/정정 시점 변경0; 기존 원본/snapshot 변경0;
current UPDATE/history 변경0; auth identity/owner guard 유지;
Learning/Decision/Outcome 구분 영향0; 권한·retention·외부공유 변경0;
derived metric을 raw fact로 도입0. 신규 storage/수집/운영 migration 없음.

## 검증

- 온보딩/이메일/인증 lifecycle/Apple·Google·Kakao 관련10파일 **144 PASS**.
- 앱 업데이트/최초 개인화/개인 repository/프로필 상태4파일 **68 PASS**.
- 신규 mock-transport 검사: 로그인 id-only upsert → 미완료 gate → 일부 저장 → fresh repository로
  재조회/보존 → 완료 → 재로그인 홈 → 다른 계정 미완료 → 원 계정 완료 보존.
- 기존 widget 검사: 명시적 skip, 완료 실패/재시도, nickname 이전 owner 응답 차단,
  저장된 profile 재개·무변경 skip 보존 등 PASS.
- `flutter analyze`: No issues found. 실제 SMTP/소셜 공급자/운영 계정 E2E와 구분한다.
- 수정 앱 설치/실행·실기기 신규 온보딩 완료·강제 종료 재개·Apple/Google 로그인은 **NOT TESTED**.
  Owner의 기존 설치본 이메일 수신/인증/로그인 성공만 실기기 근거다.

## 충돌과 후속

LAB `bcbee72` 대 `4489603` 변경 범위와 비교: 수정 Dart/test 파일 겹침0.
wiki/index/current-status/log/decisions는 공통 편집 파일이므로 향후 통합 시 해당 항목만 수동 병합한다.
기존 LAB SQL/Registry/코드 변경0. Auth/SMTP/운영 DB/RPC/기존 사용자 데이터/스토어 변경0.

다음: 설치 대상 기기 확정 → 독립 검수 빌드로 신규 로그인/온보딩/완료/재로그인 확인 →
미완료 재개/계정 전환/Apple·Google 실기기 검수 → 저장 전 임시 draft 보존 범위 해결 → 릴리스 통합.
이번 결과는 코드 결함 수정·격리 회귀 완료이며 실기기 전체 안정화 완료가 아니다.
