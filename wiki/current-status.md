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

## 작업03-C — 자동채점 운영 적용 완료 · 실기기 검수 진행

[운영 결과·검증·남은 일](task03c-production-rollout-20261111.md) ·
[검수 원본](task03b-ready-candidate-20261111.md) ·
[SQL·원복](../supabase/candidates/task03b_ready_20261111/README.md).

- Owner 승인 범위 적용: migration20261111041154,443정답표/11,170문항/396READY과목/17시험 공개.
  PARTIAL12·NOT_READY9 제외. 기존372READY 검수자료/417Registry 유지.
- 참고1,029행 추가, 총3,486. 기존2,457행 전체행해시 동일. 자동등급키0, 등급 산출 불가 유지.
- 실제 운영1,329RPC 점수·저장·재조회 검사 후ROLLBACK. review검수11건 별도보존,
  동시중복1건·새ID재제출·다른계정DBrole 접근차단 PASS. 실제JWT E2E와 구분.
- 실제 Flutter Repository 운영조회443표/과목396/시험17 + Guest MCQ/단답/전원정답 PASS.
  기존 학습회귀100 PASS. 기존RLS정책동일·새security advisory0. Auth/원장/평가 변경없음.
- APP67/71 보존. 내부APP72(1.0.2/72) 서명·iPhone 삭제 없는 설치/실행 PASS.
  Owner 화면 검수 회신 대기, authenticated JWT 제출 E2E 미확인, 스토어제출0.
- 다음: iOS 로그인 TEST 저장·재조회 실기기 확인, Android 별도검수. 미검증 과목 공개금지.

## 모의고사 결과 UI 후속 — 2026-11-11
[구현·예상 등급 대안·검증](task03-result-ux-20261111.md).
Owner APP72 기능 정상 확인. 시험명 축약/점수 배너/별도 답안 화면/정오 색상·번호 버튼,
중복 액션·내부 설명 제거, 공부시간3항목 구분. 원본 결과/출처/엔진 보존.
649검사·analyze PASS. 예상 등급 산출은 기존 원점수 우선 계약 기반 제안만 작성,
운영 DB/RPC·WEB·스토어 변경0. 내부APP73(1.0.2/73, source b8b824d) 서명/설치/실행 PASS. 새 UI Owner 검수 대기.
