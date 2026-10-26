# WEB 논술 작성·진행 UI — 2026-10-26

## 미제공 시험 CTA 문구 — 2026-10-26

Owner 요청에 따라 자연계 포함 미제공 회차의 하단 제출 위치에 비활성 **첨삭 서비스 제공 예정** 버튼을 표시한다. 서버 admission 미승인 또는 작성 문항 중 실행 연결 미완료 상태에만 적용한다. 조회 중/오류는 기존 확인 중/재시도 표시를 유지하고 서버 승인 우회는 없다. 대학 카드 문구 및 정상 CTA는 변경하지 않는다. 운영 고려2025모의 자연은 조회 오류/재시도 상태가 관찰되어 미제공 버튼 실제 표시 확인으로 보고하지 않는다. 미제공 버튼은 기존 admission 회귀 검사로 확인했다. Production `069e9c29-c2a6-48c5-89d1-7a3c046b077e` success. WEB `0704f33`, Typecheck·관련6검사·build PASS. DB/Worker/APP/Provider 변경0.

## 답안 입력 후속 — 2026-10-26

첫 문항만 기본 펼침, 나머지는 접힘으로 변경했다. 헤더에 작성 여부·저장 상태·접기/펼치기를 표시한다. 숨긴 문항도 mounted 상태로 두어 기존 Draft·사진 복원을 유지한다. 수동 저장 성공 시 다음 미작성 문항을 열지만, 해당 시험에서 한 번이라도 사용자가 직접 토글했다면 그 선택을 우선한다. 페이지 재진입 시 답안은 기존 저장소에서 복원하며 펼침 상태는 첫 문항 기본값으로 시작한다.

TEXT는 사진 촬영/새 첨부 메뉴를 숨긴다. 기존 사진이 남아 있다면 지우지 않고 보관 안내와 명시적 삭제만 제공한다. IMAGE 또는 기존 서버 availability의 문항별 Math binding에 해당하면 카메라·이미지·미리보기·교체/삭제와 수식/텍스트 입력을 제공한다. 대학·계열 이름으로 판단하지 않는다. 기존 추출·사용자 확인·혼합형 parent 실행 및 회차 1/0 Credit은 변경하지 않는다. 재작성 화면도 동일 문항별 Math 계약을 전달한다.

### 기존 자연계 Math 성공 근거 — 신규 호출 없음

|구분|건국 자연계|다른 대학/기록|
|---|---|---|
|Registry|2026 자연1번 기존 시험/문항과 Math14행 연결 기록 있음|등록 여부만 평가 성공으로 세지 않음|
|STANDBY/공개|2026-10-23 자연1번 일반 로그인 사용자 실행 연결 기록 있음; 전체 시험 STANDBY와 구분|한양 상경은 혼합형이며 자연계 성공에 포함하지 않음|
|실제 Math 평가|자연1번 최초 `a05ed47e-4974-4e1e-a9d1-e0b56c5592f2`, 무료재첨삭 `8511e404-9343-4ff4-9b52-5666b24fd4e6` COMPLETED 기록|Wiki에서 다른 대학의 자연계 공식 시험 실전 성공은 이번 조사로 확정하지 못함|
|다문항 회차 성공|위 근거는 단일문항이므로 다문항 성공 아님|기존 합성 계약 검사를 실제 다문항 성공으로 환산하지 않음|
|이미지 답안|합성 인쇄 이미지 업로드→판독8영역→학생확인→최초평가 성공; 실제 손글씨/6장 성공 아님|기존 generic Math COMPLETED8은 대학/공식시험 증거가 없어 대학별 성공으로 세지 않음|

근거: [건국 최초/무료재첨삭·WEB/Simulator·1/0Credit](phase3-service-20261022.md), [DRAFT 및 실험 범위](konkuk-service-20261021.md), [generic Math8 범위](essay-full-service-implementation-20261011.md). 과거 운영 증거를 재사용했으며 오늘 DB 실행·평가 재호출은 하지 않았다.

