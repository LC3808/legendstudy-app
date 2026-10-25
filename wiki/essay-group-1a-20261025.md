# 논술 LAB 1-A — 시험 회차 전체 연결 / 2026-10-25

상태: APP MY 복원 완료 증거 확인·APP 작업 중단. 1-A 운영 Registry 대조와 회차별 연결 명세 작성 완료, 실제 시험 전체 연결·공개는 미완료.

## Owner 범위와 복구 확인

Owner가 중앙·성균관·경희3대학을 명시 지정했다. 과거 건국 우선/11대학 동시 처리 계획은 이번 범위에 적용하지 않는다. 2022이후 준비된 시험(2027모의 포함)의 인문·언어·수리·혼합형 전체 문항을 연결한다. 일부문항 공개를 시험전체공개로 세지 않는다. 최초 회차1Credit/기존 무료재첨삭0, 부분제출·추가미제출문항·기간·회차 계약을 보존한다.

기존 [출시 기록](app-release-20261025.md)과 출시채팅의 최종결과 확인: MY Native 복원본 Android/iPhone12 Pro Max 재설치·실행 완료. APP8fb30a23의 MY는 c3e93d9와 비교하여 관리자메뉴제거만 남고 기존화면구성 복원. 기존 Analyze No issues/1123PASS·7skip 로그 확인. 전체APP회귀무결점이나 첨삭결과UI정상판정은 아니다. 새롤백·재빌드·스토어제출 없이 복구완료 상태를 재사용한다.

**APP 첨삭 결과 UI/UX 미완료:** Owner 문제보고, 업데이트회귀인지기존문제인지미확정. 3대학 연결후 일괄개선하며 지금수정하지않는다. Flutter Native 유지,모바일터치·스크롤·Safe Area·기존정상UI 기준으로 결과/근거/재작성/재첨삭/성장 정보구조 정리,중복문구·과다노출 제거. WEB복제금지. 동일데이터·기존Credit/History계약보존. APP UI개발·빌드·스토어업데이트 중단.

WEB운영기준은 최신출시Wiki e9f1d4a/e6af7b54,Worker17b3bd65이다. 과거10/24버전으로되돌리지않는다. 이번작업WEB/Worker/결제/Secret변경0,Production쓰기0,Provider0.

## 회차 기준 전수 대조

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
3. 검증된시험만precheck/apply/postcheck/rollback 묶음작성. 현재안전하게적용요청할신규SQL패키지는아직없음. Production SQL Owner직접실행.
4. 적용후정확전체문항범위·회차1/0Credit·WEB일반계정확인. 기존성공Provider반복금지. 대학별대상/전체연결/실제공개/보류시험수와WEB결과보고.

보존검토7항목: 기존발생/기록시각유지,ID·source/version pin재현,기존답안/History UPDATE·삭제없음,동일auth owner,학습/금융/입학결과분리,기존권한·보존·개인정보범위불변,초안집계와운영사실구분. 새storage/schema선택없음.
