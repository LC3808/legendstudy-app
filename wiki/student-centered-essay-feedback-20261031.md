# 학생 중심 첨삭 결과 — 2026-10-31

## Owner 결정과 적용 경계

[기존 결과 개선](essay-web-result-refinement-20261030.md), [원문/정정 후보](rubric-structure-fix-20261031.md), [재첨삭·정산 계약](essay-evaluation-stability-p0-20261029.md), [성장 정책](essay-growth-history-ui-20261026.md), [Analytics](analytics-v1-implementation-20261030.md)를 보존한다.
이번 Owner 결정은 학생 결과의 기본 정보 구조를 **종합 평가 → 높은 평가를 위한 작성 가이드 → 잘한 점 → 보완할 점과 개선 방법 → 다시 써보기**로 바꾼다. 대학 공식 배점표를 학생에게 나열하는 대신 저장된 답안 진단과 수정 행동을 보여준다.

이전 공식 원문 disclosure 정책은 학생 **결과 화면**에 한해 이번 정책으로 대체한다. 과거 Wiki의 시행 당시 기록은 삭제하지 않는다. 학습 성장 페이지의 별도 원문 상세보기와 PDF 생성 계약은 이번 변경에서 보존한다. 원문 정정·PDF 대조 작업은 계속 별도 품질 과제다. 숭실 후보의 운영 digest 불일치와 적용 BLOCKED 판정은 유지한다.

운영 DB/RPC/Auth/Worker/Package/Provider/평가 실행/Credit/History 변경 및 WEB 배포·스토어 제출·기기 설치 없음. 저장 결과 재생성 없음. Source/UI 구현과 운영 활성화는 다르다.

## 복원 기준 및 보존 검토

APP `codex/essay-evaluation-stability-p0-20261029`, 시작 `20c1861b7d70ed62f0439817e849de8fb1a97090` (remote 일치). 경로 `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022`.
WEB `codex/web-app-release-20261024`, 시작 `e8099691663b08b067c092c8497421b3a85304c3` (remote 일치). 경로 `/Users/woojinchang/development/legendstudy-release-20261024`.
기존 APP `.fvmrc` untracked 보존, WEB 시작 clean. Claude Analytics 브랜치/통합 코드는 수정하지 않았다.

[일곱 보존 질문](longitudinal-learning-admissions-data-strategy.md): ① 평가 발생 시점/기준 버전과 이번 UI 변경 시점 분리 ② 원본 JSON·답안·Package pin·기존 adapter를 유지하여 재구성 가능 ③ UPDATE/새 저장소 없음 ④ 사용자·parent·canonical question·lineage 불변 ⑤ 학습 피드백 표시이며 입시 성과/합격 예측 아님 ⑥ 신규 수집/권한 확대 없음, Git Fixture는 합성 문장만 ⑦ 가이드 UI는 기존 사실의 파생 표시이며 새 평가 사실을 만들지 않음.

## 데이터 매핑과 구현

| 저장 데이터 | APP/WEB 표시 | 보존/부족 정보 |
|---|---|---|
| overall_feedback / overall_summary → report.summary | 종합 평가 | 종합 숫자 단계 없음: 평균·총점 생성 안 함 |
| strengths | 잘한 점: 제목·설명·검증 가능한 답안 인용 | 원문과 정확히 일치하는 인용만 학생 글로 표시 |
| improvements / progress_items → weaknesses | 문제·이유·개선 방법 | action은 문제 바로 아래, 별도 배경 |
| core 우선순위 next_action / report.actions | 가이드 우선 개선 과제 | 중복 action은 해당 보완 항목 안내, 고유 action만 한 번 표시 |
| rewrite_checklist / report.nextSteps | 가이드의 다시 쓸 때 확인할 것 | 저장된 문항별 점검 사항만 사용 |
| criterion explanation / dimension feedback | 접힌 평가 항목별 설명과 단계 | 검수 별칭/중립 `평가 항목 N`; raw rubric을 제목/가이드로 복사하지 않음 |
| exact criterion label + ` — ` evidence | 설명 누락 시 fallback / 고유한 추가 설명 | 동일 설명 1회, 매칭 안 되는 내부 원문은 학생 화면 비노출, 원본 삭제 없음 |
| sentence_feedback | 학생 문장 / 평가 / 개선 방법 / 수정 예시 | 기존 exact-offset 검증 유지, 학생 원문 아닌 예시는 명확히 구분 |
| previous_improvement_reviews.reason | 비교 조건 통과 시 실제 개선 내용 | 단계 상승만으로 문제 해결이라고 추정하지 않음 |
| criterion ID / pins / priorId | 기존 비교 함수·성장 그래프 | 다른 버전/lineage 비교 거절, 유료 정책 불변 |

가이드에 **별도 검증된 높은 평가 핵심 조건/권장 답안 전개 순서가 없음**을 명시한다. 저장된 checklist를 권장 논리 순서로 오인해 번호를 붙이지 않는다. 모든 대학 공통 서론·본론·결론/5단계 템플릿을 만들지 않는다. 기존 결과는 summary/strengths/weaknesses/actions/checklist만으로 호환된다.

