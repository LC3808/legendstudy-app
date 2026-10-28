# APP 최종 통합 — 2026-10-28

상태: 코드 통합·자동 검증·Android/iOS Release 빌드 완료. 운영 페이지네이션 미적용·실기기 QA 대기. 전체 완료/스토어 출시로 보고하지 않는다.

## 근거와 작업 보존

Owner 전체 인수 지시와 추가4과제가 기존 APP 보류/OCR 설계만 지시를 해당 범위에서 대체한다. [내구적 결정](decisions.md#2026-10-28--app-학습-회차와-과금-분리사진-ocr-입력-보조), [기존 성장 정책](essay-growth-history-ui-20261026.md), [OCR 설계·합성 인쇄 PoC](essay-photo-ocr-design-20261028.md), [10/25 release](app-release-20261025.md) 계승.

- 별도 managed worktree `app-final-integration-20261028/legendstudy-service-app-20261022`, 브랜치 `codex/app-final-integration-20261028`.
- Codex 원본 d5714b8, Claude eedd28f63be9214ad2803bb66999911969d13829. 원본 두 폴더의 미커밋 변경·브랜치 보존.
- 구현 commit `58ef17476342ea8bdda56f68368dd3f47df5bba3` (이후 문서 영수증 commit 별도). Codex pending 작업 보존 commit 0ebad6e, Claude merge 777911e. 충돌은 wiki/log 양쪽 원문 보존. 기존 PDF487 동일+37추가=524, asset166 확인. 원본 작업트리는 수정하지 않았다.
- [통합 전 상태 원문](app-claude-status-archive-20261028.md). Claude 아코디언·크롭·임시저장·접수/진행·브랜드·음성·인증 UI 유지.

## 보존 검토 7항

1. 생성·완료 시각은 기존 run 값이며 UI 순서를 새 학습 사실로 기록하지 않는다.
2. immutable 답안·결과·canonical ID·rubric/evidence pin을 그대로 조회한다.
3. UPDATE·삭제·원장 보정 없음. 새 SQL은 SELECT 전용 함수 추가안이다.
4. 현재 auth UID 확인, 원래 owner RPC 사용, 계정 변경 시 이전 답안/OCR 노출 차단.
5. Learning 표시이며 입시 Decision/Outcome 또는 합격 예측이 아니다.
6. 사진 OCR 작업은 기기 내 세션, 평가 첨부와 분리; 확인 후 TEXT만 기존 draft 동기화. 새 개인정보 수집·보관 정책을 만들지 않는다.
7. 회차 번호·그래프는 파생 UI. 기준 변경/누락을 추정 점수로 채우지 않는다.

## 구현

- `source_catalog.dart / SourceCatalog.forHistory`: owner-scoped 완료 이력의 exam/question IDs를 기존 대학 browse metadata와 엄격히 일치시킴. 대학명은 유일 일치만 허용, 문항 중복·불일치 거절. 해당 run 문항으로 제한하며 verification/evaluationReady를 승격하지 않음. 재작성만 제한 카탈로그 진입을 허용; 공개 HOLD 정책·서버 availability/quote 유지.
- `source_catalog_page.dart`: 기존 답안을 재작성 초안 초기값으로 복원, 이미 수정한 scoped draft 우선. 기존 parent/additional quote·멱등키/1·0Credit 처리 보존. 수락 runId를 화면 이탈 후에도 저장, 복귀/100초 이후 상태 조회, completed는 공통 저장 결과 화면 자동 열기. failed 확인 후에만 pending키 해제.
- `shared_history.dart`: owner-scoped 페이지들을 끝까지 읽은 뒤 학습 회차 계산, failed 제외. 동일 시험 성장 묶음에 유료 후속 포함; canonical 문항별 그래프 분리. 과금 lineage는 불변. 구 서버가 정확히50행을 반환하면 범위 경고·회차 번호 보류로 잘못된 ‘첫 첨삭’ 방지.
- `essay_growth_page.dart / growth_timeline.dart`: 최근 시험부터5개 표시+스크롤5개, 최신 기본 펼침. 문항별 1회 막대·2회 비교 막대·3회 이상 전체 꺾은선. 최초/최신 요약·각 회차 각 문항 결과 접근. 서로 다른 pin/기준·누락은 선을 연결하지 않으며 하락/정체 유지.
- `answer_ocr.dart`: 카메라/갤러리→기존 crop→온디바이스 인식→학생 수정→명시 합치기/교체→기존 editor/controller.save. OCR 실패는 원 답안/사진/평가 첨부 불변. 30,000자 초과 적용 거절, 자동 제출 없음.
- `ios/Runner/AppDelegate.swift`: Vision accurate ko-KR/en-US, 언어지원 확인, 자동 언어교정 끔. `android/.../AnswerOcrBridge.kt`: bundled ML Kit Korean16.0.1. 공통 MethodChannel,20MB/20MP 검사. 기존 이미지·수리평가 경로 변경 없음.

## 운영 확인과 SQL 적용 게이트

Production `stlhijzpjfgwwdgunlsd` 읽기 전용 확인: 기존 `essay_exam_history(uuid)`는50행 상한, 별도 페이지 RPC 없음. 기존 Sogang 완료 run의 대학명→유일 university ID→browse exam/question IDs 정확히 일치 확인. 운영 schema 변경 없음.

[적용 후보 SQL](../supabase/migrations/20261028120000_essay_history_pagination.sql)은 `essay_exam_history_page(before_at,before_id,limit≤50)`를 추가한다. auth.uid/require_active/account 범위+created_at,id keyset. 기존 exact-run 함수 redaction 재사용, 목록에서 answers/result 제거. 원장/결과/답안 변경 없음. 기존 함수 불변이라 WEB 영향 없음. 롤백은 새 함수 DROP 한 문장(파일 하단); APP은 기존50행+범위 경고로 fallback.

**AGENTS 기본 절차에 따라 Production 적용은 Owner 실행 대기.** 로컬 함수 존재를 Production 배포로 간주하지 않는다. 전체50회차 초과 운영 조회 완료 기준은 아직 충족하지 못했다. 적용 후 auth 없는 호출 거절·타 계정 제외·일반계정 페이지/최종행 대조가 필요하다.

## 검증

- Flutter3.47.6 사용. 전체 테스트1,158 PASS /7 조건부 skip(운영 결과 fixture·렌더 등). 마지막 소규모 변경 후 대상23검사 PASS, Flutter Analyze 이슈0.
- 저장run41회/123초 이상 polling, background pause/resume, failed키 해제, completed 결과 자동 이동 테스트 PASS. 실제 Provider 호출 없음.
- canonical history 메타데이터/답안 복원/HOLD·공개목록·계정 경계·유료3차·pin불일치·OCR 수정/합치기/교체·에러 전달 테스트 PASS.
- `tool/test_essay_history_pagination`: 격리 로컬 PostgreSQL17에서123행, timestamp 동률 keyset, 중복/누락0, 다른 owner 제외, 답안/결과 목록 제외, anonymous 권한 거절 PASS. 운영 DB 테스트 아님.
- 실제 학생 손글씨 CER/WER 미측정. 기존 Mac 합성 인쇄3장9회 CER/WER0,0.09~0.49초를 iOS/Android 정확도로 확대하지 않음.
- Native 인증 설정: 기존 Bundle/Application ID·서명·entitlements·schemes 보존. public auth settings의 email/google/apple/kakao 활성 확인. 기존 로컬 Google/Apple 설정 포함. 로그인/IAP 실기기 완료를 주장하지 않음.
- Production Provider 호출0·새 평가0·Credit 변경0·운영DB 수정0·Worker 변경0·스토어 제출0.

## 남은 검수

Owner SQL 적용 후 >50회차 계정 전체 조회 확인. iPhone/Android에서 로그인, 기존 완료 결과→다시쓰기→초안 복원, OCR 촬영·크롭·인식·편집·합치기/교체, 계정 변경, 실제 손글씨·조명·장문, 성장3회/큰글자, 웹/앱 동일 결과를 확인한다. 새 첨삭/실제Credit/IAP는 별도 승인 범위에서만 실행한다. backend 정산 E2E는 이번 mocked regression과 구분한다.

## Release 산출물

기존 public Production config·release flags·서명 사용. Android1.0.1(2026102802), min24/target36, application ID com.legendstudy.app. iOS1.0.1(21), deployment15, Bundle ID com.legendstudy.app·Google scheme 포함 확인. 실제 Store 업로드·실기기 설치 없음.

|산출물|SHA256|
|---|---|
|`build/app/outputs/bundle/release/app-release.aab` (93.3MB)|`dd22e885e61bf282e717d9bf63ba888594835e94002934a3f104f101b4247d29`|
|`build/app/outputs/flutter-apk/app-release.apk` (122.0MB)|`5480a759ebf287fc65958143a5f71520d75f2210331fae8e41b643d29ba67a36`|
|`build/ios/ipa/legendstudy_app.ipa` (31.2MB)|`765e8d295fe6ad013be0532d8344f8679afb2db65ecb7d6d364b591824acb64a`|

로그: `/tmp/legendstudy-final-analyze.log`, `/tmp/legendstudy-final-all-tests.log`, `/tmp/legendstudy-final-targeted.log`, `/tmp/legendstudy-history-sql-final.log`, `/tmp/legendstudy-release-android-aab.log`, `/tmp/legendstudy-release-android-apk.log`, `/tmp/legendstudy-release-ios.log`. 초기 병렬test/build의 integration_test registrant 실패는 순차 최종빌드로 해소. 기존 toolchain/tts SPM/Cupertino 경고는 남아 있으나 두 Release 빌드 성공.

복구: 배포/원장 변경이 없어 서버 롤백 불필요. 코드 통합 전 checkpoint777911e 또는 기존 출시 APP 사용 가능. 새 SQL 미적용이며 적용 후 복구는 파일의 DROP FUNCTION만 사용한다. 원래 두 작업트리 변경을 버리거나 서명 파일을 Git에 넣지 않는다.
