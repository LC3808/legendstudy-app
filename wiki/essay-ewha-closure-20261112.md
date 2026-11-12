# 이화여대 연결 작업 종료 및 자연계열 잔여43 · 2026-11-12

**이화29시험87문항 연결 DONE / 신규 자료 연결 CLOSED.** Owner 종료 확인을 반영했다. 실제AI 품질은 Owner 통합검수 대상으로 유지한다. 이번 종료 작업 운영쓰기0/Provider0/추가배포0.

## 중복 없는 공개 집계

| 구분 | 시험 | 문항 | Math | Essay |
|---|---:|---:|---:|---:|
| 기존 수시 공식 자료 |21|63|27|36|
| 신규 모의 자료 |8|24|12|12|
| 이화 합계 |29|87|39|48|

두 문항 ID 집합 교집합0, 합집합87. 운영 Registry ID·source key87개와 공개 API87개가 정확히 일치한다. 기존 운영3문항은 모의24에 포함하며 추가로 더하지 않는다. 전체 확장308 = 기존자연221 + 이화87; 공개265 = 자연178 + 이화87; 잔여43은 전부 기존자연계열이다.

## 기존 운영3문항의 ID 및 공개 상태

시험 `c15360f1-571e-5fa4-8314-dde3022f9594` / 2024 모의 자연Ⅰ.

| 문항 | 기존 질문 UUID | Registry ID 유지 | Math 공개 | 공개 catalog |
|---|---|---|---|---|
| Q1 | `f32f7b67-6fcf-52ab-b6b7-06074712c702` | PASS | 공개 | 노출 |
| Q2 | `4a432fdf-d601-5230-b045-d2123c614773` | PASS | 공개 | 노출 |
| Q3 | `e7362b80-3f05-5d84-8768-826ab7136233` | PASS | 공개 | 노출 |

레거시 `essay_questions.is_published=false`, `essay_exams.is_active=false`는 기존값을 보존한다. 기존 서비스는 Math release_catalog와 WEB/APP 허용목록으로 공개하므로, 위 플래그만 보고 미공개로 분류하지 않는다. 공개를 위해 레거시 값을 임의 수정하지 않았다.

[종료 읽기 검증 원본](../supabase/candidates/ewha_mock_public_20261112/closure-readonly.json) · [실제 적용·검증·원복](essay-ewha-mock-public-20261112.md) · [Owner265 통합목록](../supabase/candidates/ewha_mock_public_20261112/owner-integrated-review.json).

## 자연·수리 잔여43의 구분

| 대학 | 수 | 미완료 유형 | 해결 작업 |
|---|---:|---|---|
| 한국항공대 |5|공식 자료 내 표기 불일치 HOLD|해당5문항의 처리 범위 결정 후 기존 Math 연결 재사용|
| 숭실대 |1|2024자연Q2 공식 배점 불일치 HOLD|정확한 배점 처리 근거 확정 후 해당문항 연결|
| 경희대 |12|과학 Worker 운영 계약 미구현|과목·문항별 근거 바인딩, 결과 저장, 재작성/재첨삭 및 WEB·APP 계약 구현·검증|
| 서울여대 |6|과학 Worker 운영 계약 미구현|동일 과학 계약 연결. Math로 임의 우회하지 않음|
| 경희대 |4|2022모의 자연 평가 요소 연결 미완료|기존 검사에서 공식 기준 구간 미확인. 원문 설명의 충분성·서비스 요소 매핑 후 package 검증 필요. 자료 자체의 부재로 단정하지 않음|
| 성균관대 |15|Owner HOLD — 기술 미구현과 별도|모의6/2026수리9의 기존 Owner 결정을 유지. 기술 후보 보존; 이번 종료 작업에서 재조사·공개하지 않음|

과학18·경희모의4는 기술/평가자료 연결 미완료, 공식불일치6·Owner HOLD15는 결정 대기다. 중앙대 과학11은 기존308 분모 밖 HOLD로 유지한다. 이미 공개된 대학은 재작업하지 않는다.

### 잔여43 문항별 목록

