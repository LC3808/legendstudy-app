# 11대학 전체 문항 서비스 연결 — Owner 최종 지시

2026-10-23 Owner 지시. 공통 UX·대학별 평가·문항별 근거를 분리하고 기존 Essay/Math
Worker를 재사용한다. 대표11문항 공개를 전체완료로 처리하지 않는다. 기존 대학별
프로필 전략을 구체화하며 [PHASE1](university-evaluation-profile-phase1.md),
[PHASE2](university-evaluation-profile-phase2.md), [P0 실행 이력](essay-p0-direct-execution-20261023.md)을 계승한다.

## 확정 범위와 실행 순서

일반 계정 공개가 기본이다. 운영 계정 선검증을 강제하지 않는다. DB의2022~2026기출,
2027모의를 대상으로 한다. 기존11대학 작업집합512에는2021경희모의3문항이 포함되어 요청연도범위509와 구분해 보존·분류한다. 기존28기본체계·423상속·89미상속,
시험/문항ID, PDF·근거·RLS·Credit·Ledger·History, 성공E2E를 보존한다.

1. 서울여Q1 진행 상태를 이어 일반계정 최초1/무료재첨삭0·신규History자동반영·WEB/APP 확인.
2. 같은 평가체계의 서울여 정상 문항을 묶어 확대.
3. 기존 성공 대학 정상 문항 → 나머지11대학 정상 문항 → 미상속89보완.
4. 전체512범위 확정 및 검증 묶음 서비스 활성화. 이후22→30→35대학 이상.

공통 UI를 유지하고 대학별 화면·새 엔진·서버를 만들지 않는다. 결제 담당의 검증된
결제/Credit/MY 소스를 건드리지 않는다. 사진 입력 등 기존 기능의 실제 지원 범위를
확인하며 지원하지 않는 유형을 텍스트로 강제하지 않는다.

## 기존 입력 조립과 묶음 단위

대학 기본체계 → 학년도/시험별 실제 예외 → 해당 문항 공식 정답·해설·채점기준 →
기존 실행 계약. 충돌 시 문항 공식 기준이 우선이다. 모의/수시·학년도·유형 범위를
추측하여 넓히지 않는다. 다른 문항 답안을 차용하지 않는다.

공통 프로필/버전/학년도·시험·유형 scope별로 묶되 문항마다 공식 근거와 입력 digest를
고정한다. 기존 version-pinned snapshot은 유지하며 새 검수 revision만 추가한다.
대표 유형 실제E2E와 전체 자동입력검증을 별도 집계한다. Provider 미호출 문항은
개별E2E PASS가 아니다. 문항별 동일 SQL·승인·E2E 반복을 대학/유형별 묶음으로 대체한다.

## 분류와 실행 승인 분리

- FULL_EVALUATION: 정확한 문항 공식 근거+기본체계로 정답/논점/풀이 평가 가능한 범위.
- DIAGNOSTIC_EVALUATION: 기본체계와 검증된 문항으로 제한적 진단만 가능. 부족 근거,
  평가 제외 범위를 표시하고 공식 채점 완료라고 표현하지 않는다.
- NEEDS_REVIEW: 문항/근거/유형/프로필 충돌 또는 검증 부족. 자동 활성화 제외.

프로필 상속만으로 FULL이나 입력검증PASS를 부여하지 않는다. 분류는 활성화 승인과
다르다. DIAGNOSTIC의 현재 계약/공통 표시 지원 여부를 먼저 확인하고 유료정책은 임의
변경하지 않는다. 분류 표시가 필요한 경우 공통 계약의 최소 변경으로 처리한다.

전수 검사 열: canonical시험/문항ID, 연도/시험/계열/유형, profile/version/digest,
연도예외, 문제PDF, 공식자료, 입력조립, Worker호환성, 분류/사유, 활성화 후보.
대학별 등록시험/문항, profile, 공식자료, FULL/DIAGNOSTIC/REVIEW, 입력검증,
실제E2E, 일반공개, WEB/APP를 모두 보고한다. 미확인값을0이나PASS로 바꾸지 않는다.

## 보존 검토 일곱 답변

