# 논술 LAB 대학별 브랜드 히어로 — 2026-10-26

## 현재 구현과 Owner 결정

[기존 인하/화이트 히어로](inha-standby-20261026.md)와 [WEB 작성 UI](essay-web-studio-ui-20261026.md)를 확장한다. Catalog 42개를 유지하며 공통 UniversityEssayHero와 university-brands.json 설정을 사용한다. 대학별 코드 복제·공개 범위 변경은 없다. 흰 배경, 대학색 상단 강조선, 중립색 본문/버튼, 원본 로고 및 흰 컨테이너를 사용한다. primary/secondary는 공식 팔레트 안의 UI 선택이지 대학의 단일 대표색을 새로 정의하지 않는다.

Manus `27개대학_공식브랜드컬러_로고색상.xlsx` 27개, Claude `2027_논술33개대학_심볼색상.xlsx` 33개 모두 기존 Catalog와 매칭. Claude 목록은 공식 CI와 비공식 출처가 혼재하며 개별 출처 URL이 없다. 코드만으로 공식값으로 승격하지 않는다. 두 자료 합집합 37개, 둘 다 없는 5개는 공통색 유지.

## 확인 결과

- A 공식 HEX 원문 확인 1개(부산), B 공식 RGB 환산 11개. 공식 포인트 적용 12개.
- C Pantone만 확인 5개, D 색상명만 확인 2개: 화면값은 임시 UI 색상으로 명시한다. C/D는 Manus 조사 분류이며 모든 원문 숫자를 이번에 재확인했다는 의미가 아니다.
- E 수치 미확인/원문 재확인 대기 23개. 이 중 인하·건국은 Manus가 A로 보고했으나 인하 연결종료/건국 WAF로 원문 재대조 보류. 기존 UI 색상을 보존한다. Manus 보고상 A3과 이번 직접확인 A1을 구분한다.
- 공통 브랜드 설정/화이트 히어로 적용 42개. 공식색 확정 보류가 서비스 공개 보류를 뜻하지 않는다.
- 경희: 공식 이미지 R164 G15 B22 → **#A40F16**. Manus #A40F02는 오류이며 Claude와 원문이 일치한다.
- 서울여: R158 G26 B32 → #9E1A20, 이화: R0 G70 B42 → #00462A, 항공: R0 G40 B112 → #002870. Claude값 대신 원문을 따른다.
- 추가 차이: 국민 R0 G79 B159 → #004F9F, 가톨릭 R12 G46 B134 → #0C2E86. 외대는 공식 Primary HUFS GREEN #146E7A를 선택하며 Claude의 Navy는 다른 팔레트다.
- 고려 Pantone202C/서강1805C를 HEX로 변환하지 않았다. 기존 임시색 #8B0029/#9B1838을 공식값으로 표시하지 않는다.

## 대학별 설정과 원문

A/B만 공식 포인트. 나머지 HEX는 **임시 UI 색상**이며 공식 HEX가 아니다. secondary·원자료 값·매칭 여부·RGB·원문 URL은 WEB `src/data/university-brands.json`에 함께 관리한다. 로고는 기존 `university-logos.json` 파일 경로·바이트·비율을 보존했다.

