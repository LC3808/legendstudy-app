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

## 최종 검수 후속 / 기존 회원 보호 — 2026-11-11

Owner는 앞서 인증한 신규 이메일 계정으로 검수를 진행하도록 지정했고, 이후
**“온보딩 확인 완료”**라고 회신했다. 따라서 APP77 온보딩 노출은 **Owner PASS / DONE**.
에이전트 미러링은 iPhone 사용 중으로 화면 접근 불가. 실제 완료 버튼·홈 이동·재실행·재로그인·
기존 회원·계정 전환까지 확인했다는 회신은 없어 해당 시나리오를 임의 PASS 처리하지 않는다.
iPhone12의 APP75는 설치/삭제/업데이트하지 않았으며 iPhone17의67만 Owner 승인으로77로 업데이트했다.

### 기존 회원 영향 — DONE(읽기 조사), 과거 완료 여부 PARTIAL

2026-11-11 23:04 KST 운영 SELECT 집계. 직전63은 당시 값이며 이번62와 혼합하지 않는다.

| 가입 cohort(KST) | 계정 | profile 없음 | 완료/skip marker 있음 | profile 있으나 marker 없음 | 그중 학년/학교 있음 | 그중 현재 상태 있음 |
|---|---:|---:|---:|---:|---:|---:|
| 9/27 이전 | 2 | 0 | 2 | 0 | 0 | 0 |
| 9/27~11/8 | 400 | 14 | 340 | 46 | 16 | 15 |
| 11/9 이후 | 151 | 5 | 130 | 16 | 3 | 5 |
| 합계 | 553 | 19 | 472 | 62 | 19 | 20 |

marker 없는62개는 모두 과거 로그인 시각이 있고, 홈 설정 revision은0개다.
기존(11/9 이전) marker 없는46계정과 profile 없는14계정도 로그인 시 온보딩 대상이 될 수 있다.
새 계정만 영향을 받는다고 보고하지 않는다. 학년/학교19개·상태20개는 중복 가능하며 합산하지 않는다.
현재 학교/학년/상태는 MY/WEB에서도 수정 가능하므로 이전 온보딩 완료 증거가 아니다.
9/27 migration은 당시 학년/학교 있는 profile을 backfill했지만 이번에 재실행하지 않았다.
public schema에 analytics/onboarding/profile-history 명칭의 이력 table은 확인되지 않았다.
이는 외부 Analytics까지 이력이 없다는 뜻이 아니며, 과거 완료했으나 marker만 누락된 인원은 **확정 불가**.
기존 계정의 marker/필드/권한 변경0. 완전한 재온보딩 방지 보장은 없으므로 릴리스 위험으로 유지한다.

### 복원 / N수 지원 대학 확인

저장된 입력 재조회·보존은 기존 자동검사 PASS. 진행 단계 `_step`은 메모리이며 재시작 시1로 돌아간다.
진행 단계 복원은 **미구현(PARTIAL)**. 계정별 로컬 step 저장을 추가하면 가능하지만 이번 gate 수정에는
포함되지 않았다. 저장 전 임시 입력 완전 복원은 Owner가 허용한 별도 후속으로 분리한다.

Owner 후속 “N수 지원 대학은 없더라?”: 현재 온보딩 step3는 모든 상태 공통 **관심 대학**,
실제 지원 기록은 고3/N수의 **MY → 실제 지원 대학 관리**다.
[기존 정책](my-college-management-20261026.md), [작업04](task04-applications-20261111.md)와 코드 대조 완료.
온보딩 실제 지원 입력 추가 요청인지, MY 메뉴 누락인지, 관심 대학 단계 누락인지 Owner 확인 대기.
관심 대학을 실제 지원으로 자동 변환하거나 임의의 기존 데이터를 생성하지 않는다.

## N수생 실제 지원 단계 / 단계 복원 — Owner 후속 구현

Owner는 누락 의미를 “온보딩에도 N수생 실제 지원 대학 입력이 필요”로 확정했다.
N수(retaker) 선택 시 관심 대학 다음에 실제 지원 대학 단계를 추가했다. 기존 MY의
ApplicationsEntry → ApplicationsPage → 동일 등록/수정 화면 및 RPC/중복·revision 가드를 재사용한다.
등록 화면으로 이동했다 돌아와 온보딩을 계속한다. ‘나중에 입력하기’는 해당 단계만 넘기며
완료 marker를 쓰지 않는다. 일반6단계 유지, N수7단계. 고3 MY 지원 관리는 기존대로 유지하며
이번 요청에서 고3 온보딩 단계를 추가하지 않았다. 관심 대학 자동 복사/전환 없음.

