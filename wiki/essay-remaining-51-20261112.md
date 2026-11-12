# 잔여51 문항 처리 및 이화여대 인계 · 2026-11-12

**추가8 PUBLISHED / 미완료43 / 전체 확장 PARTIAL.** 한국항공 기존 DRAFT7과 동국 공식 정정 Q1을 공개했다. 대상10대학83시험221문항 중72시험에 속한178문항 공개이며, 공식 HOLD6 + PDF RIGHTS_HOLD15 + NOT READY22가 남는다. 한양·중앙·고려·인하, 기존 건국4·경희3·숙명6은 이 분모 밖에서 보존한다. 중앙대 과학11 HOLD도 유지한다. 이화여대는 별도 조사·로컬 후보이며 이221개에 섞지 않는다.

| 대학 | 대상 시험·문항 | 공개 시험·문항 | 잔여 |
|---|---:|---:|---|
| 한국항공대학교 | 6·12 | 4·7 | HOLD 5 / RIGHTS 0 / NOT READY 0 |
| 건국대학교 | 6·24 | 6·24 | HOLD 0 / RIGHTS 0 / NOT READY 0 |
| 경희대학교 | 4·23 | 3·7 | HOLD 0 / RIGHTS 0 / NOT READY 16 |
| 성균관대학교 | 5·15 | 0·0 | HOLD 0 / RIGHTS 15 / NOT READY 0 |
| 서강대학교 | 9·11 | 9·11 | HOLD 0 / RIGHTS 0 / NOT READY 0 |
| 숭실대학교 | 5·20 | 5·19 | HOLD 1 / RIGHTS 0 / NOT READY 0 |
| 숙명여자대학교 | 16·44 | 16·44 | HOLD 0 / RIGHTS 0 / NOT READY 0 |
| 동국대학교 | 7·21 | 7·21 | HOLD 0 / RIGHTS 0 / NOT READY 0 |
| 광운대학교 | 21·42 | 21·42 | HOLD 0 / RIGHTS 0 / NOT READY 0 |
| 서울여자대학교 | 4·9 | 1·3 | HOLD 0 / RIGHTS 0 / NOT READY 6 |

## 운영 적용과 보존

- [한국항공7 공개](essay-kau-public-20261112.md): 기존106행 내용 재사용,28상태변경,신규내용0. Migration `20261112085916_kau_7_existing_draft_public_release`, 공개확인18:01:02 KST, WEB `136d6c4a-6187-495e-bedd-7c6ee7f8951c` / 소스 `65ab29fc8e5f78f1400426974f8be6b240056896`.
- [동국 Q1 정정·공개](essay-dongguk-correction-20261112.md): 공식 수정 HWP를 정상 렌더한 자료13행,신규Registry0. Migration `20261112092154_dongguk_mock_q1_official_correction_public`, 적용18:25:52 / 공개확인18:26:54 KST, WEB `844798cb-e04b-4f2c-82ec-16fc45cc200a` / 소스 `7987a4639dcb18fbbf3a8a9e771a0bcaa8e68c5c`.
- 기존 내부 허용목록 두 함수만385→392→393으로 확대. 새 RPC0, Worker평가엔진·public RPC·ACL·RLS272개·Credit정책 불변. 적용 단계별21개 보존지문 동일. 최종221대상+이화기존3 Registry 메타데이터224행 모두 불변, 기존385개 공개catalog 정확히 보존. 운영 검수 답안 생성0.
- WEB 배포는 논술 경로·해당 공개 범위만, 비논술 정적 파일2189/2192개·API소스·Secrets·Preview·라우팅 보존. APP제품코드·기존설치본·릴리스병합·Store 변경0. SQL은 재실행하지 않는다.
- [최종 운영221문항 검증](../supabase/candidates/remaining_51_20261112/integrated-expansion-status.json), [보안Advisor 전후동일](../supabase/candidates/remaining_51_20261112/security-advisors.json): 기존5종222finding(56INFO/166WARN), 신규0. 기존 항목 개선은 범위 밖이며 JSON의 공식 remediation URL에 분리했다.

