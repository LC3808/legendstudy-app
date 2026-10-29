# APP Device QA follow-up — 2026-10-30

Owner 2026-10-29 지시, 기준 iOS 1.0.1(28). 기존 [LAB 디자인·결과 정리](app-lab-refinement-20261029.md), [성장 정책](essay-growth-history-ui-20261026.md), [장기 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 이어간다. 운영 DB/Worker/Provider/Credit 접근·변경·평가 제출 없음. 실기기 설치/스토어 제출 없음.

## 원인과 수정

- 평가 전문: `approved_result_adapter.dart::approvedEssayEvaluation`의 개선/하락 요약이 `shortCriterionTitle`과 단계 변화만 만들고 있었다. 전체 criterion 이름 + 실제 저장된 feedback을 전달하도록 수정. `ResultTextDisclosure`는 동일 Text의 maxLines를 접힘3/펼침무제한으로 바꾸며 미리보기/전문을 중복 생성하지 않는다. 원본 결과와 점수는 불변.
- 음성: `essay_voice.dart::_EssayVoiceState`는 이전에 native start 전에 playing=true였고 iOS playback category 설정이 없었다. shared AVAudioSession/playback/defaultMode/volume1 설정, 시작 콜백 전 준비 상태, 완료·취소 콜백 기반 큐로 변경. 설치된 flutter_tts iOS 구현의 didCancel은 awaitSpeakCompletion pending result를 해제하지 않아 앱 Completer로 stop/pause 시 대기를 해제한다. 시작8초/호출15초/청크완료10분 timeout은 실패 안내이며 자동 재시도하지 않는다. 백그라운드에서 중지하고 자동 재개하지 않는다. 실제 iPhone 무음 모드/스피커/Bluetooth 출력은 미검증.
- 텍스트: `result_disclosure.dart::displayEssayText`와 `essay_pages.dart::_diagnosis`에서 표시만 정리. 긴 비종결 설명의 단일 줄바꿈 일부를 공백으로 연결하고 빈 문단·번호·준거·글머리표·수식/표 경계를 보존한다. 원문에 들어 있는 추출형 줄바꿈을 기존 Text가 그대로 표시한 경로를 확인했으며, 원본 PDF 추출 단계에서 발생했는지까지 이번 작업에서 확인하지 않았다. 좁은 화면의 자연스러운 한글 줄바꿈은 오류로 간주하지 않는다. 단어 합치기/삽입된 준거 위치 추정/원문 변경은 하지 않는다.
- 평가기준: `GrowthCriterionTitle`은 짧은 첫 줄을 제목으로 쓴 경우 같은 첫 줄만 본문에서 제외한다. 모든 기준 본문은 기본 접힘, 왼쪽 정렬. 그래프와 기존 평가 단계는 유지.
- 결과 UI: `shared_history_page.dart::_Result`에서 추가 첨삭 버튼 아래16dp 간격, `ResultAccordion`에서 미세한 회청색/음성 연오렌지 배경, `ResultPdfButton`에서 오렌지 테두리·연한 강조색 적용. PDF 생성 로직 불변.
- 빠른 이동: `goToEssayHistory`는 imperative 상세 스택을 popUntil(first)한 후 기존 GoRouter `/lab/essay/history`로 이동. 상단 기록 아이콘(툴팁/접근성 이름 “나의 첨삭 기록”)으로 제공해 좁은 화면·큰 글자에서 제목과 충돌을 피한다. AppBar 기존 뒤로가기 유지.
- 진행: `source_catalog_page.dart::ExamSubmissionPanelState`은 실제 processing 문항/회차에서만 StepProgressBar 반복 표시. `ProcessingGuidance`는 대기 안내 두 문장을6초마다 교체하며 임의 퍼센트·가짜 상세 작업 단계·완료를 생성하지 않는다. 대기/실패/완료에는 반복하지 않는다.
- 종합 단계: 현재 `EvaluationReport`/승인된 essay 결과 reader에는 숫자형 종합 단계가 없다. 문자열 종합평가를 유지하고 항목 평균/가짜 전체 별점을 추가하지 않았다. 운영 원문 전체를 새로 조회한 검증은 아니다.
- 성장: `essay_growth_page.dart::changePage`는 expandedId를 빈 값으로 재설정한다. 최초1페이지 진입만 최신1개 펼침, 이후 이전/다음 전환은 모두 접힘. 사용자 직접 펼침·5개 페이지·기존 그래프 계산 유지.

## 자동 검증

- Flutter3.47.6 Analyze: **0 issues**.
- 전체 Flutter Test: **1226 PASS / 7 SKIP**. SKIP은 기존 환경 의존 검사이며 실기기 검증으로 취급하지 않는다.
- 새 `test/essay_device_followup_test.dart`: 9 PASS. 긴 실제 전달 필드 보존, 짧은/긴/줄바꿈 본문 반복, 기준 제목 중복, 구조 보존, processing 안내, 직접 History 스택, TTS 준비/시작/일시정지/재개/완료/오류/timeout/백그라운드 검사.
- TTS는 MethodChannel 모의 응답이며 iOS category API 인자는 테스트 엔진으로 검증한다. macOS 호스트 flutter_tts의 Platform.isIOS 가드 때문에 실제 AVAudioSession·음향 출력 검증이 아니다.
- `essay_refinement_test.dart`: 6/10/11시험 페이지 이동 후 접힘 및 이전 페이지 복귀 접힘 보강. 기존320/360/390/430dp·글씨2배·성장/무료재첨삭/Observation/소셜/Credit·History 계약 검사는 전체 suite 범위에서 통과. 운영 무료/유료 평가를 호출하지 않았다.

합성 Flutter PNG(결과/성장 목록/비교 그래프)를 렌더링해 카드와 본문 정렬·접힌 기준/그래프 배치를 확인했다. 실사용 평가 데이터나 실기기 캡처가 아니다.

## 보존 검토 일곱 답변

1. 새로운 historical fact 수집 없음; UI 표시 상태만 변경. 2. 원본 평가/답안/기준은 그대로 두어 재현 가능. 3. DB UPDATE와 원문 덮어쓰기 없음. 4. 학생 identity·소유권 경로 불변. 5. Learning 결과 표시 개선이며 Decision/Outcome 생성 없음. 6. 새 개인/집단 분석 및 외부 전송 없음; TTS는 기기 엔진. 7. 표시 정규화/단계 문구는 projection이며 원본에 저장하거나 종합 점수로 취급하지 않는다.

## 빌드·롤백·남은 검수

서명된 다음 검수 빌드29 준비 중. 28 보존. 완료 영수증과 정확한 소스 SHA/경로는 빌드 검증 후 이 절에 기록한다.

롤백은 보존한28 앱을 동일 Bundle ID로 업데이트 설치하거나 이번 소스 변경만 별도 revert한다. 앱 삭제/로그아웃/기기 데이터 초기화/운영 복구 SQL은 필요하지 않다. 실제 음향, 실기기 반복 펼침·큰 글자·PDF 저장·외부 오디오 장치 확인은 Owner 검수 대상이다. 불확실한 PDF 문단/단어 경계와 준거 삽입은 의미를 추정해 고치지 않았다.
