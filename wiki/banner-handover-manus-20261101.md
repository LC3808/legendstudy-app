# 마케팅 배너 작업 인계서 — Manus (2026-11-01)

작성: Claude(UI/UX). **지금부터 배너 시각 디자인 작업은 Manus가 진행**(Owner 지시). 이 문서는 Manus가 재기획 없이 착수할 수 있도록 Owner 피드백·확정 재료·제약·미결정·현재 상태를 정리한다. 실물 재료는 `assets/marketing/handover/`(+ `SOURCES.md`).

## 0. 인계 범위
- **Manus 담당(이관)**: 마케팅 배너의 시각 디자인·최종 자산 제작(iOS/Android 앱 출시, 논술 LAB, 대학별 게시글 배너 / PC·모바일·Retina).
- **유지(변경 금지 — Claude 산출물)**: 아래 명세 문서는 그대로 둔다. 배너 작업은 이들을 **참조**만 한다.
  - 슬라이더 삽입/수정: `wiki/web-main-slider-fix-20261101.md`
  - 지원상태 UX(대학 배너 CTA 분기 근거): `wiki/essay-support-status-ux-20261101.md`
  - Analytics 계측: `wiki/marketing-analytics-events-20261101.md`
  - 논술 일정, 티스토리 삽입 비교, §17 보고: `wiki/essay-schedule-intake-20261101.md`, `wiki/beta-launch-marketing-20261101.md`
- **서비스 코드·운영 DB·Codex TASK 08 영향 금지. 운영 배포 금지. Owner 승인 전 최종 확정·배포 금지.**

## 1. Owner 디자인 피드백 히스토리 (필독 — 반려 사유)
1. **v1 배너(Claude) 반려 사유**: 과도한 노랑·주황 / 이벤트 광고풍 / 불필요한 배경 장식(원형 패턴) / 반복적 대형 로고 카드 / 과도하게 굵은 타이포 / 모바일 공간 효율 낮음 / 공식 앱 아이콘 미사용 / 실제 서비스 UI 미활용.
2. **재디자인 원칙**: Minimal · Clean · Professional · Trustworthy · Modern Education Platform. 배경 화이트/라이트그레이. **`#FFAC14`는 강조 요소에만.** 금지: 과도한 주황 배경, 장식용 원형, 불필요한 그라데이션, 대형 로고 카드, 과도한 그림자, 이벤트 광고 스타일, 불필요한 아이콘·장식. 가독성·정보 전달 최우선.
3. **앱 출시 배너(iOS/Android)**: **앱 화면 넣지 말 것.** 오른쪽에 **공식 스토어 다운로드 배지**(iOS=App Store 배지, Android=Google Play 배지). 좌측은 `LegendStudy⁺` 로크업 + 소형 공식 아이콘 + 헤드라인/서브. → **Owner 레퍼런스 `1.png` 스타일(§2)로 1:1 복제가 안전.**
4. **논술 LAB / 대학 배너(§5·§6 원 지시)**: 실제 LAB **첨삭 결과 화면**(핵심 UI) 활용. **실제 서비스에 없는 평가 결과·점수 임의 생성 금지.** ※ 단, "화면 유지 vs 앱 배너처럼 아이콘/배지만" 여부는 **Owner 미결정**(§10).
5. **Claude v2 시안도 Owner 반려**(디자인 방향 미스). → Manus가 **새로 제작**. 임의 창작보다 **레퍼런스 복제** 권장.

## 2. 레퍼런스 스펙 (Owner 제공 `1.png`) — 복제 기준
- 비율 **약 1324×336(≈3.94:1)**, 가로형, 배경 화이트, 여백 넉넉(에어리).
- 레이아웃: 좌상단 **짧은 오렌지 틱(라인)** → (슬라이드 번호, 생략 가능) → **`LegendStudy⁺`**(라틴, superscript +) + **소형 공식 앱 아이콘**(오른쪽) → **헤드라인 2줄**(과하지 않은 굵기) → **서브 2줄**(회색). **우측: 공식 스토어 배지** 세로 중앙·우측 정렬.
- ⚠️ **레퍼런스 실물 `1.png`은 Owner 보유**(세션 업로드라 저장소에 없음). Manus는 Owner에게 원본 파일을 받아 픽셀 기준으로 맞출 것. Claude가 역설계한 스펙은 위와 같음.

## 3. 배너별 확정 카피 · CTA · 링크
> §6-1 대학 배너 원문은 Owner 대기(아래는 현재 안). 앱/LAB 카피는 Owner 브리프 §3~§5 기준.

**iOS 앱 출시** — 헤드라인 "레전드스터디+, 이제 아이폰에서도 만나보세요." / 서브 "기출문제 검색부터 학습 기록까지. 필요한 입시자료를 더 편리하게." / 우측 **App Store 배지** → iOS URL.

**Android 앱 출시** — 헤드라인 "레전드스터디+, 안드로이드 앱 출시." / 서브 "모의고사·수능 기출자료를 더 빠르고 편리하게 확인하세요." / 우측 **Google Play 배지** → Android URL. (iOS와 동일 디자인 시스템 유지.)

**논술 LAB** — 메인 "논술, 내 글에서 부족한 것이 무엇일까?" / 서브 "대학별 평가기준을 바탕으로 내 답안을 분석하고, 부족한 부분을 다시 써보세요." / 혜택 "인문논술 LAB 베타 · 매일 무료 첨삭 1회" / CTA "[논술 LAB 시작하기]" → `https://lab.legendstudy.com`. (우측: 실제 첨삭 결과 화면 — §10 확인 후.)

