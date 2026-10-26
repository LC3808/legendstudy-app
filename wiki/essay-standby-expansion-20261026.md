# 한국외대·건국대·서강대 STANDBY 확대 — 2026-10-26

상태: 운영 반영·WEB STANDBY 확인 완료, 건국 2026 수시의 기존 제출 확인 1회차는 완료 집계에서 제외. 추가 개발 중단 / Owner QA 대기. 최신 Owner 지시에 따라 한국외대 → 건국대 → 서강대 순서. 고려대 변경 금지. 2022~2027 확보된 인문·사회·상경 전체 회차가 대상이며 실제 존재하지 않는 시험을 생성하지 않는다. [공통 STANDBY 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책)과 [기존 82회차 인수인계](essay-handoff-20261025-final.md)를 재사용한다.

Owner는 이 세 대학의 Registry·공식 근거·프로필·실행 정책·정확한 문제 PDF 접근·STANDBY 공개 연결 SQL에 한해 사전/적용/사후 실행을 승인했다. 학생 답안·평가·Credit·Ledger·History 변경, 광범위한 권한 변경은 제외한다. Provider/가상답안/재첨삭 시험·APP UI/빌드/스토어 작업은 하지 않는다. 실제 일반계정 WEB에서 입력·저장·PDF·서버 1 Credit 안내창까지 확인하고 최종 제출은 하지 않는다.

## 보존 검토

1. 새 사실은 공식 원본과 시험 연결/승인 시점이며 학생 학습 사실을 생성하지 않는다.
2. 원본 PDF SHA256·물리 페이지·기존 ID·적용 전 JSON과 SQL 영수증으로 복원한다.
3. 기존 검수 본문/이력은 보존하고 새 revision만 추가한다. 학생 기록 UPDATE/DELETE는 하지 않는다.
4. 기존 auth.users identity·회차 예약/정산 경로를 유지한다.
5. 공식 자료 메타데이터 연결이며 학생 Learning/Decision/Outcome 사실과 분리한다.
6. 문제전용 PDF만 기존 로그인 사용자 정책으로 연결한다. 해설/채점자료는 비공개이며 개인정보 신규 수집은 없다.
7. PDF 추출/파생본은 원본 해시·페이지와 구분하고 STANDBY를 평가 성공/E2E PASS로 표시하지 않는다.

## 재개 기준

시작 APP `839b156`, WEB `a6accdf`, DOCS `ce2f843`. 로컬 자료/영수증: `legendstudy-materials/essay-validation-2026-10/three-universities-20261026/`. 기존 APP 미커밋 변경은 별도 작업이며 stage/reset/clean하지 않는다. 운영 기준은 읽기 조회로 재확인하며 파일 존재만으로 적용을 추정하지 않는다.

## 한국외대 반영 현황

2022~2026 수시 20회차·60문항을 연결했다. 기존 2023 인문 T3 ID를 보존하고 누락 19회차·57문항을 등록했다. 확보 자료에 2027 공식 모의는 없어 생성하지 않았다. 문제전용 파생 PDF와 원본을 분리하고 공식 근거는 비공개로 유지한다.

Worker `0c72d75c-8fa7-4423-8045-f3eb6d8533db`, WEB Production `030c7b86-80d8-496d-aca6-66489cadd126`(source `8e0358d`) 배포 성공을 API에서 확인했다. 기존 Worker 모듈·Secret·설정을 유지하고 Registry와 명시적 공개 회차 범위만 확대했다. 신규 전체회차 discovery evidence 누락을 보완했다.

일반 사용자 WEB 20회차에서 전체 3문항 탭·입력·로컬 저장·서버 1 Credit 안내창을 확인하고 최종 제출을 취소했다. 기존 draft를 원복했다. 2026 인문 T1 문제 PDF 6페이지 렌더를 직접 확인했으며 전체 20회차 PDF 뷰어에서 로딩 종료·페이지 수 표시를 확인했다. 카드 첨삭 시작하기 활성화 확인. 새 Provider 호출 0, 해당 확인 전후 화면 Credit 9 유지. Owner의 별도 한양대 평가 탭은 조작하지 않았다. E2E PASS가 아니다.

