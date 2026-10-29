# APP 2026-10-29 실기기 2차 수정

상태: APP 구현·자동 검증 완료, iOS 검수 빌드 완료(미설치). 운영 Worker/광운 Draft 및 실제 인증·재첨삭 검증은 대기. 기존 [1차 수정](app-owner-fixes-20261029.md)과 구분한다.
기준 `codex/app-owner-fixes-20261029` LOCAL/REMOTE `80a5ab4dbeb331fb9278d4a1888a15d6ab9ae39e` 확인 후 별도 `codex/app-device-qa-fixes-20261029` 생성. 기존 통합 worktree, 원본 APP/Claude 브랜치, 미추적 `.fvmrc` 보존. 운영 변경·Provider 평가·Credit 쓰기·스토어 제출 없음.

## Owner 범위 및 보존 검토

첨부 IMG_1285–1291의 실제 증상: 서울여대 Q1 실패/Q2 완료, 새로고침·재처리 피드백 부족, 재첨삭 제출 거절, 광운 계정 저장 거절, 로그인 버튼 미노출. 대학 Push, 기술 문구 제거, 소문항 작성, 기존 답안 바로 확인, 모달·진행 화면 정리가 추가 범위다. 결과 화면 전면 개편·성장 분석 상세 QA는 제외한다.

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의 일곱 보존 기준을 적용한다.
1. 기존 발생/완료/정산 시각과 원본 기록을 유지한다.
2. run snapshot·공식 패키지·기존 checkpoint·답안은 변경하지 않는다.
3. 새 Draft 권한 후보는 사용자·문항·만료·승인 사유만 별도 기록한다. 기존 이력 UPDATE/삭제나 전체 공개 변경은 없다.
4. 동일 Auth UID와 기존 WEB/APP session/Draft RPC·RLS를 사용한다.
5. 답안/재작성은 Learning, 저장 권한 승인은 운영 Decision이다. 입시 Outcome 수집은 없다. 학습 사실·과금 유형·재첨삭 권리·실패 재처리를 혼합하지 않는다.
6. 운영 조회는 지정 사례/관련 함수/소규모 권한 정보에 한정한다. 학생 원문·JWT·키는 저장소에 기록하지 않는다. 권한 후보는 효력14일·Auth 사용자 삭제 시 cascade이며 기존 답안은 기존 삭제 정책을 따른다.
7. UI 파생 상태는 원장 사실로 저장하지 않는다. 테스트는 합성 입력·격리 DB/HTTP이며 운영 성공으로 계산하지 않는다.

이 범위는 [Native 디자인](design-system.md), [앱 통합 결정](app-final-integration-20261028.md), [기존 Credit/학습 회차 분리](essay-growth-history-ui-20261026.md)를 유지하는 구현이다. 수리 IMAGE와 OCR TEXT 입력은 분리한다.

## 운영 근거 — 읽기 전용

서울여2026 인문사회 `6ef28b49-12a5-4825-886d-548f0d9897df`:

- 생성 2026-10-29 12:38:03 KST, 완료 12:41:38 KST. 현재 두 문항 completed.
- Q1 a0 독립 검토의 grounding fail: 공식 표현의 축약·변형을 정확한 직접 인용으로 표시. 별도의 전송 오류나 timeout으로 단정하지 않는다. 독립 검토 오류 타입은 ProviderFailure이며, 저장된 거절 사유로 품질 검증 거절을 확인했다.
- 12:40:38 재처리 요청 generation1, attempts `{"0":1}`. Q1 retry1 완료, Q2 최초 성공 checkpoint 보존. 이는 명시적 재처리 기록이며 자동 재시도 횟수로 계산하지 않는다.
- decision `5523bb69-705d-4511-a5cf-9325003eab58`: reserve 1건 `(0,+1)`, consume 1건 `(-1,-1)`. 순예약0·순차감1. 실패 평가·독립검토 호출도 Provider 비용이 발생할 수 있으며 Provider 청구 원장은 미검증.
- 정확한 parent run의 읽기 전용 `essay_exam_quote` SELECT는 `included`, `credits:0`, 기존 두 canonical ID 반환. 14일 이내·재첨삭 미사용·환불 없음, 현재/원본 package digest·binding·regime 일치. 과거 APP HTTP 거절 코드/당시 payload는 확보하지 못했으므로 원인을 확정하거나 실제 재제출 PASS라고 보고하지 않는다.
- 최종 제한 SELECT 재확인에서도 같은 서울여 run이 completed·결과 2개다. 이 작업에서 운영 run/Provider/Credit/History를 수정하거나 재실행하지 않았다.
- 외대·건국2023의 기존 실패/최종완료 근거는 [1차 진단](app-owner-fixes-20261029.md)을 재사용한다. 실평가 재실행 없음.

