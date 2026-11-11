# 이메일 SMTP 공급자 비교와 전환 준비 — 2026-11-11

상태: **조사/도입 준비 승인, 공급자 최종 선택 및 운영 전환 승인 대기**.
기준 `codex/email-auth-stabilization-20261111`, 인증 수정 `c5cd349` 보존.
[장애 실측과 UX 검증](email-verification-audit-20261111.md), [기존 Resend 피드백 발송](day-11-b4-feedback-email.md)을 계승한다.
계정 생성/키 생성/DNS 수정/결제/운영 Auth 변경/실제 발송/배포 0. LAB 소스는 고객지원 주소 확인을 위해 읽기만 했으며 변경하지 않았다.

## 결론과 추천

**Resend를 1순위로 추천한다.** 기존 LegendStudy 피드백 메일의 Resend 발송 검수 기록과 공개 DNS를 재사용할 가능성이 높고, Supabase 전용 SMTP 안내와 전달 이벤트 조회가 있어 도입 부담이 작다.
초기 소량 검증은 Free($0), 실제 운영 예상 peak가 100통/일에 근접하거나 초과하면 Pro($20/월,50,000통)를 별도 승인한다. 일80통 또는 월2,400통 도달을 점검 기준으로 제안하며 이는 공급자 정책이 아닌 내부 운영 기준이다.
기존 피드백/인증 발송은 같은 팀 사용 시 quota를 공유한다. 새 API key만으로 한도나 장애 영향이 격리되지 않는다.
현재 계정 플랜·사용량·suspension·도메인 Verified 상태는 **NOT TESTED**이며 과거 검수나 DNS만으로 현재 발송 가능을 확정하지 않는다.

SES는 규모가 커질 때 비용 면에서 유리하지만 sandbox 해제·IAM·이벤트 수집 운영이 추가된다. Brevo는 무료 일300통이 장점이나 신규 transactional 활성화 확인과 DNS 인증 작업이 필요하다.

## 공식 요금과 발송 제한

2026-11-11 조회, USD 기준·세금/환율/카드 수수료 제외. 월간 quota는 가입자 수가 아니라 발송량이며 가입·재발송·복구·기존 알림을 합산한다.

| 항목 | Resend | Amazon SES | Brevo |
|---|---|---|---|
| Supabase 호환 | 공식 지원 목록 + 전용 연동 문서 | 공식 지원 목록/표준 SMTP | 공식 지원 목록/표준 SMTP |
| 무료 | $0,월3,000통·일100통 | 영구 무료 발송량으로 예산 잡지 않음. 신규 AWS 고객 최대$200크레딧, free plan6개월·크레딧12개월 내 사용 조건; 계정 적격성 미확인 | $0,일300통, 이월 없음. 월9,000통은30일 산술치이지 별도 월 quota가 아님 |
| 최소 유료 | Pro $20/월·50,000통;100,000통 $35/월 | 신규 기본 Essentials $0.16/1,000통,최소 월정액 없음(0–1천만 구간). 선택 가능한 à-la-carte $0.10/1,000통 + 발송 데이터$0.12/GB | Starter $9/월부터·5,000통, 일 제한 없음. 상위 용량은 별도 견적/가격 선택 |
| 초과 | Pro $0.90/1,000통, overages 옵션 켠 경우에만. Free 초과 유료 자동전환 전제 금지 | 사용량 과금; 승인 quota 초과는 발송 불가 | 유료 volume tier/선불 credit 검토, 고정 초과단가 확인 안 됨 |
| 시간/초 제한 | 팀 기본10요청/초, SMTP에도 같은 rate limit. 별도 고정 시간당 quota 미명시; 일/월 제한 우선 | sandbox 1통/초·rolling24h200통. production은 리전별 승인된 초당/24h quota; 고정 월 quota 없음 | 과거 engagement 기반 시간당 transactional quota는2023-03-10 폐지. 현재 보편적 SMTP 시간당 숫자는 확인 불가; 일 credit·계정 제한 확인 |
| 확대 | Pro/Scale/Enterprise, 한도 상향 요청 | production quota 상향·리전 확장, IAM/모니터링 관리 필요 | 상위 월량/Enterprise; 마케팅과 섞지 않을 운영 설계 필요 |

