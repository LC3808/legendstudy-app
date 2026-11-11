# 실제 지원 대학 — 따뜻한 카피·컴팩트 Native 폼

2026-11-11 Owner 후속. 기준 `f9413a7`, 독립 `codex/email-auth-stabilization-20261111`.
[기존 inline CRUD·보존 계약](onboarding-inline-applications-20261111.md)을 유지한다.

## 카피

제목: **합격의 순간까지, 함께할게요! 🎓**

설명: **지원 대학을 등록하면 전형 일정을 더 편하게 챙길 수 있어요. 합격 발표도 놓치지 않도록 함께 준비해요.**

Owner 지정 문구를 사용했다. 실시간 합격 조회·자동 알림·발표 push를 구현하거나 현재 제공한다고
안내하지 않는다. 관련 기능이 추가됐다는 주장0. 기존 데이터·일정 제공 범위를 확대하지 않는다.

## 레이아웃

- 검색 아이콘을 입력창 suffix에 통합. tooltip ‘검색’과 키보드 search action이 같은 기존 검색 호출을 사용.
  별도 검색 버튼/중복 섹션 제목 제거. 검색 요청 시 결과 표시, 선택 대학 강조·무결과/실패 안내 유지.
- 지원 학년도/모집 시기는 기본 가로2열. 학년도는1900~2200의 선택 목록으로 변경하되 기존 검증 범위를 그대로 유지.
  기존 학년도 값 포함, 신규 기본값 계산 동일. 모집 시기 기존값·수시·정시 계약 유지.
- 가용 폭280dp 미만 또는16sp 기준 확대20px 초과 시 세로 전환. 긴 글자를 억지로 축소하지 않음.
- 카드 padding14/radius16, 카드 간12, 필드 간12, 라벨 간6, 입력 내부12.
  기본 입력 높이 약44~48이며 접근성 확대 시 유동 높이. 고정 maxHeight로 글자를 자르지 않음.
- 학과/전형/상태를 순서대로 배치하고 중복 상태 카드를 제거. 필수 정책·120자 제한·필드별 오류 유지.
- 저장 카드에서 학과·전형을 한 줄(필요 시 자연 줄바꿈)로 묶고 간격을 줄임. 모든 기존 정보와 수정·삭제 제공.
- 하단 다음/이전/나중에 입력하기 구조 유지. 저장 버튼은 폼 스크롤 안에 있으며 footer와 겹치지 않는다.
  430×932 격리 렌더 기본 크기에서는 폼·저장까지 보임. 실제 safe area/글자 크기에서는 스크롤이 필요할 수 있다.

## 보존·검증

공통 ApplicationEditor를 쓰므로 MY도 동일 컴팩트 폼을 사용한다. Repository/DB/RPC 변경0.
새 저장소/API/필드/자동 지원·결과 추론 없음. 기존7항 데이터 보존 검토 유지:
시점·원본·revision/history·동일 identity·관심/지원/Outcome 구분·권한/retention·raw/derived 의미 모두 변경0.
완료 marker·계정별 진행 단계 저장 코드는 변경하지 않는다. 운영 사용자 데이터 쓰기/삭제0.
저장 중 중복 방지·실패 입력 유지·partial event 재시도·미저장 이탈 확인·복수 등록·수정/삭제·재조회 유지.
프로세스 종료 시 미저장 폼은 기존 정책대로 복원되지 않을 수 있으나 저장된 지원 기록은 기존 Backend에서 조회한다.

집중66 PASS(온보딩·MY·inline CRUD·진행 복원), 렌더/큰 글자·키보드3 PASS, analyze No issues found.
추가 검사는 키보드 검색→대학 선택→2028학년도/정시 선택→저장 payload 확인,
기본2열/200% 세로 전환/키보드300dp 상태에서 실제 스크롤로 저장 접근을 포함한다.
전체 테스트: **2551 PASS / 8 SKIP / 기존5 FAIL**. 이전 APP79와 동일한 D3 runner navigation1, mobile IA mock4 실패이며 새 실패0. 전체 suite가 모두 성공한 것은 아니다.
최종 기기 영수증은 아래 후속 절에 기록한다.

## 화면

아래는 실제 Flutter production 위젯의 **격리 렌더**이며 실기기 캡처가 아니다.
430×932, 기본 text scale, 시스템 한글·이모지 font를 사용했다.
저장 카드는 테스트 fixture이며 운영 회원 정보/운영 저장 성공 근거가 아니다.

- [기본 입력 폼](assets/onboarding-compact-20261111/onboarding-compact-form.png)
- [입력 완료 후 저장 카드](assets/onboarding-compact-20261111/onboarding-compact-saved.png)

## 수정 파일

`application_editor.dart`, `onboarding_applications.dart`, `onboarding_page.dart`;
`application_management_test.dart`, `onboarding_applications_inline_test.dart`, `onboarding_page_test.dart`.
Wiki index/current-status/log/decisions와 본 문서·화면 자료 갱신.
논술/수능 LAB·Backend·Auth·스토어·릴리스 병합 변경0. Owner 실기기 확인 전 **HOLD**.

## APP80 최종 영수증 (2026-11-12 KST)

- DONE: 앱 소스 `11e84e92e8ec56d2d20c5c9e0bd7855e3a50d151`, 버전1.0.2(80), bundle `com.legendstudy.app`. device-qa 서명/identity 검증과 iOS release build PASS(44.8MB).
- Framework SHA256 `2059138b3828f895ba88b1e1d8b0e3e7a349ddf69e9718aaf7f6b93c43bf7b53`.
- DONE: iPhone17 Pro Max APP79→80 삭제 없는 업데이트 설치, devicectl 실제 metadata80 재조회 및 process launch 성공. 기존 앱 데이터 초기화/삭제0. 별도 iPhone12 Pro Max APP75 읽기 재확인·변경0.
- PARTIAL: 설치/실행 성공과 화면 내 실제 동작 검수는 구분한다. 미러링 연결 재시도 결과 ‘iPhone 사용 중, 연결하려면 iPhone을 잠그십시오’로 UI 접근 불가.
- NOT TESTED: APP80 실기기 대학 검색·선택/CRUD/앱 종료 복원/MY 연동/글자 확대/키보드 연속 흐름. Owner 최종 실기기 UX 확인 대기. 저장 상태·계정 데이터는 강제로 변경하지 않았다.
- 격리 회귀: 집중66 PASS, 화면/200%·키보드3 PASS, analyze PASS. 전체2551 PASS/8 SKIP/기존5 FAIL. Wiki handoff 및 diff whitespace 검사 PASS.
- build receipt의 installed:false는 빌드 시점 값이며 이후 install80/launch80 성공 영수증과 설치 metadata로 실제 설치를 확인했다. 로컬 영수증은 `.local/onboarding-device/`, 키/설정 값은 Wiki·Git 미기록.
- 릴리스 **HOLD**. 스토어 제출/릴리스 병합/운영 Backend·Auth·DB·RPC 변경0. 완료된 회원의 온보딩을 강제로 초기화하지 않음. 미저장 입력의 프로세스 종료 복원은 기존 제한 유지.
