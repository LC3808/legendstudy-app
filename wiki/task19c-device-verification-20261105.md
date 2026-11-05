# TASK19-C — TEST 빌드·실기기 검증

기준: 2026-11-05, Owner TEST BUILD / DEVICE VERIFICATION 승인. [TASK19 표시 정정](task19-owner-ui-followup-20261105.md) 및 [기존 A/B](task19-lab-ux-grade-cutoff-20261105.md)를 재사용한다. **진행 중 / 전체 PARTIAL**.

## 빌드와 보존
- APP 소스 `9138593`, 브랜치 `codex/app-review-candidate-b-20261103`. 제품 코드 수정 없음.
- 별도 iOS **LS Math TEST 1.0.1(60)**, `com.legendstudy.app.task16f`. 기존 TEST56 xcconfig/entitlements/팀 서명 재사용, Xcode Release build 성공·codesign deep/strict PASS. iPhone **12 Pro Max / iOS26.6.1**에 설치·실행 PASS. 설치 목록에서 본앱 `com.legendstudy.app` 및 별도 PDF TEST 보존 확인.
- 별도 Android **LS TASK19 TEST 1.0.1(60)** APK, `com.legendstudy.app.task19test`. 동일 HEAD 임시 소스 사본에 TEST 패키지/이름만 override, 기존 Release signing 재사용. 빌드·apksigner v2·versionCode60 PASS. 연결 Android 기기 없음: 설치/OS/실기기 모두 NOT_VERIFIED.
- 정식 앱 ID/프로젝트/버전 파일과 APP58 산출물 변경0. Store 업로드·제출0, 운영 DB 쓰기0, Provider 호출0.
- 산출물·로그·원본 실기기 캡처: `/Users/woojinchang/development/legendstudy-private-backups/task19c-20261105/test60/`. Android APK SHA256 `bd6940285715b59ccf086d2d562d23e4dae6206af23e2fb699be6a795765c5fe`. iOS App.framework SHA256 `235dd341580af12cd37bd915084024b790376bdfc56fc26859dfba04b68f4a38`.

## TEST 데이터 실제 적용

사전 조회에서 격리 `kpqbedylxlyntrrfybpn`에는 등급컷 테이블/RPC가 없고 exams/exam_subjects도 0행이었다. 기존 운영 공개 데이터의 대상 11시험만 allowlist 조회하여 같은 ID의 TEST 검수 fixture로 연결했다. source_posts11/content_items11/exams11/exam_subjects268/참조 subjects21, 기존 공개 PDF 각 시험1건(총11건). 원문 내부 메타데이터·개인정보는 복사하지 않았다. 삽입만 수행하고 기존 Registry 행은 덮어쓰지 않았다.

[후보 migration 및 seed/publish 절차](../supabase/candidates/task19_grade_cutoff/README.md)를 TEST에 적용했다. 첫 2회는 자동 생성 열 content_type/sort_date 때문에 트랜잭션 실패·롤백. 정보 스키마에서 전체 generated 열을 확인해 입력을 제외한 뒤 성공했다. 공개값은 후보 데이터 그대로이며 운영 검수 상태 변경은 없다.

- **PASS actual anonymous HTTP**: 앱과 동일 TEST 공개 키로 11시험 목록과 RPC 2,457행 조회. 원점수/범위/표준점수/출처/과목·선택과목·등급을 기존 전사본과 대조.
- 시험별: 2024/25/26 각6·9·수능, 2027년6월은 각각216행; 2027년9월297행. 총11시험2,457행.
- RLS true, anon SELECT true / INSERT false, authenticated UPDATE false.
- 기존 credit_accounts/credit_grants/credit_transactions/feedback_submissions/profiles 5테이블 count·hash 전후 동일. 기존 학생 평가/원장/History를 변경하는 SQL 없음.
- 추정 원점수 미확인 `—` 유지. 표준점수로 임의 환산0. 학습 채점용 grade_cutoff_versions 미변경.
- 운영 데이터 전체행 export는 자동 승인 검토가 거절했고 실행되지 않았다. 공개 대상·필드 allowlist로 축소한 읽기만 실행했다.