광운2026 인문1교시 exam `cc5dfe4e-63ec-5877-be9a-8bdafbb97e8d`, Q1 `f529765c-7d71-5993-bef9-d2e9e926e020`, Q2 `19e67592-af8f-5231-b7d1-e20f91c6a523`: 두 `is_published=false`. 현행 `essay_open_session`은 이 flag를 요구해 PT422. 기존 Draft/session RLS는 owner 및 account lifecycle을 검사한다. 단순 APP 버튼 활성화로 서버 저장 문제를 해결할 수 없다.

연결된 iPhone 12 Pro Max의 앱 버전은 `0.1.0(1)`로 확인되며 이전 산출물 `1.0.1(22)`와 다르다. 설치 바이너리의 Git SHA/컴파일 define은 복원하지 못했다. Production Auth GET settings의 Google/Apple/Kakao 활성은 모두 true. Google URL scheme은 Info.plist의 빌드 변수이며 기존 Auth.local.xcconfig 및 이전 빌드 plist에서 로컬 Google iOS ID와 일치한다. Debug/Release 모두 같은 xcconfig 포함, Apple entitlement 유지. Kakao는 기존 외부 브라우저 PKCE이며 native Kakao SDK 도입 없음. 실제 세 Provider 인증은 이번 작업에서 수행하지 않았다.

## APP 변경

- `source_catalog_page.dart`: 대학 선택을 iOS Cupertino/Android Material push로 연결하고 중복 push 차단, 선택값·목록 scroll 보존. owner 변경 시 이전 화면을 감춘다.
- `exam_session_status.dart`: owner-scoped 상태 읽기와 기존 run 재처리를 분리. 서버 retry_allowed 및 문항 상태를 재확인한 뒤 동일 API의 retry만 호출. 진행/기록 화면이 같은 durable retry key를 사용한다. 불확실 응답에는 key를 보존한다.
- `round_history_actions.dart`, `ExamSubmissionPanel`: 새로고침의 변화 없음/오류/최신 상태, 재처리 접수 안내, 주기 조회와 background/resume. 완료 문항은 재전송하지 않고 서버의 failed-only 계약에 맡긴다. 0 Credit은 서버가 허용한 실패 재처리에만 표시한다.
- `exam_rewrite.dart`, 제출 패널: 정확한 parent 상세를 다시 읽어 자격·canonical 문항 집합을 검증하고 parent-relative revision으로 TEXT payload 구성. 로컬 Draft revision은 변경하지 않는다. 무료 권리가 없는 결과의 다시 쓰기는 명시적 확인 후 유료 추가 작성으로 연결하며 자동 차감하지 않는다.
- `exam_draft_actions.dart`: 선택 문항의 기기 답안/기존 owner 서버 Draft를 읽고 이어쓰기·답안 확인·일부 작성 상태 표시. 새 서버 session/evaluation을 만들지 않는다. 서버 답안을 복원할 때 이미 작성된 기기 답안은 덮어쓰지 않는다.
- `answer_sections.dart`: 서울여2026 공식 source SHA `bd57ddfa7982c2c2c72bcb39b9c41693b19efe3eccf3c59095f2eadcab31be15`의 문제 문구에서 Q1/Q2 각각 (1)/(2) 확인. 동일 canonical ID 아래 두 작성 칸을 단일 TEXT로 저장·제출. 기존 비구조화 답안은 그대로 표시하고 학생이 구분 표시를 넣을 수 있다. 자동 분할/덮어쓰기 없음. 구조화 답안의 빈 소문항 제출을 차단한다.
- `exam_presentation.dart`: 학생 화면에서 TEXT/IMAGE·Essay/Math·실행 승인 등 내부 문구 제거, 제출 gate는 유지.
- 답안 확인 구분선 토큰 통일/빈 메시지 공간 제거. 진행 제목 중앙 정렬, 큰 휴식 안내·작은 회색 보조 문구, 중복 구분선/불필요한 활동 막대 제거. 가짜 진행률 없음.
- `tool/device-qa`: 기존 운영 config의 로그인·평가 flag와 public ID 누락을 빌드 전에 차단하고 서명된 iOS 검수 앱/소스 receipt 준비. 자동 설치·업로드 없음.

