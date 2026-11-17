# Finance 인증 자동 갱신 — 2026-11-17

상태 **PARTIAL — 구현·로컬/실제 읽기 검증 완료, 운영 설치·전환 Owner 승인 대기**.
기존 [LIVE 승인·환불 기록](toss-live-owner-qa-preflight-20261115.md)과 [인증 수명 검토](essay-jwt-lifecycle-review-20261023.md)를 계승한다. Owner의 이번 요청은 Finance 자동화를 구현하되 운영 적용 순서의 **“5. Owner 승인”**을 유지한다. 실제 결제·환불 시험은 금지되어 수행하지 않았다.

## 기존 계약 및 실제 확인

- Pages `legendstudy-lab` Production → Supabase `stlhijzpjfgwwdgunlsd` REST RPC. Edge Function 발급/검증 구조가 아니다.
- 기존 로컬 발급 스크립트 `/tmp/payment-public-20261117/preflight.mjs`: Owner 보관 EC 키로 JWT 발급, 읽기 검증 후 Secret 교체·Pages 배포. 장기 보존 구현은 이번 WEB `cloudflare/finance-auth/credential.ts`로 이전한다.
- 알고리즘 ES256 / EC P-256, kid는 현재 Supabase JWKS와 대조. issuer `https://stlhijzpjfgwwdgunlsd.supabase.co/auth/v1`, audience `authenticated`, role `essay_finance`, 기존 sub 유지, iat/exp만 갱신. TTL 604800초(7일).
- 서명 신뢰는 Supabase JWT 검증 계층, RPC 실행권은 PostgreSQL ACL이 검증한다. `payment_process`/`payment_support`는 기존 `essay_private.uid()` 검사와 전용 ACL을 유지한다.
- `essay_finance`: login/super/bypassrls 모두 false, 직접 테이블 grant 0. service_role 대체0, SQL/GRANT/함수 변경0.
- 현재 `PAYMENT_FINANCE_TOKEN` Secret 만료 **2026-11-24 18:03:34 KST**. Production LIVE/enabled=true 유지. review TEST 전용 유지.
- 기존/신규 후보 모두 `payment_process(get, 00000000-0000-0000-0000-000000000000)` → HTTP404/PT404. 실제 함수 정의에서 미존재 주문은 잠금·쓰기 전에 예외 종료하는 것을 확인했다. 익명 동일 호출 HTTP401.
- 서명키는 과거부터 Owner 로컬 보안 파일에 존재한다. 이번에는 메모리에서만 사용하고 외부 업로드/로그/Git 저장하지 않았다. Node crypto에서는 허용하던 JWK 사용 메타데이터가 WebCrypto import와 호환되지 않아 EC 숫자·kid를 보존하고 import 속성만 정규화했다. 새 키 생성/회전 없음.
- [비밀 없는 사전검증 영수증](evidence/finance-auth-preflight-20261117.json).

## 방식 비교와 선택

| 방식 | 보안·권한 | 복잡도·안정성 | 만료·복구·배포 |
|---|---|---|---|
| A: Pages 직접 서명 | JWT role 고정 가능하지만 WEB 공격면에 프로젝트 서명권한을 둠 | 단순하나 다중 인스턴스 조율·영속 상태 별도 필요 | 재배포 없이 발급, 서명키 침해 영향이 큼 |
| B: 스케줄러가 Pages Secret 교체 | 서명키와 Cloudflare 설정/배포 권한 모두 필요 | 설정 PATCH·배포·부분 실패를 매번 처리해야 함 | 배포 실패가 갱신 실패가 됨; 이전 배포/Secret 복원 필요 |
| C: Supabase Auth 구조 변경 | 전용 클라이언트/역할 연결 검토 필요; service_role 대체 금지 | 기존 Auth·DB 계약 변경과 추가 운영 검증 필요 | 이번 P0에서는 기존 계약 보존을 우선 |
| **선택: A의 발급을 비공개 전용 Worker에 격리** | WEB에는 서명키 없음, private service binding만 사용. 발급 claims/대상 고정 | 하나의 Durable Object로 전역 직렬화·암호화 영속 상태 관리 | 요청 시 갱신 + alarm/cron 감시. 갱신마다 Secret 변경/재배포 불필요 |

