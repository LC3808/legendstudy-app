# PHASE 3 — 기존 첨삭 연결 / 2026-10-22

## 범위와 상태

Owner iPhone12ProMax 최신시험/PDF 확인 후 PHASE3 로컬 연결 승인. 기존157시험512문항, 승인485문항153PDF/성균관27권리HOLD 보존. WEB 운영1638d9c 및 iPhone검증1.0.0(2026102201) known-good는 별도 배포/실기기 교체 없이 유지한다. 경희·동국 자료보강 후속HOLD, Claude담당IAP/결제 불변.

## 재사용과 로컬 최소 수정

- 한양대 실제Production 텍스트 평가/재첨삭/History/Credit1·0은 기존 성공 기록 유지. 숙명 이미지 실험 및 건국25회(인문15/수리10)는 그 범위만 재사용.
- Native 등록 검수문항 중 승인PDF가 있는 문항은 기존 작성UI·기기초안 저장 진입을 허용. 계정쓰기와 평가버튼은 HOLD. 미승인PDF/후순위16대학 진입 제한 유지. 360px/200% 포함Widget검증. 기존계정 답안을 변경하지 않음.
- 기존 MathWorkspacePage leaf 고정 구현 유지. LAB 최신PDF/UI브랜치에 과거 서비스브랜치의 동일 leaf고정, CALCULATION→COMPUTATION 물리매핑, 개념/계산오류 분류 및 Provider75초 수정 재사용. 71702 snapshot 제출변경은 가져오지 않음.
- WEB 제출 후 기존 owner History 조회를 사용하며 최대100초 자동 확인. 동일평가 재제출 없음. Native도100초 기준 뒤 수동상태조회/History 유지. Math extract/evaluate 클라이언트100초로 기존75초 Provider보다 먼저 끊기지 않게 맞춤. 새로운 Worker/서버/평가테이블 없음.
- 인문v6 기본값 보존. 실패 사실교정·분량불확실성 안내 v7는 격리 opt-in 후보. 실제 Provider가 재작성에서 criterion UUID를 잘못 복사함: 기존 검증기 CRITERION으로 차단. 요청 schema의 기준/근거 ID를 정확한 입력enum으로 제한하는 로컬수정. 결과UUID를 임의교체하지 않음.

## 평가자료 전수 대조

157시험512문항 읽기전용 audit.430문항에 기존2772페이지연결이 있으나 현행 private review의 VERIFIED 실행패키지·runtime policy는0.82문항은 현행 검수 페이지연결 없음. public evidence/criteria0은 원본·공식자료 부재의 증거가 아님. 건국 인문private cache/Math DRAFT14행은 예외 자산으로 보존. 모든512 운영 실행은HOLD; 자료조회/PDF실패 판정 아님.

비공개 근거: `~/development/legendstudy-materials/essay-validation-2026-10/phase3-20261022/`의 `readiness-summary.md`, `evaluation-holds.json`, 대학별`*-evaluation-holds.md` 및3auditJSON. 각문항 기존exam/question ID,연결수,원인,수정방향,Owner게이트 기록. Git에원본/답안/키 업로드하지 않음.

## 실제 Provider — 승인 범위

Owner 추가6회/$5 승인.3실패사례만 기존gpt-5.6-sol/OpenAIResponses/공식입력 재사용. 첫5회: 미흡·논점이탈 평가+독립검수PASS, 재작성기준ID오기로차단. 사용량보수비용$0.455232,실청구미검증.Owner 총7회/$5 변경승인 후 수정사례 평가+독립검수 PASS(8항목). 총7회 사용량 보수비용 $0.6167, 실청구미검증. 기존25회 포함 누적32회/보수비용 $3.2377406. 추가호출 종료. 운영DB/실Credit/공개변경0. 이전25회는청구미확정2건 포함 보수추산$2.6210406로별도보존.

## 검증 및 한계

Flutter 관련58tests/analyze PASS. Python기존Worker/공식입력/기준ID계약35tests PASS. WEB 인문제출/History/Math고정/ordered-upload 관련23tests 및 Math물리/ProviderMock/공식입력22tests PASS(중복테스트 포함, 단순합산하지않음). 실Provider 호출과Mock검증 구분. Android debug/iOS Simulator 빌드 PASS; 새코드의 iPhone실기기E2E 미확인. WEB Typecheck/Lint/Build/Boundary/GitHubReady 확인. 최종체크결과는 후속절에 기록.

