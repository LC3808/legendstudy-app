# Analytics Measurement Architecture v1.0 — 외부 리뷰

2026-09-29 · **REVIEW / ADVISORY ONLY.** 코드·DB·analytics 구현 없음. LegendStudy
/ LegendStudy LAB의 Analytics Measurement Architecture v1.0 요청서에 대한 비판적
리뷰. Learning Data의 Source of Truth는 [Essay LAB 제품 스펙](essay-lab-product-v1.md)
/ [데이터 아키텍처](student-analytics-data-architecture.md) / [server transactions](essay-lab-server-transactions.md)
와 일관. 상위 데이터 전략은 [longitudinal 전략](longitudinal-learning-admissions-data-strategy.md).

---

## A. Architecture 총평

큰 뼈대는 옳다: (1) Learning / Growth / Business 3영역 분리, (2) "하나의 Backend,
여러 Client", (3) 공통 event 이름 + `platform` property, (4) 답안 본문/OCR/PII를
analytics에 넣지 않음. 출시 후에도 유지할 자산.

그러나 문서는 "이벤트를 어디에 얼마나 보낼까"를 과설계하고, 두 급소를 과소평가했다.

1. **인증 이후 funnel은 이미 Supabase에 트랜잭션으로 존재한다.** essay_submit·
   evaluation·rewrite·credit·purchase는 이미 RPC로 원장에 기록된다. →
   **로그인 이후 funnel/cohort/revenue의 Source of Truth는 이미 있는 Postgres.
   GA4는 로그인 전 익명 marketing 상단 funnel 전용이 더 단순하고 더 정확하다.**
2. **미성년 개인정보(PIPA)를 §20 체크리스트 한 줄로 취급** → 출시 전 법적 **P0 게이트**.

한 줄 요약: **"덜 보내고, 이미 있는 걸 쓰고, 미성년 동의/최소수집을 P0로 올려라."**
2026 첫 시즌(수천~수만 명) 규모 대비 event/dashboard/cohort는 과설계,
North Star·출시 신뢰성 지표·법적 게이트는 과소.

## B. 반드시 수정할 사항
1. **GA4를 cross-device user-level funnel/cohort 엔진으로 쓰지 말 것** (sampling·
   thresholding·user_id 조인·PII 제약). 그 분석은 **Postgres에서 user_id 조인**으로.
2. **Business event를 analytics에 이중 기록해 두 번째 truth로 삼지 말 것.**
   Credit=원장, Purchase=Store+Backend가 유일 truth. GA4엔 시각화용 얇은 event만.
3. **미성년/개인정보를 P0 법적 게이트로 승격.** GA4 Google Signals·광고 개인화 OFF,
   보존 최소, IP 익명화, iOS cross-app tracking 안 함(ATT/IDFA 회피), 14세 미만
   법정대리인 동의 흐름·동의배너·삭제/보존정책 확정.
4. **North Star Metric 부재** → §L 정의.
5. **Cross-device identity는 오직 인증 pseudonymous user_id로만.** fingerprinting
   금지, analytics에 이름/이메일/전화/답안 금지.
6. **Web→App deferred deep link에서 Firebase Dynamic Links를 전제하지 말 것**(종료
   중). 최소 토큰 방식 또는 전문 MMP는 P1.

## C. 유지할 사항
- Learning/Growth/Business 3영역 분리 + Supabase = Learning/Business SoT.
- "하나의 Data Contract, Web/App은 다른 Client."
- 동일 행동 = 동일 event 이름 + `platform` property (플랫폼별 event 이름 금지).
- 답안 본문·OCR 원본·PII를 analytics에 넣지 않는다.
- anonymous→authenticated 연결 의도, credit ledger·store를 재무 truth로.

## D. 과도하게 설계된 사항 (P0에서 덜어낼 것)
- 4단 Dashboard 계층 → 출시엔 **1페이지 launch 대시보드** 하나.
- §8–13 event 전량 → P0는 ~12개(§K). OCR·open_in_app 계열은 P1.
- §16 cohort 매트릭스 전부 → P0는 Credit·Learning-loop·Platform 3~4개.
- 전용 Product Analytics 도구(PostHog/Mixpanel/Amplitude) 초기 도입 → 연기.
- 6개 context 전 구간 attribution 완결 → signup 시점 first-touch 스탬프로 80% 커버.

