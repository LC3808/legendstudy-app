# 논술 LAB 1-A — 시험 회차 전체 연결 / 2026-10-25

상태: 성균2026 언어2교시 전체3문항 최초·무료 재첨삭 운영 완료(관리자 계정). 일반계정에서 2교시 세 문항·PDF·1Credit 견적 확인. 일반계정 실제 Provider 제출은 반복하지 않음. APP 작업 중단 유지. 최신 승인된 인문3회차·중앙10회차 연결 상태는 문서 말미 참조. 이전 승인대기 기록은 당시 이력이다.

## Owner 범위와 복구 확인

Owner가 중앙·성균관·경희3대학을 명시 지정했다. 과거 건국 우선/11대학 동시 처리 계획은 이번 범위에 적용하지 않는다. 2022이후 준비된 시험(2027모의 포함)의 인문·언어·수리·혼합형 전체 문항을 연결한다. 일부문항 공개를 시험전체공개로 세지 않는다. 최초 회차1Credit/기존 무료재첨삭0, 부분제출·추가미제출문항·기간·회차 계약을 보존한다.

기존 [출시 기록](app-release-20261025.md)과 출시채팅의 최종결과 확인: MY Native 복원본 Android/iPhone12 Pro Max 재설치·실행 완료. APP8fb30a23의 MY는 c3e93d9와 비교하여 관리자메뉴제거만 남고 기존화면구성 복원. 기존 Analyze No issues/1123PASS·7skip 로그 확인. 전체APP회귀무결점이나 첨삭결과UI정상판정은 아니다. 새롤백·재빌드·스토어제출 없이 복구완료 상태를 재사용한다.

**APP 첨삭 결과 UI/UX 미완료:** Owner 문제보고, 업데이트회귀인지기존문제인지미확정. 3대학 연결후 일괄개선하며 지금수정하지않는다. Flutter Native 유지,모바일터치·스크롤·Safe Area·기존정상UI 기준으로 결과/근거/재작성/재첨삭/성장 정보구조 정리,중복문구·과다노출 제거. WEB복제금지. 동일데이터·기존Credit/History계약보존. APP UI개발·빌드·스토어업데이트 중단.

WEB운영기준은 최신출시Wiki e9f1d4a/e6af7b54,Worker17b3bd65이다. 과거10/24버전으로되돌리지않는다. 이 문단은 적용 전 기준이다. 후속 WEB/Worker 배포와 Provider 호출은 아래에 구분한다. 아래 후속 적용에서 Production 2시험 패키지·승인·정책 pin 및 좁은 과거조회 호환 변경을 실행했다.

## 적용 전 회차 기준 전수 대조

READ-ONLY Production stlhijzpjfgwwdgunlsd 2022이후 집계. 시험0문항은 자료준비완료로세지않고 별도보류.

|대학|등록시험|문항있는시험|등록문항|전체문항 실행승인시험|기존 부분승인문항|전체시험 공개완료|
|---|---:|---:|---:|---:|---:|---:|
|chungang|22|22|69|0|0|0|
|kyunghee|17|9|35|0|0|0|
|sungkyunkwan|15|9|27|0|2|0|

합계54시험131문항, 문항있는40시험/빈14시험. 54개전체가자료준비완료라는뜻아님. 전체연결/공개완료0,준비상태미확정/보류54. 성균2026언어1·2교시 각각3개중1개만승인되어기존2문항성공은보존하되전체시험완료로계산하지않는다. 기존성균Q1 WEB/APP성공은재사용하며신규WEB운영첨삭검증은아직없음.

성균7·경희8시험의 private review에기존문서/근거매핑있음(시험자료링크107개/15시험). public essay_question_evidence가0이어도자료부재라고판정하지않는다. 기존private mappings가현재재사용경로다. 중앙22시험69문항은Registry에있지만현재review/runtime패키지와시험자료링크가없다. resources에서중앙명칭후보139개(2026문제/해설포함)를발견했으므로다시수집/업로드하지않고정확시험·유형·원문범위연결이필요하다. 같은source_post로자동확정되는경로는0개여서제목만으로공식근거를승인하지않는다.

## 재개 산출물 및 보류 원인

로컬 `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/group-1a-20261025/`:

- `runtime-inventory.json`:운영54시험/131정확문항ID·revision·승인범위 및private자료매핑요약.
- `whole-exam-plan.json`:전체문항집합대조·기존부분승인보존·회차별미연결원인.
- `exam-resources.json`:기존107시험자료링크와원본주소.
- `chungang-resource-candidates.json`, `chungang-exam-metadata.json`, `chungang-source-reuse-candidates.json`:중앙기존자료/시험메타데이터;후보일뿐검증완료아님.

`tool/essay_lab/exam_group_inventory.py`는기존문항별조립결과를회차로집계한다. 정확ID집합불일치/다른시험승인차단,부분승인및과거입력PASS를현재전체공개로승격하지않음. 회귀3PASS. 새평가엔진아님.

A공통장애는이번조회에서발견안됨. B/C보류:문항없는시험14,중앙자료실행경로미연결22,성균/경희기존근거정확범위·프로필·입력전수검증미완료,수리physical binding과교차엔진혼합회차미검증. Math MIXED 사진/텍스트가인문+수리교차엔진회차를뜻하지않는다. 기존Math회차API를재사용하고이중예약으로혼합형을우회하지않는다.

## 다음 실행 순서

1. 성균/경희기존private mappings와PDF/프로필을시험의전체문항ID에대조·조립. 중앙139자료후보는기존문제/해설을정확시험으로묶는다.
2. 정상회차의전체입력검증과기존유형대표계약재사용. 오류문항은명세화하며전체집합이불완전한시험은전체공개하지않음;다른정상시험계속.
3. 검증된시험만precheck/apply/postcheck/rollback 묶음작성. 성균2회차 SQL은 아래 기록대로 적용 완료. 이번 범위는 Owner 추가승인에 따라 Codex 직접 실행.
4. 적용후정확전체문항범위·회차1/0Credit·WEB일반계정확인. 기존성공Provider반복금지. 대학별대상/전체연결/실제공개/보류시험수와WEB결과보고.

보존검토7항목: 기존발생/기록시각유지,ID·source/version pin재현,기존답안/History UPDATE·삭제없음,동일auth owner,학습/금융/입학결과분리,기존권한·보존·개인정보범위불변,초안집계와운영사실구분. 새storage/schema선택없음.

