# APP78 후속 — 온보딩 내부 실제 지원 입력 / Native UI

기준 `c0b79e6`, 독립 `codex/email-auth-stabilization-20261111`.
Owner 첨부 IMG_9292/9293/9294의 외부 MY 이동·라벨 중첩·여백 문제를 근거로 개선했다.
운영 Auth/DB/RPC/기존 회원 데이터/논술·수능 LAB/스토어/릴리스 병합 변경0. APP 릴리스 HOLD.

## 결정과 보존

[기존 실제 지원 계약](task04-applications-20261111.md), [관심/실제 지원 구분](my-college-management-20261026.md),
[완료 marker 및 계정별 단계 복원](onboarding-auth-routing-fix-20261111.md)을 재사용한다.
고1/2/3은 기존 학교·학년 단계 유지. N수/기타는 설명용 빈 학교 단계를 자동 생략한다.
N수는 상태→관심 대학→실제 지원→전공→닉네임→홈의6단계, 기타는 실제 지원 없이5단계,
재학생은 기존6단계다. 사용자 유형을 바꾸면 이전/다음·표시 분모를 실제 순서로 계산한다.
저장된 학교 코드/소속을 삭제하는 호출은 추가하지 않았다. 기존 N수 상태의 grade 처리 계약은 유지한다.
APP78에서 학교 단계 ID2에 멈춘 N수/기타는 재실행 시 관심 대학 ID3으로 정규화한다.
완료한 기존 회원은 다시 온보딩시키지 않는다.

보존7검토: 기존 지원 발생/기록/정정 시각 유지; 원본 이력 보존;
profile projection과 지원 revision 의미 변경0; auth identity/owner guard 유지;
관심(Decision)·실제 지원·Outcome 추정/자동 전환0; 신규 수집·권한·retention·외부 제공0;
UI 진행 단계를 실제 지원/성과 사실로 취급하지 않는다. 삭제는 기존 RPC가 이력도 삭제하므로
UI 확인창에서 명시하며 운영 삭제 검수는 하지 않았다.

## 구현

- `onboarding_page.dart`: 유형별 순서, 과거 단계 복원, inline 패널, 이전/다음 이탈 확인 및
  확인 중 계정 변경 가드. 별도 MY route/탭바 이동 없음.
- `onboarding_applications.dart`: +지원 대학 추가하기 → 펼친 입력 → 저장 → 카드 목록.
  대학/학년도/모집 시기/학과/전형/현재 상태, 여러 내역·수정·삭제 확인 지원.
  저장 후 같은 단계, 나중에 입력하기는 등록0으로 다음 단계. 기존 내역을 지우지 않음.
- `application_editor.dart`: 기존 MY Editor의 저장 로직을 공통 위젯으로 분리.
  흰 카드·미세한 그림자·라운드20, 네이비/브랜드 오렌지·기존 밝은 배경.
  라벨 바깥 상단/간격8, 필드 간24, 글자 수 아래 표시, 검색 결과 같은 카드,
  선택 대학 강조·무결과 안내·필드 인접 validation, 상태 별도 섹션·저장 여백/SafeArea.
  검색/저장 중 중복 요청 차단. 실패 시 입력 유지. 상태 기록 실패 후 지원 id를 재사용하여
  지원 내역을 중복 생성하지 않는 기존 계약 유지. 기존 내역 수정은 명시적 상태 변경 때만
  기존 event API로 append하며, 필드 수정만으로 기본 상태를 쓰지 않는다.
- `applications_page.dart`: MY 기존 목록/이력/상태 정정/삭제를 유지하며 공통 폼 사용.
- `application_repository.dart` 및 SQL/RPC는 변경 없음. 동일 save/event/delete/page 계약 사용.

## 미저장 및 재실행 정책

폼 수정/검색/선택 후 닫기·이전/다음에는 미저장 입력 폐기 확인. 취소하면 입력 유지.
저장 중 이동 차단. 계정 변경 시 이전 계정 폼을 재사용하지 않음.
단계는 기존 기기별·계정별 local ID 복원, 저장된 지원은 기존 repository 재조회로 표시한다.
**프로세스 강제 종료 시 미저장 폼/검색어는 메모리이므로 소실된다.** 기존 허용된 후속 범위이며
새 개인 입력 저장소를 만들지 않았다. 이미 저장된 지원과 이력은 손대지 않는다.

## 검증 구분

