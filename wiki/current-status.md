# Current Status

공식 기준은 **LC3808/legendstudy-app origin/main의 wiki/**다. 작업 브랜치의 사본은 공식 상태를 대신하지 않는다. 아래는 **2026-11-26 마지막 확인 상태**이며 외부 운영을 실시간 보증하지 않는다. [index](index.md) · [정상화 절차/검사 한계](project-cross-review-20261125.md).

## P0 논술 LAB 운영 장애 — 2026-11-26 22:43 KST Owner 보고

- **복구 대기.** Owner가 실제 출시 iOS 앱과 모바일 WEB에서 서비스 상태 조회 실패를 확인했다. 이번 주 신규 첨삭 요청 0건 및 마지막 정상 요청 11/22 17:53 KST는 Owner 보고다. 장애 시작이나 영향 건수는 이 시각으로 산정하지 않는다.
- 11/26 00:18 KST 학생 QA에서 Pages Production `ESSAY_REGISTRY_WORKER_JWT` 만료 및 discovery/availability HTTP 503이 확인됐다. 최신 Owner 증상은 기존 장애와 일치한다. 최신 preflight 및 HTTP 응답은 독립 재확인 대기. [기존 조사](finance-auth-renewal-20261117.md).
- Owner는 [터미널 절차](../tool/cloudflare_essay/OWNER_JWT_RECOVERY.md)의 Essay Registry 항목으로 동일 `essay_worker` 권한의 30일 JWT를 발급하고 읽기 HTTP 200 확인 후 `legendstudy-lab` Pages Production의 해당 Secret을 저장한다. 저장 확인 후 운영 설정과 아티팩트를 보존해 배포한다. Finance 설정 변경 없음.
- 배포 후 승인된 학생 권한 계정으로 WEB 및 출시 APP에서 대학 상태·표시, 시험·문항, 첨삭 가능 여부, 이용권과 답안 작성 및 제출 직전까지 확인한다. Owner iOS 확인과 503 해소 확인이 남았다. 기존 학생 요청 재실행 및 이용권·원장 변경 없음.
- APP 출시 준비, 무료 첨삭권 정책, 배지, 품질 콘솔 및 신규 기능 작업은 복구 우선으로 보류한다. 로그 기반 영향 분석과 Registry 자동 갱신·감시 설계는 후속으로 추적한다. 운영 자동화 적용은 별도 승인 대상이다.

## APP 실제 출시와 다음 후보

**iOS/Android 1.0.6, Build88 RELEASED.** iOS11/18,Android11/17 출시. 출시 소스 `08345b69b1d71c9038be50767bd849a7354d2b8e`. 최종 포함 기능·제외·QA 한계의 단일 참조는 [88 릴리스 기록](pdf-white-screen-hotfix-20261117.md)이다. PDF/학습/기존 학교TOP10/MY 개선을 재개발 대상으로 등록하지 않는다.

[1.0.7+89](app-release-89-preparation-20261125.md)는 출시88을 포함한 `76cc4050` 후보로 D-Day 및 무료2 안내가 BUILT/UNRELEASED다. 양OS 빌드·자동검증 완료와 실기기88→89 업데이트·스토어 출시를 구분한다. 업로드·제출은 아직0이며 승인 필요. 무료2 DB 미적용 상태에서 정책 적용 완료로 안내하지 않는다.

## 운영 상태와 DB

- WEB: 진단 패치 `513e641f`/Pages `5fd50a21` 운영 반영, 기존 품질V1 및 정적3207경로 보존. [배포·검증](quality-console-v1-20261125.md). 후속 문서 HEAD를 배포 소스와 혼동하지 않는다.
- Essay Worker: `29f4f6cc-433f-4e8e-8da4-9ca5710f2e71`,11/22 배포·11/25 확인. 관리자 복구/정확 인용 보정 운영, 부분 재생성·신규 상한은 비활성. [런타임](admin-recovery-runtime-fix-20261122.md).
- DB: 프로젝트 stlhijzpjfgwwdgunlsd. [D-Day 설치](admissions-dday-implementation-20261120.md)와 [복구 설치](admin-run-recovery-deployment-20261122.md) 확인. [무료2 SQL](signup-credit-policy-two-20261125.md)은 승인 대기. 모든 migration이 적용됐다는 뜻은 아니다.
- 결제: Toss LIVE 유지. Finance Worker `d14a757e-5b46-448c-8b66-325d181c2a9f` **11/23 10:30:35 자연주기 갱신 성공**,active 만료11/30 10:30:35 KST를 기존 로그에서 확인. [P0 교차검증](finance-auth-renewal-20261117.md). 별도 Pages Registry credential invalid로 WEB/공유 APP 첨삭 진입503,미복구/P0. **학생 QA에서 EXPIRED 확정**, Owner Registry 갱신 대기.

## 진행·미완료·승인·다음 작업

1. q1 요청03629605…는 reserved,완료1/2. 복구 연결 수정과 실제 완료는 다르다. Owner 승인 후 직전 잠금·완료문항 해시·이용권0 재확인→기존 복구1회. 이번 실행 없음.
2. **P0 첨삭 진입503**: Worker binding=true/Registry credentialIssue=EXPIRED. Owner 동일권한 Registry credential 갱신→설정 보존 배포→학생 비파괴 재검증. Finance 성공 확인으로 로그접근 BLOCKED 해소;학생 재실행 없음.
3. APP89 실기기 업데이트·PDF/로그인/학습/수동 및 자동 D-Day 회귀. 스토어 제출 별도 승인.
4. 무료2 신규 지급 정책은 [준비된 SQL/검증/원복](signup-credit-policy-two-20261125.md) Owner 승인·적용 후 확인. 기존 지급분/원장 보존.
5. [품질V1](quality-console-v1-20261125.md) PARTIAL:70요청118문항 대조,내용20요청38문항 검토. Q15 개별 저장·Owner 집계·나머지 내용/Claude 검토 미완료. 새 DB는 exact SQL 준비 후 별도 승인.
6. 아주·인하 자료의 부족 범위와 [통합 후속](integrated-followup-20261125.md) QA. 배지·OCR·수리 확장·Evidence ID는 구현/설계/활성화를 각각 구분한다.

## 개발 기준과 인수인계

- 공식 문서와 출시된 APP 기준: `origin/main`. main은 출시88을 포함한다. 이후 Wiki 커밋은 버전 증가나 운영 배포가 아니다.
- APP 후보89: `codex/operations-commercial-20261113`; 운영/SQL/Worker: `codex/material-service-app-20261022`; WEB 별도 저장소: `codex/lab-admin-operations-20261114`.
- 작업 전 원격 main의 AGENTS/index/current를 읽고 실제 branch/HEAD와 출시 ancestry를 확인한다. 오래된 작업 branch 전체를 APP에 덮어쓰지 않는다.
- 종료 시 작업 결과를 공식 main Wiki에 선택 통합하고 원격 일치 검사를 한다. 다른 기능의 미커밋 변경을 섞지 않는다.

## Daily Sync status

기존 자료 운영/자동 동기화 범위는 [Materials closeout](materials-final-closeout-2026-09-27.md)과 [Daily Sync 이력](history/status-checkpoints.md)을 참조한다. 이번 작업에서 재수집·운영 실행 없음.

## 과거 상태

과거 Store BLOCKED/AI OFF/10월 우선순위는 [정상화 전 상태 원문](history/status-checkpoints.md#pre-normalization-release-branch-status--2026-11-25)에 보존했다. 현재 판정으로 사용하지 않는다. 제품 정책은 [decisions](decisions.md), 실제 과거 작업은 [log](log.md)를 따른다.

## 검사 입력 (동일 문서의 구조화된 요약)

자동 검사는 필수값·Git·구조화된 충돌만 검사한다. 스토어/DB/운영 사실 자체는 보증하지 않는다. 외부 상태는 실행·배포·업로드 직전에 재확인한다.

<!-- handoff-status -->
```json
{
  "wiki_branch": "main",
  "last_verified": "2026-11-26",
  "release_record": "pdf-white-screen-hotfix-20261117.md",
  "candidate": {
    "version": "1.0.7",
    "build": 89,
    "source": "76cc405028308ceddcc76dca77285e6795346640",
    "branch": "codex/operations-commercial-20261113",
    "state": "BUILT",
    "release_state": "UNRELEASED",
    "evidence": "app-release-89-preparation-20261125.md"
  },
  "unreleased": [
    "자동 입시 D-Day APP",
    "무료2 안내 APP/운영 DB 정책 승인 대기"
  ],
  "web": {
    "source": "ecac36e5b31dbf980ee0eebbb433626bb33c477e",
    "deployment": "6e4b8189-5a6c-4f28-8d16-e15bf4508500",
    "state": "DEPLOYED",
    "evidence": "quality-console-v1-20261125.md"
  },
  "worker": {
    "essay_version": "29f4f6cc-433f-4e8e-8da4-9ca5710f2e71",
    "finance_version": "d14a757e-5b46-448c-8b66-325d181c2a9f",
    "evidence": "project-cross-review-20261125.md"
  },
  "db": "D-Day/관리자 복구 APPLIED; 무료2 APPROVAL_PENDING; 전체 migration 전수 인증 아님",
  "payment": "Toss LIVE 유지,이번 변경0",
  "finance": "11/23 10:30:35 갱신 성공;active 만료11/30 10:30:35 KST",
  "development": {
    "app": "codex/operations-commercial-20261113",
    "backend": "codex/material-service-app-20261022",
    "web": "codex/lab-admin-operations-20261114"
  },
  "work": [
    "APP89 QA",
    "품질 콘솔 Q15/Owner 집계 미완료"
  ],
  "blocked": [
    "첨삭 진입503: Pages Registry JWT EXPIRED;Owner 갱신/복구 대기"
  ],
  "approval": [
    "q1 실제 복구",
    "무료2 운영DB",
    "스토어 제출",
    "부분 재생성/상한 활성화",
    "Q15 DB/Owner 역할 계약"
  ],
  "next": [
    "P0 Registry credential Owner 갱신 후 비파괴 복구 검증",
    "q1 승인 후 직전 조건 재확인",
    "APP89 실기기 회귀",
    "무료2 DB 승인 패키지 검토"
  ]
}
```