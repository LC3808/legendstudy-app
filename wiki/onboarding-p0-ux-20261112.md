# 온보딩 P0 — 가운데 정렬·저장 우선·단계별 건너뛰기

2026-11-12 Owner IMG_9296~9301 실기기 피드백. 기준5e895c3/설치APP80 소스11e84e9.
기존 [컴팩트 폼](onboarding-compact-layout-20261111.md), [inline 지원](onboarding-inline-applications-20261111.md),
[진행 복원](onboarding-auth-routing-fix-20261111.md) 및 [개인화 계약](personalization-onboarding.md)을 계승한다.

## 실기기 증거와 원인

- IMG_9297/9301: 같은 실제 지원 단계의 접힌 화면. IMG_9298: 펼친 폼에서 저장이 뷰포트 아래인데 다음은 고정 노출.
  IMG_9299: 스크롤 후 저장과 다음이 동시에 노출. IMG_9300은 전공, IMG_9296은 관심 대학이다.
  이전 캡처와 중복된 상태를 별도 문제로 중복 계산하지 않았다.
- 코드에 TextAlign.justify나 수동 공백 삽입은 없었으나 제목·설명 정렬과 spacing을 명시하지 않았다.
  실기기 과도한 간격을 단정적인 엔진 원인으로 설명하지 않는다. center/wordSpacing0/letterSpacing0을 명시한다.
- P0: 기존 `_skip()`이 중간 단계에서도 markOnboardingComplete→홈을 실행했다.
  최신 Owner 지시는 이를 **현재 단계만 건너뛰기**로 대체한다. 기존 best-effort 전체 완료 정책은 폐기한다.

## 카피 변경표

강제 개행 없이 자연 줄바꿈. 기본 크기는2줄 이내를 목표로 하되 접근성 확대 시 maxLines/ellipsis로 자르지 않는다.

| 단계 | 이전 제목 | 새 제목 | 새 설명 |
|---|---|---|---|
| 유형 | 지금의 나를 알려주세요 | 지금, 어떤 목표를 향해 달리고 있나요? | 현재 학습 단계를 알려주세요. 나에게 맞는 공부와 입시 준비의 첫걸음이에요. |
| 학교 | 학년과 학교 | 우리 학교에서 시작하는 합격 준비! | 학교와 학년을 등록하고, 같은 학교 친구들과 공부 기록을 쌓아보세요. |
| 관심 대학 | 관심 있는 대학을 선택해 주세요 | 꿈꾸는 대학, 이제 목표로 만들어 볼까요? 🎓 | 마음에 두고 있는 대학을 모아보세요. 나의 목표 대학과 관심 학과를 한곳에서 관리할 수 있어요. |
| 실제 지원 | 합격의 순간까지, 함께할게요! 🎓 | 동일 | 지원 대학과 전형을 한곳에 모아보세요. 지원부터 합격·등록까지, 나의 도전을 차곡차곡 기록해요. |
| 전공 | 어떤 전공에 관심이 있나요? | 어떤 미래를 꿈꾸고 있나요? ✨ | 좋아하는 분야에서 미래의 힌트를 찾아보세요. 관심 전공을 기록하며 나의 진로를 구체화해요. |
| 닉네임 | 어떤 이름으로 불러드릴까요? | 나의 도전에 어울리는 이름은? | 나를 표현하는 닉네임을 정해보세요. 레전드스터디에서 함께할 나만의 이름이에요. |
| 홈 | 나만의 홈 화면 만들기 | 나만의 합격 준비 공간을 완성해요! | 필요한 기능을 골라 나만의 홈을 꾸며보세요. 매일의 공부와 입시 준비가 더 편리해집니다. |

상단·빈 목록의 ‘선택하지 않아도/나중에’ 반복 제거. 관심 대학은 ‘첫 번째 목표 대학을 찾아보세요’, 최대5개/3개 시작 안내.
전공 null 선택 라벨은 ‘진로 탐색 중’. 값/필수 정책은 그대로다. 관심 대학 기반 자동 일정·전공별 추천·실시간 합격 조회/자동 알림은
현재 구현 근거가 없으므로 약속하지 않는다. 학교 공부 기록/기존 MY 관심·지원 관리/홈 카드 선택의 실제 기능만 설명한다.
기기 최초 서비스 소개3슬라이드는 별도 기존 승인 영역이며 이번 계정 온보딩 변경에 포함하지 않는다.