검사: 관련 UI4파일17건 PASS, Typecheck/Production build PASS, lint 오류0/기존경고2. 저장·복원·타계정 차단·다른 창 충돌·자동 다음 문항·사용자 토글 우선·TEXT/Math 메뉴·기존 혼합형 입력/제출 계약을 확인했다. DB·Worker·Secret·APP 변경0, Provider0. WEB `8cb9342`, Production `3909b32a-faa2-4d75-b9d8-a72c5c66005a` production/success 확인. 일반계정 한양2027모의 상경에서 Q1텍스트만/Q2사진·수식 메뉴, 기존701자/사진1장 복원, 기본 첫문항 펼침 및 수동토글, 두문항 준비완료/1Credit CTA 활성화 확인. 답안·사진 변경/제출/재추출0. 이 확인 시 표시 Credit7이며 앞선 작업의8과 시점이 다르므로 UI 작업의 차감으로 해석하지 않는다. 롤백은 직전 Pages `bb120a6a-c50c-4ced-80ed-d11860fec1f0`만 대상, SQL/Worker 복구 불필요.

## 13:31 후속 — 완료 결과 전용 화면 통합

최신 Owner 지시가 앞선 결과 상세 불변 범위보다 우선한다. 상단 4단계 표시를 삭제하고, 첨삭 완료/History 양쪽에서 `/my/essays/result/?source=exam&id=<기존 회차 ID>`를 연다. 기존 `RecordDetail`·평가 데이터 조회·음성·근거·재작성·성장 비교를 재사용한다. Math는 동일 페이지의 `source=math` 경로를 사용한다. 새 결과 저장/복제는 없다.

자동 이동은 기존 상태 RPC에서 부모와 제출 문항 전부 completed인 경우만 수행한다. 진행 모달을 닫아도 조회를 유지한다. 부분 실패는 이동하지 않고 기존 0 Credit 재처리를 유지한다. 결과 화면에는 기존 작성/제출 입력을 반복 표시하지 않는다. 재작성하기를 명시적으로 누르면 기존 무료 재첨삭 입력 화면이 열린다. 추가 유료 첨삭은 접힌 선택 영역으로 유지하며 비교 대상이 없으면 성장 비교 자체를 숨긴다.

- WEB commit `ce433f8`, Production `bb120a6a-c50c-4ced-80ed-d11860fec1f0` / production success 확인.
- Typecheck·Production build PASS, lint 0 errors/기존 경고2. 관련 검사 총9파일34건 통과(실패한 링크 기대값 수정 후 해당 검사 재실행 포함). 실제 완료/부분 실패·모달 닫힘·최초/무료재첨삭 이동은 합성 상태 검사이며 신규 Provider 평가 아님.
- 운영 일반 계정: 기존 한양2027모의 인문 최초 첨삭 History → 결과 전용 URL, 원래 종합평가/근거/음성/기준별 결과, 빈 성장 비교 없음 확인. 재작성하기 → 기존 0 Credit 무료재첨삭 입력 확인 후 결과로 복귀. 답안 입력/새 제출 없음, 표시 Credit8 유지.
- APP·DB·Worker·Secret 변경0, Provider0, 신규예약/차감0. 원본 답안·평가시각·회차 ID·최초/재첨삭 관계·사용자 소유 범위·기존 정산/History·학습사실 구분을 보존하며 새 저장/UPDATE 의미를 도입하지 않는다.
- 복구: 바로 전 UI 배포 `93aaf61c-13f3-463e-8257-099c6178a028`로 Pages만 복귀. DB/Worker/Secret 복구 금지.

아래는 오전 UI 배포 당시 기록이다.

## 이전 결과

Owner 샘플을 기준으로 WEB 작성·저장·제출·진행 화면과 History 목록만 변경했다. Flutter APP·결과 상세·DB·평가 Worker·Secret·금융 계약은 변경하지 않았다. 기존 상경/고려 운영 상태는 [별도 기록](commerce-korea-20261026.md)을 유지한다.

