# 관리자 회원별 크레딧 관리 — 2026-10-26

기존 [회원 관리](admin-member-directory.md), [결제 계약](payment-app-foundation.md), [데이터 보존 원칙](longitudinal-learning-admissions-data-strategy.md)을 재사용한다. Owner 관리자 크레딧 지시의 P0는 구현·배포, P1은 검토만 진행했다.

## P0 운영 결과

- `/admin/credit/` 최상단 서버 회원 목록. 기본 사용 가능 잔액 내림차순, 이메일/UUID 검색, 10/20/50명, 잔액 오름차순·최근 지급/사용/가입 정렬. 동률 UUID 고정.
- 회원 이메일/ID·사용 가능/예약/유료/무료/기타·최근 크레딧 사용일 표시. 최근 로그인 등 전체 활동일을 사용일로 혼동하지 않는다.
- 기존 회원 상세·지급단위·거래내역·지급 폼 재사용. 회수/환불 버튼 미노출. 통계는 하단 유지.
- WEB `584a9142ef6d9fd7bf6815be72cf8091d0b82aca`, Pages `89246b7e-c283-499b-a849-5e1f1e6dbb3d`, API Production deploy success 및 해당 commit 확인.
- 운영 관리자 계정: 13명, 첫 페이지10/다음3, 잔액 내림차순·오름차순,20명 표시, 이메일 검색1명, 기존 상세 거래내역·지급 폼 열기/닫기 확인. 지급 실행0.
- Typecheck PASS, 관련 UI/API 48검사 PASS, lint 오류0/기존 경고4, Production build PASS. 모바일 가로스크롤 대응 코드 적용; 실기기 확인은 미실시.

## 승인된 DB 변경

Owner “조회 RPC 검증 후 적용 승인”에 따라 `admin_credit_member_list(text,integer,integer,text)` 1개만 추가. 기존 admin_operator/account allowed 검사, authenticated만 EXECUTE. 기존 admin_credit_snapshot을 호출하며 잔액·지급 로직은 변경하지 않는다.

[SQL·적용 영수증·복구](../supabase/candidates/admin_credit_directory_20261026/README.md). **apply.sql 재실행 금지.** 격리 PostgreSQL17의 합성55회원에서 10/20/50·검색·안정 정렬·권한거부·만료/예약/취소대기 검증. 사후7true, 기존 snapshot/manual grant 함수 정의 불변, 적용 직후 Ledger90행/잔액변동합338 불변. 학생답안/History에 쓰기없음. 운영 지급·회수·차감·Provider호출0.

서버에서 전체 잔액을 계산한 후 페이지를 반환한다. 브라우저 전체회원 다운로드는 없다. 현재13명 운영 조회 성공은 대규모 성능 보증이 아니다. 회원 증가 시 실행계획/응답시간을 관찰하고 집계 최적화·인덱스는 별도 승인한다.

## P1 회수 검토 — 미구현

기존 append-only Ledger는 grant_id별 negative adjustment를 지원한다. 최소 신규 관리자 회수 RPC 1개가 적합하다. admin_operator+account allowed 확인, 계정→지급단위 잠금, 수량/사유 검증, 사용·예약분 제외한 잔여분 한도, actor UUID·시각·사유·원지급ID 기록, 요청 멱등키와 동일 payload 확인이 필요하다. 잔액 UPDATE/원거래 삭제 금지. 구매분은 직접 회수 대신 기존 환불 경로 사용; 무료/이벤트/관리자 지급은 현금 환불 불가. 신규 회수 RPC와 권한은 아직 구현·적용하지 않았다.

## P1 부분 환불 검토 — 기존 기능 재사용

운영 `payment_process(jsonb)` 읽기 전용 정의 및 WEB `cloudflare/payments.ts` 확인:

- 주문 grant_id의 consume/refund 합계로 순사용량, balance/reserved 합계로 잔여/예약 산출. 예약!=0 차단, 원장 수량 불일치 차단.
- `max(0, 결제금액 - 사용량 × deduction_unit)`; 기존 단가4900 고정. 사용량>=0으로 원결제금액 초과 없음. 0원은 NO_REFUND_DUE. 미사용은 전액. 기존 일반환불 가능기간/주문상태 조건 유지.
- cancel_begin은 CANCEL_PENDING 및 멱등 operation을 생성하고 해당 구매 grant를 사용 불가로 둔다. Provider 성공 확인 후 cancel_finish에서 해당 grant 잔여량만 negative adjustment·주문취소 확정.
- WEB 어댑터는 cancelAmount·Idempotency-Key 사용, isPartialCancelable 검사. [Toss 공식 부분 취소 안내](https://docs.tosspayments.com/guides/v2/cancel-payment), [API](https://docs.tosspayments.com/reference)는 부분 취소를 지원하나 결제수단별 제약 존재.
- 응답 불명/timeout은 UNKNOWN으로 대기 유지, Provider 조회 후 같은 operation 정산. 확정 REJECTED만 PAID 복귀. 재시도에 새로운 취소/회수 요청을 만들지 않는다.
- 현 어댑터는 취소1건·금액 일치를 기대한다. 임의 다중 부분환불 기능은 별도 범위이며 현재 구현으로 지원한다고 보고하지 않는다. 기존 TEST/LIVE 동결 유지, 실제 취소API 호출0.

## 복구 및 인수인계

WEB 이전 Pages `1061ae14` / commit `e669cbc7b4d9a4ea4afc1a35b5a567f9a2cb31d0`를 사용한다. 이전 배포로 되돌린 뒤 필요 시 candidate rollback.sql로 신규 조회 함수만 제거한다. Ledger/History 복구 작업은 필요 없다. Worker·Secret·결제 설정 변경0.

중단했던 2·3순위 대학 STANDBY는 이번 변경의 완료 범위가 아니며 기존 초안/작업 파일을 보존한다. P1 구현은 Owner 별도 승인 후 진행한다.
