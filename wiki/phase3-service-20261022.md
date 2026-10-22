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