같은 프로젝트 서명키는 **암호학적으로 Finance 역할에만 제한된 키가 아니다**. 전용 Worker의 코드가 role/sub/audience/issuer를 고정하지만, Worker/Secret 관리자 권한이 침해되면 더 넓은 토큰 발급 위험이 있다. 이 때문에 공개 라우트·workers.dev·preview URL을 모두 금지하고 서명키는 Pages에 등록하지 않는다. 신규 Worker에 기존 서명키를 보관하는 행위까지 Owner 운영 승인 범위에 명시한다.

## 구현

WEB 저장소 `cloudflare/finance-auth/`:

- `credential.ts`: 고정 Production issuer/JWKS와 키 일치 확인 → ES256 서명 → 공개키로 자체 서명/claims 검증 → 읽기 RPC 검증.
- `core.ts`: 기존7일 TTL, 남은20%(33시간36분) 이하 갱신. 실패 시 유효한 active 보존, 60/300/900/3600초 재시도(최대1시간). 만료·거절 토큰은 반환하지 않는다.
- `worker.ts`: `FinanceVault` 단일 이름 `production-v1`. 동일 DO의 promise 직렬화로 요청/alarm 경쟁을 방지한다. 새 토큰 검증·영속 저장 성공 뒤 교체. active/previous와 메타데이터는 AES-256-GCM 암호문으로 저장한다. 서명키·암호화키는 Worker Secrets만 사용.
- 정상 alarm 최대1시간, cron15분은 같은 singleton을 깨워 갱신/읽기 상태를 확인한다. 상태 확인 시 읽기 probe 최대15분 간격. 장애 로그는 event/유한 오류 코드/시각/잔여시간만 포함한다.
- `wrangler.bootstrap.jsonc`: cron 없이 초기 설치; `wrangler.jsonc`: 15분 cron. 둘 다 public route 없음, workers_dev=false, preview_urls=false.
- `finance-client.ts`: Pages private binding에서 토큰을 얻는다. `PAYMENT_FINANCE_AUTO` 미설정/false는 기존 동작, `shadow`는 상태만 후보를 검증하고 결제는 기존 토큰, `true`일 때 자동 토큰 사용. 브로커 장애 시 유효하고 거절되지 않은 기존 Secret만 fallback.
- Finance 전송 목적지는 Production의 payment_process/payment_support/payment_compensate 세 RPC로 제한. 사용자 세션은 기존 buyer RPC에 그대로 사용한다.
- HTTP401+PGRST301/303처럼 RPC 실행 전 JWT 거절이 확인된 경우에만 새 토큰으로 동일 본문을 딱1번 재시도. timeout/네트워크/5xx/403/업무 오류/토스 API는 재실행하지 않는다. 기존 요청키·원장 멱등성 계약 유지.
- `/api/payments/finance-auth-status`: fresh Auth로 고정 Owner UID 확인, 일반/다른 관리자 거절. 서비스 응답에서 허용한 메타데이터만 재구성하여 반환한다. 토큰/개인키 반환 없음.
- 기존 `/admin/payment/`에 Finance 인증 상태 패널 추가: 수동/검증/자동/fallback, 남은시간, 만료, 마지막 성공·실패, 재시도, 경고. ‘인증 상태 확인’으로 조회한다. 별도 관리자 시스템/사용자 알림 탭은 만들지 않았다.

## 모니터링 범위

Owner는 기존 외부 알림 채널이 없고 관리자 화면으로 확인한다고 답했다. 따라서 이번 범위는 관리자 경고 + 비밀 없는 Cloudflare 로그이다. 이메일 후보는 ceo@copacabana.co.kr/admin@legendstudy.com이나 **발송 수단·수신 주소 확정/전송 승인 없음**, 메일/Slack/Telegram 발송0. 신규 WEB 알림 탭은 후속 설계 대상으로 분리한다.

관리자가 열지 않아도 받는 push 경고, Cloudflare 전체 장애를 탐지하는 외부 heartbeat 감시는 **미구현**이다. cron+alarm은 모두 Cloudflare 의존이며 외부 독립 감시라고 표현하지 않는다. 키 폐기/네트워크 장애가 갱신 여유기간 전체에 지속되면 중단 위험이 남는다.

## 검증

