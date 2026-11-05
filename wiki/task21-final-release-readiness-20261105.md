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
집중42PASS. 초기 시스템 Flutter3.8은 저장소SDK와 달라 실행불가, 고정 tool/flutterw 3.47.6으로 재실행. 첫 전체검사 도중 수정된 기대문구가 기존 컴파일과 혼재했으므로 최종 전체검사를 다시 실행한다. 동일 소스를 고정한 최종 전체 1,553 PASS / 7 SKIP, analyze No issues found. Android release AAB/APK PASS; iOS 정식 Archive/App Store IPA PASS.

APP58 및63 IPA/AAB/Archive 별도 보존. 신규 버전1.0.2(64): 동일63번호 재사용으로 검수 산출물이 혼동되지 않게 다음번호 선택. 기존release63 플랫폼별 운영설정 그대로 재사용, 새Secret/권한 변경없음. 현재 작업트리 재생성가능 build intermediates만 정리했으며 보존63파일 해시 확인.

운영 PDF 읽기검증18게시글/846PDF/846PENDING. 파일별 권리승인·Edge 개방0. iOS 과거 합성저장 Owner PASS와 최종 기기검수 구분. Android SM-G950N 연결·기존APP58 확인. 등급컷11시험2457행 공개는 이전 실제HTTP 원본대조PASS 유지. GA4최종버전 수신/Android저장/새iOS실기기 및 TASK20연결 최종확인 전 RELEASE_READY=NO.


## 2026-11-06 Android 설치·보존 확인

소스 `b9f6e1a` / 1.0.2(64). 정식 AAB 및 실기기용 arm64 release APK 생성 완료. 기존 APP58 AAB와 업로드 인증서 SHA256 `c00f4260d5b95a084335576c03bf36b8914a2f33cb3da701403e0adbacfb8ef1` 동일.

연결된 Android SM-G950N의 APP58은 Google Play 앱서명 인증서 `4d9694e8525102cf3f65193bbc8c4061212a43b63d2c15061614a976df6371ac` 사용. `adb install -r`은 INSTALL_FAILED_UPDATE_INCOMPATIBLE로 거절되었고 설치 버전은58 그대로 확인했다. 삭제/앱 데이터 초기화/서명 우회 없음. 최종 Android 검수는 Owner의 Play 내부 테스트 배포 후 진행해야 한다. 디버그 수집용 일시 설정은 `.none.`으로 복구했다. DebugView는 당시 디버그 기기0/이벤트 대기였으며 최종 빌드 실수신 PASS가 아니다.

산출물은 비공개 `development/legendstudy-private-backups/task21-release64-20261106/`에 보관한다.
- `legendstudy-1.0.2-64.aab`: SHA256 `638ec0575a5127b621947982db7920a47b63be19089c12e8fbda2a9eff9050bc`
- `legendstudy-1.0.2-64.apk`: SHA256 `214a231e5f4dc245d4be9d2194d17a341c43b39d8912b2e2eef3e52c85a9d2e3`

TASK20 운영 상태를 재확인한 문서는 WEB23a03b0/배포858e369c이며 신규 전체 공개 완료 근거는 없다. 실제 기존 공개시험과 미공개시험을 구분한다. 최종 기기 동작·GA4 수신/Android PDF저장 및 전체 대학별 admission 검증이 완료되기 전 RELEASE_READY=NO 유지.


## iOS 빌드·설치 결과

동일 소스 `b9f6e1a`, 1.0.2(64) 정식 Archive 및 IPA 생성 PASS. IPA 내부 bundle `com.legendstudy.app`, version1.0.2/build64 확인. App Store 프로파일 get-task-allow=false, ProvisionedDevices 없음, Team VUKFS69GB4. Archive 및 IPA 내부 앱 codesign --verify --deep --strict PASS(시스템 신뢰 저장소 접근 가능한 환경에서 검증).

- `legendstudy-1.0.2-64.ipa`: SHA256 `006887f3edc0c474958dc20eee1afe2aacf3d73876ff1744d6f835654d7f4bb6`
- IPA/Runner.xcarchive는 Android와 동일 비공개 백업 디렉터리에 보관.
- iPhone12ProMax 본앱63→64 삭제 없이 설치·실행 PASS. Owner 기능 확인 및 실제 GA4 수신은 별도 대기.
- Android는 Owner가 AAB를 Play 내부 테스트에 직접 업로드하기로 응답. Agent Store 제출0.

