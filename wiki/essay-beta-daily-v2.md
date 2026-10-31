# 베타 매일 무료 첨삭 v2 — 2026-10-31

## 상태와 Owner 결정

TASK 02 구현·격리 검증 완료 후보. **운영 SQL·캠페인·공지 게시·APP/WEB 배포 미적용. 실제 평가/Provider 호출 없음.** TASK 01 [공지 시스템](notices-system.md)과 연결한다. 기존 [베타 출처·원장 설계](essay-beta-credit-design-20261027.md), [결제 기반](payment-app-foundation.md), [장기 데이터 보존](longitudinal-learning-admissions-data-strategy.md)을 재사용한다.

Owner는 2026-11-10까지 이용, **11/11 00:00 KST 종료**를 확정했다. 기존 2 Credit/일·5~7일 캠페인·종료 후 14일 규칙을 이번 캠페인에 적용하지 않는다. 하루 1회 인문논술 시험 단위, KST 자정 갱신/미사용 이월 없음. 신규가입 3 Credit·유료 잔액 및 기존 재첨삭 정책은 그대로다. 베타 원본의 포함 재첨삭 1회만 `min(최초 완료+14일, 당시 캠페인 종료)` 적용. 경계는 배타적이며 종료 전에 접수된 요청은 종료 후 완료 가능하다.

## 실제 기준 확인

APP baseline b334c688c13b44c9a21d2fb8b4b375187fde2b9e, branch `codex/essay-evaluation-stability-p0-20261029`. WEB baseline fb7f7dfe1eef5ad7a585bcfa52322b237a82e57c, branch `codex/web-app-release-20261024`, path `/Users/woojinchang/development/legendstudy-release-20261024`. LOCAL/REMOTE 일치를 확인하고 기존 `.fvmrc`를 보존했다. 최종 SHA는 해당 변경을 담은 Git commit과 최종 보고로 확인한다.

Production `stlhijzpjfgwwdgunlsd`를 SELECT로 확인: 기존 beta 테이블/함수 설치, campaign=0, daily_grants=0. 기존 기간 CHECK는 5~7일로 새 정책과 달랐다. 8개 실제 함수 정의·owner·ACL을 후보 baseline으로 확보했다. 과거 Wiki의 설계/설치를 활성 캠페인으로 해석하지 않았다. 사용자 답안/History 데이터는 이번 작업에서 쓰거나 재실행하지 않았다.

## 데이터 보존 검토 7문항

1. 사건/기록 시각: ledger created_at과 KST grant_day를 분리하고 서버 시계 사용. 클라이언트 날짜를 믿지 않는다.
2. 원장 불변: 기존 grant/credit_transactions와 run 연결을 재사용. grant별 revision_cutoff를 고정하여 캠페인 변경으로 과거 권한을 연장하지 않는다.
3. UPDATE 의미: 발급 이후 기간/한도/정책 변경을 trigger로 차단. 실패는 기존 append-only release 사건으로 기록하며 History를 덮어쓰지 않는다.
4. 동일인: auth.users 및 기존 essay account 연결로 WEB/APP 동일 계정을 사용한다.
5. 사실/해석: 무료 사용·정산은 과금 사건이며 학습 회차/성장 평가를 초기화하지 않는다.
6. 최소 접근: 본인 allowance/정책 확인만 공개 RPC. 관리자 캠페인 적용은 별도 승인, 답안/평가/피드백 새 수집 없음.
7. 파생값: available/next_reset_at은 유효 grant/ledger에서 계산. 별도 유료 잔액 또는 매일 누적 카운터를 만들지 않는다.

## 원장·동시성·재첨삭

기존 `credit_grants`, `credit_transactions`, `daily_grants(user_id, grant_day)`를 재사용한다. 자정 cron으로 원장을 초기화하지 않고 날짜별 on-demand 발급·expires_at으로 무이월을 보장한다. 계정 advisory lock, 캠페인 lock, unique 날짜키 및 lock 후 서버시각 확인을 사용한다. 일반 credit_summary에서는 beta를 제외하여 유료/가입 잔액과 섞이지 않는다.

기존 공식 exam reserve 경로에서 요청키 replay를 우선하며 confirmed grant가 달라지면 CREDIT_SOURCE_CHANGED로 거절한다. 다른 기기가 소진했을 때 유료 잔액으로 조용히 전환하지 않는다. 승인된 인문/non-math scope만 beta를 쓸 수 있다. 학생이 확인한 기존 출처 계약을 유지한다.

