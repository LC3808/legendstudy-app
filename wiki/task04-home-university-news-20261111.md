# 작업04 확장 — 홈 커스터마이징·나의 대학 소식

2026-11-11 · 개발 구현 DONE / 운영 연결 PARTIAL / 실기기 NOT TESTED.
Owner의 같은 날짜 확장 지시를 기존 [작업04 실제 지원](task04-applications-20261111.md)에 추가했다.
APP75 기반 별도 `codex/task04-applications-app75`. 운영 DB/RPC/Auth/WEB/스토어/푸시/결제 변경0.

## 복원·기준·기존 결정 (최종 보고 1–4)

APP75 실제 빌드 소스 `c9b483018bcada179050595cf78c8ca4a3d213ba`, 문서 포함 작업 시작점 `633f982`.
기존 온보딩 `d00ec696`/`74815f64`와 MY `30edf235`는 이미 APP75 조상이라 병합하지 않았다.
이전 `codex/kakao-ios-system-auth` checkout은 수정하지 않았다. 작업04 지원 관리 커밋 `1a07b70`을 유지한다.
APP75의 닉네임/학교 검색 확인·키보드 guard 및 Claude의 카드/타이포/빈 상태/온보딩 팔레트 재사용.
별도 디자인 체계, 기존 파일의 옛 버전 덮어쓰기, 강제 reset/기존 브랜치 병합0.

Wiki 전체 aliases 검색과 [홈 기반 결정](home-personalization-and-events.md),
[Home policy](day-10-b-home-polish.md), [온보딩](personalization-onboarding.md),
[대학 관리](my-college-management-20261026.md), [APP75](task03-result-ux-20261111.md)를 교차 확인했다.
이번 Owner 지시는 이전 역할별 추천 preset/드래그 후순위 설계를 구체화한다:
학년별 기본값 강제 없음, 표시·순서 모두 명시 저장, 대학 소식 기본 OFF, 입시 일정 별도 카드 없음.
기존 실제 D-Day는 dayEventsProvider/DayTargetCard의 여러 일정·대표 일정이며 그대로 재사용한다.
오래된 단일 profiles.target_date 설명을 현재 구현으로 오인하지 않는다.

### 7항 보존 검토

1. 홈 설정은 개인 UI 선택, 지원/결과 사실과 구분. 공지 발생일·게시일·수정일·확인일·수집 created_at 분리.
2. 홈은 immutable revision, 공식 공지는 원본 archive key/SHA256/locator와 revision으로 재현 근거 보존.
3. 설정 저장은 append, 공지 변경·철회도 append. latest projection만 조회하며 원본 UPDATE 금지.
4. 기존 auth.users identity와 FK/cascade 사용. 학년·학교 변경이 카드 선택/지원 주체를 바꾸지 않음.
5. 희망 대학 Interest, 실제 지원 Decision, 결과 Outcome, 학습 Learning을 서로 변환하거나 덮어쓰지 않음.
6. 설정은 본인 RPC만 접근, 공지는 공식 공개 자료만. 신규 analytics/알림/원본 학생 정보 공개0.
   회원 삭제 시 설정 이력도 cascade. 설정 이력 retention·공식 archive 운영 정책은 배포 전 검토.
7. D-Day·정렬·중복 제거는 파생 표시. 점수/합격률/Outcome/대표 D-Day에 저장하지 않음.

## 홈 Registry·기본 보존 (보고 5–6,9–12)

`lib/features/home/customization/home_registry.dart`: card_id/title/description/icon,
display_order_default/default_visible/availability/route/component/data_dependency.
안정 ID/기본순서는 home_configuration.dart의 공통 계약을 사용하며 중복 ID 테스트가 있다.

|순서|ID|기본 표시|재사용|
|---|---|---|---|
|0|dday|ON|기존 DayTargetCard·대표/다중 일정|
|1|study_summary|ON|기존 HomeStudyCard·학습 진입|
|2|school_meals|ON|기존 HomeMealCard·시간/학교 빈 상태|
|3|materials_search|ON|기존 검색창과4개 자료 chip|
|4|recent_documents|ON|최근 본 자료6개/접기|
|5|recent_updates|ON|최근 업데이트·더보기|
|6|school_ranking|OFF|기존 /study/schools|
|7|essay_lab|OFF|기존 LegendStudyLabEntry·/lab/essay|
|8|university_news|OFF|신규 공식 소식 Native 카드|

