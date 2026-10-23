# 논술 LAB — Claude 최종 인수인계 / 2026-10-24

## 중단 지점과 금지 사항

계정 도구 확인: 주간95%사용/5%잔여. Owner 지시에 따라 신규개발·Provider호출 중단, 안정화와 인수인계만 수행했다. 11대학 전체서비스 **미완료**. 기존공개12/전체등록512이며 대표E2E9를 전체완료로 취급하지 않는다. 후속실행은 아래 순서로 재개한다. 이 문서는 기존 [묶음 연결](essay-batch-service-20261023.md), [프로필 운영증거](university-profile-production-e2e-20261023.md), [P0 WEB/APP](essay-p0-direct-execution-20261023.md)를 요약하며 과거 성공증거를 재작성하지 않는다.

Production Supabase `stlhijzpjfgwwdgunlsd` SQL은 Owner만 실행한다. 기존ID/정책/RLS/Secret/프로필 pin/Credit/Ledger/History 보존. 새 평가엔진·WebView전환·무관한 결제/Credit/MY수정 금지. 이번 종료작업은 READ-ONLY 운영확인, Provider0/새배포0/DB쓰기0/Secret변경0.

## Git와 실제 배포

다음 SHA는 인수인계 작성 직전 구현 기준선이다. 최종 문서 commit은 이 파일을 포함한 Git commit에서 확인하며, 최종 응답에 로컬/원격 SHA 대조 결과를 보고한다.

|대상|폴더|브랜치|구현/문서 기준 SHA|
|---|---|---|---|
|APP 및 Worker 소스|/Users/woojinchang/development/legendstudy-service-app-20261022|codex/material-service-app-20261022|7b6b3af361caa1fef5f64c61a74f5a9860de215c|
|WEB|/Users/woojinchang/development/legendstudy-material-ui-release-20261022|codex/material-browse-release-20261022|f1a9e27a7d1e8d9882339398b4c0cbc86aa43616|
|Unified Wiki DOCS|/Users/woojinchang/development/legendstudy-service-docs-20261022|codex/material-service-docs-20261022|75adaae39860b1145281046739e8dbab034b5e28|

- APP 설치 build `2026102401`, GalaxyS8 `ce021712a597b93505`. 현재Git과 설치APK는 같다고 추정하지 않는다. 이 종료작업에서 APP 재빌드 없음.
- WEB Production `e67a0d37-0d1f-4042-b480-7ffd7ba18b5b`, source `f1a9e27a7d1e8d9882339398b4c0cbc86aa43616`, `https://lab.legendstudy.com` HTTP200. Cloudflare canonical deployment에서 확인.
- Essay Worker `legendstudy-essay-reviewed`: version `c3fb54be-2f98-40cb-8a1a-2caae786003b`, deployment `82ce516d-a843-47e0-a116-d5d077fc6ce2`,100%. 실제변수와 기존검증설정 일치. Worker 전용Git저장소는 없으며 APP tree의 `tool/essay_lab`, `tool/cloudflare_essay` 및 기존 배포 산출물을 사용한다. Git SHA와 Cloudflare version UUID는 다른 식별자다.
- 관리API 최초401은 로컬Wrangler OAuth 갱신 후 READ-ONLY 재조회 성공. 운영Worker/Provider Secret 오류로 해석하지 않는다. Secret 원문조회·출력·전송 없이 기존 설정 유지.
- APP 미커밋 기존별도작업: `.gitignore` 수정, `.fvmrc`, `.wrangler/`, `supabase/.temp/`, Python cache, `tool/essay_lab/prompts/scaffolding-1.3-v13.txt`, `scaffolding-1.3-v14.txt` untracked. 인수인계 작업에서 임의commit/reset/삭제하지 않았다. WEB은 clean.

## 대학별 현재 범위

READ-ONLY 운영DB:11대학171시험512문항. 기존작업집합157시험과의차이14시험은 문항없는 경희8/성균6 시험이다.2022이후509문항, 경희기존연도3은 보존만 하며 범위에서 분리. 전체Registry700과 이11대학512를 혼동하지 않는다. 아래FULL은 기존 조립초안이며 운영입력PASS/공개가 아니다. DIAGNOSTIC은 전대학0.

