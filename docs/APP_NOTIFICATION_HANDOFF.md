# LegendStudy 앱 ↔ LAB 공용 알림센터 — 구현 핸드오프

**상태:** 백엔드 구현 완료 · **앱(Flutter) 구현은 이 문서를 받은 쪽 작업**
**작성:** ADMIN-P0-B ADDENDUM (Manus)
**적용 커밋:** 이 커밋

---

## 0. 왜 앱을 수정하지 않았는가

이번 작업의 범위는 **공용 알림센터의 백엔드와 LAB 웹**입니다. LegendStudy 앱
(Flutter)은 이 문서의 계약만 받아 연결하면 되며, 앱 코드는 이 저장소에서
수정하지 않았습니다. 앱에 필요한 것은 **RPC 4개 호출과 종 아이콘 하나**입니다.

---

## 1. 이미 앱에도 쌓이고 있는 알림

알림은 LAB에서만 만들어지는 것이 아닙니다. 다음 이벤트는 **DB 트리거 또는
서버 경로**에서 생성되므로, 앱에서 발생한 첨삭·Credit 지급도 이미 앱 사용자의
알림함에 들어갑니다.

| 이벤트 | 생성 지점 | 대상 이동 |
|---|---|---|
| 1:1 문의 답변 | `inquiry_replies` INSERT 트리거 | 1:1 문의 |
| 논술 첨삭 완료 | `essay_evaluations` 상태 변경 트리거 | 첨삭 결과 |
| Credit 지급 | `credit_transactions` INSERT 트리거 | Credit 내역 |
| 결제 완료 | 서버 `user_notification_payment_complete(order)` | 결제 내역 |
| 수리논술 첨삭 완료 | 서버 `user_notification_math_evaluation_complete(...)` | 첨삭 결과 |
| Credit 부족 | 원장에서 잔액이 3 이하로 **진입**할 때 1회 | Credit 내역 |
| Credit 만료 예정(D-30/14/7/3) | 일일 스케줄러 | Credit 내역 |

앱은 **읽음 상태를 공유**합니다. 앱에서 읽은 알림은 LAB에서도 읽음이고,
그 반대도 같습니다. 이것이 이 설계의 핵심입니다 — 앱과 웹 중 어디서
확인했는지는 사용자에게 중요하지 않습니다.

---

## 2. 앱이 호출할 계약 (`notification-v1`)

모두 `SECURITY DEFINER`이고 **본인 것만** 반환합니다. 앱의 세션 토큰으로
그대로 호출합니다.

### 2.1 목록

```
POST /rest/v1/rpc/user_notifications_list
{ "p_limit": 20, "p_offset": 0, "p_unread_only": false }
```

```json
{
  "dto_version": "notification-v1",
  "limit": 20,
  "offset": 0,
  "unread": 5,
  "items": [
    {
      "id": "uuid",
      "type": "essay_evaluation_complete",
      "title": "논술 첨삭이 완료되었습니다",
      "body": "첨삭 결과와 총평을 확인해 보세요.",
      "target_type": "essay_evaluation",
      "target_id": "attempt uuid",
      "created_at": "2026-10-05T01:00:00+00:00",
      "read_at": null,
      "is_read": false
    }
  ]
}
```

- `items`는 최신순입니다.
- `title`과 `body`는 **알림에 필요한 최소 정보만** 담습니다. 첨삭 결과 본문이나
  문의 본문은 알림에 복사되지 않습니다.
- `target_type`은 앱에서 **허용 목록**입니다. 모르는 값이 오면 링크로 만들지
  말고 무시하십시오. 서버는 URL을 저장하지 않습니다.

| target_type | 앱 이동 |
|---|---|
| `inquiry` | 1:1 문의 |
| `essay_evaluation` | 첨삭 결과 (`target_id` = attempt id) |
| `math_evaluation` | 수리논술 결과 |
| `payment_order` | 결제 내역 |
| `credit_history` | Credit 내역 |
| `essay_lab` | 논술 LAB 홈 |

`target_id`가 없으면 해당 **목록 화면**으로 이동합니다. URL을 조립하지 마십시오.

### 2.2 안 읽은 개수

```
POST /rest/v1/rpc/user_notifications_unread_count   → 5
```

종 아이콘 배지에 그대로 쓰십시오. **앱에서 다시 세지 마십시오.** 다른 기기에서
읽은 알림이 앱에 남아 있으면 배지가 거짓말을 하게 됩니다.

### 2.3 하나 읽음 / 모두 읽음

```
POST /rest/v1/rpc/user_notification_mark_read  { "p_id": "uuid" }
POST /rest/v1/rpc/user_notifications_mark_all_read
```

- `mark_read`는 **본인 알림이 아니면 `false`**를 반환하고 아무것도 바꾸지
  않습니다.
- 두 함수 모두 멱등입니다. 두 번 불러도 안전합니다.

### 2.4 권장 호출 시점

- 종 아이콘: 앱 포그라운드 진입 시, 그리고 알림함을 나올 때
- 목록: 알림함을 열 때
- 읽음: 사용자가 알림을 **탭했을 때**(목록을 렌더링할 때가 아님)

---

## 3. 앱에서 해서는 안 되는 것

