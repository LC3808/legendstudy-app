# 건국대 대표 문항 서비스 연결 — 2026-10-21

## 판정

전체 서비스 PARTIAL. 자료21시험58문항 등록은 이전 검증 재사용. 이번 Production 조회에서 동일 건수와 자연시험 Math세트0 확인. Production 쓰기/Provider/Credit/배포/공개/스토어 변경0.

## 재사용 및 최소 변경

- 한양대 실제 Production 인문 제출/Worker/재첨삭/History 경로를 재사용한다. 숙명여대 비공개 이미지 품질 성공은 Production History 증거가 아니다.
- 인문 대표2026수시인문2번(60점), 기존 exam `1033e20b-9a20-5622-a67b-c288ace2734f`, question `1f980d57-683e-5d49-b2ed-4bbb554b967b`. 공식5개 기준과 문제/제시문/의도를 private cache로 구성. 원문·예시답안·평가자료는 Git에 없음. 교육적 품질 판정 아님.
- 수리 대표2026수시자연1번(17점), 기존 question `cea40cf3-dc05-507a-a6eb-fd5e1e1847bb`. 기존 Math8개 테이블14행 DRAFT 후보, leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3`. 등급별 점수를 임의 배분하지 않고 공식17점 기준표1개로 보존. 기존 논술 ID↔leaf 명세를 유지하며 신규 FK 설치로 보고하지 않는다.
- Native/WEB Math `?leaf=` 고정 선택. 승인 catalog에 없으면 다른 문항 기본선택 금지, 제출 차단. 일반 선택 화면에서 대표문항을 활성화한 것은 아니다.
- APP 기존 AnswerImagesInput 재사용, Math에서만 순서 변경 옵션. 최대6장/미리보기/삭제, 입력 freeze 후 동일attempt/position/artifact 유지, 성공한 업로드 건너뛰고 실패 부분 재시도. 판독·학생확정·평가·History는 기존 gateway 재사용.
- LAB physical adapter의 CALCULATION을 기존 SQL COMPUTATION으로 변환. 알려지지 않은 종류 fail closed. SQL/엔진 변경 없음.

## 검증 증거

|검증|결과|실제 범위|
|---|---|---|
|WEB Math/UI+worker/physical+ordered upload|14 tests PASS|합성 gateway/RPC, private 공식 Worker 입력은 별도 fixture|
|WEB 인문 제출→결과→무료재첨삭→History adapter|1 test PASS|기존 UI/History 변환, canonical IDs, 합성 HTTP/RPC와 평가 결과|
|인문 공식5기준 worker|PASS|실제 기존 Worker+Mock transport2회, 재작성/체크포인트 재실행; 운영 저장 아님|
|Math 공식 콘텐츠/DB|27 checks PASS|격리PG17 기존schema, 정확한DRAFT SQL2회/롤백/재등록, 권한, ID, 최초1/재첨삭0 로컬 Credit, lineage/result; 실제Storage 아님|
|Flutter Widget/Gateway|8 tests PASS|잘못된leaf 차단, HOLD, 사진6장/순서/부분실패재시도, 인증gateway|
|Flutter analyze|PASS|이번 변경 파일 포함|
|WEB Typecheck/Lint/Build/Boundary/Ready audit|PASS|Node22/pnpm11, 배포 없음|
|Android/iOS 빌드|PASS|debug APK 및 simulator Runner.app, build number2026102101; Store/TestFlight/실기기 아님|
|실제 Provider·WEB/APP 교차E2E|NOT_ASSESSABLE|미실행; HOLD 유지|

개별 UI/Worker/격리DB 검증을 단일 실제 브라우저→DB→Provider 통합 E2E PASS로 합치지 않는다. Mock 결과는 학습 품질 증거가 아니다.

## 비공개 산출물

`~/development/legendstudy-materials/essay-validation-2026-10/건국대/service-20261021/`: humanities-private.json, math-private.json, 두 Mock/DB 보고서, math-draft-registration.sql, math-draft-rollback.sql, production-preparation.md. 원본 PDF 및 공식 평가 본문 Git 업로드 금지. 임시 실행 경로는 /private/tmp/konkuk-service-inputs/.

## 운영 게이트 및 다음 단계

1. Math14행 DRAFT 콘텐츠 등록 별도 승인 요청. 새 Migration/시험/문항/Storage 생성 없음, 신규 후보ID 모두 운영에 없음. 평가활성화와 별개.
2. 인문 reviewed cache/criterion·evidence binding 및 권리·검수·Provider regime를 운영 승인 단위로 확정. 현재 approved_processing/Provider/publication false.
3. 일반 사용자 메타데이터와 기존 UI 선택→승인된 Math leaf 연결은 미완료. 기존71701/02를 무조건 적용하지 않으며 현재 미적용 유지.
4. 실제 계정/allowlist/모델·토큰·비용상한/Credit·History 영향 확정 후 별도 Provider 승인 요청. 이번에 가격이나 호출 준비 PASS를 추정하지 않음.
5. 운영WEB 배포/APP업로드는 별도 승인, 실제기기와 WEB/APP 교차History 추후 검증.

기존 Vault 복구 PARTIAL 기록 보존. 완료된 백업·DB/Storage등록 재실행 없음.

## 2026-10-21 — 건국대 Math DRAFT 등록 승인 적용 PASS

Owner 별도 승인 범위14행만 Production 적용: 세트1·문제1·소문항1·출처4·profile1·criterion1·solution1·step4. 기존 자연2026시험/문항 ID 보존. 상태열4개 DRAFT, 시험inactive·문항unpublished 유지. 동일내용 검증 포함 단일 트랜잭션 성공. 신규ID 중복없음.

기존 Math/논술 시험·문항/답안·평가/시험History/Credit·결제/Storage/근거/runtime control 및 RLS·ACL 등31개 비교 항목 건수·전체행해시 전후 동일. 정책132개 유지. 대상8테이블 anon/authenticated 직접SELECT 차단. 합성subject catalog조회는 ACCOUNT_RESTRICTED; 실제회원 조회PASS는 아님.

DRAFT등록 PASS와 실제서비스 PARTIAL을 구분. Migration/Provider/실제Credit/WEB·APP배포/공개활성화 없음. 다음: 인문 운영입력 binding·검수/권리, 실제Provider 실행범위 준비. 비공개 근거 `essay-validation-2026-10/건국대/service-20261021/production-draft-postflight.json`.

## 2026-10-21 — 건국대 실제 Provider 품질 검증 PARTIAL

기존 OpenAI/Reviewed Worker/Math 경로로 실제25회(인문15·수리10) 실행. 완료23건 usage요율 추산$2.0007006, timeout2건 최대예약$0.62034 별도; 청구총액 미확인. 승인35회/$30 안에서 인문15회 세부한도 도달로 중단. 키체인키는 메모리만 사용, 원문/답안/키/응답은 Git미포함.

인문: 우수답안 타당성 인정, 보통답안 수정후 독립검수8항목PASS. 미흡/논점이탈에서 사건순서·기억상실 과장 발견, 재작성은 이력계약PASS이나 분량불확실성 안내 검수FAIL. 전체품질PASS 아님. 실제 발견한 level0→기존1~5계약 불일치 및 Provider 답안해시 오복사에 대해 transport schema 범위/ID고정. 기존v3 보존, 로컬후보v6/독립검수2에 인용정확성·사건순서·resolved이력 연결 명시. Production미적용.

수리: 정상·정답만·계산오류·부분풀이·개념오류·재작성 구분. 개념미분오류 CALCULATION 오분류는 최소prompt보완 후 CONCEPT_SELECTION 확인. 40초timeout2건은5분lease안75초로 로컬조정 후 영향사례만 성공. 합성인쇄이미지8영역 판독은 확인했지만 실제손글씨/6장실측PASS 아님. 반환된 실제수리최초/재첨삭 결과의 격리PG17 기존SQL 재생25체크PASS(저장·조회·lineage·테스트Credit1/0·중복방지·타인차단). 온라인연속E2E와 구분. 초기구버전SQL harness실패 후 기존runtime/learning SQL을 격리에 포함해 해결.

Python34/WEB50 관련테스트·Typecheck·변경Lint PASS. Production쓰기·배포·Credit0, DRAFT/공개HOLD 유지. 남은BLOCKER: 인문사실정확성/분량안내, 실제손글씨·이미지확정연속흐름, 인문SQL History/WEB·APP 운영E2E, 운영package/policy 및 DRAFT제약. 유료서비스 준비PARTIAL/HOLD.

비공개근거: `essay-validation-2026-10/건국대/service-20261021/quality-20261021/quality-report.md`, `call-ledger.json`, `math-actual-output-history.json`. Provider대시보드 청구액 검증 전 실제총비용확정 주장 금지.

## Owner 후순위 대학 CTA — 2026-10-22 실행 / 10-21 지시

16개 대학(연세·홍익·서울시립·성신여·을지·단국·삼육·덕성여·동덕여·서경·수원·신한·한국공학·한국기술교육·한신·강남)의 WEB/Native 첨삭 CTA를 회색 disabled `서비스 준비중`으로 변경. 대학명 자료 탐색·공식 링크·42 Catalog/순서/기존 자료·다른 대학 상태는 보존. 상세/재작성 진입 및 제출 consumer에도 UI 차단 적용. 서버 권한 변경 아님; 기존 AI HOLD 유지.

로컬 검증: WEB 관련35테스트/Typecheck/변경Lint, Flutter 관련8테스트(360px/200% 확대 포함). 초기 카드 overflow 수정 후 PASS. 실제 Production/실기기 배포검증은 미실행. DB·Provider·Credit·Production 배포·스토어 제출 없음. 배포는 별도 Owner 승인 필요.

### 다음 작업 계획 — 미실행
Owner가 2026-10-22 계획으로 지정한 작업은 이번 CTA 범위에서 실행하지 않음. 한양대→숙명여대→건국대 우선, 이후 경희·서강·성균관·고려·동국·숭실·항공·서울여대. 기존 한양 Production E2E, 숙명 이미지 검증, 건국 Provider25회 및 Math/Flutter 재사용. 응답 목표30–60초/최대대기100초; 확인된 서버 상태만 표시, 초과 시 기존 상태 조회, 중복 평가·차감 금지.

WEB/APP 공통 응원 문구 계획: “오늘도 수고했어요.”, “잠깐 어깨를 펴고 쉬어가세요.”, “물 한 모금 마시고 오셔도 좋아요.”, “열심히 생각한 만큼,\n잠깐 눈을 쉬게 해주세요.” 숙명2026모의 자연1 공식 우수 손글씨 답안의 수식·증감표·근호·분수·도형·소문항 판독/공식기준 검증 예정. 원문 변경·재배포 없음. 가입→제출→첨삭→재작성/재첨삭→History 양 플랫폼 실제E2E 목표; Mock와 구분하고 공개는 Owner 최종 승인. North Star의 학생 가치/재이용 철학 및 사업 목표는 그대로 유지하며 성과를 보장하지 않음.
