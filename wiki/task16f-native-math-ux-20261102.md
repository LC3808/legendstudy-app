# TASK16-F — Native 수리논술 UX / Academic Purple

Owner TASK16-G 결정: 모바일 UI/UX PASS, 추가 디자인 개편 없음. 전체 서비스/운영 승인은 아님. [후속 통합](task16g-learning-loop-20261102.md).

2026-11-02. **Native 구현·로컬 회귀/실기기 검수 빌드 제공. 서비스 전체 완료 아님. 운영 HOLD.**

## 근거와 작업 경계

Owner의 `TASK16-F_모바일_통합_최종_지시서.md` (SHA-256 `a742b31fb5d026dc57d696782fb8ffb15f1812b6fe3688ef7f5b0c34af0af169`) 전체 0–25절 및 추가 화면 이미지가 공식 명세다. 작업 브랜치는 `codex/math-scaffolding-mobile-task16f`, 별도 Codex worktree. 기존 APP 작업 폴더의 미커밋 변경과 APP 1.0.1(41) 릴리스는 변경하지 않았다. WEB UI/운영 DB/Credit/Ledger/결제/Provider 설정 변경 없음. 새 Provider 호출 0회.

[감사](task16-commerce-social-predevelopment-audit-20261102.md), [TASK16-B](task16b-commerce-social-integration-20261102.md), [TASK16-C](task16c-math-recognition-scaffolding-20261102.md), [TASK16-E](task16e-recognition-disclosure-p0-20261102.md), [기존 학습 계약](math-essay-learning-runtime.md)을 계승한다. 건국대·한양대 Q1/Q2의 기존 실제 API 결과는 다시 호출하지 않았다. 기존 Q1의 고신뢰도 부호 오류, Q2 정상 수치/라벨 구분, 경계 답안의 조기 정답 노출 이슈는 여전히 품질 근거다. 이번 화면 예제는 공식 기출의 실제 재평가 결과가 아니다.

## A–C. 재사용·신규 구현·변경 파일

- 기존 `AnswerImagesInput`, `MathText`/flutter_math_fork, MathGateway, math_input 확인본, Math Session, math_learning, SharedEssayHistory와 기존 Worker를 재사용한다. 새 평가 엔진·새 History·새 결제 시스템은 없다.
- `lib/features/essay/math_mobile/academic_purple.dart`: 수학 화면에만 Owner 확정 색상 적용. 홈/MY/일반 인문 UI 공통 테마는 그대로다.
- `math_image_tools.dart`: 다중 이미지 입력·순서 재사용, 확대/90도 회전/범위 표시 자르기. 원본 byte는 유지하고 PNG 사본을 만든다. 새 이미지 패키지 없음.
- `math_formula_editor.dart`, `math_recognition_panel.dart`: 원본 영역/인식 수식 비교 탭, TeX 삽입 도구, 불확실 영역 표시, 영역별 확인+최종 확인. 수정 또는 후보 교체 시 확인 취소. 빈 수식·UNCERTAIN·미완성 삽입 기호로 평가 준비하지 않는다. 좌표 미확정은 전체 원본 대조로 표시한다.
- `coaching_contract.dart`, `math_coaching_page.dart`, `math_coaching_screen.dart`: 결과/개념/기록, 최대 5개 개선 과제, 누적 힌트, 공개 확인, 공식/검수/AI 풀이 구분. owner 변경 시 이전 Future 결과를 재사용하지 않는다. 새 계약이 없으면 차단 안내하며 raw Provider 결과로 fallback하지 않는다.
- `math_mobile_preview.dart`, `lib/main_math_preview.dart`: 네트워크·인증·Provider 없는 명시적 오프라인 화면 검수 엔트리. 대학 이름이 포함되어도 예제임을 표시한다.
- 기존 변경: `answer_image.dart`는 선택적 편집 버튼, `math_workspace_page.dart`와 `math_exam_session.dart`는 확인 UX, `math_gateway.dart`는 새 DTO 허용, `shared_history_page.dart`는 기존 Math evaluation ID로 결과 화면 연결. 인문 경로는 유지한다.
- 테스트: `test/task16f_mobile_test.dart`, 기존 `test/math_workspace_selection_test.dart`의 스크롤 후 HOLD 검증, `tool/test_task16f_coaching.py`.
- SQL 후보: [검토/적용/복구 패키지](../supabase/candidates/task16f_math_coaching/README.md). 자동 migration 디렉터리에 넣지 않았고 클라우드에 적용하지 않았다.

## D–I. 검증 결과와 한계

