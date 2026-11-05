# TASK20 — 건국·경희 자연 전체 문항 연결

2026-11-06 · **TEST PASS / 운영 적용 승인 대기 / 전체 서비스 PARTIAL**.
APP65 내부 검수용 유지. 스토어 제출0, 운영 DB/WEB 변경0.

## Owner 결정과 기존 계약

건국2026자연 Q1만 가능한 상태는 의도된 최종 범위가 아니다. Q2–Q4와 경희2026자연 Q1–Q3의 실제 평가자료/엔진 연결을 복구한다. 준비 문구 제거/버튼 활성화만으로 완료 처리하지 않는다.
[기존 전체 문항 연결 결정](decisions.md), [Math 공통 계약](math-essay-shared-integration-contract.md), [기존 건국 연결](konkuk-service-20261021.md), [APP65 검수](task21-final-release-readiness-20261105.md)를 계승한다.
Owner는 이번 턴에 공식 문제·채점 기준·예시풀이와 합성 정상/오답의 **OpenAI TEST 외부 전송 12회**를 명시 승인했다. 처음 자동 검토가 명시적 외부 전송 승인 부족으로 거절했으나, 승인 후12회 완료했다. 학생정보/운영DB/실이용권 사용 없음. 추가 호출 승인으로 해석하지 않는다.

## 원인 및 원본 복구