| 대학 | 학년도·계열·문항 | 시험 ID | 문항 ID | 미완료 분류 |
|---|---|---|---|---|
| 한국항공대학교 | 2024 공학계열 문제 1 | `00355b1e-744d-553c-bba3-2483d4d57d42` | `74e16370-a1be-57f9-b6c7-b2e035bfbb06` | OFFICIAL_CONFLICT |
| 한국항공대학교 | 2024 공학계열 문제 2 | `00355b1e-744d-553c-bba3-2483d4d57d42` | `f0ae1ea0-6c50-5b7e-b42b-35f436849c6f` | OFFICIAL_CONFLICT |
| 한국항공대학교 | 2024 이학계열 문제 1 | `51d7f36d-a011-5279-8c5d-f731b2900af3` | `2476c8dc-a8e4-599a-8cf2-1ffdddbb6f06` | OFFICIAL_CONFLICT |
| 한국항공대학교 | 2026 이학계열 문제 1 | `3e312310-9393-5d7d-90d3-731aee13c360` | `8c11754b-d3af-56bf-9b66-d72092468f70` | OFFICIAL_CONFLICT |
| 한국항공대학교 | 2026 이학계열 문제 2 | `3e312310-9393-5d7d-90d3-731aee13c360` | `48512d94-959c-5a94-b985-7e1bd005c6b7` | OFFICIAL_CONFLICT |
| 경희대학교 | 2022 자연계 문제 1 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `f7733560-15d9-530e-aaae-6d04da444d51` | MISSING_OFFICIAL_RUBRIC |
| 경희대학교 | 2022 자연계 문제 2 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d` | MISSING_OFFICIAL_RUBRIC |
| 경희대학교 | 2022 자연계 문제 3 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5` | MISSING_OFFICIAL_RUBRIC |
| 경희대학교 | 2022 자연계 문제 4 | `c47c6ed4-a3fc-5758-b773-9d7ce4762725` | `c6b54603-e483-5a5d-b4c3-d4044b40a0d2` | MISSING_OFFICIAL_RUBRIC |
| 경희대학교 | 2026 의·약학계 논제 물리 Ⅲ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `7873aab1-1245-52c4-919e-0cc2888e70bd` | SCIENCE_RUNTIME |
| 경희대학교 | 2026 의·약학계 논제 물리 Ⅳ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `dc618430-fc97-5868-ad1d-cc168ed0cf13` | SCIENCE_RUNTIME |
| 경희대학교 | 2026 의·약학계 논제 화학 Ⅲ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `a3d0ca59-1ac8-534c-b30a-74da00810686` | SCIENCE_RUNTIME |
| 경희대학교 | 2026 의·약학계 논제 화학 Ⅳ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `24a038de-b10a-5f62-af31-4214d12c093a` | SCIENCE_RUNTIME |
| 경희대학교 | 2026 의·약학계 논제 생명과학 Ⅲ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `f67348c2-6c17-550d-a806-64bcfde64af9` | SCIENCE_RUNTIME |
| 경희대학교 | 2026 의·약학계 논제 생명과학 Ⅳ | `0b5b9aea-e23f-5644-84df-5e5f6f5a2782` | `213cc62c-629a-580b-b83c-9846024db47d` | SCIENCE_RUNTIME |
| 경희대학교 | 2027 의·약학계 논제 물리 Ⅲ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `ae3aa413-1fdf-5274-a0a6-4c4f59c5af8a` | SCIENCE_RUNTIME |
| 경희대학교 | 2027 의·약학계 논제 물리 Ⅳ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `2eece199-d608-5e4d-90f3-8b188543b851` | SCIENCE_RUNTIME |
| 경희대학교 | 2027 의·약학계 논제 화학 Ⅲ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `04321068-ec5c-528d-b211-b5c6d4e44894` | SCIENCE_RUNTIME |
| 경희대학교 | 2027 의·약학계 논제 화학 Ⅳ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `22f61110-4d80-5faa-be59-fab0855fa0cf` | SCIENCE_RUNTIME |
| 경희대학교 | 2027 의·약학계 논제 생명과학 Ⅲ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `fed0bf52-4242-52e9-9a1e-6a35d8f309ca` | SCIENCE_RUNTIME |
| 경희대학교 | 2027 의·약학계 논제 생명과학 Ⅳ | `c71cb668-d9c6-52a9-b771-c48c3efd7dc3` | `fc09f3ae-3aa8-501d-8a82-05f8449b2140` | SCIENCE_RUNTIME |
| 성균관대학교 | 2023 자연계 문제 1 | `ed5bcc6c-ee78-527c-94bc-c913414c846c` | `1ce6e75d-2e6e-543c-b6a4-e1c41b95b0bb` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2023 자연계 문제 2 | `ed5bcc6c-ee78-527c-94bc-c913414c846c` | `40cb9125-a195-5540-a650-60f0cc6f7518` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2023 자연계 문제 3 | `ed5bcc6c-ee78-527c-94bc-c913414c846c` | `d0e47369-676a-5347-94f3-bb7a2dcd6814` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 1 | `17a2b4c9-6070-51b4-8f96-5d347335b5d2` | `8121b47e-4a8c-5767-b90c-90bde3327d74` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 2 | `17a2b4c9-6070-51b4-8f96-5d347335b5d2` | `e8deaca8-512a-56d8-82fa-fa11993883bc` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 3 | `17a2b4c9-6070-51b4-8f96-5d347335b5d2` | `b36ee18b-15cd-53bf-ba79-62bccf56510e` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 1 | `cfced8fe-2111-5ee2-9b81-b19dd1933d54` | `0ee85c19-7d9f-5186-8ff7-6f9353f21097` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 2 | `cfced8fe-2111-5ee2-9b81-b19dd1933d54` | `8633896c-7611-5eeb-ae69-ab2672f1d867` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 3 | `cfced8fe-2111-5ee2-9b81-b19dd1933d54` | `337b7c8a-1c15-5f67-b542-f82877aad6df` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 1 | `fa908d5a-f3f9-5565-b11a-8fcaf8d0bc78` | `dcd032b7-e2e8-52d7-b3fe-ccb55e572a96` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 2 | `fa908d5a-f3f9-5565-b11a-8fcaf8d0bc78` | `8215d793-884f-5392-ba34-39b2c934c7db` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2026 수리형 문제 3 | `fa908d5a-f3f9-5565-b11a-8fcaf8d0bc78` | `1bb7bbff-fdf4-5205-b779-ccb29e756479` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2027 수리형 문제 1 | `f4674c42-defb-57df-9356-611138d2be85` | `9ea7243c-f209-5341-a334-347cda833409` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2027 수리형 문제 2 | `f4674c42-defb-57df-9356-611138d2be85` | `c5fc0bc9-02a5-5298-904d-33c9b3c405eb` | Owner HOLD(기술 사유와 별도) |
| 성균관대학교 | 2027 수리형 문제 3 | `f4674c42-defb-57df-9356-611138d2be85` | `fda4849f-0f49-5553-99bb-1c78985ab5cb` | Owner HOLD(기술 사유와 별도) |
| 숭실대학교 | 2024 자연계열 문제 2 | `fb89bcfe-ed40-5bc2-8a91-db9e935a5d43` | `815bc344-cdbb-5b7f-82c1-dc528de46f51` | OFFICIAL_CONFLICT |
| 서울여자대학교 | 2023 자연계열 문제 1 | `a16f832e-20b1-5ee3-b3dc-9e0973e7483c` | `dd144dfa-d36a-5393-a966-f4968b773485` | SCIENCE_RUNTIME |
| 서울여자대학교 | 2023 자연계열 문제 2 | `a16f832e-20b1-5ee3-b3dc-9e0973e7483c` | `b8a5061c-b06d-57c7-b2e1-8e41d248eb17` | SCIENCE_RUNTIME |
| 서울여자대학교 | 2025 자연계열 문제 1 | `c7ffdcd0-54fe-5c84-9a12-3df64985d2bc` | `137e2e86-6d84-5e88-a276-b0479e435556` | SCIENCE_RUNTIME |
| 서울여자대학교 | 2025 자연계열 문제 2 | `c7ffdcd0-54fe-5c84-9a12-3df64985d2bc` | `44610023-7a33-50e6-9924-e06a57f78a84` | SCIENCE_RUNTIME |
| 서울여자대학교 | 2024 자연계열 문제 1 | `ebb3dead-13e3-5e19-993f-0a7459431aec` | `8ba18b30-2a9a-5eba-a8ff-f3544ce67134` | SCIENCE_RUNTIME |
| 서울여자대학교 | 2024 자연계열 문제 2 | `ebb3dead-13e3-5e19-993f-0a7459431aec` | `9bb9c3b5-9a18-52b5-a8fb-befbe86573c5` | SCIENCE_RUNTIME |

## 보존·검수·Git

종료 재검증은 SELECT/공개GET만 수행했다. 기존 원본·Registry ID·사용자 답안·첨삭 기록·권한·Credit·결제 정책 변경0. 이전 운영 적용의 보존 영수증과 비파괴 원복 자료는 그대로 유지한다. 실기기/실제로그인제출·AI품질을 새 PASS로 보고하지 않는다.

Owner 검수: https://lab.legendstudy.com/essay-lab/universities/ewha/ → 수시 또는2024/2027모의 → 문항 → 기존 첨삭/재첨삭. 신규 자료 연결 작업은 CLOSED이며 Owner 품질검수와 구분한다.

APP `codex/essay-natural-expansion-20261111`, WEB `codex/essay-public-natural-20261112` 작업 브랜치에 종료기록을 commit/push한다. 릴리스 병합·스토어 제출 없음. 최종SHA/원격동일여부는 완료보고에 기록한다.
