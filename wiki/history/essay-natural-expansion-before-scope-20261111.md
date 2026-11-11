# 범위 정정 전 기록 — 이후 최신 Owner 지시 우선

[현재 연결 작업](../essay-natural-expansion-20261111.md). 아래는 기존 인수 시점 증거이며 최신 완료 조건이 아니다.

# 논술 LAB 자연계열 확장 인수·로컬 연결 검증 — 2026-11-11

**전체 PARTIAL. 운영 변경·신규 공개 없음.** 중앙대 수학69문항은 이미 운영 연결되어 재작업하지 않았다. 한국항공대6시험12문항의 비공개 DRAFT·문제PDF·기존 Math 계약 리허설을 추가했다. 신규 서비스 연결 후보10개교의 기존 Registry ID를 정리했으나, 이10개교의 runtime package·공개 완료를 뜻하지 않는다.

기존 정책: [TASK20 자연 연결](../task20-priority-natural-connection-20261106.md), [기존15대학/신규10대학 경계](../app58-expanded-production-connection-20261104.md), [공식 원본 보존](../essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30), [공통 STANDBY 정책](../essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책). 이번 Owner 지시는 로컬 구현·검증을 허용하고 **운영 DB/RPC·WEB 배포·사용자 공개·스토어 제출은 금지**한다. Provider/Credit/결제 정책 불변.

## 인수와 최신 상태 대조

- APP 기준 `4489603ccb3359aa95857737cc06dc016e1150f1`, 전용 브랜치 `codex/essay-natural-expansion-20261111`. 이전 `codex/task04-applications-app75` HEAD를 움직이거나 병합하지 않았다. 앱 제품 코드·build 설정 변경0.
- WEB 참조: `codex/task20-chungang-connection-20261107`, HEAD `745fbf3`; 중앙대 적용 구현 `9b5c229`, 공개 scope512 수정 `391ed0b`. WEB checkout은 읽기·기존 테스트만 실행했다.
- Owner가 지정한 `task20-15-audit-20261107.md`, `task20-15-exams-20261107.md`(task20-priority-release checkout)와 `task20-chungang-connection-20261107.md`(task20-web-availability checkout)를 대조했다. 전자는 착수 전 스냅샷, 후자는 중앙대 적용 후 기록이다. 과거 ‘중앙80 미연결’을 현재 상태로 사용하지 않는다.
- 감사표390시험의 등록 문항 수는 현재 DB와 **전부 일치**. Math 직접FK 연결 수가 달라진 것은 한양17시험·중앙20시험. 감사표 밖 한양2024수시 자연 오후1 1시험2문항도 현재 존재한다. [390시험 대조 결과](../../supabase/candidates/natural_expansion_20261111/owner-audit-reconciliation.json).
- 현재 LegendStudy 운영 DB 메타데이터를 SELECT로 확인했다. [재조회 SQL](../../supabase/candidates/natural_expansion_20261111/registry-readonly.sql), [review 승인 메타데이터](../../supabase/candidates/natural_expansion_20261111/review-metadata.json), [입력 해시·참조 커밋](../../supabase/candidates/natural_expansion_20261111/input-provenance.json). 사용자 답안/원장/계정은 읽거나 수정하지 않았다. 이전 작업의 데이터 보존 해시를 이번 보존 검사로 재사용하지 않는다.
- WEB42개 대학 Catalog와 Owner22개 우선순위를 재사용했다. Source Registry93시험 중90개는 대학UUID+exam_key+학년도+종류+계열+캠퍼스+회차+문항 label 집합이 기존 DB ID에 일치한다. 연세2025자연(추가), 성균2025언어형, 숙명2025인문계열 3개 source key는 정확 일치하지 않아 **UNRESOLVED_NO_INSERT**. 유사 제목으로 붙이거나 새 UUID를 만들지 않았다. [시험/문항별 결과](../../supabase/candidates/natural_expansion_20261111/registry-reconciliation.json). 미일치는 해당 대학 전체 미연결 판정이 아니다.

