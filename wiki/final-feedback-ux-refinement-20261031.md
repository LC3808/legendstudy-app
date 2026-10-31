# APP/WEB Final Feedback UX Refinement — 2026-10-31

## Owner 결정과 범위

iOS31 IMG1330–1333 후속. [학생 중심 결과 정책](student-centered-essay-feedback-20261031.md)을 유지하며 재작성 기본 빈 답안, 명시적 이전 답안 가져오기, 종합평가 직후 접힌 음성듣기, PDF→재작성 24dp, 번호/문단/개선 행동 강조를 적용한다. 원본 평가·점수·Package·Credit·History는 변경하지 않는다. 운영 쓰기/평가 호출/설치/배포 권한으로 확대하지 않는다.

기준 APP `e55d4fc98ca4297f4348727f72e9e93a26218deb`, WEB `ff78af5eef2133cf9b78f6163ea7591c8188fdc1`. 기존 `.fvmrc` untracked 보존. Analytics 통합과 Firebase 호환 pin 보존.

## 변경 전후 및 파일

- APP `source_catalog_page.dart::_QuestionWorkState.load`, `exam_draft_actions.dart::loadExamAnswerPreview`: 이전 평가 답안을 암묵적으로 Draft로 복사하던 두 경로 제거. owner/question/rewrite-run별 저장된 Draft 우선. legacy Draft는 원본과 다른 수정 본문만 이관하며, 원본만 남은 legacy/이미지 자동 이관은 하지 않는다. 이미 생성된 scoped Draft(빈 본문 포함)를 존중한다.
- APP `importPrevious`: 사용자가 누른 경우만 원본 불러오기. 기존 텍스트 덮어쓰기 확인/취소, mounted·controller·owner guard, 변경 알림/저장 유지. 이전 답안은 참조용으로 계속 보존된다.
- WEB `source-exam-writer.tsx::AnswerEditor`: 기존 신규 재작성 빈 본문 정책 유지, legacy 이미지 가져오기도 실제 수정 Draft가 있을 때로 제한. 로딩/동기화 중 원본 불러오기 비활성. 원본 가져오기 확인/취소/문항별 독립 복원 테스트 추가.
- APP `student_feedback.dart::StudentFeedbackView`, `shared_history_page.dart`, `evaluation_report_view.dart`: 음성 위젯을 actions에서 voice slot으로 분리, 종합평가 바로 아래. 기존 TTS 재생 엔진/수명주기는 유지. 카드 간격24, PDF 뒤24, 피드백 번호·저장된 제목·문단, 개선 행동 연한 오렌지.
- WEB `evaluation-report.tsx::HumanEvaluationReport/FeedbackSection`, `evaluation-refinement.css`, `exam-result-layout.css`: 종합평가 다음 접힌 음성 details, 번호·제목/문단 간격, 개선 행동 오렌지/보완 warm red, rewrite margin24. 기존 PDF/TTS/CTA 함수 유지.
- APP `evaluation_report.dart::humanEvaluationReport/examEvaluationReport`: 우선 행동은 unresolved이고 1.3에서는 core_focus인 것만. WEB의 기존 core_improvement_keys mapping과 맞춤. 비핵심 unresolved action은 보완 카드에 남긴다. 해결된 항목을 새 우선 과제로 표시하지 않는다.

## 데이터 매핑 감사

| 데이터 | APP/WEB 표시 | 누락·중복 정책 |
|---|---|---|
| overall_summary / exam output.summary | 종합 평가 | 없는 총점/요약 생성 안 함 |
| strengths | 잘한 점 번호별 문단 | 원문 그대로; 번호는 UI 순서 |
| improvement progress explanation + next_action | 보완 사유 + 개선 방법 | unresolved만; core 여부는 우선순위에만 적용 |
| core_improvement_keys → core_focus | 우선 개선 과제 | APP 누락 mapping 보완, WEB와 동일 |
| rewrite_checklist / exam checklist | 다시 쓸 때 확인할 것 | action과 정확히 동일한 문장 중복 방지 |
| dimension level/explanation | 평가 항목별 설명과 단계 | 저장된 단계 보존, 종합 점수로 승격 금지 |
| before/previousReviews + rubric pins | 성장 비교 | 다른 기준/parent는 비교 불가; 과금과 성장 회차 별개 |

