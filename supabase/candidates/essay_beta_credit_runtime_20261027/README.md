# 일일 베타 Credit 런타임 — Production 승인 요청 후보

**미적용. 신규 지급·캠페인 활성화 없음.** 기존 `essay-beta-credit-design-20261027.md`의 일일 지급 부분을 구현한다. 피드백 보상은 이번 최소 SQL에 포함하지 않는다.

## 변경 범위

- private 관계 3개: 캠페인, 정확한 시험/전체 문항/실행 정책 범위, 일일 지급 연결. 잔액은 기존 원장으로만 계산한다.
- 본인 전용 `essay_beta_daily_claim()` RPC 1개. 서버 KST 일자, 일일 2개, 다음날 00:00 만료. 계정 잠금과 사용자+일자 unique로 다중 기기 중복 지급 차단.
- 기존 회차 예약 함수 1개: 허용된 베타 지급분을 먼저 선택. **기존 가입·구매·운영 지급분끼리의 선택 순서는 변경하지 않는다.** 설계서의 가입/기타/유료 순서 재편 제안은 제외했다.
- 기존 단일문항/Math 선택 함수 5개: 베타 지급분만 제외. 기존 예약·확정·반환·무료 재첨삭·History 계약 변경 없음.
- 기존 `credit_post_grant` 및 `finish` 그대로 재사용. 결제·환불·Toss·Secret·인증 정책 변경 없음.

시험 범위는 대학명이나 클라이언트 flag로 판정하지 않는다. 승인된 exam ID, 전체 Registry 질문 ID 배열, runtime policy JSON을 고정한다. 변경 시 베타 사용을 차단한다. 혼합형은 별도 Owner QA 근거 필수. 기존 WEB/Worker 공개 allowlist와 preflight는 그대로 남는다. 새 관계는 이를 대체하지 않는 추가 사용 제한이다.

## 실행 순서

1. `precheck.sql`: 기존 함수 6개 정확한 정의 hash와 신규 schema 부재 확인(7개 true).
2. `apply.sql`: 단일 transaction, baseline 재확인, private 관계/RPC/선택부 변경. 재실행 금지.
3. `postcheck.sql`: 함수 6개 hash, 캠페인 비활성, 지급 0, 본인 RPC/익명 차단/private 접근 차단(11개 true).

**이 패키지는 캠페인 날짜·시험 범위를 임의 생성하지 않는다.** RPC 적용 승인과 실제 베타 시작은 구분한다. 기간/허용 회차 및 WEB·APP 연결 준비 후 캠페인 활성화 SQL을 별도로 제시한다. 기존 전체 유료 잔액을 베타 잔액처럼 표시하지 않는다.

## 격리 검증

`test_runtime.py`는 loopback 전용 임시 PostgreSQL에서 합성 계정만 사용한다. 운영 `credit_post_grant`, `reserve`, `finish` 정의를 재사용한다. 100개 동시 claim, 1회 지급2, 다음날 지급, KST 만료, 시험/전체문항 범위, 혼합형 QA 누락 차단, 베타 우선선택, 요청 재시도, consume/release 멱등성, 무료재첨삭0/기존횟수, 만료후 예약확정, 유료잔액 보존, 역할 접근을 검사한다.

5개 legacy/Math 함수는 실제 변경 SELECT를 실행해 베타 제외를 검사한다. 해당 엔진 전체의 Provider 통합 검증으로 간주하지 않는다. Production Provider·지급·예약·회수 호출은 하지 않는다.

## 복구

`rollback.sql`은 캠페인 비활성화만 수행한다. 기존 지급·원장·예약·완료 결과는 유지한다. **베타 지급 이력이 있으면 이전의 무제한 allocator로 되돌리지 않는다.** 기존 요청의 finish/release와 무료 재첨삭을 유지한다. `allocators-baseline.sql`은 감사/비교 근거이며 일반 롤백 실행 파일이 아니다.

## 생성/감사

`build_candidate.py`는 읽기 전용 추출 `baseline.private.json`에서 정확히 6개의 선택부만 수정한다. `manifest.json`에 전후 hash를 보존한다. 전체 apply는 별도 Owner 승인 전 실행 금지.