빌드 환경 경고: Flutter TTS의 iOS Swift Package Manager 미지원은 현 버전에서 경고이며 빌드 성공. Android CupertinoIcons 폰트 경고도 빌드 성공과 구분하여 기록한다. UI 시각 검수는 별도다.


## APP64 Owner 검수·후속65 (2026-11-06)

Owner는 iPhone 주요 기능 정상 작동을 확인했다. 건국2026수시자연에서 문항2개를 선택하면 전체시험 제한처럼 보이는 안내가 나온다고 추가 보고했다. 경희2026수시자연은 선택 전에도 제한 안내. 실제 공개 Q1과 비공개 문항을 함께 선택한 경우의 제출 차단은 유지하되, 부분 공개 시험에서는 현재 가능한 문항 목록과 문항별 표시를 제공한다. 전체 미공개 시험에는 내부 용어 '운영 공개 범위' 대신 '현재 이 시험·문항은 첨삭을 제공하지 않습니다'를 사용한다. 자료/초안 작성과 실제 첨삭 요청의 차이를 설명하며 서버 공개·원장 변경0. 집중15PASS; 후속65 전체검사/빌드 진행.

GA4는 최초 미수신 화면 이후 지연 반영됐다. 00:32~00:34 KST DebugView에서 APP64 설치 이후 Owner 조작 시각(00:17~00:26)의 screen_view/menu_view/material_open/grade_cutoff_view 및 기존 History/MY 등 메뉴 ID 확인. material_open의 platform=ios, content_item_id=`c3686e6b-eee1-522a-92ee-278c81bf513e`, entry_source=home을 직접 열어 확인했다. 이전 합성 smoke ID와 다르며 앱 Registry ID 전달 경로를 확인했다. 00:31 iPhone SDK 로그에서도 Analytics 시작·collection enabled 확인. 수집 초기화 실패로 확정하거나 코드를 수정하지 않았다.

비공개 스크린샷 `/tmp/task21-ios64-ga4-material.png`, `/tmp/task21-ios64-ga4-menu.png` 보관. 이 증거는 iOS64 실제 수신 PASS이며 Android 수신 및 관리자 운영 집계 화면 PASS를 의미하지 않는다. DebugView의 상단 기기 수0과 실제 수신 이벤트 목록이 함께 보였으므로 상단 숫자만으로 미수신 판정하지 않는다. 이전 초기 미수신 관측은 당시 시점 기록으로 보존한다.

Owner는 Android AAB 준비 후 Play 내부 테스트 직접 업로드 예정. 추가 안내 수정 때문에 최종 후속 버전은1.0.2(65), 64 산출물 유지. 앱 Analytics 수집 코드·SDK설정은64와 동일하다. Android본앱58 삭제0, 새평가/지급/차감/결제/환불0.


## Owner 의도 정정: 부분 공개는 완료 정책이 아님

Owner는 APP65 건국 Q1 단독/다른 문항 동시 선택의 새 안내를 확인한 뒤 “왜 하나만 가능하지? 우리의 의도와 다르잖아”라고 지적했다. **Q1만 제공하는 것을 최종 정책으로 승인한 것이 아니다.** 표시 회귀 PASS는 전체 문항 연결 완료를 뜻하지 않는다. [기존 확대 연결 범위](app58-expanded-production-connection-20261104.md)와 [기존 TASK19 단일 leaf 관측](task19-lab-ux-grade-cutoff-20261105.md)을 구분한다.

TASK20 2026-11-06 조사 스냅샷을 대조했다: 건국2026자연 기존4문항/legacy Math set1, 시험 단위 평가 policy 없음; 경희2026수시자연 기존3문항/Math set0/평가 policy 없음. 공식 자료 참조 및 문항 등록은 존재하지만 패키지 검수·Math 연결이 미완료다. 건국 Q1~Q4 기준이 같은 페이지에 있어 문항별 분리가 필요하다는 TASK20 근거가 있다. 수치·상태는 해당 조사 시점 기준이며 이번 Agent가 운영 DB를 변경하지 않았다.

