# APP 실기기 10/29 수정·검증

Owner 2026-10-29 1·2차 및 3차 일부 검수 지시. 기준은 `codex/app-final-integration-20261028`의 `16a03084c389b71a02ab3e8fc67965eef72f67c4`이며 시작 시 remote 동일 확인. 수정은 같은 통합 worktree의 별도 `codex/app-owner-fixes-20261029` 브랜치. 원본 Codex/Claude 작업트리와 미추적 `.fvmrc` 보존.

[10/28 통합](app-final-integration-20261028.md), [인문·상경·자연 기존 정책](commerce-korea-20261026.md), [수리 공개 보류](math-technical-review-20261026.md), [인증 검수](auth-native-owner-acceptance.md)를 계승한다. 재작성·성장·페이지네이션·run 복원 재설계와 추가 OCR 개발은 이번 범위 밖.

## 실제 실패 원인 — 운영 SELECT 확인

| 요청 | 실제 결과 | 실패 근거 | Credit |
|---|---|---|---|
| 한국외대 `1f3230a8-168e-4f8a-8b7d-6d17541ba3c1` | 3문항 completed, 2026-10-28 13:46:05 UTC | Q2 최초 independent review 거절, Q3 최초 EXACT_QUOTE 및 후속 review 거절 3회 | reserve 1, consume 1, 총 balance -1 / reserved 0 |
| 건국2023 `6de564cf-ef6d-468b-8ff6-db13212df0f1` | 2문항 completed, 2026-10-28 14:14:50 UTC | Q2 a0/a1 INDEPENDENT_REVIEW_NOT_ACCEPTED, a2 통과 | reserve 1, consume 1, 총 balance -1 / reserved 0 |

두 run 모두 Q1 a0 성공 checkpoint 유지, Q1 retry checkpoint 없음. 각 실패 문항만 동일 run에서 retry; final/summary checkpoint 존재. 이전 2024 공식근거 길이 오류와 다르다. `semantic_review.py`는 fail/uncertain 판정을 `ProviderFailure('INDEPENDENT_REVIEW_NOT_ACCEPTED')`로 올리므로 이 이름만으로 Provider 통신 장애라 단정하면 안 된다.

거절 근거는 공식 글자수 준수 미확인과 최고 수준 판정의 모순, 정확 인용 실패, 자료의 서로 다른 통계 개념 혼동 및 학생 답안에 없는 내용의 긍정 평가였다. 원문 답안·개인정보·원문 reviewer 설명은 이 문서에 복사하지 않았다. Provider 별도 청구 원장까지 검증한 것은 아니다. 실패 시 평가/독립검토 호출도 비용 발생 가능하나 앱 Credit은 각 1회만 정산 확인.

APP 진행 화면은 run이 reserved여도 문항 실패 checkpoint가 있으면 재처리 필요로 표시한다. 기존 `essay_exam_session_status` 문항 checkpoint를 읽어 완료/실패/대기를 구분한다. 상태 조회 오류를 Worker 실패로 만들지 않는다. 상세 상태 조회는 5초 제한이며 다른 계정으로 전환되면 화면에 반영하지 않는다. 기존 실패 문항만 재처리하는 retry와 idempotency 계약 유지. 운영 재실행·새 평가·Provider 호출 0.

**미해결:** 생성 품질의 반복 거절 자체는 APP 표시 수정으로 해결되지 않는다. 최소 후속안은 기존 evaluator/reviewer 계약을 유지하며 위 오류 유형의 합성 재현 fixture 및 생성 지침을 보강하는 Worker 후보 검토다. 검증 기준을 약화하거나 무조건 자동 재시도하지 않는다. Worker 수정/배포/실평가 별도 승인 필요, 이번에는 변경하지 않았다.

## APP 수정