|대학|운영등록 시험|등록문항|2022이후|기존프로필|FULL초안|NEEDS_REVIEW|일반공개 정책|기존 실제E2E 완료|
|---|---:|---:|---:|---:|---:|---:|---:|---:|
|dongguk|16|48|48|24|5|43|0|0|
|gachon|17|166|166|166|0|166|0|0|
|kau|15|30|30|20|0|30|0|0|
|konkuk|21|58|58|41|5|53|5|2|
|korea|10|30|30|30|1|29|0|1|
|kyunghee|18|38|35|29|1|37|0|0|
|sogang|24|28|28|19|1|27|0|1|
|sookmyung|8|22|22|22|3|19|0|2|
|soongsil|16|42|42|40|3|39|3|1|
|sungkyunkwan|15|27|27|15|2|25|2|1|
|swu|11|23|23|17|2|21|2|1|

공개총12=Essay시험단위11(9시험)+건국Math별도1. Pages `ESSAY_PUBLIC_EXAMS`와DB runtime_policy/approval 교집합11 확인. Math leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3`/question `cea40cf3-dc05-507a-a6eb-fd5e1e1847bb`: admission/catalog pin, ACTIVE set/problem, evaluations_enabled 및 Pages public leaf/Provider flags true 확인. 새 실사용자E2E를12개 전부 재실행한 수가 아니다.

E2E9: 건국인문/수리2, 숙명2025모의/2026수시2, 서강2026모의1, 고려2025인문2 1, 성균2026언어1교시Q1 1, 서울여2026Q1 1, 숭실2026Q1 1. 초기숙명/서강/고려는 운영검증계정·당시APP범위이며 일반공개 완료와 다르다. 성균/서울여Q1/숭실은 일반계정WEB+GalaxyS8확인. 서울여Q2는 최초평가만 성공하므로 E2E9에 추가하지 않았다.

전수입력:512초안/FULL23/DIAG0/보류489. profile423/미상속89, 공식매핑430/텍스트398은 기존기준선. 고려12텍스트회복은 병합파일에만 반영, 자동승격0. 대학별 최종 입력PASS는 아직 집계확정 안 됐으며 FULL로 대체하지 않는다.

## 89 미상속 / 37 묶음 / 17 후보

89는 기존 실패명세를 재사용했다.489보류중미상속88+보존MathFULL미상속1. 공통원인별중복집계는 기존 묶음문서 참조. 아래37묶음은 실행/오류분리단위이며 question IDs는 원본 `root-causes.json`에 고정돼 있다.

|대학|학년도|시험종류|유형|문항수|오류|
|---|---:|---|---|---:|---|
|dongguk|2022|mock|자연계열|3|PROFILE_MISSING|
|dongguk|2022|mock|인문계열|3|PROFILE_MISSING|
|dongguk|2023|mock|인문계열|3|PROFILE_MISSING|
|dongguk|2023|mock|자연계열|3|PROFILE_MISSING|
|dongguk|2024|mock|자연계열|3|PROFILE_MISSING|
|dongguk|2024|mock|인문계열|3|PROFILE_MISSING|
|dongguk|2026|admission|자연계열|3|PROFILE_MISSING|
|dongguk|2027|mock|자연계열|3|PROFILE_MISSING|
|kau|2022|admission|이학계열|2|PROFILE_MISSING|
|kau|2022|admission|공학계열|2|PROFILE_MISSING|
|kau|2023|admission|이학계열|2|PROFILE_MISSING|
|kau|2023|admission|공학계열|2|PROFILE_MISSING|
|kau|2023|admission|사회계열|2|PROFILE_MISSING|
|konkuk|2024|mock|인문사회Ⅱ|2|PROFILE_MISSING|
|konkuk|2025|mock|자유전공|2|PROFILE_MISSING|
|konkuk|2025|mock|인문사회Ⅱ|2|PROFILE_MISSING|
|konkuk|2026|admission|인문|1|PROFILE_MISSING|
|konkuk|2026|mock|통합|2|PROFILE_MISSING|
|konkuk|2026|admission|자연|4|PROFILE_MISSING|
|konkuk|2026|admission|통합|4|PROFILE_MISSING|
|kyunghee|2021|mock|사회계|3|PROFILE_MISSING|
|kyunghee|2022|mock|자연계|4|PROFILE_MISSING|
|kyunghee|2027|mock|사회계|2|PROFILE_MISSING|
|skku|2023|mock|자연계|3|PROFILE_MISSING|
|skku|2025|admission|언어형|3|PROFILE_MISSING|
|skku|2027|mock|언어형|3|PROFILE_MISSING|
|skku|2027|mock|수리형|3|PROFILE_MISSING|
|sogang|2023|mock|자연계열|2|PROFILE_MISSING|
|sogang|2024|mock|자연계열|1|PROFILE_MISSING|
|sogang|2025|mock|자연계열|2|PROFILE_MISSING|
|sogang|2026|admission|인문계열(경제경영)|2|PROFILE_MISSING|
|sogang|2026|mock|자연계열|1|PROFILE_MISSING|
|sogang|2027|mock|자연계열|1|PROFILE_MISSING|
|soongsil|2022|admission|인문계열|2|PROFILE_MISSING|
|swu|2023|admission|자연계열|2|PROFILE_MISSING|
|swu|2024|admission|자연계열|2|PROFILE_MISSING|
|swu|2025|admission|자연계열|2|PROFILE_MISSING|

17호환후보=건국9/항공3/서강5. 기존PDF 공식근거로32개 검토·17독립PASS,15보류,57은공식후보부족. **프로필 새버전/상속 반영은 아직 없음**. 같은검토30회(추정USD2.496596)를 반복하지 않는다. private누적229호출/추정USD22.987344/기존불명2; 운영receipt비용NULL은0으로계산하지않고별도유지.

|대학|문항ID|기존프로필 후보|
|---|---|---|
|kau|9b99b725-1db4-5f45-98b7-8062184259e9|uep/kau/social|
|kau|266b08c1-3b68-5e67-aee4-9dacc75093b3|uep/kau/engineering|
|kau|8b9b0f55-5bcf-5c74-98b7-83ba81a9da9e|uep/kau/engineering|
|konkuk|1b26acfe-6f9e-5c32-8bc6-f79946c51593|uep/konkuk/humanities|
|konkuk|cea40cf3-dc05-507a-a6eb-fd5e1e1847bb|uep/konkuk/math|
|konkuk|7c112225-51cc-59d8-a985-6c459a1e0a0a|uep/konkuk/math|
|konkuk|40290efd-36af-55a9-beb7-8c90bbb04ee4|uep/konkuk/math|
|konkuk|a7d06546-9d61-5317-afff-e656c25964f7|uep/konkuk/math|
|konkuk|509dea2c-cda8-5dcd-a98b-6226e9b559d3|uep/konkuk/humanities|
|konkuk|a6f4d2b0-3b68-5a71-89c8-077921603658|uep/konkuk/math|
|konkuk|a03d83b2-5109-58a1-96e8-0c6ebb65cc5c|uep/konkuk/math|
|konkuk|d8cf9053-496d-5ee6-a4c8-54aac03417c1|uep/konkuk/math|
|sogang|38855473-99d1-5b4d-8dd1-3af5c22b2102|uep/sogang/math|
|sogang|fa0bd742-0c3c-5981-8525-e19976f67f7b|uep/sogang/math|
|sogang|e24c5c6c-c0ad-5723-a15c-61f5b2322044|uep/sogang/math|
|sogang|3b96a9ab-3629-5e4d-bec3-475928fa4a74|uep/sogang/math|
|sogang|d74b47b8-87a1-587b-ae7d-623d08ccdb08|uep/sogang/math|

로컬 증거 디렉터리: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/batch-remediation-20261024`