Production: https://lab.legendstudy.com/essay-lab/
- Pages deployment: `93aaf61c-13f3-463e-8257-099c6178a028`, production/success API 확인.
- 배포 소스: `894180cd0daecd9f4af1541301024cdc8de70b6c` (앞선 구현 `dd72bd181eeb75a4abdf0ae654485c32dd536567`).
- WEB 최종 코드/검사 commit: `376e6b2` (배포 이후 사진 재추출 회귀 테스트만 추가; 실행 코드 동일).
- Backend Worker: `65fd5977-fbac-460a-bfc9-a38d836f6357` 100% 그대로.

## 구현 및 기존 계약

대학별 로고·대학명·선택 시험·공식 자료·기존 2027 일정 표시를 네이비 히어로로 통합했다. Registry 전체 시험명이 중복 출력되지 않도록 표시만 정리했다. 모든 문항 카드를 동시에 표시하며 기존 문항 선택은 카드 이동으로 재사용한다. 문항별 저장·자동저장·PDF·텍스트/사진 기능을 유지한다.

사진 교체, 다시 추출하기, 이 내용으로 확인을 구분한다. 재추출하면 이전 확인 참조를 제거하고 사용자 확인을 다시 요구한다. 기존 입력 이력은 유지한다. 사용자 사진을 임의 확인하지 않는다.

회차 제출 영역은 작성/저장/사진 확인 상태와 기존 1/0 Credit 정보를 보여준다. 기존 부분 제출 모달·서버 승인·멱등키·재처리 경로를 그대로 사용한다. 서버가 run ID를 반환한 뒤 진행 모달을 표시하고 사용자/시험/범위별 접수 영수증을 보관하여 재접속 시 해당 요청 상태를 조회한다. 기존 대기 제출키를 대체하지 않는다.

진행 모달은 기존 상태 RPC와 실제 문항 완료 수를 사용한다. 퍼센트는 만들지 않으며 기존 휴식 메시지를 10초 간격으로 표시한다. 일부 성공을 전체 완료로 표시하지 않는다. 완료 버튼은 기존 결과 상세로 연결한다. History 목록만 최초/재첨삭 배지를 테두리로, 결과 보기를 채운 버튼으로 표시한다.

## 확인 범위

- Typecheck PASS; lint 오류 0, 기존 Math effect 의존성 경고 2.
- 관련 UI 8파일/34검사 PASS. 최종 표시 보정 후 관련 2파일/9검사 PASS; 추가 사진 재추출 회귀 포함 Math 8검사 PASS.
- Production build PASS, Pages production/success 확인.
- 일반 계정 운영 WEB: 동적 고려 로고/흰 제목/중복 없는 시험명·전체 문항 카드·임시 입력 자동저장·제출 CTA 활성화·부분 제출 확인창·1 Credit 안내 확인. 최종 제출하지 않고 임시 입력을 원래 빈 상태로 복원. 표시 Credit 8 유지.
- 진행 모달은 합성 상태 및 로컬 360px 화면으로 완료/부분완료/실패/닫기/메시지 전환을 확인했다. 새 실제 평가를 제출하지 않았으므로 신규 Provider E2E PASS로 표시하지 않는다.
- Provider 호출 0, 새 Credit 예약/사용 0, Production SQL 0. 기존 ID·History·Ledger 저장/정산 함수 수정 0.

## 보존 검토와 제한

원본 답안·관찰 시각·제출 회차·개인 식별 범위·학습 이력은 기존 계약을 유지한다. UI 상태를 평가 사실로 저장하지 않는다. 사용자 소유 범위별 조회를 유지하며 DB UPDATE/새 수집은 없다. [장기 학습 데이터 원칙](longitudinal-learning-admissions-data-strategy.md)과 [회차 정책](decisions.md)을 따른다.

순수 Math의 기존 문항 실행은 브라우저 조율 계약을 그대로 사용한다. 부모 회차는 서버에 남고 재진입 시 조회/기존 재개 경로로 이어진다. 이번 UI 변경이 새 서버 백그라운드 실행기를 제공하는 것은 아니다. 실제 사진 내용 확인과 실제 첨삭 결과는 Owner 검수 대상이다.

