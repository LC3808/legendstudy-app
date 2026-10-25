# 2026-10-25 종료 인수인계 — 성균 PDF·한양 STANDBY

오늘 개발 종료. 추가 개발·Provider 호출·배포·SQL·APP 빌드·Mac 종료/예약 명령을 실행하지 않는다. 내일 Owner 검수 후 재개한다. 기존 [최종 작업 기록](essay-group-1a-20261025.md#2026-10-25-최종-범위--성균-pdf-수정한양-standby)을 재사용하며 이 문서는 재개 순서만 정리한다.

## 완료와 미완료

- 성균 언어형16회차·48문항: 문제 확인 버튼 표시 복구. 2025수시1교시의 이전 PDF/PENDING manifest 3행을 이미 승인된 문제전용 PDF로 정정. 기존 자료/권한/평가 계약 유지. 16회차 버튼과 해당 누락 회차 PDF 렌더 확인.
- 한양 인문13회차·13문항: 실제 일반 사용자 STANDBY. 전체 회차 입력·브라우저 저장·버튼 활성, 정확한 PDF/공식근거/runtime 연결. 2027모의 PDF 렌더·서버1Credit 견적 확인 후 취소. 평가 제출하지 않았으므로 E2E PASS 아님.
- 한양 상경8회차·16문항: Registry만 완료, STANDBY 미완료. 각 시험 수리Q2와 Essay의 동일 예약을 공유하는 혼합 경로 미연결. 별도 Math 예약으로 중복 과금하지 않으며 전체 시험 공개 보류.
- 한양2025모의 인문·상경2회차: resource는 존재하지만 로컬 원본 미확보·기존 URL 다운로드 실패. 준비된21회차와 별도. 알려진 대상 기준 인문14=완료13+보류1, 상경9=완료0+보류9.
- 기존 경희 사회 그래프2회차 보류, 성균2024모의 자료 미확보는 이전 기록 유지. 오늘 다시 조사/평가하지 않았다.

### 한양 회차별 상태

| 시험 | 상태 | Registry ID |
|---|---|---|
| 2022학년도 한양대학교 수시논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `56a6be43-48eb-5aaa-a0ce-f646faaabe23` |
| 2022학년도 한양대학교 수시논술 인문계열 오후 1 | STANDBY / OWNER QA PENDING | `43405c4d-c711-5258-b9ce-31e2a26ad14f` |
| 2022학년도 한양대학교 수시논술 인문계열 오후 2 | STANDBY / OWNER QA PENDING | `805f26ac-6a09-5d51-8660-11463c4f95ef` |
| 2023학년도 한양대학교 수시논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `f45667e4-bbd0-5372-b044-e5e9d3983521` |
| 2023학년도 한양대학교 수시논술 인문계열 오후 1 | STANDBY / OWNER QA PENDING | `cae8d130-1086-5854-8365-543d236f9b29` |
| 2023학년도 한양대학교 수시논술 인문계열 오후 2 | STANDBY / OWNER QA PENDING | `57437772-29b0-5b2f-8976-6781f2ef7109` |
| 한양대학교 · 2024 · mock · 상경계열 | 보류: 혼합 수리 단일예약 연결 | `f88663fb-a0d4-52ed-bead-ea11f2c2970e` |
| 2024학년도 한양대학교 모의논술 인문계열 | STANDBY / OWNER QA PENDING | `9e39d1e1-81db-5de8-9981-cff9f630052d` |
| 2024학년도 한양대학교 수시논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `ef5ca7d9-3a56-5068-933e-f7a2859ef438` |
| 2024학년도 한양대학교 수시논술 인문계열 오후 1 | STANDBY / OWNER QA PENDING | `c5cc5f46-d74f-5c83-a432-cf173d3c8be1` |
| 한양대학교 · 2024 · admission · 인문계열 · 오후 2 | STANDBY / OWNER QA PENDING | `345d3caa-3438-58c3-8f80-62a6242179ec` |
| 2025학년도 한양대학교 수시논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `6536445f-75b2-5f84-894a-f33382e8ea91` |
| 2025학년도 한양대학교 수시논술 인문계열 오후 1 | STANDBY / OWNER QA PENDING | `5fa43d13-0d0b-54f3-85f7-106102d4e50b` |
| 2025학년도 한양대학교 수시논술 인문계열 오후 2 | STANDBY / OWNER QA PENDING | `770b0d74-da6d-5136-a87e-b25e3961093f` |
| 2026학년도 한양대학교 모의논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `54d99cb2-f04e-598a-b5e9-9222d0b97bba` |
| 2026학년도 한양대학교 모의논술 인문계열 | STANDBY / OWNER QA PENDING | `c3636363-c579-5f50-8bcb-93e0732b502a` |
| 2026학년도 한양대학교 수시논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `e8ea5bb3-0956-5fd6-b90e-4b7fb350b2f9` |
| 2026학년도 한양대학교 수시논술 인문계열 오후 1 | STANDBY / OWNER QA PENDING | `e4969922-c133-5f7d-ae8d-fc50ba389066` |
| 2026학년도 한양대학교 수시논술 인문계열 오후 2 | STANDBY / OWNER QA PENDING | `d9882328-3973-58f2-b0d3-fec7d7984d9e` |
| 2027학년도 한양대학교 모의논술 상경계열 | 보류: 혼합 수리 단일예약 연결 | `68996278-1e19-5560-ac94-cf43656bf684` |
| 2027학년도 한양대학교 모의논술 인문계열 | STANDBY / OWNER QA PENDING | `e628b01a-9ab6-5cff-88e0-dcdb7ff8ce26` |

## Production 및 Git

마감 시 Cloudflare API read-only 재조회: WEB `d4037191-2000-4266-a5cf-a43a8cc156e5` success, 배포 source SHA `f5cebe5541a74988d0be6d6f396b5bf1cd03ed16`. Worker `238ab93f-49d1-4c5f-a660-4920fe92d5f5` 100%, deployment `6ef0e5cd-9dd8-4ba2-88e1-0ee4c08c7821`. Production DB `stlhijzpjfgwwdgunlsd`. 공개 UUID scope68, Worker registry135는 정책/registry 크기이며 전체 대학 STANDBY 수가 아니다.

| 저장소 | 작업 폴더 | 브랜치 | 구현/직전 문서 SHA (원격 일치 확인) |
|---|---|---|---|
| WEB | `/Users/woojinchang/development/legendstudy-release-20261024` | `codex/web-app-release-20261024` | `f5cebe5541a74988d0be6d6f396b5bf1cd03ed16` |
| APP·Worker 소스·Wiki | `/Users/woojinchang/development/legendstudy-service-app-20261022` | `codex/material-service-app-20261022` | `edfc83af934b2dbed9f2484ef06625533c19c581` |
| DOCS | `/Users/woojinchang/development/legendstudy-release-docs-20261024` | `codex/web-app-release-20261024` | `b524294a56f954663a8179c89e0e8afcb044df06` |

이번 인수인계의 문서 전용 후속 커밋은 위 구현 SHA와 구분한다. 실제 최신 HEAD는 `git rev-parse HEAD`와 `git ls-remote origin refs/heads/<branch>`로 대조한다. Worker는 별도 Git 저장소가 아니라 APP 소스·생성 Registry를 배포한 Cloudflare 버전이다. 생성 Registry/private 평가자료는 아래 로컬 보관소에 유지하며 공개 Git에 원문을 넣지 않았다. 기존 Worker123 entries와 나머지 모듈/Secret/bindings/CPU30000 보존, 변경 모듈은 registry_asset와cloudflare_http 두 개다.

APP 작업 폴더에는 이번 범위 밖 기존 미커밋 Flutter/테스트/.gitignore 변경과 미추적 파일이 남아 있다. 깨끗한 checkout이라고 보고하지 않는다. 다음 작업자가 reset/clean/전체 stage하지 말고 `git status --short`와 diff를 먼저 확인한다. APP 새 빌드/스토어 배포 없음.

## SQL 적용 기록과 재실행 금지

로컬 보관 루트: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/hanyang-standby-20261025/`.

| 패키지 | 결과 | 재실행 금지 파일 |
|---|---|---|
| Registry | 19시험·26문항 추가, 사전1/사후1 true | `registry-sql/apply.sql` |
| 인문 A | 6회차, 사전16/사후7 true | `batch-a/owner-sql/apply.private.sql` |
| 인문 B | 6회차, 사전16/사후7 true | `batch-b/owner-sql/apply.private.sql` |

precheck/postcheck 결과 영수증은 각 패키지의 `*.result.private.json`, 정확한 회차·문항은 manifest에 있다. 모두 적용완료이며 SQL 대기 아님. 기존 성균 continuous-skku A/B, 경희 continuous, 중앙대10회차 및 누락2026모의, 고려·성균·서울여 revision 패키지와 normal-batch-01도 기존 적용기록 그대로 재실행 금지. 전체 일괄 SQL의 폐기/분할 대체본은 실행하지 않는다. 상경과 미확보2025모의는 실행할 준비가 끝난 SQL이 대기하는 상태가 아니다.

## Credit·History·Ledger 보존 근거

이번 변경 SQL은 Registry/검수자료/실행 정책/정확한 PDF SELECT에 한정했고 학생 답안·평가·Credit·History·Ledger 수정/삭제는 하지 않았다. 기존 ID/다른 정책 보존 사후검사 통과. WEB 입력 확인은 기존 브라우저 초안을 복원했고 최종 평가 제출을 누르지 않았다. Provider0, 비용0, 평가제출0, 추가 예약/차감0, 일반 계정 화면 잔액10 유지. 기존 최초1/무료재첨삭0/History 계약을 보존했으며 새 E2E로 재검증한 것은 아니다. 기존 모든 학생 행의 전후 hash를 전수 대조한 것이라고 확대 해석하지 않는다.

## 내일 Owner 검수 대상과 재개 순서

1. 이 인수인계 → 기존 공통 STANDBY 정책 → 현재 Git/Production 상태를 읽는다. 이전 성공 평가·SQL을 반복하지 않는다.
2. Owner가 일반 계정에서 성균2025수시1교시 PDF와 한양 인문13회차 중 원하는 시험을 선택한다. 공식 예시답안/실제 답안으로 실제 첨삭·재작성·무료재첨삭·성장·History를 직접 검수한다. 1Credit 최초/0Credit 무료재첨삭은 실제 검수 결과로 기록한다. 개발팀의 자동 가상답안/Provider 반복 호출 금지.
3. Owner가 지정한 오류의 시험ID·문항ID·증상만 최소 수정한다. 인증/중복 차감/History 무결성 오류는 해당 경로 공개보다 우선한다.
4. 한양 상경은 기존 Essay·Math/이미지 처리의 회차 단일예약 연결부터 이어간다. 수리Q2 제외하고 전체 완료로 표시하거나 별도 예약으로 우회하지 않는다. 정산·권한 계약 변경이 필요하면 추가 승인 범위를 확정한다.
5. 한양2025모의 인문·상경 원본을 기존 resource/보관소에서 복구한 뒤 기존 ID와 연결한다. 준비자료가 없으면 보류 유지. 다른 대학 확대·APP UI/빌드/스토어 작업은 Owner의 다음 지시 전 시작하지 않는다.

## 롤백 경로

현재 정상 배포 유지가 기본이며 마감 때 롤백하지 않았다. 문제가 생기면 먼저 해당 한양 exam ID만 Pages/Worker 공개목록에서 제외해 신규 진입을 차단한다. 기존 학생 기록과 나머지55개 범위는 보존한다. 설정은 해당 plain scope만 patch하고 마스킹된 Secret 전체를 전송하지 않는다.

DB 복구가 필요하면 최신 runtime과 예약 상태를 먼저 읽고 위 루트의 `batch-b/owner-sql/rollback.sql` → `batch-a/owner-sql/rollback.sql` 순서로 제한 적용한다. 해당12개 신규 runtime case와 PDF SELECT만 제거하며 리뷰/학생기록은 유지한다. Registry 등록을 삭제하지 않는다. 기존 인문2024수시2교시 정책은 신규12개 rollback 대상이 아니다.

전체 배포 복구가 필요하면 이전 Worker `fafe9380-2af4-4bca-8fb6-9a370c9f3f48`, WEB `fd558454-b9bd-4bae-8078-3ac307353428`와 공개scope55를 함께 맞춘다. 이전코드 cap64에 현재68 scope를 넣지 않는다. 성균 PDF manifest 수정은 이전WEB에 없으므로 한양만 차단하고 현재WEB를 유지하는 최소복구를 우선한다. 진행 중 요청/기존 성공 결과는 삭제하거나 재평가하지 않는다.

## 로컬 배포 자료 무결성

- `registry-worker.private.json` SHA256 `c8e6890f9d1571627d2c07e7675f6a6bb57ea446a73c56e83a5e8fa7c7099bda`.
- `deployment-result.json` SHA256 `5abdb8df55b12e5b705fca388b046522575adee4802a059b8a26297c2cd160a7`.
- `production-current.json` SHA256 `74d5ecf9f872b0ee9c8be95bd5a7a5d0529784f3bfb2d6d1b1910f68cd895381`.

`deployment-result.json`의 web_deployed=false는 Worker단계 시점 영수증이다. 이후 완료 상태는 `production-current.json`과 위 canonical API 재조회가 우선한다. Secret·JWT·학생답안 원문을 Wiki/인수인계에 복사하지 않는다.
