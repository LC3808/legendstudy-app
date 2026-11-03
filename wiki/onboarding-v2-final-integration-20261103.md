# 온보딩 V2 최종 통합 준비·MY 정보 보완 — 2026-11-03

## 상태와 기준

**IMPLEMENTED / TESTED(자동 검사) / OWNER_REVIEW_REQUIRED / RELEASE_READY 아님.**
별도 `codex/onboarding-v2-profile-completion`에서 작업. 최초 `d00ec696`, 최종 리뷰
`74815f64`를 계승한다. [V2 저장·검색 계약](onboarding-school-search-v2-20261103.md#final-review-fix),
[원인 진단](onboarding-profile-integrity-20261103.md), [개인화](personalization-onboarding.md),
[기존 MY](core-app-improvements.md), [관리자](admin-member-directory.md),
[Analytics](analytics-v1-implementation-20261030.md)의 후속이다.
이 문서는 로컬 구현 검증이며 운영 반영/실기기 합격의 증거가 아니다.

## 1–5. 구현·입력·검색·저장·기존 회원 보완

1. V2 두 커밋을 그대로 포함하는 후속 브랜치에 MY 안내만 추가했다. 릴리스 통합은 하지 않았다.
2. 실제 4단계(상태 → 학교/학년 → 관심 대학 → 희망 전공)를 유지한다. 재학생 학년 선택,
   비재학생 학교 없이 진행, 대학 0개/전공 미정 허용. 대학/전공은 기존 공용 편집기와 저장 경로를 사용한다.
   신규 계정 가입 자체와 실제 대학/전공 서버 저장 E2E는 Owner 검수 대상이다.
3. 고등학교 기본·접미 학교급 명시 중학교·초등 제외·관련도 정렬·주소 숨김·카드·placeholder 유지.
   첫 결과/다른 결과는 임시 선택, 오렌지 테두리/배경/체크, 학교명 확인 CTA를 유지한다.
   검색 화면 중복 선택 정보/해제 버튼 없음. 확인 전 DB 저장 없음.
4. 조기 저장, dirty 값만 쓰기, 계정/세대 가드, 코드쌍 동시 저장/NULL을 변경하지 않았다.
   skip은 optional 값 실패와 완료 marker 쓰기를 분리한다. marker 실패는 완료로 표시하지 않는다.
   marker 성공·값 실패는 재시도/저장 없이 계속을 제공한다. 후자는 실패값이 저장됐다는 뜻이 아니다.
   확인하지 않은 UI 초안은 앱 종료 후 복원 대상이 아니다. 저장된 값의 fresh provider 복원은 자동 테스트한다.
5. MY에 선택형 안내 카드를 추가했다. 상태 NULL이면 먼저 상태 안내. 재학생은 학교쌍/학년 중
   누락 항목만 안내. retaker/other는 학교 권유 없음. 완성하면 provider 갱신으로 숨긴다.
   로그인 없음/읽기 중/읽기 실패/다른 계정 데이터에는 누락 안내를 표시하지 않는다.
   학교명 조회 결과가 아니라 저장 코드쌍으로 판단하므로 NEIS 장애를 미설정으로 오인하지 않는다.
   `정보 설정하기`는 기존 `/my/school` 편집기로 이동한다. 자동 쓰기·팝업·강제 재온보딩 없음.
   기존 설정값을 편집기에 유지하고 사용자가 수정한다. MY 기존 카드 여백을 그대로 준수한다.

### 데이터 보존 검토 7항목

[상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md)에 따라:
1. 새 수집 항목 없음; 현재 profiles projection 읽기만 추가.
2. 과거 snapshot/event/시점 의미 변경 없음.
3. 상태 NULL을 학생/기타로 추정하지 않음.
4. 학교쌍·학년·대학·전공 기존 저장 계약 유지; 안내 노출은 UPDATE하지 않음.
5. 계정 일치/비동기 읽기 가드 적용; 타 계정 정보 안내 금지.
6. Learning/Decision/Outcome/추천·입시 성과 데이터와 연결/수정 없음.
7. 새 권한·보존기간·외부 제공·B2B 수집 없음; 기존 회원 보완은 본인 명시적 편집.

## 6. 관리자 정합성

기존 LAB의 회원 parsing과 `AdminSchoolName` 테스트 2파일 **7 PASS**.
상태·학년·학교 코드쌍 계약은 동일하며 조회 오류는 재시도 표시만 하고 코드를 지우지 않는다.
LAB 소스 수정/배포 없음. 이번 앱으로 신규 가입/수정 → 운영 관리자 반영은 실계정 미검증이다.
기존 운영 학교명 검수는 [11/2 기록](admin-member-directory.md#automatic-school-name-resolution--2026-11-02)과 구분한다.

## 7. 측정 현황 (읽기 전용)

2026-11-03 **14:21:25 KST**, LegendStudy 프로젝트 `stlhijzpjfgwwdgunlsd`에서 SELECT만 실행.
분모는 auth.users의 deleted_at NULL·비익명 계정, profiles를 LEFT JOIN. 테스트 계정이 포함될 수 있으며
실제 학생 수/활성 사용자 수가 아니다. 개인정보/개별 식별자 결과는 취득하지 않았다.

| 지표 | 관측값 | 해석 |
| --- | --- | --- |
| 계정 / profile 행 | 100 / 98 | profile 없는 2개 포함 |
| 11/3 KST 00시 이후 생성 | 29 | auth 생성 시각 기준, 가입 시도 이벤트 아님 |
| onboarding_completed_at 있음 | 88/100 = 88% | skip·과거 backfill 포함 현재 기록률; 전환율 아님 |
| 현재 상태 있음 / 없음 | 79/100 = 79% / 21 | 없는 profile 포함 |
| 재학생 학년 있음 | 40/43 = 93.02% | 현재 재학생 기준 |
| 재학생 학교쌍 있음 | 18/43 = 41.86% | 미설정 25 |
| 한쪽만 있는 학교쌍 | 0 | 전체 계정 기준 |
| 기존 회원 보완율 | 산출 불가 | 이전 누락 cohort/항목 변경 이력 부족 |

과거 69/33/19/17은 당시 관측으로 보존한다. 이번 수치로 과거 개선 효과를 주장하지 않는다.
기존 `sign_up`는 이메일 가입 요청 전 started 이벤트라 실제 신규 계정 수로 세면 안 된다.
`onboarding_complete`는 marker 성공 후 발생하므로 모든 정보 입력 완료와 다르다.
기존 Analytics 계약을 그대로 유지했고 새 이벤트/분석 시스템을 추가하지 않았다.
GA/Firebase 실제 수신은 미검증([연결 상태](admin-integrated-analytics-task10.md)).
향후 보완율이 필요하면 기존 집계의 시점별 분모/누락 cohort 정의를 먼저 승인해야 한다.

## 8–9. 실기기 검수 준비 및 A–O 시나리오

현재 연결 가능한 iPhone 12 Pro Max를 확인했으나 **설치/실행하지 않았다**.
Android adb 연결 기기는 없었다. APP 1.0.1(41), 수리 검수 앱 `com.legendstudy.app.task16f` 모두 보존.
unsigned iOS profile 산출물은 바로 설치할 수 없다. 승인된 서명/TestFlight 또는 별도 허용된 검수
배포 경로와 APP41을 유지할 예비 기기를 확보한 뒤 설치한다. bundle/OAuth/서명 설정을 임의 변경하지 않는다.
Android debug APK 역시 예비 기기에서 검수한다. 기존 설치와 서명이 다르면 삭제하지 말고 검수 기기를 분리한다.

| 시나리오 | 이번 근거 | Owner 실제 계정/기기 검수 |
| --- | --- | --- |
| A 신규 재학생 가입 | 기존 auth 회귀 자동 검사 | 이메일 신규 가입, 소셜 신규 유저 흐름 |
| B 상태·학년 | onboarding/profile 자동 검사 | 각각 입력 후 MY와 관리자 확인 |
| C–D 고등/중학교 | query/filter/picker 자동 검사 | 별내고/별내중, 주소 없음·검색 순서 확인 |
| E 확인 후 저장 | 임시 선택 무쓰기·확인 지연/실패 검사 | 첫 결과→다른 결과→학교명 CTA 확인 |
| F 중간 skip | dirty 저장·기존값 보존 검사 | 상태/학년 단계마다 건너뛰기 |
| G 오류 후 재시도 | draft 실패 반복 재시도·marker 실패 검사 | 네트워크 차단/복구; 입력 유지·허위 성공 없음 |
| H 저장 없이 계속 | 별도 marker 성공 후 선택 검사 | optional 저장만 실패하도록 제어한 테스트 환경 필요 |
| I 재실행 유지 | fresh provider/repository 재조회 검사 | 저장 성공 후 강제 종료/실행·로그아웃/로그인 |
| J 기존 MY 보완 | 상태 우선·누락별 안내·완료 숨김 검사 | 기존 NULL 회원에서 편집 후 카드 숨김 |
| K–L 변경/미설정 | 실패 재시도·확인/취소·코드쌍 NULL 검사 | 변경→재실행, 미설정 취소/확정 후 관리자 확인 |
| M 관리자 | LAB 7 테스트 | 신규/기존 계정의 동일 상태·학년·학교명/코드 확인 |
| N 소셜 로그인 | 기존 auth 자동 검사 | Apple/Google/Kakao, APP41 합격을 새 빌드 합격으로 대체 금지 |
| O 인문논술·자료 | 전체 Flutter 회귀 검사 | 검색/자료 열기/기존 논술 내역 읽기; 유료 평가 자동 실행 없음 |

G/H는 비행기 모드만으로 optional 실패와 marker 성공을 분리할 수 없으므로 제어된 네트워크 환경이나
테스트 계정의 승인된 검수 환경을 사용한다. 운영 데이터 수정/오류 주입을 여기서 실행하지 않았다.

## 10. 검증

- Flutter 전체: **1,344 PASS / 7 SKIP**, `./tool/flutterw test --no-pub`.
- `flutter analyze --no-pub`는 LSP 초기 JSON 메시지의 `FormatException: Unterminated string`으로 종료255. 동일 Flutter 3.47.6 SDK의 `dart analyze lib test` 대체 실행은 **No issues found**. 코드 진단 실패와 분석기 실행 오류를 구분한다.
- MY 렌더 추가 실행 5 PASS; 360px·문자 200% 이미지 확인. 새 안내는 화면 아래로 스크롤 가능.
- 안내 카드 신규 10개: 상태/재학생 누락 조합/비재학생/guest·오류·다른 계정/자동 숨김/접근성 크기.
- 최초 전체 실행의 MY 카드 여백 8건 실패를 기존 horizontal16/vertical8 규칙에 맞춰 수정했다.
- LAB 2파일 7 PASS. `python3 tool/check_wiki_handoff.py` PASS (current-status 11,781 bytes), `git diff --check` PASS.

## 11–13. 변경 파일·SHA·Push

- `lib/features/profile/presentation/profile_completion_card.dart`: 선택형 안내.
- `lib/features/profile/presentation/profile_page.dart`: 기존 MY 위치에 삽입.
- `test/profile_completion_card_test.dart`: 조건·이동·숨김·큰 글씨 검증.
- Wiki: 본 문서, index/current-status/decisions/log 및 기존 V2 보고서 후속 링크.
- 기준 `74815f64f4fd17c632e4775747f8ae73c9cf2bd7`, 최종 SHA는 완료 응답과 Git 로그 참조.
- **원격 push 없음.** 릴리스 checkout/브랜치 통합/Store 제출/배포 없음.

## 14–15. 빌드 후보·충돌·출시 차단 요소

기존 APP는 **1.0.1(41)**. 다음 후보 **1.0.2(42)**를 로컬 QA build override로만 지정했다.
Store의 최신 번호 조회/예약 전이므로 최종 확정 번호가 아니다. pubspec/서명/config 파일은 변경하지 않았다.
기존 QA config에 대한 iOS/Android `tool/store-release --check`는 PRODUCTION_CONFIG_PASS였으나
이 산출물은 Store 최종 제출본이 아니다(직접 Flutter QA 빌드, 배포 wrapper의 추가 플래그/서명 별도).

- iOS: **PASS**, `build/ios/iphoneos/Runner.app` (51.4MB), profile/no-codesign/no-pub. 최종 Info.plist 1.0.2/42 확인. 설치 가능한 서명본 아님.
- Android: **BLOCKED**, debug/no-pub 빌드와 재시도 모두 PDFium native asset 다운로드에서 `release-assets.githubusercontent.com` connection reset. APK 생성되지 않음. 네트워크 복구 후 동일 명령 재실행 필요; 의존성/앱 코드는 우회 변경하지 않았다.
- AGP/Kotlin 버전과 flutter_tts Swift Package Manager 경고는 기존 환경 후속 과제다.

수리·상경 작업 브랜치 `codex/math-scaffolding-mobile-task16f`의 `097397b4`를 로컬 clone에서
읽기 전용 fetch하여 `git merge-tree --write-tree --name-only`로 점검했다. 실제 merge 없음.
온보딩/MY 파일 충돌은 없으나 **14파일 충돌**:
`app_config.dart`, `answer_image_crop.dart`, `evaluation_report_view.dart`, `shared_history_page.dart`,
`source_catalog_page.dart`, `pubspec.yaml`, `answer_image_crop_test.dart`, `math_gateway_test.dart`,
`source_catalog_widget_test.dart`, Wiki `current-status/decisions/essay-beta-credit-design-20261027/index/log`.
수리 TASK16K 자체도 운영 HOLD이므로 함께 통합하지 않는다. 전체 릴리스 충돌 해소와 각 작업 승인 필요.

출시 차단: Owner A–O 실계정/실기기 검수, iOS 서명/검수 배포, Android 실제 설치,
Android 의존성 다운로드/빌드 복구, Store 번호 중복 확인, 분석 실제 수신 검증, 별도 릴리스 통합 검토/승인. 운영 DB/Auth/Credit/Ledger/결제 변경 없음.

### 재현 명령과 로그

Flutter SDK는 `./tool/flutterw` 사용. QA 설정은 기존 승인된 외부
`config/observation-v1-qa.local.json` 경로를 `--dart-define-from-file`로 전달한다. 비밀값은 문서/커밋에 포함하지 않는다.

```sh
./tool/flutterw test --no-pub
./tool/flutterw analyze --no-pub
./tool/flutterw build ios --profile --no-codesign --no-pub --build-name=1.0.2 --build-number=42 --dart-define-from-file=<existing-QA-config>
./tool/flutterw build apk --debug --no-pub --build-name=1.0.2 --build-number=42 --dart-define-from-file=<existing-QA-config>
python3 tool/check_wiki_handoff.py
```

로컬 로그: `/tmp/legendstudy-completion-full-final.log`,
`/tmp/legendstudy-completion-analyze-final.log`, `/tmp/legendstudy-completion-ios-final.log`,
`/tmp/legendstudy-completion-android-retry.log`, `/tmp/legendstudy-completion-admin.log`.
