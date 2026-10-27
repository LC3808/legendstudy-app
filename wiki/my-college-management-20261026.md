# WEB MY — 프로필 압축·대학 관리 통합

Owner P1 2026-10-26 지시, 2026-10-27 KST 배포. 기존 [MY 공통 계약](my-shared-foundation.md)과 [장기 학습·지원 데이터 원칙](longitudinal-learning-admissions-data-strategy.md)을 재사용한다.

## 적용 결과

- 프로필: 기본 신원·학교·학년·희망 전공·편집 유지. 관심 대학은 분리.
- 바로 아래 ‘나의 대학 관리’: PC 1:1 두 카드, 850px 이하 1열. 관심 대학→지원 현황 순서.
- 관심 대학: 압축 행, 변경·삭제 확인·네이비 추가. 기존 최대 5개/중복 제한 유지.
- ‘지원 내역 추가’: 해당 대학 ID·학과를 기존 등록 폼에 미리 채움. 저장 전 DB 생성 없음. 관심/지원은 독립.
- 지원 현황: 기존 메타데이터·상태·변경·삭제 확인·진행/결과 기록·이력 기능 유지. 최신 학년도 기본, 저장된 모집 구분 필터, 10건 단위 화면 페이지.
- 연도 필터가 첫 서버 페이지에 제한되지 않도록 기존 소유자 조회 RPC를 25건씩 순회. 빈 페이지+has_more/10,000건 초과는 오류로 표시하고 부분 자료를 전체 집계로 오인시키지 않음. 서버 응답·RPC 변경 없음.
- 요약은 필터 결과의 등록 수와 최신 이벤트가 최초/추가합격인 수만 산출. 다른 상태를 임의로 합격 처리하지 않음.

## 보존 검토 7문항

1. 기존 지원 발생/기록/정정 시점을 그대로 사용. 새 historical fact 도입 없음.
2. 기존 원본 이벤트·맥락·이력을 보존. UI 이동은 원본 수정 없음.
3. 기존 revision/idempotency/supersedes/삭제 계약 그대로. 새 UPDATE 의미 없음.
4. 기존 Auth 사용자·owner 검사·RLS 사용. 별도 학생 ID 없음.
5. 관심은 목표, 지원은 자기보고 결정, 결과는 기존 이벤트. 관심 등록만으로 지원 생성 금지.
6. 기존 본인 권한·개인정보 범위 유지. 운영 학생 데이터 테스트 쓰기 없음.
7. 요약은 동일 조회 결과의 파생 표시만 사용, 저장하지 않음.

## 확인한 범위

- Typecheck PASS, ESLint 오류 0/기존 무관 경고 4, UI 14 tests PASS, Production build PASS.
- 테스트: 기존 등록 멱등 키 재사용, 이력 정정 연결, 조회 실패, 최신 연도/다음 서버 페이지 포함 필터, 관심→지원 사전 입력(자동 생성 없음), 기존 관심 등록/제약·빈 상태.
- Production 일반 계정: 기존 관심 5개 표시, 프로필/학교/학년 표시, 2열 배치, 지원 없는 빈 상태, 관심의 대학·학과 사전 입력, 취소, 프로필 편집 진입/취소 확인. 저장/삭제는 실행하지 않음.
- Chrome 400px 기기 미리보기: 프로필→관심→지원 1열과 버튼 줄바꿈·긴 대학명 확인. 실제 모바일 기기 검증은 아님.
- 해당 운영 계정 지원 내역은 0건. 실제 지원 이력 데이터의 운영 쓰기/수정/삭제 검증은 하지 않았으며 기존 handler와 mock UI 검사로 확인.
- Provider 호출/크레딧 차감/DB·Worker·Secret·APP 변경 0. 기존 Credit·Ledger·History 관련 코드 수정 없음.

## 배포·Git·복구

WEB 폴더 `/Users/woojinchang/development/legendstudy-release-20261024`, branch `codex/web-app-release-20261024`.

WEB commit `6934af89f47fb4ac6e01cd10f9c912ebbf2628c8`: Push 및 `git ls-remote` 동일 확인.
Cloudflare Pages Production `30bfbe41-f1c3-4988-bf46-e01c3582ae05`, canonical deployment success와 commit metadata 일치. `https://lab.legendstudy.com/account/` 실제 반영 확인.

수정 파일: `src/components/my/dashboard.tsx`, `applications.tsx`, 각 테스트 2개, `src/app/globals.css`.