## 보존 검토 7항
1. 공개 자료 날짜·학년도·원래ID를 보존하고 TEST 적용 시점은 별도 기록한다.
2. 원본 후보 JSON·출처와 실제 조회 결과를 보존해 재현한다.
3. 기존 행 UPDATE/삭제 없이 추가하며, 공개 등급컷은 revision 불변 계약을 따른다.
4. 학생 identity를 수집/복제/재할당하지 않는다.
5. 이 데이터는 공개 시험 참고자료이며 학생 Learning/Decision/Outcome이 아니다.
6. 공개 필드만 TEST 조회에 사용, 민감 데이터/비밀은 Git 제외한다.
7. 추정/미확인 상태는 내부 보존하며 도출값을 사실로 만들지 않는다.

## 실기기 검수 상태
|항목|상태|근거|
|iOS 설치·앱 실행|PASS|실제 기기 설치/실행·캡처|
|베타 인문·사회·상경·자연/종료 시각|PASS|Owner “확인 완료”; 해당 안내 화면 캡처는 아직 미확보|
|다음부터 보지 않기|NOT_VERIFIED|별도 재진입 확인 대기|
|건국 자연 준비중 제거|PARTIAL|코드 공통 공개 판별 회귀 PASS. 현재 TEST 대학 카드에는 준비중 표시; TEST 공개 scope는 한양 중심으로 운영과 다름|
|실제 미공개 제한 유지|PARTIAL|실기기 대학 카드 준비중 캡처. 상세 접근 제한 조작 미검수|
|기존 첨삭 진입|NOT_VERIFIED|새 평가/차감 없이 기존 기록 진입 검수 대기|
|11시험 등급컷 서버 연결|PASS|실제 HTTP 전 행 대조|
|11시험 실기기 표 조회|PARTIAL|Owner는 요청한 2024·6월 원점수/2026·9월 표준점수·추정 — 및 과목/접기 확인 완료. 나머지 9시험 실기기 전체 확인 아님|
|자료·학습 동일 표시/과목 변경/접기|NOT_VERIFIED|공통 API 확인, 실제 사용자 조작 대기|
|작은 화면/PDF Viewer|NOT_VERIFIED|iPhone 조작 대기, Android 기기 없음|

## 후속·운영 경계
TEST 적용은 운영 적용 승인이 아니다. 운영 SQL은 아직 미적용. 등급컷 운영 공개 및 후속 Store 후보는 별도 승인·실기기 QA 후 진행한다. 건국 TEST 공개 fixture 부재를 화면 문구 강제 삭제로 감추지 않는다. 기존 제품 전체 공개 범위는 기존 서버 계약을 따른다.

## Owner 후속 — 과목군 비교·조회 동선 단축

TEST60 기존 표시 확인 후 Owner는 과목별 반복 선택을 줄이고 비교 표로 변경하도록 지시했다. 기존 선택과목 개별 명시 선택 정책은 비교 표시 범위에서 대체한다. 채점/성적 입력의 선택과목 계약은 변경하지 않는다.

- 국어: 언어와 매체·화법과 작문 나란히. 수학: 기하·미적분·확률과 통계 나란히.
- 영어·한국사: 절대평가 원점수 한 표.
- 과학탐구: 같은 화면에 Ⅰ 네 과목/Ⅱ 네 과목 표를 연속 배치. Ⅰ·Ⅱ 별도 드롭다운 없음.
- 사회탐구: 네 과목씩 여러 표를 같은 화면에 세로 배치. 제2외국어·한문도 같은 다중 과목 구조 재사용.
- 학습 → 모의고사 → 공식 기출 → **등급컷 확인**을 기존 화면에서 펼쳐 시험 드롭다운 선택 → 표 즉시 표시. 별도 페이지 push와 중복 등급컷 펼치기 제거. 처음에는 국어 두 선택과목 모두 표시하며 과목군 변경 가능.
- 자료 상세와 학습 모두 동일 Panel/API 사용. 원점수 우선/표준점수·추정 원점수 —/출처 접기 유지. 데이터·SQL 변경0.
- 좁은 화면은 표 자체 가로 스크롤, 여러 과목 표는 기존 페이지 세로 스크롤. 분류는 현재 Registry의 실제 과목명으로 확인했으며 점수 값·등급은 변경하지 않는다.
- 기존 TEST60 사용자 검수 PASS를 새 레이아웃 PASS로 이전하지 않는다. 후속 TEST61 재빌드·설치 후 Owner 검수 필요.

