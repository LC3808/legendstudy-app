# Current Status

[로그인 인증 안내 P0 hotfix](auth-verification-ux-hotfix-20261113.md): 일반 로그인 상시 안내 제거, 가입 직후/실제 미인증 코드만 재발송 제공. 오류 유형 분리·20초 대기 제한, 기존 세션/온보딩/운영 데이터 보존. 전체2601 PASS/8 SKIP/0 FAIL·Analyze PASS. iOS unsigned 컴파일 PASS·hotfix Push 완료. 1.0.4(84) 번호 조회는 ASC 로그인 대기, 서명 IPA PARTIAL. main/스토어 최종 승인 필요.

[APP83 최종 빌드·스토어 제출](app83-store-handoff-20261112.md): 스플래시6962c0f 포함, main fast-forward/Push 완료. 1.0.3(83) IPA/AAB·서명/설정 PASS. 전체2580 PASS/8 SKIP/0 FAIL·Analyze·Python33·격리SQL71/42·Android JVM2 PASS. Owner IPA/AAB 업로드 보고. Android83 서버 수락 확인·심사 전송 요청 완료: Google 자동 검사 중, 승인 후 기존100% 자동 출시 설정. iOS 심사 신청 완료 Owner 확인. 최종산출물 실기기·심사 승인·실제 공개 NOT TESTED. 신규RPC2 미적용: 기존TOP10 유지, 추가순위/백분위 미활성. 운영DB/Auth/회원/Provider 변경0. 기존 설치 앱·APP82 보존. [후속UX·이전 iPhone 검증](app82-post-rc-ux-20261112.md).

[APP82 릴리스 승인·main Push·빌드 완료](app82-store-handoff-20261113.md): 최신main 보존 fast-forward/원격 Push 완료. 1.0.3(82) 배포 IPA·서명 AAB 생성·버전/서명/운영 연결 설정 확인. 통합 후2557 PASS/8 SKIP/0 FAIL·Analyze·Python29·Android JVM2 PASS. 기존 [RC 실기기 근거](app-release-rc-20261113.md) 유지. 추가 소셜 로그인/논술 실사용 검증 WAIVED, marker 없는46개 회원 재노출 ACCEPTED(보호/backfill 없음). 운영 DB/RPC/Auth·회원 데이터·평가 엔진 변경0. 스토어 업로드/제출0, 새 배포 바이너리 설치·Play 업데이트 NOT TESTED. Owner 제출 전 인계.

[대학 검색 Catalog 확장 CLOSED](university-catalog-closure-20261112.md): Owner 완료 승인. 신규78·전체131·활성128, 관심/실제 지원 검색 PASS. 기존 ID·사용자·논술 LAB 보존. 보류7 정체성 검토 제외, iPhone 검색·WEB 배포본 E2E NOT TESTED. 추가 운영 변경 없이 마감, APP 릴리스 HOLD 유지.

[온보딩 P0 UX](onboarding-p0-ux-20261112.md): 제목/설명 가운데 정렬·전체 카피, 지원 입력 중 다음 숨김/저장 우선, 건너뛰기는 현재 단계만 이동(중간 전체 완료 오류 수정). 집중80/렌더6/analyze PASS. Catalog78개 Owner 승인 운영 추가 완료(53→131/활성128), 기존53행·사용자 데이터 보존/보류7 제외. 공개78개·양쪽 Flutter 검색 PASS(실기기 재검색 미검증). 전체2552 PASS·8 SKIP·기존5 FAIL, iPhone17 APP81 설치·실행/MY 폼·이탈확인 PASS, 기존 완료계정이라 신규온보딩 실기기 NOT TESTED. Owner HOLD.

