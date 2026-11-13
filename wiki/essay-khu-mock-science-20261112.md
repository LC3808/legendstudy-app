# 경희대 모의 4문항 및 과학 18문항 연결

Owner 2026-11-12 후속 개발 지시. 이화 87문항 DONE/CLOSED 유지. Provider 호출 및 AI 품질 평가 금지.

## 경희대 2022 모의 — DONE

- 기존 1시험·4문항 Registry ID 유지. 공식 문제 3쪽·해설 7쪽 원본 불변.
- 해설 7쪽의 문항별 설명을 분리하고 서비스 평가 요소를 명시. 공식 수치 배점 생성 없음.
- 운영 migration `20261112114857_khu_mock_4_service_connections_public`, 2026-11-12 20:49:47 KST COMMITTED.
- 기존 Math 스키마 46행 및 private Worker source 4행. 새 Registry/RPC/Storage 정책 0건.
- 사전 18개·사후 24개 PASS. 기존 데이터·함수 identity/ACL·RLS·Credit·private history 보존 검사 PASS.
- 기존 공개 Math 432 leaves 보존, 현재 436. 확장 범위 공개 **269**, 잔여 **39**, 전체 **308**.
- 격리 PostgreSQL 실제 기존 RPC의 제출·결과·재작성·재첨삭·계정 격리 44개 검사 및 비파괴 원복 PASS. 합성 출력만 사용.
- WEB 계약 17 PASS, Native PDF 계약 3 PASS(원본 bytes/hash 포함), WEB build PASS.
- WEB 배포 `b791314f-359a-4f89-938e-e4e2be2d2341`; source `f2aa5e66f9997424dd6dd4eed068598b2d2ec170`.
- 운영 HTTP catalog IDs/DB 공개 mapping/배포 scope 사후 검사 PASS. 기존 비논술 static asset 2,209개와 Preview/기타 설정 보존.
- 기존 PDF 인증 사용자 읽기 1건, 익명 읽기 0건 확인.
- 실제 브라우저 로그인 제출·실기기·AI 품질: **NOT TESTED**. Provider 호출 **0**.
- 원복은 새 4 leaves admission만 닫고 기존/신규 결과·원본·설정 이력 유지. 격리에서 검증, 운영 실행하지 않음.

증거: `../supabase/candidates/khu_mock_science_20261112/`의 `math-isolated-results.json`, `production-application-receipt.json`, `public-postflight.json`, `math-rollback-admission.sql`.

## 과학 18문항 — 운영 연결·공개 DONE

- 경희대 물리 4·화학 4·생명과학 4, 서울여대 생명과학 3·통합과학 3. 기존 5시험·18문항 ID 유지, 동일 시험의 기존 수학 4문항도 보존.
- `science-reasoning-v1` / `SCIENCE_REASONING` 명시. 기존 reviewed Worker와 Essay 1.3 결과·재작성 계약 재사용. 과학을 Math로 우회하지 않음. 공식 평가 설명/예시답안과 서비스 평가 요소를 구분하며 임의 공식 배점 생성 없음.
- migration `20261113013507_science18_reviewed_runtime_public`, **2026-11-13 10:40:29 KST** COMMITTED. 사전9·사후7 PASS.
- 최초 사전검사에서 경희대 기존 review2/revision2행을 발견해 미적용. 기존 두 revision 1을 보존하고 review만 revision 2로 전진하도록 후보 수정 후 격리 재검증. 신규 documents4/review3/revision5 =12행, 기존 review2행 revision 전진. 기존 revision2행 불변.
- 기존 submit/preflight/cycle 3함수는 허용 유형에 science만 추가, runtime_policy는5시험만 추가. 나머지358함수 body, 전체362함수 identity/ACL, RLS274, relation127, private history13테이블 보존. 기존229 runtime/436 Math leaves 보존. Registry 공개 플래그 변경 없음.
- 공식 원본13개 확인. 기존9개 재사용, 누락된 서울여대4개만 private bucket에 업로드·다운로드 SHA256 일치. 원본 파일 변경0/Storage정책 변경0. 인증 역할 문제PDF7개 읽기, 익명0개, 신규 내부원본4개 일반사용자 읽기0개. 기존 정책에서 보이던 원본1개는 그대로 보존(신규 권한 확대 아님).
- Worker `27c67e48-5526-46a6-a7e8-1aab3218016e`, 기존68모듈 보존. 공개scope228→233. 새 독립 서비스/평가 모델/프롬프트 전면 교체 없음.
- WEB Pages `68e2172b-802d-4d07-ad6a-0aa205824cd7`, source `f99135ce02abe67c8d0af3152872026ac2297760`. 기존 비논술 static2,212개·API소스·설정 보존. 기존 scope 유지하며 public364→367/beta194→197/Math436 유지.
- 운영 HTTP 공개catalog5시험22 entries(과학18+기존수학4), 실제 DB preflight5, package digest/Registry ID/기존Math/배포구성 일치 PASS. 임의 캐시 query 조회403 후 정규 공개 URL HTTP200 확인.

