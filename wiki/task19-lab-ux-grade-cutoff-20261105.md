# TASK19 — LAB 안내와 평가원 등급컷

## Owner 범위와 보존
2026-11-05 Owner는 iOS 1.0.1 심사 통과를 알리고 후속 업데이트 A/B를 승인했다. APP58 산출물·버전, 운영 평가/이용권/History, 다른 PDF 개발 브랜치를 보존한다. Store 제출·운영 DB 적용은 승인 범위 밖이다.
[기존 베타](essay-beta-daily-v2.md), [공통 공개 계약](app58-expanded-production-connection-20261104.md), [등급 판정](day-8-d3-grade-result.md), [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)을 재사용한다.

## A — 구현 및 검증
- 베타 안내를 인문·사회·상경·자연으로 수정. CTA 무료 첨삭 시작하기. 매일 00시 KST/이월 없음/가입3·구매 유지. 실제 종료 11/11 00KST와 표시 11/10 23:59 유지. 체크박스·scrollable modal·무료 재첨삭 서버 정책 변경 없음.
- 상세 준비 중 표시는 통합 공개 목록 외에도 기존 standalone Math의 정확한 exam/question/leaf 연결과 Provider 활성 상태를 확인한다. 자연계 이름만으로 공개하지 않는다. 미연결 질문·중복/잘못된 leaf는 준비 중을 유지한다. 서버 제출/정산 권한은 변경하지 않는다.
- 운영 읽기 확인: 건국2026자연 exam `25dc068b-4672-56e1-b8df-08ee8800e2f6`, Q1 `cea40cf3-dc05-507a-a6eb-fd5e1e1847bb`, leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3` release_catalog 연결. 전체4문항 공개를 주장하지 않는다.
- Flutter beta/gateway/상태 단위·위젯19 PASS, catalog/session/credit/history/round 회귀24 PASS, analyze 오류0.
- 새 실기기·실제 Provider 검증 NOT_VERIFIED. 기존 평가 재호출/차감0. 수정 화면 런타임 검수는 별도로 필요하다.

## B — 조사 진행
운영 읽기에서 대상11시험 모두 기존 exams/content_items와 연결됨. grade_cutoff_versions는 0행. 기존 schema는 raw_absolute/raw_estimate 전용이므로 표준점수를 minimum_scores에 넣지 않는다. 기존 게시글11개 이미지224개를 임시 확보·로컬 Vision 후보 추출했다. 원점수 범위 및 표준점수 자료 공존; OCR 후보를 검증 완료 데이터로 취급하지 않는다.

### 보존 검토 7항
1. 시험일/수집일/검수·정정일 분리.
2. 게시글·원본자료 URL/해시/버전으로 재현.
3. 기존 판정·기록 소급 UPDATE 없음; 새 출처 revision 보존.
4. 기존 canonical content/subject ID 사용; 신규 학생 identity 없음.
5. 공개 시험 기준 자료이며 학생 학습·지원 결과와 별개.
6. 공개 자료 조회 목적, 개인정보 추가 수집 없음.
7. 추정 원점수와 공식 표준점수·학생 실제 성적을 구분. 누락값 생성 금지.

## 상태
A 코드/로컬 회귀 PASS, 실제 화면 PARTIAL. B 진행 중. 운영 적용0·스토어0·다른 브랜치 병합0.
