# 작업03-B — 자동채점 자료 정리·운영 적용 후보

2026-11-11 · 기준 `1556b0f` 후속 · 최종 **PARTIAL**.
검증된 범위의 적용 후보는 준비했으나, 미확정9과목·generic12행 직접 채점은 공개하지 않는다.
**운영 DB/RPC 쓰기0, WEB/APP 배포0, 스토어 제출0.** 기존 APP67 및 Owner 검수APP71 보존.

[03-A 근거](task03a-official-ready-20261111.md) · [기존 엔진·오답노트 계약](task03-mixed-scoring-20261111.md) ·
[승인 SQL·원복 절차](../supabase/candidates/task03b_ready_20261111/README.md) ·
[자료·재현법](../data/mock_expansion/task03b/README.md).

## 결과

|구분|03-A|03-B|
|---|---:|---:|
|Registry 시험|17|17|
|Registry 과목 행|417|417|
|READY|372|396|
|PARTIAL|36|12|
|NOT_READY|9|9|
|검증된 선택과목/형별 정답표|412|443|
|검증된 문항(선택과목·홀짝형 포함)|10,340|11,170|
|최소1개 READY 과목이 있는 시험|16|17|
|모든 Registry 행이 READY인 시험|9|10|

372과목의412정답표 객체 및 기존 검수파일 SHA를 대조하여 보존했다. 2025수능24과목/31형/830문항 추가.
11,170은 정답표별 문항 수 합계이며 선택과목 공통문항·홀짝형을 합친 고유 문제 수가 아니다.
운영 채점 가능 시험은 현재0: 후보 READY와 운영 공개를 구분한다.
[전체 시험·과목 목록](../data/mock_expansion/task03b/verification_report.json).

## 2025학년도 수능 이미지 정답표