현재 TASK20 채팅은 숙명 및 한양/중앙/광운 비공개 Registry 복구와 원본 평가자료 분리를 진행 중이다. 등록 승인은 공개/평가 활성화 승인이 아니므로 결과를 혼동하지 않는다. 기존 agent 작업을 덮어쓰거나 이 채팅에서 별도 운영 공개를 실행하지 않는다. 등록된 전체 대상 문항의 연결·검수·정확한 공개 적용이 충족돼야 출시 판정할 수 있다. **APP65는 안내를 보완한 검수 빌드이며 최종 출시 완료 아님. RELEASE_READY=NO.**

## 후속65 산출물

소스234368b, 1.0.2(65). Android AAB 실제 manifest versionCode65/versionName1.0.2, 기존 업로드 인증서 동일. iOS Archive/IPA64 별도 보존 후65 생성·App Store 프로파일/get-task-allow=false·서명검사 PASS, iPhone12ProMax 유지설치/실행 PASS. Owner는 건국 문제1 단독·문제2 동시선택의 새 안내 정상 표시를 확인했다. 경희 새 문구 직접 확인은 응답에 포함되지 않아 미확인으로 남긴다.

- AAB SHA256 `43c3a8e54447167e4830d4c7ce50c8059fabaca92aa8b8e497c8a672cb65909d`
- IPA SHA256 `ee4ee00e3edf7c42a85b8eb22fd1d177198f1538294866f0b47d309260695a71`
- 비공개 백업 `development/legendstudy-private-backups/task21-release65-20261106/`
- 정적분석0/집중15PASS. 디스크 부족으로 중단된 전체검사를 성공으로 계산하지 않고 빌드 완료·공간 정리 후 단독 재실행한다.

Android 합성 PDF TEST는 기존 TASK18 fixture를 재사용하여 별도package `com.legendstudy.app.task18qa`/LS PDF TEST로 생성·서명확인·설치했다. Supabase/Firebase 초기화0, Analytics Noop. tracked Android 프로젝트 수정 없이 로컬 Gradle finalizeDsl/별도 Manifest override만 사용했다. 본앱58은 유지. 실제 저장/파일 열기는 Owner 확인 대기.


## 최종 확인 보충 — 2026-11-06

- APP65 소스234368b: 정적분석0, 집중15PASS, 공간 복구 후 단독 전체 **1,555 PASS / 7 SKIP / 0 FAIL** (`task21-65-full-tests-final.log`). 디스크 부족 중단 두 실행은 검증 수치에서 제외했다.
- Android LS PDF TEST 합성 파일 저장·파일 앱 열기: Owner “합성 PDF 저장·열기 성공” 응답 **PASS**. Android 최종 본앱65/GA4 수신·운영 실제PDF 공개 성공을 뜻하지 않는다. 실패·취소·재시도 Android 실기기 매트릭스는 별도 미확인.
- 운영 DB 재조회(SELECT만): 건국2026자연4문항과 경희2026자연3문항 모두 기존 Registry is_published=false. 건국 기존 ACTIVE Math set `9551ff08-3c17-550d-b745-1ebf20dba1ec` 아래 ACTIVE problem1개/leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3`(leaf_key=q1) 존재, legacy leaf의 essay_question_id는 null이다. 경희 해당시험 Math set0. 따라서 단순 직접FK조인으로 건국Q1이 없다고 단정하면 안 되며 기존 server release binding을 함께 본다. 기존 Q1 연결과 나머지 미연결 구분을 재확인했다.
- 이번 운영 쓰기0, 실제 평가·지급·차감·결제·환불0. TASK20의 별도 승인/실행과 이 채팅의 실행을 혼동하지 않는다.
- 판정 **PARTIAL / RELEASE_READY=NO**: 전체 대상 문항 Package/Math 연결·운영 적용 검증, Android Play 최종본 실기기/GA4, 관리자 운영 집계 확인이 남는다. 문의/History iOS 기존 Owner PASS 및65 부분공개 안내 PASS만 해당 범위에 기록한다.

- 00:57 KST GA4 DebugView에서 APP65 설치 이후 00:47:11~00:47:35 Owner 검수의 university_select/exam_select/question_select 5이벤트 도착도 확인했다. 이는 최종65 전송 경로의 추가 근거다. 메뉴/자료 Registry 상세 증거는64에서 확인한 범위로 별도 보존한다. `/tmp/task21-ios65-ga4-selection.png`. 검수 종료 시 iOS FIRDebugDisabled로 재실행하고 필터 로그 수집을 종료했다.