홈 인사/사용자 이름/알림/홈 편집과 기존 bottom navigation은 고정이다.
자료 찾기는 bottom tab에서도 계속 접근 가능하다. 기존6개 카드 순서/내부 컴포넌트·동작 보존.
수능 자동채점은 기존 자료/학습 경로 보존. `/lab/csat-mock`은 현재 준비 중 화면이므로
신규 활성 수능 카드인 것처럼 만들지 않았다. 내신/오답/구독 등 미래 카드도 이번에 만들지 않았다.
표시 조건은 학년/학교 권한이 아니다. N수도 급식 선택 가능; 학교 없으면 기존 정확한 설정 안내.
설정·계정의 초기 확인 중에는 고정 헤더/편집/정적인 안내만 표시하고 선택형 카드 builder/provider를 실행하지 않는다. 저장된 숨김 값을 읽기 전에 기본 카드 요청이 먼저 나가는 것도 방지한다. 숨긴 카드는 builder/provider를 실행하지 않는다. 진행 중 학습 타이머 서비스는 기존 생명주기 유지.
홈·설정의 두 진입은 동일 HomeEditor. 임시 선택, 드래그, 기본 구성으로 초기화, 저장/취소 제공.
모두 OFF여도 헤더와 '홈에 표시할 카드를 선택해 주세요'/편집 버튼 유지.
unknown ID/숨김 ID 보존, 중복은 안정적인 첫 항목, 동일·누락 order는 저장 순서로 복구.
명시 설정에 없는 신규 카드는 OFF로 추가, 기존 설정 초기화0. 기본 초기화도 unknown ID는 보존.

## 온보딩 (보고 7–8)

기존1상태/2학년·학교/3관심대학/4전공/5닉네임 뒤6홈 선택 추가.
5→6에서 닉네임 validation/save를 수행하며 실패는 입력을 유지한다. 학교/대학 검색 guard는 유지.
6은 아이콘·설명·checkbox, 순서 변경 없음. 기존 기본6개ON/신규OFF.
'이대로 시작하기'는 명시 설정 저장 확인 후 완료 처리. 저장 실패와 완료 실패는 구분하여 재시도,
설정 저장이 확인된 뒤 완료만 실패하면 같은 화면의 재시도에서 설정 재저장0. 재개된 온보딩에서 명시 저장하더라도 기존 서버의 unknown future 카드 ID는 보존한다.
'다음에 할게요'는 설정 INSERT/RPC 없이 기존 best-effort 완료 흐름 사용.
상태·학년 저장 실패와 온보딩 완료 실패를 성공으로 표시하지 않는 기존 정책 보존.
기존 회원을 다시 온보딩으로 보내는 redirect 변경0.
**현재 운영에 신규 RPC가 없어 이대로 시작하기의 서버 저장은 실패할 수 있다.**
입력 보존·재시도/다음에 하기는 제공하지만 운영 연동 완료로 보고하지 않는다.

## 저장 계약·동기화 (보고 11–12,21–22)

운영 information_schema를 SELECT로 확인: 홈 설정/대학 일정 전용 저장소 없음.
profiles의 학년·학교·D-Day·닉네임 필드는 목적이 다르고, Auth metadata로 우회 저장하지 않는다.
SharedPreferences는 기존 의존성 재사용. guest는 `home.v1.guest`에 기기 저장,
로그인 계정은 `home.v1.<owner>` 캐시 + 서버 우선. guest 값을 로그인 계정으로 자동 복사하지 않는다.

- read: 같은 계정 캐시 우선 표시 → 서버 confirmed로 교체. 서버 null=미설정, 저장된 기본 구성=exists true.
- read failure: 서버 조회8초 timeout을 포함하여 기본 홈으로 복귀, 캐시/서버에 기본값 쓰기0, 편집 저장은 확정된 조회 전 제한.
- write: 명시 저장만, revision CAS로 다른 기기의 변경 덮어쓰기 방지. payload 동일 재시도는 멱등 반환.
- 응답 설정이 요청과 일치하는지 확인. 서버 성공 후 캐시 오류는 서버 실패로 오인하지 않음.
- 계정 변경 전후 guard, 이전 owner 결과 표시/새 owner 캐시 저장 금지. auth loading도 기본 구성.
- 프로필 학년/학교 변경은 저장 설정을 수정하지 않는다. 숨김/unknown/card 순서 모두 유지.

후보는 [SQL·격리 검증·원복](../supabase/candidates/task04_home_20261111/README.md).
실제 운영 조회·기기 간 저장/재설치 복원은 **NOT TESTED / 후보 적용 전 불가**.

## 나의 대학 소식·공식 데이터 (보고 13–18)

희망 대학 student_target_universities와 실제 지원 my_applications 기존 API를 재사용.
고3·N수만 실제 지원 관리 CTA 노출. 학년 변경으로 기록을 삭제하거나 대학 소식 카드를 강제로 숨기지 않음.
대학 미등록은 기존 희망 대학/지원 관리 CTA. 대학명/전형/학년도/제목/일정/D-Day/중요 표시,
홈 최대3개, 전체 보기의 주요 일정/대학별 소식·전체/실지원/희망 필터가 같은 feed를 사용한다.
공식 source_url은 외부 링크 공통 컴포넌트, 논술 자료는 실제 자료검색 route로 연결한다.