## 중앙대 — 기존 완료 보존

현재20자연시험80등록문항 중69수학문항의 Math set/problem이 ACTIVE이며, 나머지11개Q4는 미연결이다. [현재69/11 증거](../../supabase/candidates/natural_expansion_20261111/central-live-verification.json).

|항목|판정·근거|
|---|---|
|시험·문항 ID, 순서|DONE — 기존20시험/80문항 보존, 수학69 연결 확인|
|기존 문제PDF·평가 근거·Worker 입력|DONE(기존11/7 적용 기록) — private PDF20, 원본 지면 입력69, 기존8테이블920행|
|수식·텍스트 답안/사진 확인 진입|11/7 WEB20회차·69문항 확인 기록 재사용. 이번 새 사용자 E2E는 NOT TESTED|
|전체69문항의 모든 지면 육안/APP 입력|NOT TESTED — 과거 PDF뷰어 접근과 개별 모든 페이지 검수를 구분|
|실제 신규 첨삭·결과 품질|NOT TESTED — 이번 Provider0회. 기존 기술 연결을 품질 PASS로 확대하지 않음|
|2025/2026수시16문항 별도 출제 의도|기존 승인 예외 `INTENT_SOURCE_NOT_PROVIDED` 유지. 공식 채점기준·예시답안 사용, 의도 생성0|
|과학논술Q4 11문항|HOLD 유지|
|2027 자연 공통/선택 매핑 후보4시험|기존 별도 미확정 범위 유지. 위93 source metadata의 인문/상경2027과 혼동 금지|

중앙대11/7 최초 WEB 공개 시험262개가256한도를 넘은 장애는 당시 원복 후 공통512한도·입력검증으로 보완됐다는 기록을 확인했다. 이 수정은 되돌리거나 재배포하지 않았다. 이전 최종 배포ID `ce3e336c-5ccb-4f1b-b833-06234ac125c1`은 **11/7 기록**이며 오늘 배포ID를 새로 조회한 것은 아니다.

## 기존 자연계열 누락 목록

아래 시험 수는 **등록 문항이 있는 시험** 기준이다. 직접 Math FK 수와 사용자 공개/실제 검수는 다르다. 특히 건국Q1 기존 별칭 연결은 직접FK집계 밖에 있으므로 이미 연결된 Q1을 다시 생성하지 않는다. 현재 review 패키지 승인 메타데이터와 기존 감사표를 함께 대조했다.

|대학|시험/등록문항|직접 Math 연결|남은 처리|
|---|---:|---:|---|
|한양|21/42|42|재패키징 제외. 실제 전체 품질은 별도|
|고려|5/20|20|재패키징 제외. 기존 TEST 근거 보존|
|인하|25/75|72|2021수시 자연 오후3문항 근거 위치·매핑 재검수|
|숙명|18/50|6|44문항 후속. 기존 일반·약학6 유지|
|건국|7/28|3|별칭Q1 포함 기존4 유지, 나머지24 검수|
|경희|5/26|3|나머지23 검수. 문항 없는 자연계 placeholder4시험은 별도|
|한국항공|10/20|0|이번2024–26공학·이학6시험12 DRAFT,2022–23의8문항 후속|
|숭실|5/20|0|공식근거 페이지·수식·기준 검수 후 기존 Math 후보|
|동국|7/21|0|2026모의3문항과 후보 파일명2025 불일치 우선 해결|
|성균관|5/15|0|연도/언어형 alias·근거 정합성. 빈 placeholder4시험 별도|
|서울여자|4/9|0|자연 명칭만으로 Math 라우팅 금지, 과학/서술 기준 검수|
|서강|9/11|0|정확한 문항·소문항 구조와 기존 엔진 적합성 검수|
|광운|21/42|0|복구 Registry ID 유지,2022모의 근거 위치 재확인|
|중앙|20/80|69|과학Q4 11 HOLD, 완료69 재작업 금지|
|한국외대|0/0|0|현재 Registry 인문/사회만. 자연 시험 임의 생성 금지|