## 복구 및 다음 작업

UI 복구는 Pages의 직전 정상 배포 `758c9a18-f1a2-49b3-87f9-bd0b9e52b8ba` (WEB `225cc2dd1a3641fc0b4ea54c464e6ba314a0a3bb`)로 복귀한다. DB SQL·Worker·Secret 복구를 실행하지 않는다. 배포 설정 전체 덮어쓰기 금지.

Owner는 일반 계정에서 작성/사진 확인/제출 진행 화면을 확인한다. 결과 상세 및 APP UI는 이번 변경 대상이 아니다. 추가 Provider 호출·앱 빌드·스토어 배포는 수행하지 않았다.


## 2026-10-26 — 기존 첨삭 시험 재진입과 독립 초안

Owner 최신 결정: 시험 선택만으로 완료 결과로 이동하지 않는다. exact exam ID에 기존 평가 기록이 있으면 작성 화면 위 확인 모달을 표시한다. ‘네, 기록 확인’은 해당 시험만 필터한 기존 History, ‘아니오, 새로 작성’은 독립 빈 초안이다. 기존 결과에서 재작성하는 무료 경로와 구분한다.

- `ExamReentryGate`가 로그인 주체/시험 ID로 기존 Essay·Math 기록을 읽는다. 조회 실패는 재시도이며 기록 없음으로 취급하지 않는다. 비동기 조회는 unmount 시 무효화한다.
- 새 UUID 작성 세션을 owner/exam별 로컬 index에 보관한다. 텍스트(localStorage), 사진(기존 IndexedDB), Essay 접수/멱등키, Math 입력/접수 키가 같은 세션 namespace를 사용한다. 기존 key 삭제/덮어쓰기 없음. 보관된 작성 세션 메뉴에서 기존/별도 초안을 다시 열 수 있다.
- 독립 초안은 기존 단일 계정 초안 자동 동기화를 사용하지 않는다. 브라우저 저장임을 명시한다. 기존 계정 초안과 무료 재작성 경로는 유지한다. 새 초안은 parent 없는 1 Credit, 기존 결과의 rewrite는 parent 있는 0 Credit 견적을 사용한다.
- 저장된 완료 영수증의 복원만으로 자동 이동하지 않는다. 이번 화면에서 실제 접수한 요청의 전체 완료 자동 이동은 유지한다. 이전 미완료 요청/정산/재처리는 기존 ID 그대로 보관한다.
- History query `?exam=<UUID>`는 exact ID 필터이며 다른 시험 성장 요약을 노출하지 않는다. 기존 결과 페이지/부모 연결은 수정하지 않는다. Legacy Essay 조회에도 기존 exam ID를 읽어 문자열 추측을 피한다.

보존 질문 7개: (1) 새로 발생하는 것은 브라우저 작성 세션/생성시각이며 평가 사실 아님. (2) 기존 제출/평가 원본과 key 보존. (3) 기존 초안 UPDATE 대신 독립 namespace. (4) auth owner+exam ID 격리. (5) Learning 작성 흐름이며 Decision/Outcome 아님. (6) 기존 사용자 브라우저 저장 범위, 신규 서버 수집/권한 확대 없음. (7) UI 선택/초안 index를 점수·성장 사실로 저장하지 않음. [장기 데이터 원칙](longitudinal-learning-admissions-data-strategy.md), [기존 회차 정책](decisions.md) 유지.

검사: typecheck PASS, lint 오류0/기존 Math effect 경고2, 관련 9파일37검사 PASS, Production build PASS. 합성 테스트에서 기존 초안 보존·독립 세션 복원·시험 ID 필터·오류 재시도·신규1/재작성0 견적 분리 확인. Provider/평가submit/SQL/Worker/Secret/APP 변경0. 실제 운영 화면 확인과 배포 정보는 아래에 기록한다.

