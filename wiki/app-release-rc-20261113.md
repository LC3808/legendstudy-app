# APP82 릴리스 후보 통합 — 2026-11-13 목표 / HOLD

## Owner 범위와 실제 작업

2026-11-12 Owner 지시에 따라 [Catalog 단독 main 통합](university-catalog-main-integration-20261112.md)을 중단하고 인증·온보딩·홈·검색을 포함한 APP 전체 RC로 전환했다. 별도 `codex/app-release-rc-20261113`에서 최신 검증 APP 소스에 원격 main을 병합했다. **main 자체 병합/Push, 스토어 제출은 아직 승인되지 않았다.** 운영 DB/RPC/Auth 변경, WEB 배포, 기존 회원 데이터 변경은 금지 상태다.

- 원격 main 기준: `aeb8be2dade4dfd39ea6c98eba2d738a83fb7a85`.
- APP 출발점: `codex/email-auth-stabilization-20261111`의 `1eb8e1ffc7375b3518ad6666a521ccc3f82f0058`.
- RC 통합 커밋/APP82 빌드 소스: `eab45637bec4abea837ed10ec98c609040894f18`.
- 기존 APP/한국항공대 작업 브랜치를 수정하지 않았다. 새 RC의 통합 외 변경은 기존 UI 기대값에 맞춘 테스트 2개 파일 및 검증 Wiki다.
- 최종 보고 SHA와 설치 소스 SHA는 구분한다. 후속 테스트·문서 커밋은 APP82의 제품 소스를 바꾸지 않는다.

## 소스 정합성과 포함 기능

[전체 SHA·ancestry·main 보존 파일 목록](assets/app-release-rc-20261113/source-alignment.json).

|기능/기준|확인한 커밋|RC 포함|
|---|---|---|
|APP75 설치 소스|c9b4830|DONE; iPhone12 Pro Max 빌드75 보존|
|APP78 설치 소스|79f5a12|DONE; 설치 영수증과 Git 대조|
|이메일 인증·재발송60초/중복/오류 안내|c5cd349|DONE|
|신규 회원 onboarding_completed_at 라우팅|ddbbe5a|DONE|
|홈 카드 개인화·계정별 저장/복원|efb6b59 (37eb530/ef228c2 후속 포함)|DONE; 홈 브랜치 이미 ancestry에 포함|
|알림 실패·타임아웃·수동 재시도|4489603|DONE; 작업04 브랜치도 ancestry에 포함|
|N수·기타 학교 생략/inline 실제 지원/MY 공통 폼|8470a15|DONE|
|컴팩트 폼·가로2열/접근성 세로 전환|11e84e9|DONE|
|전체 카피·center·저장 우선·현재 단계skip|275d976|DONE|
|Catalog78 운영 증거/검색·별칭|bffa210 / 6e2f138|DONE; 신규 운영 적용 없음|
|main 자료 수집72시간/관리자 큐/security ignore|aeb8be2 및 선행 main3커밋|DONE; RC로 통합|

중복 cherry-pick을 하지 않았다. 공통 조상 이후 main의 변경25파일 중24파일은 main과 byte-identical이며 `.gitignore`는 양쪽 규칙을 보존한 superset이다. 텍스트 merge conflict0. main의 최신 자료 수집 변경을 APP 소스로 덮어쓰지 않았다.

### APP75 대비

인증 UX, 신규 온보딩 gate/단계복원, 지원 대학 관리, 홈 개인화, 알림 오류 처리, Catalog 검색이 추가/개선됐다. `lib/features/essay`와 `lib/features/study` 제품 소스는 APP75와 동일하다. 기존 수능/모의고사·논술·학습 엔진, Credit, 공개 정책을 바꾸지 않았다.

### APP78 대비

학교 단계 동적 생략, 온보딩 내부 지원 CRUD와 MY 공통 폼, 컴팩트 레이아웃, 제목/설명 가운데 정렬, 현재 단계만 건너뛰기, 지원 폼 열린 동안 다음 차단, Catalog78 대응을 포함한다. 계정별 저장된 단계/입력 복원 계약은 유지한다.

## 자동 검증

SDK Flutter3.47.6 stable, `./tool/flutterw`, lockfile 변경 없음.