롤백: Pages 기존 정상 배포 `62435975-f93d-4c65-8e01-d85f214c1cd8` (WEB `730d74a6b1a30b31596fa83147dba619db9ee7b2`)로 되돌리거나 이번 WEB commit만 revert 후 같은 배포 경로 사용. DB 롤백/재실행 SQL 없음. Secret 설정을 덮어쓰지 않는다.

## 별도 미완료

이 P1 화면 개편은 [전체 대학 STANDBY P0](essay-all-university-standby-20261026.md)의 신규 대학 연결·APP PDF GAP 완료를 의미하지 않는다. 해당 상태와 재개 순서는 기존 기록 유지.

## 2026-10-27 — 2차 밀도·관리 메뉴 보정

Owner 2차 지시에 따라 기존 데이터/handler를 유지한 WEB UI 변경. 위 보존 검토 7문항을 그대로 적용하며 저장 구조·수정 의미 변경 없음.

- 프로필의 빈 필드 공간 제거, 실제 이름/이메일·재학·학교·학년·전공과 편집 유지.
- 관심 대학: 대학/학과/지원 추가/⋯ 한 행(긴 이름 줄바꿈). 변경·삭제는 ⋯로 이동.
- 지원 현황: 대학·학과/상태/⋯ 및 학년도·모집·전형의 두 줄. 기존 변경/진행 기록/이력/삭제 확인 연결 유지.
- PC 두 카드 높이는 콘텐츠별 독립, 모바일 한 열 CSS. 관리 메뉴 Escape/포커스 이탈 닫기 및 터치 영역 적용.
- 요약은 필터된 지원 기록 건수와 최신 이벤트 기준 최종 합격(accepted/additional_acceptance), 1단계 합격(stage_pass)을 분리. registered를 최종 합격으로 추정하지 않으며 대학 수/결과 대기 수를 임의 산출하지 않음. 관심→실지원 상태는 정확한 관계가 없어 생략.

검사: Typecheck, 변경 파일 ESLint, 관련 UI 15개, Production build(136 routes), diff check PASS. 운영 일반 계정 관심5/지원0에서 압축 목록·독립 높이·긴 이름·관리 메뉴·편집 진입/취소 확인. 학생 데이터 저장·삭제 테스트 없음. 지원 상태/이력은 mock UI 검사로 확인했으며 운영 계정에 지원 내역은 없음. 이번 2차 변경의 모바일 실화면 재확인은 미완료(반응형 CSS 적용, 1차 400px 확인과 구분).

WEB `780eff88e4d3509774ea0eea9c4644e06bec02f4` commit/push/remote SHA 일치. Pages Production `efe137e9-cac7-43b6-a10c-bad56a7d679b`: canonical deployment success와 commit metadata 일치, `/account/` 실제 반영 확인. DB/RPC/Worker/Secret/APP 변경0, Provider 호출/학생 Credit 변경0.

복구: 직전 정상 Pages `d1249daa-0305-4352-ab2c-680c9adbdf2d` (WEB `91c19ea5c679bc07f2788c76a784499cccc90811`) 또는 이번 WEB commit만 revert 후 기존 공개환경 주입 배포. SQL 없음. Secret 설정 변경 금지. 한국항공대 APP은 기기 연결만 확인했으며 일반 계정 로그인 및 실사용 확인은 별도 미완료로 유지한다.

## 2026-10-27 — 최종 MY 통합·학년별 노출·성장 요약

Owner 최종 지시를 적용했다. 기존 2차 보정과 위 7문항 보존 검토를 계승한다. 프로필과 대학 관리를 하나의 외곽 카드로 통합하고, 내부 중첩 카드를 제거했다.

- 지원 현황/관심 대학의 지원 추가는 기존 상태 `student`+3학년 또는 `retaker`에만 표시한다. 1·2학년/학년 미설정/기타·상태 미설정은 관심 대학 전체 너비이며 숨김 안내를 추가하지 않는다. 기존 retaker 분류를 사용하며 N수 연차를 새로 추정하지 않는다.
- 프로필 편집 저장 후 같은 조회 상태를 갱신하여 즉시 노출을 재계산한다. 숨겨진 지원 기록을 삭제하거나 변경하지 않는다.
- MY 성장 요약은 기존 시험·문항 선택, 평가 횟수, 실제 그래프·범례, 전용 LAB 상세 이동만 남긴다. 기간/통계/긴 기준 원문/전체 이력 목록/잘한 점·보완점은 MY에서 제거하고 전용 상세 화면에 보존한다.
- 1회 막대·2회 비교 막대·3회 이상 전체 이력 꺾은선, 점수 공백·하락·기준/척도 분리 및 결과 링크는 기존 계약 그대로다.