## 동작

- 제목·설명 모두center/spacing0; 입력 라벨left. 26sp 제목·접근성 scaling 유지.
- 지원 입력open→부모 footer 전체 숨김(다음/이전/건너뛰기 없음), 저장만 주요CTA.
  `_move`에도 open 상태 forward 차단. 폼 저장성공→close→카드→다음 복귀. 오류/부분성공은 폼 유지.
  카드padding12/필드gap10/labelgap4, 연도·모집2열/큰 글자 세로. SafeArea 안의 폼 스크롤로 키보드에서도 저장 접근.
- 건너뛰기는 본문 아래28dp 간격의 보조 ‘이 단계 건너뛰기’. footer에는 다음과 이전만.
  키보드와 지원 입력 중에는 보조skip 숨김. 클릭 대상 최소크기·명료한 라벨 유지, 선택 입력을 필수로 바꾸지 않는다.
- skip은 `_move(1, skip:true)`로 한 단계만 진행, 중간marker/홈 이동0. 마지막은 ‘이대로 시작하기’만 완료 기록.
  상태/학년 수정분은 기존 저장 성공 후 이동, 실패 시 해당 단계에 남아 재시도.
  임시 학교/검색어/닉네임은 skip 확인창에서 계속입력 또는 현재단계skip 선택. 기존 저장값 삭제0.
- 미선택 유형도 단계skip 가능하며 이를 새 상태값으로 추정하지 않음. 계정별 stable step 복원은 미선택 유형도 유지.
  N수·기타 학교 자동생략 및 과거학교 코드/소속 보존. 완료된 기존 회원의 라우팅·로그인·Auth 변경0.
- 프로세스 종료 시 저장된 서버값과 계정별 단계 복원, 미저장 임시 폼 완전 복원은 기존 제한.

## 대학 Catalog

[읽기 전수 감사·78개 SQL 후보·원복/승인](../supabase/candidates/university_catalog_20261112/README.md).
운영53행/활성50. 한국교원대0, 교육대10개 모두0. 기존 과학기술5개 활성.
교육청116+공식2개 비교:118 중 기존33/후보78/identity보류7. 국가전체 대학 목록 완전 커버리지는 아직 검증하지 않았다.
기존 비활성2개 실제대학과 합성1개는 유지. 국립부경대는 기존 부경대ID 재사용.

한국교원대 **후보 추가 DONE / 운영 검색 NOT APPLIED**. 기존 Repository 검색어 정규화는 관심·실제 지원 양쪽 재사용.
국립/공백/카이스트·교대·KNUE 별칭 처리, 서버ID/활성필터 유지. Backend/RPC/새 저장소0.
APP LAB42개 매핑·시험·Registry는 변경0. 후보SQL에 새대학 essay_exams 연결0 검사.
운영 적용과 WEB 소비자 검수는 별도 Owner 승인. 승인 전에 검색 UI에 가짜 저장가능 대학을 표시하지 않는다.

## 7항 보존 검토

1. 기존 발생/기록/정정 시각 보존, 완료시각은 최종 완료에서만 기록.
2. 원본 지원/학교/학습/관심 이력 및 기존 Catalog53행 보존.
3. 사용자 명시 저장과 local 단계 projection 구분, 과거 완료/프로필 backfill0.
4. 기존 계정 identity/owner guard와 대학 ID 유지; 캠퍼스/통합 정체성 불확실7건 보류.
5. 관심≠실제 지원≠합격/등록, 카피로 Outcome을 추정하지 않음.
6. 신규 수집·동의·권한·retention·외부 공유·결제 변경0.
7. 화면 진행/카드 표시·검색 별칭은 파생 UI, 원본 사실과 구분.

## 검증 및 화면

집중79 PASS + 검색 transport1 PASS(초기 mock response request 누락 수정 후 통과), 렌더6 PASS, analyze PASS.
375×667/430×932·1x/2x, 전단계 제목 center, 2→이전→1→다음→2 /3→이전→2→다음→3,
지원open 다음없음→검색/입력→저장→카드/다음, partial retry/중복저장, MY CRUD·복원·계정 변경 회귀 포함.
기존 전체skip 기대값 테스트는 최신 단계skip 정책에 맞게 변경했고, 최종 완료실패/입력유지/재시도 검사는 유지했다.
로컬 PostgreSQL 후보78추가/rollback/재적용0/identity충돌거부 PASS. 운영 변경0.