- 대학 카드의 `첨삭 시작하기 →` 제거. 대학명·로고·이동 chevron·카드 터치·공개 정렬 유지. 서비스 상태 조회 중/실패 재시도는 목록 상단 한 곳에서 표시. 보류 대학 진입 권한을 확장하지 않음.
- 답안 작성/확인의 시험 제목은 표시 전용 `essayExamTitle()` 공통 처리. Browse에서 track/session에 전체 공식 제목이 들어온 경우 한 번만 표시하고 별도 대학명 중복 제거. Registry 원본/식별자는 불변.
- 서비스 계열과 inputMode/engine/publication/readiness를 분리해 표시. 사회·상경에는 수리 문항 포함 가능. 자연·공학·이학·의예는 APP 제출 보류. 기존 서버 준비 상태의 일반 메시지를 일괄 ‘수리논술’로 잘못 표시하던 부분 정정.
- 운영 Registry 363시험의 서로 다른 track 전체 54종(값 없는 경우 포함)을 읽어 분류 테스트. `수리형`, `수학`, `A형`, `B형`, `통합`, `자유전공`, `수리 논술`, null은 이름만으로 학습 계열을 확정하지 않으며 ‘계열 확인 필요’ 표시. Math 입력이라는 이유로 자연으로 분류하거나 엔진을 활성화하지 않는다. 모호한 8종에 해당하는 21건(실제 시험 20 + 기존 synthetic smoke 1)은 별도 공식 metadata 정비가 필요하다. 계열 미확정 Math 문항은 제출을 보류하며 TEXT 공개 상태를 별도 확인한다.
- 문항별 TEXT/IMAGE·Essay/Math·공개/실행 상태는 기존 availability API로 표시한다. 이 조회는 Credit을 예약하지 않는다. 혼합 TEXT/Math 선택은 기존 APP에 혼합 일괄 payload 경로가 없음을 명확히 안내하고 제출하지 않음. 선택을 자동 제외하지 않고 답안 보존. TEXT만 명시 선택하면 기존 부분 제출 확인·회차 Credit 계약 유지; 전부 기존 Math catalog에서 승인된 leaf이면 기존 Math 경로 유지. 혼합 admission의 mathQuestions만으로 별도 Math session 경로를 열지 않는다. **혼합 한 회차 제출 구현 완료가 아님.** 기존 Backend 계약 확인 후 별도 APP 연결 작업 필요.
- 진행 제목 중앙 배치, 주요 안내 `잠시 쉬어가세요.\n결과가 준비되면 확인할 수 있어요.` 확대/중앙. 짙은 섹션 경계·회색 문항 구분. 서버가 알려 준 상태에만 단계 이동; 임의 진행률/남은 시간 없음.
- 사진 OCR/크롭/입력 편집·저장/기존 TEXT·IMAGE 계약은 변경하지 않음.

## 소셜 로그인

Production `/auth/v1/settings` 읽기에서 Google/Apple/Kakao 모두 enabled=true. 기존 네이티브 로그인 UI 및 identity 계약 존재. 시작 시 iOS Generated.xcconfig의 DART_DEFINES에는 세 OAuth flag가 모두 없었으나, ignored `config/store-rc.local.json`에는 모두 true였다. **현재 로컬 빌드 설정 누락은 확인, Owner 설치 바이너리의 정확한 define는 미확인.**

`tool/store-release`가 세 OAuth enabled flag 및 Google public client ID가 없거나 false이면 빌드를 중단하도록 보강. 기존 완전한 production config로 최종 산출물 빌드. 서버 Auth 설정·키·계정 ID 변경 없음. 실제 계정의 로그인/취소/복귀 실기기 재검수는 미완료이며 widget/native mock 테스트와 구분한다.

## 광운대 계정 답안 저장

Production `essay_open_session(uuid,uuid)`는 `essay_questions.is_published=true`를 필수로 검사하며 실패 시 PT422 INVALID_QUESTION. 광운대 17시험 34문항은 이 legacy flag가 모두 false. 별도 서비스 계약으로 인문16회차를 공개한 상태와 모순이다. APP은 계정 Draft를 열 때 이 함수를 호출하므로 서버 계약 차단 경로가 확인된다. 개별 Owner 기기 오류 로그를 확보한 것은 아니다.

PT422는 계정 저장 미지원, PT401은 로그인 재확인, 나머지는 조회 실패로 구분하고 기기 답안 보존. 저장 재시도도 기존 오류 안내를 지우지 않는다. **서버 저장 복구 완료가 아님.** 최소 서버 후속안: `essay_open_session`/`essay_save_draft`의 동일 owner·canonical question·revision 검증을 유지하면서 공개 여부와 개인 Draft 작성 권한을 분리할지 승인 후 검토. 전체 is_published=true 변경, RLS 우회, 임의 SQL 변경 금지. 기존 세션/답안·History 변경 0.

## 보존 검토 7문항

