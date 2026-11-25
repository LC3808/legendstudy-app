# 관리자 복구 응답 실패 원인과 최소 패치 — 2026-11-22

**DONE — 원인 재현·최소 WEB 코드 수정·테스트·운영 배포. 실제 학생 복구 재실행 NOT TESTED/미실행.** [이전1회 실패](admin-run-recovery-execution-20261122.md)와 [운영 설치](admin-run-recovery-deployment-20261122.md)를 계승한다.

후속: WEB 경로를 통과한 뒤 드러난 별도 운영 transport 결함은 [런타임 수정·운영 진단](admin-recovery-runtime-fix-20261122.md)에서 해결했다. 아래는 앞선 WEB 경로 누락의 원인 기록이다.

## WEB API → Worker → DB 조사

1. UI는 진단 후 `POST /api/admin/essay-run`에 `action=recover`·원 요청/작업 key·진단 token·allow_uncertain을 보낸다.
2. WEB API는 기존 관리자 JWT로 `admin_lab_run_recovery`를 먼저 조회한다. 이 진단은 읽기 전용이다.
3. API가 `reviewedWorkerBinding.fetch('/admin-exam-recover')`를 호출하지만, **공통 어댑터의 허용 경로 배열에 `/admin-exam-recover`가 없었다.** Cloudflare service binding 경로와 origin fallback 경로 모두 누락됐다. `INVALID_WORKER_REQUEST`가 실제 Worker 호출 전에 발생하고, API의 catch가 이를503 `REQUEST_UNCERTAIN`으로 바꾼다. UI가 이를 응답 불확정으로 표시했다.
4. Worker에는 이미 `/admin-exam-recover` 처리가 설치돼 있으며, 원 JWT로 관리자 진단→`admin_lab_recover_run`→저장 결과 검증→finish/queue 계약을 사용한다. 이번 실패는 이 단계 진입 전이다. 별도 Worker 코드/환경 변경 불필요.
5. DB 복구 함수 signature·원 JWT 권한·원자적 intent/fence 계약은 설치된 소스와 일치한다. 대상의 복구 감사0·새 attempt0·재시도0은 Worker 호출 이전 실패와 일치한다. 진단상 `PROVIDER_NETWORK_UNKNOWN`은 과거 q1 오류이며 이번 WEB 제출 오류의 원인이 아니다.

**재현 근거:** 기존 실제 배포에 사용한 compiled Pages bundle로 합성 요청을 실행하면 DB 진단 stub1회 후 Worker stub0회,503 `REQUEST_UNCERTAIN`. 수정 bundle은 동일 입력에서 DB1회→Worker1회, Worker의409 `ACTIVE_LEASE`를 그대로 반환한다. 외부 네트워크/실학생 실행0. [번들 전후 실행 증거](evidence/admin-recovery-binding-bundle-test-20261122.json). 과거 실제 HTTP 추적 로그를 새로 확보한 것은 아니며, 배포 소스·실제 번들의 결정적 재현과 DB 상태를 근거로 한다.

## 최소 수정 및 검증

WEB `src/lib/essay-runtime/server/worker-binding.ts` 두 허용 경로에 승인된 복구 endpoint만 추가(런타임 변경2줄). 관리자 검증·Origin/POST 제한·JWT·서비스 credential·redirect 거절은 그대로다. 부분 재생성/새 상한·Worker·DB·평가 기준·인용 검증·원장 로직 변경0.

이전 API 단위 테스트는 어댑터를 mock하여 누락을 발견하지 못했다. 새 `src/lib/admin/admin-run-binding.integration.test.ts`는 실제 API/transport/adapter를 사용하고 외부 DB·Worker 경계만 stub한다. 두 연결 방식에서 원 JWT·서비스 credential·불확정 승인 플래그 전달, DB 권한 검사 순서, Worker1회 호출, non-admin dispatch0을 검증한다.

- 수정 전 신규4검사 중2실패(503),2권한검사 통과.
- 수정 후 API·adapter·새 통합18 PASS.
- essay-runtime/server10파일101 PASS(앞의 adapter4와 일부 중복, 합산하지 않음).
- TypeScript·변경파일 ESLint PASS, Pages Functions build PASS.
- 수정 전후 실제 compiled bundle 합성 검사 PASS(원인 재현 포함).
- 실제 학생 재실행, 실제 Provider 호출, 유효 관리자 요청의 운영 Worker→DB mutation E2E는 금지 범위여서 NOT TESTED. 설치 단계의 Worker166/DB55 격리검증 이력과 현재 계약을 재사용한다.

## 운영 배포 및 데이터 보존

WEB source **4408c3e6bcba495dc83e310a2ce5380f9599bdd6**, Pages **2faad0e4-d995-4abe-8106-2557caf38400** production success. 번들 SHA256 `0fd73eb572820c7d24166ee41b36adcf70150491462f7b10c0ac58f7dc4b178f`.

빌드 입력81개 중 변경은 worker-binding.ts1개. 기존 **3,173개 정적 경로 전부 동일**, UI 정적 빌드/교체0. 운영 manifest·관리자 HTML 동일, 비로그인 API401, 전체 deployment_configs 동일. Toss LIVE/Finance Automatic 유지. 첨삭 Worker b28790b2 그대로, DB Migration0. 원복은 Pages cab719e1이나 복구 endpoint 결함이 다시 생기므로 사용 전 인지해야 한다. [배포 증거](evidence/admin-recovery-binding-release-20261122.json).

배포 구간 읽기 비교에서 고정9요청과15RPC hash 동일. 대상 q0 완료 결과·q1 attempt0·9checkpoint·billing/원장 보존, 복구 action0. [보존 증거](evidence/admin-recovery-binding-preservation-20261122.json). 실제 재실행·삭제·보관·원장 변경0.

## 재실행 준비 상태와 후속 승인

연결 경로 누락은 수정·배포됐다. 대상 `03629605-9a58-4b78-8465-c5331ac1b1c7`은 완료 q0보존·미완료 q1응답불확정, included_revision·추가 이용권0·원장0·잠금만료 상태다. 새 시도 생성 시 fence를 함께 기록하는 기존 계약을 유지한다. 실제 복구 성공을 미리 보장하지 않는다.

**추가 실제 재실행은 별도 Owner 승인 후에만 수행한다.** 승인 시 관리자 화면을 새로 열어 최신 진단을 확인하고 미완료 문항1개만 복구한다. 이전 실패 때의 “이전 복구 요청 결과 확인” 버튼은 POST 재전송 경로이므로 이번 조사에서 누르지 않았다. 부분 재생성과 신규 재시도 상한은 계속 비활성이다.