APP `StudentFeedbackView`, `studentCriterionFeedback`, `studentWorkspaceReport`/`StudentWorkspaceComparison`: 단일 읽기 전용 표시. `shared_history_page.dart` 인문 결과·`EvaluationReportView` 공통 결과·기존 live workspace에 연결. 답안/이전 답안, 문항·회차·날짜, TTS/PDF, 마지막 서버 자격 기반 `EssayFollowupAction` 보존. legacy live workspace는 기존 controller 재작성 경로/검증된 비교 상태를 재사용한다. Preview 학습 데모는 운영 결과가 아니므로 기존 데모 렌더러 유지.
WEB `EvaluationReport`/`HumanEvaluationReport`, `CriterionResults`, `EvaluationComparison`: 같은 stored report 사용. `ExamResultLayout` 기본 탭 전체 학습 흐름, 작성 가이드 탭, 마지막 재작성 CTA. server `free_rewrite_available`가 true일 때만 무료 버튼 활성화, 유료는 기존 continuous contract 사용. 네트워크 제출 로직 변경 없음.

## 내부 자료와 관리자

공식 source text/criterion ID/가중치/배점/digest/예전 결과를 변경하지 않는다. `OfficialRubricView`/`OfficialRubricTable` 및 자료 검수 도구/후보/EXACT_QUOTE/독립 검토 코드 보존.
WEB `/admin/materials/`의 `MaterialsConsole`, `/ql/`의 `QualityConsole`/`QualityCaseDetail`은 변경하지 않았다. 후자는 `official_evidence`, `frozen_evidence_bindings`를 계속 표시하며 `is_quality_operator` 계약/권한 거절을 유지한다. 관리자·일반 사용자·비로그인 구분은 기존 격리 테스트로 검증; **실제 운영 관리자 로그인/DB 권한을 이번 작업에서 재검증한 것은 아니다.** 학생 화면 비노출은 DB 보안 변경이 아니다.

## 신규 출력 확장 설계 — 미적용

기존 1.3 출력은 overall_feedback, criterion_feedback, strengths, improvements, core_improvement_keys, previous_improvement_reviews, sentence_feedback, rewrite_checklist를 이미 가진다. evaluation_summary/weaknesses/improvement_actions/evidence_quotes를 새 필드로 중복 생성하지 않는다.
추가로 필요한 후보는 optional `writing_guidance`: `requirements[]`(criterion ID + 공식 근거 ID + 학생용 설명), `structure[]`(문항 요구에 대응하는 순서/목적 + criterion ID), 기존 improvement key 참조다. 구체 필드명/버전 확정·producer 변경은 Owner 승인 후다.
- 가이드 없음/null은 정상 legacy 경로, 빈 내용을 생성하지 않는다.
- 사용 평가 당시 Package digest/criterion version과 동일해야 한다. 다른 기준이면 숨김/검수 대상.
- 모든 criteria/evidence/improvement 참조는 같은 문항에서 존재해야 한다.
- 인용은 기존 exact quote/offset 검증, 수정 예시는 별도 타입. 없는 학생 문장 금지.
- 배점/등급/종합 점수 필드 추가 없음. 공식 자료와 다른 수치 금지.
- 독립 검토는 논제 적합성, 학생 답안의 부족 요소와 행동 연결, 기존 평가와 모순, 불필요한 서론/결론, 일반론 반복을 검사해야 한다. 기준 완화 금지.
- backward compatibility, 기준 mismatch, 누락/잘못된 참조, exact quote 실패, 소문항, 표/일반 원문, 부분/완료 재처리 Fixture가 모두 필요하다.
현 단계는 설계만이며 Worker/DB/API 출력은 확장하지 않았다. 새 출력의 실평가 품질 PASS를 주장하지 않는다.

## 검증 범위와 품질 판정

공통 합성 Fixture `student-feedback-cases.json` 12건 A–L: 정확한 개념, 연결 부족, 오해, 논제 이탈, 결론 부족, 부분 미충족, 표, 텍스트, 배점 차이, 소문항, 재첨삭, guide 없는 과거 결과. APP/WEB 동일 JSON. UI는 입력으로 준 판단/행동만 보존하고 raw rubric/없는 인용을 숨기는지 검사한다. **합성 Fixture 통과는 평가 엔진이 실제 학생을 올바르게 평가한다는 증거가 아니다.**
자동 검증과 실제 평가 품질 판정은 분리한다. 실제 학생 답안·공식 PDF와 새 가이드 간 일치성 10개 기준의 사람 검수는 NOT TESTED; Provider 호출하지 않았다. 신규 조건/구조 생성 미구현이므로 완전한 새 가이드 서비스 준비 상태는 PARTIAL이다.

