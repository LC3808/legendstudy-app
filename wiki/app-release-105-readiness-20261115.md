# APP 1.0.5(85) 통합·릴리스 준비 — 2026-11-15

상태: PARTIAL. 코드 검증 완료, 실기기 업데이트/E2E와 개인정보 신고 보완 전 출시 준비 완료로 판정하지 않는다. 스토어 제출·업로드·운영 DB 수정 없음.

## 기준과 통합

App Store Connect 배포 1.0.4 / TestFlight 최신 84, Play Console 프로덕션 1.0.4(84) 전체 출시 및 최신 AAB 84를 브라우저로 확인했다. 후보는 양쪽 1.0.5(85). 기존 작업 브랜치 `codex/operations-commercial-20261113`을 유지한다. 작업 시작 APP HEAD 66c3ba7, main 02996be; WEB HEAD 16be931. 이번 작업에서 main 변경/force push/WEB 재배포 없음.

[지원 삭제·요약 캐시](operations-integrity-20261115.md), [닉네임20](nickname-grapheme-phase3-20261114.md), [행동 분석](app-usage-analytics-implementation-20261115.md)은 이미 포함되어 재개발하지 않았다. 다른 브랜치의 대학 소식 ba2039e/c5ced49 구현은 실제 차이를 검토하여 필요한 파일만 통합했다. [기존 연결 문서](university-news-phase1-connected-20261113.md), [당시 운영 영수증](university-news-production-receipt-20261113.json), [과거 기기 검증](university42-device-verification-20261114.md)은 역사적 근거이며 이번 빌드의 실기기 PASS로 사용하지 않는다.

## 변경과 원인 판정

- LAB 진입 카드, MY LAB 요약, 성장 페이지의 현재 BETA 표시 제거. 베타 종료 공지·과거 내역·가입/구매 이용권 정책·내신/수능 준비 중 유지.
- Catalog 서비스 상태 실패를 HTTP/timeout/network/login 오류 유형별로 안내. 원시 응답/토큰을 UI에 노출하지 않는다. 기존 새로고침 및 재시도, 실제 시험 수, 오류와 서비스 준비 중 구분 유지.
- 운영 public-service-status는 일부 내부 인증 실패도 503으로 반환할 수 있어, 클라이언트 메시지만으로 원인을 확정할 수 없다. 서버 계약은 이번에 변경하지 않았다.
- Owner가 두 기기 모두 App Store 1.0.4(84), 서로 다른 계정이라고 확인했다. 실패 기기에서 다른 계정 로그인 후 정상, 원래 계정 재로그인 후에도 정상이라고 보고했다. 지정 계정의 운영 Auth/allowed 상태를 읽기 전용 확인했으며 지속적인 계정 제한 근거 없음. 최초 HTTP 응답/trace가 없어 **NOT REPRODUCED / 원인 미확정 / 재로그인 복구(Owner 보고)**. 세션 또는 일시 요청 실패 가능성만 있으며 확정 원인이나 이번 수정으로 해결한 장애로 보고하지 않는다. 계정 식별자/이메일은 이 문서에 남기지 않는다.
- 대학 소식 통합 후 계정 전환→숨겨진 홈 복귀 테스트에서 Riverpod pause/resume 의존성 알림이 build 중 root scope를 갱신하는 실제 회귀를 재현했다. mounted news card에서 listenManual로 의존성을 유지하고 dispose 시 자동 종료한다. 타 계정 개인화 분리 테스트 포함 17 PASS. 이 오류는 최초 LAB 실패와 별개다.
- 대학 UUID 42개와 현재 운영 Catalog 응답 일치 테스트 PASS. 실제 지원 우선, 관심 대학 후순위, 중복 제거, 빈 상태/미확정/실패 구분. 기존 앱 내부 전체 대학 소식 페이지→공식 입학처 흐름 재사용. 신규 뉴스 수집 엔진/추측 일정 없음.
- 기존 mobile_ia_test 닉네임 기대값 80을 현재 정책 20으로 수정. 테스트 import를 package 경로로 정리.

## 자동화 검증

최종 `flutter analyze --no-pub`: PASS (No issues found).
최종 `flutter test --no-pub --reporter expanded`: **2,629 PASS / 9 SKIP / 0 FAIL**.
운영 공개 응답을 별도 캡처하여 `catalog_news_live_test.dart` 실행: 1 PASS. 기본 전체 실행의 이 opt-in 테스트는 fixture 미지정으로 SKIP하므로 양쪽 결과를 구분한다. 나머지 기존 환경 의존 skip은 PASS로 환산하지 않는다.

중간 실패: 공통 import 제거로 생긴 컴파일 실패는 복원, nickname80 기대값은 수정, 계정 전환 복귀 회귀는 위 원인으로 해결. 중간 실행 수치는 최종 결과가 아니다. 과거 WEB 11 FAIL/1 ERROR와 이번 Flutter 실패는 별개다.

로컬 상세 로그: `/tmp/app105-final-analyze.log`, `/tmp/app105-final-tests.log`, `/tmp/app105-catalog-live.log`, `/tmp/app105-switch-fixed.log`. 빌드 결과는 아래 영수증에 갱신한다.