[장기 학습 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의 기준 적용: (1) 기존 발생/기록/정정 시각 유지, (2) snapshot/checkpoint 원문 불변, (3) current UPDATE 및 이력 삭제 없음, (4) 동일 auth.users identity 유지, (5) learning 사실·실행 판단·결과 분리, (6) 제한된 두 run/집계 SELECT만 사용하고 학생 원문/키 미기록, (7) 표시 계열/상태를 새로운 raw fact로 저장하지 않음. 신규 storage 없음.

## 검증 및 산출물

- `./tool/flutterw analyze`: issues 0.
- `./tool/flutterw test`: 1,165 PASS / 7 기존 skip. 인증 버튼/취소·복귀 mock, 카드, 단·다문항 작성/제목, 혼합 선택 보존/문항별 상태, 보류, 진행/실패/완료, draft, 기존 OCR/TEXT·IMAGE/History 포함. 실기기 실제 인증·평가 PASS로 해석하지 않는다.
- `python3 -m unittest tool.test_essay_session_retry tool.test_essay_async_runtime tool.test_semantic_review`: 13 PASS. 성공 문항 보존/실패 문항만 재시도/불확실 dispatch 재전송 금지/독립검토 거절 fail-closed 검증. sync/async 동등성 테스트의 실제 시계 0/1ms 차이 flake는 테스트 clock 고정으로 수정; Worker 코드는 불변.
- `python3 -m tool.test_essay_exam_credit --pg-bin /opt/homebrew/opt/postgresql@17/bin`: 격리 로컬 PostgreSQL 18 PASS. 동시 8개 요청의 단일 예약, 불완전 결과 정산 금지, 완료 정확히 1Credit, 재정산/History 변조 방지 포함. 운영 DB 연결 인자 없음.
- `python3 -m unittest tool.test_store_release_config`: 2 PASS. OAuth flag/Google 공개 client 설정 누락 및 false 차단, 설정값 로그 비노출.
- `python3 tool/check_wiki_handoff.py`: PASS. current-status 12 KB 이내, routing/내부 링크 검증.

운영 DB/Worker/Auth 설정 변경, live Provider, Credit 쓰기 및 Store 업로드 없음.

### 수정 파일

| 파일 | 변경 |
|---|---|
| `lib/features/essay/exam_presentation.dart` | 표시 제목·계열·문항 상태·availability 표시 공통 함수 |
| `lib/features/essay/source_catalog_page.dart` | 대학 카드·작성/확인 헤더·계열·혼합 제한·진행 및 문항 상태 |
| `lib/features/essay/exam_submission.dart` | Credit을 예약하지 않는 availability 조회 공유 |
| `lib/features/essay/source_draft.dart` | 계정 저장 거절 원인 구분·로컬 보존 |
| `tool/store-release` | 소셜 설정 누락 Release 차단 |
| `test/exam_presentation_test.dart`, `test/essay_mixed_review_test.dart`, `test/essay_submission_restore_test.dart`, `test/source_draft_sync_test.dart` | 새 정책/버그 회귀 |
| `test/public_service_cards_test.dart`, `test/source_catalog_widget_test.dart`, `test/essay_service_preparing_test.dart` | 승인된 표시 변경에 맞춘 기존 검증 |
| `tool/test_store_release_config.py`, `tool/test_essay_async_runtime.py` | 릴리스 설정 회귀·결정적 테스트 clock |

관련 wiki의 status/log/decisions/index/auth/광운/Worker/통합 문서는 본 문서로 연결한다.

## 남은 승인·실기기 항목

1. Worker 반복 품질 거절 방지 후보 검토/배포와 필요 시 승인된 실평가.
2. 광운대 계정 Draft 서버 권한 계약 정합화.
3. 혼합 시험 한 회차 APP 제출 및 모호한 8종 track 공식 분류 정비.
4. 새 산출물의 실제 Google/Apple/Kakao 로그인, 단·다문항 제목/진행 표시 실기기 검수.

원격 기준 브랜치는 보존. 롤백은 이 수정 브랜치를 사용하지 않고 위 기준 SHA에서 기존 release config로 다시 빌드하거나 수정 커밋을 revert한다. Production DB/Worker rollback은 필요 없음(변경 없음). Owner 검수 전 릴리스 완전 완료로 처리하지 않는다.

## 최종 빌드 기록

- iOS `1.0.1(22)`: Archive/IPA PASS. IPA Info.plist 버전 확인, Apple sign-in entitlement Default 및 세 OAuth define=true 확인.
- Android `1.0.1(2026102901)`: AAB PASS, jarsigner 검증 PASS.
- 동일 ignored production config 사용; 새 기기 설치/Store 업로드/실제 로그인·평가는 수행하지 않음.

| 산출물 | SHA-256 |
|---|---|
| `build/ios/ipa/legendstudy_app.ipa` | `0d4e9d54852a2c183f934a67229186b750f55310c091f814325f955d87d6950c` |
| `build/app/outputs/bundle/release/app-release.aab` | `af90925ae9542ebca1fe73ebb97f8c86bc8e597b3b874595d928cbe5254c2907` |