복구 기준: 직전 정상 Pages `48b95117-75fe-488e-a7bc-6fb243778da1` / WEB `b62b123`. DB/Worker 롤백 불필요. 신규 초안 key는 삭제하지 않으며 구버전 UI에서는 별도 초안 조회 메뉴가 없으므로 복구 시 그 한계를 안내한다. 최신 uuid64 공개범위 parser가 없는 더 오래된 WEB으로 복귀하지 않는다.


운영 확인 결과: WEB `b49d52f2f482e4412052a30064d21f3e097d6812`, Pages `460e65a3-30fc-4300-9c1a-71bbfff1aa48` production/success. WEB Push·Remote SHA 일치. Worker `e85c587b-46fe-4abd-b871-3c84eb4305d7`는 이번 작업 변경 없음.

대표 일반계정에서 한양2026수시 인문 **오후1**(exam `e4969922-c133-5f7d-ae8d-fc50ba389066`)을 확인했다. Owner 문구 ‘오전1’은 현재 운영 선택 목록에 없어 임의 명칭/ID 수정 없이 이 차이를 기록한다. 자동 이동 없이 모달, exact exam History 기존run `798712a6-29b5-4220-b214-11a088cab176` 한 건, 같은 결과 페이지, 기존 재작성0Credit 표시를 확인했다. ‘새로 작성’ 빈 입력→로컬 저장→서버 신규1Credit 확인창→취소(최종 제출 없음). 기존 작성 세션에서 원래1,314자 답안/완료 접수 영수증 복원, 자동 결과 이동 없음 확인. 확인용19자 문구는 신규초안에서만 사용한 뒤 빈 값으로 복원했다. 기존 기록/답안 미변경, Credit7→7. 400px 모바일과 PC 모달 배치 확인. 실기기 APP/새Provider E2E는 수행하지 않았다.

추가 초안 전환 보완 후 gate3검사·Production build PASS. 새 UUID 초안은 같은 브라우저에서만 복원하며 계정 간/기기 간 신규 초안 동기화는 추가하지 않았다. 운영 증거는 materials `essay-validation-2026-10/exam-reentry-20261026/{web-checks.json,deployment-final.json,web-build.log}`. SQL 적용/재실행할 항목 없음. Owner 다음 확인: 위 한양 시험 재선택→새로 작성/기록 확인. 기존 인하34회차 STANDBY와 다른 대학 공개 상태는 유지한다.

## 2026-10-26 — 실패 재처리 진행 모달·직접 버튼

Owner 추가 요청: 결과 화면에서 기존0Credit 재처리를 누르면 공통 진행 모달을 즉시 연다. 요청 전송 중에는 ‘재처리 요청 중’과 비정량 애니메이션, 이후 실제 서버 문항 상태를 표시한다. 결과 화면에서 ‘첨삭 진행 상태 보기’로도 열 수 있다. 답안 화면에서 모달을 닫아도 서버 retry_allowed일 때 붉은 ‘다시 시도 · 0 크레딧’을 하단에 표시한다. 모달에도 동일 버튼을 제공한다. ref 잠금으로 중복 클릭 차단, 기존 runId/멱등키/서버 retry API 재사용. 성공 문항·History·Credit 정책과 DB/Worker/Secret/APP 변경 없음.

보존 검토7항목: 기존 실행·관찰시각 유지; 원본 checkpoint 재사용; 저장 UPDATE 추가 없음; 기존 사용자 소유 조회; UI 상태를 학습 성과로 저장하지 않음; 기존 인증 범위 유지; 서버 상태 외 가짜 진행률/완료 생성 없음. 기존 회차 정책/완료 결과 통합 결정을 따른다.

WEB ea7768c3243eeb603900ae9f97f500a06bfc1940, 원격 일치. Pages185a0fb9-60ec-4014-8760-67ada1e312b3 production/success 확인. Typecheck/build 및 관련17검사 PASS. Lint 오류0, 기존 effect2경고 및 테스트 미사용인자2경고. 일반계정 기존 인하 요청 결과에서 모달 열기·1/3완료·실패2문항·0Credit 버튼 실제 표시 확인. 실제 재처리 클릭/Provider 호출/추가 Credit 예약0; 요청 전송 중 모달은 합성 UI 검사로 확인. 모바일 실제 확인은 미수행. 복구는 직전 Pages00f8c3a8-b101-42d1-a112-bc74396da892, DB/Worker 복구 불필요.

