# GA4·서버 분석 역할과 수집 감사

[Phase 1](admin-analytics-phase1-20261104.md). 2026-11-04 읽기 전용. 기존 Analytics v1, Firebase/GA4 adapter, Data API를 재사용한다. 새 event warehouse/analytics 시스템/속성 생성 제안이 아니다.

## 책임 분리

| 질문 | 기준 시스템 | 관리자 WEB의 역할·금지 |
|---|---|---|
| 방문/세션/PV·검색/채널·광고캠페인·클릭/이탈·행동 퍼널 | GA4 | 기존 Data API 요약과 GA4 상세 진입 유지. 별도 행동 수집 DB나 자체 퍼널 엔진 금지 |
| 가입 완료·학생 제출·평가 완료·재첨삭·사용권·매출/환불 | Supabase 원본 | 기존 Analytics RPC/원장으로 확정 수치. 브라우저 완료 이벤트를 거래 확정으로 사용하지 않음 |
| 품질 정확성·보류·OCR·근거/힌트·정책별 비교 | 저장 결과 + 사람 검토 | 처리 성공과 정확도 구분. GA4에 원본 답안·전사·개인ID·검수내용 전송 금지 |
| 유입→가입→첨삭→구매 | GA4 관측 퍼널 + 별도 서버 확정 보고 | 동일 사용자/시각/동의/coverage 계약 검증 전 join·합산·전환율 산출 금지. 두 보고서를 나란히 이름을 구분해 표시 |

## 실제 연결 상태

| 대상 | 확인 상태 | 근거·미검증 범위 |
|---|---|---|
| 기존닷컴 property396674471 / stream5829568136 / G-295EQHYTCK | CONNECTED | 16:34:54 KST 실제 관리자 Data API 응답, 기간10-29~11-04 / Asia/Seoul. 활성42,267·신규30,839·세션98,987·PV180,054. 당일 포함 변동값; 신규+재방문 합산 금지 |
| 앱홍보 이벤트 | PARTIAL 실수신 | 같은 응답 impression102/77users, dismiss22/21, click1/1. snooze는 선택기간 미수신/지연가능. 설치완료나 store별기여 아님 |
| LAB stream16254992877 / G-MVHZ7HS214 | NOT_CONNECTED(운영 화면) | ‘LAB 이벤트 수집 설정 미연결·수집 비활성’, ‘보고서 미연결’. 최신 Wiki의 phase2 소스431a635 미배포와 일치. 실제31업무이벤트 수신PASS 아님 |
| home stream16255062112 / G-S4JZMP0141 | NOT_VERIFIED 수신 | 별도작업 Wiki에는 tag부착/로드 증거 존재. 이번 main stream Data API로 home 수신을 검증할 수 없음 |
| Native Firebase | NOT_VERIFIED 출시수신 | Analytics v1의 no-op 기본/설정주입 구조 존재. APP58 실제 Firebase event 수신을 이번 감사에서 확인하지 않음. WEB31정의를 APP수신으로 확대 금지 |
| 설치완료·교차서비스전환·유지율 | NOT_CONNECTED / NOT_VERIFIED | 앱홍보 클릭과 first_open/실설치는 다름. 동일property 내 별도stream 사용자 수를 더해 고유사용자로 만들지 않음 |

서버 `cloudflare/ga4-reporting.ts`는 property/stream/host 허용목록, admin_operator, 실제 auth user 검증, readonly Google scope, timeout·no-store를 적용한다. 브라우저에 서비스계정 private key를 제공하지 않는다. 현재 보고서는 summary/daily/channel/pages/promo4종이며 모든 business event의 수신 현황표가 아니다.

기존 GA4 복구 Wiki에는 11-03 LAB enhanced measurement의 page_load ON / history_change OFF / scroll·video ON 및 outbound·search·form·file OFF 결정이 있다. 과거 코드 comment의 ‘모두OFF’와 다르므로 **현재 Owner 결정과 실제설정 확인**이 우선이다. 이번에는 GA4 관리 설정을 변경하지 않았고 새 DebugView event도 발생시키지 않았다.

## 31개 업무 이벤트: 정의와 WEB 호출점

배포 WEB `src/lib/analytics/events.ts`31개/14개param allowlist를 보존한다. 소스의 `logAnalytics(AE.*)` 호출점 조사이며 **수신 증명과 다르다**. 운영 flag 비활성 상태에서는 이 호출점도 no-op이다.

| 이벤트 | 배포 WEB 호출점·의미 |
|---|---|
| app_open | 정의만, WEB 호출점 미발견 |
| sign_up / login | auth-forms, **status:started**. 가입/로그인 성공 건수 아님 |
| onboarding_complete | 정의만, WEB 호출점 미발견 |
| essay_lab_view / exam_select | source-exam-selection, resolved selection 시점 |
| university_select | university-essay-start |
| question_select | question panel 펼침 |
| essay_editor_open / essay_draft_save | writer focus / 기기·계정 저장 |
| essay_ocr_start / success / failure / apply | 4종 정의만, WEB 호출점 미발견 |
| essay_submit_start / accepted / rejected | exam-submit request시작/응답. accepted≠평가완료 |
| essay_processing_view / completed / failed | session-progress 클라이언트 관측. 백그라운드 서버완료 누락 가능 |
| essay_retry_requested | history에서 재처리 요청시작, 성공보장 아님 |
| essay_result_view | MY 결과보기 |
| essay_rewrite_start / submit / completed | rewrite 진입/제출/MY client관측. `is_free:!!parentId`는 실제 과금 확정 대체 불가 |
| credit_pricing_view / purchase_start / purchase_success / purchase_failed | 4종 정의만, WEB 호출점 미발견 |
| essay_growth_view | History 성장 진입 |
| essay_growth_detail_view | 정의만, WEB 호출점 미발견 |

총20개 이름에 호출점,11개는 정의만 확인. 전달param: platform,app_version,screen,exam_code,university_code,question_count,attempt_no,is_free,duration_ms,status,error_type,product_id,credit_count,source. 중복제거 onceKey는 브라우저 메모리 범위이며 기기간/세션간 서버 멱등성을 의미하지 않는다. page_view는 별도 GA 표준 이벤트이고 promo4종은 기존닷컴의 별도 기존 계약이다.

## Phase 2 확인 순서

1. 기존 수집 복구 작업의 최신 브랜치·Owner 승인과 조율. 이 문서만으로 LAB flag·GA 설정을 활성화하지 않는다.
2. 기존31개 중 제품에서 실제 호출하는 경로와 성공/시작 의미를 대조. 이름 삭제나 과거 이벤트 의미 소급변경 없이 status/전환조건을 명세한다. 결제확정은 기존 server ledger 보고 그대로 유지한다.
3. 승인된 TEST에서 stream별 DebugView/Realtime/지연된 Data API를 구분 검증. main·LAB·home·APP 각각 evidence timestamp/환경/수집범위 기록. 개인정보 없이 테스트한다.
4. 방문자 페이지 하나에 기존 main report를 보존하고 미연결 stream 상태를 별도 표시한다. 다른5페이지는 참조링크로 통합하되 이전 URL은 유지한다.
5. 광고·검색·캠페인·행동경로·가입/첨삭/구매퍼널은 GA4 내 기존 탐색 활용. 관리자WEB 자체 클릭/이탈/세션엔진을 새로 만들지 않는다. server 확정지표는 별도의 출처badge 유지.

이 작업의 연결판정은 일부 업무가 동작한다는 의미일 뿐 GA4 데이터 정확도/광고기여도 전체 인증이 아니다.
