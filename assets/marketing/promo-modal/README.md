# LegendStudy+ 모바일 웹 앱 홍보 모달 — 적용 가이드 (TASK 15)

legendstudy.com(**티스토리 스킨**) 모바일 방문자에게 앱 설치를 유도하는 모달.
드롭인 단일 블록. 기존 HTML/CSS/게시글 **미수정**, 필요한 CSS만 추가.

- 붙여넣을 코드: [`legendstudy-app-promo-modal.html`](legendstudy-app-promo-modal.html)
- 전체 명세·검증·보고: `wiki/app-promo-modal-20261101.md`

---

## 1. 삽입 위치 (정확히 1곳)

티스토리 관리 → **꾸미기 → 스킨 편집 → html 편집**.
스킨 HTML 맨 아래 **`</body>` 바로 앞**에 `legendstudy-app-promo-modal.html` 내용 전체를 붙여넣는다.

```
   ...기존 스킨 내용...
   <!-- ↓↓↓ 여기(=</body> 바로 위)에 붙여넣기 ↓↓↓ -->
   <!-- LS-APP-PROMO-MODAL:START ... LS-APP-PROMO-MODAL:END -->
</body>
</html>
```

- `</body>`가 보이지 않으면(치환자 스킨) **문서 가장 마지막**, 닫는 태그 직전에 둔다.
- 다른 요소 안(슬라이더·헤더·사이드바 등)에 넣지 말 것. 최상위에만.
- 블록 하나만 추가하며, 기존 CSS/HTML은 건드리지 않는다.

적용 후 **적용(저장)**. 게시글 본문·`style.css`는 수정하지 않는다.

## 2. 동작 요약

| 항목 | 동작 |
|---|---|
| 노출 대상 | 모바일 웹 브라우저만 (PC·앱 내부 WebView 미노출) |
| 노출 시점 | 진입 **6초 후**, 세션 1회 |
| 기기별 링크 | iOS → App Store, Android/기타 → Google Play (UA 자동 판별) |
| `X` / 배경 / ESC | **24시간** 숨김 (`app_promo_dismiss`) |
| 오늘은 그만 보기 | **당일**(자정까지) 숨김 (`app_promo_snooze`) |
| 앱 다운로드하기 | **30일** 숨김 후 스토어 이동 (`app_promo_click`) |
| 미노출 상황 | PDF 뷰어 중 · 키보드 입력 중(입력 끝나면 1회 재시도) · 인앱 WebView |
| 상태 저장 | `localStorage`(+세션은 `sessionStorage`, 실패 시 쿠키/메모리 폴백) |

- 모든 상태 키는 `ls_appmodal_*` 전용 네임스페이스 → 기존 숨김 정책과 충돌 없음.
- 스토리지 접근 실패해도 오류 없이 동작(try/catch), 동일 세션 반복 노출 방지(쿠키/메모리 폴백).
- GA4(`G-295EQHYTCK`) 미설정이어도 오류 없이 무음 처리.

## 3. 분석 이벤트 (GA4)

신규 이벤트명(기존 계약과 비충돌): `app_promo_impression`, `app_promo_click`, `app_promo_dismiss`, `app_promo_snooze`.
파라미터: `platform`(ios/android), `placement`(mobile_web), `store`(appstore/googleplay), `reason`.
`window.gtag` 있으면 `gtag('event', ...)`, 없으면 `dataLayer.push(['event', name, params])`로 동일 shape 전송.

## 4. 설정 변경 지점

`legendstudy-app-promo-modal.html` 상단 `CFG` 객체:
`delayMs`(노출 지연), `hideOnCloseMs`(X 숨김), `hideOnClickMs`(다운로드 숨김), `iosUrl`, `androidUrl`.
스토어 URL은 **공식 URL 고정**(변경 금지 대상). 바꾸지 말 것.

## 5. 검증 체크리스트

- [ ] iPhone Safari / iPhone Chrome / Android Chrome / Samsung Internet: 6초 후 노출
- [ ] iOS=App Store, Android=Google Play로 이동
- [ ] X=24h / 오늘 그만보기=당일 / 다운로드=30일 재노출 안 됨
- [ ] 페이지 이동(게시글→홈 등) 후 **같은 세션 재노출 안 됨**
- [ ] PC Chrome / PC Safari: **미노출**
- [ ] 기존 게시글·검색·카테고리·사이드바·인기글·홈 슬라이더·광고·PDF 다운로드·댓글·게시글 내부 배너 정상
- [ ] 모달 열림 중 배경 스크롤 잠김, 닫으면 스크롤 위치 복원
- [ ] 키보드 입력(댓글/검색) 중 미노출

## 6. 롤백

스킨 HTML에서 `<!-- LS-APP-PROMO-MODAL:START -->` ~ `<!-- LS-APP-PROMO-MODAL:END -->` 블록 **전체 삭제** 후 저장.
그 외 변경이 없으므로 이 블록 제거만으로 원복 완료.
(적용 전 스킨 HTML 전체를 백업해 두길 권장: 관리 → 스킨 편집 → html 복사 보관.)

## 7. 범위 / 금지

- legendstudy.com 티스토리 스킨에만 적용. **Flutter APP / LAB WEB / Supabase / Worker / Credit / 결제 변경 금지.**
- Codex TASK 14-B/C와 작업 영역 분리(이 블록은 독립 네임스페이스, 전역 1회 가드 `__lsAppPromoInit`).
- 스킨 구조 임의 재구성 금지 — 이 블록 추가만.