운영 universities는 id/slug/name/is_active만 제공하고 공식 URL 없음.
content_items는 source_url/published_at/source_updated_at가 있지만 대학·학년도·전형·모집단위
정확한 일정 관계나 verified evidence 계약이 없다. 게시글을 자동 확정 일정으로 전환하지 않는다.
관심 대학에는 정확한 전형명 계약이 없어 **대학 공통 정보만** 사용한다.
입력한 관심 학년도가 없으면 연도별 자료를 임의로 현재 것으로 매칭하지 않고 연도무관 공통 소식만 제공.
실제 지원은 학년도/대학/수시·정시/전형명/필요한 모집단위 정확 일치. 문자열 유사 매칭0.
모집단위별 예외가 있는 공지는 division 단위로 검수해야 하며 '전형 공통'으로 넣지 않는다.

공식 조사: [서울대 입학본부 수시 안내](https://admission.snu.ac.kr/undergraduate/early/guide),
[2027 공식 모집요강](https://admission.snu.ac.kr/webdata/admission/files/2027susi.pdf).
음악대학과 그 외 일반전형의 일정이 달라 전형명만으로 연결하면 오류가 난다.
'18시 이후'는 정확 발표 시각이 아니다. 기존 [조사 기록](task04-applications-20261111.md)에 상세 근거 보존.
현재 변경 공지와 전체 모집단위까지 검수한 운영 데이터는 **0건**. 자동 크롤러/운영 seed 없음.
서울교대 fetch 실패/대학원 페이지 제외도 기존 조사 기록에 남겼다.

후보 공식 계약: verified host allowlist, academic_year/university/scope/round/track/department,
event_type/kind, date 또는 instant, source title/url/archive/SHA256/locator,
published_at/updated_at/verified_at/expires_at, immutable revision/status/created_at.
공식 확인 전 저장소를 채우지 않는다. 앱 테스트의 example.edu/가상 일정은 test/와 격리 SQL에만 존재한다.
최신 revision을 먼저 선택하고 매칭/만료 필터 적용. 동일 series는 중복 제거하되 다른 전형·학과는 별개.
최근7일 내 등록 마감 우선, 나머지 실제 지원의 다가오는 일정, 이후 관심 소식 순서.

### 시간·신선도·오류

Asia/Seoul calendar-day 연산. date-only는 DATE를 유지하고 시간 임의 부여0.
exact는 공식 instant, after는 '이후' 표시. after 종료시각이 없으면 해당 KST날까지 노출하고 다음날은 과거로 분류.
날짜 미확인/오래된 정보는 D-Day 계산하지 않음. past는 홈 제외, 상세에서 '지난 일정'으로 유지.
진행 중 기간은 종료일까지 유효. 원래 대표 D-Day를 수정하지 않는다.

등록 없음/공식 자료 없음/전형 매핑 없음/일정 미확인/네트워크/서버/계약 준비 중/재확인 필요를 구분.
공식 URL이 없는 상태에서는 대학 slug로 입학처 URL을 만들어 내지 않는다.
각 카드 독립 async. 뉴스는 영구 디스크 캐시 없음, 화면에서5분마다 재조회·resume/수동 refresh,
분 단위 표시 재평가. 숨기면 autoDispose되어 타이머/추가 뉴스 요청 종료.
서버 snapshot_at으로 pagination(100개)을 고정해 중간 개정/추가로 인한 누락을 피한다.
expires_at은 운영 검수자가 지정하는 재확인 기한이며 만료 시 현재 확정 정보로 표시하지 않는다.
자동 수집·공지 변경 추적 운영 주기는 배포 전에 확정해야 한다.

## 검증·실기기·잔여 (보고 19–25)

관련 검증 **93항목 PASS**: 홈14/뉴스12/온보딩42/지원11/기존 Auth복귀9/Native render4/실제 탭 계정전환1. 초기 집중91PASS 후 미래 카드·초기 숨김2항목을 추가했고 최종 전체 회귀에서 모두 통과했다.
분리된 PostgreSQL17에서 candidate DDL/owner isolation/CAS/멱등/이력/철회/권한/삭제 cascade PASS.
최종 전체 회귀 **2,505 PASS / 8 SKIP / 5 FAIL**. 대학 소식 선택 상태 계정전환·미래 카드 보존·초기 숨김 요청 방지까지 포함한다.
5FAIL은 APP75 원본633f982에서도 재현된 grade_runner_navigation1/mobile_ia_render4의 오래된 label/key 기대값.
[초기 비교 영수증](task04-applications-20261111.md)에56PASS/동일5FAIL 근거 보존. 기존 학습/채점 기대값을 변경해 green으로 만들지 않았다.
확장1차에서 새로 발견한 Auth 복귀4FAIL은 캐시 초기화와 숨김 Home TickerMode 재개 시 동기 provider invalidation을 수정해 해소했다.
현재 Auth 복귀9/소식 선택 상태 계정전환1 PASS. 캐시 IO 오류는 기본 구성으로 안전하게 처리한다.
`flutter analyze --no-pub`: **No issues found**.
iOS profile/no-codesign **PASS**(55.4MB), Android debug **PASS**. Flutter3.47.6, 기존 APP75 private defines/Android 기존 config 사용.
flutter_tts SPM와 Kotlin2.2.20 미래지원 경고는 기존 의존성의 빌드 경고이며 이번에 패키지를 변경하지 않았다.
360px1x/2x 홈 편집·대학 소식 Native render4 PASS, 실제 PNG 시각 확인. 테스트 가상 자료 화면이며 실기기 증거가 아니다.
최종 로그: `/tmp/task04-verified-suite.log`, `/tmp/task04-verified-analyze.log`,
`/tmp/task04-verified-ios.log`, `/tmp/task04-verified-android.log`, `/tmp/task04-render-final.log`, `/tmp/task04-pg-last.log`.
초기 집중91 검증은 `/tmp/task04-focused-verified.log`, 원본 APP75 비교는 `/tmp/task04-baseline-tests-correct.log`.
Wiki checker/current-status6023bytes/internal links3209개/Task Routing PASS. `git diff --check` PASS.
APP75 대비 Auth·학습·자동채점·논술·PDF·플랫폼 설정·pubspec 관련 소스 diff0 확인.
실기기 iPhone/Android 설치·터치·네트워크 전환·재설치·계정 간 동기화는 **NOT TESTED**.
기존 APP75 설치를 덮어쓰지 않았다.1.0.2+76은 로컬 컴파일 후보 표시이며 다음 릴리스 번호 예약이 아니다.

### Owner 검수와 안전한 통합

1. 이 브랜치와 두 기능 커밋을 리뷰한다. APP75 학습/자동채점/인증의 파일 diff가 없는지 확인한다.
2. 별도 승인된 staging DB에 후보 계약만 적용하고 실제 official 원본/학년도/전형·학과 mapping을 검수한다.
3. 테스트 계정2개로 로그인→온보딩 skip/save→홈 toggle/drag/reset/cancel/allOFF→앱 종료/재실행→다른 기기 복원.
4. 서버 차단 중 조회/저장/온보딩 완료 실패를 구분하고 입력 유지·재시도를 확인한다. logout/계정 전환 정보 누출0 확인.
5. 희망만/지원만/둘 다/대학 없음, 동일대학 다른전형/학과/연도, 변경·철회·만료·KST경계/공식 링크를 검수한다.
6. APP75 학습 타이머·offline 복구·순위·초대·자동채점·결과/성적·PDF·논술·D-Day·급식·검색·로그인을 회귀 검수한다.
7. Owner 실기기 검수 및 별도 운영 승인 뒤 최신 릴리스 브랜치와 다시 비교하여 필요한 커밋만 통합한다.
   이 작업에서 release merge/push/store submit은 하지 않는다. 승인 전 APP75 유지.

후보는 이미 리뷰 가능한 코드/SQL/테스트 상태이므로 운영 적용 승인 요청으로 작업을 중단하지 않았다.
운영 적용·공지 수집/검수·계정 간 실동기화·실기기·최종 릴리스는 의도적으로 미실행한 후속 단계다.


### 변경 파일과 Git 인계

- 실제 지원: `lib/features/applications/` 두 파일, MY profile 진입, `test/application_management_test.dart` (초기1a07b70).
- 홈: `presentation/home_page.dart` 조합, 기존 컴포넌트 `home_components.dart` 이동, `customization/` 모델·서버/캐시·Registry·편집3파일.
- 대학 소식: `university_news/` 계약/조회/정렬/Native 카드·상세2파일.
- 온보딩6단계 및 Settings 공통 진입, application list autoDispose(숨김 후 불필요한 조회 종료).
- 테스트: home_customization/university_news/task04_account_switch/task04_render, onboarding 회귀 갱신 및 memory-cache fixture.
- 후보 SQL: `supabase/candidates/task04_home_20261111/` DDL·검증·원복·README. migrations에는 추가하지 않음.
- Wiki: current-status/log/index/decisions, 기존 home/onboarding/college 문서 backlink, 초기 지원 보고서 범위 정정, 이 문서.

작업04의 전체 커밋은 `git log 633f982..codex/task04-applications-app75`로 확인한다.
후속 코드 SHA는 완료 응답과 Git 기록에 남기며 current-status에 영구 HEAD를 하드코딩하지 않는다.
검수 후에도 최신 릴리스 소스와 재비교가 필요하며 이번 실행은 로컬 commit까지만 수행한다.
