# 관리자 첨삭 복구·완료 — 2026-11-22

현재 운영: Owner 승인으로 DB·WEB·Worker 설치 및 실제 관리자 진단 완료. 실제 재실행0, 신규 품질정책 비활성. [배포·검증·추가 승인](admin-run-recovery-deployment-20261122.md). 아래 설치 전 상태는 구현 당시 이력이다.

상태: 구현·격리 검증 DONE / 운영 DB 설치·WEB/Worker 배포 BLOCKED(별도 승인 대기), 실제 학생 복구 NOT TESTED. 기존 [안정성 점검](essay-lab-stability-20261122.md)의 분석·최소 패치 운영 배포를 완료한 뒤 이어서 수행한다. [관리자 요청 관리](admin-lab-run-management-20261120.md), [보관의 운영 제외](admin-archived-run-operations-20261120.md), [장기 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 계승한다.

후속: [E 불확정 복구·부분 재생성·상한 구현과 새 설치 hash](essay-quality-followup-20261122.md). 기존45검사는 최초 후보 이력이며 최신 확장 SQL은55검사·별도 승인 대상이다.

## Owner 지시 및 경계

실제 결과·문항 상태를 검증하여 정상 완료를 지원한다. 상태만 completed로 바꾸는 강제 완료는 금지한다. 기존 Worker·Provider·평가 기준과 프롬프트, 학생 답안/결과/이용권/Credit Ledger를 재사용·보존한다. 이미 완료된 문항 재평가, 이용권 추가 차감, 정상 실행 강제 중단, 응답 불확정 실행의 나이 기반 탈취는 하지 않는다.

구현·자동화·격리 검증과 Git/Wiki 갱신은 승인됐다. 신규 Migration은 별도 준비하고 AGENTS §4에 따라 Owner 설치 승인을 받아야 한다. 승인 전 운영 DB 변경 및 그 변경에 의존하는 WEB/Worker 배포는 하지 않는다. 실제 학생 요청은 테스트하지 않으며 운영 설치 후에도 Owner가 관리자 화면에서 명시적으로 실행한다. 실제 결제·환불은 제외한다.

## Seven preservation answers — storage 결정 전

1. 최초 생성·원 실행·lease·retry·복구 요청/실행/완료 시각을 분리한다. 미기록 마지막 상태 변경 시각은 NULL/기록 없음으로 표시한다.
2. snapshot·답안·완료 문항·검토/사용량 영수증·기존 final을 근거로 사용한다. Provider 성공 로그만으로 결과를 복원하지 않는다.
3. 완료 결과를 덮어쓰지 않는다. 기존 append-only 관리 감사와 retry 이력을 우선 재사용하고, 새 실행/완료도 기록한다. 원장 직접 UPDATE/DELETE 없음.
4. 기존 run/account/auth.users identity를 유지한다. 관리자 JWT는 그대로 검증하며 학생으로 위장하지 않는다.
5. 복구는 운영 Decision이며 학생 Learning 평가나 입시 Outcome을 새로 정의하지 않는다. 검증된 기존 평가 결과만 재사용한다.
6. 기존 관리자 권한과 최소 식별정보를 사용한다. 로그에 답안·Provider 원문·credential을 복제하지 않고 새 공개 데이터나 장기 보관 정책을 만들지 않는다.
7. 완료·장시간·복구 성공은 서버 근거의 파생 지표다. 큐 접수를 성공으로 세지 않고 실제 완료를 확인한다. Worker 상태 불명확과 현재 실행을 구분한다.

## 구현 계약

- 진단: `admin_lab_run_recovery(p_run)` — 읽기 전용, 관리자 권한, 문항/lease/원장/최근 오류/차단 이유/진단 token 제공.
- 실행: `admin_lab_recover_run(p_run,p_key,p_diagnosis_token)` — account→run→billing 잠금, 최신 상태 재판정, stale 진단/활성 실행/보관/이미 완료/불확정 원장 차단, 멱등 작업 키.
- WEB: 기존 `/api/admin/essay-run`에 recover action 추가, Worker `/admin-exam-recover`로 원본 관리자 JWT 전달. 클라이언트는 복구 유형/학생 identity/결과 payload를 선택하지 않는다.
- A/D 공통 2단계: 관리자 실행 RPC가 감사 intent를 준비한 뒤 Worker-only `essay_exam_recovery_context(p_key)`로 frozen claim/parent/checkpoints를 읽는다. Worker는 기존 `prepare_claimed_material`·claim digest·durable 결과 검증을 순수 재사용하고, `essay_exam_recovery_finish(p_key,p_diagnosis_token,p_result,p_proof)`가 잠금 안에서 intent·같은 상태·문항별 동등성을 다시 확인하여 기존 finish를 호출한다. Provider 객체/호출0. 과거 검토 영수증의 당시 검증 통과 사실을 재사용하며 현재 시각으로 만료된 HMAC을 재검증하여 과거 정상 결과를 무효화하지 않는다.
- A: 검증된 N/N final을 기존 finish로 완료. Provider 호출0.
- B/C: 완료 문항과 확정 실패 문항의 원래 claim/결과 무결성도 같은 Worker 2단계 검증으로 확인한 뒤, 확정 실패 문항만 기존 retry로 실행한다. 0/N 실패의 빈 결과는 재시도 증명에만 허용하며 완료 처리에는 허용하지 않는다. 기존 완료 문항과 예약 유지, 새 이용권 예약/추가 차감0.
- D: durable reviewed 결과·usage·identity가 검증된 pending 문항은 원래 writer/token의 기존 checkpoint write로 복원한다. 다른 확정 실패 문항이 있으면 같은 DB 트랜잭션에서 기존 retry를 생성하며, 실패하면 둘 다 rollback한다. N/N 결과가 검증되면 pending summary/final 원문을 바꾸지 않고 결정적인 요약 조립 및 기존 finish로 완료할 수 있다. 복구 가능한 artifact 없이 응답 여부 불명확한 문항은 차단한다.
- 진단에서 실행까지 상태가 바뀌면 새 확인이 필요하다. 큐 접수/복구 중/실제 완료/차단을 구분한다.

## 현재 운영 요청의 적용 한계

기준 요청 `03629605-9a58-4b78-8465-c5331ac1b1c7`는 q0 완료·q1 reconciling, q1 결과/영수증 없음, PROVIDER_NETWORK_UNKNOWN이다. 새 기능이 설치되어도 이 증거 상태에서는 자동 재실행·강제 완료를 허용하지 않는다. 실제 데이터 변경0을 유지한다.

## 구현·검증·설치 패키지

[SQL 승인 패키지](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/admin_run_recovery_20261122/README.md) · [install.sql](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/admin_run_recovery_20261122/install.sql) · [사후 검사](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/admin_run_recovery_20261122/postcheck.sql) · [원복](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/admin_run_recovery_20261122/rollback.sql).

대상 프로젝트 `stlhijzpjfgwwdgunlsd`, 후보명 `20261122064411_admin_run_recovery_20261122.sql`. 운영 migration history에 아직 등록하지 않았다. 설치 SHA256 `9187578017e5f4982bd5834800e6fba54f0e089867f3becf70ef3c23d047fb2c`.

신규 함수12개(관리자3/Worker2/private7)와 기존 감사 action 제약 확장만 준비했다. 기존 핵심 RPC10개 정의·owner·ACL 및 checkpoint 제약3개 preimage를 설치 전에 검사한다. 신규 테이블·학생 backfill 없음. 16:06 KST 운영 읽기 검사에서 기존 source/ACL/owner/제약 동일, 신규 RPC 미설치를 확인했다.

승인 후 순서: 기존 데이터 count/hash·실제 프로젝트·preimage 재확인 → 단일 트랜잭션 install → postcheck/권한/보존 검사 → 검증된 운영 사본 기반 Worker 최소 패치 → WEB → 읽기 전용 운영 UI 검증. 실제 학생 복구는 자동 실행하지 않는다. 원복은 WEB/Worker 이전 버전 복원 후 guarded rollback; 복구 감사가 이미 있으면 감사 vocabulary를 유지하고 과거 결과·원장을 되돌리지 않는다.

## 테스트 결과 및 한계

- 격리 PostgreSQL17 **45/45 PASS**: 실제 운영 RPC/auth 정의와 합성 데이터, 실제 SQL→Python 검증기→Worker adapter→SQL finish/replay 통합. [DB 결과](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/admin_run_recovery_20261122/result.json).
- 운영 bdee88d0 사본 후보 **145/145 PASS**, Provider 호출0, 변경4+신규1모듈 외 기존40개 source 및32 vendor 보존. 소스 환경51회 중50 PASS/1 SKIP은 소스에 없는 운영 retry_feedback 때문이며 운영 사본에서는 해당 검사 PASS. [Worker 증거](evidence/admin-run-recovery-20261122-worker.json).
- WEB **2,246 PASS/5 SKIP**, TypeScript·변경파일 ESLint·171페이지 build PASS. 기존 boundary audit 실패2건은 관련 입력이 변경 전 HEAD와 byte 동일해 별도 미해결로 기록한다. [WEB 증거](evidence/admin-run-recovery-20261122-web.json).
- 실제 React 합성 화면: 데스크톱·390px 모바일 확인창/대상 문항/추가 차감0/큐 접수≠완료/활성 잠금 차단 PASS. 운영 API 미연결. 실제 결제·Provider·학생 복구 E2E 미실행.

| 요청 시나리오 | 격리 검증 |
| --- | --- |
| 1 결과0/N | 확정 실패만 기존 retry, 빈 결과 강제 완료 차단 PASS |
| 2 일부 완료 | 기존 완료 보존·실패 문항만 retry PASS |
| 3 N/N 상태 전환 | 기존 finish·Provider0·정산1회 PASS |
| 4 Provider 후 저장 실패 | durable reviewed 복원 및 미검증 결과 차단 PASS |
| 5 잠금 만료 | 확정 실패 허용/불확정 출력 없음 차단 PASS |
| 6 정상 실행 | 활성 lease 차단 PASS |
| 7 중복 복구 | 동일 키 canonical replay PASS |
| 8 동시 관리자 | 잠금·digest 재검증·한 번 정산 PASS |
| 9 자동 retry 충돌 | generation 한 번 증가 PASS |
| 10 중복 차감 | 기존 Apple/purchase 합성 grant·예약 보존 PASS |
| 11 중복 저장 | late checkpoint·기존 결과 불일치 차단 PASS |
| 12 기존 결과 보존 | 부분 결과·pending aggregate·rollback PASS |
| 13 관리자 | 실제 require_admin/auth 계약·권한 회수 PASS |
| 14 일반 회원 | 직접 RPC/API/private context 접근 차단 PASS |
| 15 학생 결과 화면 | 기존 결과 계약·WEB 회귀 PASS; 복구된 운영 학생 화면 E2E NOT TESTED |
| 16 KPI | 실제 완료 귀속·관련 목록 새로고침·보관 제외 PASS |

DB 격리 fixture는 관련 운영 RPC를 사용하지만 모든 결제 trigger를 복제한 전체 운영 DB는 아니다. Apple/Toss 실제 결제 E2E와 운영 학생 결과 화면은 이 결과로 검증했다고 주장하지 않는다. 실제 학생 action/운영 DB 쓰기/결제·환불·원장 변경0. 기존 상태는 [직전 안정성 점검](essay-lab-stability-20261122.md)의 보존 증거와 이번 read-only preflight를 구분한다.

## 인계·승인 경계

WEB 기존 요청 관리 화면에 진단→최신 상태 재확인→확인창→실행→동일 화면 결과/재조회 구현. 대시보드는 전체 기간 확인 대상과 선택 기간 실제 복구 완료를 분리한다. Flutter 변경·스토어 출시 없음.

이번 소스 Commit·Push는 운영 배포를 뜻하지 않는다. 운영 DB/WEB/Worker는 아직 이전 버전이며 새 버튼의 운영 확인은 승인 후 수행한다. Owner에게 요청할 범위는 위 정확한 SQL 설치와 사후검증 통과 후 WEB·Worker 배포이다. 기존 요청 복구·재진행·삭제·보관·결제·환불은 포함하지 않는다.

참고: 이번 작업은 Supabase client/CLI 업그레이드 없이 기존 RPC 권한 계약을 재사용한다. [공식 DB function 권한 지침](https://supabase.com/docs/guides/database/functions)과 [변경 이력](https://supabase.com/changelog.md)을 확인했다. 운영 branch merge나 Flutter v3 업그레이드는 범위에 없다.

## 추가 보존·권한 검토

실운영 `require_admin`과 `admin_operator`를 읽기 전용으로 확인했다. 최초 요청은 auth.uid와 JWT sub 일치, authenticated role, 만료되지 않은 exp, 기존 admin_users 및 계정 허용을 검사한다. Worker 두 번째 단계는 준비된 관리자 intent와 그 actor의 현재 권한·계정 상태를 검사하며 caller를 다른 학생/관리자로 바꾸지 않는다.

수학·혼합형 저장 결과는 인문형 검증에 강제로 맞추지 않는다. 기존 MixedMathWorker의 성공 결과 guard를 동일 동작의 순수 함수로 분리하여 원 실행과 복원이 함께 사용한다. 새로운 수학 평가 기준이나 Provider 호출을 추가하지 않는다.

예약 이력과 현재 잔류 예약을 분리한다. 정상 완료/반환 원장을 복구 대상이 아니라는 이유만으로 오류로 표시하지 않는다. 복구 성공은 실제 완료와 그 작업의 최신 retry generation 귀속으로 판정하며, 과거 실패한 복구 후 다른 학생 재시도로 완료된 회차를 잘못 귀속하지 않는다.

원본 운영 runtime에는 Git HEAD보다 최신 retry_feedback 등이 있으므로 전체 소스로 덮어쓰지 않는다. 기존 bdee88d0 모듈을 검증한 preimage에서 필요한 변경만 적용하는 재현 도구를 저장소에 함께 준비한다. 운영 설치·배포는 별도 승인 전까지 실행하지 않는다.