|검사|결과|근거/범위|
|---|---|---|
|초기 전체 Flutter 테스트|2552 PASS / 8 SKIP / 5 FAIL|기존 APP 소스에서도 동일5건 재현|
|기존 실패 baseline 재현|DONE|원본1eb8e1f에서 grade_runner_navigation 1건/mobile_ia_render4건 재현|
|기대값 수정 후 집중 회귀|61 PASS|테스트2파일; 제품 변경 없음|
|Flutter Analyze|PASS|최초 및 최종 검사 모두 no issues|
|최종 전체 Flutter 테스트|2557 PASS / 8 SKIP / 0 FAIL|done.success=true; 새 실패0|
|main 자료 동기화 Python 단위 검사|26 PASS|daily_material_sync / material_sync_schedule; 실제 수집 실행 없음|
|운영 공개 Catalog 읽기 + 양쪽 검색 UI|2 PASS|78개 조회/관심·실제 지원 Flutter 검색; 인증·쓰기 없음|
|iOS release 서명 빌드|PASS|1.0.2(82), codesign deep/strict PASS|
|Wiki handoff/diff 검사|PASS|링크·라우팅·12KB restore budget·whitespace|

[최종 검사 영수증·SKIP8 목록](assets/app-release-rc-20261113/validation.json). SKIP은 live opt-in2건, disposable local Auth fixture1건, 기존 운영 결과 fixture5건이 없는 환경 조건이다. SKIP을 PASS로 집계하지 않는다. Catalog live 읽기는 별도 명시 실행2건으로 검증했다.

기존5건 원인: APP75 이후 결과 화면은 앱바 뒤로가기와 하단 홈 탭을 사용하는데 테스트가 제거된 결과 footer를 찾았다. 모의고사는 공식 기출이 기본인데 렌더 테스트4건이 자유 연습 과목 선택을 바로 찾았다. 기존 경로에 맞춰 테스트 진입만 고쳤고 점수·저장·재조회·재제출 금지·작은 화면/확대 assertions를 유지했다. 실패 테스트를 skip하거나 제품을 과거 UI로 되돌리지 않았다.

## 실기기 영수증과 검증

iPhone17 Pro Max 기존 설치에 **삭제 없는 업데이트**로 APP82를 설치하고 CoreDevice metadata에서1.0.2(82)를 확인했다. 빌드 receipt와 `eab4563` 소스를 대조했다. iPhone12 Pro Max는1.0.2(75) 그대로 재확인했다. 앱 삭제·데이터 초기화0.

초기 실행은 기기 잠금으로 거절됐고, Owner 잠금/미러링 연결 후 재실행은 exit0 및 실제 화면으로 확인했다. 설치 성공을 실행 성공으로 대신하지 않았다. APP82는 내부 QA 번호이며 스토어 버전/업로드 승인이나 제출 완료를 의미하지 않는다.

|시나리오|결과|범위|
|---|---|---|
|APP82 설치·실행·빌드 확인|DONE|metadata와 실제 화면 실행|
|신규 이메일 가입·인증·최초 로그인|PARTIAL|Owner가 직접 입력/인증/로그인 후 준비 완료 회신; 에이전트는 첫 온보딩부터 확인. 이메일 발송/전달 로그는 별도 조회하지 않음|
|N수 온보딩/학교 생략/단계표시|DONE|1/6→2/6, 학교 단계 자동 생략|
|이전·다음|DONE|2→1→2, 4→5→4→5|
|현재 단계 건너뛰기|DONE|관심전공4/6→닉네임5/6; 홈으로 이동하지 않음. 돌아가 교육 선택 저장|
|관심 대학 검색·선택|DONE|KNUE 별칭→한국교원대학교→관심 대학 저장|
|실제 지원 대학 검색·저장|DONE|동일 한국교원대 검색,2027/수시/QA 가상 학과·전형/지원 완료 저장|
|저장 누락 방지|DONE|폼 open 시 footer 다음 없음, 저장 버튼 접근, 입력 닫기 경고→계속 입력 시 값 보존|
|온보딩 중 종료·재실행|DONE|앱 전환기 종료/재실행→3/6과 저장 대학 카드 복원|
|온보딩 최종 완료|DONE|닉네임/홈 설정→최종 시작→홈|
|완료 후 재실행|DONE|온보딩 재노출 없이 로그인된 홈|
|MY 데이터 연동|DONE|관심 대학·교육 전공·실제 지원 대학 동일 표시, 관리 목록도 재조회|
|홈 카드 설정/복원|DONE|새 계정 학교 급식 off/논술 LAB on→완료→앱 재실행→편집 화면 동일 상태|
|알림 오류/재시도|DONE|로그인 후 명확한 오류와 수동 retry, 무한 spinner 없음. 기존 Backend 부재 해결을 의미하지 않음|
|학습·모의고사|PARTIAL|타이머/최근7일/공식 기출 연도 선택 화면 로딩; 실제 시험·공부 기록 생성은 하지 않음|
|수능 LAB|PARTIAL|기존 MY 수능 LAB→모의고사 분석 empty→모의고사 이동. 신규 점수 입력 없음|
|논술 LAB|PARTIAL|인증 후 공개 대학/시험 목록, 고려대2026수시 인문 오전→문제1 공식 PDF 표시. 유료 제출·결과 생성은 미실행|
|고1·고2·고3·기타/큰 글자·키보드|PARTIAL|자동 테스트 PASS. 이번 iPhone은 N수 분기만, 외부 키보드 미러링이므로 소프트 키보드 개방 재검증은 NOT TESTED|
|기존 회원 로그인·계정 전환|DONE|Owner 기존 계정 직접 로그인→온보딩 재노출 없이 홈. 기존 프로필/학교/홈/최근 자료 표시, 새 QA 관심·지원 데이터 미노출. 읽기만 수행|
|Apple/Google 로그인|NOT TESTED|이번 실기기 자격 증명별 조합 미실행|
|main 병합 후 회귀|NOT TESTED|main 변경은 Owner 최종 승인 후 수행|