[LegendStudy1649](https://legendstudy.com/1649)의24개 정답·해설 PDF와 평가원 공식25페이지를 대조했다.
- 객관식 원문 기호와 배점은 셀 좌표를 고정해 전사하고, 기준 글리프/신뢰도·문항 수·총점을 검사.
- 홀수/공통24개 정답 목록은 해설 PDF의 native text와 **전 문항 정확히 일치**, 불일치0.
- 홀짝형별 배점 배열 일치. 짝수형은 홀수형 해설을 복사하지 않고 공식표에서 독립 전사했다.
  달라지는21개 실제 셀(선택과목 중복 집계28개)을 전부 시각 확인했다.
- OCR 문항번호 예외92개, 낮은 신뢰도 객관식25셀·배점30셀, 학년도/과목/형 제목을 시각 확인.
- 수학 단답형16~22·29~30은 정수로 유지. 공식 정답 발표/정정 근거도 기존 source manifest와 연결.
- 전 문항을 사람이 수동 두 번 검수했다는 주장은 아니다. 독립 해설 대조·이미지 인식·구조검사와
  예외 시각검수의 조합이며, 원본 PDF/ZIP member/hash/page/좌표로 재검증 가능하다.
[정답표](../data/mock_expansion/task03b/2025_image_papers.json) · [셀별 증거](../data/mock_expansion/task03b/image_cell_audit.json).

## 중복 별칭12행과 코드 미확정9행

**12행은 동일 문항의 중복이 아니라 선택과목 상위 묶음(1:N)**이다.
2022학년도6월·수능,2023학년도6·9월,2024학년도6월,2025학년도9월의 generic국어/수학이다.
각각 기존 화작/언매2개, 확통/미적/기하3개 Registry ID로 매핑을 검증했다.
ID·참조 삭제/병합0, generic에 중복 정답키 생성0. 해당 선택과목의 실제 READY 채점은 가능하다.
Generic만 있는 시험은 기존 ID+paper_variant 계약 유지. 직접 키가 없는12행은 PARTIAL로 남긴다.
[매핑 전체](../data/mock_expansion/task03b/alias_mapping.json).

2027학년도9월 독일어·러시아어·베트남어·스페인어·아랍어·일본어·중국어·프랑스어·한문9행은
공식Ⅰ과목명/30문항/50점/정답표는 확보·매핑 확인했다. 그러나 운영 `subject_id/code=null`이고,
기존 수집기의 `foreign:독일어` 같은 키는 인식용 내부키이지 공식 숫자 코드·정규 taxonomy가 아니다.
ZIP 앞자리01~09를 공식 과목 코드로 오인하지 않는다. canonical 코드 근거/정규매핑은 미확정이므로
**NOT_READY 유지, 이번 SQL 적재 제외**. 후속으로 공식 코드 근거와 기존 subjects taxonomy 확정 필요.
[9과목별 근거·미해결](../data/mock_expansion/task03b/foreign_mapping_review.json).

## 원점수·백분위·등급컷

- 기존2022·2023 표준점수114표1,026공식등급행과2024~2026/2027의2,457기존행 보존.
- LegendStudy114표의 원점수·백분위1,280셀을 추가 검수: **원점수816 / 백분위304 / 원문 '-'160**.
  이미지 전체 OCR와 셀 OCR을 대조하고387개 불일치/빈 셀을 시각 확인했다. 등급행 누락3개도
  원본 해당 행에서 확인했으며 보간해 점수를 만들어 넣지 않았다.
- 기존 OCR 숫자5개 정정: 33→3,76→7,61→6,50→80,96→8 오독. 원래 OCR파일은 변경하지 않았다.
- 값은 출처의 전사 사실이다. 게시글1483에 ‘확정’ 제목이 있지만 원점수별 공식 환산 근거는
  확인되지 않았다. `source_claim`은 따로 보존하고 raw certainty는 unspecified; 추정이라고도 꾸며 쓰지 않는다.
- 국어·수학 원점수160개 빈 셀은null. 원점수→표준점수/백분위/공식등급 추론 없음.
- 후보 참고행은 **1,029행**: 공식1~8등급의 유효 하한과 검수된 참고값만 기존 Registry에 연결.
  국어/수학의 공통 표준점수를 기존 명시적 선택과목별 참조에 연결해 원본 사실 행 수와 다르다.
  원점수 포함813행, 백분위 포함327행(선택과목 연결 중복 포함), 표준점수는 모두confirmed.
- 공식9등급114행은 ‘미만’, 윤리와사상8등급3행은 ‘해당 없음’. 기존 scalar 조회 계약으로
  의미를 잘못 표현하지 않도록 이번 적재에서 제외하고 원본 사실은 별도 보존한다.
- 자동 등급 계산용 `grade_cutoff_versions`에는 **0행**. 결과는 원점수/정오/획득점수와
  **‘등급 산출 불가’**. 참고표 확장과 공식 자동등급 산출은 구분한다.
[셀 검수](../data/mock_expansion/task03b/raw_percentile_review.json) · [출처·제외 사실](../data/mock_expansion/task03b/load_evidence.json).

## 운영 읽기 감사와 후보의 중요 보완

11/11 11:47 KST의 read-only transaction에서 PG17.6, 정답키/문항/채점 결과/자동등급0건,
기존 참고 등급컷2,457건을 확인했다. 이후417개 Registry 과목의 ID/부모/코드/과목명/활성 상태도
후보와 일치했다. 조회만 수행하고 매번ROLLBACK했다.
[운영 확인 증거](../data/mock_expansion/task03b/production_preflight.json).

초기03-A SQL은 initial schema를 대상으로 해서 현재 운영의 계정 생애주기 검사가 없었다.
실제 `submit_mock_attempt`의 `account_private.lock_subject/allowed` 검사를 발견하여
**03-B 생성 후보에 그대로 보존**했다. 기존 fetch/RLS/계정 함수는 변경하지 않는다.
탈퇴대기·삭제진행 계정은 신규 제출·동일요청 재시도·조회가 차단되는지 격리 검증했다.
이유 없이 Auth를 새로 설계한 변경이 아니라 운영 권한 계약을 덮어쓰지 않도록 한 보존 조치다.
과거 `task03_scoring_v2/candidate.sql`을 운영에 직접 적용하지 않는다.

## 저장 계약과 회귀 검사

기존 mcq5-v1/mixed-v2/RPC/사용자ID/정답버전/불변 결과 계약을 재사용한다.
문항UUID/학생답안/공식답 배열/전원정답/정오/배점/획득점수는 원래 버전 snapshot에 남는다.
단원·영역·유형 미확보는null, 오답노트 UI나 유료 기능 추가 없음.

- Flutter 공식443형+기존 채점/READY/참고등급컷 **522 PASS**, 학습/타이머/복구/학교/초대 **120 PASS**.
- Flutter analyze: No issues found.
- 기존03-A/preflight/03-B Python 데이터 검사 **22 PASS**.
- 기존 격리SQL:1,236점수벡터·412키 publication/submit, MCQ/단답/복수/전원정답/미응답 PASS.
- 03-B 격리SQL: 실제 운영의 대상 함수/ACL/컬럼/제약 계약을 복제한 PG17에서
  **1,329건** 만점/오답/미응답을 submit RPC로 저장·재조회 PASS.
- 동일요청 동시 제출1건 유지, payload충돌 거절, 새attemptID 재응시 독립 저장,
  사용자별 격리·계정제한·정답불변·draft숨김·재적재/재공개 no-op·충돌중단 PASS.
- 원복 후 답안/점수 hash와 기존2,457참고행 hash 보존. 새 제출차단, 과거동일요청 재조회가능;
  출처 상태만withdrawn으로 표시됨. Registry 비활성이어도 원복 가능.

이는 최소한의 합성 계정 의존 테이블을 갖춘 **대상 스키마 계약 검증**이며 전체 운영 복제나
운영 실사용자 E2E 검증은 아니다. 실제 평가/지급/차감/결제/환불/학생 제출은 실행하지 않았다.

[검사 결과 요약과 로그 해시](../data/mock_expansion/task03b/test_results.json).

## 운영 적용 요청 범위·남은 일

[정확한 순서·SQL·원복](../supabase/candidates/task03b_ready_20261111/README.md).
1. Owner 승인 후 최신 preflight 재확인·백업·잠금/생성컬럼 영향 확인.
2. 기존 계정 제한 보존 mixed-v2 SQL → draft443키/11,170문항/1,029참고행 적재 → 대조 → 공개.
3. 예상 참고행총수3,486, 기존ID/자료/사용자원장 보존. `grade_cutoff_lookup` 변경 없음.
4. 장애 시 이번 batch만withdraw/current=false. 학생 기록/증거 삭제나 typed컬럼 강제역변환 금지.
5. 미확정9과목 코드, generic12행 직접 진입 정책(실제 선택과목은READY), 공식미만/미배정표현,
   raw 공식등급환산 근거는 후속으로 남긴다. 검증자료를 임의로 메우지 않는다.
6. 승인 이후 별도 내부 앱 연결·iOS/Android 실기기 검수. 이번은 새빌드·설치·스토어 제출 없음.

## 장기 데이터 보존7질문

[기존 전략](longitudinal-learning-admissions-data-strategy.md)과03-A 검토를 유지한다.
1. 시행학년도/수집/검수/발표정정/학생제출 시각을 구분한다.
2. 원본URL·hash·member/page/cell과 불변키로 당시 답안 근거를 재현한다.
3. 원래READY/Registry/학생결과를 UPDATE하지 않고 신규 버전만 적재한다.
4. 기존 사용자ID·본인RLS·계정제한/잠금을 유지한다.
5. 채점은 Learning 사실이며 지원·합불의 Decision/Outcome과 혼합하지 않는다.
6. 공개 시험 자료와 합성TEST만 사용하며 새 개인정보 수집/권한 확대를 하지 않는다.
7. source transcription/공식표준점수/raw/백분위/확정주장/추정을 분리하고 근거 없는 파생값은null.
