# Owner 실행 — 기존 서명키로 Pages JWT 복구

대상: Cloudflare Pages `legendstudy-lab` → Settings → Production.
Supabase `stlhijzpjfgwwdgunlsd`. 준비만 완료; agent는 실제 토큰 발급·등록을 실행하지 않았다.
기존 `issue_worker_jwt.py`를 재사용하며 Math 역할 선택과 읽기 전용 검증만 추가했다.

|Production Secret|role|alg|iss|aud|유효기간|
|---|---|---|---|---|---|
|ESSAY_REGISTRY_WORKER_JWT|essay_worker|HS256|기존대로 생략|기존대로 생략|기존365일|
|MATH_EVALUATION_WORKER_JWT|math_evaluation_worker|HS256|supabase|기존대로 생략|기존7일|
|MATH_EXTRACTION_WORKER_JWT|math_extraction_worker|HS256|supabase|기존대로 생략|기존7일|

Essay 기존 로컬 발급 함수와 Math Oct09/Oct23 성공 발급 계약을 유지한다.
운영 성공 로그에서도 Essay issuer없음/HS256, Math iss=supabase/HS256 확인.
로그에서 audience 부재를 추측한 것이 아니라 기존 발급 계약의 claim 목록을 따른다.
새 서명키·키 회전·학생 토큰·service_role 토큰을 만들지 않는다. 기존 Worker 설정 불변.

## 30일 복구 — Owner 승인

아래 명령은 `--ttl-days 30`을 명시한다. 기존 계약표의365일/7일은 과거 발급 계약이며,
이번 복구는 exp만 발급시각+30일로 변경한다. 1년을 새 운영정책으로 승인한 것이 아니다.
**eyJ로 시작하는 토큰은 서명키가 아니다.** 기존 Legacy JWT Secret을 별도로 확보한 경우에만
재발급한다. 이미 발급된 JWT나 Service Token에서 서명키를 복원할 수 없다.
기존 토큰만 보유했다면 신규 발급 명령을 실행하지 말고, Supabase의 해당 프로젝트
JWT Keys → Legacy JWT Secret에서 기존값을 Owner가 확인한다. Rotate/Revoke/Create 금지.
이번 검토는 실제 발급·등록·배포를 수행하지 않았다.

## 실행 순서

Mac 터미널에서 아래 명령을 **하나씩** 실행한다. 서명키는 프로그램의 숨김 입력에만
붙여넣는다. 명령 인자·환경변수·파일·채팅에 넣지 않는다. 입력은 화면에 표시되지 않는다.
각 실행은 메모리에서 JWT를 발급하고 읽기 전용 인증 검사에 통과한 경우에만 클립보드에
복사한다. 실패하면 해당 토큰을 등록하지 말고 비밀값 없이 실패 여부/HTTP 상태만 알린다.
한 개 등록을 마친 후 클립보드를 비우고 다음 명령을 실행한다.

### 1. Essay Registry

```sh
python3 /Users/woojinchang/development/legendstudy-service-app-20261022/tool/cloudflare_essay/issue_worker_jwt.py --config /Users/woojinchang/development/legendstudy-service-app-20261022/tool/cloudflare_essay/owner-jwt-recovery-config.json --role essay_worker --ttl-days 30
```

### 2. Math Evaluation

```sh
python3 /Users/woojinchang/development/legendstudy-service-app-20261022/tool/cloudflare_essay/issue_worker_jwt.py --config /Users/woojinchang/development/legendstudy-service-app-20261022/tool/cloudflare_essay/owner-jwt-recovery-config.json --role math_evaluation_worker --ttl-days 30
```

### 3. Math Extraction

```sh
python3 /Users/woojinchang/development/legendstudy-service-app-20261022/tool/cloudflare_essay/issue_worker_jwt.py --config /Users/woojinchang/development/legendstudy-service-app-20261022/tool/cloudflare_essay/owner-jwt-recovery-config.json --role math_extraction_worker --ttl-days 30
```

### 4. 등록과 클립보드 정리

프로그램이 안내한 **Pages Production Secret 하나**의 Value에 클립보드를 붙여넣고 저장한다.
`pbpaste`로 출력하지 않는다. 등록 직후 다음을 실행한다.

```sh
pbcopy < /dev/null
```

기존 `ESSAY_WORKER_SERVICE_TOKEN`은 Owner 보관 원문을 Pages에 그대로 복원한다.
**`--service-token` 옵션은 실행하지 않는다**: 그 기존 옵션은 새 토큰을 생성하므로
이번 복구의 기존값 유지 조건과 다르다. 정상 Essay Worker의 Service Token은 변경하지 않는다.
`MATH_PROVIDER_API_KEY`는 JWT가 아니며 이 도구로 만들지 않는다. 별도의 기존 Provider
API key 복원이 필요하다. 보관값이 없다면 그 항목만 알려 준다. 임의 새 키 발급 없음.
카카오·토스·결제 설정은 변경하지 않는다. 새 WEB 배포 버튼도 누르지 않는다.

## 검사와 실제 보존 범위

- Essay: 기존 전용역할로 `essay_registered_questions` 읽기 HTTP200/배열 확인.
  과거234개 고정 검사는 현재 문항 증가와 무관한 인증 실패를 만들므로 배열 검사로 교체.
- Math: 자체 RPC에 `p_request:null` → HTTP400/22023(인증 후 입력검사 도달),
  교차 역할 RPC → HTTP403/42501. 둘 다 일치해야 클립보드 복사.
- 제출·claim·평가·Provider·SQL변경·Credit·History 쓰기를 호출하지 않는다.
- 원문 JWT/서명키는 stdout·오류·파일·Wiki에 기록하지 않는다. 클립보드는 Owner 등록용이다.
- 합성 키를 이용한 계약/서명/역할/실패경로 테스트4개 PASS. 실제 키/토큰 사용0.

Owner가 등록 완료를 알리면 agent가 현재 Production 설정을 다시 진단한다.
로컬 발급 성공만으로 Cloudflare 등록 성공이나 서비스 E2E 성공을 주장하지 않는다.
현재 정상 WEB a8796fb4는 복구 검증 전까지 유지한다.