스크린샷의 빈 보완 카드만으로 DB mapping 오류를 단정할 수 없다. 보완 데이터가 없으면 기존 정직한 누락 안내 유지. 이번에 실계정 원문 API/DB를 조회하지 않았으므로 해당 실제 run의 보완 항목 존재 여부는 미확정. 합성 A–L Fixture는 APP/WEB 동일하고 API adapter/UI 회귀는 검증했지만 실제 평가 품질 검증을 대체하지 않는다.

## 종합 평가 별점: 현재 계약과 승인 후보

현행 `EvaluationReport`/WEB `Report`에는 numeric overall 단계가 없다. 문항 rubric의 level_1_to_5는 개별 항목이며 전체평균으로 사용할 수 없다. math overall 설명도 수치가 아니다. 따라서 이번 UI에서 종합 별점을 추가하지 않는다. 이는 확인한 코드/Fixture 계약 기준이며 모든 운영 JSON을 전수 조회했다는 의미가 아니다.

후속 제안(미구현/미적용): 기존 문항 evaluation output 내 선택형 종합 판정에 level1–5, 근거 설명, 적용 rubric version/digest, 산출 규칙 version을 함께 기록한다. 엔진이 공식 기준의 총체적 충족을 판단하되 항목 평균·공식 배점 환산·UI계산 금지. 독립 검토에서 항목별 판정/근거와 모순 검사. DB에는 평가 당시 immutable output으로 저장하고 과거행 backfill 금지. 기존 결과는 null로 표시 생략, 신규 결과만 explicit 값+유효성 검증 후 표시. 필드명/스키마 중복 검토 및 Worker·RPC·DB 영향 검토 후 별도 Owner 승인 필요. 실제 평가 호출 없음.

## 보존 검토 (longitudinal strategy 7개)

1. Historical fact: 기존 평가/수정 Draft는 유지하며 이번에는 UI projection만 변경한다. 평가 발생·저장 시점/회차를 바꾸지 않는다.
2. 복원/맥락: 원본 답안·평가·parent·Package digest로 기존 판단을 재현한다. 명시적 가져오기는 수정 Draft만 갱신한다.
3. UPDATE 손실: 운영 이력 UPDATE 없음. Draft는 기존 현재 작업 projection이며 덮어쓰기 확인/취소를 유지한다. 별도 Draft 버전 원장을 새로 만들지 않는다.
4. Identity: owner/question/rewrite-run key와 기존 세션 분리 유지. 신규 identity/소속 매핑 없음.
5. 분류: Learning의 답안 작성/피드백 표시이며 입시 Decision/Outcome으로 해석하지 않는다.
6. 개인정보/권한: 기존 인증·접근·retention/Analytics 설정 유지, 신규 수집·세션 추출 없음. 실제 계정 검증 미실행 범위를 명시한다.
7. 파생/원본: UI 번호/색/배치는 파생 표시만이며 원문·판정으로 저장하지 않는다. 종합 단계는 임의 계산하지 않고 버전/근거가 있는 미래 계약으로만 제안한다.

## 검증 및 한계

- APP Analyze 0 issues; 전체 1,290 PASS / 7 SKIP / 0 FAIL. 추가 위치/여백/너비1x·2x 포함 focused23 PASS.
- WEB TypeScript PASS, Lint 0 error / 기존4 warning, Production Build PASS; 전체1,409 PASS / 4 SKIP / 0 FAIL. 이전 테스트의 음성 h3 순서 기대를 새 collapsed details 정책으로 수정했고 실제 위치/접힘 assertion 추가. 테스트 삭제/추가 skip 없음.
- 재작성 빈 입력/가져오기/취소/Draft복원, 기존 parent/revision·서버 자격·무료/유료·Credit/History·Analytics·OCR·PDF·TTS mocks 포함 기존 전체 회귀 통과. 실제 무료/유료 제출·Credit 원장 전후 대조·기기 음성 출력은 실행하지 않음.
- 실제 WEB `http://127.0.0.1:8899/my/essays/`: 앱 export 로그인 안내 화면 확인. Chrome/IAB에 로컬 로그인 세션 없음. 로그인 버튼→로그인 화면까지 확인했지만 연결 불가 메시지. 계정 로그인·저장된 결과 조회 BLOCKED/미검증. 대학 현황 조회 실패 안내도 확인되어 실제 API 연결 성공으로 보고하지 않는다. 비밀번호/토큰 추출·운영 로그인을 localhost로 복제하지 않는다.
- 별도 `http://127.0.0.1:8898/`: 최신 렌더러 합성 Fixture 정적 검수 전용. 실계정 결과 검수의 대체물이 아님. 외부 Preview URL 없음.
- 전체 결과의 의미/점수/답안은 변경하지 않음. 운영 데이터 불변은 변경·호출을 하지 않은 범위의 확인이며 live hash 대조 아님.