APP 새 테스트: A–L source immutability/단계 보존/없는 인용 차단/action 중복 방지/320·360·390·430dp 1.8x/기준 불일치/근거 fallback. 기존 수리 360dp 2x 테스트는 새 scroll widget을 대상으로 유지.
WEB 새 테스트: A–L 동일 입력/제목순서/원문 비노출/단계/immutability, 마지막 재작성 server eligibility. 기존 duplicate/missing feedback 테스트를 새 표시 정책에 맞춤. 품질·관리자 접근, 무료/유료/재처리/History/OCR/Analytics/PDF/TTS 기존 전체 회귀도 실행한다. 운영 DB 불변은 이번 코드 diff/호출 없음 범위로 확인하며, live 데이터 전후 hash 대조를 했다고 보고하지 않는다.

최종 테스트 수치·빌드·SHA는 아래 완료 기록에 추가한다.

## 검수 환경·롤백

WEB 합성 화면 `http://127.0.0.1:8898/` (실계정 없음); production export 로컬 `http://127.0.0.1:8899/my/essays/` (로그인 UI 포함, 실제 계정 인증 미실행). 외부 Preview URL 없음. 합성 화면은 네트워크/평가 요청 없이 결과·비교를 확인하는 정적 HTML이다. 본 시스템의 실제 History 결과는 Owner 로그인 이후 읽기 조회가 필요하다.
APP 빌드 예정 1.0.1(31), 기존23–30 보존, install/store upload 안 함. 검수 빌드의 기존 Observation/소셜로그인/Bundle/서명 설정 유지. 새 빌드에서 실제 평가 버튼을 자동 실행하지 않는다.
롤백: 이번 UI 커밋을 역순 revert하여 검증·재빌드한다. 미커밋 변경 삭제/reset하지 않는다. 기기 설치는 Owner 별도 지시, 기존 보존30 빌드를 사용 가능. WEB은 미배포이므로 운영 롤백 불필요; 로컬/승인 후 배포 소스를 이전 WEB SHA로 되돌린다. DB/Worker rollback.sql은 실행하지 않는다.

## WEB 완료 기록

WEB commit `ff78af5` (변경 11파일). 최종 전체 1,408 PASS / 4 SKIP / 0 FAIL, TypeScript PASS, Lint 0 error/기존 4 warning, Production Build PASS. 합성 결과/비교 320·375·390·768·1024px에서 document width 초과/가로 overflow 0, 390px 캡처 육안 확인. `/tmp/legend-student-responsive.json`, `/tmp/legendstudy-student-feedback-390.png`. APP/WEB A–L Fixture byte 일치. 실계정 로그인·운영 결과 품질/관리자 로그인 미검증.

## APP 자동 검증 완료

최종 Analyze **0 issues**, 전체 Flutter Test **1,285 PASS / 7 SKIP / 0 FAIL**. 새 학생 결과 테스트 18 PASS. 기존 7 SKIP은 PASS에 포함하지 않음. 최종 로그 `/tmp/legend-student-analyze-final.log`, `/tmp/legend-student-app-verified.log`. 작업 중 데모 분기에 삽입된 잘못된 named parameter를 발견·수정했으며 겹친 테스트 실행을 종료하고 단일 전체 실행으로 재확인했다. 기존 기능 계약을 완화하거나 테스트를 삭제하지 않았다. Wiki handoff PASS/current-status 11,905 bytes. iOS 생성 이후 빌드 receipt를 별도로 기록한다.

## iOS 의존성 충돌 발견과 최소 조정

첫 빌드(소스 `5f8b0d4`)는 SwiftPM resolve에서 실패: 기존 firebase_core5.1.0/analytics13.0.1이 Firebase iOS13.1.1의 AppCheck12를 요구하지만 기존 GoogleSignIn9 계열은 AppCheck11을 요구한다. 운영/로그인 설정 문제나 평가 기능 실패가 아니다.
Firebase Flutter만 정확히 core4.15.2/analytics12.6.1로 고정하여 둘 다 Firebase iOS12.19.3을 사용하도록 조정한다. 기존 Google 로그인 플러그인·네이티브 URL scheme·Bundle·서명·iOS15 target은 유지한다. 관련 Firebase 6개 lock entry만 변경, Analytics 이벤트/Noop/수집 동의/GA4 설정은 변경 없음. SwiftPM cache를 직접 수정하거나 Firebase를 제거하지 않는다.
공식 의존성 근거: [GoogleSignIn Flutter Package](https://raw.githubusercontent.com/flutter/packages/main/packages/google_sign_in/google_sign_in_ios/darwin/google_sign_in_ios/Package.swift), [Firebase12.19.3 Package](https://raw.githubusercontent.com/firebase/firebase-ios-sdk/12.19.3/Package.swift) (AppCheck11.3..<12). 사용 Flutter package의 배포 archive도 확인했다. 조정 후 Analyze/전체 Test/서명 build를 다시 확인한다. 실제 Google/Apple/Kakao 로그인·GA4 수신은 실기기 미검증.

의존성 조정 후 Analyze0 및 전체1,285PASS/7SKIP/0FAIL 재확인 (`/tmp/legend-student-analyze-native.log`, `/tmp/legend-student-tests-native.log`).
