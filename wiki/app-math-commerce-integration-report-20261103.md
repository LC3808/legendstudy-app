# LegendStudy+ APP·수리·상경논술 통합 작업 보고서

최종 갱신: 2026-11-04 KST · 대상: Owner / ChatGPT 검토

**후보 A의 인증·온보딩·MY 개선과 후보 B의 수리논술 학습 화면을 통합했으며, iPhone에서 일괄 체크와 긴 답안 근거 표시까지 Owner 검수를 통과했다.** 기존 Essay·Math 평가 기능과 Registry·Evidence Package·Credit·Ledger·History를 재사용했다. 다만 저장 결과 조회·UI 검수의 통과를 신규 사진 제출 전체 실기기 E2E나 OCR·첨삭 품질 전체 통과로 확대하지 않는다.

Owner의 최신 지시는 지금까지의 보고서 작성, 기존 서비스 통합, 상경·수리논술 차단 해제, 배포용 빌드 준비다. 이전 문서의 운영 HOLD는 당시 승인·검증 상태를 기록한 이력이다. 이번 지시에 따라 통합·차단 해제 작업을 진행하되, 실제 반영 범위와 배포 성공은 마지막 절의 실행 증거로 확정한다. 이 보고서의 기존 TEST 성공 기록만으로 운영 활성화나 스토어 제출이 완료됐다고 보고하지 않는다.

## 1. 기준선과 통합 구조

