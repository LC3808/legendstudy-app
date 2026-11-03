# 온보딩 프로필 정합성·학교 검색 V2 — 2026-11-03

상태: 구현·자동 검증 완료 / 운영 미배포. Owner 검수 후 별도 신규 APP 빌드·배포가 필요하다.

## 기준과 범위

- 원격 `codex/beta-store-release-task14`의 `367bfab`에서 현재 작업 폴더에
  `codex/onboarding-school-search-v2` 생성. 기존 릴리스 APP 1.0.1(41),
  버전/서명/OAuth/다른 worktree 보존. 자동 운영 배포·스토어 제출 없음.
- [Claude 진단](onboarding-profile-integrity-20261103.md)은 별도 Claude checkout의
  `d0fab09`에서 원문 보존해 가져왔다. 69/33/19/17은 Claude의 11/3 읽기 전용
  실측이며 이번 작업의 새 DB 실측으로 주장하지 않는다.
- [기존 개인화](personalization-onboarding.md), [학교 계약](day-7-neis.md),
  [프로필 UX](core-app-improvements.md), [관리자](admin-member-directory.md)를 계승.
- 실제 릴리스는 상태 → 학교/학년 → 관심 대학 → 전공의 **4단계**다.
  과거 개인화 문서의 2단계 설명과 구분한다. 대학/전공 저장 경로는 변경하지 않는다.

## 저장 계약

