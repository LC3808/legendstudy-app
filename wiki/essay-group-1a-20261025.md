# 논술 LAB 1-A — 시험 회차 전체 연결 / 2026-10-25

상태: APP 작업 중단 유지. 성균2026 언어1·2교시 전체6문항 DB 연결 완료(revision3). WEB 일반계정 공개·운영 E2E와 나머지 시험은 미완료.

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

Owner가 이번 작업에 한하여 “운영자 개입 없이 … SQL 쿼리 명령어 실행도” Codex가 수행하도록 명시 승인했다. 이 지시가 기존 Owner 직접 SQL 원칙을 이번 범위에서 대체한다. 추가 승인 대기 항목으로 남기지 않는다. APP UI/빌드/스토어 중단과 데이터 보존 조건은 유지한다.

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