재실행 금지: 로컬 `three-universities-20261026/hufs/registry-apply.sql`, `batch-00`~`batch-19/owner-sql/apply.private.sql` 적용 완료. 각 APPLIED 영수증·사전/사후 결과를 보존한다. 복구는 해당 batch의 runtime/PDF 정책만 비활성화하는 rollback.sql이며 학생 기록을 삭제하지 않는다.

## 최종 결과 / Owner 검수 대상

| 대학 | 확보 대상 회차 | 이번 전체 연결 | 신규 STANDBY | 기존 STANDBY 보존 | 확인 보류 |
|---|---:|---:|---:|---:|---:|
| 한국외대 | 20 | 20 | 20 | 0 | 0 |
| 건국대 | 14 | 13 | 12 | 1 | 1 |
| 서강대 | 23 | 22 | 22 | 1 | 0 |

**신규 STANDBY 합계 54회차.** 기존 건국 2026 모의 인문과 서강 2026 모의 경제경영은 재평가하지 않고 보존했다. 이번 전체 연결 55회차·114문항 중 1회차는 UI의 이전 제출 확인 안내 때문에 서버 안내창 확인을 보류했다. Provider 평가 성공 수가 아니다. 일반계정 실측은 각 대학 `web-ui-receipt.json`에 기록했다. 입력은 평가용 가상 답안이 아닌 연결 확인 문구이며 안내창에서 취소하고 기존 브라우저 draft를 복원했다. 새 평가 제출·Provider 호출·이번 작업의 Credit 사용은 모두 0. 화면 잔액 9 유지. Owner의 별도 실제 평가 탭/기록은 조작하지 않았다.

### 건국대

2022~2026 확보 인문·사회 14회차 대상. 신규/전체 확장 13회차·26문항, 기존 전체 연결 1회차 보존. 2022/2023 누락 4회차·8문항만 등록했다. 기존 부분 공개 2025 수시 인문I, 2026 수시 인문은 기존 ID와 과거 패키지를 남기고 전체 2문항으로 확장했다. 인문사회II 6회차의 수리 Q2는 기존 Math 입력·공식 근거 계약을 재사용했다. 기존 자연계 Math 성공 기록은 재검증하지 않았다.

보류: `1033e20b-9a20-5622-a67b-c288ace2734f` — 2026 수시 인문. 전체 2문항·PDF·입력저장·버튼 활성화는 확인했으나 이 계정 브라우저의 ‘이전 제출의 처리 상태를 첨삭 기록에서 먼저 확인해 주세요’ 안내로 서버 1 Credit 안내창에 진입하지 못했다. 기존 Q2 답안과 제출키를 보존했으며 localStorage 초기화·새 제출·예약 해제는 하지 않았다. Owner가 기존 첨삭 기록의 처리 상태를 먼저 확인하고 정상 새 회차 경로를 선택한다. 미완료 요청이면 요청 ID에 따라 별도 복구하며 추가 예약/차감을 만들지 않는다. 이 1회차를 신규 STANDBY 성공으로 계산하지 않는다.

자유전공/통합 4회차와 자연계열은 이번 인문·사회·상경 우선 범위에 넣지 않았다. 확보되지 않은 2027 공식 모의를 만들어내지 않았다.

### 서강대

기존 2026 모의 경제경영 1회차를 보존하고 신규 22회차·28문항 연결. 누락 Registry 8회차·12문항 추가. 2022/2023 모의 각4, 2024 수시2·모의2, 2025 수시2·모의4, 2026 수시2·모의 인문1, 2027 모의 인문1이다. 추가 2024 수시2는 기존 공식 2027 논술 가이드북의 실제 2024 기출 구간을 사용했으며 2027 변경사항을 소급 적용하지 않았다.

