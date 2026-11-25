# 35개 대학 브랜드 재점검 — 2026-11-13

[대학 카드 후속 수정](essay-university-ui-followup-20261113.md)에 이어 Owner가 전체35 로고·브랜드 컬러와 카드 내 균형을 재확인하도록 요청했다. 제외7개 정책은 그대로 유지한다.

## 구현과 근거

- 공식 UI에서 내려받은 원본14개로 교체: 서울시립·을지·가천·성균관·건국·숙명·동덕·성신·연세·경기·한양·항공·삼육·외대. ZIP 내부 파일은 재인코딩하지 않고 그대로 보존한다. 원본 URL·archiveMember·SHA256 기록.
- 서울시립: 입학처 헤더 대신 대학 공식 UI의 2023 심볼/로고타입 ZIP 내 symbol mark.png. 을지: 공식 UI ZIP의 엠블럼 기본형. 홍익: 공식 school-mark의 흑백 교표를 재확인하여 유지; 임의 컬러화0.
- 가천 #004E96, 상명 #0E207F, 서울시립 #004094 수정. 인하 #005BAC·한양 #1D2475는 공식 숫자 원문 재확인으로 검증 상태 승격. 서울시립 색상표의 HEX #004094와 RGB R10 G77 B155가 불일치하여 웹 HEX를 우선하고 상충 근거 기록.
- 35개 모두 출처를 재점검했다. 공식 디지털 수치19개 확인, 나머지16개는 Pantone/CMYK/색상명 또는 자료 접근 한계로 임시 UI 색상을 유지한다. 임시색을 공식색으로 승격하지 않는다. 서강 공식 본문의 Cardinal 명칭은 확인했으나 숫자 이미지 URL은 HTML 오류 응답이다.
- 원본 파일 변경 없이 opticalBounds로 주변 여백만 프레임에서 정규화. 심벌은 최대64px 높이, 가로형은 최대148px 폭, 카드 상단72px 영역. 원본 비율·색상 유지. 기존 원본과 제외 대학 Catalog/직접 URL 유지.

## 일곱 보존 검토

1. 공개 브랜드 정정이며 확인일/원본 출처와 현재 표시 상태를 분리한다.
2. 이전 자산과 Git 이력, 공식 원본 SHA256/ZIP member로 복원 가능하다.
3. 정적 UI 메타데이터만 수정하며 DB UPDATE/DELETE0.
4. 학생 identity·대학 UUID·계열 식별자 변경0.
5. 학생 Learning/Decision/Outcome fact를 생성하지 않는다.
6. 개인정보·권한·동의·retention 변경0.
7. 여백 측정은 derived 표시 metadata이고 공식 색상값이 아니다. 추정색/Pantone 환산을 공식 HEX로 저장하지 않는다.

## 대학별 대조표

