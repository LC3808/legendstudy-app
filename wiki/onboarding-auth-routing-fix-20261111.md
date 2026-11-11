# 이메일 인증 후 온보딩 미노출 — 2026-11-11

## 범위와 설치 근거

독립 `codex/email-auth-stabilization-20261111`, 시작 HEAD `fe36cc6`.
기존 `c5cd349` 이메일 UX 보존. LAB 브랜치 수정·병합·cherry-pick 없음.
Owner는 Resend 인증 메일 수신→인증→이메일 로그인 성공, 일반 iPhone 앱에서 온보딩 미노출을 보고했다.
SMTP 성공은 Owner 실기기 보고이며 이번 에이전트가 운영 설정을 변경하거나 발송하지 않았다.

**정정: Owner 재현 기기는 iPhone 17 Pro Max, 홈 화면에서 실행한 앱이다.**
`devicectl device info apps --include-default-apps`로 일반 배포 앱을 포함해 확인:
`com.legendstudy.app`, **레전드스터디+ 1.0.2(67)**, builtByDeveloper=false.
앞선 조회는 기본값이 개발용 앱만 포함하므로 빈 결과였으며 앱 미설치 근거가 아니었다.
iPhone12의 APP75를 재현 설치본으로 연결한 이전 보고를 철회한다.

[APP67 빌드 기록](app67-essay-admission-20261106.md)에 대응하는 소스는
`2fa70bf9a5e7ff2016e714bf107faad2289672e2`. 이는 빌드 기록 매핑이며
현재 기기 바이너리에서 직접 추출한 SHA가 아니다. 해당 Git 소스의 AuthPage 로그인 profile upsert와
onboarding_gate의 profile 존재만으로 완료 판단하는 조건을 직접 대조해 동일 결함을 확인했다.
최신 개선 코드가 설치돼 있었다고 주장하지 않는다. APP67에도 존재하는 결함이 APP75 및 수정 전 브랜치에 이어져 있다.

별도 연결된 iPhone12 Pro Max는1.0.2(75), LS04C QA는76으로 확인했으나 Owner 재현 기기가 아니다.
이 브랜치의 홈6단계·이메일 UX·gate 수정은 APP67 설치본에 포함되지 않는다.
설치/삭제/실행·운영 설정 변경 없이 메타데이터와 기존 Git 소스만 확인했다.

## 원인과 최소 수정

이메일 로그인 성공 → `AuthPage._passwordAuth`의 id-only profile upsert →
`currentProfileProvider`의 계정별 조회 → router의 `onboardingRedirect`.
기존 gate는 profile 행만 있으면 준비 완료로 판단하여 NULL 완료 marker를 무시했다.
APP67·APP75와 수정 전 브랜치 모두 같은 조건이다. Auth 가입/인증 성공이 온보딩 완료를 의미하지 않는다.

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

다음: iPhone17 Pro Max 대상 독립 검수 빌드로 신규 로그인/온보딩/완료/재로그인 확인 →
미완료 재개/계정 전환/Apple·Google 실기기 검수 → 저장 전 임시 draft 보존 범위 해결 → 릴리스 통합.
이번 결과는 코드 결함 수정·격리 회귀 완료이며 실기기 전체 안정화 완료가 아니다.

## Owner 승인 iPhone17 업데이트 설치 — 후속

Owner는 기존 앱 데이터 유지 조건으로 수정 앱 설치·온보딩 검증을 승인했다.
빌드 소스 `1b2a92542b6cb8051dc0a28079e982babdd8e350`, 버전 **1.0.2(77)**.
기존 APP75 공개 클라이언트 설정을 로컬 파일로 재사용했고 OAuth3개/프로젝트 일치 validator PASS.
Flutter release 빌드80초,44.8MB; codesign deep/strict PASS.
동일 team `VUKFS69GB4`, application identifier `VUKFS69GB4.com.legendstudy.app`,
iPhone17 대상 UDID의 provisioning 포함을 확인했다.
App.framework SHA256 `d53f873e2b7110a8b795693c0b72e4601367d608db5ec10d3192afe5bdd0acbf`.

`devicectl device install app`으로 기존67 위에77 업데이트 설치 SUCCESS, launch SUCCESS,
설치 메타데이터1.0.2(77) 재조회 PASS. 삭제/재설치/컨테이너 초기화/로그아웃/계정 reset 없음.
설치·실행 영수증은 ignored `.local/onboarding-device/{install77,launch77}.json`,
빌드 영수증은 `build/ios/device-qa-receipt.json`. 비밀값/개인 기기 식별자는 Git에 기록하지 않는다.
기존 배포 앱 container는 접근 불가여서 업데이트 전 데이터 전체 해시/백업은 취득하지 않았다.
따라서 삭제 없는 업데이트 성공과 앱 내 실제 데이터·세션 보존 확인은 구분한다.

iPhone 미러링은 대상 iPhone17 사용 중으로 연결 시간이 초과됐다. Owner에게 화면 잠금을 요청했다.
온보딩 화면/실제 세션 보존은 NOT TESTED; 잠금 후 연결하여 확인해야 한다. 운영 Auth·DB·SMTP 설정/스토어 변경0.
