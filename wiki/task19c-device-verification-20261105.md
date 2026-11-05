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
|11시험 실기기 표 조회|NOT_VERIFIED|Owner 검수 대기; HTTP를 실기기 PASS로 대체 안 함|
|자료·학습 동일 표시/과목 변경/접기|NOT_VERIFIED|공통 API 확인, 실제 사용자 조작 대기|
|작은 화면/PDF Viewer|NOT_VERIFIED|iPhone 조작 대기, Android 기기 없음|

## 후속·운영 경계
TEST 적용은 운영 적용 승인이 아니다. 운영 SQL은 아직 미적용. 등급컷 운영 공개 및 후속 Store 후보는 별도 승인·실기기 QA 후 진행한다. 건국 TEST 공개 fixture 부재를 화면 문구 강제 삭제로 감추지 않는다. 기존 제품 전체 공개 범위는 기존 서버 계약을 따른다.