- 전체 WEB 회귀: **2161 PASS / 5 SKIP**(최종 목적지 제한·shadow 추가 전). 이후 변경 관련 최종 결과는 아래 마감 기록에 기재한다.
- 정상/20% 경계/만료/실패 보존/지수 backoff/거절 토큰/동시40요청/재시작/저장 실패/읽기 네트워크 오류/401/PGRST303/비허용 대상/Owner 권한/Secret 비노출을 합성 테스트.
- 새 ES256 후보로 실제 Production 읽기 성공, old/candidate 비시간 claims 일치. 익명 요청 차단. 후보 토큰은 운영 Secret에 등록하지 않았다.
- 검증 전후 주문22·작업13·원장889행 동일, payment_process 정의 MD5 `0dcccf66129e06eb3535da797b56f8f6` 동일, RPC ACL 동일. 실제 결제·환불·SQL 변경0.
- TS/ESLint/Next production build/Pages Functions compile/전용 Worker dry-run 검증. 실제 CF 다중 지역 실행·alarm/cron·관리자 화면 운영 E2E는 **NOT TESTED — 승인 후**. 시간 이동/동시 요청 테스트와 운영 증거를 구분한다.

## 정확한 운영 변경안 — 승인 전 실행 금지

1. 현재 Pages deployment/config/API/static manifest를 다시 읽고 보존 영수증을 만든다. 이번 기준은 `fb94f1da-0603-4a45-9d65-d387edb730b7`; 다른 배포가 생기면 새 기준으로 재검토한다.
2. 동일 LegendStudy Cloudflare 계정에 **legendstudy-finance-auth** Worker + **FinanceVault SQLite Durable Object namespace**를 bootstrap 설정으로 설치한다. 공개 routes/workers.dev/preview URL은 없다. 기존 서비스/DB는 변경하지 않는다.
3. 전용 Worker Secrets **FINANCE_SIGNING_JWK**, **FINANCE_SUBJECT**, **FINANCE_PUBLISHABLE_KEY**, **FINANCE_STORAGE_KEY** 등록. 기존 서명키/subject/publishable을 안전한 메모리 경로로 재사용하고 저장 암호화키만 암호학적 난수32바이트로 신규 생성한다. 로그/채팅/CLI 인자/Git으로 전달하지 않는다. 기존 키를 Rotate/Revoke하지 않는다.
4. Worker 정상 설정을 배포하여15분 cron 설치. Pages Production service binding **FINANCE_AUTH → legendstudy-finance-auth** 추가. Preview에는 연결하지 않는다.
5. Pages에 **PAYMENT_FINANCE_AUTO=shadow** 추가하고 검증한 결제 Worker 코드·관리자 상태 화면만 배포. 기존 PAYMENT_FINANCE_TOKEN은 그대로 보존. 그 외 모든 설정·정적 페이지·API 입력을 비교한다. `PAYMENT_MODE=LIVE`, `PAYMENT_ENABLED=true`, `PAYMENT_PUBLIC_ENABLED=true`, Toss 키, review 설정은 변경하지 않는다.
6. Owner 상태 API/관리자 패널에서 후보 읽기·만료·마지막 성공 확인. 비Owner API403. 실제 알람/cron heartbeat와 encrypted storage 재시작을 확인한다. 실패 시 여기서 중지하며 기존 결제 토큰은 계속 사용한다.
7. 성공 시 **PAYMENT_FINANCE_AUTO=true**로 바꾸고 Pages 재배포. 이후 갱신은 환경변수 쓰기·재배포 없이 DO 내부에서 처리된다. 상태/읽기 probe, 비Owner 차단, 원장 비교, 기존 LIVE/review runtime 확인. 실제 결제·환불 실행 없음.
8. 신규 Worker/DO/binding/Secrets/Pages 두 단계 전환에 대한 **Owner 승인 필요**. Supabase SQL/DB 권한 변경은 필요하지 않다.

## 원복·수동 복구

