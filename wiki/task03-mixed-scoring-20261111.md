# 작업03 — 5개년 확장·단답형·검수 계약

2026-11-11. **PARTIAL: 코드·격리 검증 완료, 공식 전체 정답/배점·추가 등급컷 원본 검수 미완료.**
운영 DB/RPC/WEB 변경·앱 설치·스토어 제출0. 현재 iPhone APP71과 APP67 원본 보존.
이 문서는 [기존 커버리지 감사](task03-mock-five-year-audit-20261111.md)의 후속이다.
이전 객관식 계약은 [scoring v1](mock-exam-scoring-v1.md), 저장·재시도는
[scoring storage](day-8-scoring-storage-proposal.md)를 계속 사용한다.

## Owner 추가 결정과 범위

2022~2026학년도6·9월·수능15시험 + 기존2027학년도6·9월2시험 유지.
기존 객관식 엔진을 유지하면서 수학 단답형, 복수정답/정정, 문항별 배점 검증을 추가한다.
READY만 채점 제공; PARTIAL/NOT_READY는 비활성화한다. 없는 점수·영역은 추정하지 않는다.
오답노트는 데이터 계약 검토까지이며 UI/구독 구현은 제외한다.
학교 순위 화면은 Owner가 APP71 검수 완료로 회신했다. 그 UI는 이번 채점 작업에서 바꾸지 않는다.

## 실제 자료와 검수 현황

운영 읽기 감사: answer_key_versions0 / exam_questions0 / grade_cutoff_versions0,
참고 grade_cutoff_references2457행(11시험). **운영 실제 채점 가능0시험.**
17시험417개 활성 Registry 과목을 다시 대조했다. 이는 선택과목·홀짝형별 완전한 시험지 수가 아니다.
[과목별 검수표](../data/mock_expansion/task03/verification_coverage.json)에 417개 원본 ID를 보존했다.
현재 READY0 / PARTIAL1 / NOT_READY416. PARTIAL1은 2022수능 생명과학Ⅱ의 정정 근거만
확인한 상태이며, 그 과목 전체 정답/배점을 검수했다는 뜻이 아니다.
모든 과목의 답안·배점·선택과목 매핑 검수 완료는 false이며, 전체 시험의 채점은 비활성 상태다.

|학년도|시험 월|Registry 과목|첨부 링크|정답·해설 명칭 링크|기존 참고 등급컷 행|READY 시험|
|---|---:|---:|---:|---:|---:|---:|
|2022|6|26|47|21|0|0|
|2022|9|21|44|21|0|0|
|2022|11|26|47|21|0|0|
|2023|6|26|46|24|0|0|
|2023|9|26|47|24|0|0|
|2023|11|24|50|24|0|0|
|2024|6|26|47|24|216|0|
|2024|9|21|44|21|216|0|
|2024|11|24|50|24|216|0|
|2025|6|21|44|21|216|0|
|2025|9|26|47|21|216|0|
|2025|11|24|50|24|216|0|
|2026|6|21|43|21|216|0|
|2026|9|24|49|24|216|0|
|2026|11|24|49|24|216|0|
|2027|6|24|48|23|216|0|
|2027|9|33|67|33|297|0|

[17게시글 첨부 목록](../data/mock_expansion/task03/source_inventory_all.json)819개는 링크 확보이며
PDF 내용·공식 정답·배점 검수 완료 수가 아니다. 기존 PoliteFetcher/parser를 재사용했다.
2022/2023 영어 문제·해설 대표 PDF를 로컬 추출했으나 해설 제공자 자료만으로 KICE 공식
정답 대조 완료를 주장하지 않는다. 운영 자료나 학생 답안은 새로 생성하지 않았다.