로그인 전 논술 대학 목록의 ‘서비스 상태 확인 필요’는 `publicServiceExamCountsProvider`의 로그인 요구 경로와 일치했다. 로그인 후에는 정상 서비스 목록과 PDF가 표시됐다. APP75와 동일한 기존 동작이며 Provider 호출/유료 첨삭은0이다.

입력은 Owner가 새로 제공한 테스트 계정에만 수행했다. 가상 값 `QA Test Department`, `APP82 QA`, `APP82QA`를 사용했으며 실제 학생의 지원 사실로 검증하지 않는다. 기존 계정의 프로필·지원·홈 설정을 변경하지 않았다. 계정 이메일/토큰은 보고·Git에 기록하지 않는다.

### 검증 화면

개별 확인한 빈 입력 폼과 가상 QA 저장 카드2장만 repository에 보존한다. 계정/설정 화면 원본 캡처는 제외했다.

- [폼 open: 저장 우선/다음 숨김](assets/app-release-rc-20261113/app82-application-form.png)
- [저장 후 카드와 다음 복귀](assets/app-release-rc-20261113/app82-application-saved.png)

## 데이터 보존과 잔여 위험

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의7질문: (1) 발생/기록/정정 시점 계약 유지, (2) 원본/Registry/결과 유지, (3) 기존 history UPDATE·초기화 없음, (4) auth identity·계정 scope 유지, (5) 관심/실제 지원/결과 구분 유지, (6) 기존 권한·수집·retention 범위 유지, (7) 파생 등급/AI 판단을 원본으로 대체하지 않음. 새 storage나 RPC 설계 없음.

- 기존 완료시각 없는 회원 영향은 [인증 라우팅 보고](onboarding-auth-routing-fix-20261111.md)에 남아 있다. 과거 읽기 조사에서 기존 profile46개의 marker가 비어 있었다. 과거 완료 여부는 확정할 수 없으며 이번 RC에서 임의 backfill/강제완료하지 않는다. 이들에 온보딩이 다시 나타날 가능성은 Owner 검토 대상으로 남긴다. 이번 기존 관리자 계정1개가 홈으로 진입한 결과를 이46개 전체의 안전성 근거로 확대하지 않는다.
- 저장된 계정별 단계/Backend 지원 대학은 복원 대상이다. 앱 강제 종료 시 **미저장 폼 전체 복원**은 기존 후속 범위이며 완전 복원을 약속하지 않는다.
- 개인 알림 Backend 미구현 상태에 대한 오류/재시도 UI를 포함한다. 이번 RC가 운영 알림 table/RPC를 신규 제공하는 것은 아니다.
- Catalog78 전체 운영 조회 PASS는 모든 대학의 iPhone 개별 검색이나 논술 LAB 지원 범위 확대를 뜻하지 않는다.
- APP75와 동일한 LAB/study 소스 보존은 실서비스 전체 제출·AI 품질 통과의 대체 증거가 아니다.

## main 통합·릴리스 판단

main과의 소스 통합은 RC에서 끝냈다. 자동 검증과 핵심 신규/기존 회원 실기기 흐름은 통과했다. 소스 기준 main 병합 후보는 준비됐으나, 남은 소셜 로그인/기존 회원 marker 영향과 Owner UX 확인 후 **별도 최종 승인**을 받아 main에 반영한다. 최종 fetch에서 origin/main은 여전히 `aeb8be2`였다. 이후 origin/main이 바뀌면 다시 diff/통합/필요 회귀를 수행한다. 승인 전 main merge/Push0, WEB 배포0, 스토어 제출0. APP 릴리스 HOLD 유지.

## 최종 인계

최종 제품 소스는 설치 APP82의 `eab4563`와 동일하며 후속 변경은 테스트 기대값2파일과 Wiki/검증 영수증뿐이다. 원본 이메일 인증 브랜치도1eb8e1f에서 clean 유지. APP 릴리스 후보 브랜치만 로컬 커밋하고 원격 main/RC Push는 하지 않는다. 기존 관리자 계정의 홈 화면으로 기기를 돌려놓았으며 원본 회원 필드를 수정하지 않았다.