## 2026-10-25 후속 — Owner 직접 실행 승인 및 성균 2회차 DB 적용

Owner가 이번 작업에 한하여 “운영자 개입 없이 … SQL 쿼리 명령어 실행도” Codex가 수행하도록 명시 승인했다. 당시 이 지시가 기존 Owner 직접 SQL 원칙을 대체했다. 이후 Owner가 SQL 승인 원칙을 복원했으므로 현재의 포괄 실행 권한이 아니다. 추가 승인 대기 항목으로 남기지 않는다. APP UI/빌드/스토어 중단과 데이터 보존 조건은 유지한다.

성균2026 수시 언어1교시 `035e5d8d-e91f-5acd-a3a3-4d321bc9f067`, 언어2교시 `d420ef29-218a-57fd-8524-842a0e551714`: 각각 전체3문항, 합계6문항을 기존 Worker/프로필 v5에 연결했다. 기존 Q1 내용 동일; 신규 Q2/Q3에 공통 제시문, 문항별 출제의도·채점 포인트·등급, 원문 도표 이미지 연결. 예시답안과 채점기준 구간 분리. 2교시 Q2는 기존5–6쪽 매핑에서 누락된 자료4의7쪽까지 연결.

로컬 전체입력6PASS 및 실제 배포 Worker에서 내려받은 Registry/코드에 동일 패키지 바인딩6PASS. PostgreSQL17 격리 사전8/사후13PASS, 진행중요청 적용차단·재실행차단·복구멱등·신구패키지조회·기존기록보존 PASS. 첫4MB 요청은 API본문크기제한으로 SQL실행 전 거절. 검수한32단계 회색조 PNG와 SQL내 이미지 중복제거로 적용파일918,898bytes로 축소 후 재검증했다. 원본PDF 불변.

Production 사전8true → 원자적 적용 → 사후13true 확인. 두 review revision3; 기존 review metadata/rights 원본·ID·Q1·revision2 조회 보존. runtime_policy는 두 package_digest만 변경; 이를 기존 pin으로 정규화한 함수MD5 `92a1384688218c948216a3e50718a841`가 적용전과 일치하여 다른 실행정책 불변 확인. Credit/Ledger/History 테이블 쓰기없음; 기존 성균 완료4건 유지. SQL 적용 자체의 Provider/차감0. 후속 실제 요청은 아래 별도 기록. Reader는 기존서울여revision2 호환을 보존하고 위 두 시험의 정확히 승인된revision2만 추가 조회하도록 확장.

산출물은 기존 materials/group-1a-20261025/ 아래 `prepare-skku-exams.py`, `prepare-skku-sql.py`, `test-skku-sql.py`, `skku-whole-exams-validation.json`, `skku-sql-isolation-result.json`, `skku-production-postcheck.json`, `skku-whole-exams-sql/{precheck.sql,apply.private.sql,postcheck.sql,rollback.sql}`. 적용SQL 재실행 금지. 복구는 두 실행pin만 종전Q1으로 복귀하며 revision3·모든 결과·과거조회 호환은 보존한다.

**공개/E2E 판정 미완료:** WEB 데이터 Commit `3bf73923212adcf83b8eb8c856d203584d549c2c`, Production `b08beb10-18a3-4564-a304-477af690837f` 배포 성공. 기존 Q2/Q3 PDF4행의 검수상태만 공개가능으로 연결. PDF/catalog14PASS·Next build PASS. 기존 원본/ID/페이지/Secret 불변.

현재 Chrome은 admin 계정이다. 일반계정 E2E로 계산하지 않는다. 언어2교시3문항을 한 번 제출한 run `b2cbc55f-edc7-423d-bfdc-f5d039b215e5`: Q1은 평가·독립검수 PASS, Q3은 `INDEPENDENT_REVIEW_NOT_ACCEPTED`(근거 없는 ‘익명적 소비’ 추론 및 핵심 논증 누락 진단 부족), Q2는 생성 응답 이후 검수시작 checkpoint pending. 내부 q0/q1/q2 순서는 UUID 정렬이므로 실제 Q1/Q3/Q2이다. 잘못된 문항/답안 연결이 아님을 snapshot ID와 답안 첫부분으로 확인했다. 최초1Credit reserved, settled/released 없음. 무료재첨삭·회차완료·일반계정 검증은 아직 PASS 아님.

실제 Provider 영수증5개(생성3+독립검수2), 입력87,785/출력9,992tokens, 비용NULL로 미확정. 완료Q1과 모든 영수증을 보존하며 신규 유료 제출·무작정 재호출하지 않는다.