1. 새 사실은 검증 결과·적용 revision·새 서비스 시도이다. 발생/검증/배포 시점을 구분한다.
2. 기존 원본 hash·page·profile version·package digest를 유지하여 입력을 재현한다.
3. 과거 답안/결과를 UPDATE하지 않는다. 새 검수 revision과 새 입력만 추가한다.
4. 기존 auth/account identity와 서버 소유권 검사를 그대로 사용한다.
5. 학생 첨삭은 Learning이며 분류/배포 결정은 운영 검증이다. 합격 Outcome으로 취급하지 않는다.
6. 기존 목적·권한·retention 안에서 처리한다. 새 개인정보 수집/공유나 Secret 노출 없음.
7. FULL/DIAGNOSTIC/품질등급은 검증된 파생 판단이다. 원문 사실과 구분하고 version/한계를 남긴다.

## 활성화와 복구

Owner가 Production SQL을 실행한다. 사전/전체적용/사후/롤백을 묶음별 생성하고 범위와
영향을 명시한다. 기존 성공 정책·일반공개·기록을 보존한다. 실패 문항은 명세로 분리하고
정상 문항의 준비를 계속한다. 현재 Gateway/Worker의42시험 허용목록 제한은 전체512
확대 시 검사할 기존 제약이며, 숫자만 무작정 늘려 승인 경계를 제거하지 않는다.

현재 전체 입력 조립·분류·서비스 활성화는 **미완료**다. 서울여Q1 SQL15검사PASS는
해당 문항 연결의 근거일 뿐512개 완료 근거가 아니다.

## 과거 읽기 전용 전수 대조 — 2026-10-23

Production identity700행에서 대상512ID를 대조: 모두 일치. 최신 상속423개 전부
profile/version/digest와 학년도·시험·유형 scope 재검증PASS. 미상속89 유지.
현재 운영 패키지의 Essay7문항 입력검증PASS(서울여 포함, 서울여 E2E 미완료).
건국 수리1문항은 과거 성공 보존이며 이번 입력 재검증 수에 포함하지 않는다.
아래 FULL8/DIAGNOSTIC0/REVIEW504는 **불완전한 조립 범위의 보수적 중간 분류**다.
504개가 실제 평가 불가능하다는 결론이 아니며 미조립 검수를 계속해야 한다.
기존 공식자료 매핑430은 이번 공식 근거 품질검수430PASS를 뜻하지 않는다.

|대학|시험|문항|프로필 재검증|기존 공식자료 매핑|이번 Essay 입력검증|FULL 범위|기존 E2E|공개 확인|
|---|---:|---:|---:|---:|---:|---:|---:|---:|
|동국|16|48|24|30|0|0|0|0|
|가천|17|166|166|166|0|0|0|0|
|항공|15|30|20|18|0|0|0|0|
|건국|21|58|41|58|1|2|2|2|
|고려|10|30|30|30|1|1|1|0|
|경희|10|38|29|31|0|0|0|0|
|성균|9|27|15|21|1|1|1|1|
|서강|24|28|19|13|1|1|1|0|
|숙명|8|22|22|18|2|2|2|0|
|숭실|16|42|40|40|0|0|0|0|
|서울여|11|23|17|5|1|1|0|0|

WEB/APP 성공은 위 기존 E2E 근거를 재사용한다. 이번 신규 교차조회0; 서울여는 미완료.
개별 미호출 문항에 E2E를 전파하지 않았다. 진단 실행 계약/표시와 전체 입력 조립은
미검증이며 자동활성화 후보를 생성하지 않았다. 다음은 서울여 동일체계 근거를 문항별로
조립하고 대학/유형/학년도 묶음 manifest와 Owner SQL을 생성하는 단계다.
검사 도구: `tool/essay_lab/batch_inventory.py`; private 증거는 materials의
`official-answer-quality-20261023/batch-inventory-512.private.json`에 보존한다.

## Source audit checkpoint — 2026-10-23

Live Registry237exams/700questions; legacy11-university512questions preserved, including
Kyunghee2021mock3 outside the current requested years (509 within). Existing mapped423/unmapped89 unchanged.
`tool/essay_lab/batch_source_audit.py` audited182existing PDFs across154 profile/year/type groups.
Hash/page/text/font/scope/profile checks PASS114; this is NOT semantic review, input compilation,
FULL_EVALUATION, activation or individual E2E. Existing successful packages are not demoted by an
older manifest's extraction failure. Malformed-font exceptions remain source failures and no longer
abort other universities;5testsPASS. Private detailed evidence remains outside Git.

