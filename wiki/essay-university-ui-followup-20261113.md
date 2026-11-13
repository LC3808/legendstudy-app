# 대학 카드·로고 후속 수정 — 2026-11-13

[오전 UI·일정 작업](essay-university-ui-schedule-20261113.md)에 대한 Owner 12:14~12:15 피드백을 우선 적용한다.

- 지난 논술 일정 항목 전체 제거. 현재2027 일정은 유지하며 원본 이력 데이터는 삭제하지 않는다.
- 이화 녹색 교표·경북 빨간 Authority Mark·단국 파란 DKU·홍익 공식 흑백 심벌 원본으로 교체. CSS 재착색0, 원본 파일 SHA256/공식 페이지/asset URL을 university-logos.json에 기록하고 이전 파일 보존.
- 전체 카드2px #242424, hover/focus #111로 경계 명확화.
- 한신/한국공학/한국기술교육/수원/신한/서경/강남7개는 향후 서비스 대상에서도 제외. ‘서울공학대’는 Owner가 한국공학대로 명시 확인했으며 서울과학기술대는 유지한다.
- 탐색 전체/주요/검색/정렬/페이지에서 제외, 목록35개·3페이지. 공통 university-service-policy.ts에 영구 제외 사유를 명시했다. 원본 Catalog42 ID, Registry, 과거 자료와 직접 상세 URL은 보존하며 신규 서비스는 추가하지 않는다.

## 공식 원본

| 대학 | 공식 확인 페이지 | 적용 |
|---|---|---|
| 이화 | https://www.ewha.ac.kr/ewha/intro/ui-si01.do | 원본 녹색 symbol-mark.png |
| 경북 | https://www.knu.ac.kr/wbbs/wbbs/contents/index.action?menu_idx=194&menu_url=intro/about04 | ui_symbol01.jpg, 붉은 Authority Mark |
| 단국 | https://www.dankook.ac.kr/web/kor/dku_ui | est_ui_int01.jpg, 파란 DKU |
| 홍익 | https://www.hongik.ac.kr/kr/introduction/school-mark.do | img-symbol@2x.png, 공식 흑백 |

## 일곱 보존 검토

1. 공개 UI/서비스대상 Owner 결정이며 확인일과 이전 기록을 분리한다.
2. 이전 자산/데이터를 유지하고 원본 URL·SHA256·Git으로 복원 가능하다.
3. 화면 목록/항목만 제거하고 DB UPDATE/DELETE0이다.
4. 학생 identity·대학 UUID 변경0이다.
5. 개인 Learning/Decision/Outcome fact를 생성하거나 수정하지 않는다.
6. 신규 개인정보/권한/동의/retention 변경0이다.
7. 색 추정0이며 공식 흑백 심벌을 임의 컬러화하지 않는다.

## 검사

관련4파일24테스트, 변경파일ESLint, webpack production build(TypeScript 포함), diff-check PASS. 35카드/4로고 로드 및390px 화면·가로넘침0 확인. 기존 전체회귀7실패는 오전 보고서 참조; 이번은 변경 관련 회귀만 실행했다. API/DB/평가 Worker/Credit/공개304문항 변경0.

## 배포

직전 Pages349e36b6 기준 최신 snapshot으로 UI·새4로고만 반영한다. 기존 API bundle/routing/운영설정 유지. 운영 검증·배포 receipt는 후속 기록한다.

### 운영 완료

Pages `e6c7e088-1bed-459d-bdc9-3c1cd7c56751`, source `042be2b83b3b5b6d4d743898b2db2f888c5561d7`, 2026-11-13 12:25 KST success. [설정·라우팅·자산·Worker 비교](evidence/university-ui-followup-deployment-20261113.json) 모두 보존 PASS. 운영 로그인 화면에서35개/제외7개0/4로고 실제 표시/외대 지난일정 없음·현재2027 일정 유지 확인. 카드 CSS2px(브라우저 zoom으로 computed1.66667px 관측) 검정 경계 확인. Credit92 유지·답안 입력/제출0. 복구는 직전349e36b6 배포이며 SQL/env 역변경 없음. Wiki handoff PASS(11,973bytes).
