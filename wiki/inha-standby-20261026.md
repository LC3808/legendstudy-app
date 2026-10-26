# 인하대학교 STANDBY — 2026-10-26

상태: **34회차 WEB STANDBY / OWNER QA PENDING**. 실제 평가 성공/E2E PASS는 주장하지 않는다. [전체 대학 공통 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책) 및 [기존 WEB 입력·결과 UI](essay-web-studio-ui-20261026.md)를 재사용한다.

## Owner 범위와 보존 검토

Owner는 인하대 인문·자연·의예 2022~2027 확보 시험의 Registry/공식 근거/기존 프로필/실행 정책/정확 PDF SELECT/STANDBY 공개 SQL을 사전·적용·사후 조건으로 승인했다. Provider 평가·가상 답안·실제 차감은 하지 않는다. APP 코드/빌드/스토어·결제·환불·인증 정책은 범위 밖이다.

1. 새 사실은 공식 자료와 시험 연결·승인 시점이며 학생의 학습 사실을 만들지 않는다.
2. 원본 SHA256·물리 페이지·파생 PDF와 적용 전 Registry/정책을 구분해 보존한다.
3. 기존 시험·문항 ID와 평가 revision을 보존하며 학생 답안·평가·History를 UPDATE/DELETE하지 않는다.
4. 기존 계정 identity와 회차당 최초1/무료0 Credit 예약·정산을 유지한다.
5. 대학 공식 근거 연결은 학생 Learning/Decision/Outcome 사실과 분리한다.
6. 학생용 문제 영역만 로그인 SELECT로 공개하며 공식 해설/평가근거 원본은 비공개 유지한다.
7. 추출 text/문제전용 파생본은 원본과 구분하고 STANDBY를 E2E PASS로 부르지 않는다.

## 자료 대조

인문10·자연15·의예9, 총34회차·92대문항을 확인했다. 각 대문항의 소문항 전체를 하나의 답안 작성 단위로 연결한다. 2025 모의 등 확보되지 않은 시험은 생성하지 않았다. 2022/2023 수시 자연 오후2회차의 기존 ID·6문항을 재사용하고 나머지32회차를 신규 등록했다. 범위 밖2021회차는 변경하지 않는다.

2027 모의 분리본의 **문제 PDF 파일명 일반/의예가 본문과 반대**다. 본문의 계열 표기와 통합 원본의 해당 페이지를 기준으로 연결한다. 해설 파일은 본문 표기가 정상이며 별도로 대응한다. 원본 파일 이름/내용은 변경하지 않았다. 2022/2023 수시 오전과2026 모의는 통합 원본 내부 일반/의예 영역을 분리했다. 공식 자료에서 명시한 공통 문항(일반3=의예1 등)은 정확한 공통 근거를 재사용하되 시험·문항 ID는 분리한다.