## 남은 실행 게이트

1. 기존 검수페이지/공식자료를 기존 reviewed-package 계약으로 연결·검수.82문항은 연결보완 우선. 가천약술형/단답형은기존엔진적합성 별도확인.
2. 기존 한양대와같은 문항한정 package/policy binding 및 Math DRAFT 실행허용 준비. 데이터/정책변경 정확한범위와복구안 별도Owner승인. 신규Migration 필요하다고단정하지않음.
3. 실제 손글씨/6장판독, 신규문항 온라인상태저장/재첨삭/WEBAPP교차History/운영Credit 미검증. 격리성공을운영E2EPASS로대체하지않음.
4. WEB배포/Store업로드/일반AI활성화 별도승인. Provider범위확대도별도승인. 실서비스가능문항은 이번11개대학0(현재일반사용자HOLD 기준).

## 최종 확인

WEB Typecheck/Lint/Build PASS. Flutter analyze·Android debug APK·iOS Simulator 정상앱 빌드 PASS. 로그인 유지 iOS Simulator에서 실제71701 건국 인문2번→기존Native 작성화면 진입 PASS; 제출/계정답안쓰기 없음. 테스트 후 일반 검증앱을 삭제 없이 복원. 새 코드 iPhone실기기/운영History E2E는 미검증.

추가 두 호출 원장: `approved-repair-call-ledger.json`; 원래5회 원장보존. 재작성 응답의 정확한 기준ID·기존 상호성 문제 resolved·공식 분량 확인유보 안내 확인, 독립검수8항목PASS. 세 합성사례의 격리 품질검증만PASS이며11개대학 서비스PASS아님.

## Owner P0 후속 — 실제 연결 후보

격리품질재실행0. 읽기전용운영확인: 한양대revision17/정책존재, 건국인문revision1/패키지·정책없음. Worker staging은76시험정적Registry에건국신규시험누락; v3prompt만복사해현재v6 import실패가능. 기존stage자산복사와trusted Registry옵션, 서버snapshot+배포exact allowlist에의한기존prompt선택을최소수정. 기존한양대v3/기본v6보존, 후보v7별도승인필요. 모델·정책불일치차단.21개오프라인계약검증PASS, 새Provider0.

건국대표공식cache를기존material runtime9연결/5기준으로투영PASS; 운영생성digest/권리/시험내다른문항검수보존은미완료. 상세비공개 `phase3-20261022/operating-connection-plan.md`와`operating-candidate-report.json`. Worker후보77시험은기존76시험보존. 아직운영쓰기·배포·Credit0. 실제운영E2E미완료. 새로운엔진/테이블/71702없음.

## 2026-10-22 운영 연결 승인 후 (진행 중)

Owner가 운영 연결·검증계정 Provider/Credit E2E를 승인하여 위의 “운영 변경 없음”은 이전 체크포인트가 됨. 일반 전체 공개는 유지 HOLD.

- 기존 runtime 함수 3개에 검수 revision으로 고정한 건국 인문2번만 연결. 기존 exam/question·다른 문항·18개 검수 매핑 보존. revision2에 9개 공식자료/5기준 연결. ACL·RLS 유지. 한양대 기존 정책 보존.71702 없음.
- 기존 Worker prompt 포함/Registry77시험/정책별 정확한 prompt binding 반영. 일반 공개 대신 기존 테스트 계정·시험·요청키 scope만 Pages에 허용. Native도 서버가 승인한 question ID로만 제출 허용.
- WEB d0107bc 배포: 서버 승인 문항 제출, 실패 확정 요청의 명시적 재준비. 실패한 이력은 지우지 않으며 처리 중인 요청은 재제출하지 않음.
- 첫 운영 배포에서 공개 빌드 환경변수 누락을 발견해 기존1638d9c로 즉시 복구. 보존한 Production public 환경으로 재빌드·재배포하여 로그인 복구. 비밀값/Binding 변경 없음.
- 운영 WEB 첫 평가: 독립검수에 내부1~5 충족도 척도 설명이 없어 uncertain 차단. 설명만 전달하도록 보완, 검수 guard 유지. 두 번째 평가: 공식801~1,000자 조건이 length_requirement에 전달되지 않아 피드백 누락으로 차단. 검증된 question evidence의 명시적 범위만 전달하며 산정방식·감점 추정 금지. 29개 관련 계약테스트 PASS.
- 실패2건 모두 reserve1/release1, balance_delta0 확인. 새로운 수정 후 WEB 제출 진행 중. APP은 로그인 세션·입력 보존, WEB 실패 History 교차조회만 확인. APP Provider 제출·무료재첨삭·Math 운영E2E는 아직 미검증.
- 비공개 백업/SQL/호출사용량/실패근거: 기존 phase3-20261022 로컬 폴더. 롤백은 scope 비활성→기존 함수/Worker/WEB 복구; 생성 이력·학생 데이터 삭제 없음.