|University|Legacy questions|Requested years|Extraction checks PASS|
|---|---:|---:|---:|
|dongguk|48|48|8|
|gachon|166|166|61|
|kau|30|30|0|
|konkuk|58|58|10|
|korea|30|30|4|
|kyunghee|38|35|4|
|skku|27|27|5|
|sogang|28|28|2|
|sookmyung|22|22|4|
|soongsil|42|42|15|
|swu|23|23|1|

Remaining failures distinguish missing role mappings, PUA/formula visual review, empty page text,
invalid page intervals, PDF parser failures and unassigned profiles. They are not permission to invent
criteria or silently activate DIAGNOSTIC paid evaluation. SWUQ2 existing official pages8–15/profilev6
compiled privately with2official chart images; original wrong-answer grounding failed, split criteria
regression passed. Q1 operating omission GAP is undergoing a private candidate check. No new SQL applied.

## 일괄 조립·다대학 적용 패키지 — 2026-10-23 23:40 KST

최신 Owner P0 우선순위 적용: 문항별 승인 반복을 중단하고 전체512문항을154묶음으로
조립했다. 운영 Registry237시험/700문항 중 대상11대학157시험/512문항이며 추가문항0.
요청연도509, 경희2021모의3은 역사적 범위로 보존한다. 초안 조립512는 검수/서비스PASS가 아니다.

|대학|시험|문항|상속|공식 매핑|공식 텍스트 조립|Essay 입력PASS|FULL|DIAGNOSTIC|REVIEW|현재 공개 연결|기존 운영E2E|신규 SQL 후보|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|동국|16|48|24|30|30|5|5|0|43|0|0|0|
|가천|17|166|166|166|166|0|0|0|166|0|0|0|
|한국항공|15|30|20|18|18|0|0|0|30|0|0|0|
|건국|21|58|41|58|40|4|5|0|53|2|2|3|
|고려|10|30|30|30|18|1|1|0|29|0|1|0|
|경희|10|38|29|31|31|1|1|0|37|0|0|0|
|서강|24|28|19|13|13|1|1|0|27|0|1|0|
|숙명|8|22|22|18|18|3|3|0|19|0|2|0|
|숭실|16|42|40|40|40|3|3|0|39|0|0|3|
|성균관|9|27|15|21|21|2|2|0|25|1|1|1|
|서울여|11|23|17|5|5|2|2|0|21|2|1|0|

합계: 상속423/미상속89, 기존 공식자료매핑430, 실제 비어 있지 않은 공식 텍스트조립398,
Essay 입력PASS22, 보존된 과거 Math E2E1을 더한 FULL23, DIAGNOSTIC0, REVIEW489.
FULL은 입력 범위이며 품질·권한·일반공개 완료와 다르다. REVIEW489에는 미검수·미조립
실행계약이 포함되므로 평가불가능489라는 결론이 아니다. 동국/경희 private 품질GAP,
숙명 기존 활성시험의 과거 digest 조회 보존 준비 등은 입력PASS여도 이번 적용에서 제외했다.
현재 공개 연결5는 정책/공개목록 교집합; 서울여Q2는 일반WEB 버튼 활성까지 확인했고
실제 제출은 아래 장애로 미완료. 신규7개는 아직 공개수에 합산하지 않는다.

### 자동 조립 및 검증

`tool/essay_lab/batch_assembly.py`는 최신 canonical ID, 고정 profile version/digest,
문항별 source hash/page/text를 조립한다. draft digest가 다른 검수는 거부한다. 이전 성공
패키지를 옛 수집 매핑으로 대체하지 않는다. 인접 문항 혼입·예시답안/채점기준 혼입·PUA
문자는 분리 사유로 기록한다. 오류는 해당 문항에 격리하고 다른 문항을 계속 조립한다.
14개 신규 private package+8개 기존 Essay package 입력PASS, 과거Math1은 신규검사로 세지 않는다.
의미검수35Provider호출(34응답/1결과불명), 기존 정답·근거를 line ID로 고정한 독립검수
11문항 PASS를 재사용했다. 첫 시도의 line-selection 오류와 검수 메타데이터 오독은 폐기하고
명시적 line ID 입력으로 수정했다. 근거텍스트를 모델이 새로 만들어 공식자료로 쓰지 않았다.
건국2026모의Q1 도표2개는 원본PDF page1을 이미지로 포함하고 직접 시각 확인했다.
테스트15PASS, 격리PostgreSQL pre11/post14true, baseline drift 원자적 거부·중복적용차단·
대학별/전체 rollback·새 History보존 확인. PDF RLS는 authenticated 정확한3개만 조회되고
범위 밖 fixture가 차단됨을 확인했다. Production writes0, 신규Credit차감0.