로컬 증거: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/inha-standby-20261026/`. 원본 전체 내용·Secret은 Wiki/Git에 저장하지 않는다.

## 대학별 히어로

공통 `UniversityEssayHero`와 `university-theme.ts`를 사용한다. 화이트 배경·대학별 표시 색상·원본 로고 비율을 유지하고 높이를 줄인다. 대학명 중복과 raw mock/admission 표시를 제거한다. 공식 자료 링크·2027 일정은 유지한다. 표시 테마는 서비스 승인에 관여하지 않는다. 인하 #005BAC, 한양 #004483, 중앙 #0068B7, 경희 #8E1836, 성균 #00664F, 고려 #8B0029, 서강 #9B1838, 건국 #006B3F, 외대 #007681; 미지정 대학은 기본 #244A6A. 공식 로고 자산은 교체하지 않는다.

## 공개 목록 저장 표현

34회차 추가로 기존 단일 Cloudflare binding 5KB 제한을 넘는다. 명시적 UUID 집합을 `uuid64:` + UUID16바이트의 Base64로 표현한다. 기존 CSV/compact UUID/Worker JSON 형식도 읽으며 최대256개·잘못된 입력 거부·서버 승인 검사 유지. wildcard나 대학 전체 권한을 새로 허용하지 않는다. 신규 parser를 WEB에 먼저 배포한 뒤 Worker와 정확한 공개 목록을 적용한다. Pages GET 응답 전체 재전송은 금지하고 지정 plain_text 두 항목만 PATCH한다.

## 대상 회차

| 계열 | 학년도 | 구분 | 회차 | 문항 | 시험 ID |
|---|---:|---|---|---:|---|
| 인문 | 2022 | 수시 | - | 2 | `9ac3f72b-9240-505f-894e-cc14673ed6f8` |
| 자연 | 2022 | 수시 | 오전 | 3 | `3e1a421d-0c40-5120-88ed-b1646f50e0fd` |
| 자연 | 2022 | 수시 | 오후 | 3 | `45f76789-e20e-596f-9760-3850644d21a9` |
| 의예 | 2022 | 수시 | 오전 | 3 | `216c2d1c-e807-5823-aab6-578560b52498` |
| 인문 | 2022 | 모의 | - | 2 | `21f707e4-022b-500f-9398-795a47909992` |
| 자연 | 2022 | 모의 | - | 3 | `33af3caf-afc5-5243-b110-4ba4d6a6651a` |
| 인문 | 2023 | 수시 | - | 2 | `c91c5281-6254-54d6-acf4-1a55151d9c2f` |
| 자연 | 2023 | 수시 | 오전 | 3 | `3dc612e2-15e0-51cc-9906-40a387f128a5` |
| 자연 | 2023 | 수시 | 오후 | 3 | `b4e457a5-0ce6-5973-bade-f4f43ecfa604` |
| 의예 | 2023 | 수시 | 오전 | 3 | `2e3a428b-a02a-5803-b317-3b9ad41e4834` |
| 인문 | 2023 | 모의 | - | 2 | `97e09d35-3944-5ae9-b7c7-e6bf7d195970` |
| 자연 | 2023 | 모의 | - | 3 | `c2f698b5-c617-57da-bc44-ee21b9df25e6` |
| 의예 | 2023 | 모의 | - | 3 | `28055f9c-b578-5d11-93f6-b3243ec7a014` |
| 인문 | 2024 | 수시 | - | 2 | `5192386d-51d4-5901-aa48-a82e6fb16e30` |
| 자연 | 2024 | 수시 | 오전 | 3 | `b59d5983-e977-52be-89cf-385d6ecc0403` |
| 자연 | 2024 | 수시 | 오후 | 3 | `1131e065-951f-5aba-bbc4-85c15fb9f0b0` |
| 의예 | 2024 | 수시 | 오전 | 3 | `7398c5f5-7678-5294-a7f8-81ac8d88be7c` |
| 인문 | 2024 | 모의 | - | 2 | `6bcf4726-033f-5920-b27b-7d51ab2030f6` |
| 자연 | 2024 | 모의 | - | 3 | `e5f1d7de-f69b-5d7b-85e6-8ded440ee94d` |
| 의예 | 2024 | 모의 | - | 3 | `43621b22-b507-5c54-816c-66ea6d06a01b` |
| 인문 | 2025 | 수시 | - | 2 | `ce546836-b363-5b4d-ac8f-389305f36a27` |
| 자연 | 2025 | 수시 | 오전 | 3 | `5a42333d-9def-5438-9baa-f46201f97fae` |
| 자연 | 2025 | 수시 | 오후 | 3 | `fd82164c-936c-56b2-ab96-b576f0c3be40` |
| 의예 | 2025 | 수시 | 오전 | 3 | `c951a7bf-3acc-5c4e-8ddf-07f09b257f25` |
| 인문 | 2026 | 수시 | - | 2 | `a3d9bb40-582c-5e76-8296-839ca6863bea` |
| 자연 | 2026 | 수시 | 오전 | 3 | `3e2526ee-14af-5c47-a5fc-76b70cc5bf8c` |
| 자연 | 2026 | 수시 | 오후 | 3 | `19f4c1e7-a82a-53ad-9aa2-7c72594518f1` |
| 의예 | 2026 | 수시 | 오후 | 3 | `eab15ec7-dd3c-5c41-865b-4b018b715a71` |
| 인문 | 2026 | 모의 | - | 2 | `9fc697fe-b7ac-5dcb-8c14-bf683b532060` |
| 자연 | 2026 | 모의 | - | 3 | `1a51f7f2-76c3-5d2f-a6f2-8020d00ff637` |
| 의예 | 2026 | 모의 | - | 3 | `84f67679-aa38-541a-a208-a3eceb1b17c5` |
| 인문 | 2027 | 모의 | - | 2 | `65493219-cab9-56b4-a3b0-fd6529207d15` |
| 자연 | 2027 | 모의 | - | 3 | `70b0ddd5-0816-5395-8ac5-6a4e3664a282` |
| 의예 | 2027 | 모의 | - | 3 | `4418be93-d956-5ec5-ab74-16cc48baab23` |

## 적용·복구·재개

Registry `registry-apply.sql`: 적용 완료, 재실행 금지. 신규32·기존2 및 대상92문항 사후검사 true. 연결 `batch-00`~`batch-33/owner-sql/`은 각 APPLIED.json이 있는 범위만 적용 완료로 판단하며 재실행하지 않는다. 사전/적용/사후 SQL 영수증을 함께 보존한다. 회차별 rollback.sql은 해당 신규 runtime/PDF 정책만 차단하며 Registry/학생 기록/Math 원본은 삭제하지 않는다.

공개 목록 변경을 되돌릴 때는 저장된 worker-before.private.json의 버전·정확한 ID 목록을 참고하되 Secret 응답을 PATCH로 재전송하지 않는다. 기존 공개 시험과 정상 인문 경로를 보존한다. 최종 배포·WEB 확인 결과는 아래에 추가한다.


## 최종 운영 확인 및 인수인계

| 계열 | 확보 대상 | 전체 문항 연결 | WEB STANDBY | 보류 | 답안 단위 |
|---|---:|---:|---:|---:|---:|
| 인문 | 10 | 10 | 10 | 0 | 20 |
| 자연 | 15 | 15 | 15 | 0 | 45 |
| 의예 | 9 | 9 | 9 | 0 | 27 |
| 합계 | 34 | 34 | 34 | 0 | 92 |

2022~2027 실제 확보분 기준이며 미확보 시험을 완료 수에 포함하지 않는다. 신규 STANDBY34, 신규 Registry32+기존2 재사용. 기존2021 회차는 범위 밖이며 STANDBY로 계산하지 않는다.

- 일반 사용자 Chrome Production에서 **34회차 모두** 계열/회차 선택·전체 답안 단위·문제 PDF 로딩 완료·첫 답안 입력/저장·활성 첨삭 버튼·서버 quote의1 Credit 확인창 확인. 최종 ‘첨삭 진행하기’는 누르지 않았다. 확인용 문구는 원래 빈 상태로 복원했다. 시험마다 실제 답안을 만들어 평가하지 않았다.
- 인문 TEXT 촬영/첨부 숨김, 자연/의예 Math binding 기반 사진·수식 입력 표시. 기존 이미지 추출·확인 경로는 재사용하며 새 이미지 추출/Provider 호출은 하지 않았다. 이미지 평가 품질/전체92답안 동시 제출 결과는 Owner QA 대상이다.
- 인하 카드 ‘첨삭 시작하기’ 활성 및 서비스 가능 대학 우선 목록 확인. PC1920·모바일400px 화이트 브랜드 히어로 확인, 모바일 documentWidth=viewportWidth=400. 로고 원본 비율·공식 자료·일정 유지. 2022/2023 Registry session의 raw admission도 사용자용 문구로 표시한다.
- Provider 호출0, 실제 제출0, 인하 운영runs0, 확인 전후 계정 크레딧7. 기존 submit/submit_cycle/runtime reader/finish/reserve 함수MD55개 보존 true. 기존 타시험 runtime 일치 true. 학생 답안·평가·History·Ledger는 이번 SQL의 변경 대상이 아니다.
- Typecheck/Production Build PASS, 관련 WEB40검사 및 Python scope3검사 PASS. Lint 오류0/기존 Math useEffect 경고2. 범위 밖 APP 미커밋 변경은 건드리지 않았다.

### 배포

- WEB source `b62b123` (연결·브랜드 구현 `1597c21`, 후속 회차 명칭 수정 포함).
- Pages Production `48b95117-75fe-488e-a7bc-6fb243778da1`: API success/source b62b123 확인.
- Worker `e85c587b-46fe-4abd-b871-3c84eb4305d7` 100%, deployment `31171b89-ad73-48a4-97f8-9e11c8aabc36`.
- Worker Registry232회차, 명시 공개scope181개(인하34 추가). 이 scope수는 전체 서비스 E2E 완료 수가 아니다.
- Worker 실제 기존 모듈을 읽어 registry_asset와 scope parser만 교체. 나머지 bindings/compatibility/CPU limits 보존 확인. Pages는 ESSAY_PUBLIC_EXAMS·MATH_PUBLIC_LEAVES 두 plain_text 항목만 변경하고 나머지 설정 보존 확인. Secret 원문 조회·재전송·변경0.
- 재실행 금지: `registry-apply.sql`, `batch-00`~`batch-33/owner-sql/apply.private.sql` 전부 적용 완료(APPLIED.json34개). 미적용 SQL0.
- 영수증: `REGISTRY-APPLIED.json`, 각batch APPLIED.json/SQL.result.json, `deployment-result.json`, `production-final.json`, `web-standby-checks.json`, `final-preservation.json`.

### 복구와 다음 순서

1. Owner는 인하2027 모의 인문/자연/의예부터 실제 답안으로 검수한다. 자연4쪽·의예3쪽의 전용 문제 PDF가 구분되는지 확인한 후 원하는 회차를 제출한다. 개발팀 E2E PASS로 기록하지 않는다.
2. 문제 발견 시 시험ID·문항·요청ID로 좁혀 수정한다. 동일 SQL/기존 성공 평가를 반복 실행하지 않는다.
3. UI만 복구할 경우 parser를 포함하는 Pages `16a832e5-6b73-44ca-bff7-0d1b2c4ce6e5`(1597c21)로 되돌릴 수 있다. 공개scope가uuid64인 동안 과거0704f33으로 곧바로 롤백하지 않는다.
4. 인하 연결 전체 복구는 먼저 인하34개만 공개scope에서 제거하는 최소plain_text PATCH/WEB재배포, 필요 시 해당batch rollback.sql로 runtime/PDF정책 차단. Worker 이전버전 `65fd5977-fbac-460a-bfc9-a38d836f6357`는 기존scope형식으로 함께 복구할 때만 사용. 현재 인하run0이지만 복구 실행 직전 진행 요청을 재확인한다. Registry·Math원본·학생기록을 삭제하지 않는다.
5. 이번 작업 이후 새 대학 개발/APP 빌드·스토어 작업은 진행하지 않았다. APP은 이번 WEB 회차 계약의 실기기 검증 대상이 아니며 호환을 새로 보증하지 않는다.
