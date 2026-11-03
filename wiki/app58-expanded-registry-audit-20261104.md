# APP58 — 운영 Registry 전체 재조사 및 확대 후보

기준: 2026-11-04 운영 읽기 전용 snapshot. 기존16시험은 최초 검증 기준선이며 전체 확대 범위가 아니다. 실제 운영 활성화·Provider 평가·이용권/History 성공은 이 문서의 데이터 준비 판정과 구분한다.

연결 문서: [APP58 산출물 인계](app58-store-handoff-20261104.md), [기존 통합 보고서](app-math-commerce-integration-report-20261103.md), [전체 대학 STANDBY](essay-all-university-standby-20261026.md), [상경·고려 자료](commerce-korea-20261026.md), [인하 기존 연결](inha-standby-20261026.md).

## 조사 범위와 검증

- 프로젝트 `stlhijzpjfgwwdgunlsd`. 대학26, 시험363, 기존 시험·문항 ID와 검수 상태를 그대로 조회했다. 신규 시험 DB/복제/리뷰 승격 없음.
- 공식 package213/문항493: 현재 package digest 재계산, exam/question/source FK, 공식 문제·criteria, VERIFIED 근거, Provider 전송권한, 현재 runtimeApproval 조건을 검사했다.
- 213개 각각 `essay_material_runtime_package(exam_id, current_digest)` SELECT 성공. 운영 runtime_policy digest도213개 모두 현재 package와 일치하며 Provider binding validity=true였다.
- 전체 문항이 연결된 데이터 후보211, 부분 승인2, 승인 package 미확보150. Provider 호출0, 원격 변경0, 제출0이다.
- [전체363시험·문항 ID·근거 요약·현재 scope·재현 SELECT JSON](evidence/app58-expanded-registry-20261104.json). 이 파일에는 학생 답안·이메일·비밀번호·토큰·키·공식 원문 본문을 넣지 않았다.

## 판정의 의미

`READY`는 **데이터/연결 후보**다. 공식자료, 승인 package, canonical 문항 전체, 기존 Essay/Math 경로가 준비됐다는 뜻이며 운영 제출 E2E PASS를 뜻하지 않는다.

`NEEDS_REVIEW`는 기존 review가 있으나 승인 package가 없거나, 승인 문항이 전체 시험의 일부인 경우다. `BLOCKED`는 승인된 runtime package/review가 없어 현재 경로로 공개할 수 없는 경우다. is_active/is_published=false만으로 차단 판정하지 않았다. 운영은 기존 엄격한 RPC/Worker scope와 승인 package를 통해 접근하기 때문이다.

| 집계 | 수 |
|---|---:|
| 데이터 READY | 211 |
| NEEDS_REVIEW | 73 |
| BLOCKED | 79 |
| 이번 완전 비의예 목표 | 202 |
| 기존 beta 보존 | 160 |
| 신규 연결 후보 | 42 |

목표202=기존 beta160 + 혼합26 + 자연 수리15 + 서강 business Essay1. Essay161/혼합26/Math15이다. 의예9는 이번 확대에서 제외하고 기존 공개 metadata는 삭제하지 않는다. 운영 완료 판정은 후속 배포·입력·평가·이용권·History 실제 검증 기록으로만 추가한다.

## 대학별 전체 집계

| 대학 | 전체 | 데이터 READY | 검토 필요 | 차단 | 이번 목표 | 기존 beta |
|---|---:|---:|---:|---:|---:|---:|
| 가천대학교 | 17 | 0 | 17 | 0 | 0 | 0 |
| 가톨릭대학교 | 1 | 0 | 0 | 1 | 0 | 0 |
| 건국대학교 | 25 | 14 | 11 | 0 | 14 | 8 |
| 경북대학교 | 1 | 0 | 0 | 1 | 0 | 0 |
| 경희대학교 | 34 | 24 | 4 | 6 | 24 | 22 |
| 고려대학교 | 10 | 4 | 6 | 0 | 4 | 4 |
| 광운대학교 | 17 | 16 | 0 | 1 | 16 | 16 |
| 동국대학교 | 16 | 6 | 4 | 6 | 6 | 6 |
| 부산대학교 | 2 | 0 | 0 | 2 | 0 | 0 |
| 서강대학교 | 32 | 23 | 4 | 5 | 23 | 22 |
| 서울시립대학교 | 1 | 0 | 0 | 1 | 0 | 0 |
| 서울여자대학교 | 11 | 1 | 1 | 9 | 1 | 1 |
| 성균관대학교 | 25 | 16 | 4 | 5 | 16 | 16 |
| 세종대학교 | 3 | 0 | 0 | 3 | 0 | 0 |
| 숙명여자대학교 | 8 | 3 | 5 | 0 | 3 | 3 |
| 숭실대학교 | 16 | 4 | 11 | 1 | 4 | 4 |
| 아주대학교 | 6 | 0 | 0 | 6 | 0 | 0 |
| 연세대학교 | 16 | 0 | 0 | 16 | 0 | 0 |
| 이화여자대학교 | 1 | 0 | 0 | 1 | 0 | 0 |
| 인하대학교 | 35 | 34 | 0 | 1 | 25 | 10 |
| 중앙대학교 | 26 | 21 | 0 | 5 | 21 | 11 |
| 한국외국어대학교 | 20 | 20 | 0 | 0 | 20 | 20 |
| 한국항공대학교 | 15 | 4 | 6 | 5 | 4 | 4 |
| 한양대학교 | 23 | 21 | 0 | 2 | 21 | 13 |
| 합성 검증용 — 실제 대학 아님 | 1 | 0 | 0 | 1 | 0 | 0 |
| 홍익대학교 | 1 | 0 | 0 | 1 | 0 | 0 |