- `root-causes.json`:512/489,37묶음의 정확한 IDs·원인·draft digest.
- `profile-89-dossiers.private.json`, `profile-scope-review-results.private.json`: 공식근거해시/페이지/인용 및 독립검수. 원문이므로Git에복제금지.
- `source-audit-merged.private.json`, `source-repair-summary.json`: 고려12회복/나머지500보존. FULL승격아님.
- 기존512: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/batch-assembled-512.private.json`.
- 기존프로필/미상속: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/university-profiles-20261023/`, `reference-recovery-20261023/base-inheritance-512.json`, `remaining-89.json`.
- 재현도구는APP `tool/essay_lab/batch_remediation.py`, `batch_source_audit.py`; tests9PASS. PDF검사는 bundledPython 사용(시스템Python pypdf없음).

## 서울여Q2·기록보존·알려진 오류

WEB문항별pending키 분리commit f1a9e27,11검사/typecheck/buildPASS. legacy키/본문 보존, 동일문항재사용, 겹치는문항집합차단. localStorage일괄삭제/새키강제재제출 금지. 최초 `bf95ad2f-8382-4999-82c4-054fd8437dee` completed/1settled, 재첨삭 `44e85e8f-352f-495b-9d4b-6cb6ebb5edc9` failed/0released.

