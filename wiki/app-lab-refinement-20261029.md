# APP 논술 LAB 최종 UI 정리 — 2026-10-29

Owner IMG_1299–1306, 22:08/22:13 iPhone 및 22:15 WEB 참고. [기존 P0/무료 재첨삭 복구](essay-evaluation-stability-p0-20261029.md), [성장 정책](essay-growth-history-ui-20261026.md), [Native 디자인](design-system.md)을 계승한다. 이번 지시는 이전 결과 화면 개편 보류와 무한 스크롤 정책을 대체한다. 실제 운영 제출·Worker·DB 구조·과금 정책은 범위 밖이다.

## 기준 및 보존 검토

시작 LOCAL/REMOTE `3754bbd40f93ceb2a998aa8edf3854807ea46e20`, `codex/essay-evaluation-stability-p0-20261029`. 기존 `.fvmrc` 외 작업트리 clean 확인. 같은 브랜치에 후속 커밋으로 작업하며 이전 커밋/26번 산출물을 보존한다.

장기 데이터 전략의 일곱 질문: (1) 새 학습 사실/시각 생성 없음. (2) 기존 run·canonical ID·결과로 재현. (3) 답안/원장 UPDATE·삭제 없음. (4) 기존 Auth UID/owner-scoped 조회 유지. (5) Learning 표시이며 Decision/Outcome 추론 없음. (6) 개인정보 수집·공유·retention 확장 없음. (7) 회차·페이지·그래프는 화면 투영이며 원본으로 저장하지 않는다. 서로 다른 기준/척도 연결, 누락 보간, 하락 제거 금지.

## 원인과 구현

- `essay_pages.dart / _changeOverview`: 긴 문장의 앞100자 미리보기를 ExpansionTile 제목으로, 전문을 children으로 동시에 렌더링했다. **UI 중복 원인 확인**. `result_disclosure.dart / ResultTextDisclosure`는 단일 Text 노드의 maxLines3 ↔ 전체를 전환한다. 접힌 미리보기와 펼친 전문을 동시에 만들지 않는다. 짧은 문장도 큰 글씨에서3줄 제한을 적용한다. 기존 평가 원문의 반복 문장은 제거하지 않으며, overview/상세 목록의 문자열 dedup도 제거했다. 모든 대학의 저장 원문에 중복이 없다는 주장은 하지 않는다.
- `approved_result_adapter.dart`: 상세 기준 원문의 문단을 평탄화하지 않는다. 기존 검증되지 않은 배점 노출 정책은 보존. 기준 제목/feedback의 원본 DB 값은 불변.
- `ResultAccordion`: 동일 하단 구분선·왼쪽 제목·오른쪽 아이콘·본문16sp/1.6행간. 제출/이전 답안, 종합 평가, `essay_voice.dart` 음성 영역에 재사용. 음성 동작은 변경하지 않음. `comparisonDimension`의 사용자 문구는 **평가 근거 자세히 보기**로 통일.
- `shared_history_page.dart / EssayResultHeader`: 대학1회/시험1회, 문항·학습 회차·짧은 날짜를 Wrap 그룹으로 배치. T2/오후/교시 등 구분은 보존하며 기존 중복 track/session Chip 묶음을 결과 헤더에서 제거. 완료 직후 단일 run record에 없는 표시 metadata/학습 회차는 같은 owner의 history record를 활용한다. 알 수 없는 회차를 최초로 추정하지 않는다.
- `_Result`: 개별 결과의 성장 기록 공유 버튼만 제거. PDF 저장 및 다른 성장 기능은 유지. 무료/유료 작성 action·fresh entitlement 재확인·명시적 Credit 동의는 기존 코드 유지.
- `_HistoryBody`: 대학·시험 검색 입력과 긴 설명 삭제. 최신순/시험별 유지. 전체/최초/재첨삭 필터에서 `essayIsFollowup`이 learning_round>1 및 실제 lineage를 사용하여 유료3차도 재첨삭에 포함. 상태/실패재처리/완료문항 조회 유지.
- `shared_history.dart / orderedEssayEvaluations`: Registry `questions` 순서를 사용하며 metadata 미확인 항목은 원래 순서 유지. UUID로 문항 번호를 만들지 않음. History/회차 목록의 렌더링 및 기본 결과 진입 순서에 적용. 날짜·examLabel은 표시용이며 원본값 변경 없음.
- `essay_growth_page.dart`: 소개는 **논술 작성 후, 성장 변화를 보여드려요.** 한 줄. 대학/시험명을 분리한 카드. 부모가 expandedId 하나만 관리하여 최신1개 기본 펼침·다른 카드 선택 시 이전 접힘. 펼칠 때 기존 owner 결과를 읽고 캐시. 새 페이지 첫 카드만 기본 펼침, 이동 시 scroll0.
- 기존 무한 스크롤 제거. **시험 그룹 최대5개/페이지**, 이전/다음·첫/끝 disable, 5개 이하 버튼 숨김. 기존 History server cursor 소비 계약 유지. `_historyTruncated`이면 조회범위 경고와 현재 페이지 번호만 표시하여 전체 페이지 수를 만들지 않음. Production 서버 페이지네이션 신규 설치/확장은 하지 않음.
- `growth_bars.dart / GrowthCriterionTitle`: 긴 공식 평가기준은 왼쪽 상세보기로 보존, 기본 화면은 그래프·실제 단계 변화를 우선. 비교 막대는 최초/실제 과금유형(무료 재첨삭 또는 Credit 첨삭) 라벨, 회색/브랜드오렌지#FFAC14. 동일 기준에서 유지/상승/하락 실제값 표시. 1회 막대·3회이상 꺾은선 유지. `loadReports`는 문항이 빠진 회차에 null을 유지하여 회차를 압축/왜곡하지 않는다.