현재 Backend `math_private.release_catalog`도 읽기 확인했다: 중앙20시험69, 한양21/42, 고려5/20, 인하15/45, 건국1/4(legacy Q1 포함), 경희1/3, 숙명2/6. **인하 ACTIVE72 중 의예9시험27문항은 현재 release catalog 밖**이다. 이전11/7감사의 ‘공개 설정72’와 현재 Backend45를 분리하고 의예27을 자동 복구/공개하지 않는다. [현재 release catalog 증거](../../supabase/candidates/natural_expansion_20261111/release-catalog-metadata.json). Backend 목록 역시 오늘의 실사용 WEB·APP 성공을 의미하지 않는다.

[전체 자연/과학 계열23대학 시험별 ID·미연결 문항 목록](../../supabase/candidates/natural_expansion_20261111/natural-gap-inventory.json). 계열명이 없는 placeholder와 가천A/B형은 자연 단일 분류에 넣지 않았다. 자연계열이라는 이유만으로 엔진이 미구현이거나 자료가 없다고 단정하지 않는다.

## 한국항공대6시험12문항 — 이번 로컬 구현

우선 선정 근거: 기존 미연결20문항 중2024–26의6개 원본PDF99쪽이 로컬 공식자료 아카이브에 있고, 각Q1/Q2의 문제·출제의도·채점기준·예시답안 경계가 확인된다. 공식 입학처에도 [2026기출·모범답안 및 영향평가 게시](https://ibhak.kau.ac.kr/admission/html/usage/total_search.asp?page=2)를 확인했다. 로컬 원본SHA 일치와 공식 게시 존재는 별도 증거다. 현재 사이트에서 동일 원본을 다시 내려받아 byte 동일성을 검증한 것은 아니다.

|학년도·계열|기존 시험 ID|문항|문제 전용PDF쪽|
|---|---|---:|---:|
|2024공학|00355b1e-744d-553c-bba3-2483d4d57d42|2|4|
|2024이학|51d7f36d-a011-5279-8c5d-f731b2900af3|2|5|
|2025공학|3005e0cd-0a3b-5f8c-98ed-ae4a6736f0af|2|4|
|2025이학|85a8468d-2141-52b1-9d70-3bcf6f340f8e|2|4|
|2026공학|6815943a-42c1-5eae-b711-449ac403b9fb|2|4|
|2026이학|3e312310-9393-5d7d-90d3-731aee13c360|2|4|

- [source plan](../../supabase/candidates/natural_expansion_20261111/kau-source-plan.json): 원본SHA·physical page·문항UUID·순서·학생용 crop 경계. 인쇄쪽번호와 physical page를 혼용하지 않는다.
- [오프라인 도구](../../tool/essay_lab/natural_expansion.py): 대학/시험/문항 identity drift, 이미 연결된 문항, 공개된 대상, Owner HOLD, 누락 role/범위 밖 page를 거부한다. 기존 TASK20의8개 Math 테이블과 DRAFT SQL renderer를 재사용. 새로운 엔진/schema/RPC 없음.
- 기존 question1개당 leaf1개. 소문항을 별도 Registry 질문으로 중복 생성하지 않는다.12 DRAFT package/172행, 출처4role, 기존3개 rubric dimension을 사용한다. 채점기준은 **공식 지면 참조**이고 세부 배점 정규화는 미완료(official_points=null). 페이지 순서를 수학 풀이단계 의미로 추론하지 않는다.
- 원본 추출에는 수학 PUA 글리프가 남아12개 모두 `technical_ready=false`. 공식 지면 이미지를 기존 Worker JSON형식으로 묶었으며 최대508,405bytes로 기존1,800,000bytes제한 이내. 이미지 바인딩이 텍스트 품질/정답 타당성을 자동 증명하지 않는다.
- 문제와 출제의도가 섞인 페이지는 확인된 경계에서 잘랐다. **문제 전용PDF6개25쪽**을 raster로 생성하여 숨겨진 해설 텍스트·주석을 제거했다.25쪽의 수식·그래프·도형/잘림 여부를 이미지로 확인, 최종 재생성본25쪽 픽셀 일치. 실제 WEB/APP PDF 렌더는 NOT TESTED.
- Private 산출물: ignored `.local/natural-expansion-20261111/kau-verified/`. 원문·이미지·PDF·등록SQL은 Git에 넣지 않는다. [공개 가능한 해시 명세](../../supabase/candidates/natural_expansion_20261111/kau-draft-manifest.json)만 추적한다. Storage 업로드0, 운영 Registry/Math 등록0.
- **미완료**: 수식 전사/정규화 및 채점기준 정밀 검수, 문제PDF 실제 앱 렌더, 손글씨/수식 답안, 실제 Provider 정상/오답/부분답안 품질, WEB/APP 동일 결과·History. 아직 공개 후보 아님.

## 신규 서비스 연결 후보10개교

기존 Catalog42에 이미 있는10개교이며 대학 row10개를 새로 만든다는 뜻이 아니다. [기존 APP58 감사](../app58-expanded-production-connection-20261104.md)의 미연결10개교와 동일하다. Owner우선22에8개교 포함, 서울시립·가톨릭은 기존 source metadata를 가진 준비대학으로 보완한다. 실제 수요 통계는 확보하지 않아 수요 점수는 만들지 않았다.

아래 수는 **기존 등록 parent 문항/검토 상한**이다. 소문항·전체 공식 기출 보유 수·즉시 연결 가능 수와 다르다. 신규10개교의 이번 runtime package 생성은0, 공개 가능 확정도0이다. [대학·시험·문항UUID 전체 후보](../../supabase/candidates/natural_expansion_20261111/university-candidates.json).

|대학|기존 문항있는 시험/문항|연도·종류·계열|우선 검토 가능 범위·기준/엔진|
|---|---:|---|---|
|가천|17/166|2024–27 수시/모의,인문·자연·의약·A/B|국어/수학 혼합. 자연/의약 명시8시험73문항도 전부 Math로 연결하지 않음. 세부 과목·기준 분리 전 예상 연결 수 미확정. [공식 가이드](https://admission.gachon.ac.kr/upload/BBS0024/202507151748295SGWU8.PDF)|
|경북|1/3|2025모의 자연Ⅱ|3개 조사 대상. 수리/통합과학/의학 구분·기준 확보 후 기존 엔진 판정. [공식 수시 안내](https://www.knu.ac.kr/wbbs/wbbs/bbs/btin/viewBtin.action?bbs_cde=28&btin.doc_no=1333182&menu_idx=214)는 같은 연도 모의 구성의 증거가 아님|
|부산|2/6|2021모의·수시 자연|수학6 후보, 공식 해설/기준 지면 검수 필요. [공식 기출 게시](https://go.pusan.ac.kr/college_2016/pages/index.asp?b=B_1_3&bn=42069&m=read&p=7)|
|이화|1/3|2024모의 자연Ⅰ|수학3 후보, 기존 Math 재사용 검토. [공식 기출 목록](https://admission.ewha.ac.kr/admission/html/rolling/lecture-info.asp)|
|세종|3/9|2023수시 A/B,2024모의 자연|수학9 후보, 공식 답안/기준 확보 후 검수. [공식 기출 목록](https://ipsi.sejong.ac.kr/ipsi/assistant/exam-questions.do?mode=list)|
|아주|6/12|2021–24모의 인문/자연|자연2022–24의6 우선 Math, 인문6은 기존 Essay 후보. [공식 기출 목록](https://www.iajou.ac.kr/pasttest/index.php?f=&m_type=SUSI&nPage=-6148&s=)|
|연세|12/47|2022–24수시 과목별·2027모의 과학|수학8 우선, 과학39는 자동 라우팅 금지. 문항없는 시험4개 별도. Source2025자연추가3은 정확ID 미일치 HOLD. [공식 자료집 URL](https://www2.yonsei.ac.kr/entrance/2025/2026%ED%95%99%EB%85%84%EB%8F%84_%EC%97%B0%EC%84%B8%EB%8C%80%ED%95%99%EA%B5%90_%EB%8C%80%ED%95%99%EB%B3%84%EA%B3%A0%EC%82%AC_%EC%9E%90%EB%A3%8C%EC%A7%91.pdf) 조회는18.4MB크기 제한으로 본문 재검수 미완료|
|홍익|1/7|2025수시 자연 수학 **세종**|수학7 후보, 서울 캠퍼스로 합치지 않음. [기존 공식 영향평가 출처](https://www.hongik.ac.kr/kr/admission/notice-admission.do?articleNo=134109&mode=view)는 이번 fetch 실패; 기존 확인 기록과 구분|
|서울시립|1/4|2027모의 자연|수학4 후보, 수시 기출로 변경 금지. [공식 입학처](https://admission.uos.ac.kr/admissionNew/main.do), 해당4개 문항 기준 재검수 필요|
|가톨릭|1/3|2026모의 인문|기존 Essay3 후보. 자연 수·평가기준 미확정. [공식 입학처](https://ipsi.catholic.ac.kr/) 본문 재확인 불충분; 제3자 사본을 공식검증으로 승격하지 않음|

10개교는 문항있는45시험260문항이다(연세 빈4 포함 Registry 시험49). 자연 수학 우선 검토량은 부산6+이화3+세종9+아주6+연세8+홍익7+서울시립4=43문항이며 **검증 후 확정되는 후보 상한**이다. 가천/경북의 혼합·과학 및 가톨릭 자연 수는 별도다. Source Registry의9개교29시험97문항 중28시험94문항이 기존ID에 정확히 연결된다(가천은 별도 기존17시험166문항). 남은3문항은 연세2025추가 HOLD. 연세·홍익·서울시립의 기존 servicePreparing 정책도 유지했다.

## 검증 결과와 한계

|검사|결과|
|---|---|
|신규 Python identity/페이지 경계/HOLD/기존 연결 보호|15 PASS|
|격리 PostgreSQL17: 실제 기존 schema+RPC|12문항 모두 PASS, 공통6검사+문항별6검사(72). DRAFT 재실행, 기존 답안/결과/원장 보존, ACL, 중복/변조 거부, 답안·평가 멱등성, 기준별 결과 저장/조회·다른 계정 차단|
|첨삭 요청→결과 저장|로컬 모의 응답 계약 PASS. 실제 Provider·OCR·정답 타당성 NOT TESTED. 운영 DB 접속 없이 Unix 소켓 임시DB 사용|
|PDF|원본99쪽 렌더·경계 검토, 파생25쪽 육안 확인/픽셀 대조/숨은 텍스트·주석 없음. APP/WEB 실제 PDF NOT TESTED|
|기존 WEB|9파일97 PASS — Registry/공개범위512/대학정책/PDF/입력·Math 결과 계약|
|기존 Flutter|8파일85 PASS/4 SKIP — 회차·Workspace·수식/사진·준비중/멀티선택/혼합·승인결과|
|신규 실패|최종 관련 검사0. 최초 로컬 변조 시험은 기존 `IMMUTABLE_CONTENT_VERSION`이 먼저 차단해 시험을 수정했고 재실행 PASS. 최초 Flutter는 PATH의 구 SDK가 native-assets 미지원이라 실행 전 중단; 저장소 지정3.47.6으로 통과. 제품 수정/전역 SDK설정 변경 없이 해결|
|빌드·실기기·운영 E2E|이번 제품 코드/설정 변경이 없어 새 빌드·설치 없음. 새 후보 WEB/APP 실제 계정·기기 흐름 NOT TESTED. 과거 APP75/알림 빌드 PASS를 이번 후보 E2E로 재사용하지 않음|

[격리 계약 결과](../../supabase/candidates/natural_expansion_20261111/isolated-contract-report.json), [검증 영수증](../../supabase/candidates/natural_expansion_20261111/verification.json), [재현 방법](../../supabase/candidates/natural_expansion_20261111/README.md). 기존 전체 Flutter FAIL5는 이전 APP75 기준 실패이며 이번에는 관련 범위만 실행했다. 건너뛴4개를 PASS에 포함하지 않는다.

## 운영 적용 필요 사항과 남은 순서

1. 한국항공12문항의 공식 지면·수식·기준 검수와 TEST UI/실제 첨삭 검증을 완료한다. 현재172행 DRAFT SQL은 **운영 적용 승인 요청 가능한 최종본이 아니다**.
2. 운영 적용을 검토할 시점에 새 SELECT 스냅샷으로 기존ID·중복 binding·승인/공개 상태를 재검증한다. 현재 파일 존재를 운영 등록 증거로 사용하지 않는다.
3. Owner 별도 승인 후에만 검수된 문항에 한해 기존 Math DRAFT 등록 → 비공개 지면·문제PDF → 기존 release catalog/공개 scope 순서로 준비한다. 이번 코드에 activation SQL·Provider 설정·새 엔진을 넣지 않았다.
4. WEB/APP 동일 Backend에서 대학→회차→문제→답안→첨삭→결과/History를 실제 TEST 계정으로 확인한다. 정상/오답/부분답안, 취소/재시도와 기존 이용권 규칙도 기존 정책으로 검증한다.
5. 장애 시 새 scope 진입부터 닫고 이전 scope/asset reference만 복원한다. 이미 생성된 답안·평가·패키지·이용권 이력을 삭제하거나 덮어쓰지 않는다. 현재 운영 적용0이라 이번 운영 롤백 실행도0이다.
6. 항공2022–23의8문항 및 나머지 기존 대학은 위 누락 목록 순으로 공식 원본·기준을 먼저 검수한다. 신규10개교는43개 수학 후보부터 시작하고, 동국 연도불일치/연세추가3/중앙 과학11은 각각 HOLD 유지.

운영 DB/RPC·운영 WEB·공개·Store는 Owner 별도 승인 전 진행하지 않는다. 현시점은 전체 확장 완료/최종 릴리스 준비 완료가 아니다.

## 데이터 보존7항

1. 시험 학년도/모의·수시/계열·캠퍼스·회차, 기존 Registry와11/11검수 시점을 분리한다. 과거 테스트 시각을 현재 사실로 바꾸지 않는다.
2. 원본PDF SHA·physical page·crop·문항ID·생성 도구/version·입력 스냅샷 SHA로 재현한다. 원본은 private archive 보존.
3. 기존 row UPDATE/DELETE 없음. DRAFT SQL은 같은ID 내용불일치/기존다른leaf를 거부한다. 정정은 별도 version 검토 대상이다.
4. 대학/시험/문항 UUID 재사용. 학생 identity·로그인·기존 학습 기록에는 접근/변경하지 않는다.
5. 공식 시험자료/검수 메타데이터는 학생 Learning/Decision/Outcome 원본과 별개다. 로컬 synthetic 결과를 학생 학습 사실로 적재하지 않는다.
6. 사용자PII/답안·credentials를 읽거나 Git에 저장하지 않는다. 공식 원문·Provider 이미지도 Git 제외. 기존 권한/동의/retention 변경 없음.
7. source metadata 일치, DRAFT 등록 가능, 기술 연결, 실사용/품질, 공개를 각각 구분한다. 후보43·미연결 수는 재계산 가능한 검토량이며 제공완료 수가 아니다.
