# APP 통합 전 상태 보존 — 2026-10-28

아래는 병합 전 두 작업트리의 상태 기록이다. 최신 통합 상태는 [최종 통합](app-final-integration-20261028.md)을 참조한다. 과거 미병합/개발보류 문구는 당시 상태다.

## 2026-10-28 — APP 실기기 검수 후속 수정 (2차, 재검수 대기)

iPhone 검수 P0/P1 일괄 수정. §1 준비 중 안내를 inputMode(투영 누락) 대신 서버 서비스 가능 집합(`serviceExamIdsProvider`) 기준으로 전수 일치화. §2 첨삭 요청 접수 시 리뷰 시트를 진행 전용으로 전환(중첩 없음). §3 답안 확인 시험명 1회·진회색 구분선·[답안 수정][첨삭 요청] 나란히. §4 결과 라벨 '문항 정보 확인 중'→실제 문항 번호(APP); 재작성 진입 실패는 Backend 범위(run에 대학 id 없음·STANDBY 시험 카탈로그 부재)로 Codex 인수인계. §5 성장 분석 시험별 접이식 카드·최신 펼침·5개 페이지네이션. 기존 PASS 기능·계약 미변경. `fvm flutter analyze` 0·`fvm flutter test` 1142 PASS/0 fail. **미검증(실기기 QA): 제출/상태조회 HTTP(§2·§8), 크롭 래스터화. §4 재작성은 Backend 선행 필요.** 커밋 6a0f040→04ea3a5. [로그](log.md#2026-10-28--app-실기기-검수-후속-수정-2차-일괄).

## 2026-10-28 — APP UI/UX 전체 구현 완료 (일괄, 실기기 검수 대기)

Owner 최종 지시(단계별 승인 폐기)로 논술 LAB APP UI/UX 전체를 일괄 구현. §3 준비 중 안내를 시험·계열 선택 직후로 이동(공개 정책 기준), §4 문항별 아코디언(드롭다운 폐기·전환 시 답안 보존), §5 임시저장(버튼→상태·네이비 채움·누르기 전 미표시), §6 제출 확인창 디자인 개선, §7 진행 화면 재구성(큰 제목·단계바·문제별 상태), §8 runId 보존·복원·폴링 backoff·백그라운드 일시중지(100초 컷오프 제거, 재요청 없음), §9 첨삭 기록 문항 번호, §10 사진 크롭(로컬·dart:ui, 촬영/선택→크롭→미리보기→첨부), §11 상단 메뉴 한 줄, §12 성장 분석 보존. WEB·DB·Worker·Credit·History·인증 변경 0, Flutter Native UI 유지. `fvm flutter analyze` 0·`fvm flutter test` 1141 PASS/0 fail. **미검증(실기기 QA): 시험 제출/상태조회 HTTP 경로(§7·§8), 크롭 PNG 래스터화(§10). 소셜 로그인 버튼 미노출은 별도 후속.** 코드 커밋 c61a898(최종). **Codex 폴더·브랜치 미수정·미병합; 최종 통합은 Codex.** [로그](log.md#2026-10-28--app-uiux-전체-구현-단계별-승인-폐기-일괄-구현).

## 2026-10-28 — APP 2차 검수 step 1: 자연·수리논술 첨삭 준비 중 안내

자연·수리논술(사진·수식) 시험을 선택하면 답안 작성까지 진입한 뒤에야 첨삭 불가를 알게 되던 문제 수정. `_SourceWriter` 작성 영역 상단에 차분한 붉은 안내('수리논술 첨삭 서비스 준비 중', 'AI' 문구 미사용)를 추가. 노출 판정은 대학·계열명이 아닌 기존 공개 정책(`mathEvaluationAvailableProvider` + published `leaf_id`, Registry 문항 ID 기준)으로, 사진·수식(`inputMode=='image'`) 문항이 공개 전일 때만 표시. 입력 유형과 공개 상태 분리로 TEXT·혼합 시험 정책 불변. 제출 차단은 기존 서버/`_ExamSubmit`/`MathExamSession` 계약 유지(안내만 선제). `fvm flutter analyze` 0·`fvm flutter test` 1138 PASS/0 fail. WEB·DB·Worker·Credit·History 변경0. 코드 커밋 0fc745e. **Worker 장애·APP 상태관리(§12) 후속; Owner 승인 전 step 2(아코디언) 미진행, Codex 브랜치 미병합.** [로그](log.md#2026-10-28--app-2차-검수-step-1-자연수리논술-첨삭-준비-중-안내).

## 2026-10-28 — APP 실기기 검수 1차 수정 (논술 LAB 메인·시험 선택)

Owner 실기기 검수 2번 항목 한정 수정: 시험 선택 후 문항 미선택 CTA '문제 선택' 표시(REVIEW_REQUIRED 오표기 '서비스 준비중' 수정; 첨삭 불가는 '첨삭 서비스 준비 중', 대학 전체 보류는 기존 유지), 논술 LAB 상단 '나의 논술랩'(→ `/lab/essay/growth`) 추가, Credit 문구 '현재 크레딧 N개'. 공개 판정·조회/계산 로직 불변. `fvm flutter analyze` 0·`fvm flutter test` 1136 PASS/0 fail. WEB·DB·Worker·Credit·History 변경0. 코드 커밋 68d89ff. **Owner 승인 전 답안 작성 화면(다음 단계) 미진행, Codex 브랜치 미병합.** [로그](log.md#2026-10-28--app-실기기-검수-1차-수정-논술-lab-메인시험-선택).

## 2026-10-28 — APP 인문논술 LAB UI/UX 개선 (BETA)

Claude APP 전용 worktree(`claude/essay-app-beta-uiux-20261028`, 기준 733bad7, Flutter 3.47.6/fvm)에서 논술 LAB 첨삭 UI/UX 11건 개선: 제출 확인창 간소화(서버 확정 Credit 출처 1줄 표시, 잔액·수량·중복 안내 제거), 명시적 임시저장 버튼, 첨삭 진행 프로그레스바, 전용 성장 분석 화면 `/lab/essay/growth`(MY에서 진입; 기존 비교 계약 재사용·임의 수치 없음·50회차 범위 고지), 차분한 네이비 BETA 배지, 결과 화면 재구성·중복 문구 제거, 베타 Credit 안내 축약. `fvm flutter analyze` 0건·`fvm flutter test` 1136 PASS/0 fail. WEB·DB·Worker·Credit·History 변경0, Flutter Native UI 유지. **Owner 실기기 검수 대기, Codex 브랜치 미병합.** 코드 커밋 4985818. [로그](log.md#2026-10-28--app-인문논술-lab-uiux-개선-beta).

## 2026-10-24 — 5% 잔여, 신규개발·Provider 중단

Owner 지시에 따라 안정화·Claude인수인계 완료. 운영DB171시험512문항(2022이후509), 일반공개12=Essay11+Math1, 기존E2E9. WEB e67a0d37/f1a9e27·Worker c3fb54be 100% 확인, Secret/배포/DB쓰기변경0. 17호환후보 미반영, 서울여Q2무료재첨삭 품질보류/0해제. [인수인계·정확한 재개순서](essay-lab-claude-handoff-20261024.md).

성균 Q1 일반계정 최초/재첨삭1/0Credit·WEB/GalaxyS8 History PASS 유지. History 복귀/재활성화/주기갱신 및 저장된 기준별 판단근거 표시 수정, WEB a8796fb4·GalaxyS8 build2026102303 실제표시PASS. WEB4·Native26검사/빌드PASS. 기존ID/정책/두평가기록·Ledger 보존검증PASS, 추가Provider/차감0. [배포·증거·검증범위](essay-p0-direct-execution-20261023.md).
