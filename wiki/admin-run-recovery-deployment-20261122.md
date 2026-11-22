# 관리자 첨삭 복구 운영 설치·배포 — 2026-11-22

상태: **DB·WEB·Worker·관리자 진단 DONE**. 실제 학생 재실행 및 새 부분 재생성/재시도 상한 활성화는 **NOT TESTED / 승인 제외**.

후속: [Owner 승인1회 실제 제출·응답 실패·보존 확인](admin-run-recovery-execution-20261122.md). 아래 승인 제외는 설치 당시 범위다.

## 승인과 적용 범위

Owner가 APP/SQL/Worker `5cf2f4ba610fe834c3955dbbfc000f644b3971ed`, WEB `75397907eba9ff1f7c2e68382db0f0714a68bd79`를 기준으로 운영 설치·배포·진단을 명시 승인했다. AGENTS §4 기본 직접 적용 절차의 설치 승인을 이번 지시로 확인하고, 준비된 SQL을 변경 없이 적용했다. 기존 요청 상태·결과·원장 변경, 학생 재실행, 부분 재생성/새 상한 활성화, 결제·환불은 제외했다. [기존 계약과 7개 보존 검토](admin-run-recovery-20261122.md), [후속 구현·검증](essay-quality-followup-20261122.md)을 계승한다.

## DB 설치 및 권한 — DONE

- 프로젝트 목록에서 **LegendStudy / stlhijzpjfgwwdgunlsd / ACTIVE_HEALTHY** 확인. 다른 프로젝트 접근 없음.
- [설치 SQL](../supabase/candidates/admin_run_recovery_20261122/install.sql) SHA256 `c52fb2c42b8a88264f671b78629a1fc89c4307b0d66e0015c1f62cd32676db50`, 실제 migration version `20261122115251` / name `admin_run_recovery_20261122`.
- 기존 함수·ACL·소유자·체크포인트 제약 충돌 방지 검사를 통과했다. 신규18함수, 보호 트리거3개 설치. [postcheck](../supabase/candidates/admin_run_recovery_20261122/postcheck.sql) PASS.
- anon 진단 EXECUTE 없음, authenticated Worker finish EXECUTE 및 private schema USAGE 없음. 관리자 신원 없는 authenticated 역할의 진단 호출은 `42501 ADMIN_REQUIRED`. 실제 로그인 관리자 UI의 진단 성공.
- 실제 일반 학생 계정 로그인으로 API 우회를 시도하지 않았다. 격리 DB/Worker/UI 권한 테스트, 운영 ACL 및 관리자 gate, 운영 비로그인 API401을 확인했다.
- 품질 정책 checkpoint 0개, 복구 action 0건. 새 상한 트리거는 정책 marker가 없으면 적용하지 않으며 품질 기능 flag도 비활성이다.

## Worker 배포 — DONE

운영204cfb37 기반 실제76모듈에서 승인된7개 변경·2개 추가, 기존69모듈 byte 보존. source 전체 덮어쓰기가 아닌 검증된 후보 사용. 버전 **b28790b2-3949-4ee3-ae59-96d3a9712bf4**, deployment `cff622d9-53da-4480-b7d8-0b34c2b8f8c2`, 100%. 다운로드한78모듈 모두 후보 hash 일치. binding·compatibility·CPU·queue 설정 불변. `ESSAY_QUALITY_REPAIR_ENABLED` 없음으로 false, 부분 재생성과 신규 상한 자동 정책 미활성. [배포 증거](evidence/admin-recovery-worker-release-20261122.json).

## WEB 배포 — DONE

Pages **cab719e1-aeb1-4639-89cf-85fb5baaa51c** success/production. `/admin/essay-runs/` 정적파일5개 및 신규 해시 자산13개를 적용하고 기존 다른3155경로를 보존했다. API 빌드 입력81개 중 변경은 승인된 `functions/api/admin/essay-run.ts` 한 개뿐이다. lockfile·라우팅·환경설정 보존. API bundle SHA256 `4729665ce5f151a4db0996d8d9521d6b4ed0c2e66e902c2314e2ad4228c9b676`.

운영 manifest 일치, 실제 `lab.legendstudy.com/admin/essay-runs/` HTML 일치, 비로그인 API401 확인. 첫 빌드는 공개 인증 환경이 없어 배포 전 검사에서 거절했고, 운영 공개 설정을 주입해 다시 빌드한 뒤 검사 통과본만 배포했다. PAYMENT_MODE=LIVE, PAYMENT_FINANCE_AUTO=true 및 전체 deployment_configs 불변. 실제 결제·환불·Finance 강제 갱신은 실행하지 않았다. [WEB 증거](evidence/admin-recovery-web-release-20261122.json).