| 대학 | 분류 | 적용 포인트 | 근거 |
|---|---|---|---|
| 가천대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 가톨릭대학교 | B | #0C2E86 | [공식 원문](https://www.catholic.ac.kr/ko/about/signiture.do) |
| 강남대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 건국대학교 | E | #006B3F | [공식 원문](https://www.konkuk.ac.kr/konkuk/2109/subview.do) |
| 경기대학교 | E | #244A6A | [공식 원문](https://www.kyonggi.ac.kr/www/contents.do?key=5093) |
| 경북대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 경희대학교 | B | #A40F16 | [공식 원문](https://www.khu.ac.kr/kor/user/contents/view.do?menuNo=200033) |
| 고려대학교 | C | #8B0029 | [공식 원문](https://www.korea.ac.kr/ko/373/subview.do) |
| 광운대학교 | D | #244A6A | [공식 원문](https://www.kw.ac.kr/ko/life/symbol01.jsp) |
| 국민대학교 | B | #004F9F | [공식 원문](https://www.kookmin.ac.kr/comm/menu/user/0a4f7cf187cc3164678352bc3f4575b3/content/index.do) |
| 단국대학교 | E | #244A6A | [공식 원문](https://dankook.ac.kr/dku_ui) |
| 덕성여자대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 동국대학교 | E | #244A6A | [공식 원문](https://www.dongguk.edu/page/261) |
| 동덕여자대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 부산대학교 | A | #005BAA | [공식 원문](https://www.pusan.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN156) |
| 삼육대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 상명대학교 | E | #244A6A | 자료 없음; 공통색 |
| 서강대학교 | C | #9B1838 | [공식 원문](http://www.sogang.ac.kr/intro/symbol/s_colorsystem.html) |
| 서경대학교 | E | #244A6A | 자료 없음; 공통색 |
| 서울과학기술대학교 | C | #244A6A | [공식 원문](https://www.seoultech.ac.kr/intro/symbol/logo/symbol) |
| 서울시립대학교 | E | #244A6A | [공식 원문](https://www.uos.ac.kr/kor/html/auos/symbol/ui/ui3.do?identified=anonymous&) |
| 서울여자대학교 | B | #9E1A20 | [공식 원문](https://www.swu.ac.kr/swu/797/subview.do) |
| 성균관대학교 | B | #072A60 | [공식 원문](https://www.skku.edu/skku/about/symbol/symbol_01.do) |
| 성신여자대학교 | E | #244A6A | 자료 없음; 공통색 |
| 세종대학교 | B | #C3002F | [공식 원문](https://pr.sejong.ac.kr/news/promotion/basic-element.do) |
| 수원대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 숙명여자대학교 | B | #003087 | [공식 원문](https://www.sookmyung.ac.kr/kr/intro/ui.do) |
| 숭실대학교 | C | #244A6A | [공식 원문](https://ssu.ac.kr/학교소개/학교상징/ui/전용-색상/) |
| 신한대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 아주대학교 | C | #244A6A | [공식 원문](http://www.ajou.ac.kr/kr/intro/uibasic01.do) |
| 연세대학교 | E | #244A6A | [공식 원문](https://designcenter.yonsei.ac.kr/) |
| 을지대학교 | E | #244A6A | 자료 없음; 공통색 |
| 이화여자대학교 | B | #00462A | [공식 원문](https://www.ewha.ac.kr/ewha/intro/ui-si04.do) |
| 인하대학교 | E | #005BAC | [공식 원문](https://www.inha.ac.kr/kr/1828/subview.do) |
| 중앙대학교 | B | #2155A4 | [공식 원문](https://www.cau.ac.kr/cms/FR_CON/index.do?MENU_ID=230) |
| 한국공학대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 한국기술교육대학교 | E | #244A6A | Claude 코드/색명만, 공식 수치 미확정 |
| 한국외국어대학교 | B | #146E7A | [공식 원문](https://www.hufs.ac.kr/hufs/11129/subview.do) |
| 한국항공대학교 | B | #002870 | [공식 원문](https://kau.ac.kr/images/ui/ui_1_14.png) |
| 한신대학교 | E | #244A6A | 자료 없음; 공통색 |
| 한양대학교 | D | #004483 | [공식 원문](https://www.hanyang.ac.kr/web/eng/colors-fonts) |
| 홍익대학교 | E | #244A6A | [공식 원문](https://www.hongik.ac.kr/kr/introduction/color.do) |

## 보존 검토와 검증

Longitudinal 일곱 질문: (1) 공개 디자인 근거의 확인일을 별도 기록, (2) 기존 로고/Registry 원본 유지, (3) 색상 수정 이력은 Git·원본 조사자료로 보존, 학생 UPDATE 없음, (4) 계정 identity 불변, (5) 학습/선택/결과 데이터 무변경, (6) 신규 개인정보 수집·권한·retention 변경 없음, (7) RGB 환산/임시 UI 색상을 공식 원문 HEX와 구분한다.

Typecheck PASS, Lint 오류0/기존 math-release hook 경고2, 관련 3파일7검사 PASS, Production Build PASS. 기존 Node24/요구22 엔진 경고는 유지. Catalog42 ID·로고 파일 존재·원문 RGB 환산·A/B 적용 경계를 자동 확인했다. 실제 Provider·평가 제출·SQL·Credit 사용 0. APP/DB/Worker/Secret/결제 정책 변경0.

## 배포·복구

WEB `86282c7` commit/push. Pages `e8def797-e14c-40f0-ad05-d50017f8fc7f` production/success, source86282c7, clean upload. 배포 설정·Secret PATCH 없음. Worker는 이전 e85c587b 배포를 변경하지 않았다.

복구는 WEB 디자인 commit revert 후 동일 빌드/Pages 절차 또는 이전 Pages `460e65a3-30fc-4300-9c1a-71bbfff1aa48`로 복귀. DB SQL 실행·재실행은 없다. 기존 공개/첨삭/재진입 정책을 바꾸지 않는다.

증거: `~/development/legendstudy-materials/essay-validation-2026-10/university-brand-20261026/`의 두 조사자료 JSON, 공식 원문 HTML/텍스트/이미지, build/deploy 로그, deployment-public.json. 후속은 인하·건국 원문 접근 복구 후 A 확정과 다른 미확인 대학의 공식 수치 확보다. 새 로고를 임의 생성하거나 Pantone/이미지 픽셀로 공식 HEX를 추정하지 않는다.

## Production 화면 확인 범위

경희대 일반계정 PC 및 Chrome 반응형400px: 흰 배경 rgb255/255/255, 원문 강조색 rgb164/15/22, 로고 natural257×184/object-fit contain, 모바일 hero241px/가로넘침0. 2027모의 인문체육 선택→전체2문항/텍스트 입력/저장 버튼/빈 답안 제출비활성 확인. 내부 mock값 노출 없음, 대학명 중복 없음. 공식자료 링크 기존 URL 유지·일정 펼침과 출처링크 확인. Credit7→7, 답안 입력/제출하지 않음. 전체42개를 실사용자 첨삭 E2E로 검증한 것이 아니며 공통 컴포넌트·42설정 자동검사와 대표 실제화면 확인이다.