## E. 누락된 사항
1. **North Star Metric** (§L).
2. **출시 신뢰성 지표**: evaluation 지연·실패율, **실패 시 credit 미차감/환급 정확성**
   (새 AI worker로 첫 시즌 → 제품건강 + 매출신뢰 핵심 P0).
3. **미성년 동의/보존/삭제/탈퇴** 확정.
4. **Event Governance**: tracking plan·네이밍 규약·검증(QA)·소유자.
5. **환불/결제실패/청구반려 관측**.
6. **Time-to-value**: signup→첫 답안, 답안→첫 평가결과.
7. **"첫 재첨삭 무료" nudge guardrail** (무료 클릭 vs 실제 참여 구분).
8. **Server-side vs client-side 결정** (웹 client GA는 광고차단/ITP로 유실 →
   로그인 funnel은 서버측/Postgres, 이미 그러함).

## F. P0 — 2026-10 출시 전 필수
1. GA4를 legendstudy.com + lab에 cross-subdomain(동일 등록도메인) + UTM + 자체 context.
2. **Signup 시 first-touch(source/medium/campaign/university_id/placement)를 user·
   session에 Postgres 스탬프** → 이후 전환/구매 attribution은 Postgres 조인.
3. 이미 있는 authenticated funnel로 **핵심 KPI 6개 materialized view/쿼리**.
4. Credit·purchase truth = 원장 + store receipt.
5. **미성년 개인정보 게이트**(Signals off, 보존 최소, 동의배너, cross-app tracking 없음).
6. **1페이지 launch 대시보드 + North Star**.

## G. P1 — 출시 직후
OCR funnel event · web→app prompt + 최소 deferred deep link · Credit/Learning/
Platform cohort 대시보드 · retention D1/D7/D30(Postgres) · 환불/재구매 ·
CTA→LAB university 맥락(통계 주의 §19).

## H. P2 — 2027 확장
필요 시 self-host PostHog · 정식 MMP(AppsFlyer/Adjust)·MMM · cross-platform 인과실험
(§18) · LTV 모델 · university별 전환 정식 통계 · 실험 플랫폼.

## I. 권장 Analytics Stack (역할 재배치)
- **GA4 (web+app 단일 property)** = 로그인 전 익명 marketing/acquisition 상단 funnel,
  UTM, page/CTA, 캠페인. Google Signals OFF.
- **Supabase/Postgres (이미 보유)** = 로그인 이후 product funnel · learning cycle ·
  credit · purchase의 **Source of Truth**. KPI/cohort는 SQL + materialized view.
  얇은 append-only `analytics_events`(같은 RPC 기록) 정도만.
- **Firebase = Crashlytics + FCM(Push) + 앱 설치 attribution만.** Firebase Analytics를
  product funnel로 쓰지 말 것.
- **제3 product analytics 도구 = P2** (입증 시 PostHog self-host).

## J. Identity / Attribution 권장 구조
- **anonymous_id** = 웹 first-party cookie / 앱 install-id. fingerprinting 금지.
- **로그인 시** `identity_map(anonymous_id, user_id, first_seen, first_touch_ctx)`를
  Postgres 기록 → 로그인 전 세션을 user에 귀속. GA4는 pseudonymous `user_id`, Signals off.
- **Cross-device(PC 작성→App 재작성)** stitching은 **오직 인증 user_id로만**. 로그인 전
  cross-device는 잇지 않는다.
- **Attribution**: signup 시 first-touch를 user에 스탬프 → 구매/전환은 Postgres 조인.
  GA4 구매 attribution에 의존하지 말 것.
- Web→App: 짧은 토큰(universal link/스토어 링크 파라미터)로 `app_open_from_web` 최소 매칭.

## K. Event Taxonomy 수정안
규약: `object_action` snake_case · 플랫폼 공통 이름 + `platform`(desktop_web/
mobile_web/ios/android) · entity는 id property(`university_id/problem_id/
essay_cycle_id/attempt_no`) · 자유 텍스트/PII 금지 · **event당 SoT 1개**.

- **P0 · GA4(마케팅 상단)**: `page_view`, `essay_cta_impression`,
  `essay_cta_click`, `lab_landing_view`, `problem_view`, `signup_start`,
  `paywall_view`
