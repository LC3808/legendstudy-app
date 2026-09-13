# LegendStudy UI/UX v1.1 — 공식 구현 명세

상태: 제품 책임자가 승인한 v1.1 정책. UI 구현 전 필수로 읽는 canonical specification.
출처: 2026-09-13 사용자가 전달한 「Day 5 준비 + UI/UX v1.1 공식 반영」 지시서.
이 문서는 해당 지시서의 확정 정책과 화면 요구사항을 정리한 것이다.
별도의 Claude 원문 파일/픽셀 단위 시안이 제공되었다는 뜻은 아니다.
Claude는 UI/UX 리드, Codex는 구현 담당이다. 미명시 세부 배치는 Day 5 구현
선택이며 새로운 제품 정책으로 간주하지 않는다.

## 1. 정보 구조

하단 탐색은 **홈 | 자료 | 학습 | MY**, 네 개의 독립적인 navigation stack이다.
저장한 자료는 하단 탭이 아니며 MY 하위에서 진입한다.
탭 전환 시 각 stack과 검색/스크롤 상태를 유지한다. 탭 재선택은 루트로 돌아갈 수 있다.
자료 상세는 root navigator로 shell 위에 push하고 뒤로 가면 기존 자료 상태로 복귀한다.

| 화면 | 경로 | 역할 |
| --- | --- | --- |
| 홈 | /home | 오늘의 공부와 자료 진입 |
| 자료 | /materials | 검색과 자료 탐색 |
| 학습 | /study | 공부 타이머와 기록 |
| MY | /my | 계정·개인 자료·설정 |
| 저장한 자료 | /my/saved | MY 하위 개인 자료 |
| 최근 본 자료 | /my/recent | MY 하위 개인 열람 기록 |
| 학교 설정 | /my/school | 비회원도 접근 가능, 저장은 로그인 필요 |
| 자료 상세 | /materials/:slug | shell 위의 native 상세 골격 |

기존 /browse, /saved, /profile은 각각 /materials, /my/saved, /my로 호환 redirect한다.

## 2. 비회원과 로그인 경계

비회원은 자료 검색·상세·PDF 및 자료 열람, 학교 검색/선택 과정 접근,
타이머 임시 실행을 이용할 수 있다. 로그인은 공개 콘텐츠 열람의 조건이 아니다.

로그인 필요: 학교 설정 저장, 학년 설정 저장, bookmark 저장, recent view 저장,
공부 기록 저장, 누적 공부시간, 개인화 알림, 계정 기반 설정.
학교 탐색과 학교 정보의 영구 저장은 별개다. 타이머 실행과 영구 기록 저장도 별개다.
게스트 실행 기록을 영구 저장한 것처럼 표시하지 않는다.

## 3. 계정 정책

Social-login-only: **Kakao / Google / Apple / Naver**.
v1 제외: Facebook, X, email/password signup.
Day 5는 MY의 로그인 / 시작하기 CTA만 제공하고 provider 버튼, login sheet,
OAuth 설정이나 자동 테스트 로그인은 구현하지 않는다.
기존 Auth 테스트 계정 검증 이력은 이메일 회원가입 UX 도입을 뜻하지 않는다.

## 4. 수익화와 광고

무료 앱 + 광고. **₩4,900 1회 결제**, **커피 한 잔 후원**, **광고 영구 제거**.
구독이 아니며 핵심 기능 unlock 상품이 아니다.
**v1 전면 광고(interstitial)는 사용하지 않는다.**
PDF 열람, 타이머 실행, 로그인, 학교 설정, 중요 CTA 사이에는 광고를 넣지 않으며,
광고 노출은 학습 흐름을 방해하지 않도록 최소화한다.
Day 5에는 광고 SDK·IAP·가짜 광고 박스를 추가하지 않는다. 구매 완료/광고 제거
상태를 실제 결제 없이 표시하지 않는다.

## 5. 화면 구성

### 홈

순서: branded header → compact D-Day → 학교/급식 요약 → 검색 진입 → 빠르게 찾기
→ 오늘 공부 요약 → 최근 업데이트 → 최근 본 자료.
D-Day는 실제 수능 날짜를 하드코딩하지 않는다. Day 5는 목표 일정 안내를 사용한다.
학교 미설정: “학교를 설정하면 오늘 급식을 볼 수 있어요.”
최근 업데이트만 실제 ContentRepository state를 사용하며 0행은 정상 empty다.
급식/공부/최근 열람의 placeholder를 실제 사용자 데이터로 위장하지 않는다.

### 자료

search-centric header, 검색 입력, 카테고리 영역, 검색 결과를 제공한다.
Day 5 카테고리 chip은 키워드 검색 진입점이며 실제 taxonomy filter가 아니다.
기존 제목/요약 검색과 explicit public projection을 유지한다.
고급 시험 필터, 대학 metadata, subject taxonomy filter는 후속 범위다.
상세는 제목/요약·loading/empty/error native 골격까지만 제공한다. PDF viewer는 후속 구현.

### 학습

utility header, 오늘 공부시간, 큰 타이머, 공부 시작 CTA, 최근 7일 요약.
Day 5는 idle만 표현한다. 00:00:00은 타이머 대기 표시이며 측정된 공부시간이 아니다.
“오늘 공부 기록이 아직 없어요.” 실제 실행/일시정지와 기록 저장은 구현하지 않는다.
타이머 CTA는 실행 불가 상태를 명확히 표시한다. 실제 타이머 logic은 Day 8 후속 범위다.

### MY