| 항목 | 결과 | 범위 |
|---|---|---|
| Flutter Analyze | PASS | 전체 프로젝트, 경고 없음 |
| Flutter Test | PASS | 1,141 PASS / 7 skip. 기존 인문논술 테스트 포함. skip을 PASS로 세지 않음 |
| 마지막 UI 변경 후 집중 회귀 | PASS | Native 8 + 기존 Math 선택/6장 업로드·재시도 3 = 11 |
| 수식 렌더링 | PASS(화면) | 기존 렌더러, 지수/분수/적분/합성함수. 기본/2배 글자 overflow 검사. 인식 정확도 PASS 의미 아님 |
| 인식 확인 | PASS(Widget) | UNCERTAIN 차단, 수정→영역 확인→최종 확인→저장, 수정 시 확인 취소. 실사진 Provider 재검증 없음 |
| 사진 처리 | PASS(로컬) | 원본 byte 유지, 회전+자르기 출력 크기, 6장 순서/업로드 재시도 기존 회귀 |
| 개선 과제/개념/힌트 | PASS(UI 계약) | 5개 초과 거부, 실제 과제 수, 누적 힌트, 접기/펼치기. 대학별 코칭 내용 품질은 별도 |
| 명시적 정답 공개 | PASS(Widget/로컬 PG) | 버튼→확인→서버 응답 후 표시. 실패 시 비공개. 공개 전 full_solution 포함 DTO 거부 |
| SQL 후보 | PASS(폐기형 PG17) | 후보 18 + 기존 Runtime 131. 소유권/익명/legacy 우회/생성문구 canary/5개/미확정/재시도/기록/원장 불변/rollback |
| 기존 학습 정책 | PASS(폐기형 PG17) | L01–L40 및 기존 부가 회귀. 무료 1회, 기간 경계, 동시성/실패/재시도 보존 |
| 클라우드 TEST 전체 E2E | 미완료 | 새 RPC 미배포, 회차/혼합형 공개 경계와 정산 반복 정책 검증 필요 |
| 실제 Provider 품질 | 기존 C/E 증거 재사용 | 이번 호출 0. UI 예제로 품질 PASS 선언 안 함 |

전체 테스트 후 원본 영역 연결·후보 변경 무효화와 표시 문구 변경은 집중 회귀로 확인한다. Git 파일만으로 DB 배포를 추정하지 않는다.

### 학생 UX

사진 입력→보정→기존 추출→원본/수식 비교→기호 수정→영역별 확인→최종 확인→기존 확인본 저장→평가 요청 순서다. 결과 화면은 임의 점수/72% 완성도를 생성하지 않는다. 개념·힌트는 선택적으로 열고 직접 수정하며, 전체 풀이에는 별도의 명시적 확인이 있다.

개선 과제 상세의 원본 영역은 서버가 확인본 region ID를 연결하고 현재 세션에 사진 byte가 있을 때 표시한다. 연결이 없으면 전체 전사본/좌표 미확정 표시를 유지한다. History 재진입 시 원본 Storage 다운로드 연결은 아직 미완료다.

### 공개 계약

`math_coaching`은 기존 evaluation/attempt/lineage를 사용한다. 공개 전에는 Provider 자유문장을 복사하지 않는 보수적 projection으로 정답 유출을 차단한다. 원본 확인 전사본은 학생 작성물이므로 공개 제한 대상이 아니다. 공개 이벤트는 기존 평가에 연결된 비공개 audit이며 독립 History가 아니다. 기존 힌트 exposure를 계속 사용한다. 열람 시 Provider 재호출 없음.

후보는 standalone raw detail/hint/learning-state 경로까지 감싼다. **혼합 essay_exam_history 및 모든 배포 소비자 호환성 감사는 미완료**이므로 전체 서버 공개 제어 완료라고 보고하지 않는다. 안전을 위한 일반 개념/제목은 대학별 공식 채점 기준과 연결된 최종 코칭 문구로 간주하지 않는다. DB 원본·기존 평가 결과는 덮어쓰지 않는다.

## J. 이용권 정책 차이 / 별도 변경 계획

Owner 정책은 1유료+1무료를 반복하고 14일/베타 종료 중 더 이른 시각을 지킨다. 현재 `math_private.learning_eligibility`와 `authorize_billing`은 lineage 안의 `MATH_INITIAL_EVALUATION`을 유료 기준으로 삼는다. 첫 무료 1회 소비/동시성 방어는 검증됐지만, 3회차가 유료 `MATH_REEVALUATION`이면 그것을 다음 무료 기준으로 선택하지 못할 수 있다. 따라서 1→2 PASS를 3→4→5→6 전체 반복 PASS로 확대하지 않는다.