## 대상 요청 진단과 복구 준비 — DONE

`03629605-9a58-4b78-8465-c5331ac1b1c7`, 경희대 2027 모의논술 사회계 무료 재첨삭. 운영 관리자에서 요청 목록 → **첨삭 복구·완료**를 열어 진단만 조회했다(11/22 20:56 KST).

- 완료 q0 1문항은 검토 완료 checkpoint에 보존. q1 1문항은 `PROVIDER_NETWORK_UNKNOWN`, 응답 불확정. 복원 가능한 저장 응답 없음.
- 원 요청 11/22 01:31 KST, 잠금 만료 01:46 KST. 재시도0. 기록되지 않은 마지막 실행/상태변경 시각은 기록 없음으로 표시.
- 필요 이용권0, 현재 예약잔량0, 원장0, 정합성 true. `included_revision` 무료 재첨삭 정책에 부합하며 원장 변경 불필요. billing 상태 문자열 reserved는 양수 이용권 잔류를 의미하지 않는다.
- 일반 복구 버튼 비활성, **Owner 승인 후 불확정 문항만 재실행** 경로 표시. 두 실행 버튼 모두 클릭하지 않았다. 복구 이력0.
- 이전 실행 차단 트리거는 설치됐고 격리 검증을 통과했다. **이 요청의 이전 attempt 차단 기록은 아직 만들지 않았다.** 별도 승인 후 실제 복구의 원자적 새 attempt 생성 시 차단 기록을 함께 남기므로 지금 이미 이전 실행을 취소했다고 해석하면 안 된다.
- 승인 후 예상 과정: 최신 진단 digest·권한·잠금 재검사 → q0 기존 결과 전체 검증/보존 → q1에만 새 generation 및 이전 attempt fence 기록 → 기존 큐로 q1 실행 → 전체 완료 결과 검증·저장. 새 증거/정상 실행이 발견되면 차단. 기존 Provider 실제 과금 여부는 불확정이며 재실행은 추가 AI 비용을 유발할 수 있다.
- 연결된 최초 첨삭의 두 문항 결과를 관리자 읽기 전용 화면에서 정상 조회했다. 최종 run 결과0/2와 checkpoint 완료1/2는 저장 단계가 다른 수치이며 임의 완료하지 않았다.

## 테스트·보존 및 한계

준비 SQL의 격리 PostgreSQL55검사 PASS 이력을 재사용했고, **실제 배포 후보166검사**를 재실행해 PASS. WEB 기존2252 PASS/5 SKIP·후속35 PASS 이력 및 새 Webpack build PASS. 운영 설치후 source/ACL/trigger 검증·인증 관리자 진단·기존 결과 표시 PASS. 실제 학생/Provider 실행 없이 중복 저장·완료 보존·권한·동시 실행은 격리 테스트로 검증했다. [실행 테스트](evidence/admin-recovery-runtime-tests-20261122.json), [운영 설치·UI](evidence/admin-recovery-install-verification-20261122.json).

설치 직전→직후→배포 후 **기존 고정9요청 및 15RPC**의 행/답안/결과/checkpoint/retry/연결 billing·ledger/보관 hash가 일치했다. 운영 전체 테이블의 모든 행을 사전·사후 전수 비교한 것은 아니다. DDL에 기존 학생·결제 데이터 DML 없음, 실제 복구/재진행/삭제/보관/원장 변경0. [보존 증거](evidence/admin-recovery-deployment-preservation-20261122.json).

실제 학생 재실행, Provider 과금·성능 개선 실측, 학생 계정 실로그인 우회, LIVE 결제/환불 실거래, Finance 갱신 실행은 NOT TESTED. 설정 보존과 해당 코드 입력 불변을 확인했다.

## 원복 및 다음 승인

WEB 원복 baseline `e55b4622-d23a-4c56-9dcd-90d7a66a4e59`, Worker 원복 `204cfb37-0b73-4f33-9f6c-86efc178539c`. 원복 시 adapter를 먼저 되돌리고 [guarded rollback](../supabase/candidates/admin_run_recovery_20261122/rollback.sql)을 검토한다. 실제 fence/품질 policy가 사용된 후에는 SQL 제거가 차단되므로 forward fix가 필요하다. 이번 검증은 통과해 원복하지 않았다.

남은 승인은 **대상 q1 실제 재실행**과 **부분 재생성·신규 상한 활성화**이며 별개다. 신규 DB 설치 추가 승인은 필요하지 않다. 본 배포는 Flutter 변경/스토어 제출을 포함하지 않는다.
