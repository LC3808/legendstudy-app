# Current Status

## APP67 학습 기능 통합 — 2026-11-11

Owner 작업02 후속 승인에 따라 누적·지원 중복 두 함수를 운영 적용했다. WEB·스토어 변경 없음.
기준 APP67 1.0.2+67의 타이머/복구/오프라인/outbox/모의고사와 APP67 출시 산출물은 보존한다.

[구현·검증·후속 작업](app67-learning-integration-20261111.md) ·
[SQL 후보·검증·원복](../supabase/candidates/app67_learning_20261111/README.md).

- 학습 홈: 서버 확정 오늘/누적/이번 주, 최근7일 차트·타이머, 학교 순위·초대 진입.
- 학교 순위: 서버 RPC all/participation 기본, 네 기간·세 지표, 공동 순위/TOP10/주변,
  비공개 인원 **, 기존 NEIS 학교명 조회·등록 연결. APP 별도 집계 없음.
- 초대: 기존 Backend 생성/복사/OS공유/토큰 보관/로그인 후 귀속/학교 확인.
  기존 Auth URL 교환은 변경하지 않는다. HTTPS 링크는 기존 WEB 랜딩이며 앱 내 직접
  전용 custom scheme 수신을 구현했다. 수동 받은 초대 페이지는 제거하고 학습 초대하기에서 바로 OS 공유한다. Universal/App Links 운영 도메인 검증,
  설치 후 토큰 복원 및 실기기 E2E는 별도 미완료다.
- 누적 표시 연결 완료. 두 함수 운영 적용 및 기존 데이터/ACL/요약 보존 검사 PASS.
  학습·초대·Auth 집중49 PASS, analyze PASS. iPhone12 Pro Max에 Owner UX·Scene 공유 오류 반영 빌드70 설치·실행 완료, Owner 확인 회신. 학교 순위 제목/시간 강조 후속 UI28검사 PASS, 빌드71 서명 빌드·iPhone 설치/실행 PASS, 학교 순위 UI Owner 검수 완료(“이대로 진행”).

## 다음 작업

1. 기능 문서의 최종 테스트·플랫폼 컴파일 결과와 제한을 확인한다.
2. Owner가 앱 내부 검수 범위를 결정한 뒤 실기기 초대 공유·수신·학교 변경·학습 동기화를 확인한다.
3. SQL 적용 완료. 도메인 링크 검증·미설치→설치 귀속·실기기 E2E는 미완료다.
4. APP67 다음 릴리스 번호/서명/스토어 업로드는 이번 작업에 포함되지 않는다.

## 기존 기능·릴리스 이력

[작업 전 상태 전문](history/app67-learning-input-20261111.md)에 기존 증거를 보존했다.
[APP67 출시 검수 이력](app67-essay-admission-20261106.md),
[APP66 최종 검증](app66-final-release-20261106.md),
[TASK20 자연 연결](task20-priority-natural-connection-20261106.md)을 참조한다.
과거 HOLD/PASS 문구는 당시 범위이며 최신 운영 상태를 자동 의미하지 않는다.
WEB 운영/인수인계는 WEB 저장소가 소유하며 이 APP 브랜치에서 배포하지 않는다.

## Daily Sync status

이번 APP 통합은 자료 수집을 변경하지 않는다. 이 브랜치의 과거 수집 증거는
[작업 전 기록](history/app67-learning-input-20261111.md#daily-sync-status)에 보존했다.
11/8 이후 수집 운영 변경은 APP main의 별도 자료 동기화 작업이 소유하며 이 브랜치로 덮어쓰지 않는다.

## 작업03-B — 자동채점 운영 후보 (PARTIAL · 승인 대기)

[최신 검수·후보·미해결](task03b-ready-candidate-20261111.md) ·
[적용/검증/원복 SQL](../supabase/candidates/task03b_ready_20261111/README.md) ·
[이전03-A 증거](task03a-official-ready-20261111.md).

- 17시험417Registry 과목: **로컬 READY396 / PARTIAL12 / NOT_READY9**.
  기존372과목/412표 보존 +2025수능24과목31형830문항 추가 →443표/11,170문항.
- generic12행은 검증된 선택과목 상위묶음1:N. 병합/삭제/중복키 없음.
  제2외국어·한문9과목 공식명/정답은 확인했으나 canonical코드 미확정으로 NOT_READY.
- 원점수816·백분위304셀 전사 검수, 원문빈값160개 null. 공식 표준점수1,026사실 보존.
  기존scalar계약으로 정확히 표시 가능한 참고1,029행 후보; 미만114·미배정3행 제외.
  raw→공식등급 변환 없음. 기존2,457행 보존, 자동등급키 추가0.
- 운영 읽기 검사: PG17.6, 키/문항/채점결과0건, 참고2,457행,417Registry 매핑 일치.
  운영의 계정제한/잠금이 초기후보에서 빠진 점을 발견하여03-B 후보에 정확히 보존.
- Flutter522 + 학습회귀120/analyze PASS, Python22 PASS.
  격리PG:1,329실제자료 제출·동시중복·본인격리·계정제한·재적재·공개/원복 PASS.
  대상스키마 계약 검사이며 운영전체 clone/실기기E2E와 구분한다.
- 다음: Owner 승인 → 최신preflight/백업 →03-B SQL·검증자료 적재/공개 → 별도실기기.
  **운영 DB/RPC 쓰기·WEB/APP 배포·스토어 제출0. APP67/검수APP71 보존.**
