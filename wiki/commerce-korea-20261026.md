# 상경형 정책 분리·고려대 자료 연결 — 2026-10-26

상태: **고려 인문4회차 STANDBY / 서강 예약 해제 완료 / 한양 사진 확인 대기**. 기존 [STANDBY 공통 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책), [한양 사진 확인 계약](hanyang-mixed-incident-20261026.md), [고려 문제2 예외 공개](essay-standby-expansion-20261026.md#서강고려-카드-우선-배치--고려-1문항-예외--owner-2026-10-26)를 보존한다. 이번 Owner는 고려 신규 자료 연결과 한양·서강 대표 회차 실제 평가를 승인했으나, 기존 범위 밖 SQL은 별도 승인을 요구했다.

## 상경형 최소 분리

`tool/essay_lab/evaluation_policy.py`에서 신뢰된 runtime 유형과 공식 시험 계열을 사용해 상경형 정책을 분리한다. 기존 business 정책 또는 명시적 상경/경제경영 계열만 선택한다. 이름에 수리·이미지가 있다는 이유로 Math를 선택하지 않는다. 실제 실행은 고정 패키지의 문항별 essay/math binding을 따른다. 입장·논증/자료해석 평가는 기존 문항별 공식 기준을 재사용하며 새 채점 기준·점수체계·평가 엔진을 만들지 않는다.

수정 모듈: 위 정책 모듈 추가, `cloudflare_runtime.py`의 실행 전 정책 확인, Worker `entry.py`의 admission 정책 선택. 기존 `MixedMathWorker`, `ReviewedRuntimeWorker`, checkpoint/무료 재첨삭/부모 정산/통합 History 코드는 변경하지 않았다. 자연·의예는 기존 Math/Science 실행 경계를 유지한다. 모든 유형의 독립 새 평가 시스템을 완성했다는 뜻이 아니다.

Worker Production `c2766277-c063-4ef8-8ea9-af7c841f33a9` 100%. 배포 전 entry/runtime HEAD와 운영 소스 일치 확인. 기존 bindings·Secret·공개143개·limits·compatibility 보존. 기존 성공 재실행 방지/불명확 실패 시 재평가·정산 차단 2개 검사 PASS, 정책 선택 확인 PASS. WEB `c244b76f-aafa-4301-bdb7-70b922b4cc3c` / `2fbde34` 유지. APP 빌드/화면 수정0.

## 고려대

기존 자료 폴더 공식 PDF10개(2025 모의2, 2025 수시4, 2026 수시4)와 운영 Registry10회차30문항을 대조했다. 원본 해시2개는 기존 documents에 있고8개는 신규 해시다. 파일 이름만으로 신규 시험을 생성하지 않았다. ZIP의 2027 모집요강은 시험 문제로 등록하지 않는다.

| 범위 | 회차/문항 | 현황 |
|---|---:|---|
| 2025 모의 인문, 2025 수시 인문 오전, 2026 수시 인문 오전·오후 | 4/8 | Owner 승인 SQL 적용·운영 공개·일반 계정 STANDBY 확인 |
| 2025 수시 인문 오후 | 1/2 | 기존 문제2만 예외 공개 유지. 전체회차 STANDBY 아님. runtime/과거 패키지 변경0 |
| 자연계열 | 5/20 | 시험·문항 ID 및 공식 자료 있음. 운영 math_problem_sets/math_subproblems 연결0. 수식 텍스트 PUA 존재, 기존 이미지 입력·Math 정식 연결 후 공개 필요 |

**이번 신규 STANDBY 4회차/8문항**, 기존 문제2 예외 공개1문항 별도 보존. E2E PASS가 아니라 OWNER QA PENDING이다. 일반 계정 Production에서 각 회차의 두 문항 탭, 문제 PDF 표시(4/4/5/4페이지), 입력 자동저장과 입력 후 1 Credit 버튼 활성화를 확인했다. 2026 오전은 최종 제출 전 부분답안 확인창까지 열고 취소했다. 임시 연결 문구는 원래 빈 답안으로 복원했고 최종 제출·Provider 호출·Credit 예약은 하지 않았다.

비공개 원본3개를 해시 경로로 추가 업로드(기존 모의원본1개·학생PDF4개 재사용). Owner 승인으로 정확한 학생PDF4개 SELECT 정책1개를 추가했다. 평가 입력 자동조립4회차8문항 PASS, 운영 사전검사18개 true. 격리 PostgreSQL 적용/롤백 검증은 미실행이며 PASS로 표시하지 않는다. 후보 SQL은 기존 검수상태/metadata/revision 보존, 신규 runtime4개와 정확한 학생PDF SELECT1개만 추가하며 기존146 runtime·정산/조회함수 해시를 검사한다.

적용 완료 파일: `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/commerce-korea-20261026/owner-sql/OWNER-README.md`. `precheck.sql → apply.private.sql → postcheck.sql`. Owner 승인 후 사전18 true→적용→사후7 true 완료. Worker Registry와 WEB 공개목록 반영 및 일반 화면 확인 완료. 이 SQL과 이전 성공 SQL 재실행 금지.

## 한양 대표 회차

2027 모의 상경 `68996278-1e19-5560-ac94-cf43656bf684`: 운영 read-only 재확인 및 Owner 현재 WEB 확인. 기존 사진 CANDIDATE COMPLETED1/CONFIRMED0, Essay 회차0/Math session0/평가0. 사진·수식과 ‘이 내용으로 확인’ 버튼이 정상 표시된다. Owner의 ‘사진 업로드되어 있음’은 내용 확인 완료 승인이 아니므로 임의 확정하지 않았다. 사진 확인 후 같은 입력으로 전체2문항을 제출할 예정. 신규 호출·예약0, E2E 미완료.

## 서강 대표 회차 및 실패 예약 해제 완료

2025 모의 경제경영2차 `a00991d4-bab2-51ac-a008-7de55ea1dcb9`를 선정했다. 해당 대표 후보에 기존 평가 회차가 없음을 확인했다. 공식 자료의 예시답안 사용, 신규 회차1회 제출. 이 시험은 언어논증형이며 강제 Math 전환 대상이 아니다.

요청 `5ffb9760-358c-4b15-910d-ba635ce9181e`, decision `8cdd7fb3-9a0d-434b-aa88-b13d170da0ee`. Provider 평가 응답은 받았으나 독립 검수 `INDEPENDENT_REVIEW_NOT_ACCEPTED`로 최종 결과 실패. 사유는 체크리스트에 공식 기준에 없는 **관점 적용 순서 요건**을 추가한 것. 기준 오연결/인증 실패가 아니라 출력 grounding 실패로 분리한다. 검수 우회·점수조작·반복호출하지 않았다.

q0 failed checkpoint 보존. Owner 승인 후 lease 만료+2분 확인, 기존 finish 함수로 parent failed 종료. 최초 reserve1 / consume0 / release1, 잔액 차감0·추가 예약0. WEB ‘재처리 필요’, ‘실패 문항 다시 처리 · 0 크레딧’ 확인. 성공 History·무료 재첨삭·성장 비교 PASS 아님. 기존 재처리 버튼을 누르지 않았다.

Owner의 **기존 실패 정산 함수로 예약1개 해제** 승인을 받아 실행 완료. 파일 `commerce-korea-20261026/sogang-failed-release.sql`: 정확한 run/decision/q0 failed와 모든 lease 만료+2분을 확인한 후 기존 `essay_exam_private.finish`로 실패 종료. 학생기록·checkpoint·Ledger 삭제 없음. 승인된 정확한 요청1개만 처리했다. 재실행하지 않는다.

Provider2호출(평가1+독립검수1): 입력24,401/출력3,529/합계27,930 tokens. 비용 필드는 NULL로 실제 금액 미확정. 입력 토큰만으로 임의 비용을 확정하지 않는다. 한양/고려 Provider0. 추가 재호출0.

## 오후 UI 보존·복구·다음 순서

진행 직후 화면 코드 변경0. WEB 공개목록/고려 카드 안내만 변경했다. 진행 직후 `essay-exam-submit.tsx`와 `my/essay-session-progress.tsx`의 Git 기준/파일SHA를 `commerce-korea-20261026/ui-baseline.json`에 보존. 실제 진행중→재처리필요 상태 관찰. 결과 상세 화면과 별도이며 임의 재설계하지 않았다.

1. Owner 사진 내용 확인 후 기존 한양 전체회차 제출. 중복 요청 금지.
2. 서강 예약 해제 완료. 실패 원인 수정 전 재호출하지 않는다.
3. 고려4회차 STANDBY 완료. Owner 실제 답안 검수 대기. 기존 오후Q2 정책 보존.
4. 고려 자연5회차는 기존 Math 입력/자료 연결을 준비하고 추가 SQL 범위를 별도 승인한다.
5. 서강 출력 문제는 기록을 근거로 최소 수정하되 의미 없는 재평가 반복 금지.

Worker 복구: 직전 `57dfa6c1-6bc8-4616-8dbe-78e516df727c` 버전으로 복귀(Secret/공개목록 unchanged). 고려 후보 rollback은 신규4회차만 비활성화하며 기존Q2/학생기록은 보존. 배포 복구는 실행중 요청 상태를 먼저 확인한다.

보존검토7: 발생/기록 시점 유지; 원본해시·패키지·checkpoint로 재현; 기존 학생이력 UPDATE/삭제0; 동일 인증계정/ID 재사용; QA 실행을 실제 학생 성장·합격성과로 간주하지 않음; 기존 소유권/비공개 원본 권한 유지; 파생 OCR/정책분류/STANDBY와 원본 공식사실·평가성공을 구분. 신규DB/정산구조/개인정보 수집 없음.

## 승인 후 Production 반영 및 사진 오업로드 대응

Worker `65fd5977-fbac-460a-bfc9-a38d836f6357`, WEB `758c9a18-f1a2-49b3-87f9-bd0b9e52b8ba` / source `225cc2d`. 공개목록143→147. Cloudflare binding 5120바이트 한도 때문에 Worker의 기존 JSON 배열과 함께 CSV UUID 직렬화를 지원하도록 `cloudflare_http.py`·`entry.py` 두 파일만 최소 수정했다. 같은147 UUID 일치 및 wildcard/잘못된 값 거부 확인, 기존 승인 정책·권한 검사는 유지. Secret·기타binding·limits·compatibility 보존. WEB build 1회 성공. APP 빌드0.

Owner 질문에 대한 현재 원인: 한양 사진 업로드·추출 완료와 학생 내용확인은 별도 상태다. CONFIRMED0이므로 제출 버튼이 비활성화된다. 올바른 사진인지 Owner가 확인한 후 ‘이 내용으로 확인’을 눌러야 한다. 임의 확정하지 않았다.

잘못된 파일 대책 제안(미구현): 제출 전 선택 시험·문항·사진을 같이 보여주는 확인 모달과 ‘파일 교체/맞습니다’ 선택. 단순 오답과 다른 문항 파일을 구분해야 하므로 자동 판정만으로 차단하지 않는다. 파일 교체 시 해당 사진의 추출확인을 다시 받아야 한다. 현재 화면 임의 재설계 금지 지시에 따라 제안만 기록했다.

이번 Worker 복구 기준은 직전 `c2766277-c063-4ef8-8ea9-af7c841f33a9`, WEB은 직전 `c244b76f-aafa-4301-bdb7-70b922b4cc3c` / `2fbde34`. 실행중 요청을 먼저 확인하고 신규 고려4회차만 닫는 SQL rollback과 함께 범위를 맞춘다. Secret 설정 전체 재전송 금지. Sogang 정산은 롤백해 재예약하지 않는다. 증거는 `commerce-korea-20261026/owner-sql/*.result.private.json`, `deployment-result.json`, `web-deployment.json`에 보존한다.