- **P0 · Postgres(원장/RPC, 이미 존재)**: `signup_complete`, `essay_submit`,
  `evaluation_complete`, `evaluation_fail`, `rewrite_submit`,
  `reevaluation_complete`, `credit_used`, `credit_exhausted`,
  `purchase_complete`, `refund`
- **P1**: `login_complete`, `history_view`,
  `open_in_app_{prompt,accept,decline}`, `app_open_from_web`,
  OCR `ocr_{offer_view,qr_open,capture_start,upload_complete,processing_complete,processing_fail,confirm}`

주의: credit/purchase를 GA4의 두 번째 truth로 저장 금지(원장이 truth, 얇은 사본만 선택적).

## L. 핵심 KPI + North Star

**North Star Metric(신설, 권장)**
> **주간, "전체 학습 루프(제출→평가→재작성→재평가)를 1회 이상 완료한 학생 수"**
> (매출 관점이면 그 중 유료 학생 수). 제품가치(재작성 학습) + 수익 동시 포착.

**출시 1개월 시즌에 먼저 볼 5–10개**
1. LAB Landing→Signup 전환율 (및 .com CTA click→LAB)
2. 첫 답안 제출률 (activation 시작)
3. **첫 전체 루프 완료율** = activation NSM
4. 무료 3 Credit 소진율
5. Free→Paid 전환율
6. 매출·ARPPU·product mix(어느 Credit 팩)
7. **Evaluation 완료/실패율 + 실패시 credit 정확성** (출시 신뢰성)
8. D1/D7 retention (1개월 → D30 비중 낮춤)
9. Contextual-CTA CTR + 하류 전환 (H4 검증)
10. Web/App 분할 + (측정 가능 시) cross-platform 비중

**Vanity(경계)**: 단독 page view·CTA impression, 느슨한 "active learners", 누적 signup 총량.

---

## 20개 질문 압축 답변
- **Q1 과복잡?** 예 — P0 축소(D). **Q2 누락?** 예 — NSM·출시 신뢰성·미성년 게이트·
  governance(E). **Q3 도구 역할** = I/K. **Q4 전용 도구?** 초기 불필요, GA4+Postgres+
  Firebase로 충분, PostHog는 P2. **Q5 cross-device 프라이버시** = 인증 user_id만,
  fingerprint 금지(J). **Q6 anon→auth 주의** = identity_map 기록·로그인 전 cross-device
  미연결·PII 금지(J). **Q7 attribution 현실선** = first-touch 스탬프 + Postgres 조인;
  web→app 부분매칭 수용(J). **Q8 UTM schema** = 외부 utm_*, 내부 `ls_placement/
  ls_university/ls_content_type/ls_source_page`, university는 id(K). **Q9 중복수집 방지**
  = event당 SoT 1개, 원장/스토어 재무 truth(B/K). **Q10 Supabase 필수 event** = 매출/
  권한·learning 조인·감사 필요 = 이미 있는 것들. **Q11 경계 더 엄격?** 콘텐츠는 더 엄격,
  id·count는 허용(E/K). **Q12 미성년** = PIPA P0 게이트(B-3). **Q13 식별자 수준** =
  pseudonymous user_id + entity id + 범주형 상태만. **Q14 OCR** = 단계·상태·시간만,
  이미지/원문 금지, session id 연결. **Q15 P0/P1/P2** = F/G/H. **Q16 vanity/NSM** = L.
  **Q17 재작성률?** 타당하되 "첫 루프 완료율"을 activation NSM으로, 재작성률은 보조 +
  무료 nudge guardrail 필요. **Q18 cross-platform 인과?** selection bias 큼 — "연관"으로만,
  시퀀스/사전참여 매칭, 궁극적으로 prompt 랜덤화 실험(H). **Q19 university 표본** = 최소 n
  임계·신뢰구간(Wilson)·Bayesian shrinkage, 시즌 중 raw 순위화 금지. **Q20 우선 지표** =
  L의 5–10개.

**요약 권고**: ① GA4=마케팅 상단, Postgres=인증 funnel/매출 truth로 역할 재배치, ②
event/dashboard/cohort P0 슬림화, ③ 미성년 개인정보·출시 신뢰성·North Star를 P0로 승격.

*Advisory only — no analytics/code/DB implementation performed. 구현 시 실제 서버 API/
privacy gate 검증이 선행되어야 한다.*
