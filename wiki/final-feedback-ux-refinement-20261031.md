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

1. 학생 identity: owner 분리 기존 유지, 신규 수집 없음.
2. event/history: 기존 이벤트·run 생성 경로 유지, 학습 이력 UPDATE 없음.
3. 원본/파생 구분: 학생 원본과 UI 번호/레이아웃 분리, 원본 가져오기 명시 동작.
4. 시간/회차: 기존 parent/revision/무료14일·유료 학습회차 유지.
5. provenance/version: Package/기준/digest 유지, 과거 기준 교체 없음.
6. 동의/권한: 기존 인증·접근 정책/Analytics 설정 유지, 세션 추출 없음.
7. 복구/분석: Draft 저장 key 유지, 기존 빌드 보존, UI commit revert 가능. 운영 원장 수정 없음.

## 검증 및 한계

- APP Analyze 0 issues; 전체 1,290 PASS / 7 SKIP / 0 FAIL. 추가 위치/여백/너비1x·2x 포함 focused23 PASS.
- WEB TypeScript PASS, Lint 0 error / 기존4 warning, Production Build PASS; 전체1,409 PASS / 4 SKIP / 0 FAIL. 이전 테스트의 음성 h3 순서 기대를 새 collapsed details 정책으로 수정했고 실제 위치/접힘 assertion 추가. 테스트 삭제/추가 skip 없음.
- 재작성 빈 입력/가져오기/취소/Draft복원, 기존 parent/revision·서버 자격·무료/유료·Credit/History·Analytics·OCR·PDF·TTS mocks 포함 기존 전체 회귀 통과. 실제 무료/유료 제출·Credit 원장 전후 대조·기기 음성 출력은 실행하지 않음.
- 실제 WEB `http://127.0.0.1:8899/my/essays/`: 앱 export 로그인 안내 화면 확인. Chrome/IAB에 로컬 로그인 세션 없음. 계정 로그인·저장된 결과 조회 NOT TESTED. 대학 현황 조회 실패 안내도 확인되어 실제 API 연결 성공으로 보고하지 않는다. 비밀번호/토큰 추출·운영 로그인을 localhost로 복제하지 않는다.
- 별도 `http://127.0.0.1:8898/`: 최신 렌더러 합성 Fixture 정적 검수 전용. 실계정 결과 검수의 대체물이 아님. 외부 Preview URL 없음.
- 전체 결과의 의미/점수/답안은 변경하지 않음. 운영 데이터 불변은 변경·호출을 하지 않은 범위의 확인이며 live hash 대조 아님.

## 빌드·최종 증거

최종 빌드/commit/반응형 결과는 아래 마감 기록에 추가한다. iOS31 보존, 신규32 계획. 실제 설치/스토어 제출 없음.

## 롤백

이번 UI/Draft 변경 commit을 역순 revert하고 자동 검증 후 이전 설정으로 재빌드. scoped Draft/원본/History 삭제 금지. 보존 iOS31 사용 가능(설치는 별도 지시). WEB 운영 미배포이므로 운영 롤백 불필요. DB/Worker/Package rollback 실행 금지. 출력 계약/운영 WEB 배포/실제 Provider 평가/스토어는 별도 승인 대상.