finish는 원문 그대로: 완료 consume 1회, 전체 실패 release 1회. **부분 문항 실패는 run reserved를 유지**하고 완료 checkpoint를 보존하며 기존 실패 문항 재처리를 사용한다. 부분 실패를 전체 실패처럼 환급하지 않는다. 이전 날짜 grant의 늦은 release는 만료된 grant에 귀속되어 오늘 이용권으로 이월되지 않는다. quote/history/reserve가 동일 cutoff를 적용한다. 유료·가입 최초 요청은 기존 14일/1회 계약 유지.

## DB/RPC 후보 및 권한

[정확한 SQL·검증·활성화·롤백](../supabase/candidates/essay_beta_daily_v2/README.md). 새 `essay_beta_daily_claim_v2`, `essay_beta_notice_ack`는 authenticated 본인만. legacy claim은 v2 adapter. eligible, reserve, quote, history, summary 최소 변경. 캠페인 일일한도/정책/공지 연결, grant cutoff, 사용자 정책 확인 receipt 추가. private 접근 차단, SECURITY DEFINER와 고정 search_path, 15개 설치 정의/ACL manifest 검증. **Owner 실행용이며 자동 적용하지 않았다.**

notice_receipts는 정책 최초 안내 확인이며 기존 notice_reads(공지 실제 열람)와 목적을 구분한다. 사용자가 정책 모달만 봤다고 공지 읽음 상태를 임의 기록하지 않는다. 공지는 TASK 01 단일 저장소를 사용한다.

## APP/WEB

기존 LAB 배너를 v2 DTO로 전환: 오늘 1회 남음 / 소진·내일 00:00 / 마지막 날은 추가갱신 없음 / 종료. 신규 RPC 미설치 시 안전하게 숨김; 잘못된 daily count는 거절. 잔여량은 서버 응답만 사용. APP 복귀·소진/종료 갱신, WEB focus/visibility/shared-credit 이벤트 및 날짜 timer, 계정 전환의 오래된 응답 차단 유지. APP 제출 접수와 terminal 상태에서도 beta만 갱신하여 일반 잔액 변화가 없는 소비를 반영한다.

정책 모달은 account/campaign/policy 키와 서버 receipt로 양 플랫폼에서 반복을 방지하고, 공지사항에서 재확인한다. 통신 실패로 ack가 저장되지 않으면 재진입 때 다시 나올 수 있으며 이를 확인 완료로 위조하지 않는다. 피드백은 기존 APP MY 설정 문의·건의사항 / WEB support 사용. 기존 submit·OCR·Analytics·평가 UI를 다시 구현하지 않았다.

## 검증 및 한계

- PostgreSQL 17 격리: **33 PASS assertion groups**. 60 concurrent daily claims=1 grant; 30 concurrent distinct submissions=1 reserve; 30 concurrent failure callbacks=1 release. 23:59/00:00, 다음날 재사용, 만료후 release, cutoff 직전접수·이후완료, cutoff이후재첨삭거절, paid14일/가입3보존, 요청키 replay, 원답안/결과 보존, 권한/정책확인/활성화검증/disable rollback 포함.
- 부분 완료는 DB 예약 불변 계약을 검증했고 실제 Worker checkpoint 재실행은 하지 않았다. 기존 Worker/Provider 테스트 계약을 변경하지 않았다.
- APP targeted beta tests 7 PASS; 최종 Flutter Analyze **0 issues**, 전체 Flutter Test **1,301 PASS / 7 SKIP / 0 FAIL**.
- WEB 전체 **1,432 PASS / 4 SKIP / 0 FAIL**; TypeScript·Production Build PASS; Lint 0 errors / 기존 5 warnings (owner-review app 1, math-release exam submit 2, my essay retry test 2). SKIP은 PASS에 포함하지 않는다.
- 실제 자정 디바이스, 실제 무료 평가, Production campaign/공지/잔액 동기화는 **NOT TESTED**. 모든 concurrency는 synthetic account를 쓴 로컬 DB 검증이다. 새 사용자 정책은 운영 적용 전까지 제공되지 않는다.

## 적용·롤백·남은 작업

Owner가 guarded precheck→install→verify를 검수/적용해야 한다. 공지 SQL/관리자 게시 및 인문시험 exact scope, 새 클라이언트 배포 준비가 선행이다. starts_on은 아직 활성화 날짜가 정해지지 않아 placeholder로 남겼으며 종료만 확정했다. activate.sql은 관리자·게시공지·scope·시작일·승인참조 미충족 시 실패한다. 출처 확인을 우회하거나 임의 Production scope를 만들지 않았다.

롤백은 campaign disable로 신규 사용을 중단하고 이미 접수된 처리·원장·cutoff·History 보존. 기존 구형 무범위 allocator 복원/원장 삭제 금지. Client rollback은 각 repo 변경 commit revert로 하되 활성 캠페인부터 중단하여 옛 2/day 문구가 다시 안내되지 않게 한다. 새 실평가/운영 DB 변경은 이번 작업에서 실행하지 않았다.