### Owner 적용 대기 — normal-batch-01

건국2026모의Q1/Q2+2025수시Q2, 성균관2026언어형2교시Q1,
숭실2024수시Q1+2026수시Q1+2027모의Q1: **3대학/6시험/7문항**.
기존28체계와 문항별 공식자료 재사용. 기존 성공 binding 및 숭실 대표 private 품질검수를
재사용했으며 신규7문항 개별 운영E2E로 보고하지 않는다.

실행폴더: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/normal-batch-01/`.
`OWNER-README.md` → `precheck.sql`(11true) → `apply.private.sql` → `postcheck.sql`(14true).
`rollback.sql` 및 대학별 rollback3개는 신규6시험 요청만 차단하고 저장된 결과/패키지/PDF
조회는 보존한다. 입력 본문은 private; Git에는 manifest/hash만 보관한다.
운영 READ-ONLY 사전11true. Production 적용은 AGENTS§4/Owner가 수행하며 응답 대기.
기존 SWUrevision3/고려/성균1교시 SQL은 재실행·롤백하지 않는다.

Worker **d1036134-ddc4-4658-b138-2cf0c627ff5e** 100% 배포 및 실제 설정대조PASS.
기존82시험/7binding을 보존하고87시험/8binding, Worker일반scope3→9를 준비했다.
원래 entry와 인증계약·Secret을 유지한다. 기존 WEB **ff327e92 / ca6022b** 그대로이며
Pages 일반scope는3개 유지. Owner SQL후 해당 plain-text scope만 추가하고 기존 코드로
배포·일반계정 확인 필요. 새 정책 미적용이므로 신규 문항은 아직 활성화되지 않았다.

### 공통 장애와 잔여 작업

- SWUQ2 일반계정 109Credit·ready상태에서 기존823자 답안을 입력했으나 `PENDING_CHANGED`로
  서버 전송 전 차단. WEB requestStorage가 owner/exam/initial 단위라 기존 완료Q1 키와
  다른Q2 fingerprint가 충돌한다. Source `essay-exam-submit.tsx`54–57에서 확인. 신규 Provider/
  DB제출/차감0. 기존Q1/재첨삭 결과는 보존. UI 수정금지에 따라 코드변경하지 않았다.
  수정후보: canonical 문항집합으로 pending key 분리 + 기존 불명요청 보존/이관 + 완료
  요청 상태조회 후 정리. 단순 localStorage 삭제나 새키 재제출로 검증을 우회하지 않는다.
- 초기 준비중 비동기 상태를 Worker장애로 오인해 임시 진단 버전을 배포했다. 실제 원인
  확인 후 원래3922d417 버전을 복원했고 진단 entry 변경은 제거했다. 이후 위 정상 묶음
  Worker만 배포했다. 기존 WEB 변경0, 실패 유료요청0. 불필요한 임시배포를 성공수로 세지 않는다.
- 미검수 근거 split, 수식/도표 visual grounding, 기존 Math 경로에 맞춘 physical input,
  profile미상속89를 묶음 처리해야 한다. PHYSICAL_MATH_OR_SPECIAL_BINDING_REQUIRED 같은
  집계는 중복사유이며 실제 수리문항수와 같지 않다. 유료 DIAGNOSTIC은 계약 확인 전 공개하지 않는다.
- 일반공개 42시험 allowlist 상한은 최종157시험 확대 전 공통 계약 검토가 필요하다.
- 이번 신규 WEB/APP 운영E2E PASS0. 기존6대학8문항 운영근거를 보존; SWUQ1 최초1/재첨삭0,
  WEB/GalaxyS8 근거·성장4→5·History는 이전 성공을 재사용한다. Q2/신규묶음 교차조회 미완료.

이번 private Provider35호출: 알려진 사용량 기준 **USD6.717716 추정**, 결과불명1건 비용미확정.
전체 private ledger199호출/197응답/2결과불명, **USD20.490748 추정**. 운영Q1의 기존4호출
receipt 비용NULL은 별도이며0으로 계산하지 않는다. 청구서 실비미검증, 전체 서비스 미완료.

## 2026-10-24 — normal-batch-01 적용 및 숭실 대표 운영 검증

Owner가 건국·성균·숭실 6시험7문항 SQL 적용 후 사후14true를 전달했고, Agent의 READ-ONLY 독립 검사도14true. 기존 ID/다른 정책/조회함수/원문/기록 보존. Agent Production SQL 쓰기0. 이미 적용된 이 묶음과 SWUrevision3은 재실행하지 않는다.

Pages 일반 시험 scope만3→9로 확대했으며 다른 설정 비교 일치, Secret 값 전송0. 기존5+신규7=정책상 일반공개12문항. 신규7문항의 일반계정 첨삭 버튼 활성 확인. 6시험 PDF 열람 확인(건국모의 Q2는 Q1과 동일 PDF 매핑, 별도 개별 클릭 검증 아님). 성균2026언어형2교시Q1 카탈로그 승인 상태를 실제 Owner 승인/DB 적용에 맞춰 WEB·Native에 연결했다. 기존486매핑 보존, 현재487매핑/155asset. 새 UI/결제/Credit/MY 변경 없음.

숭실2026수시Q1 실제 일반계정 최초 run `244aed57-d1d2-4095-9c90-18f9fffa07da` completed/1Credit settled, 재첨삭 `03b6e579-dee5-477c-9add-6f932c7ae367` completed/0Credit settled. 중간 실패 `ec9879cb-01b9-4794-a792-20b741d373f4`는0Credit released. 잔액109→108→108. 첫 부분답안2/5, 재작성5/5; WEB 근거와 성장2→5, History 복귀 시 새로고침 없이 신규기록 표시 및 과거 성균/서울여 기록 확인. Galaxy S8 build2026102401 덮어설치 성공. Owner가 숭실 최초·재첨삭 History/성장/평가근거와 성균2교시 PDF 모두 PASS 보고(실기기 조작·시각 확인은 Owner, DB/WEB 독립 확인은 Agent).

실패 원인은 독립검수가 frozen prior feedback를 이전 답안 원문과 혼동한 것. 이전 과제 해소 비교는 기록된 진단과 현재 답안으로 검증하고, 미제공 과거 문구의 직접 비교/인용은 계속 거부하도록 입력 계약을 명확히 했다. 자동PASS 우회 없음. 최초평가 입력 불변, uncertain 차단 회귀검사 포함 semantic/runtime17PASS. 수정 후 실제 독립검수8항목PASS. 기존 Worker 인증·권한·binding·정책 유지. Worker `c3fb54be-2f98-40cb-8a1a-2caae786003b`100% 및 예상변수 일치 확인.

WEB 소스 `87abdd6a0122617c49d0c58a5b2ee4cee5a7c1ba`, 최종 Production `40c5085a-107b-4b27-8a4a-70a3eab740db`. 중간 배포23ed95bf는 공개 인증 빌드설정 누락으로 로그인/목록이 준비상태에 머물렀다. 기존 Production의 plain-text NEXT_PUBLIC 설정6개를 그대로 사용해 다시 빌드/배포하여 복구. Secret 설정 변경 없음. 최종 일반계정108Credit/시험목록/성균PDF7페이지/숭실2024PDF7페이지 실제 확인. 기존 정상 배포는 보존된 복구 후보이며 현재 배포와 혼동하지 않는다. WEB8검사·Native3검사·WEB/APK빌드PASS.

이번 운영 Provider receipt6개(평가3+독립검수3), 입력58,587/출력10,493tokens. receipt 비용6개 모두NULL: 비용미확정이며0으로 계산하지 않는다. private 재검수 준비는 전송 전 종료되어 추가호출0. 기존 private 누적199회/197응답/2불명·USD20.490748 추정은 별도 유지; 운영6회를 private 합계에 혼합하지 않는다.

잔여: 숭실 재첨삭 제출 화면은 완료 전 대기 안내로 종료됐지만 History 복귀에서는 완료 결과가 표시됨(제출화면 자동완료 미PASS). SWUQ2 PENDING_CHANGED 해결은 UI수정금지 경계로 남음. 신규7개 개별 E2E를 주장하지 않으며 숭실 대표1문항 WEB/APP 학습주기만 신규PASS. 전수512 중 FULL23/DIAGNOSTIC0/NEEDS_REVIEW489 중간분류·프로필423/미상속89는 그대로이며 전체 서비스 완료 아님. 나머지 근거 분리·Math 입력·미상속 묶음 연결을 계속해야 한다.