| 대학 | 현재 UI색 | 확인 상태 | 공식 대조 페이지 |
|---|---|---|---|
| 가천대학교 | #004E96 | 공식 디지털 수치 확인 | [공식 자료](https://www.gachon.ac.kr/kor/807/subview.do) |
| 가톨릭대학교 | #0C2E86 | 공식 디지털 수치 확인 | [공식 자료](https://www.catholic.ac.kr/ko/about/signiture.do) |
| 건국대학교 | #006239 | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.konkuk.ac.kr/konkuk/2109/subview.do) |
| 경기대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.kyonggi.ac.kr/www/contents.do?key=5093) |
| 경북대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.knu.ac.kr/wbbs/wbbs/contents/index.action?menu_idx=194&menu_url=intro/about04) |
| 경희대학교 | #A40F16 | 공식 디지털 수치 확인 | [공식 자료](https://www.khu.ac.kr/kor/user/contents/view.do?menuNo=200033) |
| 고려대학교 | #862633 | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.korea.ac.kr/ko/373/subview.do) |
| 광운대학교 | #7D192D | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.kw.ac.kr/ko/life/symbol01.jsp) |
| 국민대학교 | #004F9F | 공식 디지털 수치 확인 | [공식 자료](https://www.kookmin.ac.kr/comm/menu/user/0a4f7cf187cc3164678352bc3f4575b3/content/index.do) |
| 단국대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.dankook.ac.kr/web/kor/dku_ui) |
| 덕성여자대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.duksung.ac.kr/contents/contents.do?ciIdx=290&menuId=1199) |
| 동국대학교 | #EA5514 | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.dongguk.edu/page/261) |
| 동덕여자대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.dongduk.ac.kr/www/contents/kor-ui02.do) |
| 부산대학교 | #005BAA | 공식 디지털 수치 확인 | [공식 자료](https://www.pusan.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN156) |
| 삼육대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.syu.ac.kr/about-sahmyook/symbols-ui/logo-ui/) |
| 상명대학교 | #0E207F | 공식 디지털 수치 확인 | [공식 자료](https://www.smu.ac.kr/kor/intro/uiColor.do) |
| 서강대학교 | #A6192E | 공식 전용색상 본문에서 Sogang Cardinal 확인. 색상표 자산은 HTML 오류 응답; 숫자 미확정으로 기존 임시색 유지 | [공식 자료](http://www.sogang.ac.kr/intro/symbol/s_colorsystem.html) |
| 서울과학기술대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.seoultech.ac.kr/intro/symbol/logo/symbol) |
| 서울시립대학교 | #004094 | 공식 Web HEX 적용; 동일 표 RGB와 불일치 기록 | [공식 자료](https://www.uos.ac.kr/kor/html/auos/symbol/ui/ui3.do?identified=anonymous&) |
| 서울여자대학교 | #9E1A20 | 공식 디지털 수치 확인 | [공식 자료](https://www.swu.ac.kr/swu/797/subview.do) |
| 성균관대학교 | #072A60 | 공식 디지털 수치 확인 | [공식 자료](https://www.skku.edu/skku/about/symbol/symbol_01.do) |
| 성신여자대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.sungshin.ac.kr/main_kor/10922/subview.do) |
| 세종대학교 | #C3002F | 공식 디지털 수치 확인 | [공식 자료](https://pr.sejong.ac.kr/news/promotion/basic-element.do) |
| 숙명여자대학교 | #003087 | 공식 디지털 수치 확인 | [공식 자료](https://www.sookmyung.ac.kr/kr/intro/ui.do) |
| 숭실대학교 | #00587C | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://ssu.ac.kr/학교소개/학교상징/ui/전용-색상/) |
| 아주대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](http://www.ajou.ac.kr/kr/intro/uibasic01.do) |
| 연세대학교 | #003876 | 공식 디지털 수치 확인 | [공식 자료](https://designcenter.yonsei.ac.kr/designcenter/design_con/signature_color.do) |
| 을지대학교 | #244A6A | 공식 UI 대조; 디지털 수치 미확정, 기존 임시 UI 색 유지 | [공식 자료](https://www.eulji.ac.kr/?menuno=3075) |
| 이화여자대학교 | #00462A | 공식 디지털 수치 확인 | [공식 자료](https://www.ewha.ac.kr/ewha/intro/ui-si04.do) |
| 인하대학교 | #005BAC | 공식 디지털 수치 확인 | [공식 자료](https://www.inha.ac.kr/kr/1828/subview.do) |
| 중앙대학교 | #2155A4 | 공식 디지털 수치 확인 | [공식 자료](https://www.cau.ac.kr/cms/FR_CON/index.do?MENU_ID=230) |
| 한국외국어대학교 | #146E7A | 공식 디지털 수치 확인 | [공식 자료](https://www.hufs.ac.kr/hufs/11129/subview.do) |
| 한국항공대학교 | #002870 | 공식 디지털 수치 확인 | [공식 자료](https://www.kau.ac.kr/intro/ui.php) |
| 한양대학교 | #1D2475 | 공식 디지털 수치 확인 | [공식 자료](https://www.hanyang.ac.kr/en/web/eng/colors-fonts) |
| 홍익대학교 | #1833DB | 공식 교표 흑백 원본 유지·공식 웹 색상 JS 대조 | [공식 자료](https://www.hongik.ac.kr/kr/introduction/color.do) |

## 검증·운영

구현 검사와 운영 배포 결과는 아래 완료 기록으로 확정한다. 대학 로고 외 API/DB/Credit/공개304문항/평가 Worker 변경0. 공식 숫자 미확정16개는 위 표에 남기며 확인되지 않은 값을 임의 지정하지 않는다.

### 운영 완료

Pages `60fed8dd-3069-4c64-b3d7-cea9afee5000`, source `d6fa4f6a77bd765110c85471c29d1faa0ced3cdd`, 2026-11-13 12:49 KST success. [운영 비교 증거](evidence/university-brand35-deployment-20261113.json): 설정/라우팅/평가 Worker 동일, 기존 비논술 정적 자산2266개 보존. 기존 평가 Worker `27c67e48-5526-46a6-a7e8-1aab3218016e` 100% 유지.

관련5파일28테스트 PASS(기존 color_usage 규약 불일치 발견 후 official_accent로 수정·재검사), ESLint·webpack production build·diff-check PASS. 실제 운영 35카드/35이미지 로딩, 깨진 이미지0, 가로넘침0. 로컬390px 서울시립 카드 정상. 운영 화면 `/Users/woojinchang/.codex/visualizations/2026/11/13/01a1d2c1-0c6d-7e70-9157-d5ac2c932c7e/university-brand35-production.jpg`.

복구는 직전 Pages `e6c7e088-1bed-459d-bdc9-3c1cd7c56751` 정적 배포로 되돌린다. DB/평가 Worker 복구 작업은 필요하지 않다. 숫자 미확정16개는 향후 공식 RGB/HEX 원문 확보 때만 승격한다.