근거: [Resend 가격표](https://resend.com/pricing.md), [현재 기능표](https://resend.com/pricing), [Resend rate limit](https://resend.com/docs/api-reference/rate-limit), [SES 가격](https://aws.amazon.com/ses/pricing/), [SES sandbox](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html), [Brevo 가격](https://help.brevo.com/hc/en-us/articles/208589409-About-Brevo-s-pricing-plans), [Brevo 시간당 quota 폐지](https://help.brevo.com/hc/en-us/articles/360021917460-Why-are-emails-added-to-a-queue).

SES 가격 주의: 2026-07-21부터 신규/해당 리전 비활성 계정에 Essentials 기본 적용 안내가 있다. 기존의 “무조건$0.10/1,000통” 설명은 부정확하다. à-la-carte 선택 여부와 로깅 비용을 확인한다. Pro/Enterprise SES 패키지는 이번 규모에 권하지 않는다.
Brevo $9는 월 결제 시작 tier이며 대량 tier까지 같은 가격이라는 뜻이 아니다. 연간 약정/로고 제거 add-on은 이 예산에서 제외한다.

### 예상 월비용 — 예산 시나리오, 실사용 예측 아님

| 전체 월발송 | Resend | SES Essentials 발송 기본료 | SES à-la-carte 발송 기본료 | Brevo |
|---|---:|---:|---:|---|
|1,000|$0(매일100 이하)|$0.16|$0.10|$0(매일300 이하)|
|3,000|$0(매일100 이하)|$0.48|$0.30|$0(매일300 이하)|
|5,000|$20|$0.80|$0.50|$0(매일300 이하) 또는 Starter$9|
|50,000|$20|$8.00|$5.00|50k tier 가격 별도 확인, $9로 간주 금지|

SES 데이터/이벤트 수집·SNS/CloudWatch 등 선택 비용은 별도이며 위 숫자를 최종 청구액으로 보지 않는다.
초기 제안 예산은 Resend Free **추가 공급자 비용$0/월**, 필요 시 Pro **$20/월**. 기존 팀이 이미 유료면 증분비용은 계정 확인 후 계산한다. Google Workspace/도메인 기존 비용은 제외, 새 메일박스 유료 추가는 승인하지 않았다.

## 계정 승인·로그·인증 비교

| 항목 | Resend | SES | Brevo |
|---|---|---|---|
| 시작 조건 | 계정·verified domain·API key, 계정 발송 제한/신뢰 상태 확인. 무심사 즉시 운영 보장 안 함 | 리전별 sandbox 해제 신청, transactional 용도·웹사이트·반송/불만 대응 설명. 승인 전 일반 수신자 발송 불가 | 도메인/발신자 인증과 transactional 활성화. 미활성 신규 계정은 support ticket 요청 |
| SMTP 인증 | username `resend`, password=API key. 인증 전용 sending key | 해당 리전 SMTP username/password; 일반 AWS API secret이나 AWS 로그인 비밀번호 아님 | 계정 SMTP login + **SMTP key**; API key 아님 |
| 관측 | SMTP 메일도 Emails 목록, delivered/bounce/suppression·webhook. 일반 플랜30일 데이터 보존. SMTP 서버 원시로그는 제공하지 않음 | sends/deliveries/bounces/complaints/rejects/delay 이벤트를 configuration set으로 SNS/EventBridge 등 수집. 보존기간/비용은 저장소 설계에 따름 | sent/delivered/hard·soft bounce/blocked/complaint/deferred 로그·webhook. 기본 로그 무기한, 설정1–24개월; 대규모 이벤트 별도 보존 정책 |
| DNS | Dashboard가 제시한 DKIM 및 return-path SPF/MX 또는 CNAME 방식. DMARC 정합성 확인 | Easy DKIM CNAME, custom MAIL FROM이면 전용 하위도메인 MX+SPF; DMARC는 aligned DKIM 또는 SPF | Brevo code TXT + DKIM TXT 또는2 CNAME + DMARC. 공유 IP 인증에 루트 SPF/MX 추가 불필요 |

근거: [Resend SMTP](https://resend.com/docs/send-with-smtp), [도메인](https://resend.com/docs/dashboard/domains/introduction), [SES SMTP](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html), [SES 이벤트](https://docs.aws.amazon.com/ses/latest/dg/monitor-using-event-publishing.html), [SES MAIL FROM](https://docs.aws.amazon.com/ses/latest/dg/mail-from.html), [Brevo SMTP](https://help.brevo.com/hc/en-us/articles/7924908994450-Send-transactional-emails-using-Brevo-SMTP), [Brevo 활성화](https://help.brevo.com/hc/en-us/articles/115000188150-Troubleshooting-Issues-with-Brevo-SMTP), [Brevo DNS](https://help.brevo.com/hc/en-us/articles/12163873383186-Authenticate-your-domain-with-Brevo-Brevo-code-DKIM-DMARC), [Brevo 로그](https://help.brevo.com/hc/en-us/articles/208858829-Review-your-transactional-email-reports), [로그 보존](https://help.brevo.com/hc/en-us/articles/4415743225746-Configure-a-custom-retention-period-for-your-transactional-logs-and-email-previews).

SES에서는 Supabase가 별도 SES 헤더를 넣을 수 있다고 가정하지 않는다. identity에 default configuration set을 지정하는 방식을 사용한다([공식 설명](https://docs.aws.amazon.com/ses/latest/dg/managing-configuration-sets.html)).
어떤 공급자의 delivered도 수신함 배치/열람/인증 완료를 뜻하지 않는다. 인증 토큰이 포함된 메일 preview·전체 본문은 공유 보고서에 내보내지 않는다. 인증 메일 click/open tracking은 OFF 제안; 기존 feedback 도메인에 영향을 주는 설정이면 변경 범위를 다시 승인한다.

## 현재 주소와 DNS 읽기 결과

공식 고객지원 소스: 별도 LAB checkout의 `src/lib/business-info.ts`(읽기 당시 HEAD643f68e), `src/app/support/page.tsx`.
주 고객지원 `support@legendstudy.com`, 일반/제휴 `contact@legendstudy.com`.
공개 support URL의 HTTP 조회는403으로 **현재 배포 페이지 재확인 NOT TESTED**. 실제 수신 mailbox/alias 존재도 미확인이다.
기존 APP Wiki에는 `feedback@legendstudy.com`→Owner 운영 Gmail 전달 검수 기록이 있다. 이것은 고객지원 수신 주소와 역할이 다르다.

2026-11-11 공개 DNS를 `dig`로 조회하고 Gabia authoritative 서버의 MX/TXT/CNAME과 대조했다. 수정0.

| 이름/유형 | 실제 결과 | 보존 원칙 |
|---|---|---|
|`legendstudy.com NS`|`ns.gabia.co.kr`, `ns1.gabia.co.kr`, `ns.gabia.net`|Gabia 관리 권한 Owner 확인|
|루트 MX|priority1 `smtp.google.com`|고객지원 수신 Google 경로 유지|
|루트 SPF TXT|`v=spf1 include:_spf.google.com ~all`|두 번째 SPF 만들거나 Resend 때문에 교체하지 않음|
|`_dmarc` TXT|`v=DMARC1; p=none;`|기존 한 개 유지. rua 추가/정책 강화 별도 승인|
|`resend._domainkey` TXT|공개 DKIM `p=` 값 존재|Dashboard 현재 값과 대조; 값 교체/삭제 금지|
|`send` CNAME|`send.forge.rmta.net`|CNAME 이름에 MX/TXT를 중복 추가하지 않음|
|CNAME 대상 MX/TXT|`feedback.forge.rmta.net` 및 SPF 존재|공급자가 관리하는 대상 값; 임의 고정/복제하지 않음|

TTL600초, 대상 일부300초로 관측. 루트에는 Google verification과 의미 불명 TXT(`legendstudy.com. in txt `)도 존재하나 이번 범위에서는 그대로 둔다.
DNS 일부 selector 조회는 전체 zone 감사가 아니다. 공개 DNS만으로 Resend Verified나 Google DKIM/메일 수신 정상까지 주장하지 않는다.

### 권장 발신 주소와 필요한 DNS 작업

권장: **`auth@legendstudy.com` / Sender Name `레전드스터디`**. 아직 승인·생성되지 않은 후보다.
Owner가 Google Workspace에서 이 주소를 고객지원 수신함으로 연결하는 alias인지 확인/준비하면 답장도 처리할 수 있다. DNS MX 변경은 필요 없다. 신규 유료 mailbox 생성은 별도 판단이다.
대안: 현재 지원 수신이 확인된 `support@legendstudy.com`을 Sender로 사용하면 새 alias 작업을 줄일 수 있다. `feedback@`는 기존 관리자 알림 역할을 유지한다.

Resend 기존 도메인이 Verified이고 Dashboard 요구 레코드와 현재 DNS가 일치하면 **추가 DNS 작업0**이 목표다.
불일치할 때만 Owner에게 실제 Dashboard의 Name/Type/Value/TTL 변경 전후표를 제출한다. DKIM public 값은 도메인별 생성값이므로 미리 꾸며서 제공하지 않는다.
현재 `send`가 CNAME이므로 과거 예제의 `send MX + TXT include:amazonses.com`를 그대로 추가하면 충돌한다. 공급자 표시값이 다를 때 원인 확인 없이 덮어쓰지 않는다.
향후 마케팅 분리가 필요하면 별도 `auth.legendstudy.com` 발신 도메인을 검토하되, 지금은 이미 검증 이력이 있는 루트 도메인 재사용을 우선한다. 새 하위도메인은 별도 인증 및 반송/수신 경로 설계가 필요하다.

대체 공급자 선택 시:
- SES: 공급자가 생성한3개 Easy DKIM CNAME. MAIL FROM은 기존 `send` 대신 미사용 이름을 고르고, 콘솔의 지역별 MX/SPF를 해당 하위도메인에만 등록. 루트 Google SPF/MX 유지.
- Brevo: 실제 Brevo code TXT와 DKIM TXT/CNAME 추가. 기존 DMARC는 중복 생성 금지, 필요한 rua 수정은 별도 승인(보고서 수신 목적지 포함). DNS 자동 연결 대신 수동 검토로 기존 레코드 변경을 통제한다.
- DNS 검증은 authoritative와 public resolver, 공급자 Verified를 모두 확인. 그 후에만 승인된 소량 메일의 SPF/DKIM/DMARC 결과와 alignment를 검사한다.

## Supabase 입력 준비표 — 비밀값 미포함

| 설정 | 추천 Resend | 대안 SES 서울 | 대안 Brevo |
|---|---|---|---|
|SMTP Host|`smtp.resend.com`|`email-smtp.ap-northeast-2.amazonaws.com`|`smtp-relay.brevo.com`|
|Port|`465` implicit TLS|`587` STARTTLS|`587` STARTTLS 또는465 TLS|
|Username|`resend`|Owner 생성 리전별 SMTP username|Dashboard의 SMTP login|
|Password|Owner 생성 인증 전용 API key|Owner 생성 SMTP password|Owner 생성 SMTP key|
|Sender Email|`auth@legendstudy.com` 승인 후보|동일, 해당 identity 인증 필요|동일, sender 인증 필요|
|Sender Name|`레전드스터디`|동일|동일|

[Resend Supabase 공식 입력값](https://resend.com/docs/send-with-supabase-smtp), [SES 서울 endpoint](https://docs.aws.amazon.com/general/latest/gr/ses.html).
비밀값은 Owner가 공급자→Supabase Dashboard에 직접 입력한다. Git/Wiki/채팅/명령행 인수에 넣지 않는다.
기존 feedback worker의 API key를 읽거나 회전하지 않고, 인증 전용 least-privilege key를 만든다. 기존 LegendStudy 팀이 다른 프로젝트와 공유되는지 확인하고 Muselry 도메인/키를 사용하지 않는다.

Supabase 경로: LegendStudy 프로젝트 확인 → Authentication → Emails → SMTP Settings.
**Save가 운영 전환 시점**이므로 준비 단계에서는 저장하지 않는다.
전환 직후 Rate Limits의 실제 email/hour 값을 확인한다. [현 공식 문서](https://supabase.com/docs/guides/auth/auth-smtp)는 custom SMTP 초기30통/시간을 설명하나, 이 프로젝트의 전환 후 값은 미확인이다. Supabase 한도와 공급자 quota는 별개다.
초기 제안은30통/시간·사용자 간격60초, Confirm Email ON·OTP3600초·기존 redirect allowlist 유지. 값 적용/증가 모두 별도 승인한다. Free100/day는 Supabase30/hour만으로 보장되지 않으므로 팀의 일 사용량도 확인한다.

## 운영 전환 순서와 합격 기준

| 단계 | Owner/담당 작업 | 다음 단계 조건 |
|---|---|---|
|1 SMTP 계정 준비|공급자/플랜 최종 승인, 기존 LegendStudy 팀·잔여 quota 확인, 인증 전용 키 생성|다른 프로젝트와 격리, 비용/키 범위 확정|
|2 발신 도메인 인증|기존 Verified 및 발신/수신 주소 확인; 필요 DNS 변경안만 승인|기존 feedback·Google 수신 보존|
|3 DNS 검증|권한 DNS/public resolver/공급자 화면 대조|DKIM/return-path/DMARC 정상|
|4 Supabase 설정|TEST 대상 먼저 지정·승인, 이후 별도 운영 승인으로 위6필드 저장|SMTP·한도 변경 전후 기록, 비밀 제외|
|5 소량 발송|Owner가 지정한 수신함만, 권장 TEST 총6통 이하|accepted와 delivered를 별도 기록|
|6 신규 가입|iOS/Android 신규 TEST 계정 각1, 링크→앱→로그인→온보딩|confirmed/session/profile 상태 정상|
|7 비밀번호 재설정|전용 TEST 계정1회|링크→비밀번호 설정→로그인, 비밀번호/토큰 기록 금지|
|8 재발송|미인증 TEST 계정1회,60초 대기·연속 탭 검사|클라이언트 중복0, 신규 링크 정상|
|9 로그 대조|Auth 요청시각/request ID와 provider message ID/수신 헤더 연결|delivered/지연/반송/차단 구분, 관련 사용자 노출 금지|
|10 장애 원복|아래 중단 기준이면 즉시 추가 요청 중단·Owner 원복|기존 로그인/feedback/수신 유지|

TEST6통 예산 예: signup2 + recovery1 + resend1 + 만료 링크용1 + 공급자 공식 bounce simulator1(지원 확인 후). 실제 임의 주소로 반송을 유도하지 않는다. TEST Supabase는 Owner가 지정한 격리 환경에만 설정하며 기존 결제 TEST 프로젝트를 임의 변경하지 않는다.
만료/중복클릭·429·SMTP거부/timeout은 우선 격리 mock으로 검증, 운영에 반복 발송하여 한도를 소모하지 않는다. 만료 실검증은 TEST의 실제3600초 경과로 수행하고 운영 TTL을 줄이지 않는다.
앱 종료/cold start, 같은 기기/warm, 다른 기기 인증 뒤 비밀번호 로그인, 앱 복귀 실패 뒤 수동 로그인, 기존 이메일/Google/Apple/Kakao 회귀를 확인한다. 운영 최종 최소 smoke는 별도 승인된 수신함·건수(예3통)로만 수행한다.

로그 연결 시 Supabase request ID와 공급자 message ID가 자동으로 같은 값이라고 가정하지 않는다. private console에서 시각·수신자·제목·SMTP response/메일 Message-ID를 대조하고 연결 증거가 없으면 UNKNOWN으로 남긴다. 공개 Wiki에는 익명 case와 결과만 기록한다.
성공 기준은 실제 수신함·인증 완료·앱 로그인·온보딩까지이며 SMTP250/provider accepted만으로 완료 판정하지 않는다. 기본 서비스가 과거 보낸5명의 전달 로그가 새 Resend 로그에 소급 생성되지는 않는다.

## 장애 원복 및 중단 기준

- 즉시 중단: SMTP 인증/TLS 오류, 승인한2개 시험 수신함 모두5분 내 미수신(진단 기준일 뿐 SLA 아님), repeated bounce/blocked, 링크 변조/앱 복귀 회귀, 기존 feedback 또는 수신 영향.
- 전환 전 SMTP OFF·2/h, Confirm Email ON·3600초, Site URL/redirect와 템플릿을 비밀 제외 스냅샷으로 보존한다.
- Owner가 custom SMTP OFF와 이전 한도/변경 필드로 복원. 기본2/h 문제는 재발하므로 “운영 정상화”로 보고하지 않는다. 기존 로그인 세션은 유지하고 계정 삭제/강제 인증하지 않는다.
- DNS는 가능한 유지한다. 특히 기존 Google MX/SPF·Resend DKIM·`send`·feedback 키는 삭제하지 않는다. 신규 인증 전용 키만 더 이상 사용하지 않는지 확인 후 회수한다.
- 가입/재발송 UI 개선 c5cd349는 SMTP와 독립이므로 기본적으로 유지한다. 앱 회귀가 입증된 경우만 별도 릴리스 원복.
- 대체 공급자 자동 failover, Auth Hook, DB queue는 이번 범위에 추가하지 않는다.

## Owner가 직접 수행할 일과 승인 요청

1. **Resend 우선 선택 / 초기 Free 검증** 최종 승인. 유료 Pro는 필요 시$20/월 별도 승인.
2. 기존 LegendStudy Resend 계정의 팀·현재 플랜·일/月잔여량·Verified·sending 상태 확인. 키 값은 전달하지 않는다.
3. Sender `auth@legendstudy.com` 및 Google alias 수신 연결 승인/준비(또는 기존 support 주소 선택).
4. DNS 차이가 발견되면 실제 변경 전후표 승인 후 Gabia에서 적용. 현재는 변경0이 목표다.
5. TEST 프로젝트·수신함·최대6통 검증 승인. 테스트 결과 후 운영6필드·한도·최소smoke 건수를 별도로 승인하고 Dashboard에 직접 입력한다.

이번 결과는 조사/준비 완료이며 **공급자 계정 현재 상태, 실제 SMTP 연결/전달, 운영 전환은 NOT TESTED/NOT APPLIED**다.
코드 변경0·c5cd349 보존·논술 LAB 파일/SQL/Registry 변경0. 문서만 변경하여 Flutter 회귀를 재실행하지 않는다.
