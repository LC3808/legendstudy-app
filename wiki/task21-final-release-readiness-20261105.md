# TASK21 최종 앱 출시 준비

기준 APP63 9fb4ea3 / 통합감사 ba4d89a, [운영 사전검수](app63-prelaunch-readiness-20261105.md)를 계승한다. Owner TASK21은 수정·후속빌드를 승인하고 기존58/63 보존, DB/WEB 별도승인, Store Owner 직접을 지정했다. 현재 브랜치 codex/app-update-final-integration-20261105를 재사용한다.

## 원인·수정
APP63 선택 화면은 service-status 시험집합과 raw math_catalog 최대50행을 조합했고 제출 화면은 시험별 availability를 별도로 조회했다. 조회실패/로딩을 미공개와 혼동하고, 목록 밖의 정식 Math 연결을 놓칠 수 있었다. TASK20 WEB23a03b0의 기존 시험별 availability 및 서버 필터링된 standalone mathQuestions 계약을 재사용한다. 새 서버 API/대학별 예외/권한 확대 없음.

- AVAILABLE/PREPARING/BLOCKED/ERROR 및 로딩을 공통 판정. 잘못된 응답은 오류, 오류에는 재조회 제공.
- ready/questionIds가 확인된 문항만 허용. standalone은 서버 availability.checked와 mathQuestions의 정확한 시험/문항/leaf만 사용. raw catalog로 공개를 추정하지 않음.
- MIXED_QA_PENDING/RELEASE_SCOPE_CHANGED는 standalone으로 우회하지 않음. 기존 대학 Owner hold 유지.
- 선택 안내·제출 직전 상태 공통화, 비공개 요청 비활성 및 답안보존 안내. 자료/PDF·로컬 초안 열람은 유지.
- 시험별 admission의 Math binding도 재사용해 제한된 catalog 첫 페이지 의존 완화. 서버 quote/submit의 권한·원장 계약 유지.
- 베타 인문·사회·상경·자연·수리/실제공개시험 한정, 매일1회·00KST·이월없음·종료2026-11-11 00:00 KST/가입3개 별도. 이전 마지막사용가능분23:59 표기를 정확한 종료시각으로 정정.

## 대학별 범위와 TASK20 의존
TASK20은 별도 채팅/작업트리에서 계속 실행 중. 실제 DB/공개 패키지 변경은 해당 작업의 Owner 승인·운영검증 결과를 기다리며 변경을 덮어쓰지 않는다. 아래는 TASK20 Wiki81f5716/WEB23a03b0의 조사 스냅샷이며 최종 전수 E2E PASS가 아니다.

|대학|기존 근거·필요 확인|판정|
|---|---|---|
|한국항공|공학5/이학5시험, 자연 패키지 미연결|PARTIAL|
|한양|자연2024모의1시험2문항 존재, 패키지 미연결; 인문·상경 운영진입 기존PASS|PARTIAL|
|중앙|자연2024~26모의3시험12문항 존재, 상경과 별도 패키지|PARTIAL|
|숭실|자연5시험20문항, 패키지 미연결|PARTIAL|
|숙명여자|자연/약학4시험12문항, 과거 자료177파일 매핑 후속|PARTIAL|
|성균관|기존 공통 사진·수식·저장 UI, 미공개 패키지 별도|PARTIAL|
|서울여자|자연4시험9문항 패키지 미연결|PARTIAL|
|동국|자연7시험21문항 패키지 미연결|PARTIAL|
|광운|자연2022모의1시험2문항 Catalog 존재, 패키지 없음|PARTIAL|
|경희|자연5시험10문항/의약4시험16문항 및 빈시험, 미공개사유 WEB복구|PARTIAL|
|건국|2026자연Q1만 standalone 공개, 나머지 임의공개 금지|PARTIAL|
|고려|자연5시험20문항 패키지 미연결|PARTIAL|
|서강|자연9시험11문항 패키지 미연결|PARTIAL|
|인하|2027모의3문항 기존 사진/수식·History 진입 확인|PARTIAL|

등록/공개설정/실제 admission/실평가를 분리한다. 기존 TASK20 전체363Registry·202베타시험·72Math leaf를 모두 이용가능하다고 선언하지 않는다. 대규모 자료확장은 TASK20 후속 범위.

## 보존 검토7
기존 원본시각/평가 사실 유지; Registry·질문ID 재사용; DB UPDATE 없음; 사용자/답안 연계 유지; 서비스상태와 평가성적 구분; 서버권한/PII계약 유지; 화면 파생상태를 원장으로 저장하지 않음.

## 검증·빌드 진행
집중42PASS. 초기 시스템 Flutter3.8은 저장소SDK와 달라 실행불가, 고정 tool/flutterw 3.47.6으로 재실행. 첫 전체검사 도중 수정된 기대문구가 기존 컴파일과 혼재했으므로 최종 전체검사를 다시 실행한다. 정적분석/최종전체/빌드 결과는 후속 기록.

APP58 및63 IPA/AAB/Archive 별도 보존. 신규 버전1.0.2(64): 동일63번호 재사용으로 검수 산출물이 혼동되지 않게 다음번호 선택. 기존release63 플랫폼별 운영설정 그대로 재사용, 새Secret/권한 변경없음. 현재 작업트리 재생성가능 build intermediates만 정리했으며 보존63파일 해시 확인.

운영 PDF 읽기검증18게시글/846PDF/846PENDING. 파일별 권리승인·Edge 개방0. iOS 과거 합성저장 Owner PASS와 최종 기기검수 구분. Android SM-G950N 연결·기존APP58 확인. 등급컷11시험2457행 공개는 이전 실제HTTP 원본대조PASS 유지. GA4최종버전 수신/Android저장/새iOS실기기 및 TASK20연결 최종확인 전 RELEASE_READY=NO.
