# Essay LAB 문장 다듬기

2026-09-28 · UI/typed preview boundary IMPLEMENTED; persistence and contract extension
REVIEW PROPOSAL ONLY. Actual AI/provider/Production writes: NONE.

## Product contract

맞춤법 검사기가 아니라 학습 가치가 높은 문장 관측을 제공한다.
유형: 맞춤법·문법 / 어색한 표현 / 문장 구조 / 논리 표현.
최대5개, 보통 필요한2~5개; 최소 개수 강제 없음(0/1개도 정상).
우선순위는 논리 왜곡·모순 → 의미 불분명 → 중요한 문법·호응 → 표현 개선.
취향을 오류로 단정하거나 학생의 입장/논지/문체를 바꾸지 않는다.

평가 항목별 진단 → **문장 다듬기 · N개** → 보완할 점 → 먼저 고칠 부분 → 확인 사항.
기본 접힘, 펼치면 원문/진단/수정 방향/선택적 수정 예시. 수정 예시가 없으면 빈 칸도 없다.
학생 화면에 내부 분류 key·UUID·offset을 노출하지 않는다. 0개와 미제공은 다르다.
현재 고정 미리보기 평가에는 문장 관측이 없으므로 ‘아직 제공되지 않았어요’로 표시한다.
새 원문/오류를 앱에서 생성하지 않는다. 항목 표시 검증은 합성 답안 fixture로만 수행했다.

## Current storage review — reuse first

검토 근거는 [배포 보안 기록](essay-lab-security-resolution.md)과 repository의
`20260928000100_student_essay_product.sql`, `20260928000300_essay_server_operations.sql`.
이번 작업에서 Production schema를 다시 조회하거나 변경하지 않았다.

| 기존 구조 | 재사용 가능 범위 | 부족한 부분 |
|---|---|---|
| essay_attempts | immutable body/body_sha256 | 없음; 반드시 draft가 아닌 이 원문 |
| essay_evaluations | attempt FK, contract/version, input_snapshot.answer_hash | 문장 관측 전용 결과 필드 없음 |
| essay_improvement_items | session root issue, category, 선택적 normalized key | 현재 category는 expression/structure/reasoning 등 상위8종; 학생용4종과 다름 |
| essay_improvement_progress | evaluation별 append-only title/explanation/next_action/priority, previous link | 문장 quote/span/subcategory/optional example 없음 |
| essay_evaluation_evidence | 공식 근거 mapping | 학생 원문 인용으로 전용하면 provenance 혼동 |

**결론: history/FK/권한은 재사용 가능, 필요한 구조화 정보를 그대로 저장하는 것은 PARTIAL.**
현재 finalize는 sentence field를 저장하지 않는다. 모든 improvement에 공식 evidence_ids를
요구하므로 문법 지적을 넣으려고 공식 근거를 꾸며내면 안 된다.
텍스트 column에 JSON을 숨기거나 issue_key에 유형/인용을 인코딩하지 않는다.

추천 최소 확장안(승인 전 구현 금지): 기존 improvement_progress에 nullable
`sentence_observation` 객체 하나를 추가하는 방안. category(4종), severity(priority class),
quote_start/end, exact quote, optional minimal_example만 담는 작은 고정 schema이며
diagnosis/action은 기존 explanation/next_action 재사용. 별도 sentence master/history table 없음.
기존 상위 category는 유지(grammar/expression→expression, structure→structure, logic→reasoning).
quote는 해당 attempt에서 검증된 짧은 인용에 한정하며 전체 답안 복제 금지.

이 방안은 새 column CHECK와 finalize validator/RPC adapter 검토가 필요하다.
순수 문법 지적의 공식 evidence 필수 여부는 별도 구분해야 한다. 공식 판단을 포함한
논리 지적은 기존 official mapping을 유지하고, 문장 관측만으로 충분한 경우에는
검증된 own-answer span을 근거로 허용하는 좁은 예외를 리뷰한다. 이번에는 SQL 작성/적용 없음.

같은 root issue를 보완할 점과 문장 다듬기에서 중복 비판하지 않고 공유 issue로 연결한다.
평가별 progress를 새로 기록한다. 재발/장기 묶음은 명시적 관측/버전 기반이며
student 영구 약점 자동 확정 금지. 기존 RLS/학습 삭제 cascade를 그대로 따른다.

## Source and validation boundary

UI의 `EssaySentenceReview`는 evaluation/attempt IDs, 각 항목의 Unicode code point
[start,end)와 quote를 보유한다. 별도로 전달받은 trusted result ID/immutable submitted
answer와 정확히 일치할 때만 표시한다. 현재 draft/다른 학생/공식 답안 fallback 없음.
UTF-16 인덱스가 아니다. 공백·맞춤법을 normalization하여 맞춘 것으로 간주하지 않는다.
불일치/범위 오류/필수 설명 누락을 숨기고 ID/span 중복을 제거한 뒤 우선순위로 최대5개.
동일 root issue의 의미 중복은 서버/평가 계약에서도 검사해야 한다.

UI 검사만으로 보안/정확성을 보장하지 않는다. 실제 adapter 연결 전에 서버가
자신의 evaluation→attempt FK에서 body/hash를 읽어 동일 검증을 반복해야 한다.
원문 존재 검증은 진단의 타당성이나 수정 예시의 입장 보존을 증명하지 않는다.
이 품질 항목은 독립 검토/별도 승인된 평가 실행에서 검증한다.

## Evaluation v1.2 proposal

[기존 v1.2](../tool/essay_lab/evidence/evaluation_contract_v1_2.json)에
DESIGN_ONLY 참조를 추가했다. 기존 output keys와 두 핵심 원칙은 유지한다.
[문장 출력 제안](../tool/essay_lab/evidence/sentence_feedback_v1_2.proposal.json)은
0..5 item,4유형,우선순위,원문위치,진단/행동/선택예시,동일 issue 통합,서버검증을 명시한다.
실행용 JSON Schema/adapter로 승인된 상태가 아니다. 기존 Pilot 출력은 수정하지 않았다.

## Validation and next gate

관련 Flutter27 tests/analyze PASS. 원문 위조/다른 evaluation·attempt/수정 draft/음수
offset/emoji code point/중복/5개 cap/우선순위/0개,360px100·200%,접힘/선택예시 미노출,
미제공 상태 및 위치를 검증했다. 합성 짧은 답안만 사용; 실제 학생 문장은 저장하지 않았다.
다음은 저장 확장 및 finalize 검토 → 승인된 test-only runtime 검증 → 별도 AI 실행 승인.
UI가 구현됐다는 이유로 persistence/AI/실제 학생 rollout을 PASS로 바꾸지 않는다.
