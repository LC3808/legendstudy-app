# Current Status

[서울여 수리1시험3 PUBLISHED / 과학6 NOT READY](essay-swu-public-20261112.md):36행·기존 PDF 재사용,운영119/121/9·WEB447/APP29 PASS.기존382문항·42대학목록·RLS272·Credit보존.전체WEB10FAIL/예외1은변경전재현. [10대학 통합](essay-natural-publication-summary-20261112.md):83시험221문항 중68시험170공개,항공7DRAFT·공식HOLD7·권리HOLD15·NOT READY22.전체PARTIAL,Provider0. [Owner 검수목록](essay-natural-owner-review-20261112.md) 인계; 실제AI/로그인제출/실기기NOT TESTED.

[광운21시험42문항 PUBLISHED](essay-kwangwoon-public-20261112.md):636행·공식문제PDF21파일78쪽·목록20시험숨김해제. 기존340문항·다른41대학목록·RLS271·권한/Credit보존. 운영158/199/126·WEB410/APP39 PASS,Provider0.로그인제출/실기기NOT TESTED. 광운DONE;서울여후속은상단참조.동국Q1 등HOLD유지.

[동국 자연7시험 공개20/HOLD1](essay-dongguk-public-20261112.md):273행 연결·기존320문항/Registry/RLS271보존.2026모의는2025년시행/2026학년도 일치,Q1공식수정해설 불일치로HOLD.운영137/156/60·WEB410/APP39 PASS,Provider0.비로그인목록/입력UI 확인,로그인제출/실기기 NOT TESTED. 숙명16시험44문항 DONE(기존6보존),서강9시험11·숭실5시험19 DONE(숭실Q2HOLD). 광운후속공개완료는상단참조;전체완료아님.

[자연·수리 운영 공개](essay-konkuk-public-20261112.md): 건국 신규6시험24문항/299행 **PUBLISHED**, 기존4문항 보존. 운영 사전116·사후139/72·기존20snapshot·PDF6개·공개API24·일반계정 조회 PASS. Pages802acf70, 신규실제AI/실기기 검사는 미실행. 격리24흐름/원복·WEB381 PASS/1SKIP. 실제 AI 품질은 전체 대학 후 Owner 통합 검수이며 진행 조건이 아니다. [경희 신규7 PUBLISHED](essay-kyunghee-public-20261112.md): 기존3보존, 운영116/122/21·WEB396/APP8 PASS, 과학12/기준미확인4 제외. [성균관15 PDF RIGHTS_HOLD](essay-sungkyunkwan-rights-hold-20261112.md): 이용 허락/표시 승인 미확인, 운영 객체4/5·일반조회0, 변경0. 서강·숭실·숙명·동국의 후속 공개결과는 상단참조. 광운DONE;서울여후속및통합잔여는상단참조. [기술 범위](essay-natural-integrated-review-20261112.md) 재사용, 한국항공7/106 DRAFT와 HOLD5·중앙과학11 보존. PDF/자료 미해결은 문항별 분리.

[작업04-C 실제 계정·기기 검수](task04c-device-verification-20261111.md): A SQL 운영 적용 DONE(재적용0), iPhone 기존 계정 저장·재실행/재로그인·A/B 격리·기본 복원 DONE. Android360dp guest 터치/저장/진입 PASS. 기존 iPhone APP75/Android67 설치본 보존. 신규 온보딩은 이메일 인증 장애로 NOT TESTED. 04-A/B DONE,04-C 전체 검수 PARTIAL,C/D HOLD. [운영 영수증](task04c-home-production-20261111.md).

[알림 무한 로딩 수정](notification-loading-fix-20261111.md): 운영 개인 알림 table/RPC4개 부재·404 확인. 자동 재시도 해제·단계별8초 제한·Empty/Error 분리·수동 재시도. 관련46 PASS, 전체2532 PASS/8 SKIP/기존5 FAIL, analyze·iOS/Android build PASS. Android 오류/재시도/공지 이동 확인. iPhone 오류·재시도 버튼·로딩 종료 Owner PASS, 실제 재시도·공지 이동 NOT TESTED. 운영 DB/배포 변경0.

[이메일 인증 읽기 조사](email-verification-audit-20261111.md): 11/9–11 현재 이메일 가입19계정 중5미인증. 첨부3계정 발송 시각 있음/인증·로그인 없음. 오늘 발송 한도 로그21건; 실제 수신/반송·SMTP 설정 미확인. 계정 삭제/강제 인증/재발송·Auth 설정 변경0.

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
- 참고1,029행 추가, 총3,486. 기존2,457행 전체행해시 동일. 자동등급키0, 저장된 공식 grade 필드 불변. 앱 참고 등급은 아래 후속 참조.
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
APP73 Owner 화면 확인 후 APP74 후속 구현: 오늘→이번 주→누적, 공식 기출 기본,
시험명 주황 박스·선택 답안 검정/흰색. 443키 중364 예상/79 추정 등급을 원본 결과와 별도 표시.
추정은 같은 과목/선택과목·시험 종류/월 원점수 범위이며 난이도 보정 모델이 아니다.
회귀708개(이전 기본값 기대5개 정정 후 재검증), 렌더4개·analyze PASS.
운영 DB/RPC·WEB·스토어 변경0. 내부APP74(1.0.2/74, source b92d2b9) 서명·iPhone 삭제 없는 설치/실행 PASS.
Owner APP74 화면 확인 완료. APP75 후속으로 결과 목록·상세 제목에 과목명 통합 표시.
APP75(1.0.2/75, source c9b4830) 서명·iPhone 설치/실행 PASS, 과목명 후속 Owner 확인 대기.
관련55/렌더4·analyze PASS. APP74/73/72/71/67 보존, Android 검수 미실행.