## 고려대 카드 안내 삭제 — 2026-10-26

Owner 요청으로 대학 목록 고려대 카드의 ‘인문 4회차 · 2025 수시 오후는 문제 2만 공개’ 문구만 삭제. 실제 시험 공개 범위·서버 승인·첨삭 연결 불변. WEB2b1368d, Production build PASS.
Pages 7d350495-8266-4df6-a064-7e12edcc9cae production/success API 확인.

## 고려대 무료 재작성 문항·안내 복구 — 2026-10-26

기존 고려2026수시 인문 오전 완료 run9819b85d는2문항이며 자식 재첨삭 요청 없음 확인. 기존 UI는 문제2를 문항탭 뒤에 숨겼고 ScopedExamSubmit은 비어 있는 답안을 제외해 무료 재첨삭의 최초 문항 집합과 달라지는 요청을 만들 수 있었다. 문제1만 작성된 운영 화면의 ‘문제2 이번 제출에서 제외’/일반 오류 문구 확인.

ExamRewrite는 최초 제출 문항 모두를 동시에 표시하며 기존 draft key/이전답안 명시 불러오기 유지. 무료 재첨삭에 필요한 미작성 문항이 있으면 문항명·이전답안 불러오기 안내와 비활성 버튼 제공. 두 문항 준비 후 기존0Credit 견적/확인 경로로 진행한다. 최초 유료 부분 제출 정책·기간/횟수/서버 승인 불변. 기존 답안/결과/시각/사용자 소유권/학습이력/파생사실 저장을 변경하지 않으며 새 수집·DB UPDATE 없음.

WEB d03f4f4, typecheck/build·관련20검사 PASS, 변경 코드 lint 오류/경고0. 실제 Provider/최종 제출/차감0. 복구는 이전 Pages7d350495-8266-4df6-a064-7e12edcc9cae.
Pages 7e8db0c7-0b28-4701-a546-17e41be731c9 production/success 확인.
운영 동일 계정/회차 재작성에서 두 textarea 동시 표시, 기존 문제1 749자 복원·문제2 빈 초안 유지, 문제2 준비 안내 및 버튼 비활성 확인. 학생 답안 입력/이전답안 불러오기/최종 제출은 대신 실행하지 않았다.

## 2026-10-26 — 완료 결과 화면 브랜드·섹션 통합

Owner 결과 화면 전면 개선 지시를 기존 ‘완료 직후/History 공통 결과’ 결정에 연결했다. ExamDetail의 동일 owner-scoped Report를 ExamResultLayout에서 표시하며 EvaluationReport·EvaluationComparison·VoiceFeedback·UniversityLogo·기존 브랜드 설정을 재사용한다. 대학 히어로, 실제 제출 문항 수/날짜/최초·재첨삭 구분, 6개 섹션 탐색, Registry ID 기반 문항명·순서, 첫 문항 기본 펼침과 나머지 접기, 강점/보완/우선수정 색상 구분, 제출 정보와 다음 단계 영역을 추가했다. 새 요약/종합 점수/기준/기한은 생성하지 않는다. 무료 재작성은 서버 free_rewrite_available=true일 때만 활성화하며 기존 ExamRewrite/0Credit 경로를 유지한다.

보존 검토7항목: 기존 원본 답안·결과와 발생시각 유지; 학습 기록 append/update 없음; UI 선택 상태만 메모리 보관; 기존 owner 조회/RLS 유지; UI 표시를 성과 데이터로 저장하지 않음; 수집·권한 범위 확대 없음; 없는 평가/기한/이미지를 생성하지 않음. DB/Worker/Secret/APP/정산 변경0. Provider/첨삭 제출/차감0.