- 유효한 기존 Secret이 남아 있으면 PAYMENT_FINANCE_AUTO=false + Pages 배포로 기존 경로 복원. 또는 전환 직전 Pages 배포 복귀. 신규 Worker/DO는 자격 증명과 진단 이력을 보존하고, 필요 시 cron만 제거한다. 기존 주문·원장 DELETE/UPDATE 금지.
- 기존 Secret이 만료됐다면 flag만 끄면 복구되지 않는다. 보관한 기존 서명키와 같은 비시간 claims로7일 토큰 발급 → JWKS·서명·Finance 없는 주문 get/PT404 확인 → PAYMENT_FINANCE_TOKEN **한 항목만** Secret 교체 → Pages 배포 → Owner 읽기 확인. 마스킹된 설정 전체를 PATCH하지 않는다.
- 자동화 승인·설치가 늦어지면 **11/24 18:03:34 KST 전에 수동 갱신 우선**. 기존 Owner 지시가 이 fallback 갱신을 승인한다. 현재11/17에는 아직 여유가 있어 추가교체하지 않았다.
- 암호화키를 임의 교체하면 저장된 토큰을 읽지 못한다. 이전 키를 복원하거나 승인된 재초기화 계획으로 후보를 다시 검증한다. 키 분실을 해결하려고 권한/서명 검증 우회 금지.
- SIGNER_INVALID: 기존 key와 JWKS/kid/프로젝트 확인. PROBE_401/PGRST303: JWT 시각/검증 신뢰 확인. PROBE_403: 기존 role/ACL 확인(권한 확대 금지). BROKER_UNAVAILABLE: service binding/Worker/DO/Secrets 확인. 네트워크 오류: backoff/기존유효토큰 확인. 오류 본문/키를 복사하지 않는다.

## 근거 및 후속

- [Supabase Signing Keys](https://supabase.com/docs/guides/auth/signing-keys), [Cloudflare Durable Objects alarms](https://developers.cloudflare.com/durable-objects/api/alarms/). Supabase11/17 changelog 확인; 이번 작업과 관련된 라이브러리 업그레이드는 하지 않았다.
- 다음 만료일은 기존 수동 토큰11/24이며 자동화는 아직 운영 중이 아니다. 전환 후에는 각 토큰7일/잔여20% 갱신 정책을 적용한다.
- 배포 승인 이후 실제 주기 갱신·다중 인스턴스·cold start·fallback 관측 영수증을 이 문서에 추가하기 전까지 전체 DONE으로 보고하지 않는다.

## 최종 준비 보고

| 항목 | 상태·결과 |
|---|---|
| 1 기존 인증 | DONE — ES256/7일/essay_finance, 기존sub/iss/aud 확인 |
| 2 선정 방식 | DONE — private Worker + singleton DO, 기존 계약 유지 |
| 3 구현 | DONE — 발급/20%갱신/검증/교체/fallback/backoff/경고 |
| 4 저장 | DONE(코드) — Worker Secrets + AES-GCM 암호화DO, 서버전용 |
| 5 Finance API | DONE — old/candidate PT404·익명401·동일claims |
| 6 실패 복구 | DONE(합성) — 유효토큰 보존·재시도·실패폐쇄·수동원복 |
| 7 동시 안전성 | DONE(합성40요청·재시작), CF 다중리전 NOT TESTED |
| 8 권한 보존 | DONE — role/ACL/DB함수/직접테이블권한 불변 |
| 9 운영 적용 | PARTIAL — 미적용, Owner 승인 대기 |
| 10 LIVE 영향 | DONE — 기존배포/설정 유지, 실제 결제·환불0 |
| 11 테스트 | 전체2161 PASS/5 SKIP 후 최종관련202 PASS, TS/ESLint/Next/Pages/Worker dry-run PASS |
| 12 자동갱신 실제운영 | NOT TESTED — 설치·shadow·알람검증·true 전환 필요 |
| 13 남은 위험 | signer침해 영향·CF 의존·외부 push/독립heartbeat 없음·기존11/24만료 |
| 14 WEB Git HEAD | `923f87a495e39577bdf4f82f7cd0209b39f9d2fc` Commit·Push 완료 |
| 15 Wiki | 이 문서 및 WEB `wiki/finance-auth-operations-20261117.md` |
| 16 승인 | 위 운영변경1–8: 새 Worker/DO/Secrets/private binding/shadow→true. DB SQL 없음 |

실패한 빌드는 기존 Cloudflare OAuth 세션 만료의 읽기 설정 조회 오류였으며 정상 세션 갱신 후 최종 Next build PASS. 운영자 OAuth는 개발 실행에만 사용했고 자동 갱신 시스템에 저장하지 않았다. 인증 메타데이터를 포함한 동작만 기록하며 Secret 원문은 노출하지 않았다.