| 구분 | 기준 및 상태 |
|---|---|
| 기존 APP41 | iOS 1.0.1(41), 소스·IPA·기존 브랜치와 미커밋 Xcode 설정 보존 |
| 후보 A | `codex/app-review-candidate-a-20261103`: Kakao 시스템 인증, 온보딩 V2, MY 미설정 안내, 선택형 닉네임 |
| 후보 B | `codex/app-review-candidate-b-20261103`: 후보 A + TASK16-K 수리·상경 기반 + 이후 실기기 UX 보완 |
| 초기 B 통합 | merge `89e1f11`, TASK16-K `d7d5bb1`와 A 구현 통합; 파일별 14개 충돌 해결 |
| 최신 검수 앱 | 별도 `LS Math TEST` 1.0.1(56), iPhone 12 Pro Max. 정식 앱 A48은 별도로 보존 |
| B56 실행 코드 | `6f31ac5`: 읽힌 답안 전체 체크 및 미인식 부분만 제외 |
| 보고 시작 기록 | `be71fb6`: B56 답안 근거 가독성 Owner PASS·점진 개선 결정 반영 |
| 기존 TEST WEB | [legendstudy-task16b.pages.dev](https://legendstudy-task16b.pages.dev), 비공개 검수 접근 정책 유지 |

상경 혼합형은 Q1 Essay / Q2 Math의 기존 평가 경로를 사용한다. 학생에게는 하나의 시험 결과와 학습 이력을 제공한다. 수리 화면은 Flutter Native이며 WebView로 대체하지 않았다. WEB은 같은 Backend·결과·History 계약 위에 PC 3열 구조를 사용한다.

공통 정책은 최초 첨삭 이용권 1개와 무료 재첨삭 1회가 반복되는 구조다. 무료 재첨삭은 최초 완료 후 14일과 해당 베타 종료 제한을 따른다. 기존 베타의 하루 무료 1회, 00:00 KST 초기화, 이월 없음, **2026-11-11 00:00 KST 종료**를 임의 변경하지 않는다.

근거: [통합 브랜치·충돌·빌드 기록](app-release-integration-20261103.md), [후보 B 실기기·WEB 기록](app-candidate-b-device-web-qa-20261103.md), [Owner 결정](decisions.md).

## 2. 후보 A — 인증·온보딩·MY

### 구현 완료

| 항목 | 구현 내용 |
|---|---|
| Kakao iOS 인증 | Supabase Auth 구조를 유지하고 iOS 시스템 인증 세션으로 처리. 외부 기본 Safari 앱 이동 문제를 개선 |
| 온보딩 V2 | 상태·학년 조기 저장, 실패 시 입력/재시도 유지, 기존 프로필 저장 계약 재사용 |
| 학교 검색 | 학년 한 줄, 학교 입력창 오른쪽 검색, 키보드 중 하단 다음 숨김, 미확정 검색어로 단계 이동 방어, 명시 학교 확인 |
| 관심 대학 | 입력창 오른쪽 검색, 키보드 중 나중에 설정 숨김, 선택과 검색을 분리해 누락 방지 |
| MY 미설정 안내 | 기존 정보 보존, 빠진 항목만 안내, 정보 저장 후 해당 안내 해제 |
| 선택형 닉네임 | 전공 다음 마지막 단계, 기존 저장·검증 재사용, 빈 입력/건너뛰기는 기존 이름 보존, 실패 시 입력 유지 |
| 공통 서비스 | 기존 PDF·인문논술 결과·History와 뒤로 이동 유지 |

닉네임 고유성, 별도 커뮤니티 DB, 새로운 결제·프로필 저장 시스템은 만들지 않았다.

### 실제 iPhone Owner 검수

| 항목 | 결과 | 실제 확인 범위 |
|---|---|---|
| Kakao | PASS | 인증창→취소·재시도→로그인→자동 닫힘·홈 복귀, 앱 완전 종료 후 동일 계정 유지 |
| 이메일 | PASS | 기존 계정 로그인·홈/MY, 재실행 세션, 틀린 비밀번호 오류, 정상 비밀번호 재시도 |
| Google | PASS | 인증 취소·재시도·홈/MY·완전 종료 후 동일 계정 유지. Owner가 기존 확인 완료를 명시 |
| Apple / A48 | PASS | 로그인 후 온보딩·닉네임 저장·홈/MY·재실행 유지 |
| 학교·관심 대학·전공 | PASS | 검색·선택·확정 및 MY·앱 재실행에서 유지 |
| MY 누락 안내 | PASS | 누락 항목만 안내, 학교 설정 후 안내 사라짐 |
| PDF·인문논술 | PASS | 기존 PDF와 인문논술 History·첨삭 결과 조회 및 복귀 |

Provider별 모든 신규 가입 조합, Apple 취소·재시도, iPad와 Android 실기기 전체 검수까지 통과한 것은 아니다. A47 진행 문제의 원인은 미확정이고, 동일 코드 A48 재진행 성공을 코드 결함 수정으로 보고하지 않았다. Owner가 직접 계정을 삭제한 사건과 에이전트 작업은 구분해 기록했다.

근거: [후보 A ChatGPT 전달용 상세 보고서](app-candidate-a-owner-qa-report-20261103.md), [Kakao 시스템 인증](kakao-ios-system-auth-20261103.md), [온보딩 V2](onboarding-v2-final-integration-20261103.md).

## 3. TASK16-C~K — 수리·상경 기반과 학습 루프

| 단계 | 완료한 핵심 작업 | 증거 범위와 한계 |
|---|---|---|
| TASK16 감사 / C | 기존 조사·설계·구현 교차 확인, 공식 문제/평가자료와 한양2024 자연 오전 Q1·Q2 실제 합격자 손글씨 대조 | Q1 핵심 부호·지수·일반항 인식 실패, Q2 부분 오독 확인. 전사 확인 전 자동 채점 입력으로 신뢰할 수 없음 |
| E | 미인식 기호 보존, 수정/확정 전사 분리, 미확인·미인식 평가 차단, 정답 조기 공개 방어 | 원본 OCR 정확도 향상과 구분. UI 공개 방어 이후 G에서 서버 공개 계약으로 확장 |
| F | Academic Purple Native UI, 사진·수식 확인, 최대 5개 개선 과제, 개념·힌트·명시적 전체 풀이 공개 | Owner 디자인 PASS. 초기 오프라인 예제와 실제 평가 결과는 구분 |
| G | 공통 Math Session/coaching/학습 RPC, 서버 정답 공개 제어, 반복 1/0 이용권 사이클, 재작성·History | Simulator 실제 신규 사진 학습 루프 기능 PASS를 Owner 인정. 실기기 전체 루프와 구분 |
| H | WEB 원본/결과/개념 3열→2열→1열, LaTeX·긴 수식 스크롤·원문 fallback, 공통 공개·History | APP→WEB 및 WEB 작성/공개 이력→Simulator 조회 확인 |
| I | 실제 WEB 사진 OCR·수정·평가·무료 재첨삭, 혼합형 두 Worker 통합, 실제 오류 영역 연결 | 대표 사례 PASS. OCR·힌트·공식 완성 해설 및 다수 오류 우선순위 품질은 PARTIAL |
| J | Owner TEST 접속 경로 정리, 코드·계정/Provider Secret 구분, 운영/TEST 차이와 출시 차단 조사 | 접속 코드 임의 교체·인증 해제 없이 기존 검수 경로 재사용 |
| K | WEB 사진 보정·정돈된 답안, 실제 WEB 전체 루프, 혼합 무료 재첨삭, iPhone 촬영/OCR 복구·전사 편집·키보드 | 실제 카메라부터 전사 편집까지 구간 확인. 같은 사진의 확정→평가→무료→History 전체 실기기 검증은 미완료 |

대학·시험·문항 데이터가 없는 것으로 가정하거나 새 시험 DB를 만들지 않았다. 기존 건국 검증 및 성공한 Provider 응답은 재사용했다. 미발견 조사 원문을 임의로 재작성하지 않았다.

근거: [C 실제 손글씨 분석](task16c-hanyang2024-handwriting-validation-20261102.md), [E 방어](task16e-recognition-disclosure-p0-20261102.md), [F Native](task16f-native-math-ux-20261102.md), [G 학습 루프](task16g-learning-loop-20261102.md), [H WEB](task16h-web-math-ux-20261103.md), [I 통합 품질](task16i-integration-quality-20261103.md), [J 출시 준비](task16j-beta-release-readiness-20261103.md), [K 실제 검증](task16k-beta-activation-20261103.md).

## 4. 후보 B 실기기 피드백 반영 — B49~B56

| 항목 | 반영 내용 | Owner 확인 |
|---|---|---|
| 결과 가독성 | 제목/본문·소제목 구분, 줄 간격, 버튼·카드 간격, 설명 강조 | B50에서 제출 버튼 외 수용 |
| 제출 버튼 | `첨삭 상태 새로고침` / `첨삭 결과 보기`로 역할 구분, 버튼 사이 간격 | B52 PASS |
| 일반 LAB 진입 | TEST의 두 상태조회 경로가 비공개 gate에 막히던 문제 수정 | 한양대 진입·기존 결과 조회 PASS |
| 원본 대조 | 고정 높이 대신 인식 수식/본문 높이에 맞춰 조절, 진한 테두리, 전체 원본 확대/복귀 | B53 PASS |
| 처리 상태 | 인문 StepProgressBar를 보라색으로 재사용, 실제 OCR/첨삭 조회 폴링, 오류 후 수동 복구 | 코드 회귀 PASS. 실제 처리 중 진행 바 전체 실기기 확인은 별도 |
| 답안 확인 정리 | `저장한 답안 확인`, 0크레딧 문구 제거, 중복·모호한 버튼/긴 설명 축약, 완료 결과 직접 연결 | 코드 회귀·빌드 확인. 각 실제 실행 상태 전체 PASS로 확대하지 않음 |
| 학생 답안 근거 | 원문 문단/줄/수식 분리, 긴 근거 미리보기와 전체 보기/접기, 원문 문자열 보존 | B56 Q1 끝까지 읽기·접기·개선 과제 복귀 PASS |
| 전체 내용 체크 | 읽힌 영역은 `uncertain` 대조 표시가 있어도 한 번에 체크. 미인식/빈 영역만 제외·번호 안내. 모두 읽혔으면 최종 체크와 완료 버튼 활성화 | B56 PASS |

B54/B55의 일괄 체크 구현은 Owner 의도와 달랐다. 최신 B56은 **‘미체크 번호 안내’가 아닌 전체 체크 동작**으로 정정했으며, 과거 구현의 자동 검사 PASS를 요구 충족 PASS로 대체하지 않는다. 일괄 체크 자체가 저장·평가·차감을 실행하지는 않는다. 학생이 `답안 입력 완료`를 눌렀을 때 기존 확인본 저장 흐름을 사용한다.

Owner는 답안 근거 표시가 훨씬 보기 좋고 매끄러워졌다고 확인했다. **현재 형태로 이 표시 범위 검수를 마감하고, 추가 실제 사례가 쌓이면 점진 개선**하는 방향을 확정했다. 디자인 전면 개편이나 같은 성공 사례의 불필요한 재검수는 진행하지 않는다.

근거: [B49~B56 상세 기록](app-candidate-b-device-web-qa-20261103.md), [전체 체크 실기기 PASS](app-candidate-b-device-web-qa-20261103.md#b56-전체-체크-owner-실기기-pass), [가독성 PASS·점진 개선 결정](app-candidate-b-device-web-qa-20261103.md#b56-답안-근거-가독성-owner-pass점진-개선-확정).

## 5. 기능 검증과 품질 검증의 구분

| 검증 대상 | 현재 재사용 가능한 근거 | 남은 범위 |
|---|---|---|
| 자연계 WEB 신규 제출 | K에서 한양2024 Q1·Q2 사진 보정→OCR→학생 수정→실제 평가→무료 재첨삭→History PASS(TEST) | 운영 환경의 동일 경로 검증은 별도 |
| Native 학습 루프 | G Simulator 실제 신규 제출/평가/무료/History PASS, K 실기기 저장 결과·원본·공개/무료 상태 조회 PASS | 실제 iPhone 신규 촬영부터 전체 평가·무료·History까지 연속 완주 미완료 |
| APP↔WEB | 같은 사용자/시험/문항의 원본 hash·수정 텍스트·결과·공개/힌트·History 교차 조회 PASS(TEST) | 현재 운영 RPC/Storage/설정으로의 연결 검증 필요 |
| 혼합형 | 한양2026 상경 Q1 Essay+Q2 Math 실제 완료, 시험 단위 이용권1, 부분 문항 미완료 처리, K 실제 무료 재첨삭·History PASS(TEST WEB/서버) | Native 새 사진 혼합 제출 경로 및 전체 실기기 E2E 미완료 |
| 이용권 | TEST 1→0→다음1, 동일 요청 재전송 중복차감 방지, 동시성/만료/실패 경계 회귀 | TEST admin grant 성공을 운영 일일 무료 지급/베타 종료 연결 성공으로 볼 수 없음 |
| 정답 공개 | 공개 전 서버 read/hint에서 full_solution 제외, 명시 reveal 후 반환·History 연결 PASS(TEST) | 운영 증분 RPC/legacy 응답 경계 반영 확인 필요 |
| OCR 방어 | 미인식 표식/빈 입력 차단, 수정 시 확인 취소, 원본/후보/확정 전사 구분 | 표식 없이 틀리게 읽힌 기호까지 자동 검출하는 보장은 없음 |
| OCR 정확도 | 실제 원본과 비교한 오독 증거 있음 | Q1 부호·지수·계수 FAIL/PARTIAL, Q2 표/라벨·숫자 PARTIAL. 독립 정답 집합이 없어 정확도 %를 산출하지 않음 |
| 첨삭 품질 | 정답·계산 오류·기존 개념 오류·대안 풀이의 실제 대조군 인정 | 논리 비약 독립 대조군, 다수 오류 중요도, 대학별 개념·힌트의 구체성, 공식 모범해설 수준은 PARTIAL |
| 수식 표현 | Flutter/WEB 분수·지수·적분·행렬·긴 식 fixture, 원문 fallback, 실제 Q1/Q2 표시·가독성 확인 | 모든 실제 응답의 완전한 수학 문서화 또는 OCR 구조 정확성을 인증한 것은 아님 |
| 인문논술 | 기존 전체 회귀, Owner 실제 PDF·History·결과 조회 PASS | 수리·상경 운영 연결 후 영향 검증 필요 |

실제 Provider 호출, 저장 응답 재생, Mock/계약 검사, Simulator, Owner 실기기 검수를 서로 바꾸어 계산하지 않는다. B49~B56 표시 개선·검수에서는 새 Provider 평가를 호출하지 않았다. C/G/I/K에는 실제 성공·실패 호출이 있었고, 일부 사용량이 누락되어 프로젝트 전체 토큰·비용을 임의 합산하지 않았다.

## 6. 테스트·빌드 기록

아래 수치는 서로 다른 시점과 범위의 결과다. 합산하여 총 테스트 수로 보고하지 않는다.

| 기준 | 결과 |
|---|---|
| A 최종 기능 소스 | Flutter 전체 1,375 PASS / 기존 7 SKIP, Analyze PASS; 온보딩·프로필 집중63 PASS |
| B 통합 후 기준 | Flutter 전체 1,404 PASS / 기존 7 SKIP, Analyze PASS |
| B54 | Flutter 전체 1,418 PASS / 기존 7 SKIP, Analyze PASS; 인문 진행 바·수리 표시/확인/공개 방어 회귀 |
| B56 | 관련25 PASS, Analyze0 issues, Wiki handoff PASS. 저장 한양대18영역 중16체크/미인식3·7 제외 재현. 전체 suite 재실행 결과는 아님 |
| K WEB | 마지막 전체1,617 PASS / 기존4 SKIP; 이후 추가 marker 방어는 focused83개 검사로 확인 |
| TEST 상태조회 복구 | WEB31 PASS, Native29 PASS, 실제 인증 조회200/익명·잘못된 JWT 거절 확인 |

| 보존된 산출물 | 상태와 용도 |
|---|---|
| A iOS1.0.1(48) | signed Release Archive·App Store IPA·기기 설치용 export PASS, iPhone Owner 검수 |
| A Android1.0.1(47) | 동일 최종 기능 소스 signed AAB PASS, Android 실기기 미검증 |
| 초기 B iOS/Android1.0.1(43) | signed Archive/IPA·AAB PASS. 이후 B54~56 UI 수정 전 산출물 |
| B TEST iOS1.0.1(56) | 별도 TEST bundle의 signed Release AOT·서명·격리 서버 설정·설치 확인, iPhone Owner UI PASS |
| 최신 통합 배포용 iOS/Android | 아래 실행 마감 절에서 새 빌드 번호·소스·서명·설정·산출물을 확정할 대상 |

TEST56을 운영 서버에 연결된 App Store 제출 후보와 동일하게 취급하지 않는다. 기존 APP40 인증 설정 누락을 반복하지 않도록 운영 Supabase·Google 설정 포함 여부를 빌드 preflight와 실제 binary에서 확인하는 검사를 사용한다. 기존 Kakao/Apple 권한·릴리스 서명·Analytics 상태도 유지/검증 대상이다.

Apple APP41 심사 실패 원인은 당시 확인한 Guideline4 Design의 외부 브라우저 인증 동작이었다. 시스템 인증 수정과 iPhone 검수는 완료했지만, Apple 재심사 승인이나 신규 빌드 스토어 업로드/제출 완료는 이 보고 시점에 확인되지 않았다. App Store Connect 상태와 제출 빌드 선택은 제출 직전 다시 확인한다.

## 7. 기존 서비스 차단 해제 시 확인할 연결

TASK16-K의 운영 읽기 감사 스냅샷에는 기존 **363시험/1,014문항/52 Math set**이 기록돼 있다. 연결된50개 Math Evidence Package와 정책 digest가 일치했으며, 수리 공개0은 데이터 부재가 아니라 기존 공개 제한이었다. 이 수치를 현재 런타임 재조회 결과로 오인하지 않는다.

| 연결 | 기존 감사에서 발견한 차이 | 이번 통합에서 필요한 확인 |
|---|---|---|
| UI/기능 플래그 | WEB naturalHeld, Native TEST 전용 진입, 혼합 준비중 분기 | 지원 경로와 시험별 공개 scope를 함께 확인해 차단 해제 |
| Registry/Evidence | 한양2026 상경은 기존 운영 ID/2문항/Math leaf/공식 Package 존재 | 동일 ID·공식 근거 재사용. 무조건 전체 허용/시험 복제 금지 |
| 자연 대표 identity | TEST 한양2024 자연 오전 ID와 운영2024자연 모의는 다른 시험 | 동일 시험 여부를 원문/수집 이력으로 대조; TEST ID를 모의시험으로 치환하지 않음 |
| RPC | 운영에는 coaching/mixed coaching/quote/continue 신규 계약4개 미설치 기록 | 실제 현행 함수/ACL을 재확인하고 필요한 증분만 승격 |
| Provider admission | runtime flag 외 단일 Math leaf 허용 제한 기록 | 실행 allowlist·선정 scope·분리 Secret·Worker 연결을 함께 검증 |
| 이용권/History | 운영 continuous_cycles=false, TEST true 및 함수 정의 차이 기록 | 기존 원장 보존, 1/0 반복·중복/실패/만료·History 회귀 |
| 베타 공개 | 기존 인문160 scope, 수리0 기록 | 일일1/00KST/이월0/11월11일 종료와 승인 Math/혼합 scope 연결 |
| Storage | 기존 비공개 원본·owner/서명/hash 계약 | TEST 학생 사진·세션을 운영으로 복사하지 않고 운영 제출 경로 검증 |

기존 TEST 전체 install/seed SQL을 운영에 그대로 적용하지 않는다. 기존 데이터가 있는 함수·권한·공개 계약에 맞춘 증분과 복구 절차를 사용한다. 차단 해제는 실제 평가 경로·저장·공개·이용권 조건을 갖춘 범위로 검증해야 하며, 화면 문구만 바꾼 상태를 서비스 통합 완료로 보고하지 않는다.

## 8. 남은 품질·출시 항목

1. 실제 손글씨의 부호·지수·분수·계수·표 수치 오독. 학생 확인·수정은 방어 장치이며 정확한 자동 인식을 보장하지 않는다.
2. 기존 iPhone 카메라 사진의 전사 확정 이후 실제 평가·무료 재첨삭·History 전체 흐름, 처리 중 진행 표시. 저장 결과 열람 PASS와 분리한다.
3. Native 상경 혼합 신규 사진 제출. 서버/WEB 혼합형 PASS만으로 Native 입력 경로를 PASS로 처리하지 않는다.
4. 공식 평가 기준별 개선 과제 우선순위, 구체적인 개념·힌트·완성 풀이. 개선 과제 최대5개 제한은 품질 순위 검증과 별개다.
5. 단독 수리 입력 화면의 문제 본문 텍스트 나열/공식 문제 PDF 연결 GAP.
6. 운영 Registry·RPC·Provider·Storage·beta/반복 사이클의 실제 연결과 기존 인문 회귀.
7. 최신 운영용 iOS·Android 산출물과 기기/스토어 제출 전 검증. APP41과 기존 사용자/원장 기록 보존.

답안 근거 가독성은 Owner가 현재 수준을 수용했으므로 위 P0를 이유로 그 UI의 전면 개편을 다시 시작하지 않는다. 이후 데이터로 개선할 항목과 출시 전 실제 기능을 막는 항목을 구분한다.

## 9. 이번 통합·차단 해제·배포 빌드 실행 마감

후속 실행: 2026-11-04 KST. 이전 검수 범위는 위 절에 보존하고 이번 변경을 별도로 기록한다.

### 구현·검증

- APP 자연계의 환경 일괄 차단을 제거했다. 공개 Catalog의 정확한 exam/question/leaf 연결과 서버 Math 실행 허용을 함께 요구한다. Catalog50개 이내 초기 공개 범위를 사용하며 임의 문항 연결·무조건 전체 공개는 하지 않는다.
- Native 혼합형 사진의 기존 Math 인식·확인을 preparation 모드로 재사용한다. 확인한 attempt/extraction 참조와 원본/본문 hash를 기존 Essay 시험 회차 하나에 전달한다. 입력 변경 시 제출 차단, 별도 Math 차감 없이 기존 시험 단위 이용권/History를 사용한다.
- Math 초기/반복 사이클은 공통 일일 베타 claim과 서버 quote의 이용권 출처를 사용한다. 학생 동의한 grant를 저장해 요청에 고정한다. 응답 유실은 같은 키/출처 재시도, 서버의 금액/출처 변경 거절은 재동의, 이전 앱의 출처 없는 요청은 기존 서버 회차 복구만 허용한다. 무료 재첨삭에서는 일일 claim을 호출하지 않는다.
- 앱 모든 사용자 표시 크레딧/Credit을 **이용권**으로 통일했다. 구매 상품1/3/5/10개, 잔액·사용/구매 내역·만료·첨삭/오류/출처·접근성 표시를 포함한다. 약관·환불조건 및 자동 지급/지연 문의 안내는 상품 구매 버튼 아래에 모았다. 내부 API/DB 이름·IAP 상품 ID·가격·영수증 처리는 유지했다.
- APP 전체 **1,434 PASS / 7 SKIP**. 이후 서버 거절 재동의·이전 요청 복구의 추가 보완은 **집중9 PASS**. 첫 통합1431PASS와 이후 표시/출처 연결 결과를 구분한다. 새 mixed 테스트의 fake-clock 종료 문제와 기존 hold문구 기대값, 무료 rewrite fixture 누락을 정정했다. 실제 Provider 호출·iPhone 신규 제출 PASS로 계산하지 않는다.
- WEB은 실제 운영 c9bda913을 기반으로 기존 Math23개 커밋을 선택 통합했다. 운영 Analytics/관리/결제 파일 보존, 시험 전체 admission·공식 PDF·최대5개 과제·수식/힌트·서버 공개·History 재사용. 최종1705PASS/4SKIP·lint/type/Next/Cloudflare Functions 빌드 PASS.

### 기존 DB·공식 근거 재확인

운영 read-only snapshot: active Math100leaf/52set 중 canonical98leaf/50시험. 나머지는 legacy 건국 standalone1과 합성 검증1이며 합성은 공개 대상이 아니다. 실제 `essay_material_runtime_package`로 **인하 자연계15시험과 한양2026 상경1시험**의 기존 승인 패키지16개를 조회했다. question/criteria/intent 근거, digest, canonical 문항 연결을 확인했다. `NEEDS_REVIEW` 표시는 기존 `runtimeApproval.APPROVED`의 selected-question 승인 계약과 함께 해석하며, 상태를 임의 VERIFIED로 덮어쓰지 않는다.

초기 후보는 **자연15시험45문항 + 상경1시험 Math1문항 = canonical46leaf**, 기존 건국1leaf를 보존한47leaf다. 상경의 Essay Q1과 Math Q2는 기존 하나의 시험이다. 의예와 기타 준비 범위, 미연결/합성, TEST 전용 한양2024 자연 오전 ID는 이 초기 활성화에서 제외한다. 기존 시험·문항 DB를 신규 생성하거나 TEST 원본/학생 계정을 운영으로 복사하지 않는다. 데이터 연결 확인을 시험별 평가 품질 PASS로 취급하지 않는다.

운영 Provider Math 실행 플래그/OPENAI/model/전용 Secret·추출/평가 Worker credential 존재를 읽기 확인했다. 기존 운영 Secret 변경 없음. 실제 공개는 신규 expansion scope, DB Catalog/admission, coaching·반복 사이클·일일 베타 연결 증분이 모두 갖춰져야 한다. 기존 ESSAY_PUBLIC_EXAMS에16대상이 이미 있어 기존211scope 자체를 덮어쓸 필요가 없다.

### DB 증분·검수 경계

운영 파일/함수 존재를 배포 완료로 간주하지 않는다. 기존 운영에는 신규 공통 coaching/quote/continue4 RPC가 없어 증분 후보3개(core, exact scope, beta source)를 작성했다. 기존 함수 원문·owner/ACL·run-table 구조 hash로 사전 조건을 검사하고 한 transaction에서 적용한다. 기존 원장·답안·History·프로필/결제 자료의 UPDATE/backfill 없이 필요한 함수·추가 학습 이력만 연결한다.

로컬 PG17: 운영 함수11개 원문·ACL 재현, canonical Math131회귀, 중간3지점 실패 atomic rollback,6회1/0반복·중복/실패·14일/beta기한, 정답 마스킹/명시 공개·History·인문 결과 byte동일을 검사했다. 독립 리뷰의 동시 힌트 키 충돌·1단계 전2단계 공개·공개 전후 재작성 시점flag도 후속 보완했다. scope/beta는 synthetic47문항 동작 검사와 실제 운영16패키지 읽기 근거를 구분한다. TEST/운영 원격 적용·실제 사용자 E2E와 같은 증거는 아니다.

### 실제 격리 TEST 증분 적용

TEST 전용 원문9함수 guard와 독립 리뷰를 통과한 증분만 `kpqbedylxlyntrrfybpn`에 적용했다. 신규/변경6함수의 정의·owner·ACL·search_path가 기대값과 일치하고, 기존 답안·평가·회차·원장·공개/힌트 기록10종의 행 수가 동일했다. 운영 SQL 후보3개는 적용하지 않았다.

실제 HTTP: 기존 계정 로그인, 무료 재첨삭 이용권0개/included 견적, 익명 신규RPC 접근 거절 PASS. 기존 계정 잔액0으로 자연/상경 최초 견적은 `INSUFFICIENT_CREDIT`이므로 유료 출처와 출처 변경 거절은 원격 NOT_VERIFIED다. 원장·History 전후 동일, Provider/신규 평가/일일 지급 호출0. 전체 실제 smoke는 **PARTIAL**이며 로컬 PG17 유료/무료/재시도 검증과 구분한다. 캠페인·scope가 없는 TEST에 일일 beta나 이용권을 새로 지급하지 않았다.

검토 패키지: WEB 저장소 `supabase/candidates/release57_math_commerce_20261103/`. core/scope/beta 후보, exact postflight, HOLD-only 복구, 로컬 검증 로그, TEST 실제 적용/HTTP 영수증을 포함한다. 웹 패키지 문서·SQL commit은 `3ac8269`, 실행 코드 artifact는 `c9fafea`다.

### 배포 영수증

<!-- RELEASE58_RECEIPTS -->

| 항목 | 상태 |
|---|---|
| APP 실행 소스 | `5b5e5a859a772f8f6af2716f1a1f3cec46a156d5`, `codex/app-review-candidate-b-20261103` |
| WEB 실행 소스 | `c9fafeace47dbab7b58af19ea0d5e636f681ad0e`, production 기반 `codex/math-commerce-release-20261103`; SQL/증거 후속 `3ac8269` |
| APP 전체 회귀 | **1,480 PASS / 기존7 SKIP / 0 FAIL**, Analyze0, Wiki handoff PASS |
| WEB 전체 회귀 | **1,705 PASS / 기존4 SKIP**,233파일 PASS/3 SKIP; Next/TypeScript/Functions/경계 PASS; lint0오류·기존2 warning |
| iOS1.0.1(57) | 이용권 표시/출처 연결까지 소스8542a49의 signed IPA·Archive 완료·보존. 긴급 요청으로 중단하지 않음 |
| iOS1.0.1(58) | 업데이트 기능 포함 signed App Store IPA·Archive PASS, codesign deep/strict·Apple로그인 entitlement·debug금지·실제AOT운영 인증값 PASS |
| Android1.0.1(58) | signed AAB PASS(99,632,168bytes), jarsigner·실제AAB protobuf package/version58·merged release manifest/기존권한·운영AOT인증값 PASS |
| WEB artifact | 운영 public config 포함 production tar.gz 준비; 실제 운영/TEST 배포0 |
| Math TEST 증분 | 실제 적용·postflight PASS, 실제 source smoke PARTIAL(기존 잔액0), Provider0 |
| 운영 수리/상경 증분·공개 플래그 | 준비·로컬 검증, **운영 미적용** |
| 업데이트 정책 Migration | 후보·로컬69 PASS, **운영·TEST 모두 미적용/비활성** |
| 스토어 업로드/제출·58 기기 설치 | 미실행 |

최종 산출물 보관 폴더: `/Users/woojinchang/development/legendstudy-private-backups/app-review-integration-20261103/candidate-b/release58/`. 기존 APP41·A48·TEST56·release57과 원래 브랜치는 보존했다. 빌드 산출물은 정식 서명된 배포 후보이며 스토어 제출/심사 승인/운영 활성화 완료가 아니다.

초기 전체 회귀에서 업데이트 조회 timeout 타이머가 외부 ProviderContainer보다 먼저 닫힌 화면에 남아50개 shell 검사가 실패했다. gate/controller 종료 시 소유한 deadline을 취소하도록 수정하고 기존 테스트를 숨기거나 비활성화하지 않은 채 전체1,480PASS로 마감했다. Android 최초 `--no-pub` 빌드에서는 이전 개발용 integration_test 등록 파일이 남아 compileReleaseJava가 실패했다. 로컬 Flutter SDK의 해당 옵션이 플랫폼 재생성을 생략함을 확인했고, 생성 파일 수동 편집/의존성 업그레이드 없이 기본 릴리스 생성 절차로 재빌드하여 PASS했다. PDFium 다운로드 오류는 이번 최종 빌드에 없었다.

앱 표시의 이용권 통일은 Native UI·오류·접근성·수량을 대상으로 확인했다. App Store Connect/Play Console의 상품 ID·가격·상품명 자체는 변경하지 않았으므로 OS 결제창의 스토어 등록 상품명은 별도 확인 대상이다.

## 10. 긴급 추가 — 앱 업데이트 확인

[상세 구현·A–K 검증](app-update-check-20261104.md), [비활성 Migration/검증/적용 절차](../supabase/candidates/app_update_policy_20261104/README.md).

기존 설정 조사에서 재사용 가능한 앱 버전 정책은 없었다. 결제용 설정을 변경하지 않고 최소 private 플랫폼 정책 후보와 공개 읽기 RPC를 작성했다. 기존 Native 설치 버전 채널, Supabase 클라이언트, SharedPreferences, 디자인/라우터/공식 스토어 링크를 재사용하며 별도 WebView·외부 업데이트 SDK는 추가하지 않았다.

- iOS/Android별 숫자 version/build 비교. 실제 공개 확인 tuple·시각·근거가 최신 tuple과 일치할 때만 안내한다. 심사/TestFlight/내부57·58을 최신 출시로 지정하지 않았다.
- OPTIONAL 기본: 나중에/업데이트하기. 같은 공개 tuple은24시간 미루고 새 tuple은 다시 안내한다.
- REQUIRED: Owner 승인된 minimum tuple과 시각/근거가 있을 때 minimum 미만만 차단한다. 초기 양 플랫폼은 disabled/OPTIONAL/latest·minimum 미설정이다.
- 정책 조회3초 timeout·오류·미설치·잘못된 값은 정상 앱 이용. 인증/온보딩은 미루고, legacy/WEB 프로필도 기존 규칙대로 인정한다. 앱 복귀/중복/늦은 비동기 응답/화면 종료 경합을 방어한다.
- 기존 APP41에는 이 클라이언트 기능이 소급 설치되지 않는다. 새 기능 포함 버전부터 동작하며 APP41을 운영 서버에서 강제로 차단하는 별도 변경은 하지 않았다.

집중 검사는 업데이트45개+온보딩13개+기존 기기 QA fixture10개 = **68 PASS**. 전체 회귀1,480PASS에 포함되며 합산하지 않는다. SQL은 별도 로컬 PostgreSQL17 비슈퍼유저69개 PASS, 재현 스크립트와 RLS/권한/원복 증거 포함. 공개RPC는 anon/authenticated 읽기만 허용하고 private 직접 읽기/쓰기를 차단한다. 운영/TEST에 정책은 설치하지 않았다.

Mock Native 화면 `optional-mock.png` / `required-mock.png`는 위 보관 폴더에 있다. 390×844 실제 위젯 렌더와320×568/글자1.5배 overflow를 확인했다. 화면의1.0.2는 fixture이며 실제 출시 버전이 아니다. 실제 iOS/Android 기기의 팝업·스토어 이동, 실제 공개 버전 설정은 **NOT_VERIFIED**다.

변경 파일: `lib/core/config/app_information.dart`, `lib/features/app_update/`3파일, `lib/app/legendstudy_app.dart`, `lib/features/onboarding/onboarding_gate.dart`, `test/app_update_test.dart`, 위 정책 후보와 Wiki. 수리/상경 통합에서는 기존 Math gateway/session, mixed preparation, Essay selection/admission, 공통 이용권 표시와 billing UI를 변경했고 기존 평가 엔진·가격·상품 ID는 보존했다.

## 11. 운영 반영 순서와 판정

1. Owner가 운영용 수리/상경 core → scope → beta 증분 후보3개를 검토·승인하고 정확한 기존 DB 상태에서 적용·postflight한다. 기존 History/원장과 인문 결과를 보존한다. TEST install/seed를 운영에 복사하지 않는다.
2. 승인 범위16시험의 `ESSAY_BETA_EXPANSION_EXAMS`, 보존 legacy를 포함한47leaf의 `MATH_PUBLIC_LEAVES`, `ESSAY_CONTINUOUS_CYCLES_ENABLED=true` 설정 후보를 적용하고 WEB production artifact를 배포한다. 기존 EXAM_RUNTIME/MIXED_SESSION/Math 실행값은 유지한다. 이번 경로에서 사용하지 않는 `ESSAY_REVIEWED_RUNTIME_ENABLED`는 추가하지 않아 별도 단일 문항 경로를 임의 개방하지 않는다. 가려진 Secret을 저장하거나 기존211 공개시험 allowlist를 통째로 교체하지 않는다. 실제 인문 회귀·유료1/무료1·History·혼합 전체 완료를 확인한다.
3. APP58 동일 Backend로 실제 기기 신규 사진→OCR확인→평가→재첨삭→History 및 혼합형을 검수한다. 기존 저장결과/UI PASS와 전체 실기기 신규 제출 PASS는 구분한다.
4. 업데이트 정책 Migration은 별도 승인 후 disabled 상태로 적용·postflight한다. 실제 Store 공개를 확인한 exact tuple만 등록한다. REQUIRED는 다시 Owner의 명시적 최소 버전 승인 대상이다.
5. 남은 실기기/품질·운영 연결을 검수한 뒤 Owner가 스토어 제출·베타 활성화 여부를 결정한다. 현재 업로드/제출/운영 활성화0이다.

**현재 판정: 통합 코드·배포 후보 준비, 운영 활성화 및 스토어 제출 HOLD.** 신규 업데이트 정책의 원격 적용은 Owner가 이번 지시9항에서 먼저 승인을 받도록 명시했고, [AGENTS.md4항](../AGENTS.md)의 기본 DB 적용 절차도 따른다. 운영 DB/Auth/Credit/Ledger/결제 변경 금지 조건을 지키며 SQL 후보까지만 준비했다. 수리/상경의 실제 운영 차단 해제는 아직 완료하지 않았다. 남은 P0는 운영 증분/설정·실제기기 전체 루프·OCR/공식 힌트/해설 품질과 실제 업데이트 안내 검수다.


## 부록 A. 최종 배포 산출물

- iOS: `legendstudy-1.0.1-58.ipa`, 33,981,223bytes, SHA256 `88ecaf7e91dd9fe05b79113e5e0119295bb9dbeac2f043a2592a87261a28a01e`. 같은 폴더 `Runner.xcarchive` 보존.
- Android: `legendstudy-1.0.1-58.aab`, 99,632,168bytes, SHA256 `5ac0a0448a9f65c49d90f69cf4c0b393e9cd655ee2514d77e424fc6d1e5c7987`.
- WEB: `web/legendstudy-web-c9fafea-production.tar.gz`, SHA256 `a83ef963b39814d5141de8e5e4264131e6cfec3c5b4403853a484f1ee63de504`. 운영 public config artifact이므로 TEST에 그대로 배포하지 않는다.
- `manifest.json`, 플랫폼별 receipt, 빌드/검증 로그, `SHA256SUMS`, Native Mock PNG 포함. App Store/Play 업로드0, 실제 기기58 설치0.

## 부록 B. 기존 Registry 기반 최초 공개 후보

아래16시험은 문항 연결/공식 평가 Package의 읽기 조회 PASS 범위다. 실제 운영 신규 평가·전문가 품질 검수 PASS를 뜻하지 않는다. 자료 연결은 PASS지만 현재 실제 서비스 상태는 모두 **BLOCKED(운영 RPC·공개 설정 미적용)**, 첨삭 품질은 **NEEDS_REVIEW**다. 운영 적용 후 학생 제출/저장까지 확인해야 서비스 READY로 전환한다. legacy 건국1문항은 별도로 보존한다.

| 기존 시험 | 경로/문항 |
|---|---|
| 2022학년도 인하대학교 모의논술 자연계열 | Math 3문항 |
| 2022학년도 인하대학교 수시논술 자연계열 오전 | Math 3문항 |
| 2022학년도 인하대학교 수시논술 자연계열 오후 | Math 3문항 |
| 2023학년도 인하대학교 모의논술 자연계열 | Math 3문항 |
| 2023학년도 인하대학교 수시논술 자연계열 오전 | Math 3문항 |
| 2023학년도 인하대학교 수시논술 자연계열 오후 | Math 3문항 |
| 2024학년도 인하대학교 모의논술 자연계열 | Math 3문항 |
| 2024학년도 인하대학교 수시논술 자연계열 오전 | Math 3문항 |
| 2024학년도 인하대학교 수시논술 자연계열 오후 | Math 3문항 |
| 2025학년도 인하대학교 수시논술 자연계열 오전 | Math 3문항 |
| 2025학년도 인하대학교 수시논술 자연계열 오후 | Math 3문항 |
| 2026학년도 인하대학교 모의논술 자연계열 | Math 3문항 |
| 2026학년도 인하대학교 수시논술 자연계열 오전 | Math 3문항 |
| 2026학년도 인하대학교 수시논술 자연계열 오후 | Math 3문항 |
| 2026학년도 한양대학교 수시논술 상경계열 | Q1 Essay + Q2 Math |
| 2027학년도 인하대학교 모의논술 자연계열 | Math 3문항 |

정확한 exam/question/leaf ID와 package digest는 WEB `src/data/essay-beta-expansion.json`, SQL 범위 검증은 `supabase/candidates/release57_math_commerce_20261103/scope-contract.json`에 고정했다. 미연결/합성/의예·그 밖의 미검수 시험은 무조건 공개하지 않는다.