미연결 시험도 JSON의 원래 university/exam/question ID·review 상태로 보존한다. 검토71개는 review=NEEDS_REVIEW이지만 승인 package가 없고, 나머지 검토2개는 부분 승인이다. BLOCKED79개는 review/package 미확보이며 합성 fixture1개도 포함한다. 지원하지 않는 과학 문제를 이름만으로 Math에 보내지 않는다.

## 부분 승인 및 의료계열 구분

- 고려2025 인문 `942c1c43-914f-5b99-9a30-e6474c363f6f`: 승인1/Registry2. 기존 문제2 예외 공개 유지, 새 전체회차 beta 확대 제외.
- 숙명2025 인문 `a6667288-75ad-50d4-b237-d2a08e2bff8b`: 승인1/Registry4. 전체회차 확대 제외.
- 인하 의예9: 공식 package와 canonical Math 연결은 있어도 이번 자연/상경 확대 범위와 분리한다. 기존 IDs와 승인을 수정하지 않는다.
- 기존 공개211 중 빠진 승인 package2개는 서강2026 경제경영과 숙명 부분승인1개다. 이번 공개목록 증분은 서강1개만 추가하여212로 준비한다.

## 현재 운영 상태와 배포 전 차이

- 공개 metadata scope211, Math leaf scope99(정규98+기존 legacy건국1), beta 확대flag 목록0.
- canonical ACTIVE Math50시험98문항=자연15/의예9/혼합26. 기존 legacy leaf에는 별도 기존 mapping 예외가 있으므로 신규 canonical 집계와 섞지 않는다.
- beta campaign enabled=true, 전체160/has_math0, daily_limit1. `2026-11-10` KST일까지, 즉 종료 `2026-11-11 00:00 KST` 유지.
- math runtime switch=true만으로 서비스 활성화로 판단하지 않는다. WEB flag, release-scope, RPC/Worker readiness, package/문항 전체 일치, credit source, coaching/History 계약을 모두 연결해야 한다.
- 기존 소스의 Math catalog50 제한과 확대 leaf72(이번71+legacy1)의 충돌을 APP58 바이너리를 바꾸지 않는 서버 호환 방식으로 해결해야 한다. 기존 legacy 동작과 기존 공개 metadata 보존 필요.
- 이전16/47 SQL/WEB manifest는 최초 후보이므로 전체 target202에 그대로 재사용하지 않는다. 기존 증분 코어와 검증 방식은 재사용하며 정확한 확장 scope를 별도 후보로 만든다.

## 실제 검증 준비

최소 대표군: 기존 인문(저장 PASS 재조회 우선), 서강2026 모의 경제경영 business Essay, 인하 자연, 중앙2026 경영경제 혼합, 한양2026 상경 혼합. 이미 통과한 TEST 평가를 운영 결과로 오인하거나 반복 호출하지 않는다.

중앙 다른 대학 혼합 대표 `e9e7daf3-854c-57d3-a6dd-cc18fca0d8ea`: Q1/Q2 Essay, Q3 Math. 공식 원본은 `/Users/woojinchang/development/legendstudy-materials/essay-2026-10/중앙대/2026학년도 중앙대 논술_경영경제 문제.pdf`(SHA256 `7bf9a3df472fd093874ce7dea21558cbecacca8ad52b086433046994d7779fa7`), `2026학년도 중앙대 논술_경영경제 해설,답안.pdf`(`2a52cfd3f32341a4d7f6af73fa36202d0b4b195828568dd36a44737d4624867b`). 두 파일 해시가 현재 package source refs와 일치한다. 공식 예시답안은 평가용 검수 자료이며 실제 학생 손글씨 정확도 증거가 아니다.

이 보고서 작성 시 실제 운영 평가/차감/무료 재첨삭/History 및 APP58 실기기 교차 E2E는 **NOT_VERIFIED**다. 후속 담당자가 실제 실행 증거와 비용/차감 결과를 별도로 기록한다.

## 보존

운영 학생 데이터·Auth·Credit·Ledger·결제 수정0. 원본 PDF 변경0. APP41/APP58 바이너리 변경0. provider 호출0. 로컬 보고서/익명화 metadata만 작성했다. 213 package 조회 성공을 OCR·수학적 첨삭 품질 PASS로 확대하지 않는다.