아래는 **실제 Flutter 위젯 격리 렌더**이며 iPhone 캡처/운영 저장 증거가 아니다.

- [지원 기본폼·다음 숨김](assets/onboarding-p0-20261112/onboarding-compact-form.png)
- [작은 화면 저장 접근](assets/onboarding-p0-20261112/onboarding-p0-save-small.png)
- [저장 성공 후 다음 복귀](assets/onboarding-p0-20261112/onboarding-p0-saved-small.png)
- [유형](assets/onboarding-p0-20261112/onboarding-p0-step-1-1.0.png) · [학교](assets/onboarding-p0-20261112/onboarding-p0-step-2-1.0.png) · [관심대학](assets/onboarding-p0-20261112/onboarding-p0-step-3-1.0.png) · [전공](assets/onboarding-p0-20261112/onboarding-p0-step-4-1.0.png) · [닉네임](assets/onboarding-p0-20261112/onboarding-p0-step-5-1.0.png) · [홈](assets/onboarding-p0-20261112/onboarding-p0-step-6-1.0.png)
- [200% 큰글자](assets/onboarding-p0-20261112/onboarding-p0-step-3-2.0.png)

전체 회귀 **2552 PASS / 8 SKIP / 기존5 FAIL** (D3 runner1·mobile IA mock4, 신규실패0). 최종 카피 집중80 PASS 재확인. 앱 소스 SHA·iPhone 설치/실화면은 후속 영수증에 기록한다. Owner UX 확인 전 **HOLD**.

## APP81 실기기 영수증 — 2026-11-12 KST

- DONE: 앱 소스 `275d9761f07e193c7304103b177194d0cd03542b`, 1.0.2(81), `com.legendstudy.app`.
  device-qa identity/codesign PASS, iOS44.8MB release build PASS. Framework SHA256
  `580eddfa338b6b7d52d891a40921c4cd7df6e935349a2fd8ab7dc1067fc5f287`.
- DONE: iPhone17 Pro Max APP80→81 삭제 없는 설치·process launch·실제 metadata81 확인. iPhone12 Pro Max APP75 읽기 확인/변경0.
- DONE: Owner 잠금 후 미러링 연결. 기존 완료 계정은 홈으로 진입하고 MY/실제 지원 목록으로 이동됨.
  공통 MY 등록폼에서 학년도·모집2열과 저장 버튼 전체 노출, 미저장 입력 이탈 확인창/닫기→목록 복귀 확인.
  운영 저장·수정·삭제 호출0. 검수 검색어는 지우고 로컬 초안만 닫음.
- PARTIAL: 미러링 텍스트 주입이 한글 조합 대신 자모로 전달되어 실제 검색·키보드 검수는 완료하지 못함.
  검색 별칭 transport와 입력/키보드 레이아웃은 격리 테스트로 구분한다.
- NOT TESTED: 새 온보딩 전체 제목·현재단계skip·지원 저장 후 다음 복귀의 **실기기** 연속 흐름.
  현재 계정은 이미 완료되었으므로 강제 재온보딩/marker·프로필 초기화를 하지 않았다. 미완료 테스트 계정에서 Owner 최종 UX 검수 필요.
- 실제 기기 캡처: [MY 기본폼](assets/onboarding-p0-20261112/iphone-app81-my-form.png),
  [미저장 이탈 확인](assets/onboarding-p0-20261112/iphone-app81-unsaved-guard.png).
  위 격리 렌더와 구분하며 실제 운영 저장 성공 근거로 사용하지 않는다.
- build receipt의 installed:false는 빌드 시점 값이며 install81/launch81 영수증과 metadata81로 설치를 별도 검증했다.
- Catalog78개 추가 운영 승인 대기. 국내 전체대학 커버리지·보류7 정체성·WEB 소비자 영향은 미완료.
  APP 릴리스 HOLD, 스토어/병합/운영DB·Auth·LAB·Credit 변경0.