## 2026-10-23 운영 E2E 체크포인트 — 인문 교차조회 PASS, 전체 PARTIAL

Owner 통합 실행 승인에 따라 실제 테스트 계정으로 수행했다. 과거 격리 품질 성공을 반복하지 않고 기존 Essay Worker·Registry·검수 패키지·Credit·History를 재사용했다.

- 건국대 2026 수시 인문 2번: iOS Simulator Native 앱 최초 제출 → 실제 Provider 평가 → 결과 저장 PASS. 최초 run `8673c80d-902c-46d4-9697-08e4c7702c29`.
- 같은 결과를 Production WEB History에서 조회하고, WEB에서 재작성·무료 재첨삭 → 결과 저장 PASS. rewrite `d1f6dcba-c6f7-45f6-ba1d-8ec13c45963a`. APP History를 다시 열어 같은 재첨삭 결과와 비교를 실제 렌더했다. 독립검수 8항목 PASS.
- Ledger 확인: 최초 balance_delta -1 / reserved_delta 0, 재첨삭 0 / 0. 앞선 실패 3건은 각각 reserve1/release1로 순차감0. 결제 테스트·상품 변경 없음.
- 이번 운영 Provider 10호출(평가5/독립검수5). 사용량 기반 보수 추산 USD0.972644, 캐시 할인 미반영·실청구 미확인. 이전 격리7회/USD0.6167와 별도 기록. 성공 사례를 다시 호출하지 않는다.
- 실패 원인: 내부 1~5 척도 설명 누락, 공식 분량의 런타임 전달 누락을 최소 수정. 세 번째 실패는 독립검수 통과 후 최종 계약 차단으로 당시 정확한 원인 미기록; 원인을 확정하지 않는다. 이후 명시적 local issue 목록과 안전한 symbolic failure code 기록을 보강했다. 다음 최초/재첨삭은 실제 성공했다.
- WEB 재작성 화면이 정적 Registry에 없는 시험을 거부하던 문제를 수정했다. 기존71701을 먼저 조회하고 정확한 exam/question ID를 확인하며, legacy 조회는 fallback이다. 관련2 tests·Typecheck·Lint·Build·Boundary PASS. LAB `26f0c2a29b4eeef23a0d522c6488276da4076842` 배포, APP/Worker `d675a84511b5a43bac6a7d0d721dc4b570a6ce32`. Worker version `c180f7e1-8620-4ef0-ab17-4e8545fe2f3e`.
- 첫 WEB 배포의 공개 빌드 환경 누락은 즉시 기존1638d9c로 복구한 후 기존 환경으로 재빌드하여 해결했다. 이후 로그인·실제 재첨삭으로 복구 확인. 비밀값은 기록하지 않는다.

### Math 운영 준비와 남은 인증 확인

기존 건국 자연1번 Math14행 중 set/problem/profile/canonical solution 4행만 DRAFT→ACTIVE로 변경했다. 상태·수정시각 외 원본 JSON 동등성4/4 PASS, ID·공식내용 보존. 기존 evaluation_admission 함수에 **기존 테스트 계정·정확한 leaf·자기 attempt·2026-10-24 00:00 KST 이전** 조건의 예외만 적용했다. 전역 evaluations_enabled=false 및 함수ACL postgres-only를 재확인했다. 기존 다른 문항은 계속 차단한다. 별도 테이블/71702 적용 없음.

Math Pages Provider/runtime flags는 여전히 false다. 마지막 확인 Worker JWT 만료는10월16일이며 현재 secret은 마스킹되어 갱신 여부를 확인하지 못했다. 기존 안전한 발급/갱신 경로 확인 중이며, 키 회전·service_role 대체·권한 우회 없음. Math 실제 Provider/Credit 실행은 아직0. 기존 SQL 백업·원복은 비공개 `phase3-20261022/math-operating-backup.private.json`, `math-operating-rollback.sql`. 복구는 gate 원복으로 차단하며 기존 학생답안/결과를 삭제하지 않는다.

