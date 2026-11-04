# 이용권 지급 유형·관리자 통계 조회 후보

상태: **IMPLEMENTED / ISOLATED TEST PASS / PRODUCTION NOT APPLIED**. Owner의 별도 운영 SQL·WEB 배포 승인 필요. 기존 원장·청구 RPC·결제·환불·우선순위·만료 정책 변경 없음.

## 보존 검토 7항목

1. 기존 거래 발생시각·ID·금액·예약 증감을 그대로 읽는다. 새 historical fact를 생성하지 않는다.
2. 분류는 원 지급 reason/source 및 daily_grants 연결로 재계산 가능하다. 미확인 값은 기타/일반 조정으로 남긴다.
3. 원장 UPDATE/DELETE/백필 및 새 원장·캐시 테이블 없음. 원본 reason/type 유지.
4. 기존 credit_accounts.user_id로 회원을 제한하며 별도 identity 없음.
5. 재무 거래 projection이며 Learning/Decision/Outcome 사실을 생성하거나 추론하지 않는다. 시험/회차는 실제 FK만 연결.
6. 기존 admin_operator 권한을 검사하고 authenticated만 RPC 실행 가능. 학생 답안/이메일/토큰을 반환하지 않는다. 사유·거래 ID는 운영자에게만 공개. 사용자 화면은 내부 사유코드를 노출하지 않는다.
7. credit-report-v2는 파생 분류와 집계이다. source_kind와 raw origin/reason/type을 함께 제공한다. 현재 상태와 거래 직후 잔액을 구분한다.

## 변경 대상

- 새 `essay_private.credit_display_kind/action/grant`: 순수/읽기 분류, API 역할 실행 차단.
- 새 `public.admin_credit_report(jsonb)`: STABLE SECURITY DEFINER, 빈 search_path, 관리자 검사. 기존 원장 SELECT만 수행.
- 기존 `public.admin_member_credit`: 지급 행에 `display_kind` 1필드 추가. 기존 응답·잔액 계산·권한 그대로.
- 기존 `admin_release_report`와 지급·예약·정산·환불 함수는 교체하지 않는다. WEB의 이용권 분기만 새 조회로 연결. 결제/대시보드 분기는 기존 RPC 유지.

## 적용 순서 (이번에 실행하지 않음)

1. 최신 운영 `admin_member_credit` 정의·권한을 별도 백업. `precheck.sql`의 baseline hash 및 새 이름 미존재 확인. 동일 파일 재실행 금지.
2. 별도 Owner 승인 후 `apply.sql` 단일 트랜잭션 적용. DDL만 있고 운영 DML 없음. baseline drift/기존 이름 충돌은 시작 단계에서 중단.
3. `postcheck.sql`: authenticated=true, anon/service_role=false, volatility=s, security_definer=true, search_path 빈값. 대상 원본 거래3행의 source_kind=beta, action=grant/reserve/consume 확인.
4. 실제 관리자 세션으로 전체/베타/기간/회원 필터·5건 페이지·원본 ID 확인. 운영 테스트 지급/답변/평가 실행 금지.
5. 검증된 WEB 커밋을 최신 배포 소스에 선택 통합 후 승인된 배포. APP58 브랜치에 표시 파일만 선택 통합, 별도 앱 빌드/출시 절차.

## 계약

`{version:'credit-report-v2',from,to,source,action,subject,limit,offset}`. subject는 기존 회원 UUID(credit_accounts.user_id), 별도 원장 account UUID와 다름. 시작 포함/종료 제외. WEB 기존 KST 기간 계산 재사용. limit1..50, offset0..1000000. 지급출처와 거래구분은 독립 필터이며 합계·total은 LIMIT 이전 동일 조건.

grant_stats는 신규 grant 동작만 합산. action_stats의 restore는 신규 지급 총량에 포함하지 않는다. compensation grant는 신규 보상지급, refund 양수는 기존 소비 복구, purchase_cancel/수수료 없는 IAP 환불 negative adjustment는 환불 조정이다. admin_recovery_v1은 관리자 **회수**이므로 복구로 오분류하지 않는다. 미확인 adjustment는 부호와 원본 사유를 보여주고 임의로 환불/복구라고 이름 붙이지 않는다. 지급 유형 school을 추가하고 other와 별도 집계한다.

행의 grant_balance_after/grant_reserved_after는 기간 필터 전 누적한 **지급 건별 거래 직후 원장 수량**. 현재 사용 가능 잔액이 아니며 만료/fence를 적용한 기존 회원 summary와 혼용하지 않는다. timestamp 동률은 ID로 결정적으로 정렬한다. 기록 수는 첨삭 횟수가 아니다. 오래된 evaluation_id가 NULL인 Math 회차도 실제 session_runs의 decision_id로 연결한다.

## 검증 및 복구

`python3 tool/test_credit_classification.py`: 원격 DSN 입력 없음, 임시 PostgreSQL17 Unix socket만 사용. 합성 지급8분류/동작8개, 기간/KST자정, 회원/필터/페이지, Math 회차 연결, 관리자 권한/비관리자 거부, 원장 hash 보존, rollback 확인. 미래 source와 알 수 없는 reason은 합성 fixture임.

복구는 이전 WEB으로 되돌린 뒤, 이번에 추가한 읽기 함수만 사용하는 상태인지 확인하고 `rollback.sql`. member-baseline.sql은 감사 당시 운영 읽기 함수 원문. 후속 타 작업이 같은 함수를 수정했다면 rollback을 실행하지 말고 diff를 재검토한다. 원장 복구/역분개는 필요 없고 실행해서는 안 된다.

주의: 읽기 SQL은 현재 전체 원장 기반 집계를 사용한다. 대규모 데이터의 부하 성능 인증은 별도이며 새 인덱스/캐시는 추가하지 않았다. UI 브라우저 실기기 및 운영 인증 세션 확인은 적용 후 단계이다.
