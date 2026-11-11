# 자연·수리 TECH READY 순차 검증 — 2026-11-12

[Owner 최신 기준](decisions.md#2026-11-12--tech-ready-순차-연결-후-owner-통합-검수)에 따라 대학별 기술 연결을 먼저 검증한다. **전체 완료/REVIEW READY/AI 품질 PASS가 아니다.** 운영 DRAFT 적재·검수 권한·활성화·배포·사용자 공개는 별도 승인이다. 기존 완료4개교와 중앙 과학11 HOLD를 보존한다.

## 순차 확인 결과

|순서|대학|이번 기술 범위|검증 상태|운영/잔여|
|---|---|---|---|---|
|1|한국항공|4시험7문항|TECH READY; 기존 Worker/WEB/APP 계약 및 운영 DRAFT 영수증 재사용|DRAFT106행 적용 완료; HOLD5; REVIEW READY 아님|
|2|건국|6시험24문항|TECH READY; DB489/WEB26/APP25 PASS|기존 운영4 보존; 신규24 운영 미적재; DRAFT299행 승인 필요|
|3|경희|1시험3문항|TECH READY; 후보7 leaf 계약 DB149/WEB6/APP8 PASS|기존3 보존; 의약4 leaf-only/시험 진입 차단, 과학12+기준 미확인4 NOT READY; 운영 미적재|
|4|성균관|5시험15문항|기술 계약 TECH READY; DB309/WEB22/APP16 PASS|15 PDF 승인 대기 유지; 운영 미적재; 검수/공개 차단|
|5|서강|9시험11문항|기술 계약 TECH READY; DB229/WEB38/APP12 PASS|운영 미적재; 2026자연2차 PDF 누락 보완 후보 승인 필요; REVIEW READY 아님|
|6|숭실|4완성시험16문항 / 부분3 / HOLD1|완성16 TECH READY;20 leaf DB409/WEB18/APP21 PASS|2024Q2 공식 배점 불일치 검수 보류; 운영 미적재|
|7|숙명|16시험44문항|기술 계약 TECH READY; DB889/WEB66/APP45 PASS|기존 운영6 보존; 신규 PDF38 승인·운영 미적재|
|8|동국|7시험21문항|TECH READY; DB429/WEB30/APP22 PASS|기존 승인PDF21 보존; DRAFT286행 미승인·미적재|
|9|광운|21시험42문항|TECH READY; DB849/WEB86/APP43 PASS|신규PDF42 승인 대기; DRAFT636행 미적용|
|10|서울여|후속 순서|아직 TECH READY 미보고|광운 이후 순차 검증|

위 검사 수는 각 대학의 명명 계약 검사 수다. DB는 기존 Worker 자료 매칭과 합성 답안/Mock 결과의 제출·결과·재작성·재첨삭·멱등성·권한·원복을 합산한다. 실제 Provider 호출/모델 품질/운영 WEB·APP 실계정 E2E가 아니다. WEB 각 대학1 SKIP은 대상에 없는 과거10대학 fixture이며 실패0. Flutter는 leaf별 기존 입력 진입과 계약 검사를 실행했다. 공통 Python 음성검사26 PASS. 기존 엔진·학생 기록·Credit·결제·APP75 코드 변경0.

## 증거와 적용 경계

[대학별 새 영수증/문항별 DB·Worker 결과](../supabase/candidates/natural_tech_ready_20261112/README.md). 건국→경희→성균관→서강을 순차로 검사했고, 같은 대학 내부의 독립 WEB/APP 검사는 함께 실행했다. 각 대학에서 현재 운영 Registry/leaf/공개 상태를 SELECT 대조했다. 일반 사용자 데이터 조회·수정0, 운영 쓰기0, Provider0, WEB 배포0, 앱 설치/스토어/릴리스 병합0.

건국24/경희7/성균관15의 기존 package·SQL hash를 그대로 검증했다. 기존 운영 건국4(legacy Q1 포함)/경희3은 재생성하지 않았다. 대학별 공식 자료/학생 PDF 기준은 [기존 연결 검수](essay-four-university-connection-20261111.md)를 계승한다. 새 검사가 과거 승인 상태를 승격하지 않는다. 경희7 전체를 완성 시험 TECH READY로 보고하지 않는다.

## 서강 신규 연결

기존9시험11 Registry를 그대로 사용했다. WEB Source Registry에 자연시험 진입이 없음을 확인하여 **로컬 후보에만**9시험 연결을 추가했다. 공식 보관 PDF9개에서 문제·출제의도·기준·예시답안의 SHA/physical page를 명시했고, 기존8개 Math 테이블139행 + private Worker11행 = **150행 DRAFT 후보**를 만들었다. 새 평가 엔진·문항 분할·배점 추정·공식 내용 수정은 없다.

2023모의1/2차,2024모의1차,2025모의1/2차,2026모의1차,2027모의 각1문항과 2026수시자연1/2차 각2문항이다. 각 Registry의 ‘문제1’은 기존 여러 소문항 묶음 그대로 유지한다.

문제전용 후보9 PDF/22쪽은 원본 raster와 픽셀 일치, 숨김 텍스트/주석 없음, 전 문제쪽·11개 기준 지면 육안 확인. 공식 수식/도형은 이미지 그대로 보존하며 전사·정답 품질을 판정하지 않았다. 기존 승인 학생 PDF 메타데이터9문항을 재사용하고, 누락이 확인된2026자연2차의 공유 PDF2문항은 새 비공개 후보를 참조한다. 기존 운영/추적 WEB 메타데이터는 변경하지 않았다.

### 서강2026 자연2차 Q2 PDF 누락 — 별도 승인 필요

문항 `cf5f3f9a-66e1-5e52-881a-6dad8ed84eb8`,시험 `e08ff787-f4d4-5da9-8922-d78d2c45f443`. 기존 승인 asset `da2dabb259b03f409743ff6a9bd6dfc4dc190f58d57759895027c87c7f5c21dd`와 동일 SHA인 로컬 storage-readback은3쪽이고, 마지막쪽 Q2-4가 식 중간에서 끝난다. 공식 보관 원본 물리7쪽 상단의 나머지 조건과 질문이 빠져 있다. 현재 원격 Storage bytes는 NOT TESTED이며 운영에서 동일 결함을 새로 재현했다고 단정하지 않는다.

보완 후보는 원본6쪽+7쪽의 문제 영역을 함께 보존한다. 시험 전체4쪽, Q1시작1/Q2시작3. 원문/해설을 고치지 않았으며 원래 승인 자산 삭제·교체·업로드0이다. 승인 전 기존 메타데이터를 새 자산으로 덮지 않는다. 문항 자체의 공식 문제/해설 불일치 HOLD와 구분되는 학생 PDF 지면 누락이다.

공식 사이트 현재 재조회는 `admission.sogang.ac.kr/enter/html/rolling/data.asp`, `.../counsel/book.asp`에서502로 실패했다. 기존 Owner 제공 공식 보관 원본/SHA를 근거로 연결했으며 새 공식 다운로드 성공으로 보고하지 않는다. 출처·물리쪽·해시는 [서강 source plan](../supabase/candidates/natural_tech_ready_20261112/sogang-source-plan.json), PDF 검사는 [지면 영수증](../supabase/candidates/natural_tech_ready_20261112/sogang/pdf-contract-report.json)에 있다.

## 보존 검토와 다음 단계

[기존 보존7항](essay-four-university-production-preflight-20261112.md#보존-검토7항-및-승인-경계)을 계승한다. 학년도/작업일 분리, 원본SHA·지면·Registry 유지, 기존 학습/결과/원장 UPDATE0, 동일 auth identity, 기술 검증과 Learning/입시 결과 구분, private 원문/SQL 유지, Mock을 품질 사실로 승격하지 않는 원칙을 그대로 적용했다.

Owner 검수 계정은 별도 지정된 계정으로 고정한다. [접근 제어 후보](essay-owner-review-access-20261112.md)는 공통 통합 검수용 후속이며 다음 대학 착수 조건이 아니다. 전체 대학 REVIEW READY가 확보된 뒤 통합 검수 목록을 전달한다. 운영 적용 시에는 대학별 최신 사전 SELECT와 정확한 대상/행수/SQL/복구 범위를 다시 제시하고 승인받는다.

## 숭실 자연20 기술 계약·공식 기준 불일치

기존5시험20문항을 재사용해 Math230+Worker20 =250행 로컬 계약 fixture를 구성했다. 운영 적용 대상 확정 SQL이 아니며 HOLD1을 포함하므로 **250행 전체 실행 금지**다. 원본 질문·배점·해설 수정0. 기존2026 인문 v3 기준 불일치 이슈는 별도이며 건드리지 않았다. 신규 자연 소스는 기존 보관본5개와 [입학처2025 공식 보고서](https://iphak.ssu.ac.kr/board/exam_view.asp?flag2=1&number=127&page=1&page_no=1_2_7)의 직접 다운로드1개를 사용했다. 다운로드 SHA와 원본51–67쪽 연결은 [영수증](../supabase/candidates/natural_tech_ready_20261112/soongsil/official-download-receipt.json)에 있다.

원본 PDF 일부의 추출 텍스트 좌표가 실제 렌더 지면과 달라 잘못된 자동 crop 위험을 확인했다. 로컬 후보 생성기의 명시 `crop_bottom`(실제 검토 지면 좌표) 지원을 추가하고 모드충돌/범위/NaN·무한대/잘못된 형식을 거부하는 검사2개를 추가했다. 기존 heading 방식은 유지한다. 5개 문제 후보PDF21쪽은 원본 해당 영역과 픽셀 일치·숨김텍스트/주석 없음,21문제쪽/20기준쪽을 육안 확인했다. 실제 연결은 기존 승인 PDF20문항 메타데이터를 보존하여 재사용하며 업로드0이다.

2024자연Q2 `815bc344-cdbb-5b7f-82c1-dc528de46f51`: 문제PDF 물리3쪽은25점, 해설PDF 물리4쪽(인쇄40쪽)의 기준은(1)25점+(2)15점이다. 원본 raster와 추출을 함께 확인했고 재계산/정정하지 않았다. **공식 근거 검수 보류1**로 분리한다. 해당2024시험의 나머지3문항은 leaf 계약 PASS이나 부분 시험 진입 보완 전까지 전체 시험 TECH READY에 포함하지 않는다. 로컬 expansion 목록에서2024시험을 제거하고 차단 검사를 통과했다. 나머지4시험16문항 TECH READY, 실제 품질/운영검수는 통합 단계다.

숭실 DB409/WEB18 PASS(1비대상SKIP)/Flutter21 PASS. Provider0·운영쓰기0·배포0. 다음 대학은 숙명여대다.

## 숙명 자연44 연결

운영 SELECT로18시험50문항 중2026수시 일반/약학부6개의 기존 Math 연결을 확인해 대상에서 제외했다. 나머지16시험44문항은 Registry ID/답안단위를 그대로 유지한다. 2021수시·모의의1문항은 원래1-1/1-2/1-3 묶음이며 임의 분할하지 않았다. 기존 공식 보관 PDF32개에서 출제의도/채점기준/예시답안 원본 지면을 연결했다. 일부 텍스트 추출에 빠지는 표도 원본 raster로 보존한다.

문제 후보16PDF53쪽 및 고유 기준37쪽을 육안 대조했다. 2023모의Q2는2–3쪽,2024수시/모의Q2는2–3쪽·Q3는4–5쪽을 포함하여 다음 지면 누락을 방지했다. 전 후보 지면 픽셀 일치·숨김텍스트/주석 없음. 기존 승인 학생PDF6문항 메타데이터를 보존하고 신규38문항은 승인 대기로 유지했다. 업로드·교체0.

Math658+Worker44=702행 DRAFT 후보는 **미승인·미적용**이다. 격리 DB889/WEB66(비대상1SKIP)/Flutter45 PASS; Provider0. 기존 사용자 기록·권한·엔진·운영 데이터 변경0. [숙명 영수증](../supabase/candidates/natural_tech_ready_20261112/sookmyung-receipt.json), [원본 지면계획](../supabase/candidates/natural_tech_ready_20261112/sookmyung-source-plan.json). 기술 계약 TECH READY이며 실제 검수 접근과 신규 PDF 승인 전 REVIEW READY가 아니다. 다음은 동국대.

## 동국 자연21 연결

7시험21개의 기존 Registry/문항 ID를 대조했다.2022/2023/2024모의의 hash형 Source Registry ID를 유지하고2024는 기존 source hash와 일치하는 온라인모의 자료를 선택했다. 보관본2025모의와2026모의 문제·해설은 각각SHA가 동일하며 원문은2025년 시행 표기다. 기존2026학년도 Registry에만 연결하고 별도2025시험을 만들지 않았다.

기존 공식보관PDF12개,7개 문제후보30쪽,고유기준44쪽을 대조했다.2022모의Q2의 이어지는 표는물리3–4쪽, Q3는5쪽으로 연결했다.2025/2026수시는 출제의도 시작 전의 문제영역만 원본 그대로 보존했다.2025수시Q2 공식 정정문(원문 비만 표기 관련)은 그대로 포함하고 임의 수정하지 않았다. 기존 승인 학생PDF21문항 메타데이터 보존·업로드0.

Math265+Worker21=286행 DRAFT 후보는 미승인·미적용. DB429/WEB30(비대상1SKIP)/Flutter22 PASS, Provider0·엔진변경0·운영쓰기0. [동국 영수증](../supabase/candidates/natural_tech_ready_20261112/dongguk-receipt.json). 기술 계약 TECH READY이며 실제 통합 검수 경로는 아직 미준비다. 다음은 광운대.

## 광운 자연42 연결

21시험42개의 기존 Registry ID를 유지했다. 2021–2026수시14시험과2021–2027모의7시험이다. 공식 보관 합본에서 문제·기준·예시답안을 연결하고21개 문제PDF78쪽의 원본영역 픽셀 일치·숨김텍스트/주석 없음을 검사했다. 기준 지면도 육안 대조했다. 2021수시2교시Q1은물리2–3쪽/Q2는4쪽으로 바로잡고,2022모의Q2 펼침면은 왼쪽 전체와 오른쪽 문제 연속 영역으로 나누어 누락을 방지했다. 문제 내용·수식·공식 기준은 수정하지 않았다. 6개 빈 출제의도 상단과6개 표지는 제외했다.

로컬 PDF 생성기에 검토된 사각영역 crop과 범위/모드충돌 검사를 추가했다. 기존 엔진/WEB/APP 제품 동작은 변경하지 않았다. 신규 학생PDF42문항은 승인 대기이며 업로드0. Math594+Worker42=636행 DRAFT 후보는 미승인·미적용이다. 격리 DB849/WEB86(비대상1SKIP)/Flutter43·Python26 PASS. [광운 영수증](../supabase/candidates/natural_tech_ready_20261112/kwangwoon-receipt.json). TECH READY이며 실제 검수 접근/AI품질 완료가 아니다. 다음은 서울여대.