### 판정과 범위

건국 인문1문항의 테스트 계정 WEB↔iOS Simulator 평가·재첨삭·History PASS. Android/iPhone의 이번 실제 첨삭은 미검증. 나머지11개 대학 문항을 서비스PASS로 확대하지 않는다. 일반 공개0/HOLD, 건국대 외10개 대학 E2E 검증문항0. Math 및 손글씨·6장 판독은 PARTIAL/미실행. 자료157시험512문항 및 기존PDF는 보존했다. 기존 readiness 표의 페이지 연결 수는 운영 가능 문항 수가 아니다.

증거: 비공개 `phase3-20261022/operating-provider-usage-current.json`, 로컬 `/private/tmp/legendstudy-app-evaluation-success.png`, `/private/tmp/legendstudy-app-cross-rewrite-success.png`. 원문·답안·키는 Git에 포함하지 않는다. 경희·동국 보강HOLD, IAP는Claude담당 유지.

운영 배포 목록 재확인: Production `917b22de-95ad-48b8-8995-acbd2af31c91`, source `26f0c2a`. Wrangler 기존 OAuth refresh 후 읽기 성공(직접 API의 일시적401은 토큰 갱신으로 해소). 추가 Native 화면 확인 시 Mac 잠금으로 중단했으며, 앞서 저장한 실제 성공 증거는 유지한다. Math 인증 경로와 기기 잠금 해제 후 잔여 검증 필요.

## 2026-10-23 Math 인증 경로 재확인 (읽기 전용)

기존 경로 FOUND. Unified Wiki commit `67bf37d230a09a624aa39c0c521d658c17f17398`의 Oct09 Daily와 `90_HISTORY/EVIDENCE/2026-10-09-math-final-unblock.json`을 대조했다. 당시 기존 Management `GET /v1/projects/{ref}/postgrest` 경로에서 기존 서명 재료를 메모리로만 사용하고 기존 서명을 확인한 뒤, 정확히 math_extraction_worker/math_evaluation_worker 역할의 HS256 JWT(iss=supabase,iat,7일exp)를 발급했다. 새 서명키·회전·폐기 없이 기존 Pages의 두 encrypted binding만 갱신했다. 자체 null-DTO400/22023·교차역할403/42501, 실제 Math 최초1Credit/재첨삭0Credit 성공 증거가 있다. 발급 스크립트 자체는 해당 Git commit에 포함되지 않았으며 절차와 비밀을 제거한 실행 증거가 남아 있다.

현재 Production `917b22de-95ad-48b8-8995-acbd2af31c91`/`26f0c2a`: 두 Worker JWT와 Provider API key binding 모두 secret_text로 존재한다. 따라서 Secret 등록 누락이 아니다. Math Enabled/Provider Calls 모두false. 익명 빈 요청 evaluate503/extract409는 현행 gate/입력 차단이며 JWT 만료의 증거가 아니다. 최근24시간 Supabase 로그 집계에서 JWT expired 및 두전용역할 문자열 발견0; 로그 부재는 인증성공 증거도 아니다.

마지막 확인 exp는2026-10-16 18:57:41KST. 현재 설치 Secret의 claims/서명과 역할RPC acceptance는 마스킹 때문에 아직 미확인. **갱신 방식 부재 → 현재 설치 credential 유효성 미확인**으로 BLOCKER를 정정한다. 갱신을 위해 새 인증키나 새 권한이 필요하다는 근거는 없다. 기존 키 노출 이력은 별도 미해결이며 노출 키를 대화에서 재사용하지 않는다.

이번 확인에서 서명 재료 조회/토큰 발급/Secret 교체/설정 변경/Provider/Credit 실행 없음. 다음은 기존 전용 역할 인증의 안전한 유효성 검증 및 필요 시 기존 절차의 제한적 credential 갱신이다. 키 생성·회전·service_role 대체·검증 우회는 하지 않는다. 기존 인문 실제 교차조회 성공을 반복하지 않는다.

비공개 메타데이터 근거: `phase3-20261022/math-auth-readonly-20261023.json`(키·JWT 원문 없음).
