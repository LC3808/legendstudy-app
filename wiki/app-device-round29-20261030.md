# APP Device QA Round 29 — 2026-10-30

Owner 기준 iOS1.0.1(29)의 미해결 항목만 수정한다. [28 후속 수정·29 빌드](app-device-followup-20261030.md), [LAB 디자인 정책](app-lab-refinement-20261029.md), [P0 관측·재첨삭 계약](essay-evaluation-stability-p0-20261029.md)을 계승한다. 평가·Credit·History·Worker 계약 변경 없음. Provider 호출/평가 제출/운영 쓰기/스토어 제출 없음.

## P0 근거: 문장 순서

LegendStudy `stlhijzpjfgwwdgunlsd`에서 제한된 SELECT와 READ ONLY 트랜잭션으로 확인했다. 트랜잭션 내 auth claim 설정은 기존 읽기 RPC 검증용이며 영구 설정/데이터 변경이 아니다.

- 서울여대 최초 `6ef28b49-12a5-4825-886d-548f0d9897df`: 저장된 `essay_exam_private.runs.result.questions[].criteria[].label`에 이미 `제시하\n준거 1 는 것이다`, `인\n준거 2 공 지능이`가 존재한다. 운영 `essay_exam_history` 반환 label과 DB 원문 일치 확인. RPC는 local_reviews/telemetry를 제외할 뿐 label 순서를 변경하지 않는다.
- 동 run의 고정 digest로 읽은 `essay_material_runtime_package`에서 `source_page_references[role=criteria].evidenceText` 4개가 저장된 label 4개와 일치한다. **가장 이른 확인 지점은 평가 입력의 공식 자료 패키지**다. Flutter/API가 준거를 삽입한 것이 아니다. PDF 추출의 특정 알고리즘/원본 지면 대조까지 확인한 것은 아니므로 추출 원인은 추정으로 남긴다.
- APP `examEvaluationReport`는 해당 label을 rubric.name에 연결하고 `approvedEssayEvaluation`은 기준·단계 변화·feedback을 한 문자열로 표시했다. 표시 정규화는 줄을 연결할 뿐 단어 순서/준거를 이동시키지 않는다. 임의 이동·삭제·단어 재조립은 하지 않는다.
- 이번 수정은 기준/변화/평가 설명의 명시적 구분, 실제 action 앞 빈 문단, 명시적 등급·번호 행 경계 보존이다. 문장 내부의 이미 잘못 끼어든 준거는 **미해결 원본 구조 문제**다. 원본 공식 지면과 추출 좌표/표 구조 대조 및 versioned 자료 정정은 별도 후속 과제이며 이번에 평가 패키지/기존 결과를 고치지 않는다.

## 표·종합 단계의 실제 계약

- 동국대 최근 완료 run `c5b5ec08-ebd9-44da-ba79-061194ed8293`의 세 문항 criteria는 `binding/label`만 가진다. 등급·배점·설명이 평문이며 표 셀/행 데이터가 없다. `S/A/B/C/D/E/F` 및 번호 행을 보존하고 추론 표를 만들지 않는다. **표 구조화는 별도 데이터 계약 과제**다. 원문과 기존 공식 자료 링크 유지.
- 서울여대 위 run, 경희대 `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1`, 동국대 위 run의 7개 문항은 `evaluation.summary`가 문자열이다. run.summary도 문자열. 평가 객체에는 dimensions 등 기존 필드만 있고 숫자형 overall 단계가 없다. public.essay_evaluations도 overall_summary text이며 overall 숫자 컬럼은 없다. 조사한 결과 범위에 전체 단계가 없으므로 별/평균을 생성하지 않는다. 다른 모든 운영 결과까지 전수 확인한 것은 아니다.

## 실제 변경

