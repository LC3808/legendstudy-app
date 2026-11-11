# 건국대 자연·수리 운영 공개 · 2026-11-12

상태: 적용 준비. 실제 운영 반영 전이며 PUBLISHED가 아니다.

## Owner 결정과 범위

2026-11-12 Owner는 비공개 DRAFT 종료 방식을 중단하고 검증된 문항의 운영 연결·사용자 공개를 승인했다. 건국24문항·299행을 먼저 처리하고 기존 운영4문항을 보존한다. 이후 경희→성균관→서강→숭실→숙명→동국→광운→서울여 순서. 한국항공 기존DRAFT7도 공개 대상, HOLD5와 중앙 과학11은 유지한다. 새 RPC/Storage 정책 또는 기존 공개 기능에 영향을 주는 배포는 적용 전에 범위를 보고한다. 실제 AI 품질 검수는 전체 대학 이후 Owner가 수행하며 대학별 착수 조건이 아니다. Codex는 Provider 반복 호출 없이 기술 계약·권한·공개 상태를 검증한다. 로그인·품질 검수 참여를 작업 진행 조건으로 요청하지 않는다.

기존 [순차 기술 결과](essay-natural-tech-ready-20261112.md), [통합 검수 범위](essay-natural-integrated-review-20261112.md), [기존 TASK20 공개 연결](task20-priority-natural-connection-20261106.md)을 재사용한다. TECH READY와 PUBLISHED를 구분한다.

## 적용 전 확인

- 현재 운영 Pages `67873372-a54a-492c-87a6-f8171a93e681`, 소스 `3ca5ccb697732019bb56fa2eece49f99ad92767e`. 과거 논술 브랜치 전체를 배포하지 않고 현재 운영 소스에서 별도 WEB 브랜치를 생성했다.
- 건국24 DRAFT 사전 SQL116 PASS. 기존 함수 hash·RLS/ACL·Registry·충돌 검사 통과.
- 격리 PG17: 정확한299행 적재→96개 버전 상태 ACTIVE→기존2함수 허용목록 확장→72개 문항/프로필/Worker 검사→24문항 제출/결과/재첨삭→허용목록 원복 통과. 실제 Provider/운영 Credit 호출0.
- 기존 승인된 문제PDF6개가 실제 `essay-material-originals`에 존재. `review@legendstudy.com`의 authenticated 역할로 READ ONLY 검사: account_allowed=true, quality_operator=false,6개 조회. 정책 변경 없음. 실제 바이트 SHA/화면 표시 결과는 별도 확인.
- WEB 관련381 PASS/1 SKIP, TypeScript/Next production build/Functions compile PASS. 최초 실패는 미연결 첫 Registry를 전제한 테스트2개와 추가 수량 기대값으로, 독립 fixture 및 정확한 추가 수량으로 정정했다. 런타임 연결/권한 로직 변경 없음.

## 운영 변경 계획

299행 신규 추가 후 해당 package96행 ACTIVE 전환. `math_private.evaluation_admission()`·`math_private.release_catalog(uuid)`의 기존215 leaf를 보존하고24만 추가한다. 새 RPC/Storage 정책/Worker 엔진/결제 규칙 없음. Registry 원문과 ID, 기존 사용자 답안·평가·Credit 데이터는 수정하지 않는다.

WEB은 Source Registry6시험(기존 미연결1보완·신규5)와 expansion6시험만 연결한다. 기존 입력24/PDF24 메타데이터는 동일하다. 공개범위 public262→268, expansion92→98, Math215→239 예정. 기존 정적 자산과 관리자 등 다른 페이지를 보존하며 논술 페이지 산출물과 이를 사용하는 API 번들만 반영한다. 실제 배포 완료는 별도 영수증으로 기록한다.

## 비파괴 원복

동시 변경 검사를 통과한 경우에만 새 WEB scope6시험/24leaf를 제거하고 직전 배포를 복원한다. `rollback-admission.sql`은 적용 직후 함수 hash가 동일한 경우 기존2함수 정의로 되돌려 신규 평가 진입만 닫는다. package·Worker 근거·답안·진행 중 작업·결과·Credit 이력은 삭제하지 않는다. 이후 타 작업의 변경이 있으면 전체 정의를 덮어쓰지 않는다.

## 일곱 보존 검토

1. 공식 자료 버전과 공개 적용 시각을 기록하며 학생 학습 사실을 생성하거나 품질 점수로 대체하지 않는다.
2. 공식 PDF SHA·페이지·기존 Registry ID와 package SHA를 유지해 당시 근거를 재현한다.
3. 신규 버전 행만 추가하고 해당 상태만 전환한다. 기존 원문/개인 이력 UPDATE 없음. 원복은 진입 허용만 회수한다.
4. 기존 auth.users identity와 소유권을 그대로 사용한다. 신규 학생 식별자를 만들지 않는다.
5. 논술 답안/첨삭은 기존 Learning 이력이다. 지원·합격 Outcome과 혼동하지 않는다.
6. 기존 계정 서비스 허용·RLS·Storage·보존 정책을 유지한다. 공식 채점 근거는 Worker 전용이며 학생 PDF만 기존 승인 범위로 조회한다.
7. Mock 결과는 격리 DB에만 존재한다. 실제 AI 품질/정답 판정으로 보고하지 않으며 파생 평가의 기존 provenance/version 계약을 유지한다.

## 완료 증거

운영 적용·일반 사용자 접근·공개 수·배포 영수증·최종 Git은 검증 후 추가한다. Owner 실제 AI 품질 검수는 통합 단계에서 별도 수행한다.

재현: `python3 tool/prepare_konkuk_public_release.py PRIVATE_LIVE_FUNCTIONS_JSON`은 현재 SELECT로 확보한 함수 정의를 입력받아 후보만 생성한다. `python tool/test_konkuk_public_release.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`은 격리 DB만 사용한다. 공개/원복 SQL은 원문을 포함하므로 .local에 두고 추적본에는 SHA와 검증 SQL/원복 정의만 기록한다.