## 공식 불일치6

한국항공5: [현재 공식 기출](https://ibhak.kau.ac.kr/admission/html/rolling/previous.asp)의2024공학/2024이학/2026이학 PDF3개를 다시 받아 기존 SHA와 정확히 일치했다. [조회 증거](../supabase/candidates/remaining_51_20261112/kau-official-current.json). 따라서 새 정정 근거를 확보했다고 볼 수 없다. 문항별 전개부호·거리/정의역·배점 이슈는 아래51행 표에 기재했다. 소문항을 임의 분리하거나 Q2 전체 공개 범위를 결정하지 않는다.

숭실2024자연Q2: [현재 공식 게시물](https://admission.ssu.ac.kr/board/exam_view.asp?flag=&flag2=1&keyword=&number=124&page=1&page_no=1_2_7&srchoption=) PDF50쪽에서 물리39쪽 문제25점과44쪽 기준25+15=40점이 여전히 다르다. 원문을 렌더해 확인했다. 공식 배점 정정 필요. [SHA·물리페이지·동국 정정 근거](../supabase/candidates/remaining_51_20261112/official-corrections.json).

## RIGHTS_HOLD15

[성균관 기존 권리 근거](essay-sungkyunkwan-rights-hold-20261112.md)를 유지한다. 기존 Wiki/Git 및 확인 가능한 허락 기록에서 해당15문항의 해제 근거를 찾지 못했다. 2026수리형9개는 표지의 상업 사용·변형·발췌 제한이 실제 존재하고, 모의6개에도 기존 표시/조회 승인 대기가 있다. 법적 허용 여부를 새로 판정하지 않았다.

공식 링크 제공 대안은 현행 `studentPdfForExam`/APP `QuestionPdfAsset`의 승인 SHA·내부 Storage 기반 계약과 그대로 호환되지 않는다. 외부 원문 열기 adapter가 필요하며, 링크 제공만으로 Worker에 공식 자료를 전달하는 이용 권한까지 확보되는 것은 아니다. Owner 이용 허락 범위 확정 후 필요한 최소 변경을 검토한다. 정책/Storage업로드 변경0.

## NOT READY22와 추가 작업 범위

경희2022모의4는 공식 평가 기준 미확인. 기존 수학 구조를 재사용하되 기준 확보 전 생성·공개하지 않는다. 경희 의약학 과학12와 서울여 과학6은 공식 문제·기준 자료가 있지만 기존 과학 후보의 운영 연결이 없다. 서울여2025Q2는 기준 PDF에 포함된 공식 문제쪽을 사용해야 하므로 별도 student-PDF 매핑 검증도 필요하다.

재사용 가능: WEB `src/lib/essay-runtime/server/science.ts`의 `SCIENCE_REASONING` 검증·기존Provider transport·소유권/이미지해시 검사, `composition.ts`의 기존 부모claim·부분결과 비공개·원자적 저장·중복 과금 방지, 기존 답안/결과/재작성 UI. 현재 운영 import/활성화 없음, `ParentPersistence.ready`는 실제 매핑 검증 전 false. 단순 Math leaf로 등록해서 해결하지 않는다.

추가 범위: (1)18개 과학 문항별 과목/공식criterion/evidence 바인딩, (2)부모 결과 영속화·fencing·실패/재시도·재첨삭 계보 adapter, (3)시험 전체/부분 진입 및 WEB·APP 결과/PDF 계약, (4)격리 정상·실패·중복·권한·Credit 보존 회귀. 새 기반 평가엔진 개발을 시작하지 않는다. 현재 코드 기준 **약3–5개 개발일의 연결·회귀 작업 추정**이며 공식 기준 미확인4개 확보,운영 승인,Owner 품질검수 시간은 제외한다. 실제 DB/RPC 변경안이 필요한 부분은 구현 후 별도 범위를 제시해야 한다.

## 검증과 한계

한국항공 사전108/사후21/보존21,격리7문항×9흐름·비파괴원복,WEB449PASS/1SKIP,APP29PASS. 동국 사전14/사후3/보존21,격리1문항×9흐름·원복,WEB399PASS/1SKIP,APP4PASS. 타입/Next정적빌드/Functions빌드 PASS. 일반 authenticated 역할catalog 및 승인PDF범위 확인,HTTP200/비로그인PDF401. 이 수치는 서로 다른 실행이며 합산하지 않는다.

신규 테스트의 최초 fixture/type 오류는 수정 후 통과했고 운영 실패는 없었다. 이번 관련 테스트 최종 신규FAIL0. 전체 WEB suite는 이번에 재실행하지 않았으며 이전 서울여 작업의10FAIL+1예외는 [기존 분석](essay-swu-public-20261112.md#검증)에 남겼다. 실제 로그인 제출·결과·재첨삭,브라우저UI·iPhone/Android,실제AI품질은 이번8개에서 **NOT TESTED**. Provider호출0. Owner가 [178문항 통합 목록](essay-natural-owner-review-20261112.md)에서 품질 검수한다.

원복은 대학별 해시 가드 SQL로 신규 진입만 닫고 자료·사용자답안·결과·Credit를 보존한다. 동국 적용 후에는 한국항공 구버전 원복의 함수 해시 가드가 달라지므로 **역순(동국→항공)** 으로 닫거나 현재 허용목록에서 정확7개만 제거하는 원복을 다시 검증해야 한다. 드리프트가 있는 옛 SQL을 강행하지 않는다. 실제 운영 원복 미실행.

## Owner 판단이 남은 항목

한국항공5·숭실1의 공식 불일치 처리 근거,성균관15 이용 허락/표시 범위,과학18 운영 연결 범위,경희4 공식 기준 확보가 필요하다. 이화여대는 [원본·과거 이력·63로컬package 보고](essay-ewha-source-audit-20261112.md) 이후 별도 운영 승인 대상이다. 승인되지 않은 DRAFT나 공개는 하지 않았다.

## 초기 잔여51 문항별 확정 상태

Registry ID는 Source Registry key이며 UUID는 기존 `essay_questions.id`다. 모든 연도는 Registry의 학년도이며 자료의 달력 시행연도와 혼동하지 않는다. [기계 판독 전체표](../supabase/candidates/remaining_51_20261112/remaining-51-status.json).

| 대학·학년도·계열·문항 | 시험 ID | Registry ID | 문항 UUID | 이전→현재 | 원인·해결 조건 |
|---|---|---|---|---|---|
| 한국항공대학교 2024 공학계열 문제 1 | `00355b1e-744d-553c-bba3-2483d4d57d42` | `source:kau-2024-admission-engineering:q1` | `74e16370-a1be-57f9-b6c7-b2e035bfbb06` | HOLD → HOLD | 두 로그 합을 정리하는 중간 줄과 이후 곱 형태 사이 부호 표기 차이. Codex 정정 없이 원문 보존. 현재 공식 첨부 PDF SHA가 기존 자료와 동일. 대학 공식 정정 또는 Owner의 정확한 처리 범위 결정 필요. 원문 수정·소문항 임의 분리 없음. |
| 한국항공대학교 2024 공학계열 문제 2 | `00355b1e-744d-553c-bba3-2483d4d57d42` | `source:kau-2024-admission-engineering:q2` | `f0ae1ea0-6c50-5b7e-b42b-35f436849c6f` | HOLD → HOLD | 문제의 거리·정의역과 공식 예시풀이의 부호 있는 차이/최댓값 결론이 충돌할 가능성. 공식 답을 수정하지 않음. 현재 공식 첨부 PDF SHA가 기존 자료와 동일. 대학 공식 정정 또는 Owner의 정확한 처리 범위 결정 필요. 원문 수정·소문항 임의 분리 없음. |
| 한국항공대학교 2024 이학계열 문제 1 | `51d7f36d-a011-5279-8c5d-f731b2900af3` | `source:kau-2024-admission-science:q1` | `2476c8dc-a8e4-599a-8cf2-1ffdddbb6f06` | HOLD → HOLD | 1-3(1): 기준 2+2+2 / 풀이 1.5+1.5+3. 1-3(3): 기준 2+1+2 / 풀이 1+1+3. 1-3 제목17점과 세부합16점. 1-4(3) 기준5점/풀이 과정2+답3. 양쪽 원문 보존. 현재 공식 첨부 PDF SHA가 기존 자료와 동일. 대학 공식 정정 또는 Owner의 정확한 처리 범위 결정 필요. 원문 수정·소문항 임의 분리 없음. |
| 한국항공대학교 2024 이학계열 문제 2 | `51d7f36d-a011-5279-8c5d-f731b2900af3` | `source:kau-2024-admission-science:q2` | `ed096a20-52a7-5f27-a71b-4c7c2401cdc9` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 한국항공대학교 2025 공학계열 문제 1 | `3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af` | `source:kau-2025-admission-engineering:q1` | `ff6226fc-32ac-5903-ab0f-b1560803efbb` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 한국항공대학교 2025 공학계열 문제 2 | `3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af` | `source:kau-2025-admission-engineering:q2` | `ebd76ca2-dbb4-5c0f-a203-4c77650e8a77` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 한국항공대학교 2025 이학계열 문제 1 | `85a8468d-2141-52b1-9d70-3bcf6f340f8e` | `source:kau-2025-admission-science:q1` | `8744f2ad-02c4-51d4-83de-6d5ab245cec5` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 한국항공대학교 2025 이학계열 문제 2 | `85a8468d-2141-52b1-9d70-3bcf6f340f8e` | `source:kau-2025-admission-science:q2` | `fccb2d75-d4e6-54ec-b0fe-f3eced268b36` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 한국항공대학교 2026 이학계열 문제 1 | `3e312310-9393-5d7d-90d3-731aee13c360` | `source:kau-2026-admission-science:q1` | `8c11754b-d3af-56bf-9b66-d72092468f70` | HOLD → HOLD | 1-2 풀이 계산 마지막 음수와 최종 답 줄 양수의 부호 불일치. 1-1(1) 모든 빈칸 미기재: 기준표3점/예시풀이0점. 원문 보존. 현재 공식 첨부 PDF SHA가 기존 자료와 동일. 대학 공식 정정 또는 Owner의 정확한 처리 범위 결정 필요. 원문 수정·소문항 임의 분리 없음. |
| 한국항공대학교 2026 이학계열 문제 2 | `3e312310-9393-5d7d-90d3-731aee13c360` | `source:kau-2026-admission-science:q2` | `48512d94-959c-5a94-b985-7e1bd005c6b7` | HOLD → HOLD | 주 풀이의 이차식 일차항 -17m, 이후 근/다른 풀이의 +17m 표기 차이. 원문 보존. 현재 공식 첨부 PDF SHA가 기존 자료와 동일. 대학 공식 정정 또는 Owner의 정확한 처리 범위 결정 필요. 원문 수정·소문항 임의 분리 없음. |
| 한국항공대학교 2026 공학계열 문제 1 | `6815943a-42c1-5eae-b711-449ac403b9fb` | `source:kau-2026-admission-engineering:q1` | `d3909209-b5ee-50ce-b5cb-5cbbb8e0a65a` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 한국항공대학교 2026 공학계열 문제 2 | `6815943a-42c1-5eae-b711-449ac403b9fb` | `source:kau-2026-admission-engineering:q2` | `6eaec5d3-4786-55a2-8dc6-a457edd5b16b` | DRAFT → PUBLISHED | 기존106행 DRAFT 및 공개 허용 범위 미연결 → 기존 자료 재사용으로 해소 공개 완료; 실제 AI 품질은 Owner 검수 |
| 경희대학교 2022 자연계 문제 1 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:1` | `f7733560-15d9-530e-aaae-6d04da444d51` | NOT READY → NOT READY | 2022 모의 자연 공식 문제는 있으나 문항별 공식 평가 기준 미확인. 공식 기준·배점 확보 후 기존 Math package·Worker·PDF·시험 진입 검증. 예시 답안에서 기준을 생성하지 않음. |
| 경희대학교 2022 자연계 문제 2 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:2` | `f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d` | NOT READY → NOT READY | 2022 모의 자연 공식 문제는 있으나 문항별 공식 평가 기준 미확인. 공식 기준·배점 확보 후 기존 Math package·Worker·PDF·시험 진입 검증. 예시 답안에서 기준을 생성하지 않음. |
| 경희대학교 2022 자연계 문제 3 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:3` | `8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5` | NOT READY → NOT READY | 2022 모의 자연 공식 문제는 있으나 문항별 공식 평가 기준 미확인. 공식 기준·배점 확보 후 기존 Math package·Worker·PDF·시험 진입 검증. 예시 답안에서 기준을 생성하지 않음. |
| 경희대학교 2022 자연계 문제 4 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:4` | `c6b54603-e483-5a5d-b4c3-d4044b40a0d2` | NOT READY → NOT READY | 2022 모의 자연 공식 문제는 있으나 문항별 공식 평가 기준 미확인. 공식 기준·배점 확보 후 기존 Math package·Worker·PDF·시험 진입 검증. 예시 답안에서 기준을 생성하지 않음. |
| 경희대학교 2026 의·약학계 논제 물리 Ⅲ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `source:kyunghee-2026-admission-medical:q물리 Ⅲ` | `7873aab1-1245-52c4-919e-0cc2888e70bd` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2026 의·약학계 논제 물리 Ⅳ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `source:kyunghee-2026-admission-medical:q물리 Ⅳ` | `dc618430-fc97-5868-ad1d-cc168ed0cf13` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2026 의·약학계 논제 화학 Ⅲ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `source:kyunghee-2026-admission-medical:q화학 Ⅲ` | `a3d0ca59-1ac8-534c-b30a-74da00810686` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2026 의·약학계 논제 화학 Ⅳ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `source:kyunghee-2026-admission-medical:q화학 Ⅳ` | `24a038de-b10a-5f62-af31-4214d12c093a` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2026 의·약학계 논제 생명과학 Ⅲ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `source:kyunghee-2026-admission-medical:q생명과학 Ⅲ` | `f67348c2-6c17-550d-a806-64bcfde64af9` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2026 의·약학계 논제 생명과학 Ⅳ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `source:kyunghee-2026-admission-medical:q생명과학 Ⅳ` | `213cc62c-629a-580b-b83c-9846024db47d` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2027 의·약학계 논제 물리 Ⅲ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `source:kyunghee-2027-mock-medical:q물리 Ⅲ` | `ae3aa413-1fdf-5274-a0a6-4c4f59c5af8a` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2027 의·약학계 논제 물리 Ⅳ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `source:kyunghee-2027-mock-medical:q물리 Ⅳ` | `2eece199-d608-5e4d-90f3-8b188543b851` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2027 의·약학계 논제 화학 Ⅲ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `source:kyunghee-2027-mock-medical:q화학 Ⅲ` | `04321068-ec5c-528d-b211-b5c6d4e44894` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2027 의·약학계 논제 화학 Ⅳ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `source:kyunghee-2027-mock-medical:q화학 Ⅳ` | `22f61110-4d80-5faa-be59-fab0855fa0cf` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2027 의·약학계 논제 생명과학 Ⅲ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `source:kyunghee-2027-mock-medical:q생명과학 Ⅲ` | `fed0bf52-4242-52e9-9a1e-6a35d8f309ca` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 경희대학교 2027 의·약학계 논제 생명과학 Ⅳ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `source:kyunghee-2027-mock-medical:q생명과학 Ⅳ` | `fc09f3ae-3aa8-501d-8a82-05f8449b2140` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 성균관대학교 2023 자연계 문제 1 | `ed5bcc6c-ee78-527c-94bc-c913414c846c` | `source:dc5b3e812a60ed1766af528ef74ab3d70c6202097785d0199a714629306bbc9f:1` | `1ce6e75d-2e6e-543c-b6a4-e1c41b95b0bb` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2023 자연계 문제 2 | `ed5bcc6c-ee78-527c-94bc-c913414c846c` | `source:dc5b3e812a60ed1766af528ef74ab3d70c6202097785d0199a714629306bbc9f:2` | `40cb9125-a195-5540-a650-60f0cc6f7518` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2023 자연계 문제 3 | `ed5bcc6c-ee78-527c-94bc-c913414c846c` | `source:dc5b3e812a60ed1766af528ef74ab3d70c6202097785d0199a714629306bbc9f:3` | `d0e47369-676a-5347-94f3-bb7a2dcd6814` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 1 | `17a2b4c9-6070-51b4-8f96-5d347335b5d2` | `source:skku-2026-admission-sk05:q1` | `8121b47e-4a8c-5767-b90c-90bde3327d74` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 2 | `17a2b4c9-6070-51b4-8f96-5d347335b5d2` | `source:skku-2026-admission-sk05:q2` | `e8deaca8-512a-56d8-82fa-fa11993883bc` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 3 | `17a2b4c9-6070-51b4-8f96-5d347335b5d2` | `source:skku-2026-admission-sk05:q3` | `b36ee18b-15cd-53bf-ba79-62bccf56510e` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 1 | `cfced8fe-2111-5ee2-9b81-b19dd1933d54` | `source:skku-2026-admission-sk03:q1` | `0ee85c19-7d9f-5186-8ff7-6f9353f21097` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 2 | `cfced8fe-2111-5ee2-9b81-b19dd1933d54` | `source:skku-2026-admission-sk03:q2` | `8633896c-7611-5eeb-ae69-ab2672f1d867` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 3 | `cfced8fe-2111-5ee2-9b81-b19dd1933d54` | `source:skku-2026-admission-sk03:q3` | `337b7c8a-1c15-5f67-b542-f82877aad6df` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 1 | `fa908d5a-f3f9-5565-b11a-8fcaf8d0bc78` | `source:skku-2026-admission-sk01:q1` | `dcd032b7-e2e8-52d7-b3fe-ccb55e572a96` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 2 | `fa908d5a-f3f9-5565-b11a-8fcaf8d0bc78` | `source:skku-2026-admission-sk01:q2` | `8215d793-884f-5392-ba34-39b2c934c7db` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2026 수리형 문제 3 | `fa908d5a-f3f9-5565-b11a-8fcaf8d0bc78` | `source:skku-2026-admission-sk01:q3` | `1bb7bbff-fdf4-5205-b779-ccb29e756479` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2027 수리형 문제 1 | `f4674c42-defb-57df-9356-611138d2be85` | `source:skku-2027-mock-sk12:q1` | `9ea7243c-f209-5341-a334-347cda833409` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2027 수리형 문제 2 | `f4674c42-defb-57df-9356-611138d2be85` | `source:skku-2027-mock-sk12:q2` | `c5fc0bc9-02a5-5298-904d-33c9b3c405eb` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 성균관대학교 2027 수리형 문제 3 | `f4674c42-defb-57df-9356-611138d2be85` | `source:skku-2027-mock-sk12:q3` | `fda4849f-0f49-5553-99bb-1c78985ab5cb` | RIGHTS_HOLD → RIGHTS_HOLD | 기존 RIGHTS_HOLD 유지. 2026 수리형 표지에 상업 사용·변형·발췌 제한; 모의 포함 이용 허락/표시 승인 미확인. Owner 이용 허락 근거·범위 확정, 정확 PDF 접근 승인 후 자료·공개 범위 검증. 외부 링크만으로 Worker 처리 권한까지 해소되지 않음. |
| 숭실대학교 2024 자연계열 문제 2 | `fb89bcfe-ed40-5bc2-8a91-db9e935a5d43` | `source:soongsil-2024-admission-natural:q2` | `815bc344-cdbb-5b7f-82c1-dc528de46f51` | HOLD → HOLD | 2024 자연 Q2 문제25점과 공식 평가기준 합계40점(25+15) 불일치. 현재 공식 PDF도 동일. 대학의 공식 배점 정정 필요. 임의 점수 선택·조정하지 않음. |
| 동국대학교 2026 자연계열 문제 1 | `324dbf82-b4bc-5607-977b-2cf512812212` | `source:dongguk-2026-mock-natural:q1` | `49ea9aaa-1c46-51e7-b148-a03aef20ae4e` | HOLD → PUBLISHED | 기존 Q1 해설의 타원식·최댓값이 공식 수정 HWP와 달랐음 → 공식 수정본 정상 PDF 렌더로 해소 13행 보완·기존 Registry/문제 PDF 유지·공개 완료 |
| 서울여자대학교 2023 자연계열 문제 1 | `a16f832e-20b1-5ee3-b3dc-9e0973e7483c` | `source:swu-2023-admission-natural-pm:q1` | `dd144dfa-d36a-5393-a966-f4968b773485` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 서울여자대학교 2023 자연계열 문제 2 | `a16f832e-20b1-5ee3-b3dc-9e0973e7483c` | `source:swu-2023-admission-natural-pm:q2` | `b8a5061c-b06d-57c7-b2e1-8e41d248eb17` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 서울여자대학교 2025 자연계열 문제 1 | `c7ffdcd0-54fe-5c84-9a12-3df64985d2bc` | `source:swu-2025-admission-natural-pm:q1` | `137e2e86-6d84-5e88-a276-b0479e435556` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 서울여자대학교 2025 자연계열 문제 2 | `c7ffdcd0-54fe-5c84-9a12-3df64985d2bc` | `source:swu-2025-admission-natural-pm:q2` | `44610023-7a33-50e6-9924-e06a57f78a84` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 서울여자대학교 2024 자연계열 문제 1 | `ebb3dead-13e3-5e19-993f-0a7459431aec` | `source:swu-2024-admission-natural-pm:q1` | `8ba18b30-2a9a-5eba-a8ff-f3544ce67134` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |
| 서울여자대학교 2024 자연계열 문제 2 | `ebb3dead-13e3-5e19-993f-0a7459431aec` | `source:swu-2024-admission-natural-pm:q2` | `9bb9c3b5-9a18-52b5-a8fb-befbe86573c5` | NOT READY → NOT READY | 공식 문제·출제의도·평가자료는 있으나 SCIENCE_REASONING 검수된 바인딩과 운영 결과 저장·재첨삭 연결 미구현. 기존 과학 후보/Provider transport/소유권·원자적 부모 결과 저장/재작성 구조 재사용. 문항별 과목·근거 바인딩 및 WEB·APP 결과 계약 구현·검증 필요. Math로 우회 금지. |

## Git 인계

APP 잔여 공개 준비 `5d6aa38a168bddfd47944db0318d3c691b8a10d2`(항공), `c2bf8df`(동국); 이화 로컬 조사·package 구현 `3b1add1ce4407273bbdfd5f0ca493b1423c51a88`. WEB 운영 source `7987a4639dcb18fbbf3a8a9e771a0bcaa8e68c5c`. 이 문서/운영 영수증의 최종 commit은 완료 보고와 `git log -1`에서 확인한다. 이화와잔여51은후보디렉터리/구현커밋이분리되어있고브랜치병합0.

WEB 최종 문서 HEAD: `aaeb700b5c40cd329faa444ac7feaa2c2ea59043`. 문서 인계 후 재배포0, 실제 운영source는 위7987a46이다.