운영 읽기 전용 확인: 건국 시험 `25dc068b-4672-56e1-b8df-08ee8800e2f6`에 기존 Q1 leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3`만 연결. Q1은 legacy binding이며 `essay_question_id=NULL`을 미연결로 오판하지 않는다. 경희 시험 `0a331c3e-d46b-5af3-b787-e3342e8a1ae8`에는 Math set이 없다. 두 시험의 beta `exam_scope` 행도 없으며 이번 후보는 beta 지급 정책을 변경하지 않는다.

| 대상 | 공식 문제 | 기준·출제의도 | 공식 해설/예시풀이 | 검수 |
|---|---|---|---|---|
| 건국 Q2 | 기존 발췌PDF2쪽 | 전체 공식보고서98쪽 Q2 /95쪽 Q2 | 발췌5–6쪽 Q2 | 원본 이미지·수식 대조 |
| 건국 Q3 | 발췌3쪽 | 보고서98쪽 Q3 /95쪽 Q3 | 발췌6–7쪽 Q3 | 원본 이미지·수식 대조 |
| 건국 Q4 | 발췌4쪽 | 보고서98쪽 Q4 /95쪽 Q4 | 발췌7–8쪽 Q4 | 원본 이미지·수식 대조 |
| 경희 Q1 | 기존PDF3쪽(문항카드) |4쪽/3쪽 |4–5쪽 | 원본 이미지·수식 대조 |
| 경희 Q2 |6쪽 |7쪽/6쪽 |7–8쪽 | 원본 이미지·수식 대조 |
| 경희 Q3 |9–10쪽 |10쪽/10쪽 |11–12쪽 | 기존 inventory에 빠진 예시답안 복구 |

건국 기준은 Q1–Q4가 같은98쪽에 함께 있다. 문항별로 분리하고 A+~F를 임의 숫자 점수로 환산하지 않았다. 총점23/29/31 유지. 경희는 하위 기준의 실제6+6+3+6+6+3=30,9+3+7+7+7=33,7+7+6+5+5+7=37을 유지한다. 본문 추출의 PUA 수식 문자를 그대로 실행에 넣지 않고 원본 이미지에 따라 수식을 정규화했다. 정규화·단계 구분을 새 공식 사실로 취급하지 않는다.

원본 SHA256: 건국 발췌 `17acea6adb3f17ce38dd5d31e99ca2149ebde592987cf606a41106613bf6334a`, 전체보고서 `74884de48371355d76021a2e9c714e78a46b113f5a51149cedf3b34ab6a4d988`, 경희 `8ef3db4bd42d2cd1cfa4663277a5aaf726aedbd01b457719a8a151b8a1767706`. 실제 파일 해시 검사 후 생성. 공식 본문/PDF와 응답은 ignored `.local/task20-priority-20261106/`에만 보관한다.

## 구현 및 검증

[패키지 생성기](../tool/essay_lab/task20_priority_packages.py)는 기존 Registry UUID와 문항당 leaf1을 유지한다. 기존 canonical Math tables8개에 DRAFT96행 추가 후보, 기존 Q1 수정0. LEAF profile / 소문항별 기준 / 공식 solution-step / SHA·페이지 출처 연결. [활성화 생성기](../tool/essay_lab/task20_priority_activation.py)는 운영에서 읽은 함수2개의 정확한 정의에6개 leaf만 추가한다. 함수·내용 drift 및 다른 작업의 중복 문항 연결 시 중단.

| 검증 | 결과 | 한계 |
|---|---|---|
| 신규6문항 실제 OpenAI 평가 |12/12 PASS|정상 공식풀이 기반 답안+명백한 오답 각1회; 새 손글씨/OCR/다양한 부분풀이 평가 아님|
| 반환 domain 계약 / physical 변환 |12/12 PASS|기존 WEB 어댑터 재사용|
| 실제12결과 canonical DB finalize/detail |12/12 PASS|격리 PG17, 운영 E2E 아님|
| 기존Q1+신규6문항 입력/결과/재첨삭 |7/7 PASS|합성 TEST 최초/재첨삭, 무료0 검증|
| 중복 제출/평가/패키지, 다른 사용자 접근 |PASS|다른 leaf 선등록 시 후보 적용 거절 포함|
| 원본 인문 평가·답안·원장 보존 |PASS|등록 전후 격리 hash 동일|
| 정확한 활성화·원복 SQL |PASS|격리 catalog1→7→1, 평가/원장 유지|
| 기존 Math canonical 회귀 |PASS|기존 로컬131검사 suite 실행 완료|
| APP65 관련 회귀 |31 PASS|빌드/기기 설치 없음|
| 기존 WEB Gateway/인문·Math/계약 회귀 |74 PASS|기존 source 읽기·테스트만|
| 변경 WEB 후보/일반 사용자 API mapping |7 PASS|stub auth/서버 응답; 건국4·경희3, 하나 빠지면 ready=false|

처음 real-output DB 재생은 오래된 MATH-2C fixture의 `review_status` 거절로 실패했다. 운영에서 이미 사용하는 MATH-2D/E 마이그레이션까지 격리에 포함한 뒤12결과 그대로 저장/조회 성공. 출력 필드 삭제나 validation 우회 없음. 모델 추가 호출0.
토큰: 입력57,206/출력29,245. 실제 청구액 미확인.

증거: [문항별 manifest](../supabase/candidates/task20_priority_20261106/manifest.json), [실제 모델 요약](../supabase/candidates/task20_priority_20261106/provider-quality-summary.json), [격리 적용·원복·재첨삭·결과재생](../supabase/candidates/task20_priority_20261106/isolated-contract-report.json).

## 현재 문항별 판정

| 대학 | 문항 | TEST | 운영 포함 최종 판정 |
|---|---|---|---|
|건국|Q1|PASS(기존 연결·회귀)|PASS(기존 운영 연결 유지)|
|건국|Q2|PASS|PARTIAL — 운영 미적용|
|건국|Q3|PASS|PARTIAL — 운영 미적용|
|건국|Q4|PASS|PARTIAL — 운영 미적용|
|경희|Q1|PASS|PARTIAL — 운영 미적용|
|경희|Q2|PASS|PARTIAL — 운영 미적용|
|경희|Q3|PASS|PARTIAL — 운영 미적용|

**모두 실제 일반 사용자 첨삭 가능이라는 최종 판정은 아직 불가.** 별도 운영 승인과 적용 후 WEB/APP65 authenticated 조회·실기기 진입 확인이 남는다. 실제 사용자 평가/지급/차감/결제/환불을 검수 목적으로 실행하지 않는다.

## 운영 승인안과 다른 TASK20 작업

[적용·검증·원복 상세](../supabase/candidates/task20_priority_20261106/README.md): DRAFT96행 등록 → 상태24행 활성 및 함수2개 allowlist 증분 → 기존72 유지/신규6 확인 → 최신 WEB에 후보 patch/설정 범위만 반영 → 일반 사용자 read-only 검증. 운영 데이터 원복 삭제0. SQL 정확한 해시는 [영수증](../supabase/candidates/task20_priority_20261106/private-artifact-sha256.json)에 있다.

별도 ‘수리,상경 논술 개발(최우선과제)’ TASK20-C 채팅에서도 같은6문항을 작업 중임을 read-only로 확인했다. 해당 worktree에는 변경하지 않았다. 적용 전 후보를 대조해 하나만 선택하며 중복 Registry/leaf/Provider 재실행을 피한다. 해당 채팅의 신규86시험216문항·다른11개대학 후속 작업은 이6문항 승인으로 일괄 공개하지 않는다. 다른 대학 Package 완료/실제 공개는 여기서 PASS로 주장하지 않으며 기존 TASK20-C 진행 증거로 별도 검증한다.

## Seven preservation review

1. 공식 출처 시점과 이번 정규화/검수 시점을 분리한다.
2. 원본PDF 해시·페이지·문항별 후보해시를 유지해 당시 입력을 재현한다.
3. 기존 버전 UPDATE·History backfill 없음. 신규 content IDs만 추가한다.
4. 기존 auth.users/student ownership·Registry IDs를 재사용한다.
5. 공식 평가자료와 학생 Learning History, AI 판단을 분리한다. 지원/합격 사실을 생성하지 않는다.
6. 공식 원문은 private, 학생정보는 TEST 미사용; 기존 RLS·권한·삭제/retention 계약을 유지한다.
7. 수식 정규화/파생 단계와 공식 원문을 구분한다. 모델 TEST 판정을 운영 완료나 학생 능력 사실로 간주하지 않는다.


## 2026-11-06 승인 후 운영 적용

Owner가 운영 SQL·공개 연결·WEB 반영을 승인했다. 다른 TASK20-C의 동일6문항은 공식 출처/Registry는 같지만 별도 내부 ID이며 TEST에만 등록되어 있었다. 운영 사전 조회에서6문항 기존 binding 없음 및 함수2개 baseline hash 일치를 확인하고, 이 문서의12회 검증 완료 후보 하나만 적용했다. 다른 TASK20-C 후보/TEST/신규86시험에는 변경하지 않았다.

- 승인한 SHA256 일치 등록 SQL96행 적용, `task20_priority_six_natural_release_20261106` 활성화 migration 성공. Catalog72→78, 기존72 tuple 전부 보존.
- 기존11테이블(Registry2·평가/시도3·이용권3·결제3)의 count/hash는 적용 직후와 WEB 확인 후 모두 동일. RPC owner/ACL 유지. Auth/RLS/금융 정책 변경0.
- 실제 운영 WEB `23a03b0`에서 별도 브랜치로 승인3파일 패치를 반영. WEB 소스 `8c05fd12c21b0400cda7bcf1baeb5f536bcf4af8`, Pages `c6b969ee-d858-4b1f-bf8c-cab752de8525`, 운영 deploy success 확인.
- public exams212→214 / expansion42→44 / Math72→78. 숨겨진 secret 값을 다시 쓰지 않고 명시한3변수만 증분 PATCH, 나머지 config 동일. 기존1972개 정적파일 hash와 전체 함수 라우팅 그대로 유지; 공통 API만 갱신. APP65 재빌드/교체 없음.
- 실제 운영 기준 재검사51PASS, Pages Functions build PASS. 로그인된 WEB에서 건국Q1·Q2·Q3·Q4와 경희Q1·Q2·Q3의 각 수식/텍스트 작성 영역을 펼쳐 진입 확인. 건국Q4 문제PDF4/4쪽, 경희Q3 PDF2/2쪽 정상 열람. 답안 입력/저장·추출·평가 요청은 실행하지 않았다.
- APP65는 동일API 연결 반영, 물리기기7문항 진입은 Owner 확인 대기다. WEB PASS를 APP 실기기 PASS로 대체하지 않는다. 전체 최종 판정 PARTIAL(실기기 확인 대기).

운영 근거: [적용·보존·WEB 검증 영수증](../supabase/candidates/task20_priority_20261106/production-receipt.json). 위 운영 미적용 표는 승인 이전 이력이다. 현재 각7문항 운영 연결/WEB 진입 PASS, APP 실기기 NOT_VERIFIED. 실제 지급/차감/결제/환불/Provider 추가 호출/스토어 제출0. APP58·APP65 원본 보존.
