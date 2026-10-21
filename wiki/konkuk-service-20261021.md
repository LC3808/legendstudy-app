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