보류원인B(현재관측서울여Q2자료해석): GMO채택률 확대추론은 지적했으나 사료비율56.0→38.1 감소를 증가로 읽은 별도오류를 평가가 놓침. 독립검수 grounding/root_binding fail로게시차단. 실패복제/Provider재호출 중단. 공식자료별 수치/비율 검증과동일유형영향조사 후 기존계약에서최소보완. 공유Worker전면수정근거없음. 무료재첨삭APP성장/교차조회미완료.

종료시 READ-ONLY 정산 재확인: 서울여Q1 `28b18e34-a3fe-48c4-8bf9-33ce891704c8` / `c425da77-4d11-4dbf-891a-d8d209182767` 및 숭실 `244aed57-d1d2-4095-9c90-18f9fffa07da` / `03b6e579-dee5-477c-9add-6f932c7ae367` 모두completed/최초1settled/재첨삭0settled 유지. 기존History·Ledger 구조변경/삭제0. 종료시전체Ledger재감사는하지않았으며 기존보존검사와해당정산증거를재사용한다.

기타: 숭실제출화면대기안내는History복귀에서완료표시(자동완료화면미PASS); 공개시험allowlist42상한은157시험확대전검토; S8미러링터치불응은Owner수동검증사용. 새로운전체공통장애는확인되지않음.

## SQL 적용 상태 / 복구

이작업이새로Owner실행을요청할 **미적용 승인완료패키지0**. 17후보는SQL미생성/입력미검증으로적용대기SQL아님. 기존 `71702`는과거미적용HOLD 기록이며 이번작업적용대상아님; 파일존재만으로실행금지. 다른팀결제/관리자SQL은이인수인계의승인범위밖.

이미적용(재실행금지): 고려운영,성균Q1운영/PDF,서울여revision3 Q1/Q2, normal-batch-01건국·성균·숭실6시험7문항, 건국Math공개.

- 묶음원본 `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/normal-batch-01/` 의 `OWNER-README.md`, `precheck.sql`, `apply.private.sql`, `postcheck.sql`, `rollback.sql`.
- 서울여 `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/swu-batch-revision3/` 동일세트. historical-reader 별도재실행금지.
- 성균PDF APP `supabase/candidates/skku_q1_public_pdf/`; Math APP `supabase/candidates/math_konkuk_public_release/`.
- rollback은Owner가해당문항신규요청만차단/기존정책복귀할때사용; 답안·평가·History·Ledger 삭제금지. 현재정상상태를이유없이롤백하지않는다.

배포복구: 현재WEB e67a0d37/Worker c3fb54be를유지. WEB직전정상40c5085a-107b-4b27-8a4a-70a3eab740db는복구후보이나Q2키수정전이므로회귀영향을확인. 빌드시기존Production NEXT_PUBLIC plain-text6개필수; Secret마스킹값을API PATCH로재전송하지않는다. Worker버전과DB binding/digest호환 확인후기존버전으로전환하며한쪽만무조건롤백하지않는다. 배포후canonical/version100%·공개범위·일반로그인·기존History를비과금확인. Secret복구/SQL은Owner직접조치.

## Claude 재개 순서

1. AGENTS→index→current-status→decisions→scope와위증거를읽고작업폴더/Git상태확인. 기존성공Provider/E2E재실행금지.
2. 건국21시험58문항부터:17후보중건국9의정확한question scope를기존프로필새버전에추가검토. 기존423mapping pin보존,혼합형전체track을인문으로바꾸지않기. 전체근거/입력검증후정상묶음SQL4종작성,Owner적용후해당대표계약만검증.
3. 보류53을PDF경로/경계/수식/Math연결공통원인으로처리. 개별30분초과시실패명세를남기고정상묶음진행. 이어다른대학전체문항처리.
4. Owner후속UI작업: 관리자PR #2와WEB MY개선브랜치는정확한저장소/HEAD·충돌을조회후통합(이인수인계에서merge/build수행안함). 기존결제/Credit변경보존,Flutter Native유지.
5. 통합후Android/iOS빌드·WEB/APP교차조회·실기기검증. **Owner최종승인전스토어업데이트금지**.
