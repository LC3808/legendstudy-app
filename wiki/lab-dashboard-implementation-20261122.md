# 논술 LAB 대시보드 개편 — 2026-11-22

상태: PHASE 1 구현·자동화·운영 배포·실제 관리자 브라우저 검증 DONE. PHASE 2 분석 DONE / 자동성·과금 정확액·과거 Worker 실행 로그 PARTIAL.

## 기준·Owner 결정

Claude `d9c856b`의 [설계 원본](https://github.com/LC3808/legendstudy-lab/blob/d9c856b063219621b33785ebc5b38b6ad4937c99/wiki/lab-dashboard-ux-redesign-20261122.md)을 채택한다. 기존 [기간·운영 관리](admin-lab-run-management-20261120.md), [보관 제외](admin-archived-run-operations-20261120.md), [운영 안정성 조사](essay-lab-stability-20261122.md), [복구 계약](admin-run-recovery-20261122.md)을 재사용한다. UI만 WEB 배포 승인, 신규 DB는 별도 승인. 실학생 재진행·삭제·보관·원장 변경0.

## 보존 검토 7문항

1. 요청·완료·재시도 발생·조회 시점을 분리한다. 경과 시간은 새로고침 시점 기준이다.
2. 기존 RPC의 원본 요청/완료 시각·분모·현재 상태를 재사용한다.
3. 저장/UPDATE 추가 없음. 최초 답안·평가·이용권·원장을 보존한다.
4. 기존 UID·run identity와 관리자 권한을 유지한다. 목록은 UID 앞8자리 표시, 전체는 기존 상세에서 확인한다.
5. 완료율/지연 후보는 운영 파생 지표이며 학생 실력·Outcome이 아니다.
6. 추가 개인정보 수집 없음. 브라우저 합성 검증은 가짜 회원만 사용한다.
7. 기간별 모집단·현재 운영 상태·unknown/zero를 분리한다. 페이지 일부를 전체 지표로 합산하지 않는다.

## PHASE 1

- 핵심5개: 이용학생·요청·완료·완료율·평균시간. 요청/완료/실패 중복 카드 제거, 실패는 해당 조건 목록 링크로 보존.
- 완료율=선택 기간 생성 요청 중 현재 completed / 전체 요청. 8/9=88.9%. 요청0은 ‘요청 없음’, 모순/미확인은 ‘확인 불가’.
- `admin_lab_dashboard_summary` 운영 함수 확인: completed_at-created_at, 완료+유효 시각만 평균. 재시도·학생 대기 포함. 535.195초→8분55초, 8개 표본. 기존 operations success_rate=completed/(completed+failed)의100%와 분모가 달라 혼용하지 않는다.
- 출처 필터 적용 핵심 지표와 출처 무관 재시도/현재 상태를 구분. 보관 포함 기간통계·보관 제외 현재상태 유지.
- 긴 카피는 펼치는 도움말에 보존. 카드별 반복 기간을 섹션 단위로 이동.
- 최근10건 처리/경과 시간·상태 배지·회원 짧은 식별자·유형 보조정보·기존 요청 관리 링크. 미완료15분 이상은 ‘지연 확인 필요’ 후보, 중단/실패로 단정하지 않는다. 이 최근 목록은 보관 포함이며 활성 지연 KPI가 아니다.
- 기간별 전체 재시도 수는 기존 RPC 재사용. 문항별 retry_count/Worker 상태는 기존 상세 링크에서 확인하며 새집계0을 만들어 표시하지 않는다.
- 승인 대기 recovery RPC가 운영에서 호출되지 않도록 공통 영역 `recoveryEnabled` 기본false. 복구 기능 코드/계약은 보존, 설치 승인 후 명시적으로 연결한다.

## PHASE 2 — 설계 §6과 기존 조사 대조

2026-11-22 16:13 KST 읽기 전용 재확인: 최근7일 요청9/완료8/실패0/재시도12, 재시도 경험6요청, 재시도 후 완료6요청. 15:12 최초 조사와 동일하다. [요청별 시간·12사건·Provider 사용량 근거](essay-lab-stability-20261122.md).

| 항목 | 확인 결과 |
| --- | --- |
| 원인12회 | INDEPENDENT_REVIEW_NOT_ACCEPTED8 + EXACT_QUOTE4, 품질 검증 거절 |
| 자동 복구 성공 | 재시도 후 완료6은 확인. 사용자/자동 실행 귀속 미기록으로 ‘자동’ 성공 수는 미확정 |
| Provider 장애 | 위12회의 Timeout/429/5xx/Worker/DB오류 근거 없음. 응답 불확정1건은 별도이며 HTTP 상태 미기록 |
| 중복 AI 호출 | 동일 attempt 중복 실행·DB저장 실패로 재호출됐다는 증거 없음. 품질 거절 후12개 생성·9개 검토 영수증은 있음 |
| 비용 | 재시도 input388,101/output65,711tokens, 금액 UNKNOWN. 정확 추가 청구/불필요한 비용을 확정하지 않음 |
| 처리 중1건 | 03629605…: q0completed/q1reconciling, PROVIDER_NETWORK_UNKNOWN, q1 output 없음, lease01:46KST 만료·retry0 |
| 장시간 | 활성 대상1건은15분 초과 확인 후보. 완료 외대1건44분26초에는 최초retry까지33분12초 대기가 포함됨 |
| Worker | 응답 불확정 보존 상태로 안전한 자동 재시도 불가. 과거 Worker 재시작/CPU/정확Timeout 로그는 미확보 |

기존 복구 기능도 q1 durable output/영수증 없으면 차단한다. 현재 요청에 실제 복구·재진행·보관 등을 수행하지 않았다. 이전 분석 영수증은 원인 분류 근거이며 이번 화면에 과거 숫자를 하드코딩하지 않는다.

## 신규 DB 필요성·중복 방지

PHASE 1 신규 DB/RPC 필요 없음. 전체 기간 지연·잠금 만료·확인 대상·관리자 복구 성공은 준비된 [복구 SQL 패키지](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/admin_run_recovery_20261122/README.md)를 재사용하고 현재 미설치다. 날짜별 재시도 경험 고유요청·재시도 후 완료·원인 분류·목록 retry_count 상시 표시는 추가 집계 계약이 필요하다. 자동 실행 여부는 현재 자료로 확정할 수 없으므로 데이터 추가 없이 자동복구 지표를 만들지 않는다. 이번 요청은 PHASE 2 조사이며 신규 migration 설치승인을 포함하지 않는다.

## 검증·배포 경계

WEB 전체2,249 PASS/5 SKIP, 타입·변경lint·build171페이지 PASS. 완료율0/미확인, 15분 경계, 중복카드 제거, 미설치RPC 비호출 회귀 포함. 합성 브라우저320/375/390/430/768/1440px: 가로 넘침0, 모바일2열·활동카드, PC5열 PASS.

운영배포는 `/admin/`·`/admin/lab-dashboard/` HTML/RSC와 새 immutable assets만 교체한다. 기존 `/admin/essay-runs/` 및 Pages API binary·Worker·학생 화면·Toss LIVE/Finance Automatic 설정은 보존한다. 따라서 소스 HEAD의 미승인 복구 기능을 통째로 배포하지 않는다. 이전 배포 c5348617을 원복점으로 사용한다.

## 운영 적용 결과

WEB 소스 `84c3f84ac0a054ce16795f85dd7bd7e142364cd2`, Pages `e55b4622-d23a-4c56-9dcd-90d7a66a4e59` 운영 canonical 성공(16:18 KST). 기존3134경로 및 Pages API SHA256 `9361f8a2a030b889d47c5421c20a51ac584c26da9054cc9bb94199a1b55a2862` 보존. 기존 Worker 배포는 변경하지 않았다. [배포 영수증](evidence/lab-dashboard-production-20261122.json).

관리자 실제 화면: 최근7일5명/9회/8회/88.9%/8분55초, 오늘4명/5회/4회/80%/14분7초 확인. `/admin/`의 기간통계9/8/0/12 및 현재1/0/0/보관1 확인. 활동 상세 링크로 기존 요청 상세·결과 화면 연결 PASS, 변경 버튼은 누르지 않았다.

운영 브라우저는 기존75% 배율로 viewport 요청값과 CSS폭이 달랐다. 실제 CSS폭320/375/391/431/768/1440에서 document 폭 동일·가로넘침0, 모바일2열/카드 및 PC5열 확인. 로컬 합성은 정확320/375/390/430/768/1440 검증. 임시 viewport 원복 완료.

배포 전후 고정9요청·답안·결과·checkpoint·재시도·원장·billing·보관·RPC15개 source/ACL 해시 동일. [보존 영수증](evidence/lab-dashboard-preservation-20261122.json). Pages 설정/route/binding 동일, Toss LIVE·Finance Automatic 유지. 비인증 관리API401·다른Origin403, Finance비인증401, 결제runtime LIVE 확인(실제 결제0). 일반학생 별도 로그인 E2E는 미실행이며 기존 서버/권한 코드는 보존했다.

## 다음 DB 구현안 — 미설치·승인 대상 분리

추가 상시 분석이 필요하면 기존 `admin_lab_operation_stats` v1 응답에 optional 분석 필드를 추가하는 최소 확장으로 설계한다. 기존 summary·기간·권한·보관 포함 계약을 유지하고 신규 endpoint를 중복 생성하지 않는다.

- `retry_runs`: 선택 기간 retry event의 distinct run_id. 요청 생성 기간과 다르므로 명시한다.
- `retried_completed`: 위 집합 중 조회 시점 completed 고유 요청. 자동 복구라고 명명하지 않는다.
- `retry_reason_counts`: retry의 문항 attempt 직전 확정 실패 code별 사건 수, UNKNOWN 별도. 다문항 사건은 원인 복수 집계 여부를 계약에 명시해야 하며 사건수와 무조건 합계 일치시키지 않는다.
- 목록 `retry_count`는 기존 filtered RPC에 optional 필드 추가. 수치 정합성·권한·보관·KST·다문항/동시 갱신 테스트 후 정확 SQL 패키지로 승인 요청한다.
- 전체 지연/잠금/확인 대상/관리자 복구 성공은 이미 준비한 recovery operations 재사용. 최초요청15분 경과와 lease만료15분 경과는 다른 지표이며 제목·정의를 분리한다.

이번 PHASE 1에는 새 SQL이 필요하지 않아 설치 승인 요청 없음. 앞선 관리자 복구 DB 설치·활성화 승인은 여전히 별도이며 실제 학생 복구도 별도 명시 실행이다.
