# APP67 논술 LAB 공개 상태 검증

1.0.2(67) · 앱 소스 `2fa70bf` · RELEASE_READY = NO. APP66 배포 판단 철회. 운영 데이터 수정·평가 실행·스토어 제출 0.

## 원인과 변경

APP66 소스는 `3fd07d2`. WEB `d0e0e2e` 및 후속 운영 소스의 ScopedExamSubmit을 대조했다. APP66은 시험별 admission을 받은 뒤에도 자연계 여부·이미지 입력 방식·별도로 읽은 수리 활성 상태를 검사했다. 독립 조회의 로딩/실패도 false처럼 취급할 수 있었다. 답안 확인 화면은 공개 문항 목록과 다른 원본 수리 Catalog를 참조했다. 서술형 제출 패널은 응답 대기 중에도 이용 불가를 표시했다. B(계약 불일치)와 A(계열·입력 방식 분기)를 코드에서 확인했다. D의 비동기 상태 오표시를 재현 가능한 코드 조건으로 확인했다. 개별 사용자 요청 당시의 서버 응답·캐시 상태는 미확인. 후속 `c87c374`는 제한 사유 문구 변경이며 단독으로 해결하지 않는다.

APP67은 계정·시험별 POST /api/essay/exam의 questionIds와 mathQuestions를 우선한다. WEB과 동일한 조건에서만 GET /api/essay/availability의 해당 시험 공개 leaf로 보완한다. 명시적인 혼합형 검수·공개 범위 변경 상태는 보완하지 않는다. 문항별 확인과 제출 경로에 같은 결과를 사용한다. 혼합형 전체 제출 요구는 선택 집합과 대조한다. 원본 수리 목록은 기존 사진 편집 용도로 사용할 수 있다. 기존 대학 공개 정책과 실제 quote/submit 권한 검사를 유지한다.

## 검증

- 정적 분석 이슈 0. Flutter 전체 1,556 통과, 7 건너뜀. 미공개·부분 공개·수리 단독 및 혼합형·사진 보정·기존 인문 회귀 포함.
- 운영 로그인 WEB에서 건국 2026 수시 자연 Q1~Q4의 답안 작성과 PDF 1·2·3·4쪽을 각각 확인. 경희 2026 수시 자연 Q1~Q3의 답안 작성과 PDF 1·2·2쪽을 각각 확인. 사진 미첨부 상태에서 추출 버튼 비활성 확인.
- 경희 2027 모의 사회·한양 2027 모의 상경·숙명 2027 모의 인문의 작성 폼 및 요청 영역 확인. 한양 Q1의 2쪽 PDF 렌더링 확인. 경희 사회와 숙명 인문은 뷰어 진입 확인, 최초 로딩 완료 별도 검수 필요. 빈 답안에서 새 평가/차감 실행하지 않음.
- 배포 서명 IPA, 서명 AAB 생성. iPhone 12 Pro Max 설치·실행 완료. 동일 일반 계정으로 위 5개 경로의 PDF → 답안 작성 → 첨삭 요청 전 단계까지 Owner 실기기 확인 완료(PASS). 실제 평가는 실행하지 않음. Galaxy S8(SM-G950N, Android 9/API 28)은 ADB 연결 확인. Play 설치본 1.0.1(58)의 앱 서명 SHA-256은 4d9694e8…6371ac, APP67 AAB 업로드 서명은 c00f4260…8ef1로 다름. 기존 앱을 삭제하거나 로컬 APK로 교체하지 않음. Owner가 Play 내부 테스트에 APP67을 배포한 뒤 같은 기기에서 업데이트·5개 경로 검증 필요(NOT_VERIFIED). 운영 86시험 Catalog/DB 변경 없음. 이번 작업에서 86개 비노출 전수 재검증은 수행하지 않음.
- 보관 경로 `/Users/woojinchang/development/legendstudy-private-backups/app67-release-20261106`. APP66 IPA·AAB 기존 체크섬 일치. 출시·업로드 보류.

## 최종 산출물 대조

- 빌드 시점 Git HEAD 2fa70bf, 이후 변경은 Wiki뿐이다. IPA·AAB 각각 보관본과 동일 작업 트리 빌드 출력의 SHA-256이 일치한다. AAB에는 VCS SHA가 내장돼 있지 않아 빌드 기록과 바이너리를 함께 대조했다.
- APP66에는 없던 신규 admission 검사·재시도·혼합형 전체 문항 제출 안내 식별자 3개가 APP67 iOS·Android arm64 AOT 바이너리에 모두 있다.
- IPA: Apple Distribution, 1.0.2(67), Mac 신뢰 체인에서 codesign --verify --deep --strict 통과. App.framework UUID가 xcarchive와 일치한다. SHA-256: 192ce1b18f94e0f5c393afb2d548decba711fce81b448facb04ef176783d9a2b
- AAB: jarsigner 서명 검증 통과(업로드 키). SHA-256: 223e9b49396a973fa7eabd9af157c01d65a7f9412a564e5d45929071e0928c5b
- Android 내부 테스트 배포 전(Owner 확인). Galaxy S8에서 Play 설치 58 재확인. 업데이트 후 데이터 보존·PDF 본문·첨삭 진입 미검증. 앱 삭제 또는 대체 설치 없음.
- iPhone 12 Pro Max에서 실제 문제 PDF 본문까지 표시됐음을 Owner가 명시적으로 확인했다. iOS RELEASE_READY = YES. Android RELEASE_READY = NO, 통합 RELEASE_READY = NO. 스토어 업로드·심사 제출 없음.

## TASK18 출시 게이트 추가 — 2026-11-06

최신 결정: 논술·서명 게이트와 별도로 iOS·Android 모두 최종 제출 HOLD. 운영 실물 PDF 저장·열람은 양 OS NOT_VERIFIED. APP67 산출물 보존.
운영 LegendStudy에서 파일별 resource_download_policy를 읽기 전용 집계: 18게시글, 활성 PDF 846개, 전부 PENDING, 권한 revision 0건. 기존 파일별 인벤토리는 codex/popular-pdf-task18의 wiki/task18-popular-pdf-inventory-20261104.md (문제지 420, 정답·해설 416, 듣기대본 10). 파일 ID·원본 키 유지. 제공 권한을 입증하지 못한 파일은 활성화하지 않는다.
APP67의 다운로드 위젯·서비스 기존 테스트 13 PASS (릴리스 SDK 3.47.6). 버튼·파일명·해시·저장 완료·실패 후 재시도 검증이며 운영 실물 E2E는 아니다. 기존 열람 및 합성 PDF 저장 PASS도 대체 근거가 아니다.
다음 단계: 파일별 배포 근거·권리자 확인 → 동일 resource ID/source key로 PDF 원본과 SHA-256 대조 → 허용 파일에만 검수 근거와 안전한 저장명을 포함한 ALLOWED revision 추가 → 일반 앱에서 정책 RPC·resource-download 성공, iOS 파일 앱·Android 파일 관리자에서 저장 이름과 본문 확인. 원복은 기존 이력을 삭제하지 않고 차단 revision 추가.