## 운영 적용 대기 후보

### Worker — 배포 승인 필요

`tool/essay_lab/retry_feedback.py`, `cloudflare_runtime.py`, `reviewed_runtime.py`, `live_worker.py`: 서버가 승인한 동일 문항의 다음 재처리에 직전 실패 코드·허용된 검토 항목·길이 제한된 사유를 데이터로 전달한다. 이전 배포의 EXACT_QUOTE/독립검토 실패 checkpoint도 읽는다. 공식 패키지/cache/snapshot은 그대로이며 결과 인용·독립검토·입력/출력 검증을 변경하지 않는다. 자동 재시도/새 run/정산 변경 없음. 이 패치는 **미배포**이므로 운영 실패율 개선을 주장하지 않는다. 롤백 기준 Worker `451b8cae-f603-48e9-9ca9-8ccc16b4e3d4`.

### 광운 Draft — DB/RPC 및 사용자별 권한 승인 필요

[install](../supabase/candidates/device_qa_20261029/draft-install.sql), [지정 사용자 grant](../supabase/candidates/device_qa_20261029/draft-grant.sql), [verify](../supabase/candidates/device_qa_20261029/draft-verify.sql), [rollback](../supabase/candidates/device_qa_20261029/draft-rollback.sql).

baseline 함수 source MD5 `3c3dbdc274623c96f25836b9508840af`을 검사한다. 비공개 `essay_private.draft_access`는 설치 시 비어 있다. 별도 승인된 owner UUID에 광운 해당 두 문항만 14일 저장 권한을 부여하는 스크립트다. 전체 문항 공개·실행 권한/무료 Credit 부여가 아니다. 기존 RPC owner `essay_executor`에 SELECT만 제공하고 authenticated/anon/service_role 직접 접근 차단. 기존 Draft/session RLS·CAS 유지. rollback은 원래 open 함수를 복원하며 새로 저장한 답안/session/권한 승인 기록도 삭제하지 않는다. 대상 owner/범위 승인 없이는 grant 실행 금지.

### 완료 문항의 중간 결과 조회

현행 `essay_exam_session_status`는 문항 상태만, `essay_exam_history`는 회차 완료 결과만 제공한다. 실패 문항이 남은 회차에서 완료 결과를 즉시 표시할 public DTO는 없다. APP은 성공 상태와 결과 보존을 알리고 전체 완료 후 결과를 연다. 중간 결과 버튼은 이유를 명시하고 비활성화한다. 이를 completed로 위조하거나 private checkpoint를 직접 읽지 않는다. 즉시 중간 결과 조회는 owner 검증된 별도 RPC/결과 DTO 설계·승인이 필요한 미완료 항목이다.

## 검증 및 산출물

