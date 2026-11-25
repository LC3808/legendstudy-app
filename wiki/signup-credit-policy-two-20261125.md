# 신규 무료 첨삭권 2개 — APP 준비 / 2026-11-25

Owner 결정: 신규 지급만3→2, 기존 지급·잔액·소진·유료 가격·무료 재첨삭 보존. 서버 지급의 단일 기준은 DB이며 클라이언트 별도 지급 없음.

1.0.6/build88 기준08345b69 체크아웃의 essay_beta_credit.dart 안내를2개로 변경하고 기존 잔액 보존을 명시. credit 관련21 PASS, 변경 파일 analyze PASS. Store binary/실기기 QA NOT TESTED. 버전 변경/스토어 제출 없음. 구버전은 서버 실제 잔액2도 표시하며 기존3을 clamp하지 않지만 고정3 문구는 다음 바이너리에서 교체해야 한다.

운영 DB는 아직3개 정책이며 Owner 적용 승인 대기. DB 사후 검증 후 WEB 배포; APP 변경은 다음 스토어 업데이트. 기존 운영 원장 변경0, 결제/환불0, Finance 설정 변경0. 지금 WEB만 먼저 배포해 신규 지급과 안내를 어긋나게 하지 않는다.

[SQL/Wiki canonical 정책·보존 검토·검증·Owner 적용 순서](https://github.com/LC3808/legendstudy-app/blob/codex/material-service-app-20261022/wiki/signup-credit-policy-two-20261125.md). DB candidate `supabase/candidates/signup_credit_two_20261125/`의 precheck→install→postcheck, 운영 적용은 AGENTS §4에 따라 Owner 실행. 이번 문서는 정책 사본이 아닌 체크아웃 인수인계다.