`onboarding_progress.dart`: 계정별 기기 로컬 단계 ID만 저장. 답변/토큰/완료 상태는 저장하지 않음.
명시적 다음/이전 이동 시 기존 필드 저장 성공 후 단계 저장; 새 페이지/앱에서 복원.
계정 전환·늦은 load 응답은 owner/epoch 가드로 격리. 완료/skip 후 로컬 단계 제거,
서버 완료 marker가 항상 우선. 상태 미설정/잘못된 단계는1부터 시작하며 기존 답변은 삭제하지 않는다.
홈 단계 재개 시 저장된 설정을 읽고, 미편집 상태의 완료는 기존 홈 설정을 보존한다.
저장 전 임시 답변/검색어/학교 임시 선택의 완전 복원은 별도 후속이다.

보존7검토: (1) 기존 지원 발생/정정 시점 계약 유지, (2) 기존 history 원본 보존,
(3) 현재 profile UPDATE/지원 revision 의미 변경0, (4) 같은 auth identity 및 owner guard,
(5) 관심/실제지원/결과 구분 유지, (6) 로컬 단계만 계정별 보관·완료 시 제거, 새 외부 제공0,
(7) 단계는 UI 복원 정보이며 실제 지원/완료/성과 fact로 사용하지 않음. 운영 SQL/RPC/기존 회원 변경0.

변경: onboarding_page.dart, 신규 onboarding_progress.dart, onboarding_page_test.dart,
신규 onboarding_progress_test.dart. 기존 지원 UI/repository 구현 변경0.
집중69 PASS(지원 등록 화면 진입·돌아오기·선택 단계 skip·fresh page 재개·계정 격리 포함).
후속 전 전체 회귀2538 PASS/8 SKIP/기존5 FAIL(D3 runner1, mobile IA4).
후속 코드 전체 회귀·최종 analyze·기기 빌드는 아래 후속 영수증으로 구분한다.

### 완료 상태와 릴리스 판단

- DONE: marker gate 수정, Owner APP77 온보딩 노출 확인, 기존 회원 영향 읽기 조사.
- DONE(격리 검사): 신규 N수 지원 단계/저장된 값 유지/로컬 진행 단계 복원.
- PARTIAL: 과거 온보딩 완료했으나 marker 누락된 기존 회원 여부(현재 필드만으로 확정 불가).
- NOT TESTED: 최종 후속 빌드의 신규 가입→인증→로그인→온보딩 완료→홈→재실행→재로그인
  전체 실기기 연속 시나리오, 기존 회원/Apple/Google/계정전환 실기기 회귀.
- 릴리스 통합 후보는 준비할 수 있으나 **릴리스 승인 HOLD**. 미확인 실기기 항목과
  marker 없는 기존 회원46개의 재노출 위험을 Owner가 검토해야 한다. 전체 suite green으로 보고하지 않는다.

### APP78 최종 영수증

소스 `79f5a12653231462e58e30916ab2b8288d516132`, iOS1.0.2(78), release80초/44.8MB,
codesign deep/strict PASS, 기존 공개 설정/OAuth3개/프로젝트/동일 bundle 보존.
App.framework SHA256 `16866e6d3bd67fc53ed7771d4d4dea6ecff7f345a967738a5d27c369d973d82f`.
iPhone17 기존77 위78 **삭제 없는 업데이트·실행·버전 재조회 PASS**.
iPhone12의 `com.legendstudy.app` **1.0.2(75)** 읽기 재확인 PASS.
영수증 `.local/onboarding-device/install78.json`, `launch78.json`(ignored).
최종 후속 전체 **2540 PASS /8 SKIP /기존5 FAIL**. D3 runner1·mobile IA4로 기존과 동일.
중간 실행의 추가 학교 test 실패1은 완료 회원 fixture에 marker가 없던 것으로 수정,
해당13검사 및 최종 전체 재실행에서 해소했다. production 코드 추가 변경0.
최종 analyze No issues found, Wiki handoff PASS.

APP77 온보딩 노출은 Owner PASS, APP78 신규 N수 단계/프로세스 재시작 후 단계 재개/
완료→홈→재로그인·Apple/Google/기존 회원 실기기 조합은 **NOT TESTED**.
이미 완료한 회원을 새 단계 검수 때문에 재온보딩시키지 않는다. 실제 데이터 등록은 Owner가
지정한 미완료 테스트 계정의 명시적 입력으로 검수해야 하며 임의 초기화/가짜 지원 기록 생성0.
릴리스 통합 **PARTIAL / 승인 HOLD** 유지.