격리 fake repository/transport를 사용하며 운영 등록·수정·삭제0.
- 고1/2/3 학교 단계 유지, N수/기타 자동 생략, 과거 ID2 복원→관심 대학,
  이전으로 돌아가 재학생 변경→학교 단계, 학교 쓰기0 검사.
- inline 등록1/복수, 필드 수정, 명시적 상태 event, 삭제 취소/확인,
  저장 후 fresh widget/repository 재조회, 미저장 닫기 취소/폐기 검사.
- 기존 MY 등록/partial event 실패 재시도/중복 idempotency/owner guards 유지 검사.
- 360px/200% text 검사에서 dropdown 가로 overflow를 발견해 isExpanded로 보완.
- 온보딩 진행 표시/키보드 검색/학생 저장/완료/홈 및 계정별 단계 격리 기존 검사 유지.
최종 수치·iPhone 설치 영수증은 후속 절에 기록한다. 실기기 UI 최종 판단은 Owner 확인 대기.

## 변경 화면 — Flutter 격리 렌더

실제 production 컴포넌트·한글 폰트·430×932 viewport의 테스트 렌더다.
실기기 캡처/운영 저장 성공 증거로 보고하지 않는다. 아래 이미지에는 실제 회원 정보가 없다.

- [온보딩 실제 지원 기본](assets/onboarding-inline-20261111/onboarding-inline-empty.png)
- [온보딩 펼친 입력 상단](assets/onboarding-inline-20261111/onboarding-inline-form.png)
- [온보딩 입력/상태/저장 하단](assets/onboarding-inline-20261111/onboarding-inline-fields.png)
- [MY 공통 폼 상단](assets/onboarding-inline-20261111/my-application-form-top.png)
- [MY 공통 폼 하단](assets/onboarding-inline-20261111/my-application-form-bottom.png)

## 남은 사항

Owner 최종 UX 확인, 실제 테스트 계정에서 등록/수정/삭제·재실행 검수는 NOT TESTED.
운영 기존 사용자 데이터로 테스트하지 않는다. 저장 전 임시 입력 강제 종료 복원은 후속.
기존 full suite 실패5(D3 runner1/mobile IA4)는 별도 작업이며 이번 UI 변경으로 고치지 않는다.
LAB 독립 작업과 공유하는 Wiki status/index/log/decisions는 향후 항목 단위 통합이 필요하다.
릴리스 병합/스토어 제출은 하지 않으며 HOLD 유지.

## 최종 검사 / APP79

- 집중 **62 PASS**, 명시적 상태 event 추가검사3 PASS, 실제 Flutter 렌더3 PASS.
- 최종 전체 **2548 PASS /8 SKIP /기존5 FAIL**(D3 runner1/mobile IA4).
  중간 실행에서 발견된 200% dropdown overflow2건은 수정 후 전체 재실행에서 해소.
- `flutter analyze --no-pub`: No issues found. Wiki handoff PASS.
- 검수 빌드 **1.0.2(79)**, 소스 `8470a15c509eea1fbf387f701c735baa428e30bc`,
  release87초/44.8MB, 기존 공개 config/OAuth3개/동일 bundle·서명 검증 PASS.
- App.framework SHA256 `60ed8a7aad4753b6500a54fa8bfcc9e33a020eac7cc55900e982a9f52d38bf6b`.
- iPhone17에 APP78 위79 삭제 없는 업데이트 설치 SUCCESS. 영수증은
  ignored `.local/onboarding-device/install79.json`; 앱 데이터 초기화/로그아웃/계정 강제 변경0.
- 실기기 실제 신규/기존 계정 CRUD·강제 종료·로그인 E2E는 **NOT TESTED / Owner 최종 확인 대기**.
  fake transport와 Flutter 렌더를 운영 데이터 검수 PASS로 바꾸지 않는다.

설치 후 실제 메타데이터: iPhone17 **1.0.2(79)**, iPhone12 **1.0.2(75)** 재확인.
명령 실행은 기기 Locked로 실패했고, 미러링 재연결도 ‘iPhone 사용 중’으로 종료됐다.
따라서 **설치 DONE / 에이전트 실기기 화면·CRUD 검증 NOT TESTED**로 구분한다.
Owner는 기기에서 앱을 직접 열어 최종 UX를 확인한다. 앱79의 삭제 없는 업데이트 외
기존 계정·profile·지원 기록·학교 소속에 대한 에이전트 쓰기0.