| 검증 | 결과 | 범위/한계 |
|---|---|---|
| Flutter Analyze | PASS, 0 issues | Flutter 3.47.6/Dart 3.13.5 |
| 전체 Flutter Test | 1,178 PASS / 7 SKIP | 신규 QA 13개 포함. 7개는 외부 public-read opt-in 및 별도 local/private 결과 fixture 미제공; PASS 아님 |
| 신규 APP 계약/Widget | 13 PASS | 무료/유료 payload·parent revision·정확한 문항 집합, 재처리 동일 key, refresh 오류/변화없음/접수, history 자동조회 완료, 기존 서버 Draft 읽기·부분 작성, 소문항/OCR 보존, iOS push/swipe/선택 복원, 320px 1/2/3문항 모달·버튼 접근 |
| Worker offline | 23 PASS | 직전 동일 문항 feedback 한정·길이 제한·인용/검토 실패 유지·timeout 자동 재평가 금지·checkpoint/fencing·배포 stage dependency 포함 |
| 빌드 설정 | 5 PASS | 기존 release 검사2+신규3: 누락/false flag·잘못된 backend·native scheme/Debug/Release 누락 차단 |
| 격리 Credit SQL | 18 PASS | 동시8회 retry 예약1, 성공 문항 보존, 완료1Credit/재첨삭0/중복정산0/owner/만료/rollback |
| 격리 공통 실행 surface | PASS | 합성 Package→fake Provider adapter→Ledger→History, lease fencing/receipt redaction. 실 Provider0 |
| 광운 Draft 후보 SQL | 6 묶음 PASS | 실제 session/Draft DDL·RLS·CAS, owner·만료·lifecycle 제한·Ledger/Registry 불변·rollback. lifecycle helper는 stub |
| 현재 Production 재첨삭 quote | PASS(읽기 전용) | 기존 서울여 parent는 included/0Credit. 실제 제출/과거 거절 재현은 NOT TESTED/미확정 |
| 실제 소셜 인증/기기 QA | NOT TESTED | Auth 설정/SDK mock/버튼 조건은 확인, 실제 계정 로그인은 수행하지 않음 |

실행: `./tool/flutterw analyze --no-pub`, `./tool/flutterw test --no-pub --reporter expanded`, 관련 `python3 -m unittest`, `tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin` 및 `--surface-only`, `--draft-access-only`.
전체 자동 테스트에서 기존 OCR·성장·TEXT/IMAGE 분리·이메일/Auth lifecycle·Draft·History·Credit 계약 회귀 포함. 실학생 손글씨 정확도·Android 실기기·운영 E2E를 대신하지 않는다.

### 주요 함수 및 승인 단위

| 파일 | 함수/영역 | 운영 영향 |
|---|---|---|
| `lib/features/essay/source_catalog_page.dart` | `_SourceSelection.selectUniversity/saveSelection/restoreSelection`, `ExamSubmissionPanelState.submit/pollStatus/retryFailedQuestions`, `_ExamAnswerReviewState.build`, `_SourceWriterState.load/build` | APP만. 기존 API의 상태 읽기/사용자 명시 retry/submit 경로 |
| `lib/features/essay/exam_session_status.dart` | `readExamSessionStatus`, `retryExistingExam`, `ExamSessionStatus.canRetry` | 서버 권한·같은 run/key 검사 |
| `lib/features/essay/round_history_actions.dart` | `work/build/didChangeAppLifecycleState` | auth 준비 전 busy 고착 방지, 재처리 후 상태 갱신 |
| `lib/features/essay/exam_rewrite.dart`, `shared_history_page.dart` | `examRewriteAnswers`, `_Result.openWriter` | parent 기준 payload, 무료 불가 시 명시 유료 작성 선택 |
| `lib/features/essay/exam_draft_actions.dart` | `load/open/build` | owner 기존 Draft 읽기/기기 답안 우선, 조회 중 미확인 상태를 없음으로 표시하지 않음 |
| `lib/features/essay/answer_sections.dart` | `essayAnswerSections/splitAnswerSections/missingAnswerSections`, `SectionedAnswerInput` | SWU 공식 Q1 page2/Q2 page8, 동일 TEXT body |
| `tool/essay_lab/cloudflare_runtime.py`, `reviewed_runtime.py`, `live_worker.py`, `retry_feedback.py` | `consume/persist_receipt`, `prepare_input`, `previous_feedback/feedback` | 미배포 Worker 후보. 별도 승인 필요 |
| `supabase/candidates/device_qa_20261029/` | `essay_open_session`, private draft grant | 미적용 SQL. 기존 RLS·Credit·History 불변, 대상/기간 별도 승인 필요 |
| `tool/device-qa` | `validate/validate_native/main` | 기존 config·signing 보존, 소스 commit 고정·앱 identity/signature 검증·산출물 hash receipt |