Cloudflare Analytics에서 첫 실행의 외부 subrequests가 정확히50, 뒤 재전달3회가 각10회임을 확인했다. 검수시작 begin은 저장됐고 write는 미저장 상태다. 외부요청 한도 도달이 유력하며 원본 예외 로그는 보존되지 않아 단정하지 않는다. [Cloudflare 한도](https://developers.cloudflare.com/workers/platform/limits/)에 맞춰 한 큐 delivery에서 새 문항1개만 실행하고 durable checkpoint 이후 동일 identity message를 먼저 enqueue한 다음 ACK하도록 수정했다. 정상/실패/중복재전달·enqueue실패 13tests PASS. 기존 평가엔진·검수·권한·Credit finalization 불변.

Worker `e6ffbdb4-5024-4420-b335-d3c146022564` 100% 배포, deployment `d6d1b852-076e-4166-a721-9eca0a99c723`. 실제 운영70 source modules 중 entry/async_exam/cloudflare_runtime3개만 변경. 기존 모든 bindings를 strict inherit한 후 원본과 정확비교 PASS; runtime settings 동일. Secret 원문 재전송/변경 없음. 새 배포가 이미 pending인 작업을 자동 재호출하거나 성공으로 바꾸지는 않는다.

**우선 복구할 공통 GAP:** 위 run의 Q2 pending/검수시작 pending을 임의삭제·writer탈취·성공처리하지 않는다. 기존 문서에도 DLQ/불명확 pending의 자동 복구는 미완료였다. lease와 중단시점 증거를 기준으로 감사 가능한 실패확정/기존 run 재처리 절차를 보완해야 한다. 회차 예약1Credit을 새 예약으로 우회하지 않는다. Q3 실패는 개별품질명세로 분리하고 대표답안 무한반복 금지. 이 문제가 해결되기 전 새 회차 Provider 제출은 보류한다. 자료 연결 작업과 전체시험 검증은 별도로 이어갈 수 있다.

회차 수: 중앙22대상/0전체연결/0공개검증/22보류, 경희17/0/0/17, 성균15/2/0/15. 성균 두 회차는 DB전체연결·WEB PDF연결 완료지만 실제 일반계정 전체E2E 미완료이므로 공개완료로 세지 않는다. 나머지52회차는 기존 명세 재사용.

복구: Worker는 이전 `17b3bd65-8d90-4e8e-8ff6-a696e9575588`로만 복귀 가능(이번 한도 회피가 사라짐). WEB 이전 `e6af7b54-5199-4af9-94f1-1ee8fd909420` 보존. DB narrow rollback은 두 package pin만 복원하며 현재/과거결과를 삭제하지 않는다. 적용SQL 재실행 금지.


## 2026-10-25 최신 — 승인된 중단 요청 복구·무료 재첨삭 완료

Owner가 “SQL은 오너 승인 하에 진행”으로 원칙을 복원한 후, `essay_run_recovery_20261025` 복구 SQL 및 기존 요청 재개를 명시 승인했다. 승인 범위만 실행했다. rollback 예약 해제는 승인·실행하지 않았다.

- 기존 run `b2cbc55f-edc7-423d-bfdc-f5d039b215e5`: 사전8true → 적용 → dispatch 전 사후6true. 원본 checkpoint·snapshot·성공Q1 불변, Q3/Q2만 generation1로 재처리. 같은 identity 큐 메시지1회 전달. 10:58:44 UTC completed, 전체3문항 저장. 원래 예약1건을 consume1건으로 확정, 추가 예약·차감0.
- 무료 재첨삭 `0e9714ed-c2b3-4919-8bff-6582e499864b`: 실제 WEB에서 동일3문항 수정 제출, completed/settled, credits_required0, 관련 Ledger 행0. 최초·재첨삭 각각3문항·독립검수 완료.
- WEB 새로고침 없이 결과와 두 History 완료 기록 확인, 잔액94 유지. Q3 기준3→5/4→5 및 근거 표시. 공식답안 기반 테스트 fixture 결과이며 실제 학생의 성장 실증은 아니다.
- **남은 WEB 표시 오류:** 재첨삭 결과가 나타난 뒤에도 상단에 “평가 완료를 아직 확인하지 못했어요” 경고와 편집폼이 남음. DB 완료/정산 문제와 구분하며 UI 재설계는 하지 않았다.
- Owner 일반계정 로그인 후 크레딧11·관리자 메뉴 없음 확인. 계열 옵션의 접근성 disabled 표시는 실제 상태와 달랐으며 정상 선택됨. 초기 “서비스 준비 중”은 승인 응답 후 “첨삭 요청 · 1 크레딧”으로 전환. 2교시 전체3문항 선택·입력, 실제 서버 1Credit 확인창, Q3 PDF7/7페이지 표시 확인. 추가 제출하지 않고 취소, 잔액11 유지. 일반 접근/견적 PASS와 관리자 실제 Provider E2E를 구분한다.
- 대학 목록 최초 준비중 표시는 로딩 상태로 관찰됐고 최종 목록 상태는 별도 미확인. 운영공개 차단 장애로 확정하지 않는다. Pages/Worker 공개 목록은 두 성균시험 포함, 설정변경 없음.

검증: 큐분할/재개13 tests PASS, 실제 기존 Ledger SQL 격리18 checks PASS. 복구 SQL 격리검증은 중복·진행중실행 차단, 원본보존, 추가예약0, 기존finish를 통한 fallback 해제멱등까지 PASS. 운영에서 queue 분할→전체완료와 무료재첨삭을 확인했다. 임의 pending 삭제나 성공값 조작 없음.

Provider 영수증: 최초 run 총9회(중단 전5+이번복구4),171,913입력/19,112출력tokens. 무료재첨삭6회,111,842/10,468tokens. 이번 추가10회=195,970입력/19,588출력tokens. 총15회 중 비용값 확인0건으로 비용 미확정(NULL); 0원으로 보고하지 않는다.

### 중앙·경희 일괄 연결 산출물

기존 materials/group-1a-20261025에 `central-kyunghee-whole-exam-joins.json`, `central-kyunghee-whole-exam-drafts.private.json` 생성. 재생성 도구 `tool/essay_lab/group_1a_source_join.py`. 운영 DB쓰기/Provider호출 없이 기존 정확ID집합을 재사용했다.

- 중앙22시험69문항: 정확 학년도·유형의 문제/해설44개를 기존 resource ID로 짝지음. 기존 게시물의 갱신된 서명URL을 메모리에서만 사용해 PDF44/44·428페이지 추출. 업로드/새 Registry 생성 없음. `central-source-content-index.private.json`, `central-source-cache/`. 모든22해설에서 출제의도/채점기준 표제 확인.
- `central-whole-exam-source-locators.json`: 양쪽 PDF의 명시적 문항 표제를 연결한17시험56문항. **위치 확인이며 평가입력 PASS 아님.** 보류5시험은2024/25/26모의자연,2027모의경영경제일반/창의의 문항번호·하위문항 구조 확인 필요. 기존28프로필 라이브러리에 중앙 전용프로필 없음; 다른 대학 프로필로 대체하지 않는다.
- 경희17시험35문항: 비어있지 않은9시험 전체35문항 초안 재조립, 기존프로필29연결/6미연결. 과거 입력PASS1은 현행 의미검수 PASS 아님. 주요 공통 오류: 제시문범위34,수리binding31,의도29,문제23,기준19,예시답안혼입12. 빈시험8 별도보류.
- 경희2026 인문체육 원본18페이지 재추출(`khu-2026-humanities-pages.private.json`). 기존 매핑의 페이지밀림/예시답안혼입 확인. Q1 의도7–8,기준9–10(예시답안 시작 전);Q2 의도14–15,기준16–17(예시답안 시작 전). 원본 문항·제시문범위 조립 및 전체입력 검증을 다음에 이어간다.

|대학|대상시험|DB 전체문항 연결|실제 회차 E2E|일반공개 확인|공개완료 전 보류|
|---|---:|---:|---:|---:|---:|
|중앙|22|0|0|0|22|
|성균|15|2|1(관리자,최초+무료)|1(2교시 접근·PDF·견적)|14|
|경희|17|0|0|0|17|

운영 WEB b08beb10/3bf7392와 Worker e6ffbdb4 유지. 이번 복구 중 새 WEB/Worker배포,APP빌드,Secret수정 없음. 적용한 복구 SQL 재실행 금지. 다음 순서: 일반계정 실평가를 중복하지 않고 1교시 공개 접근 확인 → 경희 전체시험 근거범위 정리/중앙 기존자료 연결 → 검증된 시험만 승인용 묶음 SQL 준비. 새로운 Production SQL은 별도 Owner 승인 필요.

## 2026-10-25 최신 — Manus 구조 대조·인문 회차 확대 후보

Owner 제공 Manus 자료는 **시험 구조 보조자료**다. 실제 평가 근거는 각 시험의 기존 공식 문제·출제의도·채점기준으로 제한한다. 2027 안내/모의를 2024–26 실제 기출에 소급하지 않는다. 27/33대학 전체 연결로 범위를 넓히지 않는다. [기존 1-A 결정](decisions.md#2026-10-25--owner-복귀-sql-개별-승인-복원)과 회차1/무료0Credit·APP중단 원칙을 유지한다.

### 조사와 Registry의 분모

Production READ-ONLY 재조회: 1-A 54시험131문항 유지. 조사 ZIP2의 실제기출 35행을 **38회차**로 펼쳤다(성균 언어형 한 행에 1·2교시). 2027안내는 별도 보존. 첨부 XLSX2개·보고서2개·ZIP2개의 SHA256은 `supabase/reviews/essay-group-1a/manus-attachment-sha256.json`, 재현 도구는 `tool/essay_lab/manus_structure_compare.py`다. 원본을 덮어쓰지 않았다.

|대학|Manus 실제 조사 회차(2024–26)|Registry 시험(2022+)|동일 시험 식별|문항 수 일치만 확인|구조 불일치·미확인|시험 부재 후보|문항 0인 기존 시험|
|---|---:|---:|---:|---:|---:|---:|---:|
|중앙|12|22|6|6|6|6|0|
|성균|14|15|10|3|11|4|4|
|경희|12|17|8|1|11|4|4|

‘문항 수 일치’는 공식 근거·입력·공개 완료 판정이 아니다. 구조 불일치·미확인은 시험 부재/빈 문항/소문항 또는 선택과목 표현 차이를 포함한다. 실제 오류 확정과 구분한다. 조사에 없는 2022–23/모의 Registry 시험을 잘못된 시험으로 분류하지 않는다. 자세한 기존ID/조사회차/실패분류는 `supabase/reviews/essay-group-1a/manus-structure-comparison-20261025.json`.

### 공식 자료와 대조해 좁힌 수정 범위

- 중앙2024/25/26 수시 자연1·2교시 6시험은 Registry에는 없지만 **기존 resources에 정확한 문제/해설12개**가 있다. 재수집·재업로드·새ID생성 없이 resource ID 쌍을 정리했다. `manus-structure/central-missing-exam-resource-joins.json`. 각4대문항·7답안단위라는 조사 결과는 PDF 전체 검증 후 등록 후보로 승격한다. 기존 모의 자연시험을 수시로 바꾸지 않는다.
- 성균2026수리1: 공식 문제 PDF2–4페이지에서 3대문항·9소문항(각ⅰ/ⅱ/ⅲ) 확인. Registry3개는 부모 문항이다. 6문항 누락으로 단정하거나 기존ID를9개로 교체하지 않는다. 각 부모 안의 답안단위·공식근거 연결을 보완한다.
- 경희2026자연: 공식 문제1–2페이지에서 3대논제·6답안단위 확인. 경희2026사회: 공식12–13페이지의 논제Ⅲ(1)/(2)(a)/(2)(b) 확인. 장문Ⅰ/Ⅱ와 합쳐5답안단위다. 수식 추출의 private-use glyph는 텍스트로 추측하지 않고 원본 이미지 경로로 처리해야 한다.
- 경희 의약학: Registry8개는 수학·물리·화학·생명과학의 부모 논제 목록이다. 조사4대문항/8답안이라는 응시 조합과 숫자만 비교해 누락/중복 확정 금지. 선택과목별 조합과 답안단위·근거 연결을 확인하기 전 공개 보류.
- 2027 경희 사회형2논제 안내, 중앙 일반/창의형 및 자연/의약학 변경은 `guidance_2027`로 별도 유지. 실제 모의 PDF와 확정 요강도 서로 대체하지 않는다. 과거 시험 변경0.

### 정상 인문 시험 후보와 SQL 승인 대기

경희2026수시 인문체육2문항, 경희2027모의 인문체육2문항, 성균2027모의 언어3문항: **3시험 전체7문항**을 공식 자료로 조립하고 기존 입력 계약 PASS. 경희v7프로필 재사용, 성균v5는 보존하고 해당2027공식 공통기준에 근거한v6후보로 조립했다. 성균 자료4·5페이지 그림과 공식 배점의 가변 적용 안내도 포함했다. 조사 문구를 채점기준으로 사용하지 않는다.

중앙 인문10시험30문항은 기존 공식 자료만으로 구조적 입력 PASS 초안. 중앙2026인문은 전체제시문3–8페이지, 발문8페이지, 문항별 출제의도1페이지로 범위를 좁혔다. **전체 의미검수/일반 PDF 전달 연결/운영승인 미완료**, 다른 대학 프로필로 대체하지 않았으며 공개 수에 포함하지 않는다. 기존 중앙 문제 PDF의 hash 객체는 현재 essay-material-originals에 없어 기존 resource 전달 경로를 연결해야 한다.

로컬 기준 경로: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/group-1a-20261025/`.

- `manus-structure/`: 원본 해시, 3대학 조사 추출, XLSX 행/셀 위치, 최신 Registry, 대조표, 공식 수리/혼합 구조 확인.
- `text-expansion/`: 3시험7문항 packages/registry, 성균v6후보, 중앙10시험 초안/검증, 재생성 스크립트.
- `text-expansion/worker-registry.private.json`: 기존 운영87시험을 그대로 두고 신규3시험을 추가한90시험 후보. 원본87시험 내용 불변. Production 배포 아님.
- `text-expansion/owner-sql/OWNER-README.md`: 프로젝트 stlhijzpjfgwwdgunlsd, 사전검사→적용→사후검증→복구. 기존검수3건 revision1→2, 실행case3개, 성균2027문제PDF한 개에 좁은 로그인SELECT만 추가. 중앙대/Math/Credit/History/인증 함수 변경 없음.

검증: 격리PostgreSQL17 사전10/사후12 PASS, 진행중·중복적용 차단, 다른 정책·기록보존, 롤백멱등 및 조회보존 PASS. 운영 사전10개 모두true(READ-ONLY). PostgreSQL digest로 기존 운영 소스의 입력 검사3시험7문항 PASS. **Owner 승인 미수신·Production 적용0·신규 공개0**. SQL적용만으로 공개완료 처리하지 않는다. 이후 Worker Registry·Pages/Worker 공개목록·WEB성균PDF메타데이터 연결과 일반계정 실제 열람/제출 경로 확인이 남았다.

### 보존과 다음 실행

보존7항목: (1) 조사회차/조사일과 운영확인시점 분리, (2) 첨부SHA256·공식자료hash·기존ID로 재현, (3) 학생답안/평가/History/원장 UPDATE·삭제없음, (4) auth identity 불변, (5) 자료구조 메타데이터와 학습/금융 사실 분리, (6) 신규 개인정보수집·권한 확대없음(승인대기SQL의 문제PDF SELECT만 명시), (7) 문항 수 일치·초안PASS·일반공개를 별도 상태로 보존.

현재 공개 성과는 이전과 동일: 중앙0/22, 성균 일반접근 검증1/15(2교시), 경희0/17. 성균 DB전체연결2시험·6문항과 회차실평가1시험을 구분한다. 기존최초1/무료0Credit·History·성장비교 결과 재사용. 이 후속작업 Provider0회/추가비용0, 과거 비용NULL은 미확정 유지. 운영WEB b08beb10/Worker e6ffbdb4 보존, 새배포·Secret변경·APP빌드0.

다음: 승인된3시험SQL만 적용→기존소스/설정보존 배포→일반계정공개검증. 중앙 인문 전체 의미/전달 연결과 누락자연6회차의 기존자료 조립은 병행 가능한 독립작업. 수리/혼합형은 부모ID보존·답안단위별근거·단일회차1Credit 계약을 먼저 연결하며 두 평가엔진에 각각Credit을 예약하지 않는다.


## 2026-10-25 최신 — 승인 묶음 적용·회차 서비스 확대

Owner 긴급 지시로 문항별 가상답안/Provider 품질 반복을 중단했다. 시험 전체 ID·공식자료·입력·PDF·기존 정산/History 연결만 확인한다. 과거 중앙 “전체 의미검수 대기”는 공개 선행조건에서 제거했다. 공식자료 오연결·권한·정산 무결성은 계속 차단한다.

### 경희2·성균1 회차 적용 및 실제 공개

Owner 승인 후 text-expansion/owner-sql 사전10→적용→사후12 모두true. 기존14runtime 정책 독립비교 보존. Worker c9470a54/WEB1455ed8b 배포, 기존69개 실행모듈·bindings·Secret 보존. 일반계정(잔액11)에서 경희2026수시 인문체육2문항·경희2027모의 인문체육2문항·성균2027모의 언어3문항 모두 선택/입력란/PDF실제렌더/1Credit 요청경로 표시 확인. 답안 생성·제출 없음. 기존 성균2026언어1교시도3문항/PDF6쪽/1Credit 경로 확인하여 성균의 전체 공개3회차를 확인했다. 기존2교시 성공 E2E 재실행 없음.

### 중앙 인문10회차 승인 및 DB/배포 연결

Owner “중앙대 10회차 묶음 SQL 실행 승인” 후 central-owner-sql 사전11true→적용→사후8true. 2022모의,2023수시/모의,2024수시/모의,2025수시/모의,2026수시,2027모의 일반/창의 인문사회: 전체30문항. 기존 시험/문항/resource ID를 보존했다. 기존 공식PDF20개를 원본 hash로 private Storage에 저장 후 다운로드 SHA25620/20일치. 기존 객체 덮어쓰기0, 공개문제10개만 exact SELECT, 해설10개 비공개. 문서20연결/review10/revision10/runtime case10추가. reader·제출/정산/auth/History/Ledger 함수 변경0. 자료 추출 NUL구분자는 공백으로 정규화, 원본PDF불변.

격리PostgreSQL 사전11/사후8, 입력30PASS, 기존정책/완료기록보존·중복/진행중적용차단·롤백멱등·과거package조회 PASS. 실제 배포코드/Registry에도 전체입력30PASS. 기존 binding 그대로 사용했고 Provider호출0. 운영사후8true 및 provider_binding_valid10true.

Worker `4e90d13b-763b-47a3-8d04-0648fb76608d`(registry_asset.py만 변경, 기존80시험과69모듈보존). 공개목록에 중앙10개만추가. WEB `13008e1b-296b-4209-a0ac-5b804fa82756`, 코드 `6e740c2`, PDF manifest30행 추가/기존512행보존. 관련17tests/Next135경로buildPASS. Pages는 ESSAY_PUBLIC_EXAMS만 PATCH, 다른Secret/설정 원문 재전송 없음.

중앙 일반계정에서 10회차 모두 전체3문항 탭·답안 입력란·문제보기·서버 승인 후 1Credit 요청 경로를 확인했다. 답안이 비어 있어 버튼은 disabled이며 유료제출은 하지 않았다. 2025수시 PDF7쪽·2026수시 PDF10쪽·2027창의 PDF7쪽 실제렌더도 확인했다. 전수 원본20개 hash/정책검증과 실제 PDF 렌더 검증 범위는 구분한다.

공통 장애: 중앙2027 두회차 이용가능 조회가 준비중으로 남았으며 운영 tail에서 Python initPyInstance의 `Cannot enter a promising task` 오류 확인. [Cloudflare workerd #7814](https://github.com/cloudflare/workerd/issues/7814)에 같은 증상 보고가 있으나 우리환경의 CPU초과 원인은 미확정이다. 기존70모듈·bindings·runtime설정 전부 동일한 새 Worker `53d20942-24cd-4286-b18b-ff6e254a6e2f`로 런타임 재생성, deployment `90e1d89e-b190-415d-b33e-033dcdb8ec83`. WEB 목록의 admission 병렬3개를 순차조회로 변경하여 자체 동시초기화 부담을 줄였다. 회차 제출·평가·정산 경로는 변경0. 관련31tests PASS, WEB `6a9b716`, Production `497ea786-6dc8-42a9-aeeb-7db20a1d9fa0` 성공. 두2027회차 모두 일반계정 첨삭경로 정상전환 확인. 이는 증상 복구/부담 완화이며 Cloudflare 원천버그 해결 또는 다중사용자 부하검증 완료가 아니다. 재발 시 신규 유료요청을 늘리지 말고 tail의 초기화/CPU오류와 기존 요청 상태부터 확인한다.

|대학|대상시험|전체연결|일반WEB 공개경로 확인|보류/미완료|
|---|---:|---:|---:|---:|
|중앙|22|10|10|12|
|성균관|15|3|3|12|
|경희|17|2|2|15|

총15회차의 일반 사용자 접근·전체답안·첨삭 admission 확인. 실제 Provider 회차 E2E는 기존 성균언어2교시1회차 성공만 재사용하며 신규15회차 실평가PASS로 확대 해석하지 않는다. 나머지39회차 미완료, 대학전체완료 아님.

### APP 호환성 GAP 및 보존

현 Native코드는 /api/essay/exam availability/quote/submit, 전체/부분 텍스트답안·기존무료재첨삭·추가미제출회차 계약을 구현한다. 입력저장0, 최초1/무료0 계약은 기존 성공 회차 증거를 재사용한다. 이미지가 있는 답안은 Native회차submit에서 명시 차단되므로 수리/혼합 회차 호환 완료 아님. 고정 student_pdf_catalog에는 경희 신규2회차가 있으나 성균2027언어와 중앙10회차가 없다. 앱에서 동일PDF/새회차 전체사용가능이라고 보고하지 않는다. APP 코드/빌드/스토어변경0.

### 재개·복구

`text-expansion/central-owner-sql/`의 네SQL·README, central-storage-result/central-production-postcheck/central-sql-isolation-result/central-worker-version/central-web-deployment.json에 현재 증거 보존. 이미 적용한3+10회차 SQL재실행금지. DBrollback은 해당신규case·PDF정책만제거하고review/revision/결과/원본보존. 중앙확대 직전WEB1455ed8b/Workerc9470a54로복구가능하며 공개목록은 해당10개만제거. 학생요청을 새예약으로우회하지않는다.

남은 중앙12회차는 수리/혼합 답안단위·기존Math회차연결, 성균12/경희15는 빈Registry/자료정확연결/수리·혼합계약으로 구분해 이어간다. 대표Provider실행을 공개상한으로 삼지 않는다. 이번후속Provider0/추가평가비용0, 기존15영수증비용NULL은미확정유지.

## 2026-10-25 대학 카드 공개 상태 안정화

Owner가 새로고침마다 카드 활성/비활성 전환을 보고했다. 원인: 기존 `/api/essay/service-status`는 공개22시험마다 Worker admission을 호출하고, 브라우저는42대학 metadata를 다시 조회했다. 로딩/HTTP실패/checked=false/metadata실패가 모두 빈Set으로 합쳐져 준비중으로 표시됐다. focus중복요청의 순서보호도 없어 늦은 이전응답이 최신상태를 덮을 수 있었다.

운영근거(KST21:30–21:38): Worker집계 success82/clientDisconnected6/scriptThrewException4/exceededResources3. tail21:36:07,21:37:22,21:37:24 admission ErrnoError 확인. 이번 tail에서 `Cannot enter a promising task` 원문 재현은 없으며 이전 오류와 동일원인이라고 단정하지 않는다. Supabase해당12:30–12:45UTC창의 essay/math조회는 수집된범위 모두200; 429/5xx증거없음. Worker종료·시간초과/클라이언트취소·자원초과는 구분하며 HTTP429로 추정하지 않는다.

수정: 카드전용 `/api/essay/public-service-status`에서 기존 서버 ESSAY_PUBLIC_EXAMS와 Math공개정책을 기존공개metadata RPC로 대조하여 대학ID목록을 한 응답으로 반환한다. 클라이언트1요청, 서버Auth/기존Math조회+최대42대학메타데이터조회; DB일괄RPC를새로만든것은아님. PythonWorker/Provider/quote/submit/정산 호출0. 공개정책목록22개불변. 카드공개와 실제평가승인은 분리; 기존exam/Worker/DB권한·Credit검사는 제출시 그대로 수행한다. 기존관리자 runtime 집계endpoint 의미는 바꾸지 않았다.

상태4종: 확인중/첨삭시작/준비중/일시오류·다시시도. 잘못된응답/정책누락metadata/20초timeout/조회실패를준비중으로처리하지않는다. focus자동중복조회제거, 재시도·계정변경·unmount시 이전요청취소와active세대확인. 계정간응답역전/오류복구 테스트 포함41PASS, TypeScript/135경로buildPASS.

WEB commit b3a1c6dd7120459dd1e4f2a3dcb8bf0be16bce74, Production ad522cdf-1bbf-4961-827d-be1a1253b40f 성공확인. 일반계정 새로고침3회/타페이지왕복2회/목록2페이지왕복: 건국·경희·서울여·성균·숭실·중앙6대학 동일활성,1-A3대학보존. 로딩문구확인,잔액11유지. 오류UI는 자동테스트로검증했고 운영장애를인위적으로일으키지않음. 실제Provider0/차감0/SQL쓰기0/APP수정0/Worker배포0/Secret변경0.

보존검토7: 기존발생시각불변; ID/원본정책재현; 학습History UPDATE0; 같은Auth identity검증; 공개표시와학습/금융사실분리; 신규개인정보/권한확대0; 카드공개표시를실제평가성공으로해석금지. Worker자원/초기화문제는 별도잔여이며 카드안정화가평가엔진장애완치를뜻하지않는다. 재발시카드endpoint503은오류UI, 평가Worker장애는기존요청/예약보존하여별도복구. 이전WEB497ea786으로롤백가능하지만 카드문제도복귀하므로정상수정본유지권장.

## 2026-10-25 중앙대 인문사회 실서비스 — 실행 한도 장애 확인

Owner새지시: 중앙인문10회차실서비스→Owner화면확인→경영경제. APP코드수정/빌드/스토어와타대학확대중단. 직전APP카드미커밋변경은보존,실기기미설치. 10회차기존SQL/자료/프로필재생성금지.

READ-ONLY 중앙runs0: 현재복구할중단요청/예약없음. 기존Worker53d20942 자원/초기화오류조사. 12:30–13:00UTC집계 success82/예외15/clientDisconnected6/exceededResources3. CPU한도30초명시 version생성 요청이 HTTP400/100328 `CPU limits are not supported for the Free plan`으로거절되어현재Free플랜확정. 후보생성/운영배포변경없음. Free CPU10ms 제약이기존Python실행부하에부적합하며개별평가품질문제와구분. 모든예외의단일원인확정이나Paid전환만으로E2E완료판정은아님.

Owner에게해당계정Workers Paid전환요청. 비용발생계정작업임의실행안함. 전환후기존70소스/Secret/bindings보존하여30초CPU한도설정→기존정확10회차승인/실제제출경로확인→필요최소공식답안기반실평가→기존1/0Credit·History결과확인. 기존성공평가반복금지,새요청으로중단을우회하지않음. 운영WEB2cc8cd0a/Worker53d20942 유지. 아직중앙실서비스완료아님.

### Paid 전환 후 실행 한도 반영

Owner Workers Paid전환완료 후 API에서 cpu_ms30000 설정 허용 확인. 기존70모듈 변경0, 전체bindings/Secret 및호환설정 보존. Worker `3e31db73-b029-470b-8207-1a02ad7cdd91`, deployment `61af2cfb-a429-4350-83aa-7f0f964a15a8` 100%운영반영. WEB2cc8cd0a불변,DB/SQL/APP변경0. 이전Worker53d20942가복구기준.

일반계정 중앙2026수시 인문사회 전체3문항 기존공식예시답안 저장,회차1Credit확인창후 요청 `23b818bd-03c0-4226-9dbf-79f1447328c8` 접수. 초기예약확인,중복제출없음. 결과/정산최종확인은아직진행중.

### 중앙대 실제 회차 평가 완료 — Paid 반영 후

중앙2026수시 인문사회 `23b818bd-03c0-4226-9dbf-79f1447328c8` 전체3문항 completed, 13:08:02→13:10:55UTC. 최초공식예시답안 재사용, 가상답안생성/평가품질반복0. 일반계정WEB에서 저장·3문항제출·1Credit확인창·종합평가/평가기준/근거·History완료기록·다시써보기/무료재첨삭요청 진입 확인. reserve1→consume1,잔여예약0,가용11→10. 기존ID/정산/기록변경없음.

Provider영수증6(평가3+기존독립검수3), 입력51324/출력6510tokens. cost_amount는6건모두NULL이므로 실제비용미확정이며0으로보고하지않음. 무료재첨삭의신규Provider실행은없다. 기존성균회차무료0/성장비교 성공계약을재사용했고이번중앙은무료재작성자격/진입까지확인했다. 중앙재첨삭E2E신규PASS로표시하지않는다.

기존10회차/30문항 전체연결·PDFhash/접근증거재사용. 이번2026수시 및 이전장애2027일반/창의 모두일반계정Worker승인복구. 전체10회차실평가를반복하지않음. 신규실제평가성공은1회차/3문항. WEBProduction2cc8cd0a(code1c6339b)불변. APP빌드/스토어0. Worker error tail 관찰중추가오류출력없음(장기무장애보장은아님).

잔여표시문제: 평가결과는자동표시됐으나앞서노출된‘평가완료를아직확인하지못했어요’안내문구가함께남았다. History에는정상완료이며정산/결과저장실패아님. 별도최소표시수정대상으로기록,이번에UI/WEB재배포확대안함. Owner화면확인전경영경제작업금지.

복구: 기존Worker53d20942버전으로deployment전환가능하나이전실행한도장애재현가능. 정상3e31db73유지우선. SQL재실행·Secret변경·기존요청새예약우회금지. evidence: text-expansion/central-cpu-limit-candidate.json.

## 최신 Owner 정책 적용 — 중앙 인문 STANDBY

[전체 대학 공통 STANDBY 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책)이 과거 중앙 실제평가 완료 선행조건을 대체한다. 기존 연결/PDF/입력/승인 증거 및 Paid Worker 복구를 재사용하여 중앙 인문10회차·30문항을 WEB STANDBY / OWNER QA PENDING으로 관리한다. 실제평가성공1회차와 구분. 새Provider호출/가상답안/시험별 재검수/SQL재적용 없음. Owner 확인 전 경영경제 착수하지 않는다. 기존 완료 후 안내문구 잔존은 알려진 표시 오류로 보존한다. APP의 미배포 카드/PDF 수정과 실기기 호환성은 이 WEB 판정에 포함하지 않는다.

## Owner 지적 — 중앙2026모의 인문사회/경영경제 Registry 누락

운영 DB READ-ONLY 확인: 2026mock은 자연0723cb5a만 존재. 인문사회문제711f74c6/해설fc2c55e8, 경영경제문제99533452/해설dc1e6b23 resource는 모두 active로 이미 존재. 기존 로컬 공식PDF도 존재한다. 두 회차가초기Registry선정에서빠져 기존중앙22시험 및 인문10회차조립범위에도포함되지않았다. UI가숨긴것이아니며 기존10회차를중앙인문전체자료범위완료로표현하면안된다. 인문대상은최소11회차로정정(기존10 STANDBY+2026모의1미연결).

[공식 2026모의 공지](https://admission.cau.ac.kr/detail.do?board_seq=3249&menuurl=jcgylvDgJz1bdCxN45fl1g%3D%3D&pageNo=1)와 기존PDF의시험/문항단위만대조. 인문3·경영경제언어2/수리1. 평가품질검수/가상답안/Provider0.

[등록보완 후보](../supabase/candidates/cau_2026_mock_missing_tracks/OWNER-README.md): 사전4true,apply/postcheck/rollback준비,NOT_APPLIED. 기존ID생성계약재사용;신규미등록시험2/문항6만추가대상. 운영SQL은이번2회차의별도승인필요. 이후정확resource를패키지/PDF/Worker에연결해야STANDBY이며등록만으로완료아님. 경영경제Math계약/공개승인우회금지.

### 누락2회차 등록 적용 — Owner 승인 후

Owner ‘누락2회차 Registry 보완SQL 실행 승인’ 후 사전4true→apply성공→사후4true. 신규인문 c7e17f5e-9037-5a78-8e77-7878a98230ca / 경영경제53bdd6f5-78be-548f-ac1b-23081f9bf74c, 각3문항. 기존 자연/4resource/정책/ID/기록보존. 일반계정운영WEB에서2026모의3계열선택과신규두계열각3문항입력/저장버튼표시확인. PDF원문준비중/첨삭준비중은아직남아있으며후속실행연결대상. 이번승인은등록메타데이터범위이며추가공개정책변경승인아님. Provider/차감/WEB재배포0.


## 연속 연결 — 중앙경영경제·경희인문·사회

최신 Owner 지시: 중앙 경영경제 → 경희 인문·체육 → 경희 사회를 단계별 진행 승인 대기 없이 준비한다. 별도 범위 Production SQL/권한 변경은 승인 필요. 기존 STANDBY 정책을 재사용하며 Provider 호출·가상 답안·품질 반복검수·APP 빌드/수정은 하지 않는다.

| 범위 | 확인된 대상 | 현재 신규 STANDBY | 보존한 기존 공개 | 남은 연결 |
|---|---:|---:|---:|---|
| 중앙 경영경제 | Registry 10회차·30문항 | 0 | 0 | 언어2+Math1 단일 회차 제출/정산 연결 |
| 경희 인문·체육 | 보관 자료 11회차 | 0 | 2회차 | 신규9회차 PDF/공식자료/실행 승인 |
| 경희 사회 | 보관 자료 13회차 | 0 | 0 | 12회차 소답안 연결, 2027 모의2논제 공식자료/실행 승인 |

중앙10은 현재 Registry 기준이며 2022~2027 모든 보관 자료의 누락 없음까지 확정한 수치가 아니다. 경희24는 보관된 문제·해설36개 기준이며 2027 수시는 대상 자료에 없다. 2022/2023 사회 수시 오전·오후는 별도 회차다.

### 실제 반영

[Registry 묶음](../supabase/candidates/khu_continuous_registry/OWNER-README.md): Owner 「누락 Registry 묶음 SQL 실행 승인」 후 Production stlhijzpjfgwwdgunlsd에 신규16시험 및 기존무문항4시험의 총51문항 추가. 사전2true, 사후 exact_question_sets=true. 기존 문항 있는4회차 수정0. 승인된 메타데이터 추가만 적용했으며 실행 승인/Storage 정책/학생 답안/Credit/Ledger/History 쓰기0. 재실행 금지.

### 후속 연결 산출물

`tool/essay_lab/prepare_khu_registry_expansion.py`는 기존 exam/question/resource ID를 재사용하고 신규 ID만 기존 source-registration-v1 계약으로 생성한다. 2027 모의 사회 공식 문제·해설은2논제이므로 과거3부모/5응답 형식을 소급하지 않는다.

`tool/essay_lab/prepare_khu_text_connections.py`는 기존 material_runtime 입력 계약을 사용한다. 현재 신규5회차10문항의 공식문제/출제의도/채점기준 패키지 조립 완료, 미배포. 경희 인문 수시2022/2023/2024, 모의2026 및 사회 모의2027이다. 나머지 인문 모의2022~2025는 공통 프로필 범위 연결, 수시2025는 숫자목록형 기준 추출 연결이 남았다. 이를 평가 품질 실패로 분류하지 않는다. 기존 공개 인문2회차 패키지는 다시 조립하지 않는다.

기존자료 디렉터리 `legendstudy-materials/essay-validation-2026-10/group-1a-20261025/`의 `continuous-inventory.private.json`, `continuous-source-pages.private.json`, `continuous-storage.private.json`, `continuous-submission-contracts.private.json`, `continuous-text/`가 후속 입력이다. 신규 조립 패키지와 공개 상태를 혼동하지 않는다. 36개 원본 중30개는 해당 해시의 private Storage 객체가 없으며 기존 resource/local PDF가 존재한다. 중복 업로드 금지; 문제/해설 합본의 학생 노출 범위는 기존 정책대로 분리해야 한다.

### 중앙 혼합형 공통 계약 GAP

실제 Production `essay_exam_submit`은 questionId/body/revision 텍스트만 수용하고 단일 Essay reserve를 사용한다. `math_session_submit`은 소유권 확인된 Math attempt 목록을 받으며 별도 session/billing reserve를 생성한다. WEB ScopedExamSubmit은 Essay 또는 Math 한 경로만 선택한다. 따라서 양쪽 함수를 순차 호출해 혼합형을 연결하면 회차1Credit 계약을 보장할 수 없다. 임의 호출/버튼 강제 활성화는 하지 않았다. 기존 Math 이미지/OCR 확인 및 Essay 평가를 재사용하되 하나의 예약 소유자 아래 문항별 실행/완료를 연결하는 최소 계약 수정이 필요하다. 정산 변경 SQL은 별도 승인 대상. APP 이미지 회차 호환은 미완료이며 이번 작업 범위 밖이다.

보존 검토7항: 원본 답안/시각 유지, 과거 결과 불변, 기존 사용자/시험/문항 ID 유지, 공식자료와 파생 패키지 구분, 목적/권한 유지, 최소 메타데이터 추가만, 학습 결과 추정 생성 없음. 이번 적용은 학생 저장 구조를 바꾸지 않았다.

### 다음 실행 순서

1. 이미 적용한 Registry SQL을 반복하지 않는다.
2. 중앙 혼합 단일예약 연결을 기존 함수/Worker 경계에서 준비한다. 서로 독립인 두 유료 submit 호출 금지.
3. 경희 신규 회차 공식자료·문제 PDF·실행 승인 패키지를 묶어 준비한다. 이번 Registry 승인을 공개/Storage 권한 승인으로 확대하지 않는다.
4. 사회12회차는 기존 부모 ID 아래 공식 소답안 입력 단위를 연결한다. 2027 모의2논제는 기존 text 경로 재사용.
5. 승인된 연결을 운영 반영 후 일반계정 선택/PDF/입력/버튼만 확인한다. Owner가 실제 평가를 검수한다.

운영 WEB code1c6339b / deployment2cc8cd0a, Worker3e31db73(100%, CPU30000ms) 보존. 신규 WEB/Worker 배포0, Provider0, 추가비용0, APP빌드0. 기존 중앙2026수시 실평가1회차 성공은 재호출하지 않았다.
