# WEB 평가 결과·재작성 표시 개선 — 2026-10-30

## 범위 및 기존 결정

Owner WEB 지시의 표시 계층만 수정. [기존 WEB 결과 정책](essay-web-studio-ui-20261026.md), [성장 비교·별칭 정책](essay-growth-history-ui-20261026.md), [장기 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 계승한다. APP Round29 변경 및 Claude Analytics 브랜치는 수정하지 않았다. 운영 배포는 하지 않았다.

보존 검토 7항: 1) 신규 학습 사실/발생시각 생성 없음. 2) 저장 결과/기준 ID와 공식 원문 유지. 3) UPDATE/삭제 없음. 4) 기존 사용자 소유 조회와 identity 유지. 5) Learning 표시이며 Decision/Outcome 추론 없음. 6) 수집·권한·동의·보유기간 확장 없음. 7) 표시 별칭/카드만 파생하며 원장에 저장하지 않음.

## 원인 및 변경

WEB `src/lib/my/exam-history.ts:examReports`는 같은 `dimensions.explanation`을 `rubric.feedback`와 `evidenceLabels`에 중복 전달한다. `HumanEvaluationReport`는 전자를 접힌 details 내부에만, 후자를 독립 평가 근거 섹션에 출력했다. 따라서 항목별 펼침 여부에 따라 본문이 없는 것처럼 보이거나 두 번 보였다. 이번 증거는 실제 코드와 Owner 화면 대조이며 신규 운영 DB/API 조회는 하지 않았다. 특정 계정의 현재 응답을 재확인했다고 주장하지 않는다.

- `src/components/my/evaluation-report.tsx`: `CriterionResults`가 평가 단계/설명을 기본 표시하고 원문은 상세보기로 보존. 전체 기준명이 정확히 일치하는 근거만 연결, 같은 설명은 한 번만 표시. 별도 내용·미매칭 근거는 보존. 양쪽 모두 설명 없으면 명시적 미제공 안내. 문항별 보완점은 기존 피드백 영역 유지; criterion별 연결 근거 없는 보완점을 임의 배정하지 않는다.
- `EvaluationComparison`: 항목명→최초/재첨삭 단계→변화→설명→근거→해당 항목 그래프 순. 기존 `compareReports`/등급 계산 그대로 사용.
- `src/lib/my/criterion-display.ts`: `criterionDisplayName`은 기존 검수 별칭 맵/규칙 재사용. 검수대기·미확정이면 잘리지 않은 원문 사용. `criterionEvidence`는 전체 label 접두어 일치만 허용. 기준 ID/정의 변경 없음.
- `src/components/my/growth-bars.tsx`: `hideHeading` 선택 옵션으로 비교 카드 안에서 중복 제목/원문 상세만 숨김. 다른 성장 화면 기본 동작 유지.
- `src/components/my/evaluation-refinement.css`: 학생 문장/평가/수정 방향 구분, 제목17px bold·본문16px, 우선순위 오렌지/재작성 블루/강점 녹색/보완 붉은색의 연한 배경, 모바일 비교 수직배치/탭 줄바꿈. 기존 화면 CSS 우선순위를 고려한 선택자 사용.

## 검증

- TypeScript PASS, 변경 파일 ESLint PASS, Next Production 정적 build PASS (Node22 직접 실행).
- 관련 3파일 9검사 PASS. 추가 오프라인 fixture 생성 검사1 PASS. 중복 제거·별도 근거 보존·누락 안내·안전 별칭·동일/비교불가 단계 및 기존 권한 CTA/문항 펼침 검사 포함.
- 전체 WEB: **1373 PASS / 18 FAIL / 4 SKIP**, 추가 1개 test-file 로딩 실패. 수정 전 HEAD를 임시 폴더로 export해 동일 실행: **1368 PASS / 18 FAIL / 4 SKIP**, 같은 로딩 실패. 기존 실패는 catalog 수치/목표 UI/Math fixture 등이며 이번 범위 밖. 전체 PASS 아님.
- Headless Chrome, 합성 저장결과 offline fixture 320/375/390/768/1024px: document width=viewport, 카드 가로 넘침0. 320px 상세보기 클릭 열기/닫기 PASS. 390px 전체 스크린샷 시각 검토 완료. 운영 로그인 화면·모바일 실기기 검수 아님. PDF/TTS 실출력 재검증 안 함.
- 이미지 `/tmp/legendstudy-web-refinement-{320,375,390,768,1024}.png`. 재생성은 `REFINEMENT_PREVIEW=/tmp/legendstudy-refinement.html node node_modules/vitest/vitest.mjs run src/components/my/refinement-preview.test.tsx`; 실제 사용자 데이터/Provider 없이 생성.

## Git·운영·복구

WEB `/Users/woojinchang/development/legendstudy-release-20261024`, branch `codex/web-app-release-20261024`, commit `0ae9e2f0153807b6379a67c6f22b6a0b94d8d694`. Commit/Push 및 LOCAL=REMOTE 확인. 기준 `2f838c29fa25c38c399a6a43f9d567dd89053ffc`. 기존 checkout clean 확인 후 이 7파일만 commit. 신규 배포 없음. DB/Worker/Provider/Credit/History 변경0. APP 기존 `.fvmrc` 보존.

롤백은 WEB 변경 commit을 revert한 별도 commit으로 가능; DB/원장 rollback 없음. 미완료: 불명확 기준의 의미별 별칭 검수, 기존 전체 테스트 실패 정리, 실제 계정/실기기 및 운영 반영 후 확인. 원문 손상·순서 오류를 UI가 추론으로 고치지 않는다.

## Pre-release follow-up 2026-10-30

[Source PDF audit, separate candidate, full test failure analysis and display contract](pre-release-stabilization-20261030.md). Prior execution results above remain historical evidence. No Production deployment in this follow-up.

## 후속 학생 표시 정책

[학생 중심 첨삭 결과 정책·구현·검증·미완료](student-centered-essay-feedback-20261031.md)에 따라 학생 결과의 공식 원문 기본 노출을 대체한다. 본 문서의 내부 자료·정정 후보·기존 시행 기록은 보존한다.