검증: 기존 학습/모의고사 포함 20개 회귀 범위 PASS, analyze0. 최종 과탐 단일 선택에 맞춰 테스트의 이전 Ⅰ/Ⅱ 문자열을 정정하고 실패했던 두 화면 검사를 재실행해 통과했다. 실제 전사 데이터+mock API 렌더 확인: [국어](assets/task19/cutoff-materials.png), [수학](assets/task19/cutoff-math-group.png), [과탐Ⅰ·Ⅱ](assets/task19/cutoff-science-group.png). 새 레이아웃 실기기 PASS를 의미하지 않는다.

### TEST61 설치 영수증
소스 `6aa0b48d1c3e4db20fef9f4f1e29c8563f4cece4`의 iOS Xcode Release/codesign PASS, iPhone12ProMax에 별도 LS Math TEST **1.0.1(61)** 업데이트 설치·실행 완료. Android 별도 package versionCode61 APK/apksigner PASS, 연결 기기는 없음. 기존 본앱/TEST60/APP58 산출물 보존. iOS AOT SHA256 `9c6525c5c6ce9ff1157a0c74640a18758328134b884da7c3f9cbf2d4bf6d1ad8`, Android APK SHA256 `29a7f5a4563a6c409333984c0ba8ee179c770ffee87d492de5d7b904c381c5a4`. 새 비교 UI Owner 실기기 검수 대기. 운영 DB/Store0.

## TEST61 Owner 실기기 확인 및 추정 원점수 점검

Owner는 과목군 비교·인라인 조회에 “잘 확인했어. 훨씬 좋아졌네”로 응답했다. 요청했던 국어2/수학3/과탐Ⅰ·Ⅱ/사탐 스크롤 비교 UI의 실기기 검수를 PASS로 기록한다. 11시험 전수·PDF Viewer·Android 검수를 대신하지 않는다.

시험 자료 상세 `content_detail_page.dart`에는 동일 GradeCutoffPanel이 리소스 목록 앞에 연결돼 있다. PDF 문제 Viewer 내부에는 별도 등급컷 연결이 없다. 코드 확인과 실제 자료→PDF 왕복 검수는 구분한다.

Owner는 추정 원점수 계산·기입을 요청했다. 기존 전사본 검증 결과 미확보 대상은 2026학년도9월/수능, 2027학년도6월 국어·수학 각40행, 총120행이다. 저장 자료에는 표준점수 경계만 있으며 공통·선택 점수 분포와 조정 계수가 없다. [평가원 Q&A의 공식 학교 배포본](https://bbh-h.goebc.kr/upload/bbh-h/na/bbs_4418/2025/04/B6DF413B-63A8-D885-7FA7-E3F265825A35.pdf)에 따르면 공통과목을 활용한 선택과목 조정 이후 표준점수를 산출한다. 현재 표준점수 경계만으로 원점수를 유일하게 역산할 수 없으므로 계산값을 만들어 저장하지 않았다.

EBSi/메가스터디 원출처 검색은 수행했으나 대상120행의 검수 가능한 수치표는 확보하지 못했다. **추정 원점수 입력은 미완료**. 출처별 예상 원점수 또는 재현 가능한 분포/환산 자료 확보 후 별도 추정 필드·근거·revision을 연결해야 한다. 기존 원점수/표준점수/학생 성적은 변경하지 않는다. 데이터 검증기 2,457행/11시험 PASS, 이번 코드·DB·빌드 변경0.

### TEST62 참고 원점수 검수 빌드
소스 `6ea70552cc272bab6bc0177e6b77a2c40a4f7b39`의 iOS Xcode Release/codesign deep·strict PASS. 별도 `com.legendstudy.app.task16f` / LS Math TEST **1.0.1(62)**를 iPhone12ProMax에 설치·실행했다. 운영 본앱 `com.legendstudy.app`은 설치 전후1.0.1(58) 유지. TEST61 산출물 보존, 운영 앱/DB/Store 변경0.

산출물·로그·receipt: `/Users/woojinchang/development/legendstudy-private-backups/task19c-20261105/test62/`. AOT SHA256 `0cc48db5ee38ece99a11dee060f4c43f7b9f5bb9d0127b6bbc47bf8694491b17`. 기존 참고값9검사/analyze PASS 재사용. Android 재빌드 없음(이번 요청 iPhone).

Owner에게2026학년도9월 국어 화작91~98/언매87~96, 기준2024·2025학년도9월 및 수학·출처 확인을 요청했다. **참고표 실기기 UI 판정은 응답 대기**이며 이전TEST61 PASS로 대체하지 않는다.
