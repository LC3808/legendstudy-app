# 논술 LAB 대학별 자산(로고·브랜드 컬러) — 2026-11-06

지시: 기존 LAB 로고 + **공식 브랜드 컬러** 재사용. 추정·임의 코드 금지.
근거: Owner 제공 `References.md` + `27개대학_공식브랜드컬러_로고색상.xlsx`(공식 UI/컬러시스템 출처). Pantone만 확인된 색은 공식 자료가 **화면 HEX를 제공하지 않아** 빈칸(임의 환산 금지 원칙).

## 로고(확보)
- 출처: `lib/features/essay/university_catalog.dart`(LAB 캐노니컬 생성) → `https://lab.legendstudy.com/university-logos/{slug}.{ext}`. 15개 전부 핫링크 사용 가능.

## 15개 공개 대학 — 공식 브랜드 컬러
| 대학 | slug | 로고 URL | 공식 대표색 | 공식 HEX | 상태 |
|---|---|---|---|---|---|
| 중앙대 | cau | cau.png | CAU 청색 | **#2155A4** | 확정 |
| 경희대 | kyunghee | kyunghee.png | 경희 레드 | **#A40F02** | 확정 |
| 건국대 | konkuk | konkuk.png | 헤리티지 그린 | **#006239** | 확정 |
| 인하대 | inha | inha.png | 짙은 청색 | **#005BAC** | 확정(하늘색 #00AFEC 보조) |
| 한국외대 | hufs | hufs.png | HUFS 그린 | **#146E7A** | 확정 |
| 숙명여대 | sookmyung | sookmyung.svg | 숙명 로열 블루 | **#003087** | 확정 |
| 서울여대 | swu | swu.png | SWU 퍼플 | **#9E1A20** | 확정(블루 #101077 보조) |
| 한국항공대 | kau | kau.png | 군청색 | **#002870** | 확정 |
| 성균관대 | skku | skku.png | 성대 파란색 | **#072A60** | 확정(짙은녹색 #124532 보조) |
| 고려대 | korea | korea.png | 진홍색 | **(Pantone 202C — 공식 HEX 미제공)** | ⚠️ 결정 필요 |
| 서강대 | sogang | sogang.jpeg | 서강 카디널 | **(Pantone 1805C — 미제공)** | ⚠️ 결정 필요 |
| 한양대 | hanyang | hanyang.png | Hanyang Blue | **(공식 HEX 미제공)** | ⚠️ 결정 필요 |
| 동국대 | dongguk | dongguk.png | 전용색(색명 미확인) | **(미제공)** | ⚠️ 결정 필요 |
| 숭실대 | soongsil | soongsil.png | Pantone 308/3135/325 | **(HEX 미제공)** | ⚠️ 결정 필요 |
| 광운대 | kwangwoon | kwangwoon.png | KwangWoon Brown | **(HEX 미제공)** | ⚠️ 결정 필요 |

## ⚠️ 결정 필요 — Pantone만 확인된 6개 대학
공식 자료에 화면 HEX가 없음. 두 가지 중 택:
- **(A) 표준 Pantone→sRGB 환산값 사용**(임의 추정 아님, Pantone 공식 환산). 참고 환산: 고려 202C≈`#86252E`, 서강 1805C≈`#A32638`, 숭실 308C≈`#00587C`. 한양·동국·광운은 Pantone/코드 자체가 미확정이라 환산도 불가 → 추가 자료 필요.
- **(B) Owner가 공식 HEX 직접 지정**.
- (임시 대안) 해당 6개는 공통 네이비 `#17212F`로 두고 나머지 9개만 대학색 적용.

## 적용된 최종 색 (Owner 결정 2026-11-06: 개편+Pantone 환산)
- 공식 9: 중앙 #2155A4 · 경희 #A40F02 · 건국 #006239 · 인하 #005BAC · 한국외대 #146E7A · 숙명 #003087 · 서울여대 #9E1A20 · 한국항공 #002870 · 성균관 #072A60.
- **Pantone→sRGB 환산 3**: 고려 #862633(202C) · 서강 #A6192E(1805C) · 숭실 #00587C(308C).
- **임시 네이비 #17212F 3**(한양·동국·광운): 공식 Pantone/HEX 자체가 미확정 → 환산 불가. **Owner 공식색 확정 시 교체**(생성기 색값 1개만 수정).

## 적용 가능
- **로고**: 15/15. **대학색**: 12개 공식/환산 적용, 3개 임시 네이비(공식색 대기).

## 유지(불변)
대학별 LAB URL, GA4 impression/click, UTM, Tistory 삽입 구조, 반응형.