스캔 및 숨은 중복 텍스트가 있는 공식 PDF는 로컬 Apple Vision으로 실제 페이지의 글자를 읽었다. 외부 OCR/Provider 호출은 0. 문제전용 PDF는 출제의도/정답 시작 전까지 분리하고 원본과 별도 해시로 추적했다. 공식 원본/평가기준은 비공개 유지. 22회차 모두 일반계정에서 전체 답안 입력·저장·PDF 렌더·서버 1 Credit 안내창을 확인했다.

## 실제 Production / 보존 근거

- Supabase: `stlhijzpjfgwwdgunlsd`. 이번 승인 범위 SQL 적용 완료. 신규 Registry: 외대19 / 건국4 / 서강8. 기존 ID를 교체하지 않았다.
- WEB: `aedbf200-98f1-46c9-b565-a94bb9d3fddf`, Production 성공, source `c01caf0` (`codex/web-app-release-20261024`, 배포 branch main). 배포 API에서 확인.
- Worker: `a99a7cfc-022d-4408-84b5-cc9c44f967dd`, `legendstudy-essay-reviewed` 100%. 기존 평가 구현/인증/Secret은 상속하고 Registry와 명시적 승인 ID만 반영.
- 공개 ID allowlist는 142개이며 **STANDBY 완료 수와 다르다**. Cloudflare 단일 text binding 5KB 제한으로 같은 UUID를 32자리로 저장하고 서버가 canonical UUID로 복원한다. 전체 허용/wildcard가 아니며 각 ID·기존 DB 실행승인을 계속 검사한다. parser를 먼저 WEB 배포하고 설정 전환 후 같은 산출물을 재배포해 기존 공개 회차를 보존했다. 로컬 142 ID 동등성·잘못된 ID/중복/wildcard 거부 확인.
- Math 공개 문항 ID는 기존21 + 건국 사회II 6 =27. 그 외 Pages 환경 설정의 이름/값, Worker bindings/limits/compatibility 보존을 API에서 대조했다. Secret 원문 출력/변경 없음.
- 시작 93개 runtime 중 확장 승인된 건국2를 제외한 **91개 정책 동일**. 고려대는 이 보존 범위에 포함되며 DB/Registry/공식근거/공개 정책을 바꾸지 않았다.
- 기존 제출·cycle·예약·정산·과거 자료 조회 함수 5개 MD5 동일. 전체회차 WEB evidence 기존64건 모두 동일. 기존 중앙21·경희24·성균16·한양21=82회차 연결/공개 설정 보존. 기존 성공 E2E를 반복하지 않았다.
- 신규 학생 평가/History/Ledger INSERT/UPDATE/DELETE 없음. Owner의 동시 사용자 활동은 있을 수 있으므로 서비스 전체 학생 행 수 불변으로 과장하지 않는다.
- 최종 일반사용자 카드에서 건국·서강·한국외대 및 기존 중앙·경희·성균·한양 ‘첨삭 시작하기’가 상단에 표시됨. APP UI/빌드/스토어 변경 없음. 기존 APP 회차/혼합 제출 호환 GAP은 해소했다고 주장하지 않는다.

## 적용 SQL / 재실행 금지 / 복구