## 기능별 출시 체크리스트

자동화 PASS는 widget/unit 계약에 대한 판정이며 물리 기기 E2E를 대신하지 않는다. 아래 기능별 iOS/Android 화면 E2E는 NOT TESTED다. 후속 iPhone12 설치·실행 검증은 별도 기록한다.

| 기능 | 84/이전 상태 | 85 코드·자동화 | 운영 Backend 확인 | 포함 | 최종 |
|---|---|---|---|---|---|
| LAB 대학/시험 수·재시도 | Owner 한 계정 실패 후 복구 | 오류 분류·재시도 테스트 PASS | 공개 Catalog 조회 PASS; 실패 당시 요청 미확인 | 예 | PARTIAL |
| LAB BETA | 스크린샷에 표시 | 3개 진입 표시 제거·테스트 PASS | 베타 종료 정책 변경 없음 | 예 | PASS(코드) |
| 잔액·기존 결과·재첨삭 | 기존 기능 | 전체 회귀 PASS | 실제 계정 잔액/결과 및 차감 E2E NOT TESTED | 기존 | PARTIAL |
| 대학 소식 | 기존 브랜치 구현 미통합 | 지원 우선/중복/빈 상태/계정 분리 PASS | 공개 응답42 UUID PASS | 예 | PARTIAL |
| 지원 수정·삭제·MY 요약 | 기존 수정66ff682 | 기존 파생 요약·전체 회귀 PASS | 실제 사용자 DML 수행 안 함 | 예 | PARTIAL |
| 닉네임20 | 이전 개선 | grapheme/기존 긴 이름 보존 회귀 PASS | 일괄 변경 없음 | 예 | PARTIAL |
| 검색/PDF/저장/최근자료 | 기존 기능 | 전체 회귀 PASS | 실제 단말 다운로드/캐시 NOT TESTED | 기존 | PARTIAL |
| 타이머/D-Day/학교 집계 | 기존 기능 | 전체 회귀 PASS | 실사용 저장/학교 정책 변경 없음 | 기존 | PARTIAL |
| 로그인/세션/계정 전환 | Owner 재로그인 복구 | 계정 전환 홈 복귀 회귀 수정 PASS | 계정 활성 읽기 확인 | 예 | PARTIAL |
| 화면/메뉴/검색/PDF/저장/타이머/LAB 이벤트 | 계측 코드 존재 | 기존 Firebase 호출·실패 격리·릴리스 설정 통합 | 신규 85 이벤트 발생→GA4→관리자 NOT TESTED | 예 | PARTIAL |

## 실기기와 보존

최초 iPhone12 조회에서 별도 QA 앱만 보였던 것은 `devicectl device info apps`의 기본값이 개발 앱만 포함하기 때문이었다. 정식 앱 미설치 근거로 사용할 수 없으며 이전 안내를 정정한다. `--include-all-apps --bundle-id com.legendstudy.app`로 App Store **1.0.4(84)** 설치를 확인했다.

Owner 연결 통보 후 iPhone12 Pro Max(iOS26.6.1)에 동일 bundle/team의 최종 release archive를 `device install app`으로 **삭제 없이 1.0.5(85) 업데이트 성공**, 설치 후 버전85 및 `device process launch` 성공 확인. 기존 별도 QA 앱은 변경하지 않았다. 연결 기기가 포함된 development provisioning 서명으로 설치한 release archive이며, Store Distribution IPA의 실제 설치/다운로드 검증과 구분한다. Store IPA/AAB는 그대로 보존, 업로드0.

Mac iPhone 미러링은 iPhone17을 대상으로 연결 중이어서 iPhone12 화면을 직접 검수하지 못했다. Owner에게 기존 로그인, LAB 시험 수/BETA 제거, MY·저장 자료·학습 기록 유지 확인을 요청했다. 앱 설치 성공을 세션·사용자 기록 보존 PASS로 대체하지 않는다. 최초 LAB 실패 계정의 재로그인 복구는84에 대한 Owner 보고다. Android ADB 기기 없음. iOS 화면 E2E·분석 신규 수신·Android 실기기는 NOT TESTED 유지.

로컬 근거: `/tmp/app105-store-app-before.json`, `/tmp/app105-device-install.json`, `/tmp/app105-device-after.json`, `/tmp/app105-device-launch.json`. 사용자 데이터/로그인 토큰을 추출하거나 기록하지 않았다.

[보존 전략](longitudinal-learning-admissions-data-strategy.md)의 7개 질문 적용: (1) 변경 대상은 UI/read projection 및 기존 계측 경계, (2) 과거 사실 원본 UPDATE 없음, (3) 기존 답안/평가/지원/합격/학습 원본 유지, (4) 데이터 삭제/일괄변환/새 저장구조 없음, (5) 동일 회원 UUID·대학 UUID 계약 유지, (6) 관심/실제 지원/결과 의미 및 기존 RLS·권한 분리 유지, (7) 기존 기록만 표시하고 미수집을0으로 복원하지 않으며 신규 이벤트에 이메일/검색어/답안 원문을 넣지 않음. 운영 DML/원장/결제/평가 엔진 변경0.