### Commit 및 iOS 산출물

- APP 코드/테스트/후보 Commit: `a65cc760a2d3319066e3a0cd1e69ee20763aa26f` (`fix(app): repair device QA retry, rewrite and draft flows`). 이 SHA의 tracked APP source clean 상태에서 빌드.
- 브랜치: `codex/app-device-qa-fixes-20261029`. 아래 빌드 근거를 기록한 후속 commit은 문서만 변경하며, 실제 최종 LOCAL/REMOTE SHA는 Owner 최종 보고에 별도로 제공한다. 코드 SHA와 문서 HEAD를 혼동하지 않는다.
- `./tool/device-qa --build-name 1.0.1 --build-number 23`: PASS. Xcode 60.0초, signed Release `build/ios/iphoneos/Runner.app` 36.7 MB. `codesign --verify --deep --strict` PASS.
- `com.legendstudy.app` / `1.0.1(23)` 실제 plist 확인. Google scheme 일치, app callback 보존, Apple entitlement `Default`, development provisioning 및 검수 iPhone 12 Pro Max 포함 확인. 프로파일 만료 2027-09-21.
- `App.framework/App` SHA-256: `5a993801bf937496a587344baa3880f92a562161138339511e0d212beb785aae`.
- 로컬 receipt: `build/ios/device-qa-receipt.json`, native 검증: `build/ios/device-qa-native-verification.json`. build 폴더는 Git 제외. 실제 기기 설치/실행/인증/스토어 업로드 **미실행**. 이번 빌드는 현재 기기의 `0.1.0(1)`과 다르며 Owner 검수 전 새 artifact 설치가 필요하다.
- 기존 `flutter_tts` Swift Package Manager 미지원 경고는 남아 있으나 빌드는 성공했다. SDK·의존성·Signing·Bundle ID·IAP·Auth 설정 변경 없음.
- 이전 `build/ios/ipa/legendstudy_app.ipa`의 SHA-256 `0d4e9d54852a2c183f934a67229186b750f55310c091f814325f955d87d6950c`가 1차 기록과 일치함을 재확인. 덮어쓰거나 삭제하지 않았다.
- Wiki handoff: PASS, current-status 12 KB 미만. 기존 `.fvmrc` 미추적 파일 보존. Release/Claude 브랜치 병합 없음.

### Owner 최종 판정 기준

APP 수정/자동 검증/빌드/커밋은 PASS. 실제 재첨삭·소셜 인증·기기 화면은 NOT TESTED이며 과거 제출 거절 원인은 미확정이므로 해당 P0의 최종 운영 판정은 PARTIAL이다. Worker 안정성 개선과 광운 계정 저장은 검증된 후보까지 준비했지만 운영 적용은 BLOCKED(별도 승인). 실패 중인 회차의 완료 문항 중간 결과 조회는 현행 공개 DTO 한계로 미구현이다. 기존 정상 결과와 History는 보존한다.

## 롤백 및 미검증

기존 Release 브랜치에 병합하지 않는다. APP은 기준 SHA `80a5ab4d`의 이전 검수 산출물로 되돌릴 수 있다. 현재 작업 commit을 별도 revert할 때 기존 미커밋 변경과 보존 대상 브랜치를 삭제하지 않는다. Worker/SQL 후보는 미적용이므로 현재 운영 롤백 작업은 불필요하다. 실제 재첨삭·정산/소셜 인증/실기기 UI·손글씨·Android device OCR은 자동 테스트 PASS와 구분한다.