## 부록 — 실제 검수 준비와 남은 검증

### 읽기 전용 APP↔WEB 계약 점검 준비

실행 준비 파일은 `/tmp/legendstudy-app58-acceptance-plan.json`, `/tmp/legendstudy-app58-acceptance-sources.json`, `/tmp/legendstudy-app58-acceptance-readonly.py`다. 오프라인 형식 검사와 대표5시험 매핑 검사를 통과했다. 스크립트는 제공받은 합법적 사용자 세션으로 availability/catalog/History를 읽는 경로만 포함하며 로그인, 계정 생성, 브라우저 토큰 추출, claim/submit/Provider 실행을 하지 않는다. 여기서 원격 E2E 성공을 주장하지 않는다.

기존 인문 결과 재조회, 서강2026경제경영 Essay, 인하2027자연 Math, 중앙2026경영경제 혼합, 한양2026상경 혼합의 exam/question/leaf mapping과 후속 제출 DTO를 정리했다. 기존 TEST 답안의 내용과 PASS 자료만 재사용 가능하며 TEST attempt/run ID를 운영 제출에 재사용하지 않는다. 실제 평가 계정·이용권 범위 및 실행은 별도 Owner 승인과 실행 기록을 따른다.

### 공식 예시답안의 검수 입력 준비

원본 자료는 `legendstudy-materials/essay-2026-10`의 Owner 제공 PDF를 그대로 사용했다. 승인 package의 source SHA-256과 로컬 원본이 일치함을 확인했다. `/tmp/app58-official-answers/manifest.json`에 원본 경로/해시, canonical exam/question ID, 전사 파일, 직접 확인한 렌더링 페이지를 연결했다. 원본·이미지·전사 본문은 Git에 추가하지 않았다.

- 서강2026경제경영: 공식 예시답안 PDF8쪽을 직접 대조. 예시답안 자체1134자로 지시문의800–1000자 범위를 초과하므로 임의 축약하거나 글자 수 준수 PASS로 기록하지 않는다.
- 중앙2026경영경제: 공식 예시답안 PDF3–4쪽. Essay Q1/Q2는568/569자로 원문과 일치하며 Math Q3의 분포표·식·최종값을 전사했다.
- 인하2027자연: 공식 예시답안 PDF3·6–7·10쪽. Q1/Q2 전사와 수식 대조를 완료했다. Q3의3-1은 실제 그래프를 요구하므로 텍스트 전사만을 완전 답안으로 제출하면 안 된다. 원본10쪽 그래프 이미지를 보존했고 임의 재구성을 하지 않았다.
- 기존 인하 자료의 일반/의예 문제 PDF 이름이 뒤바뀐 사실은 [기존 인하 검수](inha-standby-20261026.md)에 기록되어 있다. 파일명만 보고 canonical 연결을 바꾸지 않았다.

검수용 LaTeX146개는 기존 WEB KaTeX로 parse error0이다. 이는 전사 문법 검사이며 실제 APP/WEB 화면 렌더링, OCR 정확도, Provider 첨삭 품질 PASS를 뜻하지 않는다. 이 준비 단계 Provider 호출0/신규 제출0이다.

### APP58 재빌드 없는 실기기 준비

기존 `release58/Runner.xcarchive/Products/Applications/Runner.app`는 버전1.0.1(58), `com.legendstudy.app`, arm64 Release AOT 앱이며 Apple Development로 서명되어 있다. profile은2027-09-21까지 유효하고 iPhone12ProMax/17ProMax를 포함한다. 기존 Store IPA는 별도 App Store 배포 서명이므로 파일 해시는 다르지만, 코드 비교 결과 Runner53개와 App.framework3개 실제 Mach-O 섹션 및 AssetManifest가 일치했다. 서명 읽기 전용 검증 `codesign --verify --deep --strict` PASS.

준비 기록: `/tmp/app58-device-readiness.md`, `/tmp/app58-archive-code-equivalence.json`. 같은 Archive의 이미 서명된 앱을 직접 설치하거나 기존 A48 ExportOptions로 별도 device export할 수 있다. 소스·버전 재빌드나 Store IPA/AAB 변경은 필요 없다. 이 조사에서 export/설치/실행/스토어 업로드는 모두0이다.

기기 목록에는 iPhone12ProMax가 연결된 것으로 확인됐으나 설치 앱 조회가 CoreDeviceService 초기화 제한시간을 초과했다. 따라서 현재 설치 버전과 APP58 실제 실행은 미검증이다. 설치하면 동일 bundle인 A48 앱을58로 업데이트하므로 기존 로그인·데이터 보존도 실제 확인해야 한다. 별도 LS Math TEST와 APP41 소스/산출물을 보존한다. A48·TEST56·Simulator 검증을 APP58 실기기 PASS로 전용하지 않는다.