별도 승인 대상 계획: 기존 billing decision/binding을 사용해 최신 settled `paid_cycle` 평가를 사이클 기준으로 선택하도록 두 함수의 기준을 일치시킨다. 새 Wallet/History를 만들지 않는다. 실제 차감 quote를 기존 Math Session 계약에 연결한 뒤 `paid_available`을 서버에서만 허용한다. 후보는 현재 false이며 무료 소진 후 임의 차감하지 않는다.

필수 TEST 행렬: 1/0/1/0/1/0 차감, 각 무료 정확히 1회, 동시 요청 1회, 336시간 직전/정각, 베타 종료 직전/정각, 잔액 부족, 환불/실패 예약 복구, 연결된 모든 attempt/History 보존. 이 금융 정책 변경 SQL은 이번 실행에서 적용하지 않았다.

## K. History / 보존 검토 7문항

1. 원본·후보·학생 확인본을 구별하고 기존 입력/평가 ID를 보존한다.
2. 평가/공개/힌트 시각은 서버 기록을 사용한다. 클라이언트 시각으로 무료 자격을 계산하지 않는다.
3. 재작성은 새 attempt와 기존 predecessor/lineage 연결이다. 기존 평가 덮어쓰기 없음.
4. Auth owner를 기존 계약으로 검증한다. 학생/학교/입시 식별 체계를 추가하지 않는다.
5. 원본 수식과 AI 판단을 구별한다. 학습 결과를 합격 가능성이나 학생 고정 수준으로 재해석하지 않는다.
6. 사진은 기존 입력·Storage 경계를 사용한다. 원본 합격자 이미지 Git 추가 없음. 공개 audit에는 이미지/Secret/답안 본문이 없다.
7. 신뢰도/오류 판단은 검증 가능한 근거와 함께 다룬다. 미확정 값은 사실로 고정하지 않는다.

기존 History에 시각·상태·힌트 수준·공개 여부를 연결한다. 새 계약의 과제 해결/잔여 과제 요약과 실제 이용권 영수증 표시를 완성하려면 안전한 서버 요약이 추가로 필요하다. 미제공 데이터를 추정하지 않고 안내한다.

## L. 기기 / 화면

Owner 지정 iPhone 12 Pro Max(기기명 `자유잍튜브`)에 **별도 bundle `com.legendstudy.app.task16f`, 이름 `LS Math TEST`** 설치. 기존 com.legendstudy.app은 덮어쓰지 않았다. 최초 Debug 설치에서 Owner가 iOS 홈 실행 제한을 보고하여 **Profile AOT 빌드로 교체**, devicectl 설치/실행 및 살아 있는 process 확인. Owner가 Profile 교체 후 “정상적으로 열림”을 확인했다. 실기기 홈 실행 PASS이며 전체 터치 UX/실제 평가 품질 통과를 대신하지 않는다. 앱 실행 시 운영 초기화/인증/Provider는 수행하지 않는다.

아래는 생성형 시안이 아닌 Flutter 렌더링이다. Simulator 캡처와 Widget 캡처를 구별한다. 예제 데이터의 수학/대학별 채점 품질 증거가 아니다.

- [iOS Simulator 실제 화면](assets/task16f/simulator.png)
- [결과](assets/task16f/result.png) · [인식 확인](assets/task16f/recognition.png) · [개선 과제](assets/task16f/task.png) · [개념](assets/task16f/concepts.png) · [공개 확인](assets/task16f/disclosure-confirmation.png)

## M–N. 인계 / 남은 차단 요소

변경 SHA는 이 문서를 포함한 feature commit 및 완료 보고를 기준으로 확인한다. current-status에 HEAD를 영구 고정하지 않는다.

1. Owner 홈 실행 확인 완료. 상세 화면·터치 UX 검수 및 피드백 반영은 계속 필요.
2. 클라우드 TEST 새 계약 배포 전 mixed/session/legacy WEB 소비자 공개 경계 정리. 신규 Native는 미배포 RPC에서 안전하게 차단된다.
3. 대학별 공식 기준 기반 제목·근거·우선순위와 검수 개념 mapping. 현재 보수적 generic projection과 시각 예제의 풍부한 콘텐츠는 동등하지 않다.
4. History에서 원본 재조회·과제 해결 상태/영수증, 전체 풀이의 공식 근거와 학생 비교 내용을 완성.
5. 반복 유료/무료 사이클 정책 별도 승인·TEST 검증. 현재 첫 무료 경계 검증만 완료.
6. 실제 사진→학생 확인→평가→재작성→재첨삭→History의 기기/TEST E2E. 기존 C/E Provider 품질 결과만 재사용했다. 표·그래프 사례의 이번 추가 실평가 없음.

WEB은 공통 DTO/SQL 설계만 공유한다. WEB UI와 운영 배포는 별도 작업이며 Owner 검수 전 운영/스토어 활성화 금지.