Typecheck·변경 파일 ESLint·관련11 UI 검사·Production Build PASS. 문항 정렬/배지 대비 보완 후 관련2검사·Typecheck/build PASS. 운영 일반계정 고려2026수시 인문 오전 기존 재첨삭 결과(3ce8cbdb…) 2문항·서버 무료재첨삭 불가·문항별 접기·성장 비교2개 확인. PC와 모바일400px 단일열, scrollWidth=innerWidth=400 확인. 기존 결과의 내용은 변경하지 않았다. 최초/재첨삭 공통 컴포넌트 경로를 유지하며 새 평가 검증은 수행하지 않았다.

제한: 회차 결과 조회 응답에는 원본 사진 미리보기 URL이 없어 Math 결과의 저장된 수식·텍스트를 표시하고 원본 사진 미제공을 안내한다. 사진 확대/순서 미리보기는 미완료이며 기존 소유권 검증된 사진 조회 경로를 재사용하는 후속 작업이 필요하다. 사진을 재업로드하거나 로컬 초안을 결과 원본으로 대체하지 않았다.

WEB 7b5a7c4461fdc08b2ca51d39e9fd83ff8dad0c13 Push/Remote 일치. 복구는 직전 정상 Pages7e8db0c7-0b28-4701-a546-17e41be731c9 / WEBd03f4f4. SQL 적용/재실행/롤백 없음.
최종 Production Pages f6e70e92-7296-47f9-a26b-b054ba01afdb production/success, branch main/WEB7b5a7c4 확인. 중간 preview0c3ace1b는 운영 배포로 계산하지 않았다. 최종 운영 재조회에서 문제1→문제2 순서, 문제1 펼침/문제2 접힘, 재첨삭 배지 브랜드색 대비 확인.

## 2026-10-26 — WEB 사진 입력을 이미지 첨부로 통일

Owner 승인: PC·모바일·태블릿 WEB 모두 ‘답안 이미지 첨부’ 하나로 제공한다. 기존 사진 촬영 버튼과 capture 속성을 제거하고 촬영 후 사진 선택 안내를 추가했다. 기존 파일 검증·미리보기·교체/삭제·순서·초안·추출/사용자 확인은 유지한다. APP 촬영/첨부 UI는 변경하지 않는다. 이전 WEB 촬영 버튼 결정은 이 범위에서 대체한다.

WEB c728eee84d9c6c4d96b8271a47444c81a950c05d Push/Remote 일치. Pages 8ce7a7fe-7c3d-4dd3-8036-bbb3821f5fe4 production/success 및 해당 commit을 API로 확인했다. 관련 UI7검사·Typecheck·변경파일 ESLint·Production Build PASS. 로컬 Node24와 선언된22 차이 경고는 있었으며 검사는 통과했다. 실제 카메라/파일 선택창의 기기별 수동 확인은 수행하지 않았다. Provider 호출·Credit 처리·DB/Worker/Secret/APP 변경0.

복구: 직전 WEB f45e40b / Pages ca6a181e-a7b1-4fab-a759-75629cae3ac2. SQL 없음. 학생 사진/답안/History는 수정하거나 삭제하지 않았다.

### 첨부 버튼 크기 보완

Owner 화면 피드백에 따라 전체 폭 첨부 버튼을 내용 너비·왼쪽 정렬·높이44px 버튼으로 축소했다. 아이콘/문구 한 줄, 안내문 보통 굵기/회색 적용. CSS만 변경, Production Build PASS. WEB5da2d0e Push 후 Pagesd8c01203 운영 배포. 실제 운영 인하2024수시 자연 오전 화면에서 작은 버튼·안내문 확인, 사진/답안 입력·제출하지 않았다. 기능/APP/DB/평가/Credit 변경0. 복구는 WEBc728eee / Pages8ce7a7fe.

## 후속 성장·기록 통합

[2026-10-26 성장 대시보드·통합 History/결과](essay-growth-history-ui-20261026.md)에서 기존 결과 컴포넌트와 URL을 재사용한다.
