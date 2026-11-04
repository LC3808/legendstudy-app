# 관리자 핵심 KPI 정의서 — Phase 2 계약 후보

2026-11-04 후속: Owner 구현·운영 적용 승인. [Phase 2 실제 적용 범위·검증·잔여 GAP](admin-analytics-phase2-20261104.md)을 먼저 확인한다. 아래 설계 전체가 구현됐다는 뜻은 아니다.
[Phase 1](admin-analytics-phase1-20261104.md) · [현재 RPC/화면](admin-analytics-inventory-20261104.md). **아래 신규 산식은 설계 후보이며 기존 RPC 의미를 이미 변경했다는 뜻이 아니다.** [기존 NSM 계약](analytics-p0-launch-contract.md#kpi-calculability-against-the-real-schema)의 학생 제출→평가→재작성→재평가를 계승한다. 서버 사실과 GA 행동을 섞지 않는다.

## 모든 행에 적용되는 공통 계약

- 기간 W: KST 시작일00:00 이상/종료일 다음날00:00 미만. 주간은 월요일00:00부터 다음월요일00:00; 현재 주는 미완결 표시. UTC 저장을 조회 경계에서 변환한다. 요청일/완료일/거래일/검토일을 각 행대로 사용한다.
- 갱신 R: 화면 진입/명시적 새로고침/필터 변경에 기존 읽기 RPC 실행, as_of 표시. 백그라운드 수집/주기 작업을 만들지 않는다. 조회 결과는 해당 account/scope에만 유지하며 로그아웃/계정전환 시 제거한다. GA는 G: 기존 no-store Data API 요청, 플랫폼 지연/thresholding/sampling을 표시한다.
- 권한 A: 기존 admin_operator와 해당RPC의 lifecycle gate. 품질 Q: 기존 quality_operators+대상 lifecycle, 원문이 없는 승인된 요약만 A에 제공. GA는A. 신규 통계도 기존 개인정보 최소화/5명미만 보호 및 현재학년 표시를 적용하되 현재 운영총계의 공개범위를 임의 확대하지 않는다.
- 중복제거: 명시된 source+ID 키. 동일 parent의 checkpoint/provider 재시도는 학생회차 증가가 아니다. 금액은 통화·환경·채널별, 토큰은 call별. 현재로그인플랫폼으로 과거거래 플랫폼을 추정하지 않는다.
- 기존 자료의 테스트/운영식별이 불완전하면 `environment=UNKNOWN`을 별도 표시한다. 근거 없이 관리자 계정 활동을 전부제외하거나 실학생으로단정하지 않는다. 제외정책·커버리지 검수 후 학생 NSM을 확정한다.

| 상태 | 값·표시 규칙 |
|---|---|
| 0 (READY) | 소스/권한/기간/집계 성공이 확인됐고 실제 대상0일 때만 value=0 |
| NOT_CONNECTED | RPC/수집/adapter 미설치·미연결, value=null. 원천자료가0건이라는 뜻 아님 |
| NOT_VERIFIED | 자료/계약/분모/수신 검증 미완료, value=null 또는 별도 관측부분값. 완전통계로 표시하지 않음 |
| ERROR | timeout/권한/파싱/서버실패, value=null·재조회. 이전값은 오래된값임을명시하거나숨김 |
| ESTIMATED | 승인된 단가·산식·버전/시각·범위를 가진 추정. 실제금액과 분리, 가정과coverage 표시 |
| SUPPRESSED | 소표본·차분노출 보호. value=null, ‘표본 보호’. 합계에서 역산되지 않도록 동반억제 |
| NOT_APPLICABLE | 분모0/비교대상없음/서로다른정책. 비율0%나0단계로 바꾸지 않음 |

현재 UNKNOWN/NOT_AVAILABLE/NOT_IMPLEMENTED/NOT_TESTED는 원래code를 detail에 보존하고 원인에 따라 위 상태로 투영한다. 예: 설치계약없음→NOT_CONNECTED, 시험안함→NOT_VERIFIED. 기존 L의 null은 EMPTY와SUPPRESSED를 개별지표별로 구분할 수 없어 임의복원하지 않는다. Phase2 read DTO에는 value/unit/state/reason/source/formula_version/from/to/as_of/denominator/coverage를 **기존 응답의 호환 확장**으로 검토한다. 범용 지표 플랫폼을 새로 만들지 않는다.

아래 각 행의 ‘결측’은 공통 상태 규칙과 함께 적용된다. 모든 서버 행은 **R 갱신**; 별도 Q표기 외는 **A 권한**이다.

## A 서비스 현황 및 학습자 맥락

| 지표 | 계산식·단위 | 원천/기존 RPC | 기간·중복키 | 결측/주의 |
|---|---|---|---|---|
| 전체 가입 계정 | 현재 auth.users 수, 계정 | admin_dashboard | M, user_id | profile수와별도; 현재 계정정책에맞춰삭제/제한상태구분 |
| 프로필 보유·미보유 | profiles 연결 유무별 계정수 | admin_dashboard/member_list | M,user_id | 프로필없음=가입실패 아님 |
| 신규 가입 | created_at∈W 고유계정 | analytics_kpi_overview | 가입시각,user_id | GA sign_up started와다름 |
| 활성 논술 학습자 | W에 학생제출 또는 완료가 있는 고유계정 | analytics_private views→기존 kpi 확장 | 제출/완료시각,user_id union | Math별도포함은adapter검증필요. 현재kpi trailing1/7/30은별도이름유지 |
| 활성 공부 기록자 | 유효공부구간이 W와겹치는 고유계정 | admin_dashboard_study | overlap,user_id | 미기록=공부0아님; 최소5 |
| 최초 첨삭 완료 학생 | 학생별 가장 이른 정상 처리완료 시각이 W인 고유학생 | 기존 평가/회차→read 확장 | 최초completed_at,user_id | 현재 `completed_users`는최초조건없음. 과거원천누락시NOT_VERIFIED |
| 재첨삭 완료 학생 | 실제학생재작성 lineage의 완료가 W인 고유학생 | run.parent/Math predecessor/legacy attempt | 재평가completed_at,user_id | operator재평가/기술retry 제외. 유료후속/무료분리 |
| 주간 전체 루프 완료 학생 | 같은 학생·문항/회차범위에서 최초완료→후속재작성완료, 주내완료≥1 고유학생 | 기존 NSM+exam/Math lineage | 재평가completed_at,KST주,user_id | 최초완료는이전주가능. requestkind·범위·부모완료·시각순서필수. 현재funnel과별개 |
| 학교·학년 분포 | 현재입력별 고유profile수 및 미입력수 | admin_dashboard/profile | M,user_id,학교office+code | 과거학년추정금지; 좁은cohort 보호 |
| 기록 공부 총시간 | 사용자별 active_segments를 W경계로자르고 union한 ms 합 | admin_dashboard_study / admin_learning_analytics | 구간시각,user_id+union | ended/합산대상/동기화기록만. 시간·분으로표시; 원ms보존 |
| 기록자 평균 공부시간 | 위총ms/유효기록자수 | 같은study RPC | W,user_id | 전체회원으로나누지않음; 분모0은N/A·소표본보호 |
| 학년별 기록시간·평균 | 같은study 산식을 현재학년별 | admin_dashboard_study | W/현재profile,user_id | 1/2/3/재수생/미입력, 작은cohort 있으면전체학년표억제. 역사적학년아님 |

## B 논술 학습 분석

| 지표 | 계산식·단위 | 원천/기존 RPC | 기간·중복키 | 결측/주의 |
|---|---|---|---|---|
| 대학별 이용 학생/회차 | 각각 distinct user / distinct run | runs+Registry, analytics_university_usage 재사용확장 | submitted_at∈W,source/run | 현재세션·회차 혼합을학생수로변경금지. Math중복확인 |
| 시험·문항별 제출/완료 | 학생회차/문항을 별도열로 count | snapshot.answers/result/checkpoints/legacy/Math | 제출/완료 기준 별도선택,source+run+question | retry checkpoints는최종선택결과만. 내부qindex≠공식문항번호 |
| 최초 평가 회차 | 최초시도/새유료cycle 시작의 완료회차수 | run lineage+decision / Math kind | completed_at∈W,source+cycle initial | ‘학생생애최초’ 지표와다름 |
| 무료 재첨삭 완료 | included_revision 근거+정상완료 후속회차수 | billing decision+parent+Ledger검증 | completed_at∈W,source+run | parent존재만으로무료추정금지. 소비0 검증은 별도 integrity |
| 재작성 제출률 | 최초정상완료 cohort 중 as_of까지 학생재작성제출한 root / 적격root | 기존 NSM/lineage | 최초completed_at∈W,root | 관찰기간/무료기한 표시. 신규cohort 미성숙, 실패최초제외 |
| 학습 루프 완료율 | 위 적격root 중 후속정상완료 root / 적격root | 위와같음 | 최초완료cohort+as_of,root | 주간완료학생/주간가입자 비율로대체금지; 다른집합분모 금지 |
| 학습5단계 분포 | valid ASSESSED level1~5 각각평가수 / 단계판단가능평가 | TASK16-L 저장/기존coaching read | assessed_at∈W,source+eval+question+policy | 운영미연결. 보류/결측을분리, criterion1~5와다름 |
| 최초→재첨삭 변화 | 호환policy/rubric/문항의 실제level_after-level_before; pair별분포 | TASK16-L 비교계약 | 후속assessed_at∈W,prior→current pair | 이전없음·기준다름은비교불가; 평균대입·backfill금지 |
| History 이용 | growth_view/detail 등 기존GAevent의사용자/발생수 | GA4 (G) | GA속성기간/사용자,metric별dedup | LAB미수신; History저장행수로열람수추정금지 |
| 희망대학/자료/지원 | targets고유학생, saved행, recent학생·자료쌍, applications행 | admin_learning_analytics | 생성/최신열람∈W,기존row key | 현재남은projection. 변경/삭제history·합격추론금지; 최소5 |

## C 품질 및 신뢰성

품질분석은Q 또는 승인된 원문없는A요약. 자동후보비율과 사람이확정한오류비율은 분리한다.

| 지표 | 계산식·단위 | 원천/기존 RPC | 기간·중복키 | 결측/주의 |
|---|---|---|---|---|
| 처리 완료율 | completed / (completed+failed), 확정상태 중% | admin_essay_operations / reliability | requested_at∈W,source+run | pending/cancel별도수. 전체요청대비완료율은별도분모로명시 |
| 판단 보류율 | semantic held / 의미판정가능 완료결과 | Math overall/검증된result projection | completed_at∈W,eval+question | 보류가COMPLETED에있음. 필드없음=보류0아님 |
| OCR 수정률(대리 지표) | 동일사진raw↔확정전사 차이 존재case / 두version비교가능case | extraction/confirmed refs | confirmed_at∈W,source+image/extraction pair | 차이≠OCR오류. 인문/혼합coverage미확정, 불완전분모NOT_VERIFIED |
| 계산/정답/오답 오판 의심 | 각 detector/rule후보 고유subject수 | existing result/checkpoint+read rule 후보 | completed_at∈W,subject+rule_version | detector미구현NOT_CONNECTED, 확정오류로표시금지 |
| 확정오류율(검토표본) | current human head 중 해당오류 / 검토가능head | HQ judgments/findings | reviewed_at∈W,subject+rubric의head | 검토표본selection bias 표시, 전체모델정확도아님 |
| 평가 근거 불일치 | frozen refs/hash/문항ID 불일치 후보 및 확정finding 각각수 | Evidence/Registry/result+HQ | 평가cohort/검토기간별,subject | missing evidence와확정mismatch구분 |
| 힌트 품질 | 안전성/실행가능성/노출정책 검토결과 분포 | stored hints+HQ findings | reviewed_at∈W,subject+hint_ref | hints저장0≠사용0. NA/미노출 포함분모별도 |
| 학습5단계 일관성 | 동일packet 독립검토 승인비율/검토불일치수 | TASK16-L review hash/policy | assessed_at∈W,packet hash | 운영미연결. 반복모델값일치만으로정확도판정금지 |
| 사용자 오류 신고 | 평가연결신고 건수/미처리수, category별 | 기존평가feedback RPC 복구후 | received_at∈W,feedback_id | 현재RPC미설치. support 문의자동병합금지 |
| 정책별 결과 | 같은policy/model/prompt/evidence별완료·보류·검토분포 | storedprovenance+HQ | 평가cohort,source+eval | 누락version UNKNOWN. 과거vs현재집단 인과비교금지 |
| 기술 재시도 | 요청generation수/실호출수 별도 | retry_requests / processing_runs /receipts | 요청시각 또는실호출시각,source+callID | exam attempt>0,legacy계약run_no>1. 기존cost RPC off-by-one보완 |
| 지연 P50/P95 | 종료-시작의분위수(초) | run timestamps 또는 provider latency | requested_at∈W,run 또는call | 두단위혼합금지; 호출시각미상일별제외 |
| 미검토/회귀coverage | 검토대상중 유효head없는수 / 전체대상; 회귀완료case/승인case | QL+subject adapter / 회귀증거 | M/as_of,subject 또는case+version | 현재QL legacy0을전체품질대상0으로표시금지 |

## D 이용권·매출·비용

| 지표 | 계산식·단위 | 원천/기존 RPC | 기간·중복키 | 결측/주의 |
|---|---|---|---|---|
| 신규가입 무료 지급 | signup 분류 grant거래 balance_delta합, 개/건별 | admin_credit_report v2 helper | tx.created_at∈W,transaction_id | 최초지급reason 보존 |
| 베타 무료 지급 | beta 분류 grant수량합 | 동일; promotion+최초reason/daily binding | 거래시각,transaction_id | source promotion만으로event로분류금지 |
| 이벤트 지급 | event 분류수량합 | 같은helper | 거래시각,transaction_id | beta/보상/관리자지급과구분 |
| 관리자 지급 | admin 분류수량합 | 같은helper | 거래시각,transaction_id | 자유reason문자열만으로보상판정금지 |
| 유료 구매 지급 | purchase분류수량,WEB/AppStore/Google별 | grants/transactions+purchase provenance | 지급시각,transaction_id | 지급개수≠매출액. unknownplatform 별도 |
| 기타/보상/이관 | 기존v2 나머지분류별수량 | 같은helper | 거래시각,transaction_id | 8분류전체를보존해subtotal=total검사 |
| 이용권 예약 | reserve reserved_delta합 | credit_transactions | 거래시각,transaction_id | 유상소비아님; 신청회차수는distinctdecision별도 |
| 사용 확정 | consume의 -balance_delta합 | 같은원장 | 거래시각,transaction_id | 여러grant합산, reserve와이중차감금지 |
| 예약 해제·복구 | release의 -reserved_delta, 실제refund양수 별도 | 같은원장 | 거래시각,transaction_id | 지급/금전환불과분리, failure현재state로소급추정금지 |
| 현재 보유/사용대기/가용 | 기존snapshot balance,reserved,available 계약 | admin_credit_snapshot/member_credit | 현재M,account/grant | 기간tx합을현재잔액으로표시금지; expiry포함기존정책유지 |
| WEB 총매출 | LIVE KRW paid_at있는실제결제금액합 | analytics_revenue/payment_orders | paid_at∈W,order_id | 현재상태paid만의dashboard완료금액과차이명시 |
| 금전 환불 | 성공취소operation금액합 | payment operations | completed_at∈W,operation_id | Credit release/refund와다름; partial취소합,중복receipt제거 |
| 기간 순매출 | 같은통화총매출-기간환불 | 위두원장 | 각발생시각,W | 환불이과거주문이면음수가능; 회계결산/수수료순이익아님 |
| IAP 플랫폼 매출 | 검증된금액·통화·환경의구매/환불 합 | 기존IAP기록/스토어정산검증후 | 확인거래시각,store transaction ID | 과거지급만있는행은NOT_VERIFIED금액. WEB매출에추정합산금지 |
| Provider 호출·토큰 | 실제receipt별calls 및 input/output/cached 합 | essay_ops_private.calls +Mathtelemetry adapter | called_at,없으면request코호트별도;source+callID | 누락tokens를0보완금지, stage별coverage; retry/검토/학습산출분리 |
| ACTUAL 비용 | provider_reported 동일통화합 | 기존cost fields | call시각 또는미상별도,callID | provider보고부분합≠청구서정산액, UNKNOWN별도 |
| ESTIMATED 비용 | versioned승인단가×실제tokens/캐시항목 | 기존cost추정계약 재사용후 | 단가유효시각+callID+price_version | 현재추정저장RPC미연결. 이번단가조회/저장/과거보정안함 |
| 비용 coverage | 금액있는calls/관측calls, 시각있는calls/관측calls | 같은calls | W및미상분리,callID | receipt없는호출은분모자체미확인. 현재185행모두UNKNOWN |

## 기존 지표 의미를 보존할 항목

`analytics_funnel`은 **가입코호트의 이후전체기간 도달수**로 별도유지하고 새주간NSM으로 이름만바꾸지않는다. `analytics_free_credit`는 signup grantcohort의 이후소비이며 ‘1개소비 후 이탈’은 이탈증거가 아니다. 무료→유료의시간순서를검증하지않은기존count는인과전환으로표시하지않는다. 만족도이진/수치, 요소별1~5/학습5단계/품질rubric은 각각분리한다.

승인할 핵심 정의: 활성논술 vs공부기록자, 생애최초 vscycle최초, 월요일KST NSM, 루프완료cohort관찰기간, 검토표본오류율/보류분모, 테스트기록제외계약. 기존RPC호환테스트 후 read-only확장 후보를 마련한다.