로컬 영수증 루트: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/three-universities-20261026/`.

- `hufs/registry-apply.sql`, `konkuk/registry-apply.sql`, `sogang/registry-apply.sql`, `sogang-guide/registry-apply.sql`: 적용 완료, 재실행 금지.
- `hufs/batch-00`~`batch-19`, `konkuk/batch-00`~`batch-12`, `sogang/batch-00`~`batch-19`, `sogang-guide/batch-00`~`batch-01`의 `owner-sql/apply.private.sql`: 적용 완료. `sogang/batch-20/21`은 guide 적용 영수증 사본이며 **별도 신규 SQL이 아니다**. 중복 실행 금지.
- 각 연결 batch에서 Production 사전15/사후7 true 및 APPLIED 영수증 확인. 실패했던 건국 수리 기준 길이/SQL 공백 오류는 트랜잭션 롤백 후 원인 수정했으며 이미 성공한 batch는 건너뛰었다. Registry 각 적용은 별도 사전/사후 영수증 보존.
- 미적용 연결 SQL 없음. 위 건국1회차는 DB 미적용 문제가 아니라 기존 제출 확인 경로 보류다.
- 시험별 복구: 해당 `batch-NN/owner-sql/rollback.sql`을 검토해 신규 runtime/PDF 공개만 차단. 학생 결과·Registry·원본은 삭제하지 않는다. 건국 기존2회차 확장은 저장된 original-runtime과 함께 이전 실행 정책으로 되돌린다. 과거 revision 조회는 유지한다.
- 전체 배포 복구 기준: 이번 작업 전 WEB `a8f3ba51-4c00-4bd7-8896-72f233d17817`, Worker `5fe85e6c-2ba4-4562-8943-b2d2ead9eb6b`; 최종 직전 정상 WEB `cd5384d9-b2f8-42aa-a7c6-8f922a4567c0`, Worker `59cea101-6089-449b-aef6-86c5b1bc007b`. 버전만 되돌리지 말고 해당 시점 공개 ID 범위/UUID 표현을 함께 맞춘다. 이전128한도 Worker에 현재142범위를 그대로 넘기지 않는다. 기본은 해당 시험 정책만 차단하는 최소 복구다.
- Pages 복구도 `public_scope_patch` 방식의 대상 plain_text 최소 PATCH만 사용. 과거 settings JSON 전체 재전송 금지(마스킹 Secret 손상 위험). `pages-before.private.json`은 비교 자료일 뿐 PATCH 본문이 아니다.

## 다음 실행 순서

1. Owner는 아래 STANDBY 목록에서 실제 답안으로 임의 검수한다. 개발팀은 실제 평가를 대신 반복하지 않는다.
2. 건국 2026 수시 기존 요청 상태 확인 → 기존 기록을 유지하는 정상 새 회차 또는 정확한 실패 복구로 한정한다.
3. 지정된 오류만 최소 수정한다. 고려대 및 확보하지 못한 회차는 새 Owner 지시 전 확장하지 않는다.
4. 기존82회차와 성공 평가를 재호출하거나 성공 SQL을 재실행하지 않는다. 이번 확대 작업은 여기서 종료한다.

## 대학별 Owner 선택 목록

아래는 이번 연결 55회차이며 건국 보류1을 제외한54회차가 신규 STANDBY다. 기존 건국2026모의 인문(`87b73ea0-99bb-5fd3-a94d-93371b4f4a68`), 서강2026모의 경제경영(`1862463a-bf97-580a-ad33-694375db5d50`)은 별도 보존.

| 대학 | 학년도 | 구분 | 계열·회차 | 문항 | 상태 | 시험 ID |
|---|---:|---|---|---:|---|---|
| 한국외대 | 2022 | 수시 | 사회계 T1 | 3 | STANDBY / OWNER QA PENDING | `450b16fa-0471-5c3d-a848-a6bd47f38495` |
| 한국외대 | 2022 | 수시 | 사회계 T2 | 3 | STANDBY / OWNER QA PENDING | `70087478-22c9-5b70-a765-2b7d6af182ca` |
| 한국외대 | 2022 | 수시 | 인문계 T3 | 3 | STANDBY / OWNER QA PENDING | `ca23e401-3738-593b-9b01-56994aa49e09` |
| 한국외대 | 2022 | 수시 | 인문계 T5 | 3 | STANDBY / OWNER QA PENDING | `5d46e26b-5aff-5cd5-a351-a55688391bb4` |
| 한국외대 | 2023 | 수시 | 사회계 T1 | 3 | STANDBY / OWNER QA PENDING | `d287daf9-1379-5a9d-b06a-0beb03deb4ed` |
| 한국외대 | 2023 | 수시 | 사회계 T2 | 3 | STANDBY / OWNER QA PENDING | `5fd2442e-2fa8-5299-9390-712161487556` |
| 한국외대 | 2023 | 수시 | 인문계 T3 | 3 | STANDBY / OWNER QA PENDING | `49f7906f-ff37-5477-90d3-07fb18c9774c` |
| 한국외대 | 2023 | 수시 | 인문계 T4 | 3 | STANDBY / OWNER QA PENDING | `b88ded2a-e271-5f33-91ea-d2d6f28050ef` |
| 한국외대 | 2024 | 수시 | 사회계 T2 | 3 | STANDBY / OWNER QA PENDING | `0165287e-f623-5127-80fc-fff3ed9c9c54` |
| 한국외대 | 2024 | 수시 | 사회계 T4 | 3 | STANDBY / OWNER QA PENDING | `26d322e6-8880-54b4-9ad4-b1b44cb1e4b1` |
| 한국외대 | 2024 | 수시 | 인문계 T1 | 3 | STANDBY / OWNER QA PENDING | `7156856a-8150-5540-aff6-87d339ddd992` |
| 한국외대 | 2024 | 수시 | 인문계 T3 | 3 | STANDBY / OWNER QA PENDING | `c0d712c5-1892-5dd4-b817-f16ad3eac373` |
| 한국외대 | 2025 | 수시 | 사회계 T2 | 3 | STANDBY / OWNER QA PENDING | `77f6e348-ab64-5f9f-afcd-83b1526564d3` |
| 한국외대 | 2025 | 수시 | 사회계 T4 | 3 | STANDBY / OWNER QA PENDING | `3f2e58de-abf3-565d-9469-bac4384a3103` |
| 한국외대 | 2025 | 수시 | 인문계 T1 | 3 | STANDBY / OWNER QA PENDING | `27fdde10-f7dd-5c0e-9d36-2a7cd53302d9` |
| 한국외대 | 2025 | 수시 | 인문계 T3 | 3 | STANDBY / OWNER QA PENDING | `efd414a4-0848-595f-9c86-c07af151a46a` |
| 한국외대 | 2026 | 수시 | 사회계 T2 | 3 | STANDBY / OWNER QA PENDING | `ab62c603-8ef9-58e5-b28a-b7b0abadb1bd` |
| 한국외대 | 2026 | 수시 | 사회계 T4 | 3 | STANDBY / OWNER QA PENDING | `76a5224b-731c-58d5-9ada-68e15c09ba66` |
| 한국외대 | 2026 | 수시 | 인문계 T1 | 3 | STANDBY / OWNER QA PENDING | `317249a5-ef36-5b30-b474-41b1d40efc57` |
| 한국외대 | 2026 | 수시 | 인문계 T3 | 3 | STANDBY / OWNER QA PENDING | `db9b27e7-fab1-543e-a75c-a5f622247c1c` |
| 건국대 | 2022 | 수시 | 인문사회Ⅰ  | 2 | STANDBY / OWNER QA PENDING | `5e91f386-4cd3-5ed5-824d-8f54809994e5` |
| 건국대 | 2022 | 수시 | 인문사회Ⅱ  | 2 | STANDBY / OWNER QA PENDING | `df220173-b0ef-5cd2-8a92-12a958fd669e` |
| 건국대 | 2023 | 수시 | 인문사회Ⅰ  | 2 | STANDBY / OWNER QA PENDING | `01390436-371e-515b-b4ae-6ba73bee28e8` |
| 건국대 | 2023 | 수시 | 인문사회Ⅱ  | 2 | STANDBY / OWNER QA PENDING | `7b2ba890-bb8d-5c00-b665-b926cdd5008f` |
| 건국대 | 2024 | 수시 | 인문사회Ⅰ  | 2 | STANDBY / OWNER QA PENDING | `f3090617-216a-509b-8416-382c48146e86` |
| 건국대 | 2024 | 수시 | 인문사회Ⅱ  | 2 | STANDBY / OWNER QA PENDING | `c722ffa2-0ff4-5718-9748-186111a7c560` |
| 건국대 | 2024 | 모의 | 인문사회Ⅰ  | 2 | STANDBY / OWNER QA PENDING | `7651b2ad-78b5-5ec3-8d52-342326103e40` |
| 건국대 | 2024 | 모의 | 인문사회Ⅱ  | 2 | STANDBY / OWNER QA PENDING | `81b81d92-0a1a-54af-b4dd-2702222bc1f3` |
| 건국대 | 2025 | 수시 | 인문사회Ⅰ  | 2 | STANDBY / OWNER QA PENDING | `cba01fbd-3de1-5ac1-ab7b-77465ac40638` |
| 건국대 | 2025 | 수시 | 인문사회Ⅱ  | 2 | STANDBY / OWNER QA PENDING | `7e232cd6-cbad-547f-bb34-2eb6cebb65f7` |
| 건국대 | 2025 | 모의 | 인문사회Ⅰ  | 2 | STANDBY / OWNER QA PENDING | `d06310c1-eec7-582f-b7af-61a59a71000f` |
| 건국대 | 2025 | 모의 | 인문사회Ⅱ  | 2 | STANDBY / OWNER QA PENDING | `1f382418-b4b8-5562-82ec-0c2e5f3cfaef` |
| 건국대 | 2026 | 수시 | 인문  | 2 | 기존 제출 확인 보류 | `1033e20b-9a20-5622-a67b-c288ace2734f` |
| 서강대 | 2022 | 모의 | 인문계열(경제경영) 1차 | 1 | STANDBY / OWNER QA PENDING | `634fe020-4f19-5e9e-b985-aeaf7d5e7674` |
| 서강대 | 2022 | 모의 | 인문계열(경제경영) 2차 | 1 | STANDBY / OWNER QA PENDING | `f5220059-e463-5dba-a579-21b03c3840ae` |
| 서강대 | 2022 | 모의 | 인문계열(인문사회) 1차 | 1 | STANDBY / OWNER QA PENDING | `83ebbe5d-5b47-5c98-a466-388b34307106` |
| 서강대 | 2022 | 모의 | 인문계열(인문사회) 2차 | 1 | STANDBY / OWNER QA PENDING | `33a658ac-d0f5-5895-9c8d-13e8071cc55a` |
| 서강대 | 2023 | 모의 | 인문계열(경제경영) 1차 | 1 | STANDBY / OWNER QA PENDING | `829acee1-1514-5f83-999b-4d0d4578fc2e` |
| 서강대 | 2023 | 모의 | 인문계열(경제경영) 2차 | 1 | STANDBY / OWNER QA PENDING | `93b21878-441b-521d-8601-a231db8c37b6` |
| 서강대 | 2023 | 모의 | 인문계열(인문사회) 1차 | 1 | STANDBY / OWNER QA PENDING | `409f730d-ea3d-5027-aeda-97ae48af3dc3` |
| 서강대 | 2023 | 모의 | 인문계열(인문사회) 2차 | 1 | STANDBY / OWNER QA PENDING | `3c362c88-42f4-5795-a065-585a81ae7879` |
| 서강대 | 2024 | 수시 | 인문계열(경제경영)  | 2 | STANDBY / OWNER QA PENDING | `d56ef42f-183a-5bfa-823e-a330b4310cb1` |
| 서강대 | 2024 | 수시 | 인문계열(인문사회)  | 2 | STANDBY / OWNER QA PENDING | `2cdffa26-7811-55c4-baa4-dd94b5675201` |
| 서강대 | 2024 | 모의 | 인문계열(경제경영) 1차 | 1 | STANDBY / OWNER QA PENDING | `b7951a7f-c382-5671-983e-b1e9dc0aa6de` |
| 서강대 | 2024 | 모의 | 인문계열(인문사회) 1차 | 1 | STANDBY / OWNER QA PENDING | `60d8874b-2417-5631-9502-227368586759` |
| 서강대 | 2025 | 수시 | 인문계열(경제경영)  | 2 | STANDBY / OWNER QA PENDING | `66f70c38-7d06-5720-b5ce-e3e9fd46a458` |
| 서강대 | 2025 | 수시 | 인문계열(인문사회)  | 2 | STANDBY / OWNER QA PENDING | `d0bc83bd-2b0d-5ce2-a939-8c8ba35af482` |
| 서강대 | 2025 | 모의 | 인문계열(경제경영) 1차 | 1 | STANDBY / OWNER QA PENDING | `5bb10508-008c-508b-a21c-316608d084c7` |
| 서강대 | 2025 | 모의 | 인문계열(경제경영) 2차 | 1 | STANDBY / OWNER QA PENDING | `a00991d4-bab2-51ac-a008-7de55ea1dcb9` |
| 서강대 | 2025 | 모의 | 인문계열(인문사회) 1차 | 1 | STANDBY / OWNER QA PENDING | `e1e4e88a-95be-50c7-a179-12a22f974246` |
| 서강대 | 2025 | 모의 | 인문계열(인문사회) 2차 | 1 | STANDBY / OWNER QA PENDING | `3ff20524-1751-53e4-9e72-f6b556ef1032` |
| 서강대 | 2026 | 수시 | 인문계열(경제경영)  | 2 | STANDBY / OWNER QA PENDING | `aa9c471c-974a-5894-b46f-560a449844b3` |
| 서강대 | 2026 | 수시 | 인문계열(인문사회)  | 2 | STANDBY / OWNER QA PENDING | `0dddefe1-624d-56e4-bf4f-3311c4784185` |
| 서강대 | 2026 | 모의 | 인문계열(인문사회) 1차 | 1 | STANDBY / OWNER QA PENDING | `58bdce90-d241-5aab-b78a-fab8339d1d80` |
| 서강대 | 2027 | 모의 | 인문계열  | 1 | STANDBY / OWNER QA PENDING | `a0d96e4b-a066-5be4-86d1-79a8f26a4cc1` |

## 서강·고려 카드 우선 배치 / 고려 1문항 예외 — Owner 2026-10-26

Owner가 서강·고려 카드 활성화/앞쪽 배치를 요청하고, 고려는 ‘현재 승인된 1문항만 예외 공개’를 명시 선택했다. 이전 고려 작업 보류 중 **이 시험의 공개 연결만** 해제한다. 전체 회차 STANDBY 정책의 일반 변경이 아니다.

서강 기존23회차는 이미 공개 중이며 그대로 보존한다. 기본 목록은 서강→고려를 먼저 배치하되 카드 활성화는 서버 공개 상태를 계속 따른다. 고려는 2025수시 인문 오후 `942c1c43-914f-5b99-9a30-e6474c363f6f`의 **문제2** `c1f90870-3ad9-59f8-afe3-c26d665f292f`만 공개한다. 문제1은 미승인 유지. 기존 runtime package digest `9afbeece5b9348c5402430f3bd215a9d8acf2c1ce0add6b38fffab78f7229ea4`와 PDF를 재사용한다. 전체 회차 evidence에 넣지 않고 별도 partial release manifest로 관리한다. 카드/시험 화면에 문제2 부분공개 표시. 신규54/기존82 전체회차 STANDBY 수에 더하지 않는다.

Pages·Worker 공개 allowlist에 기존 시험 ID1개 추가(142→143). Worker `57dfa6c1-6bc8-4616-8dbe-78e516df727c`. Worker Registry/평가 소스·기존 bindings·Secret·DB runtime 정책 그대로. DB SQL 쓰기0, Provider/평가제출/차감0. 서버 preflight/고정digest/문항 ID 검사 유지, 임의 버튼 강제 활성화 아님. 연결 증거는 `three-universities-20261026/korea-card-exception/`.

복구는 해당 ID만 공개 allowlist에서 제외하고 partial manifest/우선배치 변경을 되돌린다. DB 기존 평가·문항·Credit·History 삭제나 이전 성공 SQL 재실행은 하지 않는다.

WEB Production `c244b76f-aafa-4301-bdb7-70b922b4cc3c` (source `2fbde34`) 배포 success. 일반 사용자 운영 화면에서 기본 순서 서강→고려, 양쪽 ‘첨삭 시작하기’ 링크 및 고려 문제2 부분공개 문구 확인. 연결 검사 9개 PASS. Provider 호출·답안 제출 없음.
