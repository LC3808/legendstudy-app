# 이메일 인증 대기·발송 한도 조사 — 2026-11-11

**PARTIAL — 읽기 전용 진단, SMTP 전달 결과 미확인**.
Owner가 신규 온보딩 가입 중 빈번 요청 오류·인증 메일 미수신을 보고했고 시도 계정을 직접 삭제했다고 회신했다.
이후11/9·10·11 가입자의 인증 대기 화면3개를 제공했다. 다른 사용자 메일 재발송/삭제/강제 인증은 요청되지 않았고 수행하지 않았다.
[기존 이메일 인증 검수](app-release-integration-20261103.md#후보-a-이메일-세션오입력-재시도-owner-확인--2026-11-03)는 기존 계정 로그인 검수로, 신규 메일 전달 성공의 증거가 아니다.

## 확인한 사실

LegendStudy 운영 프로젝트의 auth.users를 SELECT로 집계했다. 기간은 KST11/9 00:00부터11/12 00:00 미만이며, 조회 시점 현재 존재하는 `provider=email` 계정이다. 삭제된 시도는 이 집계에 포함되지 않는다.

| 가입일 KST | 현재 계정 수 | 인증 완료 | 미인증 | 미인증 중 발송 시각 있음 |
|---|---:|---:|---:|---:|
|11/9|4|3|1|1|
|11/10|8|6|2|2|
|11/11|7|5|2|2|
|합계|19|14|5|5|

첨부3개 가입 시각(11/9 08:04:28,11/10 15:18:13,11/11 15:39:39)의 계정은 모두 confirmation_sent_at이 있으며 email_confirmed_at/last_sign_in_at은 NULL이다.
메일 주소·UUID는 이 문서에 복제하지 않는다. 발송 시각은 수신함 배달·열람·링크 클릭 성공의 증거가 아니다.

각 날짜24시간 범위의 auth_logs에서 오류 코드 문자열을 집계했다:

| KST | over_email_send_rate_limit 로그 | email_not_confirmed 로그 |
|---|---:|---:|
|11/9|0|3|
|11/10|0|13|
|11/11 조회 시점까지|21|5|

이는 로그 이벤트 수이며 고유 사용자/가입 요청 수가 아니다. 해당 검색 범위에서 SMTP 문자열/email_address_not_authorized 매칭은 없었으나 SMTP 정상/메일 수신을 입증하지 않는다.
오늘 발송 한도 오류는 확인됐지만 과거3개 계정의 미인증 원인이 모두 같다고 단정할 수 없다.

## 미확인과 후속

- 현재 custom SMTP 사용 여부·실제 발송 제한값, 발송업체 message ID/accepted/delivered/bounce/suppression 기록 미확인.
- 스팸함·주소 오타·미클릭·링크 만료·redirect 문제도 개별 확인 전 미확정이다.
- 다음 읽기 전용 단계는 Supabase Auth의 Email/SMTP·Rate Limits 실제 설정 확인, 발송업체에서 해당 시각의 전달/반송 결과 대조다. SMTP 비밀번호/API key를 공유 문서에 넣지 않는다.
- [공식 rate-limit 문서](https://supabase.com/docs/guides/auth/rate-limits)는 이메일 발송의 프로젝트 단위 제한을 설명한다. 계정 삭제를 한도 해제 수단으로 사용하지 않는다.
- [공식 custom SMTP 문서](https://supabase.com/docs/guides/auth/auth-smtp)의 기본 메일 서비스 제한을 현재 프로젝트 설정으로 추정하지 않는다. 기본 서비스 사용이 확인될 경우에만 별도 SMTP 운영 개선안을 준비한다.
- 수정 승인 전 Auth 설정/인증 정책/DB/RPC 변경, 인증 우회, 메일 재발송0. 신규 온보딩은 메일 인증을 통과하지 못했으므로 **NOT TESTED**다.


## 독립 안정화 조사 — 2026-11-11

**LOCAL FIX VERIFIED / PRODUCTION EMAIL READINESS BLOCKED**.
운영 Auth/SMTP/사용자/DB/RPC 변경, 테스트 메일, LAB 변경, 배포, Store 제출 모두 0.
본 절은 앞선 SMTP 설정 미확인을 실제 Dashboard 조회로 갱신한다.

### 기준과 작업 격리

- 브랜치: `codex/email-auth-stabilization-20261111`.
- Worktree: `/Users/woojinchang/.codex/worktrees/email-auth-stabilization-20261111/legendstudy-app`.
- 실제 기준: `4489603` (알림 제한·작업04 기기 검증); APP75 source `c9b4830`, 검수 기록 `633f982`를 포함한다. 오래된 main 미사용.
- source는 `codex/essay-natural-expansion-20261111`의 검증된 APP 상태만 시작점으로 사용했다. 생성 당시 untracked 자연계 SQL/Registry/Python 파일은 복사하지 않았다.
- 조사 중 source는 `9e6d38f`로 이동(알림 iPhone 확인 문서만). cherry-pick/merge하지 않았다.
- 공통 충돌 후보: `wiki/current-status.md`, `wiki/log.md`. 인증 기록 갱신에 필요하며 릴리스 통합에서 양쪽 문단을 보존해야 한다. source의 후속 변경과 Auth 코드 중복은 없음. LAB 작업 파일·SQL·Registry diff 0.

### 실제 발송 경로와 운영 설정

LegendStudy `stlhijzpjfgwwdgunlsd`만 조회했다. Supabase connector에는 Auth 설정 조회 기능이 없어 로그인된 Dashboard를 읽기 전용으로 확인했다.

| 항목 | 확인 결과 |
|---|---|
| 공급자 | Supabase built-in email service; 외부 custom SMTP OFF |
| 프로젝트 이메일 한도 | 실제 Rate Limits 화면 **2 emails/h**, 비활성 필드 |
| 일일 제한 | 별도 설정/수치 확인 불가 — NOT TESTED, 48/day로 추정하지 않음 |
| 사용자 간격 | UI 60초, custom SMTP에만 적용한다고 표시; 현재 기본 서비스의 정확한 per-user 정책으로 단정하지 않음 |
| 가입/이메일 인증 | Allow new users ON / Confirm email ON |
| 인증 OTP/링크 만료 | 실제 Email 설정 **3600초** |
| 가입 메일 템플릿 | 제목 `Confirm your email address`; 본문 표준 `{{ .ConfirmationURL }}` 링크 |
| Site URL | `https://lab.legendstudy.com` |
| Native 허용 redirect | `com.legendstudy.app://login-callback`, `com.legendstudy.app://auth-recovery` 모두 등록 |
| 외부 SMTP accepted/delivered/bounce/suppression | 제공업체 전달 로그 접근 불가 — **NOT TESTED** |

앱 `Supabase.initialize` → 잠긴 supabase_flutter2.15.4/GoTrue2.25.0의 기본 PKCE →
`signUp(emailRedirectTo: AppConfig.signupRedirectTo)` → Supabase Auth → built-in mail.
새 재발송도 같은 config로 `resend(type: signup)`을 호출한다. SDK HTTP 격리 검사로 PKCE challenge·redirect 확인.
앱 define이 비면 Site URL fallback이므로 **실제 다음 릴리스의 define 포함 여부는 빌드에서 별도 확인**한다.
Android manifest/iOS URL scheme 및 기존 callback 처리 유지. 서버가 인증 세션을 제공해야 기존 signedIn→Home→onboarding gate로 진입한다.
앱 재실행/다른 기기에서 인증 완료 시 이메일·비밀번호 로그인으로 확인하며 자동 폴링/자동 메일 없음.
다른 설치의 PKCE verifier는 공유되지 않으므로 모든 기기에서 링크 교환 성공을 보장하지 않는다.

[공식 SMTP 문서](https://supabase.com/docs/guides/auth/auth-smtp)는 기본 서비스를 운영용으로 권장하지 않으며 수신자 제한을 설명한다.
이 일반 정책을 미인증5명의 개별 실패 근거로 쓰지 않는다. 현재 확인된 오류는 아래 Auth rate limit이다.
[공식 제한 문서](https://supabase.com/docs/guides/auth/rate-limits),
[Flutter resend 계약](https://supabase.com/docs/reference/dart/auth-resend), 설치된 SDK 소스를 대조했다.
Changelog의 v3 변경은 확인했으나 현재 v2 고정 의존성은 업그레이드하지 않았다.

### 21건 재분석

조회 기간 KST11/11 00:00–11/12 00:00 미만(UTC11/10 15:00–11/11 15:00).
Auth 로그의 `over_email_send_rate_limit` 21건 = HTTP429, POST, 서로 다른 request_id21개.
Auth의 path는 `/`이므로 그 값으로 요청 유형을 추정하지 않고 edge_logs의 같은 request_id를 연결했다.

| 실제 endpoint | 오류 건수 | 클라이언트 |
|---|---:|---|
| `/auth/v1/signup` | 18 | Android12 / iOS6 |
| `/auth/v1/magiclink` | 3 | client header 없음; 실행 주체 미확인 |
| `/auth/v1/resend` | 0 | 해당21건에 없음 |
| `/auth/v1/recover` | 0 | 해당21건에 없음 |

모두 auth_event.action=`user_confirmation_requested`. Auth가 반환한 프로젝트 이메일 한도 오류이며 외부 SMTP 사업자의 quota/bounce 오류라는 근거는 없다.
고유 actor ID18개지만 고유 이메일 식별값은4개다. 실패 가입에서 임시 actor가 생길 수 있어 실제 사람18명/21명으로 보고하지 않는다. 실제 고유 사람 수는 미확인.

| 익명 요청 묶음 | KST 최초–최종 | 총 오류 | actor ID 수 |
|---|---|---:|---:|
| R1 |15:42:29–15:42:34|2|1|
| R2 |18:25:13–18:25:22|10|10|
| R3 |20:59:44–21:00:08|3|1|
| R4 |21:00:48–21:07:04|6|6|

오류 발생 시각(KST):15:42:29,15:42:34;18:25:13,15,15,16,16,16,17,17,18,22;
20:59:44,50;21:00:08,48,53;21:01:19;21:02:13;21:03:26;21:07:04.
같은 초의 반복은 distinct request_id이므로 제거하지 않았다. 이메일/UUID/IP/토큰/원문 callback은 보고서에 저장하지 않는다.

### 미인증5개 재조회 및 분류

현재 존재하는 이메일 계정19/인증14/미인증5 집계 재현. 삭제된 가입 시도는 제외.
U번호는 이 조회의 created_at,id 순서 익명 별칭이며 공개 식별자로 사용하지 않는다.

| 별칭 | 가입일 KST | confirmation_sent_at 있음 | 인증/로그인 기록 | 분류 |
|---|---|---|---|---|
|U1|11/9|예|둘 다 없음|E 원인 미확인|
|U2|11/10|예|둘 다 없음|E 원인 미확인|
|U3|11/10|예|둘 다 없음|E 원인 미확인|
|U4|11/11|예|둘 다 없음|E 원인 미확인|
|U5|11/11|예|둘 다 없음|E 원인 미확인|

A 발송 요청 실패 / B SMTP 성공·전달 실패 / C 전달 성공·미인증 / D 링크 오류에 배정할 개별 근거 없음.
발송 시각은 요청 처리 흔적일 뿐 SMTP accepted/delivered 로그가 아니다. 앞선 오류4개 식별값과 U1–U5의 동일성도 확인되지 않았다.
공급자 로그가 없어 성공 요청의 실제 전달·반송·차단은 NOT TESTED다.

### UX 수정과 보존

- 기존 재발송 동선 없음 → 로그인 화면에 명시적 인증 메일 다시 요청 추가. 비밀번호 없이 이메일 형식만 확인.
- 가입/재발송 연속 요청 → 실행 중 공유 busy guard + 60초 process-local cooldown. 화면을 다시 열어도 같은 ProviderContainer에서 유지. 앱 완전 종료 시 로컬 cooldown은 초기화되고 서버 제한은 유지된다.
- 60초는 재요청 UX 간격이며 서버 한도 리셋/메일 도착 보장 시간이 아니다. 한도 오류에 반복 요청 중단·나중에 재시도·문의 안내.
- 성공은 “발송을 요청했어요”, 실제 전달 성공 주장 없음. 인증된/없는 주소의 존재 여부를 노출하지 않는다.
- 가입 성공 후 Form.reset이 이메일 입력을 지우던 문제를 격리 테스트에서 발견, 요청 이메일만 복원. 비밀번호는 삭제 유지.
- 만료/중복 링크의 공유 오류 문구를 인증 중립적으로 정정. 기존 recovery 라우팅은 유지하며 가입 재발송은 로그인 화면, 비밀번호 재설정은 recovery 화면으로 구분 안내.
- 인증 완료 후 SDK signedIn/기존 로그인/온보딩 gate 재사용. 서버 인증 우회·강제 인증·비밀번호 보관 없음.

수정 코드: `lib/features/auth/auth_email.dart`, `lib/features/auth/auth_errors.dart`,
`lib/features/auth/presentation/auth_page.dart`.
테스트: `test/email_verification_test.dart`, `test/auth_recovery_test.dart`.
문서: 본 문서, `auth-recovery.md`, `current-status.md`, `log.md`.

### 검증 및 남은 앱 업데이트 게이트

고정 helper의 실제 SDK Flutter3.47.6 / Dart3.13.5 사용(오래된 toolchain Wiki의3.47.5와 구분).
Mock HTTP/Provider fixtures만 사용. 운영 SMTP 요청0.

- 인증 집중10파일 최종143 PASS: signup 세션 유무/redirect, 신규 가입 안내·이메일 보존, 재발송 PKCE, 중복 탭, 성공/429 문구, cooldown 만료, 대기 중 로그인, SDK session 재시작/로그아웃, 만료·재사용 링크, 기존 로그인·소셜 취소/성공·Kakao, 온보딩 분기/저장 실패 회귀.
- `flutter analyze --no-pub`: PASS. `git diff --check`: PASS. Wiki 링크/라우팅 검사: PASS(3276링크/current-status7042bytes). Credential signature scan PASS, LAB/SQL 변경0.
- 실제 이메일 수신→인증→앱 복귀→신규 온보딩, 다른 기기/앱 종료 링크 수신, 실제 소셜 제공업체 로그인: **NOT TESTED**. 기존 fixture PASS로 실제 E2E를 대체하지 않음.
- 이번 변경의 iOS/Android 빌드·실기기 설치·Store 제출 미실행. 릴리스 통합 후 build define, 작은 화면·2배 글꼴, iOS/Android 실제 메일 최소건 검증 필요.

### Owner 운영 변경 승인안 — 아직 미적용

원인: 기본 서비스2통/시간으로 APP/WEB의 가입·매직링크·복구가 프로젝트 한도를 공유한다.
코드 개선만으로 실제 발송 용량/전달 관측을 해결할 수 없다.

1. LegendStudy 전용 custom SMTP 도입 승인 및 공급자/요금·발신 도메인 선택. Muselry 자격증명/설정 재사용 금지.
2. 제공업체 확정 후 DNS SPF/DKIM/DMARC, 발신자, TLS, 시간/일 quota, bounce/suppression·delivered 로그 보존을 점검하고 정확한 설정값을 Owner에게 제출. 현재 공급자 미정이므로 임의 endpoint/자격증명/요금을 승인안에 꾸며내지 않는다.
3. 별도 TEST에서 먼저 가입1·재발송1·복구1 전달, 만료/재사용, iOS/Android cold/warm return, 다른 기기 인증 후 로그인 검증. 운영 사용자를 강제 인증/삭제하지 않는다.
4. 운영 전환은 **Owner 별도 승인 후 직접 실행**. 기본2/h에서 올릴 수치는 실제 예상량과 공급자 quota 확인 뒤 승인. Confirm email ON,3600초 및 callback allowlist 유지.
5. 영향: 동일 LegendStudy 프로젝트 APP/WEB 전체 인증 메일 경로에 적용; 기존 세션·계정·DB schema는 변경하지 않는다. 발송비용과 공급자 개인정보 처리 범위도 Owner 검토.
6. 검증: 승인된 시험 계정 최소건으로 Auth request_id→provider message ID→delivered→인증→로그인→온보딩 연결. 실패 시 반복 전송 중단, bounce/suppression 원인 확인.
7. 원복: 전환 전 비밀값 제외 설정 스냅샷과 기존 템플릿 보존. 오류 시 Owner가 custom SMTP OFF 및 기존2/h로 복원. 이는 용량 문제를 다시 가져오므로 정상화 완료로 보지 않는다. 토큰/비밀번호/계정 삭제로 원복하지 않는다.

운영 SMTP 전환 승인·공급자 확정,5명 전달 근거,최소 실제 가입 E2E,릴리스 통합이 남아 있으므로 **인증 안정화 전체 완료/앱 업데이트 가능 판정은 보류**다.
