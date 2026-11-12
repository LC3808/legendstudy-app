# 이화여대 원본 전수 조사·기존 package 연결 후보 · 2026-11-12

**조사·로컬 후보 DONE / 운영 연결 PARTIAL / 공개0.** Owner 지정 원본 폴더 `~/development/legendstudy-materials/essay-2026-10/이화여대/`의59파일을 조사했다. PDF58개476쪽, 비내용 `.DS_Store`1개다. 원본 수정·이동·이름 변경0, 빌드 전후58개 SHA·수정시각 보존. 예전 임시 저장소에서 발견한26PDF 모두 동일 SHA로 재사용하며32파일이 이전목록에 추가됐다.

후보는 APP/common repository의 [supabase/candidates/ewha_essay_20261112](../supabase/candidates/ewha_essay_20261112/README.md) 한 곳에서 관리한다. 잔여51 운영 후보와 디렉터리·commits를 구분하고 동일 Worker/engine 파일을 수정하지 않았다. WEB 브랜치에 이화 후보를 복제하거나 다른 브랜치를 병합하지 않았다. 원문 이미지는 ignored `.local/ewha-essay-20261112`에만 둔다.

## 계열·학년도·시험

| 공식 계열 | 시험·문항 | 문제·해설 PDF | 명시 기준/로컬package | 부족 |
|---|---:|---:|---:|---|
| 인문계열Ⅰ | 8·24 |16|수시6·18 / 기존Essay1.3|모의2·6 채점기준|
| 인문계열Ⅱ | 8·24 |16|수시6·18 / 기존Essay1.3, Q3 business|모의2·6 채점기준|
| 자연계열(Ⅰ·Ⅱ 포함) | 13·39 |26|수시9·27 / 기존Math v1|모의4·12 채점기준|
| 합계 |29·87|58|21시험63문항|8시험24문항|

인문Ⅱ에는 사회·경제/상경 내용이 포함된다. 별도 사회·상경 시험 Registry를 만들지 않는다. 인문Ⅱ Q1·Q2는 humanities, Q3은 기존 business 입력 계약으로 구분했고 원래 시험 ID/계열은 유지했다. 자연 자료는 수리 문항이며 별도 과학계열을 생성하지 않았다. 2021–2023수시 각3시험,2024수시/2024모의/2025수시/2026수시/2027모의 각4시험이다. 연도는 원문 **학년도**이며 별도 실제 시행 날짜는 미확인이다.