profile/settings header와 Auth 상태에 따른 분기. 비회원은 로그인 / 시작하기 CTA.
메뉴: 학교 설정, 학년 설정, 저장한 자료, 최근 본 자료, 커피 한 잔 후원 / 광고 제거,
앱 정보. 기존 Saved 코드를 재사용한다. Day 5는 학교/개인 자료 저장/후원을 연결하지 않는다.
Auth 상태는 loading/error도 처리하며 토큰이나 사용자 식별자를 화면에 출력하지 않는다.

## 6. 공통 시각 규칙

Primary #FFAC14, Dark #E99500, Soft #FFF3DC, Background #FFFFFF,
Surface Warm #FFFDF9, Text #202124, Secondary #666666, Divider #E5E5E5, Card Border #DCDCDC, Navigation Indicator #FFE3B0.
Orange는 주요 CTA와 선택 상태 등에 제한하고 화면 전체를 채우지 않는다.
각 탭의 역할에 맞는 header를 사용한다. 모든 탭에 동일한 generic AppBar를 강제하지 않는다.
중첩 화면은 명확한 뒤로가기 AppBar를 제공한다.

Day 6 entry tokens: page padding 20, section gap 24, small gap 8, card radius 16,
chip radius 24 logical px. title 24/22, subtitle 17, body 16/14, meta 12.
버튼/탭의 기본 Material semantics와 최소 48px 터치 영역을 유지하고 header semantics,
타이머 설명, 오류/empty 알림을 제공한다. 큰 글자는 줄바꿈/스크롤로 수용한다.

재사용 후보: AppHeader, SectionHeader, SearchEntry, QuickFilterChip, EmptyState,
ErrorState, ContentCard, CompactUtilityCard. 일회성 구성은 화면 내부에 둔다.

## 7. 상태와 단계 경계

실제 데이터 화면은 loading/empty/data/error + retry. 미연결 영역은 제품형 안내를
사용하고 “개발 중” 또는 가짜 데이터·가짜 광고를 표시하지 않는다.
비활성 CTA는 실행이나 저장이 된 것처럼 동작하지 않는다.

v1 전체 목표에는 school setting, NEIS meal, study timer/history, social auth,
광고/후원이 포함된다. 그러나 Day 5는 navigation/UI shell만 구현한다.
**금지:** DB/schema/migration/SQL, school persistence, NEIS/급식 API, 실제 타이머,
study DB, OAuth, AdMob/IAP, notification backend, ingestion/import.
제품 범위와 현재 구현 범위를 혼동하지 않는다.

## 8. 검증 계약

4탭/정확한 라벨, Saved의 MY 이동, nested/deep route 및 뒤로가기, 탭 상태 보존,
Home 실제 provider empty, Materials 검색, Study idle, signedOut MY, header/timer
semantics, 작은 화면/큰 글씨를 검사한다. analyze/test 및 Android/iOS build 필수.
실제 DB empty는 성공이며 schema나 fixture를 변경해서 화면을 채우지 않는다.


## Day 5 브랜드 교정

Home 브랜드는 공식 원본에서 파생한 이미지로만 표시한다. 일반 Material icon과
Text 조합으로 로고를 재현하지 않는다. 원본 3개와 crop 규격은 design-system.md 및
assets/brand/README.md를 따른다. 본문 시스템 폰트와 기존 orange 계열은 유지한다.


## Day 6 진입 — P0 검색과 카드 refinement

Home 검색 진입은 “모의고사, 논술, 학습자료 검색” read-only tappable surface다.
별도 “어떤 자료를 찾고 있나요?” 제목은 제거한다. 기본 높이 56, radius 12,
가로 padding 16이며 큰 글씨에서는 높이가 늘어날 수 있다. /materials로 이동한다.
Materials는 같은 hint의 실제 입력창으로 keyboard submit만 검색하며 자동 검색은 없다.
별도 검색 버튼/label/counter는 제거한다. IME 조합 완료 후 200자 제한을 유지하고
clear는 입력과 submitted query/results를 함께 초기화한다. 탭 상태는 유지한다.
자동 focus는 강제하지 않는다(기존 branch 진입/복귀 focus 동작 유지).
카드는 neutral 타입 badge → 2줄 제목 → 실제 날짜 보조행(있을 때만) → 최대 2줄 요약.
타입은 모의고사/학습자료/논술/입시정보/교육칼럼/기타로 표시한다. 게시일 우선,
없으면 feedUpdatedAt의 업데이트 날짜를 사용한다. 가짜 시험 metadata/bookmark 슬롯은 없다.
카드 padding 14, 간격 10. 별도 “자료 살펴보기” CTA 없이 카드 전체가 상세로 이동한다.


## Day 6 진입 — P1 hierarchy refinement 및 보류 범위

Home 공식 wordmark width 210, 소개 subtitle 제거. SectionHeader 15sp/w700,
padding 위 24/아래 8. 카드·검색 외곽선은 divider와 분리한 cardBorder를 사용한다.
loading spinner는 Center로 감싼다. 하단 탭은 4개 모두 outline/filled icon 쌍,
선택 label w700/기본 w400, indicator #FFE3B0의 Material NavigationBar를 유지한다.

D-Day/Today Study/Recent Views/MY 전체 재설계, 실제 Saved/bookmark UI, 후원 상세
route/IAP, timer/NEIS/OAuth/Ads/ingestion/DB 변경은 보류한다. MY 후원 카드의
prominence를 높이지 않으며 향후 결제 기능 시 ListTile 전환을 검토할 수 있다.
Day 6 exam metadata/resources가 필요하면 database.md와 실제 schema를 먼저
확인하고 별도 변경 필요성을 보고한다. 이번 작업은 UI 진입 기반만 정리한다.
