# 인하대 자연 오전 다중 사진 추출 복구 — 2026-10-26

대상: 인하2026수시 자연 오전 Q1·Q2·Q3. [인하 STANDBY](inha-standby-20261026.md)·[기존 사진 입력 계약](hanyang-mixed-incident-20261026.md)·[WEB UI](essay-web-studio-ui-20261026.md)를 유지한다.

## 확인한 원인과 수정

운영 Postgres 로그09:18~09:32 UTC의 실패5건 모두 `math_extraction_regions_run_id_reading_order_key` 중복 오류. 여러 사진의 Provider 출력이 각 사진마다 reading_order를1부터 시작했으나 저장 계약은 문항 추출 run 전체에서 순번이 유일해야 한다. 사진 업로드/Worker claim은 성공했고 finalize가 롤백되어 PROCESSING이 남았다. 인증이나 이미지 접근 실패로 추정하여 Secret을 변경하지 않았다.

WEB Pages extraction adapter에 `orderExtractionRegions` 추가: 기존 claim evidence의 학생 사진 순서 → page → 사진 내 순번으로 정렬하고 전체 순번1..N을 부여한다. 텍스트/수식/좌표/학생 확인 여부는 수정하지 않는다. 다른 문항 artifact ID는 거절한다. 기존 DB 제약과 Worker 평가 엔진은 유지한다.

WEB 다시 추출은 새 attempt를 만들지 않고 동일 fingerprint·attempt ID를 재사용한다. 서버 claim의 기존 lease 만료/진행중 차단을 사용한다. 이미 완료된 추출은 읽기만 하며 PRESENT 사진을 중복 업로드하지 않는다. 재진입 시 기존 결과를 읽고, 사용자 확인은 자동 수행하지 않는다. 사진별 조작 간소화·촬영/첨부/추출 색상 버튼·History 노란 버튼 적용.

## 보존 검토

1. 기존 생성시각/요청ID 유지, 재개는 기존 서버의 새 추출 세대 기록.
2. 원본 사진·순서·학생 초안 보존.
3. 기존 성공 추출/평가/History UPDATE 없음.
4. 기존 인증 사용자 소유권·leaf 공개승인 유지.
5. 사진 인식은 입력 준비이며 평가/성장 결과로 기록하지 않음.
6. 동일 기존 추출 Provider 경로만 사용, 학생 본문/사진/Secret을 Wiki·로그에 저장하지 않음.
7. 후보 결과는 학생 확인 전 확정 답안으로 승격하지 않음.

## 배포·검사

WEB `3e2e0e46f26ed9225c63934a538c563012aca609`, remote 일치. Pages `00f8c3a8-b101-42d1-a112-bc74396da892` Production success/API 확인. typecheck/build PASS, 관련 검사18 PASS(후속 변경16 PASS), lint 오류0/기존 effect 경고2. Provider 유료 평가/첨삭 submit0. DB DDL/직접 DML·Secret·APP 변경0.

## 복구

직전 WEB86282c7 / Pages e8def797-e14c-40f0-ad05-d50017f8fc7f. 구버전으로 복귀하면 다중 사진 순번 오류가 재발하므로 긴급 복구 시 해당 추출 경로의 제한을 알린다. 학생 사진·attempt·추출세대·History를 삭제하지 않는다. 적용/재실행할 SQL 없음. 기존 인하 STANDBY SQL 재실행 금지.

## 운영 확인

운영 일반계정에서 기존 Q1 4장/Q2 2장/Q3 2장(총8장) 복원. 수정 배포 후 기존 attempt3개를 재사용해 추출3건 COMPLETED. 영역 수 Q1=25/Q2=23/Q3=16이며 각 문항 unique reading_order 수와 일치. 원본 artifact 개수4/2/2 그대로, 평가0, CONFIRMED0. 유료 평가/예약/차감0, UI Credit7→7.

WEB에서 세 문항의 추출 내용 편집 영역과 활성 ‘이 내용으로 확인’ 버튼3개를 확인. PC1413px 가로 넘침0, 촬영 네이비/첨부 파란색/흰글씨 확인. 모바일 실제 화면 확인은 아직 미완료. 다중사진 조작 회귀3검사 추가 PASS.

이번 추출 Provider 요청은4회: 수정 전 기존 입력 확인 중 아직 미접수였던 Q3 1회(동일 순번 오류), 수정 후 기존 attempt 재개3회 성공. 유료 첨삭 Provider 호출0. 추출 token usage/정확한 비용은 확보되지 않아 미확정이며 0원으로 보고하지 않는다.

Owner에게 세 문항 사진 내용 직접 확인을 요청했다. 사용자 확인 없이 후보를 확정하지 않았다. **첨삭 버튼 활성화·서버1Credit 안내창은 Owner 확인 후 남은 검증**이며 전체 완료/E2E PASS로 보고하지 않는다.
