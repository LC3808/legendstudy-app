# 대학 Catalog main 통합 검토 — BLOCKED (운영 작업은 CLOSED 유지)

2026-11-12 Owner는 Catalog만 분리 가능하면 main 병합·Push를 승인하고, 이메일 인증·온보딩의 미검증 변경은 제외하도록 지시했다. 안전하게 분리할 수 없으면 임의 병합하지 않는 조건이다.

## 확인한 원격 기준

- `git fetch origin main codex/email-auth-stabilization-20261111` 실행 후 원격 main은 `aeb8be2dade4dfd39ea6c98eba2d738a83fb7a85` (자료 수집72시간/관리자 큐 변경).
- 검토 대상 작업 브랜치는 `codex/email-auth-stabilization-20261111`, 완료 SHA `6e2f13856807e0aef7f303346c2c780ecc282f6c`.
- 두 트리의 차이는2161파일이다. 전체 브랜치 merge는 Catalog 밖의 앱·Auth·온보딩·LAB 변경까지 포함하므로 제외했다.
- main에 대학 Catalog 후보/영수증 파일, 검색 정규화 파일, 대학 Repository/모델/개인화 provider/UI가 없다. `275d976` 및 `bffa210`도 main의 조상이 아니다. Catalog 코드/문서가 이미 main에 포함된 상황이 아니다.
- main의 네이티브 앱은 초기 UI shell과 content/personal repositories 구조다. main의 최신 자료 수집·workflow 변경을 삭제하거나 대체하지 않는다.

## 변경 분류

|분류|파일/범위|단독 통합 판정|
|---|---|---|
|Catalog 자료·적용 증거|supabase/candidates/university_catalog_20261112/{audit.csv,candidate.sql,applied.sql}, wiki/assets/university-catalog-{audit,applied}-20261112.json|분리 가능. applied.sql은 실행 영수증이며 자동 migration/재실행 대상 아님|
|Catalog 검색 별칭|lib/features/universities/domain/university_search_query.dart|순수 함수 자체는 분리 가능하지만 main에 호출 Repository/화면이 없음|
|Catalog 호출 연결|university_repository.dart의 import 추가와 query.trim→universitySearchQuery 변경|해당 Repository 파일 자체가 main에 없어2줄만 적용 불가. 전체 파일은 관심 대학 사용자 쓰기 CRUD도 포함|
|검색 회귀 검증|test/university_search_query_test.dart|main에 없는 UniversityRepository/University 모델에 의존|
|실제 양쪽 검색 UI 검증|tool/qa/university_catalog_live_read_test.dart|main에 없는 InterestedUniversitiesField, ApplicationEditor, ApplicationRepository 및 provider에 의존|
|제외할 변경|인증 재발송/라우팅, 온보딩 gate·복원·단계·카피·inline지원폼·UI, 앱 버전/설치/결과 이미지|이번 승인 범위에서 제외|
|공통 Wiki|index/current-status/log/decisions, 온보딩 통합 문서|원문 통째 교체 불가. Catalog 부분만 최신main에 맞게 별도 편집 필요|

`275d976`은 온보딩 UX와 Catalog가 섞인 커밋이므로 통째 cherry-pick하지 않는다. `bffa210`도 운영 증거와 위 UI 테스트·온보딩 문서가 함께 있어 통째 cherry-pick하지 않는다. 필요한 모델/Repository/UI를 연쇄 반입하면 기존 개인화/지원 관리 기능의 별도 통합이 되며 Catalog78개만의 병합을 넘어선다.

## 결론과 대안

**검색 기능을 포함한 Catalog 변경 전체를 지금 main에 안전하게 독립 반영할 수 없어 main 병합·Push를 하지 않았다.** 단순 텍스트 충돌이 아니라 선행 기능 부재다. 호출되지 않는 별칭 함수만 넣거나 SQL/문서만 병합한 뒤 기능 통합 완료로 보고하지 않는다.

1. 최소 범위 대안: Catalog 데이터 목록·운영 영수증·보류7 사유 문서만 main에 반영한다. 앱 검색 코드/테스트는 기존 작업 브랜치에 보존한다. 이는 증거 문서 통합이지 검색 기능 통합은 아니다.
2. 기능 통합 대안: 실제 릴리스용 앱 기준과 main을 먼저 정합화하고, 관심/실제 지원 대학의 검증된 선행 기능을 별도 범위로 승인·검증한 뒤 Catalog 검색2줄/정규화/테스트를 적용한다. 이메일 인증·온보딩 미검증 변경 자동 포함 금지.

이번 조건에 따라 임의로 문서 전용 병합으로 범위를 축소하지 않았다. Owner가 위 대안 중 범위를 결정하면 최신 main 재조회 후 독립 통합 브랜치에서 진행할 수 있다.

## 검사와 제한

- 원격fetch, commit ancestry, 파일 존재/의존 관계, Catalog commit diff 확인 완료.
- Wiki handoff·링크와 diff whitespace 검사 PASS.
- main 통합 코드/회귀 테스트: **NOT TESTED** — 통합 후보를 구현하지 않았으므로 기존 브랜치 PASS를 main 결과로 전용하지 않는다.
- 기존 운영 DB78개 반영/양쪽 검색 검증과 [Catalog CLOSED](university-catalog-closure-20261112.md)는 유지한다. 운영/실기기 증거의 범위는 기존 문서 참조.
- 원격 main 변경0, 추가 운영DB0, WEB·APP 배포0, 스토어 제출0, APP 릴리스 HOLD 유지.