2022수능 생명과학Ⅱ 정답 취소·재산출은 [평가원 공식 입장](https://www.korea.kr/news/policyNewsView.do?newsId=156486634),
20번 식별은 [국가법령정보센터 판결문](https://www.law.go.kr/LSW/precInfoP.do?precSeq=219611)으로 확인했다.
[정정 검수 목록](../data/mock_expansion/task03/correction_watchlist.json)에 이전5번 정답표 사용 금지를 기록.
해당 문항 배점·다른19문항·정정 후 등급컷은 아직 검수 대기다. 다른 시험의 정정 없음도 추정하지 않는다.

## 등급컷 추가 준비

2022·2023의6게시글에서 이미지121개 확보: 표114개, 표지6개, 동일 해시 중복1개(1487사회문화).
[검수 대기 후보](../data/grade_cutoffs/task03_pending/ocr_candidates.json)는 OCR로 읽힌909등급 행이다.
완성 등급컷 행 수가 아니다. 24표에 숫자·행 누락·Registry 매핑·정정 후 값 확인 등의 검토 표시가 있다.
모든 표 `PENDING / publishable=false / verified_at=null`, 신규 검수 완료 등급컷0행.
원점수/원점수 범위/표준점수/백분위를 개별 셀로 분리하고 원문 토큰·원본 해시/URL을 남겼다.
원본이 빈칸인 국어·수학 원점수나 없는9등급, 이미지에 없는 영어·한국사는 값을 채우지 않았다.
확정/추정이 아직 대조되지 않은 값은 unspecified이며 확정으로 승격하지 않는다.
[출처 해시](../data/grade_cutoffs/task03_pending/image_sources.json),
[오프라인 추출 도구](../tool/extract_task03_cutoff_candidates.py).
로컬 원본/Apple Vision OCR은 `.local/task03/assets`, `.local/task03/ocr`에 있다(미커밋).

APP `supportsGradeCutoff`와 시험 조회 하한은2022로 넓혔다. 기존 RPC가 반환한 공개 행만
표시하며 없음은 기존 빈 상태로 표시한다. 기존2024~2026 및2027 corpus를 수정하지 않았다.
조회용 references를 자동채점 minimum_scores로 복사하지 않는다. 표준점수/백분위를
원점수와 비교하거나 표준점수에서 원점수를 역산하지 않는다.

## 구현

- 기존 `scoreMcq5` 계산은 그대로 보존. `mixed-v2`만 타입별 정답을 처리한다.
- 객관식 학생 입력은 단일1~5, 공식 허용 정답은 복수 배열 지원.
- 단답형은 정수0~999, 빈칸null과0 구분, 음수·소수·문자·4자리 붙여넣기 거절.
  각 실제 시험의 허용 입력 범위는 공식 시험지와 다시 대조한 뒤 READY 처리한다.
- `all_credit=true`는 빈 답안에도 배점을 부여하되 실제 빈 답안 자체는 보존.
- 기존 타이머, 일시정지/마감, 로컬 직렬 저장, Guest/회원 제출/복구 흐름을 재사용.
  저장 실패 시 잘못된 숫자 표시를 복구한다. 시험 중 모델에는 정답을 넣지 않는다.
- 채점 결과에는 숫자/복수정답/전원정답을 타입에 맞게 표시한다.
- 기존100건 채점 목록 제한을 페이지 조회로 고침. 과목 메타데이터40개씩 조회,
  페이지 실패·중복·누락은 부분 목록으로 성공 처리하지 않는다(상한2000개는 명시적 실패).
- `READY/PARTIAL/NOT_READY` 캐시 왕복 보존. 새 계약은 READY만 답안 시작 허용.
  기존v1은 원래 publication verification guard를 유지한다.
- [SQL 후보](../supabase/candidates/task03_scoring_v2/README.md)는 추가 컬럼·분기 엔진·기존 RPC
  확장안이며 운영 미적용. 실제 시험 데이터/공개 SQL은 없다.

## 오답노트 확장 계약 검토

|정보|기존/후보 연결|제한|
|---|---|---|
|사용자·시도·시험|mock_exam_attempts.user_id/id/exam_subject_id → immutable answer_key_version → content_item_id|본인 RLS 유지, Guest는 로컬 기록|
|학년도·시험 종류|현재 Registry exams 연결|미래 notebook 출시 전 당시 academic_year/exam_type/elective/교육과정 snapshot 계약 추가 검토 필요|
|과목·선택과목·형|exam_subject_id + paper_variant + answer_key_version_id|변경 가능한 표시명 대신 검수된 ID/형을 기준으로 연결|
|문항|question_number + 새 question_id UUID|검수된 같은 문항은 정답 버전이 바뀌어도 ID 유지, legacy에 임의 backfill 없음|
|학생/공식 답|submitted_answer + accepted_answers_snapshot + all_credit_snapshot|정답 정정은 새 key version, 과거 결과 재채점 금지|
|정오·점수|is_correct / points_snapshot / awarded_points|저장 당시 검증·계산 결과|
|단원/영역/유형|unit/domain/item_type nullable snapshot|출처가 없으면null, 자동 추정하지 않음|
|출처·시각|key/cutoff version, digest, source_url, verified_at, submitted_at|단순 OCR 확보와 공식 검수 구분|

기존 본인 attempt 상세 조회로 문항 단위 결과를 복원할 수 있다. 여러 attempt의 틀린 문제를
페이지로 묶는 조회, 해설 자산 연결, 재풀이 계보, 당시 학년도 맥락 snapshot은 후속 계약이다.
이번 단계에서 해당 API/UI가 구현됐다고 하지 않는다. 현재 결과는 연습 결과이며 공식 수능 성적이 아니다.

### 보존 설계 7문항

1. 사실: 학생의 특정 시점 답안 제출/빈 답안과 당시 정답 버전. 제출·검수·정정 시각을 구분한다.
2. 복원: immutable key/cutoff/attempt와 문항 snapshot으로 결과 복원. 당시 학년도/교육과정 전체
   snapshot은 위 표의 후속 GAP이며 mutable Registry만으로 완전 복원을 주장하지 않는다.
3. UPDATE 손실: 기존 답안/정답 결과를 덮어쓰지 않는다. 수정은 새 key version, 공개 상태만 변경.
4. 학생 identity: 기존 auth user_id/RLS를 재사용, 학교/학년 변경이 기존 시도 주체를 바꾸지 않는다.
5. 층위: Learning 연습 행동과 파생 평가 결과. 입시 Decision/공식 Outcome과 섞지 않는다.
6. 권한: 기존 본인 조회/삭제 계약 유지, 추가 외부 학생 데이터 전송·수집 없음. 실제 학생으로 시험하지 않는다.
7. 파생: 원점수·정오·등급은 버전과 출처를 동반한다. 미확보 표준점수/백분위/단원을 생성하지 않는다.

## 검증 증거

- Flutter 집중92개 PASS: 기존 객관식/결과/등급컷 UI 포함, 신규18개(공유SQL/Dart5벡터,
  숫자0/999·빈칸·복수정답·전원정답, 미검수 차단,201건목록, 저장실패, Guest/회원 복구·마감).
- Flutter analyze: No issues found.
- PostgreSQL17 일회용 DB PASS: 기존v1 시도 적용 전후 보존, 신규READY/권한/불변성/오류/
  재시도/소유자 검사. 실제 운영 전체 migration clone 검증은 미수행.
- 공개 전 package/Registry/OCR 후보 검사 Python7개 PASS. 검증 도구는 근거의 완전성을 검사하며
  실제 원문 대조를 대신하지 않는다.
- 실제 학생 채점/운영 DB·RPC 수정/새 앱 빌드·스토어 제출 없음. 단답형 실기기는 미검증.

## 다음 단계와 완료 조건

1. 17시험 과목별 문제·공식 정답 PDF와 최종 정정 공지를 대조하여 문항 수/배점 합/형/선택과목 확정.
   현재417Registry 과목과 정확한 시험지 집합은 다를 수 있어 자료 수로 READY 수를 추정하지 않는다.
2. 추가6시험 등급컷114표 원본 대조, OCR24표 문제 해결, 영어/한국사 근거 확보 및 정정 후 생명Ⅱ 검수.
   raw/std/percentile·확정/추정·없는 값 유지. 검수 완료 행만 별도 reviewed 파일로 승격.
3. 불변 key/question ID/출처 package를 만들어 오프라인 validator + 기존 publication guard로 검사.
4. 운영 전체 schema clone에서 후속 migration/ACL/PG버전과 후보 호환 검증. 운영 변경은 Owner 별도 승인.
5. 합성/검수 TEST 데이터만 연결한 iOS·Android 입력/마감/복구/결과 검수 후 릴리스 판단.

공식 전체 자료 검수와 공개 가능한 데이터 세트가 아직 없어 **확장 완료/RELEASE_READY로 보고하지 않는다.**