## 스토어 개인정보·메타데이터 검토

2026-11-15 양쪽 콘솔을 읽기 전용 확인했다. 새 버전 생성/신고 저장/업로드/제출 없음.

- iOS 공개 신고: 제품 상호 작용은 수집됨, 사용자 비연결, 목적은 **앱 기능만**. 기존 사용자 ID도 앱 기능만. 이번 Firebase 분석 용도와 신고 목적 대조·보완 필요.
- Play 데이터 보안: 앱 상호작용 수집됨/비임시/사용자 선택, 앱 기능·맞춤설정 체크, **애널리틱스 미체크**. 기기 또는 기타 ID는0개 선택. Firebase 설치/앱 인스턴스 식별자 및 실제 선택권과 대조 필요.
- 코드상 ANALYTICS_ENABLED=true일 때 collection을 활성화한다. setUserId 메서드는 있지만 실제 호출부는 발견되지 않았다. 이를 근거로 기기 식별자 미수집이라고 단정하지 않는다. 수집 목적, SDK 식별자, 선택권/필수성, 공유 예외/사용자 연결 여부를 실제 SDK 설정과 맞춘 후 신고를 확정해야 한다. 신고 내용 임의 변경하지 않음.
- iOS 기존 심사 메모는1.0.1 beta 설명을 포함한다. 85에는 베타 종료와 현재 이용권 정책을 분명히 설명하는 아래 초안으로 정리 필요. 기존 리뷰 자격증명은 재기재/공개하지 않는다.

### 업데이트 설명 초안 (양쪽 스토어용, 미게시)

논술 LAB과 나의 학습 정보를 더 편리하게 확인할 수 있도록 개선했습니다.
- 논술 LAB 안내를 정리하고 조회 오류 시 재시도 안내를 개선했습니다.
- 관심 대학과 지원 대학의 논술 일정을 확인할 수 있도록 대학 소식을 연결했습니다.
- 지원 정보를 수정하거나 삭제한 뒤 MY 요약이 갱신되도록 개선했습니다.
- 닉네임 입력 안내와 계정 전환 후 화면 안정성을 개선했습니다.
기존 학습 기록과 저장한 자료는 유지됩니다.

### 심사 메모 추가 초안 (미게시)

Version 1.0.5 updates Essay LAB labels, catalog failure messages, personalized university schedules, and profile/application summaries. The free beta ended on 2026-11-11; historical records and existing signup/purchased credit policies remain unchanged. Existing review credentials and in-app purchase flows are retained. No new external payment method is added. Existing Firebase Analytics records allowlisted app interactions; store privacy declarations must be reconciled before submission.

## 출시 전 남은 검증

1. iPhone12 삭제 없는84→85 업데이트·실행 PASS 이후 학생 핵심 화면/기록 보존 확인 대기; Android 업데이트·E2E는 NOT TESTED.
2. 실제 신규 행동 이벤트→Firebase/GA4 저장→관리자 집계 수신 검증. 과거 데이터 수신을85 검증으로 대체하지 않음.
3. 위 개인정보 신고 차이를 실제 설정과 일치시키고 검토 완료.
4. 최종 IPA/AAB를 Owner가 검수한 후 스토어 업로드/제출 승인. 현재는 **출시 HOLD**.

## 빌드 영수증

양쪽 release build PASS. `build/releases/app105/`에 보존, 스토어 업로드/서버 수락은 NOT TESTED.

- IPA: `legendstudy-1.0.5-85.ipa`, com.legendstudy.app / 1.0.5 /85. Apple Distribution Copacabana Co. (VUKFS69GB4), Store profile / get-task-allow=false / expires2027-10-19, codesign deep/strict PASS.
- AAB: `legendstudy-1.0.5-85.aab`, com.legendstudy.app / 1.0.5 /85, release debuggable=false, AD_ID 없음. jarsigner PASS, 기존84와 업로드 인증서 동일. 64bit ELF12개 LOAD alignment>=16KB PASS. Play 생성 split APK 검증은 NOT TESTED.
- 양쪽 production Supabase 프로젝트 및 기존 OAuth 설정 유지, 플랫폼별 Firebase 공개 설정 병합·ANALYTICS_ENABLED=true 확인. config와 서명 파일은 미추적 로컬에만 유지.
- IPA SHA256: `433936e1c571586c65447947b61ba770257be0d80724588c2f99f0321f726da6`
- AAB SHA256: `3735ab39cce3237b9d9256d1d4edc1eadb22be2318b96b114c483308b70724e0`
- 빌드 경고: flutter_tts SPM 미지원, AGP/Kotlin 향후 지원 종료 예고, Android SDK XML 버전 차이, CupertinoIcons font 참조 경고. 빌드는 성공했으며 도구체인/디자인 변경으로 범위를 확장하지 않았다. 실제 아이콘 포함 시 단말 시각 검수가 필요하다.

Git 인계는 이 문서를 포함하는 커밋으로 식별한다. main 병합 및 실제 출시 승인은 별도다.