**아래 최초 V2 설명의 건너뛰기 실패 차단과 MY 미설정 제거는 [최종 리뷰 보완](#final-review-fix)의 최신 Owner 정책으로 대체한다.**

상태/학년의 사용자 수정분만 기존 `upsertCurrentProfile`로 단계 이동(이전 포함),
건너뛰기, 최종 완료 **전에 await 저장**한다. 수정하지 않은 값은 요청에서 제외한다.
초기 읽기 값은 초안으로 복원하며 명시적 비재학생 선택은 기존대로 학년을 해제한다.
저장 실패 시 이동/완료 표시를 하지 않고 재시도한다. 이미 성공한 단계는 마지막
단계 실패나 이후 건너뛰기로 유실되지 않는다. 계정 변경 후 이전 비동기 응답은
다음 단계/완료로 진행시키지 않는다.

학교 검색/첫 결과/카드 선택은 UI 임시값이다. `이 학교로 설정하기`를 누른 경우에만
기존 `SchoolSelection.select` → `updateSchoolSelection`을 호출한다. 학교 코드 두 개는
기존 하나의 upsert 요청에서 함께 저장된다. 학교 저장 성공 후 다음 단계로 진행한다.
건너뛰기는 임시 학교를 저장하지 않는다. MY는 기존 최종 저장 경로를 유지하고
새 학교를 확인할 때 상태 미설정 값으로 재학생 상태를 다시 지우지 않도록 한다.
학교와 상태/학년의 전체 묶음은 단일 DB 트랜잭션이 아니며, 부분 성공 뒤 실패하면
화면에 남아 재시도한다. 이미 성공한 값의 자동 롤백/삭제는 없다.

운영 DB/스키마/마이그레이션/Auth/Credit/Ledger/결제는 변경하지 않았다.
기존 누락값 추정·일괄 backfill 없음. 앱을 강제 종료하기 전 **확인/단계 이동하지
않은 UI 초안**은 영구 저장된 값이 아니다.

## 검색 및 화면

- 고등학교 기본. `중앙`은 고등학교, 끝의 `중` 또는 `중학교`만 중학교 의도다.
  `별내고` → `별내고등학교`, `별내중` → `별내중학교`로 기존 NEIS에 전달한다.
  완전한 중학교 이름 역시 해당 규칙으로 인식한다. 별도 학교 DB 없음.
- 결과의 `SCHUL_KND_SC_NM`으로 필터한다. 초등/미상 학교급 제외, 학교명으로
  학교급을 추측하지 않는다. 정확 일치 → 접두 일치 → 포함 일치, 동점은 이름/코드순.
- 흰색/회색 테두리 카드, 선택 시 #FFAC14 테두리·체크와 연한 오렌지 배경.
  결과/선택 카드에는 애니메이션이 없다. 주소·지역은 기본 숨김.
  동명 학교에만 시도/시군구를 표시하고 같은 지역이면 코드로 추가 구분한다.
- 첫 결과 임시 선택, 다른 카드 선택, 모든 입력 변경 시 초기화. 빈 결과/오류 시
  미선택. 늦은 이전 검색 응답은 새로운 입력/선택을 덮어쓰지 않는다.
- 중복 선택 요약/선택 해제 버튼 제거. 학교 설정은 강제하지 않으며 비재학생도
  학교 없이 진행한다. 기존 게스트 학교 선택은 실행 세션에만 유지한다.
- 빈 검색창 placeholder만 3초마다 예시 전환. 터치/입력 즉시 중단,
  Reduce Motion에서는 정지. 검색 네트워크와 독립된 timer는 dispose 때 해제한다.
- 기존 NEIS 프록시 최대100행 제한 유지. `중앙` 실제 응답은100행이므로
  전체 전국 결과를 완전하게 가져왔다는 보장은 없다. 구체적인 이름 검색 권장.

## 관리자 정합성

기존 관리자 코드가 동일 profile의 상태/학년과 NEIS 코드쌍을 사용함을 확인했다.
`AdminSchoolName` 조회 실패는 표시/재조회로만 처리하며 프로필을 쓰거나 지우지 않는다.
별도 `legendstudy-lab` checkout에서 기존 표시/회원 parsing 테스트 **7 PASS**.
해당 checkout 소스는 변경하지 않았다. [기존 운영 자동조회 검증](admin-member-directory.md#automatic-school-name-resolution--2026-11-02)은
과거 증거이며 신규 앱 가입→운영 관리자 E2E를 대신하지 않는다.

## 보존 검토 7문항

1. 새 발생/기록 시점 컬럼 없음. 기존 완료 마커와 저장 계약 재사용.
2. 학습 원본/관심 대학/지원/결과 데이터 변경 없음.
3. 사용자 확정 현재값만 기존 profiles에 저장. 과거 학교 이력 모델은
   [기존 설계](school-history-and-coupon-design-v1.md)대로 미구현이며 이번 범위에서
   신규 스키마나 과거 이력을 발명하지 않는다. 기존 누락값/기록은 임의 수정하지 않는다.
4. 기존 auth.users identity/owner repository 재사용. 새 사용자 ID 없음.
5. 현재 자기보고 프로필은 Learning/Decision/Outcome 원본 사실과 구분.
6. 신규 수집/권한/retention/외부 공유 없음. 학교 API에는 검색어/학교 코드만 전달.
7. 입력된 값과 NEIS 이름을 표시하며 통계/학교 추정/합격 예측을 생성하지 않는다.

## A–R 검증 매트릭스

PASS는 아래 명시된 자동/읽기 검증 범위이며 실기기 운영 E2E와 구분한다.

| 항목 | 결과 | 근거/남은 일 |
|---|---|---|
| A 고등학교 기본 검색 | PASS | 정책 단위 테스트 + 운영 NEIS 별내/별가람/진접 읽기 |
| B 중학교 명시 검색 | PASS | 접미 판별 + 운영 별내중학교/별가람중학교/중앙중학교 읽기 |
| C 초등학교 제외 | PASS | 공식 학교급 필터 단위 테스트 |
| D 관련도 정렬 | PASS | 정확/접두/포함 순서 단위 테스트 |
| E 첫 결과 기본 선택 | PASS | 위젯 테스트, 저장 호출 없음 |
| F 다른 학교 선택 | PASS | 위젯 테스트 |
| G 주소 기본 미표시 | PASS | 위젯 테스트, 동명만 최소 구분 |
| H 중복 선택 정보 제거 | PASS | 온보딩/MY 회귀 테스트 |
| I 선택 해제 제거 | PASS | 기존학교 코드 보존 테스트 |
| J 학교명 애니메이션 | PASS | 3초 전환/터치 중단/Reduce Motion 테스트 |
| K 학교 저장 | PARTIAL | 코드쌍 단일 요청·확인·실패/재시도 자동 PASS, 운영 쓰기 미실행 |
| L 상태/학년 저장 | PARTIAL | 단계·건너뛰기·기존값 보존 자동 PASS, 운영 쓰기 미실행 |
| M 중간 건너뛰기 | PASS | 선택한 학년 보존, 임시학교 미저장, 실패 시 완료 금지 |
| N 앱 재실행 유지 | PARTIAL | repository 복원/초기값 보존 자동 검증, 실기기 재실행 대기 |
| O 관리자 목록 반영 | PARTIAL | 기존 계약/표시7 PASS, 신규 운영 가입자 E2E 대기 |
| P 로그인/가입 회귀 | PARTIAL | 자동 회귀, 실제4종 로그인/가입은 Owner 검수 |
| Q 기존 프로필 수정 | PARTIAL | MY 저장/실패/기존코드 보존 자동 검증, 실계정 검수 대기 |
| R NEIS 오류 | PASS | 오류/재시도/빈 결과/늦은 응답 테스트 |

## 실행 결과 및 변경 파일

- Flutter 3.47.6, `dart analyze lib test`: **PASS**, no issues.
  `flutter analyze` wrapper는 한글 worktree 경로의 LSP JSON 파싱 오류가 있어
  동일 SDK의 `dart analyze lib test`로 전체 분석했다. 소스 오류가 아니다.
- `flutter test --no-pub`: **1328 PASS / 7 기존 SKIP / 0 FAIL**.
- 마지막 계정 전환 후 오류 UI guard 수정 후 해당 온보딩/검색 **23 PASS**.
- `CORE_RENDER=true` 검색 위젯 **5 PASS**, 360×800 PNG 시각 검사 PASS.
- iOS simulator debug/no-codesign 빌드 PASS. 실기기 설치/Store용 서명/Android 빌드 미실행.
- 운영 NEIS 읽기 8검색 성공. 별내3→고1, 별가람3→고1, 진접5→고1,
  별내/별가람 중학교 각1, 중앙중학교29 확인. 학교명 외 회원정보 출력 없음.
- 관리자 기존 테스트7 PASS. 위키 링크/라우팅/12KB 상태 예산 PASS,
  `git diff --check` PASS. 운영 쓰기0, 배포/업로드/원격 push 없음.
- 의존성/플랫폼 설정/기존 profile repository 및 학교 pair payload 불변.
  pubspec의 기존 기본값 `0.1.0+1`도 변경하지 않았다. 기존 배포 APP41의
  릴리스 주입 버전과 이 로컬 simulator 기본 버전은 구분한다.

구현 파일:
`lib/features/onboarding/presentation/onboarding_page.dart`,
`lib/features/profile/presentation/{school_page,grade_page}.dart`,
`lib/features/school/data/neis_school_repository.dart`,
`lib/features/school/domain/school_search_policy.dart`,
`lib/features/school/presentation/school_search_picker.dart`.

테스트 파일:
`test/{onboarding_page,school_search_policy,school_search_picker,day7_school,device_second_corrections,neis_attribution,task14b_profile_navigation,task14c_integrity}_test.dart`.
위키: 본 문서·Claude 진단 원문·current-status·index·log·decisions·personalization-onboarding·day-7-neis·admin-member-directory.

## Owner 검수 방법 및 복구

1. 별도 검수 빌드에서 신규 테스트 계정으로 재학생→학년 선택→다음→건너뛰기.
   MY 및 관리자에서 현재 상태/학년이 유지되는지 확인.
2. 학교 검색 예시와 동명 중앙고를 확인. 기본 체크 후 다른 카드 선택,
   입력 변경/검색0건/네트워크 실패 시 선택 초기화 확인.
3. 학교를 확인하지 않고 건너뛰면 저장되지 않는지, 확인하면 다음 단계 및
   MY/관리자 학교명·학년·현재 상태가 같은지 확인.
4. 저장 시 네트워크 차단→화면 유지→재시도, 앱 종료/재실행 후 복원 확인.
5. 기존 회원 MY 수정, N수생/검정고시 학교 없이 진행, 기존4종 로그인 확인.
6. 작은 화면/큰 글씨/동작 줄이기에서 실제 기기 검수.

신규 APP 바이너리 필요. 1.0.1(41) 버전과 운영 배포는 보존했다. Store용 새 빌드번호/
서명/배포는 Owner 검수 이후 별도 수행한다. 복구는 기존 APP41 유지 또는 이 브랜치
앱 변경만 되돌리면 된다. DB 롤백/과거 누락값 삭제는 필요하지 않다.


## Final review fix

2026-11-03.

Owner가 Claude의 d00ec696 리뷰를 확인한 후 승인한 세 가지 보완이다.
`codex/onboarding-school-search-v2-review-fix`를 d00ec696에서 생성했다.
릴리스 브랜치 통합/운영 배포/APP41 교체는 하지 않는다.

### 최신 계약

- 건너뛰기는 상태·학년 저장 실패와 무관하게 완료 기록을 **별도로 시도**한다.
  완료 기록까지 실패하면 현재 화면/입력값을 유지하며 오류·재시도를 제공한다.
- 완료 기록만 성공하면 “상태·학년은 저장되지 않았어요”를 명확히 안내하고
  **다시 저장 / 저장 없이 계속**을 제공한다. 다시 저장은 기존 입력값을 사용하며,
  반복 실패해도 값을 지우지 않고 재시도할 수 있다. 완료 기록을 반복 호출하지 않는다.
  사용자가 저장 없이 계속을 선택하면 Home으로 이동한다. 이 경우 미저장 초안은
  서버에 없으며, 화면을 나간 뒤 다시 설정하려면 MY에서 입력한다. 새 offline queue나
  자동 background 저장을 추가한 것이 아니다. 정상 skip에는 추가 조작이 없다.
- `설정 완료`와 일반 단계 이동은 기존 저장 성공 조건을 유지한다. 실패하면 재시도하거나
  별도 건너뛰기 경로를 이용할 수 있다. 완료 처리 실패를 성공으로 표시하지 않는다.
- MY에만 **학교 미설정으로 변경** 액션을 복원한다. 취소는 쓰기0,
  확인은 기존 select(null) → 단일 upsert에서 NEIS 코드 두 개 NULL.
  닉네임/현재 상태/학년은 보존한다. 실패는 기존 학교를 유지하고 재시도한다.
  학교명 조회가 실패해도 저장된 profile 코드로 미설정 액션을 제공한다.
  검색 결과의 선택 해제 버튼은 계속 제거 상태다.
- 온보딩·MY 하단 확인 버튼을 **선택한 학교명 + 로 설정하기**로 변경했다.
  첫 결과 자동 선택/다른 카드 선택과 함께 문구가 갱신된다. 확인 전 학교 쓰기0.
  긴 이름/큰 글씨의 줄바꿈을 위해 온보딩 버튼은 고정52 높이 대신 최소52 높이다.
- 고등학교 기본/명시적 중학교/초등학교 제외/주소 기본 숨김/카드/placeholder는 그대로다.

### 보존 검토

기존 [상위 전략](longitudinal-learning-admissions-data-strategy.md)의 7문항 적용:
(1) 현재 자기보고 프로필 정정이며 새 시점 컬럼 없음,
(2) 기존 학습/지원 원본 불변, 과거 학교 복원 가능성을 새로 주장하지 않음,
(3) 명시적 Owner 승인 학교 해제만 기존 current projection에 적용, history 설계는 미구현 유지,
(4) 동일 인증 owner, 계정 변경 후 후속 저장/이동 차단,
(5) Learning/Decision/Outcome 데이터 변경 없음,
(6) 권한/수집/retention/외부 공유 변경 없음,
(7) 추정/파생값을 저장하지 않음. 운영 DB·schema·Auth·Credit·결제 변경0.

### 변경 파일

- 구현: `lib/features/onboarding/presentation/onboarding_page.dart`,
  `lib/features/profile/presentation/school_page.dart`.
- 테스트: `test/onboarding_page_test.dart`, `test/school_review_fix_test.dart`,
  `test/day7_school_test.dart`, `test/device_second_corrections_test.dart`.
- 위키: 본 문서, personalization-onboarding, decisions, current-status, log, index.

### Owner 실기기 검수

1. 상태/학년 저장 실패 상황에서 건너뛰기: 완료 기록 성공 시 미저장 안내 확인.
   다시 저장으로 기존 입력 복구, 또는 저장 없이 계속으로 Home 진입 확인.
2. 완료 기록도 실패하면 Home으로 이동하지 않고 입력값과 오류가 남는지 확인.
   네트워크 복구 후 건너뛰기 재시도. 일반 설정 완료 실패도 허위 성공 없어야 한다.
3. MY 기존 회원: 학교 미설정 → 취소 시 그대로, 확인 시 학교만 미설정.
   현재 상태·학년·닉네임 유지, 실패 시 재시도 확인.
4. 검색 첫 결과/다른 카드 선택 시 하단 학교명과 체크가 일치하는지 확인.
   버튼 확인 후 학교 변경, 앱 재실행 후 유지, 긴 이름/큰 글씨 확인.

실제 운영 쓰기/신규 실계정/실기기 재실행은 미실행이며 Owner 검수 대기다.
신규 Store 빌드·릴리스 통합·배포는 Owner 검수 전 금지. DB migration 불필요.


### 최종 리뷰 검증 결과

- 전체 `flutter test --no-pub`: **1334 PASS / 기존7 SKIP / 0 FAIL**.

- 수정 관련 Flutter 58 PASS: 건너뛰기 partial failure/반복 재시도/완료 실패,
  MY 미설정 확인·취소·실패 재시도, 첫/다른 학교 CTA, fresh provider container 복원.
- `dart analyze lib test`: PASS, no issues. 이전 기록과 동일한 Flutter3.47.6 SDK 사용.
- iOS simulator debug/no-codesign 빌드 PASS. 실기기 설치·서명·스토어/Android 빌드 미실행.
- 위키 라우팅/링크·current-status12KB 예산 PASS, `git diff --check` PASS.
- 학교 pair repository/API/NEIS 검색 정책/플랫폼·의존성·버전 파일 변경 없음.
- 실제 운영 회원 데이터 읽기/쓰기 없이 fake repository 및 기존 transport tests 검증.
  앱 강제종료 후 실계정 복원은 PARTIAL: Owner 검수 항목이다.