[지원 대학 카피·컴팩트 폼](onboarding-compact-layout-20261111.md): Owner 지정 따뜻한 문구, 검색 아이콘 통합, 학년도/모집 시기2열(큰 글자 세로), 카드·간격 축소. 기존 저장/진행 복원·Backend 유지. 집중66 PASS/렌더3 PASS/analyze PASS, 전체2551 PASS·8 SKIP·기존5 FAIL. iPhone17 APP80 삭제 없는 설치·실행/버전 확인 PASS, iPhone12 APP75 보존. 미러링 사용 중으로 실기기 UI 검수 NOT TESTED; Owner UX 확인 전 HOLD.

[APP78 Native UX 후속](onboarding-inline-applications-20261111.md): N수·기타 학교 단계 자동 생략, 온보딩 내부 실제 지원 추가/수정/삭제, MY 공통 카드 폼·외부 라벨·미저장 이탈 확인. 기존 repository/운영 데이터 변경0. 계정별 단계 복원 유지. 집중62 PASS/전체2548 PASS·8 SKIP·기존5 FAIL,analyze PASS. iPhone17 APP79 설치 확인/iPhone12 APP75 보존. 기기 잠금·미러링 사용 중으로 화면 검증 NOT TESTED; Owner 최종 UX 검수 대기,릴리스 HOLD.

[이메일 인증 후 온보딩 P0](onboarding-auth-routing-fix-20261111.md): Owner Resend 수신·인증·로그인 성공 보고. Owner 재현 iPhone17 Pro Max 일반 배포 앱1.0.2(67) 확인, 빌드 기록 소스2fa70bf. 이전 iPhone12/APP75 연결 보고 정정. profile 존재를 완료로 오판하는 gate 수정; 완료/skip marker로 판별. 집중212 PASS/analyze PASS. Owner 승인으로 iPhone17에77 삭제 없는 업데이트·실행 PASS. APP77 온보딩 노출 Owner PASS. N수 실제 지원 선택 단계·계정별 단계 복원 구현. iPhone17 APP78 업데이트/실행 PASS, iPhone12 APP75 재확인. 최종전체2540 PASS/8 SKIP/기존5 FAIL,analyze PASS. 최종 실기기 연속 흐름과 기존 회원46개 재노출 검토 대기; 임시 draft 완전 복원은 후속. 운영 변경0.

[작업04-C 실제 계정·기기 검수](task04c-device-verification-20261111.md): A SQL 운영 적용 DONE(재적용0), iPhone 기존 계정 저장·재실행/재로그인·A/B 격리·기본 복원 DONE. Android360dp guest 터치/저장/진입 PASS. 기존 iPhone APP75/Android67 설치본 보존. 신규 온보딩은 이메일 인증 장애로 NOT TESTED. 04-A/B DONE,04-C 전체 검수 PARTIAL,C/D HOLD. [운영 영수증](task04c-home-production-20261111.md).

[알림 무한 로딩 수정](notification-loading-fix-20261111.md): 운영 개인 알림 table/RPC4개 부재·404 확인. 자동 재시도 해제·단계별8초 제한·Empty/Error 분리·수동 재시도. 관련46 PASS, 전체2532 PASS/8 SKIP/기존5 FAIL, analyze·iOS/Android build PASS. Android 오류/재시도/공지 이동 확인, iPhone 회신 대기. 운영 DB/배포 변경0.

[이메일 인증 안정화](email-verification-audit-20261111.md#독립-안정화-조사--2026-11-11): 독립 브랜치에서 기본 SMTP·2통/시간·만료3600초 실제 확인. 오류21건=가입18/매직링크3, 이메일 식별값4개(사람 수 아님). 미인증5명 E 원인 미확인/전달 로그 NOT TESTED. 재발송·60초 대기·오류 안내·가입 이메일 보존 수정, 인증/온보딩143 PASS. 운영 설정/메일/DB 변경0. 전용 SMTP 도입 준비/조사는 Owner 승인. [공급자 비교·DNS·비용·전환안](email-smtp-provider-plan-20261111.md): Resend 우선 추천, 공급자 최종 선택·운영 설정/발송 승인 대기. 실제 신규 가입 E2E·릴리스 통합 전 전체 안정화 BLOCKED.

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
