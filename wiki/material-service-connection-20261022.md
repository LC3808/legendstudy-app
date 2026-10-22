# 자료 조회 연결 2026-10-22 — 초기 이력

Unified Wiki `90_HISTORY/REVIEWS/2026-10-22-material-service-connection.md` 참고.
운영208시험/656문항, anon21시험/0문항, 기존 essay_browse_catalog 함수 미적용. 기존 Registry-only APP 선택에 동일 RPC 소비 경로를 추가했다. UUID/대학/문항수/중복을 검증하고 비공개 필드를 제거한다. 검수 중 문항은 선택만 가능하며 답안 작성 진입을 차단한다. 정확히 같은 DB ID 집합의 기존 승인 자료만 재사용한다.

APP 관련12테스트·analyze·Android debug/iOS simulator build PASS. 화면 제어 도구에서 Simulator 연결 불가로 Native 화면 실측 NOT_ASSESSABLE. 운영 공개/로그인계정 APP 조회와 실기기 E2E는 미검증. 71701만 자료 조회에 필요, 71702 미적용 유지. 신규 Migration 작성/운영 DB 변경/Provider/Credit/배포 없음. 복구 조건 및 Owner 승인 전 운영 적용 금지. 기존16 HOLD/42 Catalog/Native/History 보존.

## 후속 Native 연결
71701 Production 적용 이후 조회 상태는 [Native 자료·PDF 검증](native-material-pdf-20261022.md)으로 갱신. 위 함수 미적용·화면 미검증은 초기 시점 기록이다.