검증: 관련 UI 27 tests PASS, Typecheck PASS, Lint 오류0/기존 무관 경고4, Production Build 136 routes PASS. 프로필 저장 2→3→2 전환과 상태별 노출은 mock UI 테스트로 확인했다. 실제 운영 일반 계정(고2)의 PC·Chrome 400px 모바일 미리보기에서 지원 영역/지원 추가 숨김, 관심5개·긴 이름·단일 카드·3회 성장 그래프·상세 링크를 확인했다. 운영 프로필/지원 데이터 저장·삭제 테스트는 하지 않았다. 실제 모바일 기기 검증과 구분한다.

WEB `49fee2419493c12f95a9aa939804cf51c957ac70`, branch `codex/web-app-release-20261024`, Commit·Push 후 Remote SHA 확인. Production Pages `0c033b52-c4b6-4e8e-98d0-764b46ad9357`, source `49fee24`, `https://lab.legendstudy.com/account/` 반영 확인. APP Native·DB·RPC·Worker·Credit·Ledger·History·Secret 변경0, Provider/차감0.

롤백: 직전 Pages `7eea1b34-3926-4fcd-a695-aeb5a3b4b3ea` (WEB `a0b1bcf266c890556b81a1059e4fb90214bb219e`)로 복구하거나 이번 WEB commit만 revert 후 기존 배포 절차 사용. SQL 적용/재실행 없음. 기존 대학 STANDBY 및 APP GAP 상태는 별도 기록을 유지한다.

## 2026-10-27 — 프로필 라디오·학교 독립·관심 대학 제한 안내

Owner 최종 보정. 기존 통합 카드와 위 보존 검토 7문항을 계승한다. 원본 지원 이벤트/시간/식별자/이력, 본인 권한, 관심≠지원≠결과 구분, 기존 수집 범위는 유지한다. 지원 영역 노출은 저장하지 않는 파생 UI이며 실제 학생 데이터 변경 테스트는 하지 않았다.

- 학년은 정확히 5개 라디오: 1학년/2학년/3학년/재수/N수생/해당 없음. 기존 student+grade 1~3, retaker+null, other+null로 매핑. 레거시 상태 미설정은 명시 선택 없이 저장할 때 기존 null을 유지한다.
- 학교 선택/해제는 학교 식별자만 변경한다. 학교 존재로 student를 강제하던 WEB 저장 보정을 제거하여 재수/N수생·해당 없음에서도 학교 검색/선택/수정 가능. 기존 DB 제약 읽기 확인: 학교와 상태의 독립 저장이 허용되어 Migration 불필요.
- 지원 현황은 student+3 또는 retaker에만 표시하고 저장 후 갱신한다. 기존 지원 기록은 그대로 유지한다.
- 관심 대학 5개에서 추가 버튼 클릭 시 입력폼 대신 붉은 안내를 4초 표시. 반복 클릭은 동일 메시지 타이머만 갱신. PC 오른쪽/모바일 아래. 기존 서버 최대5 제한 유지.
- 희망 전공 한 줄, 통합 카드/입력/구분선 대비·절제된 그림자·compact radio와 목록 적용.

검증: 관련 4파일 45 tests PASS, Typecheck PASS, Lint 오류0/기존 무관 경고4, Production Build 136 routes PASS. 저장/복원·5개 상태 매핑·학교 유지·2→3→2 노출·반복 클릭/4초 제거는 mock 테스트로 확인. 운영 일반 계정 PC와 Chrome 400px 모바일 미리보기에서 라디오 5개, 재수 선택 후 학교 유지, 취소, 관심5개 안내 PC 오른쪽/모바일 아래를 확인했다. 실제 기기 검증과 구분한다. 운영 프로필 저장/관심 변경/Provider/Credit 차감0.

WEB commits `fd209f9`, `a5ec76dd2e7dcebefc691b704e258a9d8a744533`, branch `codex/web-app-release-20261024`. Commit·Push·Remote SHA 일치. 최종 Pages Production `a68022fe` (`https://a68022fe.legendstudy-lab.pages.dev`), canonical `https://lab.legendstudy.com/account/` 실제 화면 확인. APP Native·DB/RPC·Worker·Credit·Ledger·History·Secret 변경 없음.

롤백: 두 WEB commit을 역순 revert 후 기존 공개 환경 주입 배포, 또는 직전 Pages `db3fdb12`/WEB `0edff64ccac42806f78970ad427d71f111c08a58`로 복구. SQL 적용/재실행 없음. 학생 데이터 복구 작업 불필요. 다른 대학 STANDBY·APP GAP은 기존 별도 문서 상태 유지.