- `approved_result_adapter.dart::approvedEssayEvaluation`: 기준·평가 변화·실제 feedback을 독립 문단과 제목으로 구분. 전체 기준/feedback 유지. explanation/evidence/action은 빈 문단으로 구분.
- `result_disclosure.dart::displayEssayText`: 명시적 평가 제목/개선 방법/등급 행을 보존. 번호·등급 행과 다음 행을 무조건 합치지 않음. 불확실한 준거 위치는 원문 그대로. `ResultAccordion` 테두리 #9CAABE로 강화, 기존 배경/브랜드 유지. `ProcessingGuidance`에 스트레칭/대기 안내 추가, 통계/가짜 단계 없음.
- `shared_history_page.dart::_Result`: 기록 아이콘 대신 텍스트 포함 버튼. 좁은 화면·큰 글씨를 위해 AppBar 아래 별도 행, 글씨 배율에 따라 높이 반영. 기존 `goToEssayHistory` 스택 정리 재사용.
- `round_history_actions.dart`: 관측된 문항 중 processing이 있을 때만 기존 단계바/안내 애니메이션 사용. 재처리 요청/성공 문항/정산은 그대로. waiting만 있는 첨부 화면에서는 움직이지 않는 것이 정상이다.
- `exam_draft_actions.dart`: 이어쓰기/확인 간격16dp.
- `source_catalog_page.dart::_SelectedAnswerWriterState.reviewAnswers`, `_SourceWriterState.saveForReview`: 모든 문항 아래 확인 버튼 하나. 모든 편집기와 사진의 저장 상태를 확인하고 기존 ExamAnswerReview로 이동. 단일 스크롤 Column으로 접힌 편집기도 계속 유지. 저장 실패/진행 중이면 내용 보존하고 확인 진입 차단, 버튼 busy로 중복 진입 방지. 제출 API/키/무료 정책은 불변.

## 보존 설계 검토

[장기 보존 전략](longitudinal-learning-admissions-data-strategy.md)의 일곱 질문: 1 새 서버 historical fact 없음, 2 원본 평가/자료로 재현 가능, 3 UPDATE·삭제 없음, 4 동일 owner/canonical identity 유지, 5 Learning 표시 개선만, 6 새 수집/외부 전송/권한 확대 없음, 7 표시용 문단·색상을 원본 점수/사실로 저장하지 않음.

## 검증·빌드

- Flutter Analyze: **0 issues**.
- 전체 Flutter Test: **1233 PASS / 7 SKIP**. 초기 추가3문항 테스트는 빈 답안 안내가 `문제 2, 문제 3`인 것을 한 문항 문자열로 기대하여 실패했다. 기대값을 실제 다문항 계약에 맞춘 뒤 전체 재실행 PASS.
- 신규7검증: 원본 준거 순서 유지, action 문단, 기준/변화/설명 분리, 등급 행 보존, 아코디언 테두리, 3문항×글씨1/2배. 기존 테스트 보강:16dp 간격·재처리 접수1회/processing애니메이션/완료 후 제거·하단 확인 위치·실제 결과 화면 기록 텍스트 버튼. 재처리 반복 애니메이션에서는 bounded pump를 사용하며 pumpAndSettle로 무한 idle을 기다리지 않는다.
- 기존320/360/390/430dp×글씨1/2배 UI, 무료 재첨삭·Credit·History·OCR·PDF·TTS mock 회귀 포함. 실기기 음향/실제 재처리/실제 촬영은 NOT TESTED.7 SKIP을 PASS에 포함하지 않음.
- 합성 결과 화면 PNG 렌더를 확인하여 네이비 테두리/본문 정렬을 점검. pixel golden 비교/운영 화면 캡처는 아님.
- Wiki handoff/link/budget 검사 PASS. 기존29 framework hash `d87c1a7d59ed4270ae14fc0f2ef3455f11a9ad58a9a1c1e7ca9f9541b13404ac` 보존.
- iOS **1.0.1(30)** Release 서명 빌드 PASS (Flutter3.47.6). 소스 `8c58961a4cc2125a9c2bbc12356a8726e1b7bc1c`.
- 산출물: `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/ios/qa-device-round29-30/Runner.app`. 설치/스토어 업로드 없음.
- App.framework SHA256 `65be78b376219ed14bbcf729e9bff350ca393ff66ed1af08ed87c85a20ec7a82`. codesign deep/strict PASS. Bundle ID `com.legendstudy.app`, 29와 Entitlements/URL Schemes 일치, 기존29 hash 불변.
- 실제 Generated.xcconfig에 전달된 QA 설정을 private config 전체와 대조 PASS: Observation V1 true, Google/Apple/Kakao 유지. 설정 값/키 원문은 기록하지 않음.
- [빌드 receipt](../tool/app-device-round29-qa-build-20261030.json). 기존 flutter_tts SwiftPM 지원 경고는 남지만 CocoaPods 기반 빌드 성공. 의존성 변경 없음.

## 롤백

운영 롤백은 필요 없다. 이전 검수용 `build/ios/qa-device-followup-29/Runner.app`를 보존하며 앱 삭제 없이 동일 Bundle ID로 덮어 설치할 수 있다. 기기에서 낮은 빌드 설치가 제한되면 이전 소스로 더 높은 검수 번호를 만들어야 한다. 코드 롤백은 이번 소스 커밋을 후속 revert하고 새 검수 빌드를 만든다. reset/clean/원장 정정은 사용하지 않는다.