## 빌드·최종 증거

서명 iOS1.0.1(32) 생성·보관 완료. iOS31 framework hash 전후 일치. 실제 설치/스토어 제출 없음.

## 롤백

이번 UI/Draft 변경 commit을 역순 revert하고 자동 검증 후 이전 설정으로 재빌드. scoped Draft/원본/History 삭제 금지. 보존 iOS31 사용 가능(설치는 별도 지시). WEB 운영 미배포이므로 운영 롤백 불필요. DB/Worker/Package rollback 실행 금지. 출력 계약/운영 WEB 배포/실제 Provider 평가/스토어는 별도 승인 대상.

## 마감 검증 기록

- APP source commit `a72292e` (위 구현·회귀·Wiki). WEB `c2c79f6`, full SHA는 최종 Git 보고 참조.
- APP 320/360/390/430dp × 1x/2x에서 예외 없음, 종합→음성→가이드 순서와 PDF→다시 쓰기 최소24dp 위치 assertion PASS.
- WEB 동일4너비 × 1x/2x 합성 렌더러 실제 Chromium: 가로 overflow0, 음성 표시/위치, PDF→CTA 간격26/34px 확인. `/tmp/legend-final-responsive.json`, `/tmp/legend-final-feedback-390-1.png`. 실제 페이지와 같은 data-view=summary에서 검사; 합성 화면의 TTS는 SSR이라 재생 불가이며 음성 실재생 검증이 아니다.
- Node22를 명시 실행해 TypeScript/Lint/Build/Test 재검증 완료. 1,409PASS/4SKIP/0FAIL, Lint 0error/기존4warning; 타입/Build PASS.

- iOS32 source SHA `a72292e3369c4c481581fb41a15b24c923bc48ab`; Bundle `com.legendstudy.app`; Observation=true; Google/Apple/Kakao 유지. codesign --verify --deep --strict PASS. framework SHA256 `b8d3235706600f8e963bff8c889008df2fd61a8ad9b83f221fe8f909f7b46f59`.
- 설치용 전체 경로: `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/ios/qa-final-feedback-32/Runner.app`. 같은 폴더 `receipt.json` 보관. 빌드 후 문서만 변경하여 최종 Git HEAD와 빌드 source SHA를 구분한다.
- iOS31 framework SHA256 `75b3763fda3007234110fe40d90d35d3faeaa69d1369875a0d991866fe346458` 동일. 기존 config/store-rc.local.json 불변; 임시 설정파일만 Observation=true로 빌드 후 삭제.

### 실제 WEB 검수 차단 원인과 실행 방법

WEB `src/lib/auth-config.ts::getBrowserAuthConfig`는 기존 보안 정책상 Production `https://lab.legendstudy.com` + LegendStudy project 또는 명시된 pages.dev + 별도 비운영 Supabase project만 허용한다. localhost는 환경변수가 있어도 null. 현재 로컬 환경에는 .env도 없지만, 공개 key만 추가해도 기존 origin 정책 때문에 실제 계정 검수는 해결되지 않는다. Auth 설정·정책을 이번 작업에서 우회하지 않았다. 신규 버전의 실계정 검수는 승인된 환경/접근 정책 확정 후 진행해야 한다. 기존 운영 WEB은 이번 코드를 배포하지 않았으므로 신규 UI 검수 URL로 오인하지 않는다.

현재 서버: 실제 export `http://127.0.0.1:8899/my/essays/`, 합성 `http://127.0.0.1:8898/`. 재시작 필요 시 WEB 저장소에서 `python3 -m http.server 8899 --bind 127.0.0.1 --directory out` (기존 포트가 사용 중이면 중복 실행 금지). 합성은 `python3 -m http.server 8898 --bind 127.0.0.1 --directory /tmp/legendstudy-student-review`. 합성은 SSR 정적 Fixture라 로그인·PDF 실행·TTS실재생 테스트용이 아니다. 실제 로그인 정보/토큰 요청·추출 없음.