2026수시 `인문계열 해설,답안.pdf`의 본문은 인문계열Ⅱ다. 파일명을 고치지 않고 매핑만 확정했다. 모든 파일의 역할·쪽수·SHA·기존목록 일치는 [58파일표](../supabase/candidates/ewha_essay_20261112/README.md#모든-파일), 문항별 물리페이지/배점 원문 영역은 [source-plan](../supabase/candidates/ewha_essay_20261112/source-plan.json)과 [package-receipt](../supabase/candidates/ewha_essay_20261112/package-receipt.json)에 있다.

## 기존 구축 이력과 현재 운영

- 2026-10-12 WEB `7d62bb5` 공식 자료 inventory13시험39문항/26파일, `89dcbe7` Source 선택·로컬 draft, `146727f` canonical draft/등록 후보 이력이 있다. `86282c7`은 대학 브랜드 자료이며 첨삭 package 구축 증거로 세지 않는다.
- APP `b0aa1ee7`, Migration `20261012212352_essay_source_registration_76_234`에서 이화 **2024모의 자연계열Ⅰ 1시험3문항** metadata가 등록됐다. APP `0b99cdd4`는 공통 private Registry/기존 package binding 구조다. 해당 이화 자료의 평가 준비 완료를 뜻하지 않는다.
- 기존 시험 ID `c15360f1-571e-5fa4-8314-dde3022f9594`, 기존 문항 `f32f7b67-6fcf-52ab-b6b7-06074712c702`, `4a432fdf-d601-5230-b045-d2123c614773`, `e7362b80-3f05-5d84-8768-826ab7136233` 유지. 나머지28시험84문항은 동일 source-key/UUIDv5 규칙의 **로컬 제안 ID**만 있고 운영 등록0.
- 운영 SELECT에서 기존3문항 관련15테이블의 rubric/Math/Worker/답안·평가 연결0, Provider/model/prompt별 평가기록0,58개 원본SHA 기준Storage 객체0. 공개 browse의 metadata/`evaluationReady:false`와 사용자 첨삭 공개를 구분한다. [운영 읽기 영수증](../supabase/candidates/ewha_essay_20261112/production-readonly.json).
- Wiki/전체 local Git refs/기존 inventory/Worker material 기록/운영3문항 관련 자료에서 이화 전용 실제 Provider호출,기준 생성·수정,정상·오답·부분답안 평가,사용 모델·prompt 버전,품질PASS 기록은 확인하지 못했다. **확인 범위 밖의 실험이 없었다고 단정하지 않으며 ‘학습 완료’라고 보고하지 않는다.** [검색 범위·커밋 증거](../supabase/candidates/ewha_essay_20261112/history-audit.json).

## A–F 단계별 상태

각 행은 독립 검증 상태다. 운영 Registry가 있는 모의3문항은 명시 기준이 없어 로컬63package에 포함되지 않으므로 단순 누적 퍼널로 해석하지 않는다.

| 단계 | 시험·문항 | 확인 범위 |
|---|---:|---|
| A SOURCE READY |29·87|Owner 지정 공식 문제/해설 원본 확보|
| B REGISTRY READY |1·3|기존 운영 metadata, ID/내용 불변|
| C RUBRIC READY |21·63|로컬 공식 채점표 원문·이미지/물리페이지·SHA 바인딩|
| D PACKAGE READY |21·63|기존Math27 + Essay36 로컬 계약 검증|
| E TECH READY |0·0|WEB·APP/운영 권한·저장·재첨삭 연결 미완료|
| F PUBLISHED |0·0|운영 적용/공개 없음|

C의63개는 공식 표를 그대로 연결한 상태이며 모든 배점을 숫자별 자동 추출/정규화 완료한 의미가 아니다. 2023인문6개 채점표는 일부 내용이 이미지로만 읽혀 원본 이미지를 필수로 보존했다. 자연 수식의 private glyph도 추정 교정하지 않고 공식 이미지를 함께 쓴다. 2024인문Ⅱ Q3 등 머리말만 있는 다음 페이지를 기준에서 제거했고, 문항 전체 공식 rubric을 하나의 Essay 기준 binding으로 연결해 페이지 분할을 별도 기준으로 오인하지 않는다.

모의8시험24개는 출제의도/해설·예시답안은 있지만 명시 채점기준이 없다. 예시답안에서 점수/기준을 만들어 채우지 않았고 package0으로 남겼다. [87문항 A–F 표](../supabase/candidates/ewha_essay_20261112/stage-status.json).

## 재사용 구현과 검증

`tool/prepare_ewha_candidates.py`는 기존 `natural_expansion.build_review_package`, `task20_priority_packages.registration_sql`, `package_registry.bind_registered_package`, `live_worker.package`를 재사용한다. 새 evaluator/Provider 호출/운영 connector 없음. 자연 문제/출제의도/기준/해설은 서로 다른 원본 SHA·물리페이지로 고정한다. 인문은 공식 문제지 공통 제시문과 대상문항을 함께 전달하고, 기준 영역은 예시답안 시작 전에 끝낸다. 원문 해설을 학생에게 공개하는 변경은 없다.

`tool/test_ewha_candidates.py`: **5 unit PASS**, 인문36개 실제 기존 package binding·입력 검증과 text/image해시·외부evidence·학년도 변조 거부 PASS. 격리 PG17에 자연27개 기존8테이블 DRAFT후보를 넣어 **기존 Worker 조회81검사 PASS**, 등록2회 재실행/idempotency PASS. 원본58 SHA 보존 PASS. 자연37페이지·인문32페이지 overview와 대표 채점표10개 원본/영역을 렌더해 확인했다. 모든476페이지의 육안 전수 판독은 NOT TESTED이며 문항별 본문 품질 평가와 구분한다.

실제 Provider0/AI품질 NOT TESTED. WEB·APP 브라우저/실기기,실제 로그인 제출·결과·재첨삭 NOT TESTED. 로컬 성공을 TECH READY/PUBLISHED로 올리지 않는다. [테스트 영수증](../supabase/candidates/ewha_essay_20261112/validation-results.json), [격리 Worker81검사](../supabase/candidates/ewha_essay_20261112/isolated-worker-results.json).

## 운영 적용 전 정확한 범위

**현재 즉시 공개 가능0, 1차 연결 후보21시험63문항**. 이63개는 모두 기존 운영3개와 겹치지 않는 수시 후보다. 운영 적용 전 필요한 작업은 다음과 같다.

1. 동일 source-key/UUIDv5를 사용해21시험63문항 Registry 추가안 작성·기존1시험3개/전체 공개 문항 중복 가드. 나머지 모의21개 신규 제안ID는 적용하지 않는다.
2. 공식 PDF 원본42개(문제21/해설21)의 표시/Worker처리 권한 및 공식 원문 URL 근거 확정. 이번 조사는 Owner 지정 로컬 원본을 기준으로 했으며58개 각각의 온라인 배포 허락을 새로 확인한 것이 아니다. 학생 제공은 문제PDF21개만, 해설은 기존 private Worker 처리 경로. Storage접근 변경은 정확 object범위 후보를 먼저 검증한다.
3. 자연27 기존Math13행 내외 package/Worker 계약, 인문36 기존Essay1.3 공식evidence/criterion/assignment를 canonical DB version과 연결. 인문Ⅱ Q3은 기존business계약 재사용,혼합평가 새엔진 없음.
4. 기존WEB/APP의 Source조회·PDF/답안작성·제출·부모결과·재작성 범위와 canonical binding 승인/권한을 격리환경에서 끝까지 검증. 현재 로컬source lookup만으로 완료 처리하지 않는다.
5. 사전SELECT/적용SQL/사후조회/신규진입만 닫는 비파괴원복안 준비 후 Owner 운영 승인. 기존 사용자답안·결과·이력·Credit 삭제0,권한 확대 최소화,동시상태 변경시중단. 승인 전 운영 변경·공개0 유지.

현재 상태부터 **약2–4개 개발일의 데이터 등록·기존 계약 연결·회귀 작업 추정**이며 PDF권한 확인/운영 승인/OwnerAI검수 대기는 제외한다. 모의24개는 공식 채점기준 확보를 별도로 기다린다. 운영 적용 승인은 구체적인 SQL·권한·배포 검증안을 작성한 후 요청하며, 이번 원본 조사로 자동 승인되지 않는다.

## 보존 원칙과 Git

원본 수집일/시험 학년도/변경시각을 혼용하지 않고, SHA·파일명·물리페이지·candidate버전을 고정한다. Registry·학생 신원·답안·평가 계보·원장을 덮어쓰지 않는다. 학습 사실/평가/진학 결과를 섞지 않고 공식 원문과 후보 해석을 구분한다. 개인정보 수집/보존기간·Credit·동의 목적 변경0. 신규 공개 사실은 운영 영수증이 있을 때만 기록한다.

APP branch `codex/essay-natural-expansion-20261111`, WEB branch `codex/essay-public-natural-20261112`. 이화 코드·manifest commit은 별도이며 최종 HEAD는 Git 로그/완료보고로 확인한다. WEB 운영 source HEAD는 `7987a4639dcb18fbbf3a8a9e771a0bcaa8e68c5c`(동국 정정), 이화 운영 배포는 없다.

구현·원본 감사 commit: `3b1add1ce4407273bbdfd5f0ca493b1423c51a88`. 아래 후속 문서 커밋은 후보/운영 상태를 승격하지 않는다.