## 검증 범위

- 격리 PG17: 정확한 적용 SQL·5 package digest·기존 revision2개 보존·기존229정책 보존·중복 적용 차단·기존 run 존재 시 차단·비파괴 원복 반복 실행 PASS.
- 격리 공통 Ledger/History 실제 RPC fixture: science 유형 제출·결과 저장·계정 격리·lease/idempotency·Credit1회·포함 재첨삭·원답안/기록 보존 PASS. 운영 RPC 전체 E2E와 구분한다.
- 실제 18개 package/Worker 계약: 정상·오답·부분답안 합성 출력/재작성 parent/결과 ID·hash 검증 PASS. AI 정답률/품질 판정 아님.
- 공통 Worker 회귀 **45 PASS** (기존 package/worker/material/execution/staging 및 신규 science 포함).
- WEB 계약 **62 PASS**, production build PASS. Flutter 결과·복원·Credit·history/PDF 회귀 **19 PASS / 5 SKIP**(환경 의존 원본 PDF 검사 등). 과학 전용 Native 매핑2 PASS. Flutter Native UI 재사용, WebView/스토어 배포0.
- 실제 브라우저 로그인 제출·결과·재첨삭, iPhone/Android 실기기, 실제 Provider 및 AI 품질: **NOT TESTED**. Provider 호출 **0**.

## 원복

신규 WEB scope를 이전값으로 복원하고 이전 Pages `b791314f-359a-4f89-938e-e4e2be2d2341` 재활성화 → Worker 이전버전 `c3795154-697d-4448-a044-c0dbfcc05150` 복원 → `essay-rollback.sql`로 해당5 runtime admission만 닫는다. Worker/Pages는 동시 변경이 없는지 먼저 확인한다. 기존·신규 자료, revisions, 사용자 답안/결과/Credit은 삭제하지 않는다. 공통 science 유형 파서는 이미 수락된 이력 보존을 위해 남긴다. DB 원복은 격리에서 검증했으며 운영 원복은 미실행. 새 private object4개도 보존한다.

## 통합 집계와 Owner 검수

**기존265 + 경희모의4 + 과학18 = 공개287 / 잔여21 / 전체308.**

[Owner287 전체 문항·공식자료·화면 연결](../supabase/candidates/khu_mock_science_20261112/owner-integrated-review-287.json) · [잔여21 문항별 사유](../supabase/candidates/khu_mock_science_20261112/remaining-21.json).

잔여: 성균관대15 Owner HOLD, 한국항공대5 공식 불일치 HOLD, 숭실대1 공식 배점 불일치 HOLD. 이번 작업에서 미해결 기술 연결0. 중앙대 과학11은 기존308 분모 밖 HOLD 유지. 이화29시험87 DONE/CLOSED와 기존 공개265·사용자 데이터 보존.

검수 경로: 기존 https://lab.legendstudy.com/essay-lab/ → 대학·시험·문항 → 답안 → 기존 결과 → 재작성·재첨삭. Owner 통합 AI 품질 검수는 별도다.

증거: `science-production-receipt.json`, `science-public-postflight.json`, `science-pdf-access.json`, `science-storage-upload.json`, `essay-sql-validation.json`. Git source WEB f99135c / APP 이 문서를 포함하는 최종 커밋. 원본 private package와 적용 SQL은 `.local` 및 운영 migration ledger에 보관하고 공개 Git에는 원문을 포함하지 않는다.
