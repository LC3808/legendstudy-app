# 대학별 첨삭 프로필 PHASE 2 — 2026-10-23

## 상태: PARTIAL

Owner가 PHASE1(81e83d3)을 승인했다. 기존 엔진의 입력 조립을 로컬 구현하고 비공개 프로필 revision을 저장했다. 전체11대학 공식 프로필 검수·운영 엔진 적용 완료는 아니다. 기존 운영건국2문항·Worker·Gateway·Credit·History·UI를 변경하지 않았다.

## 구현

- `tool/essay_lab/university_profile.py`: content hash 검증, 명시 대학/시험/학년도/유형/계열/문항 scope 선택, ambiguous/missing 거부, 과거version pin선택, 동일계층충돌 차단, 문항>연도예외>프로필 criteria 우선순위, unknown≠0, immutable sidecar 생성.
- `material_runtime.load_reviewed_material(..., university_profiles=None)`: 기존 Worker loader에 선택적 연결. 미지정 시 기존 경로 그대로. 현재 배포 Worker는 미지정 상태로 보존한다. 신규입력/버전 trace는 sidecar에 보존하며 기존 History DTO에 필드를 임의추가하지 않는다.
- `bind_material`: 기존 검수된 문항기준은 그대로사용, 프로필/연도fallback으로 내용이 달라진 패키지는 `COMPILED_PACKAGE_REVIEW_REQUIRED`로 runtime 실행 차단한다. 생성 후보의 기존 digest를 신규검수 완료 digest로 간주하지 않는다. 기존 source/binding/rights/admission 검사 재사용.
- `bind_math`: 기존 physical profile ID/content hash·leaf·problem pin 대조, 기존 Math context 그대로반환. 신규숫자점수·대학scope·DBrow 없음. 실제MathWorker까지 새로운profile을배포한것은아님.
- 공통역량·피드백·감점 등의 표준필드는 저장할수있지만 현재 runtime projection은 검수된 criteria와 기존Math profile 중심이다. 모든서술필드가Provider에전달된다고주장하지않는다.

## 비공개 산출물

`~/development/legendstudy-materials/essay-validation-2026-10/university-profiles-20261023/`

- `profiles/<university>/<type>/v1.json`, `v2.json`: 30후보/60revision. v1덮어쓰기없음.
- 최신 3개는 **특정문항 한정 REVIEWED**, 27개 DRAFT. 공통적용학년도 전체를검수한3개라는뜻아님.
- DRAFT는 기존 공식자료 페이지 연결1730개를 대학별 미배정 근거inventory로재사용. 타입별공통기준으로승격하지않았다. 적용scope는비어있어선택불가.
- `compiled/`: 건국인문Q2·수리Q1, 숙명2025모의인문1-1의 입력+profile resolution 3개.
- `prepare.py`, `attach_inventory.py`: 기존 registration/review/accepted metadata 재사용. 재실행에서같은revision내용확인, 원본/PDF재업로드0.
- `report.json`, `legacy-parity.json`, `failures.json`: 건수/실제입력비교/509미연결문항의대학·연도·시험·계열·IDs·원인·근거·권장조치.

원문·평가기준 텍스트·비공개JSON은Git에포함하지않는다. Compiler/test/Wiki만Commit한다.

| 대학 | 후보 | 문항한정 REVIEWED | DRAFT | 조립 문항 |
|---|---:|---:|---:|---:|
| 가천 | 2 | 0 | 2 | 0 |
| 건국 | 3 | 2 | 1 | 2 |
| 경희 | 4 | 0 | 4 | 0 |
| 고려 | 2 | 0 | 2 | 0 |
| 동국 | 3 | 0 | 3 | 0 |
| 서강 | 3 | 0 | 3 | 0 |
| 성균관 | 2 | 0 | 2 | 0 |
| 숙명 | 3 | 1 | 2 | 1 |
| 숭실 | 3 | 0 | 3 | 0 |
| 서울여 | 2 | 0 | 2 | 0 |
| 한국항공 | 3 | 0 | 3 | 0 |
| 합계 | 30 | 3 | 27 | 3 |

## 검증 결과

- profile/material/registry/exam runtime 관련 **41 unittest PASS**, Python compile·diff check PASS. fixture 테스트이지실제운영E2E추가실행아님.
- 실제기존 건국·숙명 private package: 프로필전/후 기존 `frozen_cache` 동일PASS. 실제Math기존context동일PASS. 한양accepted 원본pin/이미지5/근거4재사용검사PASS.
- 동일입력 재실행: 기존revision/compiled bytes 동일. DRAFT/다른연도/다른계열/다른문항/모호scope/내용hash변경 차단PASS.
- 과거profile version선택, 소유권/중복요청의기존exam계약test 재사용. Production Ledger검증/무료재첨삭신규거래는실행하지않음.
- 새로운Provider 입력변경이없는3문항을불필요하게재호출하지않음. **추가Provider0회·비용US$0**. 새profile의실제평가품질PASS를주장하지않음.
- WEB/Native 코드·DTO·UI 무변경. 새프로필의실제WEB/APP/History저장E2E는미실행.

## 미완료와 다음 작업

509문항의공식기준/유형별공통성/학년도scope가미검수다. 원문존재여부와검수완료를혼동하지않는다. 27개DRAFT는표준형식과근거inventory만준비되어, 대학별내용제작완료가아니다. 현재부족한것은승인요청이아니라공식자료정밀검수·그결과의프로필작성이다.

연도/프로필fallback으로새criteria를생성한경우 기존검수package의서버digest·권리·revision·실행정책검증을거쳐야한다. 자동검수/권한승격없음. Math는로컬context대조까지이며기존physical adapter/운영Worker에새프로필적용검증은남아있다.

PHASE3 적용가능범위: 기존활성건국2문항을유지한다. 숙명신규공개0, 나머지새활성0. 이번산출물만으로일반전체공개/22대학확대를진행하지않는다. 경희·동국보강HOLD, Payment/IAP/서명키/71702변경0.
