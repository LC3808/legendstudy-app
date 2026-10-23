# 논술 운영 JWT 30일 복구 후보와 자동 갱신 검토

2026-10-23 Owner 요청. **검토·로컬 절차 준비**, Production 변경/실제 발급/자동화 설치 없음.
[현재 Secret 복구](essay-p0-direct-execution-20261023.md#current-project-secret-diagnosis--2026-10-23-2111-kst)와 장기 운영 설계를 분리한다.

## 현재 확인된 계약과 만료

최근24시간 Supabase 성공 HTTP200 로그의 비밀 없는 role/issuer/alg/iat/exp만 조회했다.
원문 JWT/서명키/서명 prefix는 조회·출력하지 않았다. 아래는 **정상 요청에 사용된 토큰**이며
빈 값인 Pages 프로젝트 Secret이나 Owner가 보관한 임의 토큰의 인증 결과가 아니다.

|역할 / Secret|alg|iss|aud 발급 계약|발급 KST|만료 KST|기존 TTL|
|---|---|---|---|---|---|---|
|essay_worker / ESSAY_REGISTRY_WORKER_JWT|HS256|생략|생략|2026-10-14 14:05:09|2027-10-14 14:05:09|365일|
|math_evaluation_worker / MATH_EVALUATION_WORKER_JWT|HS256|supabase|생략|2026-10-23 00:30:23|2026-10-30 00:30:23|7일|
|math_extraction_worker / MATH_EXTRACTION_WORKER_JWT|HS256|supabase|생략|2026-10-23 00:30:23|2026-10-30 00:30:23|7일|

Audience는 로그에 없다는 이유로 판단하지 않고 기존 발급 도구/Oct09 성공 계약의 claim 목록을
따른다. Owner 토큰 원문은 받지 않았다. 보관한 eyJ 토큰이 사용자/anon/service_role일 가능성은
역할을 확인하기 전 배제할 수 없으며 이를 Worker Secret으로 등록하면 안 된다.

## 30일 허용 여부

WEB registryWorkerCredential, Math currentRole, Essay OperatingTransport는 올바른 역할과
exp가 현재+60초 이후인지 확인한다. iat→exp 간격의7일 상한은 없다. Production read-only
함수 메타검사에서도 math_evaluation/math_extraction/essay_registered_questions에
exp/iat 또는7일/30일 TTL 상수 검사가 발견되지 않았다. 이는 검사한 함수 범위의 증거다.

**결론: 30일은 확인한 코드 계약에 호환되는 복구 후보. 실제30일 토큰의 운영 acceptance는
아직 미검증.** Supabase의 서명·권한 검증은 생략할 수 없다. 기존 도구에 명시적
`--ttl-days 30` 후보 옵션을 추가했고 비시간 claims 유지, exp만30일 변경하는 합성검사 포함
5검사PASS. 실제 키 사용/발급0. 암묵적 기본값은 하위호환을 위해 유지하므로 복구 명령은
반드시30일을 명시한다. 기존 정상 Essay Worker의365일 토큰은 이번에 교체하지 않는다.

30일은7일보다 유출 토큰 사용 가능 기간이 길지만365일보다 짧다. 현재 dedicated RPC 권한을
유지하고 원문 노출을 방지한다. Legacy HS256 공유키 유출은 역할 하나를 넘는 위험이므로
서명키를 학생 WEB·평가Worker·로그에 넣지 않는다. 1년 신규정책은 승인하지 않으며 별도
위험/폐기/운영 자동화 검토 없이 기본화하지 않는다. 기존 키 회전 없이 새 토큰을 발급하면
이전 토큰은 자체 만료까지 유효하다는 점도 복구 계획에 포함한다.

## 이번 복구: Owner 직접 수행

1. 보유한 것이 기존 Legacy JWT Secret인지 확인. **eyJ JWT ≠ 서명키**다.
   이전에 서명키도 보유한다고 했지만 최신 메시지는 토큰 보유만 명시하므로 실제 보유를
   단정하지 않는다. 토큰만으로30일로 연장하거나 새 서명을 만들 수 없다.
2. 서명키가 없다면 Supabase stlhijzpjfgwwdgunlsd의 기존 Legacy JWT Secret을 Owner가 확인.
   새 키 생성/Rotate/Revoke 금지. 채팅 전달/파일 저장 없이 로컬 도구 숨김 입력에만 사용.
3. [명령3개](../tool/cloudflare_essay/OWNER_JWT_RECOVERY.md)를 하나씩 실행. 자체 인증 PASS 후
   클립보드를 Pages의 해당 Production Secret에 등록, 즉시 클립보드 비우기.
4. Essay Service Token은 Owner 보유 원문 그대로 Pages에 복원; 정상 Worker값 불변.
   Math Provider API key는 별도 기존값이 필요하며 JWT로 대체 불가.
5. 새 배포를 누르지 말고 등록 완료 알림. agent가 배포 없는 Production 빌드 진단으로
   현재 설정의 Registry/Math RPC·Provider 인증을 재검증. Service Token은 길이 확인만으로
   PASS 처리하지 않고 실제 보호된 runtime 경로의 인증 확인 필요.
6. 정상 WEB a8796fb4 보존을 기준으로 검증된 변경만 배포·확인 후 서울여 실제 평가와
   전체512 연결 재개. 현재 복구 미완료를 자동 갱신 설계 완료로 대체하지 않는다.

## 장기 운영: 제안 설계, 아직 미구현

- 30일 JWT, 하루1회 확인; `exp-now <= 7일`이면 재발급 시작(발급 후23일 시점).
  실행중복 잠금과 배포별 성공 receipt로 같은 갱신을 반복하지 않는다. UTC 기준 계산,
  Owner 보고는KST, 서버 시계 오차 여유 유지. 현재7일 토큰은 이미 이 갱신 구간에 들어간다.
- 현재 Owner 수동등록 원칙이므로 우선 **자동 만료감시 + Owner 갱신**만 가능한 단계다.
  무인 발급/Secret 쓰기/배포는 별도 Owner 승인과 실행 주체를 정해야 한다. 이번에 스케줄,
  알림 전송, 자동 Secret 업데이트를 설치하지 않는다.
- 자동화 승인 시 보호된 실행환경에서 기존 서명키를 Secret manager/보호 CI secret으로
  접근; 기존 키를 새로 생성하지 않는다. 런타임 평가Worker에 서명권한을 넣지 않는다.
  발급 역할은 정확히3종/TTL30일로 고정하고 허용 대상 URL도 고정한다. 다만 같은 HS256
  키를 가진 실행환경이 암호학적으로 다른 역할 발급도 할 수 있으므로 격리·코드검토·최소
  인원 접근이 필수다. 일반 PR 빌드에서 서명키를 읽지 못하도록 한다.
- Cloudflare API 자격증명은 필요한 계정/Pages·Worker 설정 작업만 허용하는 범위로 별도
  승인한다. 브라우저 로그인 토큰/OAuth 캐시를 무인운영 자격증명으로 사용하지 않는다.
- 발급 → 새 토큰 자체/교차역할 읽기검사 → 현재 활성 토큰의 만료 여유 확인 → 변경할
  Secret 이름만 PATCH → 현재 프로젝트 진단 → 후보 배포/실제 인증 → 성공 receipt 순서.
  GET의 마스킹된 Secret을 다시 PATCH하는 일괄 설정 복사는 금지한다.
- Essay Registry는 Pages와 Essay Worker 두 소비자를 추적한다. 같은 서명키의 신구 토큰
  동시 유효 구간에 순차 전환하며 한 쪽만 성공한 상태를 완료로 집계하지 않는다.
  Service Token과 Provider key는 JWT 갱신 대상이 아니므로 변경하지 않는다.
- 교체 전 마지막 정상 토큰을 승인된 보안 저장소에 보존해야 설정 롤백이 가능하다.
  Cloudflare에서 원문을 역으로 읽는 복구에 의존하지 않는다. 새 토큰 실패 시 현재 정상
  배포 유지; 이미 후보로 전환됐다면 이전 정상 배포로 복귀하고 설정도 필요한 항목만 복원.
- 정상 갱신은 새exp·역할·HTTP·배포ID·검증시각만 기록. 알림은 첫 실패 즉시, 미해결 시
  D-3/D-1/6시간 임계값에 Owner 채널로 단계별 재알림. 이메일/메신저 수신처는 Owner가
  지정해야 하며 현재 전송 없음. Secret·JWT·학생 답안은 알림에 넣지 않는다.
- 갱신 프로세스 자체 실패를 탐지할 독립 heartbeat 감시를 둔다. 성공 receipt가 없거나
  일일검사가 누락되면 알림. 단순히 갱신 작업의 내부 로그만 감시하지 않는다.
- 7일 여유·신구 중첩·사전검증·롤백으로 중단 위험을 낮출 수 있으나 **완전 무중단 보장은
  불가능**하다. 만료까지 복구 실패 시 만료토큰 수용/인증 우회 금지. 기존 History 조회와
  답안 보존은 가능한 경로에서 유지하고 새 유료 제출은 예약 전 차단한다. 진행중 작업은
  기존 idempotency/recovery 계약으로 처리하며 임의 재제출/중복차감/과거결과 UPDATE 금지.

## 근거

- 로컬 issue_worker_jwt.py 및 기존 Math Oct09 발급 계약, Oct23 갱신 receipt.
- 실제 성공 요청 로그의 역할/issuer/algorithm/만료 메타데이터(토큰 원문 없음).
- [Supabase JWT 구조](https://supabase.com/docs/guides/auth/jwts): 토큰은 서명된 데이터이며 서명키와 다르다.
- [Supabase Signing Keys](https://supabase.com/docs/guides/auth/signing-keys): Legacy shared secret의 영향 범위.

Production DB·Credit·History 변경0, 키 생성/회전0, 실제JWT발급0, Secret변경0, WEB배포0.

## Owner registration recheck

2026-10-23 21:41 KST. Owner approved30day recovery and reported JWT3 + existing
Service Token registered; Provider key unchanged. Build-only Production diagnostic
`7c06ee59-ca09-470d-95b9-85b2924b568e` independently confirms:

|Secret|Result|HTTP|
|---|---|---|
|ESSAY_REGISTRY_WORKER_JWT|AUTH_ACCEPTED|200|
|MATH_EVALUATION_WORKER_JWT|AUTH_ACCEPTED; null-input validation reached|400 / 22023|
|MATH_EXTRACTION_WORKER_JWT|AUTH_ACCEPTED; null-input validation reached|400 / 22023|
|ESSAY_WORKER_SERVICE_TOKEN|Nonempty; actual service-binding authentication pending|not called|
|MATH_PROVIDER_API_KEY|EMPTY_VALUE in current project build environment|not called|

The existing canonical WEB `a8796fb4-cf86-4572-8822-6deb5702cac7` was preserved
before/after. Only build_command was temporarily changed and restored to `pnpm build`;
no env_vars PATCH, no secret write, no Worker change. Diagnostic always exits73,
so its build failure is intentional and no serving deployment was promoted.
Three probe tests PASS. No Provider generation or DB/Credit/History writes.
JWT role/TTL metadata and cross-role denial were not independently measured in this
build probe; do not present this as full E2E or Service Token PASS.
Current project Provider key empty does not invalidate the healthy serving deployment's
separate binding. Preserve that deployment; do not rotate/delete its key. Restoring a
usable next-deployment Provider binding and checking service authentication remain
required before promotion and SWU ordinary-account E2E.
[Sanitized receipt](../tool/cloudflare_essay/secret-auth-recheck-result-20261023.json).