## Owner 무료 제출 후 읽기 확인

이번 Codex는 SELECT만 실행했다. 최초 SWU run `6ef28b49-12a5-4825-886d-548f0d9897df` completed·결과2개, snapshot MD5 `042f9a6a3c3418644430884bb233b936` / result MD5 `1e596b01ba5b48f17b8c14a07d360041`이 사전 기록과 동일. 기존 reserve(+1)/consume(-1) 한 건씩 유지.

해당 parent의 child는 **1개**, `6fe629cb-7bfd-4907-b144-439b299cfdc3`, 2026-10-29 21:57:39KST 생성/21:59:23KST 완료, 결과2개, 해당 decision에 연결된 추가 Credit posting 없음. Owner 스크린샷의21:59 2차 결과와 일치한다. Codex 평가 제출/Provider 호출0. 학생 원문은 Git에 저장하지 않음. 다른 대학 run 재실행0. APP 실화면은 Owner 제공 증거이며 Codex의 신규 실기기 E2E로 집계하지 않는다.

## 검증

- 대상 widget/회귀36 PASS: 320px·글씨2배, 반복 원문 보존/단일본문, 제목·회차·T2·교시, 공식문항순서, paid3차필터, 0/1/5/6/10/11개 시험, 이전/다음/scroll0/단일펼침/불완전조회 총페이지 숨김.
- 합성 fixture의390px Native 결과/그래프 PNG 렌더 확인. 운영 답안이나 평가를 생성하지 않음. 테스트 폰트/렌더와 실제 iPhone 화면은 구분한다.
- 최종 Flutter Analyze **0 issues**. 전체 Flutter Test **1207 PASS / 7 SKIP** (기존 운영 fixture/외부 검증 관련 SKIP 유지). 이전 요약 어미 변환을 기대하던 테스트는 원문 그대로 표시하는 Owner 정책에 맞춰 전문 보존 검사로 갱신. 초기 검증 실패를 숨기지 않고 수정 후 전체 재검사 PASS.
- 무료 재첨삭/Observation·요청키복구·실패문항재처리·완료결과·OCR·Credit계약·PDF는 전체 회귀 대상. 실제 운영 평가 호출이나 소셜 로그인, iPhone PDF 공유 sheet 조작은 하지 않는다.

## 빌드 및 롤백

로컬 QA receipt에서 최대26 확인, 27 산출물 경로 없음 확인. 다음 **1.0.1(27)** 계획. 소스 커밋 후 기존 QA config로 서명하여 source SHA를 분리 기록한다. Observation V1 및 Google/Apple/Kakao ON, com.legendstudy.app·기존 signing/환경 유지. 스토어 제출/기기 설치는 수행하지 않는다.

26 보존: `build/ios/qa-swu-rewrite-26/Runner.app`, App.framework SHA256 `9001c075b0da3314f38cecae7ad5345291d85068f9360e460efcd3319a823bee`. 문제 시 26 앱으로 되돌릴 수 있으며 uninstall/기기 데이터 삭제를 하지 않는다. 소스는 기준3754bbd로 별도 복구 커밋 가능. 이미 생성된 Owner 무료 child/History/Credit을 되돌리는 조치는 포함하지 않는다.

남은 검증: Owner iPhone에서 세 화면 실제 조작·PDF 저장/음성·대규모 실제 이력·큰 글씨 확인. 운영 History가50회차로 제한되는 계정의 무제한 전체 조회는 이번 APP UI 작업으로 해결했다고 보고하지 않는다.