| 금지 | 이유 |
|---|---|
| `user_notifications` 테이블 직접 조회 | 테이블은 RLS로 잠겨 있습니다. 앱 롤에는 권한이 없습니다. |
| 앱에서 안 읽은 개수를 로컬 계산 | 읽음 상태가 기기 간에 갈라집니다. |
| 알림을 로컬 DB에 영구 복제 | 두 개의 진실이 생깁니다. 필요하면 표시용 캐시만 두고 서버 값을 우선하십시오. |
| `notification_private.emit` 호출 | 생산자 전용입니다. 클라이언트 롤에는 실행 권한이 없습니다. |
| 알림 본문에 첨삭·문의 원문 저장 | 저장 구조상 불가능하고, 개인정보 최소화 원칙에도 어긋납니다. |

---

## 4. 푸시 알림에 대해

**이번 작업에는 푸시가 없습니다.** 인앱 알림함만 구현되었습니다.
푸시(FCM/APNs)는 별도 승인 사항이며, 추가되더라도 **같은 행**을 근거로
발송하게 되어 있습니다. 알림 행이 곧 진실의 원천입니다.

SMS/알림톡/메일 발송도 이번 범위가 아닙니다. 1:1 문의 답변 메일은
ADMIN-P0-B에서 이미 큐로 분리되어 있고, **메일이 실패해도 인앱 알림은
남습니다**(검증 완료: `N-C5` 계열).

---

## 5. 일일 스케줄러 계약

```
POST /rest/v1/rpc/user_notification_run_daily_producers
Headers: Authorization: Bearer <service_role key>
{ "p_limit": 500 }
```

```json
{ "expiry_created": 34, "as_of": "2026-10-05" }
```

- 하루 한 번 실행합니다.
- **만료 알림만** 만듭니다. 잔액 알림은 이 함수에서 더 이상 만들어지지 않습니다.
- **멱등합니다.** 같은 날 두 번 실행해도 중복이 생기지 않습니다
  (검증: `N-D15`).
- 만료 알림은 **D-30/14/7/3 각 1회**입니다.
- 같은 만료일의 여러 지급은 **하나의 알림으로 합산**됩니다.
- 이미 다 쓴 Credit은 만료 알림을 만들지 않습니다(`N-D16`).

### 5.1 Credit 부족 알림은 "상태"가 아니라 "진입"입니다

매일 반복되는 잔액 알림은 폐기되었습니다. 잔액은 Credit 내역에서 상시 확인할 수
있으므로, 알릴 가치가 있는 것은 **낮은 구간으로 들어오는 순간 한 번**뿐입니다.

```
5 → 4   없음
4 → 3   알림 1회   "남은 Credit이 3개입니다."
3 → 2   없음
2 → 1   없음
1 → 0   없음
1 → 6   (충전) 없음
6 → 5 → 4 → 3   새로운 cycle로 알림 1회
```

앱에서 중요한 두 가지:

1. **예약(reserve)과 해제(release)는 알림을 만들지 않습니다.** 이것들은 예약분만
   움직이고 원장 잔액은 건드리지 않기 때문입니다. 즉 첨삭이 실패해 해제되고
   다시 시도되어도, 사용자가 떠난 적 없는 저잔액 상태를 다시 알리지 않습니다.
2. **알림 타입 이름이 `credit_balance_reminder` → `low_credit_notification`으로
   바뀌었습니다.** 앱이 타입 이름을 분기한다면 이 값을 쓰십시오. 모르는 타입은
   무시하는 구현이면 변경이 필요 없습니다.

새 스케줄러를 만들지 마십시오. 기존 워커가 쓰는 service role 호출 방식을
그대로 사용하면 됩니다.

---

## 6. 검증 상태

격리된 PostgreSQL에서 표준 마이그레이션 체인으로 검증했습니다.

```
CANONICAL_CHAIN=OK
ADMIN_MIGRATION_APPLY=OK (19 entry points)
ADMIN_CONSOLE_CHECKS   158 checks, 0 failed
ADMIN_P0B_CHECKS       351 checks, 0 failed
NOTIFICATION_CENTER_CHECKS  70 checks, 0 failed
```

알림센터 전용 59개 검사에는 다음이 포함됩니다.

- 소유자 경계(타인 알림 읽기·읽음 처리 거부) — `N-A`, `N-B7`
- 문의 답변 1건 = 알림 1건, 재시도 시 중복 없음 — `N-C1`, `N-C4`
- 메일 실패가 인앱 알림에 영향 없음 — `N-C5`
- Credit 지급만 알림 생성, 조정·만료·가입 보너스는 미생성 — `N-C6` ~ `N-C9`
- 잔액 진입 알림: 5→4 없음, 4→3 1회, 3→2·2→1·1→0 없음, 회복 후 재진입 1회 —
  `N-D6` ~ `N-D10b`
- 예약/해제가 잔액을 움직일 수 없음 — `N-D11`, `N-D11b`
- 스케줄러가 잔액 알림을 만들지 않음 — `N-D12`, `N-D12b`, `N-D14`, `N-D15c`
- 만료 임계값·합산·중복 방지 — `N-D13` ~ `N-D16b`