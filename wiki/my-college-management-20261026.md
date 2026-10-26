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