**대학별 게시글(공통 템플릿)** — 메인 "기출문제를 풀었다면, 이제 내 답안을 점검할 차례." / 서브 "대학별 평가기준에 맞춘 AI 첨삭. 부족한 부분을 확인하고 다시 써보세요." / CTA "[논술 LAB에서 첨삭받기]". **대학명·링크는 게시글별 동적**(§7). **지원하지 않는 시험에는 "첨삭" 문구 미표시**(§7).

## 4. 사이즈 · 포맷
- PC: 가로형. 슬라이더 영역 기준(§실제 적용 §8). 레퍼런스 비율(≈3.94:1) 권장. 최종 WebP @1x + @2x(Retina) + PNG 폴백 + 편집용 SVG.
- 모바일: **전용 레이아웃**(단순 축소 금지). **텍스트 잘림·버튼 이탈 0.** WebP @1x/@2x + PNG.
- 반응형 삽입은 `<picture>`(media (max-width:480px) → 모바일 자산, 그 외 PC, srcset 1x/2x). 상세: `web-main-slider-fix-20261101.md` §3.3.

## 5. 확정 재료 (저장소 실물 · `assets/marketing/handover/`)
- `official-app-icon-1024.png` — 공식 앱 아이콘(새로 만들지 말 것). 정본: essay 브랜치 AppIcon 1024.
- `appstore-badge-official.svg` / `googleplay-badge-official.png` — 공식 스토어 배지.
- `real-app-home.png` / `real-essay-lab.png` / `real-essay-feedback.png` — 실제 앱 화면.
- 상세 출처·재취득 URL·토큰·스토어 URL: `assets/marketing/handover/SOURCES.md`.

## 6. 제약 · 금지 (Owner)
- 브랜드색 `#FFAC14`, 기존 디자인 시스템 우선(새 브랜드 시스템 금지). 주황은 **강조만**.
- **공식 스토어 URL 변경 금지.** 스토어 배지는 **공식 아트워크만**(변형 금지, Apple/Google 가이드라인 준수).
- 새 앱 아이콘·로고 제작 금지(공식 자산 사용). 공식 아이콘 못 찾으면 **임의 제작 말고 Owner 보고**(→ 이미 §5에 확정 제공).
- 모바일 텍스트 잘림/버튼 가림 금지. 가상 앱 화면·가상 점수 생성 금지.
- 미제공 기능 홍보 금지, 과장된 AI 성능 표현 금지. 베타: 메인 배너엔 "인문논술 LAB 베타 오픈 + 매일 무료 첨삭 1회"만, **종료 후 혜택 지속 오인 문구 금지**(베타 종료 2026-11-11 00:00 KST = 11/10까지; 정확한 종료 시각 문구는 Owner 최종 설정 확인).

## 7. 대학 배너 동적 규칙
- 링크 매핑: 게시글의 대학 → `university_catalog.dart`의 name→`sourceUniversityId` → `https://lab.legendstudy.com/essay-lab/universities/{sourceUniversityId}/`. (URL 임의 생성 금지.)
- **지원상태별 CTA**(근거 `essay-support-status-ux-20261101.md` 4-state):
  - 지원(AVAILABLE): "[{대학} 논술 첨삭받기]" → 대학 LAB.
  - 준비중(COMING_SOON)/미지원: **"첨삭" 문구 미표시** → "[{대학} 논술 자료 확인하기]"(공식 자료/LAB).
- 티스토리 자동 매핑 방식(개별/스킨공통/카테고리/자동) 비교·권장안: `beta-launch-marketing-20261101.md` §B-3(스킨 공통 + JS 자동 매핑 권장).

## 8. 실제 적용(삽입) · 계측
- 삽입 대상: **legendstudy.com = 티스토리 스킨**(APP 저장소 아님). 메인 슬라이더 `.ls-slider` 및 대학 게시글. 슬라이더 크기·반응형·수정안: `web-main-slider-fix-20261101.md`.
- Analytics: 노출/클릭 = `banner_impression`/`banner_click`(+ `banner_id`/`banner_type`/`destination_url`/`university_code`). 설치≠완료. 상세: `marketing-analytics-events-20261101.md`.

## 9. 현재 자산 상태 (건드릴 때 주의)
- `assets/marketing/banners/` = **v1(반려본)** + SVG/gen.py. Owner "승인 전 기존 자산 덮어쓰기 금지" → Manus 최종 승인 전까지 보존(참고용). 최종 승인 시 교체.
- PR #10(base main) = 문서·자산 **리뷰 PR**. 병합 전. 명세 문서는 유효.
- Claude의 v2 시안(반려)은 세션 scratch에만 있고 저장소 미반영.

## 10. 미결정 · Owner 승인 필요
- 논술 LAB·대학 배너: **실제 화면 유지 vs 아이콘/배지만** (Owner 미결).
- §6-1 대학 배너 카피 **원문**.
- 레퍼런스 `1.png` 원본 파일(Owner → Manus 전달 권장).
- 최종 디자인 승인, 베타 종료 시각 화면 문구, (배포 시) 티스토리 스킨 반영 승인.

## 11. 완료 기준 / 승인 게이트
- 레퍼런스 스타일 부합(미니멀·화이트·강조만·공식 아이콘/배지), 모바일 잘림 0, 공식 URL·배지 준수, 대학 동적 규칙·미지원 첨삭문구 금지 준수.
- 최종 자산(WebP@1x/@2x + PNG + SVG) 제작 → **Owner 디자인 승인** → 저장소 반영 → 삽입/계측(위 명세) → 보고.
- Owner 승인 전 최종 확정·Codex 인계·배포 금지.
