# Durable Decisions

[10/31 최종 피드백 UX·빈 재작성·명시적 원본 불러오기·Draft 보존·검증/미완료](final-feedback-ux-refinement-20261031.md). 학생 중심 결과 정책의 후속이며 평가·과금·이력은 유지한다.

## 2026-10-31 — 학생 답안과 수정 행동 중심 결과

[학생 중심 첨삭 결과 정책·구현·검증·미완료](student-centered-essay-feedback-20261031.md) 공식 평가자료는 내부/관리자 검수에 보존하고 학생 결과 기본 화면에서는 비노출한다. 저장된 피드백만 재구성하고 누락된 가이드·총점·학생 인용을 생성하지 않는다. 기존 성장·무료14일·과금 분리 정책을 유지한다.

## 2026-10-29 — APP 계열 표시와 실행 계약 분리

Owner는 인문 / 사회·상경(수리 포함 가능) / 자연·공학·이학·의예 공개 보류를 분리한다. inputMode나 engine만으로 서비스 계열을 결정하지 않고, 혼합 문항 자동 제외·새 엔진 활성화·과금 변경을 금지한다. [10/26 기존 분리 정책](commerce-korea-20261026.md)을 유지하며 [10/29 APP 수정과 미완료](app-owner-fixes-20261029.md)에 적용한다. 정상 PASS OCR/편집/저장 보존, 운영 DB·Worker 변경은 별도 승인, 재작성/성장 재설계는 후속이다.

## 2026-10-28 — APP 학습 회차와 과금 분리·사진 OCR 입력 보조

Owner는 동일 canonical 시험·문항의 유료 후속 첨삭도 연속된 학습 성장으로 표시하도록 확정했다. 첫/2차/3차 첨삭 표시는 파생 UI이며 parent/paid lineage·무료14일·Credit 원장을 수정하지 않는다. 최신 시험 기본 펼침·이전 접힘·5개씩 표시, 동일 평가 pin만 비교하고 3회 이상 전체 꺾은선을 제공한다. 기존 [성장 정책](essay-growth-history-ui-20261026.md)을 확장한다.

[사진 OCR 연구](essay-photo-ocr-design-20261028.md)의 APP 통합을 승인: iOS Vision/Android ML Kit Korean 기기 내 인식 → 학생 확인·수정 → 명시 합치기/교체 → 기존 TEXT 초안 저장. 이는 10/26 TEXT 사진 첨부 금지의 평가 입력 계약을 변경하지 않는다. OCR 사진은 평가 첨부가 아니며 자동제출/유료 API/실제 Provider 검증은 금지. Claude eedd28f 작업을 보존해 별도 Worktree에서 통합한다. [구현 및 남은 게이트](app-final-integration-20261028.md).

## 2026-10-27 — MY 지원 현황 노출 및 성장 요약

지원 현황은 기존 student 3학년/retaker에게만 노출한다. 다른 상태에서는 관심 대학만 표시하며 지원 기록은 보존한다. 프로필 저장 후 즉시 재계산한다. MY는 간결한 성장 그래프, 상세 평가·이력·피드백은 전용 LAB에서 제공한다. [기존 MY 정책을 계승한 최종 적용](my-college-management-20261026.md#2026-10-27--최종-my-통합학년별-노출성장-요약).

## 2026-10-26 — 수리논술 코칭·성장 필수 후속

기존 MATH-4/5/6을 재사용해 실제 풀이 기반 코칭 → 재작성 → 재첨삭 → 성장으로 연결한다. 인문·사회·적격 상경 출시 준비 후 순차 착수한다. 자연·의예·과학 유료 공개 보류, 수리 무료 베타 별도 검토, 인문 일일 2 Credit 자동 적용 금지. 이번 결정은 Production DB·Worker·정산 변경 승인이 아니다. [수리 코칭 필수 후속](math-technical-review-20261026.md#2026-10-27--owner-필수-후속-ai-풀이-코칭성장) 및 기존 learning runtime 계약을 따르며 Issue #6은 실제 완료까지 유지한다.

## 2026-10-26 — 인하대 분리 연결·공통 브랜드 히어로

[전체 대학 STANDBY 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책)을 인하 인문·자연·의예에 적용한다. 자연/의예는 Math 유형을 공유하되 시험 ID와 해당 공식 문제·해설을 분리한다. Owner는 인하 한정 Registry/근거/프로필/실행/PDF SELECT/공개 SQL의 사전→적용→사후 실행을 승인했다. 실제 평가·차감은 Owner QA에 남긴다. 기존 공통 네이비 히어로 지시는 이 범위에서 화이트+대학별 Theme로 대체하며 로고·공식링크·일정·Native APP은 보존한다. [구현 및 적용 영수증](inha-standby-20261026.md).


## 2026-10-26 — 문항별 접힘 및 입력 계약

첫문항만 기본 펼침, 수동 저장 후 다음 미작성 문항 자동 펼침은 사용자의 직접 토글보다 후순위다. TEXT에는 촬영/새첨부 메뉴를 제공하지 않는다. Registry IMAGE 또는 기존 서버의 문항별 Math binding만 이미지·수식 입력을 제공한다. 대학·계열명 추정 금지. 기존답안/사진은 삭제하지 않으며 재진입 복원·부분제출·1/0Credit 보존. [구현·근거](essay-web-studio-ui-20261026.md).

## 2026-10-26 — 첨삭 직후와 History 결과 화면 통합

최신 Owner 승인: 상단4단계 표시 제거, 전체 문항 완료 후 기존 ID로 결과 전용 화면 자동 이동. History와 동일 컴포넌트·저장 결과 사용. 비교 대상이 없으면 성장 영역 숨김, 재작성/추가 첨삭은 명시적 선택. 기존 결과 상세 불변 지시 중 이 통합 범위만 대체한다. APP·DB·Worker·Secret 및 1/0Credit 계약은 보존. [구현·운영 확인](essay-web-studio-ui-20261026.md).

## 2026-10-26 — WEB 작성·진행 UI 범위 승인

Owner는 네이비 히어로·문항 카드·전체회차 제출·실제 서버 상태 진행 모달·History 목록 표현 변경을 승인했다. 기존 UI 동결 지시보다 이 범위만 우선한다. APP 및 결과 상세는 불변. 기존 회차 1/0 Credit 정책과 부분 제출·사진 명시 확인·멱등성은 유지한다. 가짜 진행률 금지, Provider 반복 호출 없이 UI 검사한다. [구현·배포·제한](essay-web-studio-ui-20261026.md).

## 2026-10-24 — 시험 회차 첨삭 단위 복원

Owner 확정: 동일 시험 회차 전체 문항은 최초1Credit, 기존 무료재첨삭0Credit. 문항별 텍스트/이미지 Draft 저장0Credit. 최소1답안, 부분제출은 미작성 문항 안내와 명시적 동의 후 작성분만 평가한다. 중복/재처리 추가차감 금지, 성공 문항 결과 보존, History는 회차 아래 문항 연결. Owner 추가 확정: 시험 ID와 제출 회차 ID를 구분한다. 미제출 문항을 나중에 첨삭받는 경우 새 유료 회차1Credit이며 기존 무료재첨삭에 추가하지 않는다. 각 회차의 실제 제출 문항 집합을 보존하고 부분제출 모달에서 현재1Credit/추후 새회차1Credit을 안내한다. 기존 [시험 단위 정책](essay-lab-product-v1.md) 복원이며 새 과금정책이 아니다. Owner는 회차 실행·재처리 계약에 한해 Worker 조정을 허용했다. 평가 엔진·프로필·Secret 변경은 범위 밖이다. Production SQL은 Owner 직접 실행. [실행 계약 및 차이](https://github.com/LC3808/legendstudy-lab/blob/codex/web-app-release-20261024/docs/owner-review-20261024/README.md).

## 2026-10-01 — Quality read authority and evidence access

Owner approves a narrow auth.users Quality allowlist, not admin_users/generic RBAC. Quality
Console is web; authorization is shared App/LAB backend. Authorized detail includes full
submitted answer; account direct identifiers excluded by default. Early detailed/near-census
review → mature problem-focused + sampled review. Privileged read audit POST_LAUNCH;
privileged-write audit required when introduced. [LSA-2C contract/package](essay-lab-worker-provider-l2.md#lsa-2c-shared-quality-authorization--2026-10-01)
defines the narrow shared read authority. No duplicate evaluation/sentence/history store or current Human QA
persistence. Production application remains Owner-controlled and separately verified.

## 2026-09-30 — Post-audit Owner clarification

Cross Review A/B: HEALTHY_WITH_DEBT; no broad refactor/consolidation. Owner preserves
[one Profile experience with domain-owned facts](product-architecture.md#post-audit-owner-alignment--2026-09-30),
[credit / one-time ad removal / period membership separation](roadmap-monetization-and-in-app-learning.md#post-audit-commercial-boundary--2026-09-30),
[post-CSAT then January phased/source-gated Academic/Admission](roadmap-academic-analytics.md#phased-and-source-gated--owner-clarification-2026-09-30),
[Deep Analytics and context without automatic anonymity](longitudinal-learning-admissions-data-strategy.md#deep-analytics-and-student-context--owner-clarification-2026-09-30),
and [read-mostly Quality v0 / pre-student-pilot Human Judgment design / Golden Set DB defer](essay-lab-worker-provider-l2.md#quality-console-boundary--owner-clarification-2026-09-30).
No new foundation implementation authorized. The separate day_targets ACL correction follows Owner-applied Production policy.

## 2026-09-30 — Essay learns from success and error

[Positive learning reinforcement](essay-lab-product-v1.md#l2-c2-positive-learning-reinforcement--2026-09-30)
requires concrete student move→WHY→criterion→reusable strategy, alongside corrective
where/what/why/how. Strong answers may have zero CORE; no forced defect or optional-polish
promotion. Examples are not answer keys or perfect-answer guarantees. This is student learning,
not model RL training; parser validity never certifies educational quality.


## 2026-09-30 — Sentence roots remain mandatory; CORE is a subset

Owner approves [Option A](essay-lab-scaffolding-persistence.md#l2-b4-option-a-implementation--2026-09-30):
every persisted sentence observation belongs to a real improvement; minor issues may be
NON-CORE. No null orphan links, fake CORE, parser repair or SQL weakening. Contract1.3 remains;
new prompt version expresses the accepted teaching semantics. Historical L2-B3 pending-choice
statements are superseded by this approval. Model selection/real calls remain separate gates.

This file records long-lived product and architecture decisions. Routine progress belongs in `log.md` and `current-status.md`.

## 2026-09-30 — Concrete student-anchored Essay instruction

[L2-B3 Product contract](essay-lab-product-v1.md#l2-b3-concrete-feedback-contract--design)
requires where/what/why/how/next-check, precise logical connections, selective sentence review,
strength/stance preservation and repeated student rewriting. Core1–2 preferred;3 exceptional,
existing hard cap preserved. Schema PASS or quantity never proves educational quality.
[Owner review](essay-lab-model-bakeoff-l2-b.md#l2-b3-owner-human-review-freeze--2026-09-30)
prefers GPT in two cases only, candidate not Production selection. [Root design](essay-lab-scaffolding-persistence.md#l2-b3-vnext-contract-design--no-implementation)
recommends real non-core roots without DB change; nullable independent storage awaits review.

## 2026-09-30 — Archive-first official Essay evidence

[Official evidence archive strategy](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30) is canonical: verified Owner-held university PDFs precede web reacquisition;
raw PDF remains source truth, rubric is normative and multiple examples are calibration.
Explicit non-criteria/scoring-length rules and versioned transcription review are required
future evidence distinctions. Current frozen bake-off stays unchanged; next prompt/version
prefers1–2 core tasks. Documentation decision only, no ingestion/schema/AI authorization.

## 2026-09-12 — Project independence

LegendStudy is fully separate from Muselry, including repository, codebase, Supabase, secrets, OAuth setup, identifiers, wiki, and deployment.

## 2026-09-12 — Native app, not WebView

LegendStudy will not be implemented as a simple WebView wrapper around `legendstudy.com`.

## 2026-09-12 — Canonical knowledge location

The repository-local `wiki/` directory is the official long-term development knowledge base. There must be only one canonical `wiki/current-status.md`.

## 2026-09-12 — Agent role split

- Codex: main coder + implementation lead (updated Day 4-A)
- Claude: UI/UX lead + support coder / code reviewer (updated Day 4-A)
- ChatGPT: planning, architecture, specification, review
- Manus: execution, Git/build/deployment support; Supabase direct work only when specifically useful
- User: final product decisions and default direct executor of Supabase SQL/migrations

## 2026-09-12 — Public repository during early development

The repository starts public to reduce multi-agent access friction. Before private conversion, access for all required development agents must be verified. Secrets are forbidden from Git regardless of repository visibility.

## 2026-09-12 — Structured ingestion

The app should consume normalized structured data. `legendstudy.com` content should be ingested into the backend rather than scraped by the mobile app during normal usage.

## 2026-09-12 — Login philosophy

Public study-resource access should not require login where possible. Login is primarily for personalization and synchronization.

## 2026-09-12 — Production application identity

Owner-approved in Day 2 / issue #3: use `com.legendstudy.app` for both Android
applicationId/namespace and the iOS Runner bundle identifier. Dart package remains
`legendstudy_app`; both platforms display `레전드스터디`. The iOS test-only bundle
uses `com.legendstudy.app.RunnerTests` to remain distinct from the app target.

This decision replaces Day 1's temporary identity and is independent of Muselry.
It does not imply Apple/Google registration, signing or OAuth configuration.
If platform registration reports a conflict, report it to the owner and keep the
choice unresolved rather than silently inventing another production identifier.


## 2026-09-12 — Content normalization and source evidence

Separate private source_posts from public content_items. One source post may
contain multiple content items; exam-type items optionally have shared-ID exams
metadata and raw subject occurrences. All content types may have resource links. Preserve raw labels and source provenance after normalization;
unknown values remain NULL rather than forced into modern taxonomy. Curated
subjects are versioned; historical variants require their own reviewed mappings.
Calendar year and academic/CSAT year are distinct fields.

## 2026-09-12 — Content access and personal data

Public active content is readable without login; published descendants must also
have a visible parent content item and subject occurrence when scoped. Mobile clients cannot write content
or source metadata. Personal profiles/bookmarks/recent views are auth-user-owned
under RLS. Auth-user removal cascades only personal data; content deletion is
restricted and normal unpublishing is an explicit inactive state.

## 2026-09-12 — Resource locations and ingestion identity

Preserve source URLs first; landing pages are not assumed to be direct file URLs.
No bulk mirroring or Supabase Storage setup in v0.1. Future mirrors must preserve
original provenance. Persist stable ingestion keys independent of display order,
normalized labels and mutable link queries. Ambiguous reconciliation requires
review; unique constraints alone do not make parsing idempotent.

## 2026-09-12 — Recent views and historical design-task boundary

Keep one recent_views row per `(user_id, content_item_id)`, upserting the server timestamp;
analytics event history is separate future scope. Day 3 produces a draft migration
and offline static review only. No SQL application, project creation, remote push
or merge is authorized by this design task.

## 2026-09-12 — Day 3 independent-review remediation

Claude's reported verdict was C (important corrections needed). Preserve the
existing entity architecture and raw evidence; add a backend quarantine queue.

1. LegendStudy's mandatory external post ID with source is the canonical ingestion
   identity. URL is provenance/location, never a fallback conflict key.
2. Assign `legendstudy-{external_post_id}-{source_content_key}` once (key moved to content_items). main or stable
   semantic keys identify source exams; never title, taxonomy or display position.
3. Taxonomy activity does not control source-content publication. Publish reviewed
   exams/occurrences/resources independently; inactive master joins fall back to raw labels.
4. Source-link-first remains. Attachment identity must be deterministic; same-content
   normalized URL collisions go to quarantine. URL UNIQUE is deferred for lack of
   evidence about legitimate reuse. Provenance corrections preserve resource UUIDs.
5. Notifications remain v1.0 product scope, with specific schema deferred to a later
   v1.0 milestone. No speculative profile arrays.
6. pg_trgm and the broad active_filters index are deferred until measured need.
   Stored sort_date is an exam-date sorting proxy, not a historical fact.
7. Verified mappings are immutable to automated ingestion **by contract**. S-9 is
   partially applied: no override GUC or service-role protection trigger in v0.1.
   The checker requires the contract and document rule. Before actual ingestion,
   assess a separate enforcement migration/management workflow; runtime protection
   against arbitrary service_role writes is not claimed.
8. ingestion_quarantine persists ambiguous evidence privately, including failures
   whose normalized transaction rolled back. Only trusted backend CRUD; no app API.
9. Duplicate content remains inactive with merged_into_content_item_id; trusted transactional
   merges validate cycles and personal conflicts. No automatic personal migration.
10. Profile id UPDATE enables key-preserving upsert; recent UPDATE grants only its
    two conflict keys and the trigger stamps time. Runtime coverage is tracked in
    database.md; the post-deployment recent upsert test now passes.

The supplied directive identifies S-7/S-8 (taxonomy), S-9 (verified protection) and
S-12 (profile upsert). It does not supply Claude's complete S-1–S-15 numbered review;
other numbers cannot be reliably assigned. Coverage is recorded by directive topic
rather than fabricating review IDs. At this remediation stage, independent
re-review had not yet been performed.

## 2026-09-12 — General public content layer (supersedes exam-centric draft)

LegendStudy app uses a general public content layer (`content_items`).
`source_posts` is ingestion/provenance-only, and `exams` is specialized metadata
for exam-type content. Bookmarks and recent views target content_items, not exams.

- Move common source identity, slug/title, original URL, publication and soft-merge
  pointer to content_items. Keep one authoritative parent is_active; remove exams'
  duplicate identity/publication columns. Assigned slug values remain stable.
- Use exams.content_item_id as shared PK. A generated constant exam discriminator
  with composite FK enforces exam-type specialization. Occurrences reference that
  shared key; resource occurrence/content composite FK preserves same-exam integrity
  with no redundant exam_id. Non-exam PDFs and attachment-free columns are valid.
- Home is latest **known source** publication/modification (greatest of timestamps),
  not ingestion time. No reliable modified time means publication fallback without
  a synthetic bump. Exam sort_date remains separate historical-date sorting proxy.
- Source classification is a reviewed ingestion step. Ambiguity persists privately
  in quarantine; new resources/modified title never manufacture a new content ID.
- Unified title/summary search covers university/year wording. Actual multi-year
  essay evidence makes a universal single admission_year unsafe. Defer extra common
  university/year fields and separate essay metadata until typed filtering is needed;
  retain raw evidence. No university taxonomy/master now.
- Native content cards/details may open original articles externally. Full article
  bodies are deferred; normal app browsing never scrapes HTML or wraps the website.
- During pre-deployment design, the initial file was revised in place. This is
  superseded by the applied-migration immutability decision below.

## 2026-09-13 — Dedicated deployed backend and evidence policy

LegendStudy uses its own Supabase project, separate from Muselry. The project name,
ref `stlhijzpjfgwwdgunlsd`, region and verified-at-report server version may be
recorded in canonical docs as target identifiers; they are not credentials.
Never store test-user passwords, access/refresh JWTs, service-role or secret keys.
Reconfirm the intended target for future DB operations rather than borrowing any
other application's environment.

Applied migration artifacts are immutable, including historical comments. Future
DB changes must be new migration files; a successful deployment is not permission
to replay or rewrite the initial artifact. Generated fallback notes are contingency
options only and require a reviewed new migration if ever needed.

Validate client-path RLS with actual PostgREST REST requests and real anonymous or
user JWT contexts. SQL Editor SET ROLE is not authoritative client-path evidence
for this project because editor session behavior may differ. Distinguish owner-
reported runtime results, structural policy review and tests directly performed
by an agent; never promote a structural check into unreported behavioral coverage.

## 2026-09-13 — UI/UX and implementation ownership

Claude leads app-wide information architecture, screen hierarchy, interaction flow
and design-system refinement, and reviews Codex UI implementation. Codex remains
the implementation lead for Flutter/data/state/repositories/integration, tests and
builds, including implementation of Claude's specifications. ChatGPT retains
planning/architecture/specification/review/coordination; Manus operations support;
the owner retains final product/scope decisions and default SQL execution.
Day 4-A establishes minimal data states only; no final screen/card design is adopted.

## 2026-09-13 — Approved UI/UX v1.1 product decisions

- Four bottom destinations: Home / Materials / Study / MY. Saved moves under MY.
- Stored personalization requires authentication, including school/grade settings,
  bookmarks/recent views, study history/totals, personal notifications/account settings.
- School search/selection remains guest-accessible; school persistence requires login.
- Guest timer execution may be allowed; durable study history requires authentication.
- Social-login-only: Kakao / Google / Apple / Naver. Facebook, X and email/password
  signup are excluded from v1.
- Free-with-ads + ₩4,900 one-time support purchase removes ads permanently. This is
  neither a subscription nor a core-feature unlock. No interstitial ads in v1;
  protect PDF/timer/login/school flows and important CTAs from ads.
- School settings, NEIS meals and study timer/history are promoted into v1 product
  scope; implementation is staged and their backend is outside Day 5.
- wiki/ui-ux-v1.md is the canonical UI implementation specification, normalized
  from the owner's approved Day 5 directive; see its provenance statement.

## 2026-09-19 — Study analytics, achievement and admissions are three separate layers

Study and Mock Exam are the first data sources of a longer chain, not standalone
features: Study → Subject Study Tracking → Academic Record → Academic Analytics
→ Achievement Engine, and Academic Profile → Target University/Department →
Admissions Engine. The boundaries are binding:

- Study time belongs to learning diagnosis; score change belongs to Academic
  Analytics; admission probability belongs to the Admissions Engine and is
  computed only from 내신, 모의고사 성적, 대학별 반영 규칙, 모집단위, 수능최저,
  과거 입결 and official 전형 data.
- **Study time is never a direct predictor of admission probability.** A
  structure such as "100시간 공부 → 합격확률 +10%" is rejected.
- Correlation between study time and score change is expressed as correlation,
  trend or observed change — never as causation.
- A score gap against a target is not an admission probability.
- LS LAB 논술 evaluation results are never summed onto the same score scale as
  모의고사/내신; each domain stays independent and is combined only as context in
  the Academic Profile.

## 2026-09-19 — Achievements record behaviour and confirmed growth, never prediction

The badge idea returns as an Achievement Engine driven by real learning
behaviour and confirmed growth, not by logins, ads or arbitrary activity.
Behaviour-based and growth-based achievements are modelled separately, and study
volume alone never earns a growth-based achievement.

**Prediction-style badges are forbidden** — nothing of the shape "서울대 합격
가능", "합격 유력" or "상향지원 성공". The Achievement Engine and the Admissions
Engine stay separate systems: an achievement is never an input to an admission
estimate, and an admission estimate is never surfaced as a badge.

Both this and the entry above are roadmap decisions. They do **not** promote the
advanced achievement system or the early-admission prediction service into v1.0;
`product-scope.md` still excludes both. See
[roadmap-academic-analytics.md](roadmap-academic-analytics.md).

## 2026-09-19 — Web and App are different products

The App is not a second skin over the same content. Web keeps search
acquisition, the public archive and AdSense; the App carries the learning
workflow — FIND → VIEW → SOLVE → SCORE → RECORD → ANALYZE → IMPROVE. Every new
feature is designed with its role on four axes stated: user value, app
advantage, retention and monetization.

## 2026-09-19 — Premium sells intelligence, not basic access

Public educational material and the basic in-app viewer are not the centre of
the paywall; free users must be able to search and read well enough to see the
app's value. Paid value is analysis, AI evaluation and longitudinal data
continuity. The basic experience is never degraded to force conversion.

Candidate tiers FREE / BASIC / ADVANCED / MAX supersede the earlier
Free/Basic/Pro sketch as working vocabulary; the Entitlement-layer rule in
`architecture.md` still applies. The ₩4,900 one-time ad-removal purchase and a
premium subscription remain separate product roles.

## 2026-09-19 — Metadata coverage and viewer coverage are separate

Historical metadata may expand far beyond what the in-app viewer serves.
Resources outside viewer coverage fall back to the original LegendStudy source
page, and a primary viewer path never removes that fallback. Storage cost is
therefore not a reason to slow metadata expansion. Any mirrored copy still
depends on the deferred rights decision recorded in `day-9-ingestion.md`, and
the no-bulk-mirroring rule of 2026-09-12 stands until that decision is made.

## 2026-09-19 — AI-heavy features may combine subscription and credits

Features with a real marginal inference cost (LS LAB essay evaluation,
handwritten math Vision, multimodal evaluation) are entitled by a subscription
plus usage credits. MAX is not defined as unlimited AI. Quotas and prices are
set after cost measurement.

## 2026-09-19 — Community is a free retention feature, not a launch blocker

Community stays on the long-term product map as PLANNED, with the role FREE /
RETENTION, and is not the centre of the early paywall. Initial candidates are
학교 급식 자랑 (linked to the Meal feature) and 잡담; 공부 인증, 모의고사 후기 and
학습 팁 are later candidates. Single-user learning value — viewer, Mock Exam,
Academic Record — ships first. Because the users are students, reporting,
blocking, moderation, spam and banned-word handling, prevention of
personal-information exposure, image safety and an operator workflow are
designed together with the posting feature, never afterwards. This does not
promote Community into v1.0; `product-scope.md` still excludes it. See
[roadmap-monetization-and-in-app-learning.md](roadmap-monetization-and-in-app-learning.md).

## 2026-09-20 — In-App Exam learning loop and authority boundaries

Refinement below supersedes only mandatory Viewer ordering and the combined
implementation hold; the following original safety decision is retained.

In-App Exam V1 is FIND → VIEW → START ATTEMPT → SOLVE → AUTOSAVE → SUBMIT →
SERVER SCORE → RESULT → ACADEMIC RECORD. Basic history/Record are required;
deep Analytics and AI subjective scoring remain later/separate. Whole-PDF eager
rendering and client-only authoritative scoring are unacceptable architecture.
Use bounded lazy rendering, atomic answer preservation, continuous elapsed timing
with server reconciliation, one active device/session owner, immutable submitted
answers and pinned scoring provenance. Retakes create new attempts; corrections
must be auditable revisions, never silent current-key reinterpretation.

Design entitlement compatibility now (CHECK → RESERVE → EXECUTE/SCORE → SETTLE;
definitive failure releases/refunds); payment/tier quotas remain separate and
undecided. Rights gate media storage/access; metadata coverage is independent of
Viewer coverage. Existing Study pause and Guest preview remain unchanged.
Detailed requirements and open prerequisites have one owner:
[architecture-in-app-exam.md](architecture-in-app-exam.md). No implementation approval.

## 2026-09-20 — Paper-first / answer-first Exam Engine refinement

Primary mobile value is SOLVE → ANSWER → SUBMIT → SCORE → GRADE → RECORD →
ANALYZE → IMPROVE. Users can select an exam and create an Attempt after solving
on paper without ever opening a Viewer. Viewer is an independent resource-access
convenience layer; its failure cannot block answers/scoring/records. Optional
Tablet Viewer flow remains supported in direction. This supersedes mandatory
FIND → VIEW ordering above, not atomic persistence, revision/recovery, single
execution ownership, idempotency, immutable submissions or pinned server scoring.

Separate rights-gated resource delivery/mirroring from exam identities, validated
answer/scoring/grade data and Academic Record. PDF Storage/mirrors remain HOLD;
engine contracts may advance independently. No new data-use approval is implied.
User Academic History, not PDF collection, is the retention asset: Exam → Score
→ Grade → Subject Performance → Historical Trend → Weakness → Study Strategy.
V1 provides records/basic comparison; advanced/AI strategy remains later.
Monetization centres on repeat scoring, longitudinal records/comparisons and
personalized analysis, not file ownership. Free/basic access remains meaningful;
prices, FREE/BASIC/ADVANCED/MAX entitlements and quotas remain undecided.
[Canonical architecture](architecture-in-app-exam.md) owns separate track gates.

## 2026-09-23 — Owner device corrections and MY Achievement surface

Logout confirmation success returns HOME; failure stays Settings. Save success
returns to the previous edit caller. Photo success requires completed Storage
write and verified refreshed bytes/UI, including first upload, replace and remove.
All five main screen families share the section heading/divider primitive; avoid
heavy nested cards. Settings has one destructive deletion action, no duplicate
heading.

Owner now requests MY access to earned achievements and a compact profile badge.
This promotes the **surface direction**, not the Advanced Achievement Engine or
its catalogue into v1. Existing [Achievement philosophy](#2026-09-19--achievements-record-behaviour-and-confirmed-growth-never-prediction)
and [roadmap §9](roadmap-academic-analytics.md#9-achievement--badge-engine) remain
canonical. No catalogue/model/persistence exists in the current App migrations;
this task records FOUNDATION and exposes no fake awards/collection. Study Level
has no approved taxonomy and remains FUTURE.

## 2026-09-24 — Design System v2 approved scope

Owner selects Claude Palette A (orange/navy/cool neutral); white grouped surfaces
on cool page, no peach title strips, shared typography/components. MY Study CTAs
become navigation rows, preserving Trend→Timer order. Guest MY clearly offers
Login and hides private modules. Settings logout moves below policy/info, directly
above destructive deletion. Materials initial/load-more pages are10; existing
explicit load-more and query semantics stay unchanged. This supersedes the prior
2026-09-23 strip/outlined-MY-CTA/logout-order styling only. Feature/data contracts
remain; no Badge/backend/auth redesign. [Approved mapping](design-system-v2-proposed.md).

## 2026-09-24 — Device follow-up and analytics layer allocation

Owner refines v2: personalized own-nickname Home greeting (safe guest/fallback copy),
no Home wordmark/duplicate brand text; neutral cards with small D-Day orange,
Study blue/navy, Meal green semantic icons. Meal type and school share header,
existing selection unchanged. Notification trailing slot only, no fake bell/count.
Materials initial/load-more5 supersedes10, same query/pagination. Timer seven-day
chart reuses canonical included-time totals/Trend chart: oldest→newest, weekdays,
actualmax and zero bars. Mock subject label is optional-only; validation retained.
MY score is a snapshot with LAB detail CTA; push preserves MY/LAB caller context.

[Three-layer allocation](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24)
is canonical Owner direction. [Research](research-registry.md) is evidence, not
Owner approval: retain future admission bands behind explicit research gate, not
permanent deletion or implementation approval. Existing Achievement philosophy stays.

## 2026-09-24 — Owner device follow-up 2

Keep existing v2/analytics allocation. Compact own/Guest greeting + planned neutral
notification slot; D-Day name/date metadata and primary D-n; study label/value row;
Meal actual trailing school and chronological expanded date chips, no policy change.
Daily seven-slot chart adds actual durations and mean reference; shared included-time
aggregation stays canonical. Canonical scoring setup selects actual exam then its
subject/variant; independent timer practice is explicitly separate. Successful-state
repository-refresh control removed, entry loading/error retry retained. MY comments
only confirmed structured result facts. Materials5/load-more and MY→LAB→Back are
Owner PASS; preserve. New changes require device acceptance, no new admission claim.

## 2026-09-24 — Owner device follow-up 3

Owner confirms icon-derived **#FFA300** as Brand Primary. Earlier #FB8C00 and
peach selected surfaces are superseded; **PEACH UI PROHIBITED BY OWNER**. Keep
white/cool-gray/navy surfaces, small D-Day brand/Study blue/Meal green icons.
Meal expansion has an explicit trailing control; chips represent actual provided
meal dates only, at most three, date+weekday. Existing14/19KST and next7day preview
contracts remain. Expanded-only bounded context is detailed in Home policy.
Daily study mean is annotated beside its neutral dashed line, outside the bars;
“이번 주” is presentation copy for the existing recent7day window, not a new
Monday-based aggregation. Dynamic scale/zero/time inclusion/comments stay.

Mock has two purposes: **Official Past Exam Practice** uses canonical exam,
subject/variant and published verified key; **Free Practice** uses user title,
time and optional manual score. Manual scores are personal practice only, never
verified results or MY/LAB/admissions inputs. No new taxonomy, fake key or invented
official duration. Full key catalogue and analytics stay gaps. Implementation
scope and storage boundary: [Mock contract](day-8-d2-answer-scoring.md#owner-follow-up-3--dual-practice-modes).
Daily Sync Phase1 is explicitly outside this task.

## 2026-09-24 — Final Home and Study visual polish

Owner narrows this pass to Home daily white border/shadow, check-free Meal date
selection, and displayed7day Study total/max plus line-bound mean annotation.
Existing brand/Meal/Study contracts remain; [design](design-system.md#owner-final-ui-polish--2026-09-24)
and [Study](study-v1.md#owner-final-ui-polish--2026-09-24) own details. Future
study/score relationship analysis is descriptive PLANNED work, never automatic
causation; no Mock/LAB/Daily Sync/backend expansion is authorized by this pass.

## 2026-09-24 — Longitudinal learning and admissions data strategy

Owner adopts [Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md)
as HIGH / CANONICAL PRODUCT STRATEGY for Product/Data/Marketing/Business design.
Learning→performance→planning→application→outcome→analytics→guidance is the long-term
loop; preserve event time, academic context and provenance within purpose/retention/
rights boundaries. Existing three-layer UX, Achievement and Official/Free separation
remain. Cohort requires sufficient samples plus Privacy/Statistical review; predictions
remain MODEL/EVIDENCE GATED. Raw individual-data sale is not the default business.
This refines the 2026-09-19 analysis/retention decisions and final Study comparison
direction; it does not implement engines, fix catalogue/thresholds or authorize
new collection, use, sharing, payment, schemas or deployment.

## 2026-09-24 — Global major surfaces with fixed approved depth

Owner extends approved Home white/border/shadow to major groups across Home,
Materials, Learning, LAB, MY and Settings. Border may strengthen; Home shadow must
remain exactly unchanged. Nested items stay flat and inline controls keep existing
interaction. [Design system](design-system.md#global-surface-final-override--2026-09-24)
owns tokens and hierarchy. Study total is primary, daily maximum secondary with
neutral separators; approved mean position and all domain behavior remain fixed.

## 2026-09-25 — Materials direct PDF open is release-critical

The core Materials journey is search → detail → problem PDF → answer/explanation
PDF → immediate reading. Phase A now provides Guest-accessible in-app viewing for
metadata-validated current PDF targets; signed-URL re-resolution and verified
current-file availability are not implemented. The target is
`Content → stable resource identity → safe-open resolver → current target →
in-app viewer`, with original landing/source fallback. Direct source open is the
default copyright boundary; public reachability is not redistribution permission,
so no automatic PDF mirroring/rehosting or Storage copy is authorized.

## 2026-09-25 — Cold-start baseline is a Daily Sync gate

An empty accepted local state must not be interpreted as an empty Production
baseline. Before Phase 2, a reviewed bootstrap/reconciliation strategy must bind
the Production canonical baseline to accepted local/durable state. The complete
sitemap inventory must not be treated as new publication candidates.

## 2026-09-25 — Multi D-Day and role-based Home are planned directions

D-Day may expand from one target to a user-owned event collection with Home
nearest/representative emphasis and future Calendar support. Role-based Home
presets for student, N수생, parent, teacher and academy instructor are
recommendation/presentation settings, not permissions; show/hide and later reorder
are future UX. No schema, role authorization or implementation is approved here.

## 2026-09-25 — Analytics platform direction

`analytics.legendstudy.com` is a HIGH / CANONICAL PLATFORM STRATEGY — PLANNED for
internal operational, learning, score, application/outcome, cohort, data-quality,
metric-registry, privacy/RBAC/audit and research workflows. Aggregate/cohort
analysis is the default; individual raw-data browsing is not. No domain, schema,
pipeline, data collection or admin implementation is authorized by this decision.


## 2026-09-25 — Resolver fixed source and shared coarse quota

Owner B2 Resume refines the existing ephemeral delivery decision: build only
HTTPS legendstudy.com/numeric-id from canonical relations, reject all redirects,
recover provider only from matching persisted unsigned provenance/key. A minimal
resolver-only Postgres quota migration is authorized in repository, not Production.
Use shared resource/global bounds when no trusted Guest actor is established;
no fake per-user enforcement. No signed persistence, PDF mirroring or arbitrary
URL input. Fixed-host DNS/TLS infrastructure residual must be reviewed explicitly;
no unimplemented pinning claim. Cache optional. [Implementation and review gates](day-9-c-resource-detail.md#phase-b2-implementation-candidate--2026-09-25).


## 2026-09-25 — Public resolver activation and accepted MVP cost risk

Following reported Claude B2 acceptance and Owner quota runtime PASS, Owner accepts
Guest gateway invocation/DB-cost DoS as **ACCEPTED MVP OPERATIONAL RISK**. It is not
claimed solved by Postgres quota. Keep global600/min and resource12/min mandatory,
fail-closed; no Redis/Upstash/Cloudflare introduced. Public Guest entrypoint uses
verify_jwt=false with server-only platform credentials. Prepare checked-in wiring
now; deployment and Production calls are separate steps, not executed by this task.
[Current activation contract](day-9-c-resource-detail.md#production-activation-preparation--2026-09-25)
supersedes the candidate's pending runtime/gateway conditions without weakening
canonical identity, Safe Open, no-redirect or ephemeral-target boundaries.


## 2026-09-27 — Exam full-set canonical selection

SOURCE ARCHIVE ≠ APP CATALOG. Prefer one evidence-complete representative per exam;
partial SEO posts remain source/archive evidence with publication HOLD. Preserve
raw titles, historical subjects, source provenance and user references; ambiguity
requires review. Same rule applies to future browse/search/personalization/LAB and
historical ingestion. Archive-only areas remain discoverable direction, no ranking
or schema implementation. [Canonical policy](exam-full-set-canonical-policy.md)
owns full scope and Owner gates; the dated audit does not authorize publication.

## 2026-09-27 — Materials source rule and Essay LAB first

Owner's original grade full-set source collections define the exam catalog;
registry/classifier is QA support. Preserve partial sources, suppress duplicate
normal exposure, and do not build compatibility frameworks for pre-launch test
references. Essay targets2020+ minimum five years, with publication/admission
years separate and generic verified PDFs accessible. After Materials device PASS:
Essay LAB → internal-grade → mock-score → admissions. Shared university/field/track
canonical data precedes onboarding extensions; three free feedback experiences,
official-vs-AI provenance, minimal personal-data collection and later B2B remain
product directions. [Full handoff](materials-closeout-essay-lab-handoff.md).


## 2026-09-27 — Platform university identity and minimal Essay exam keys

Owner/ChatGPT schema review approves three canonical tables;
[foundation and application gate](essay-lab-data-foundation.md) own implementation status.
`public.universities` is the LegendStudy platform master shared by Onboarding, MY,
LAB, 모집요강, 입결, School and Analytics, not an Essay-only master.
Essay identity uses UUID PK + UNIQUE(university_id, admission_year, exam_key).
Campus/track/field/session are context metadata until real Pilot evidence justifies
stronger constraints. Existing source_locator text can cite page/section/question;
no Question entity now. Approval permits migration preparation, not Production apply
or Pilot seed. Existing resources, multi-role mappings and provenance are preserved.


## 2026-09-28 — Essay official original source and delivery separation

University admission-office postings/archives are official essay canonical sources.
App/LAB must show university attribution and verified original links; LegendStudy
blog/delivery URLs do not substitute for official provenance. Reuse existing
exam/mapping official_source_url fields; no signed URL as canonical source.
Attribution is not rights clearance; review before full public expansion.
[Canonical policy](essay-lab-data-foundation.md#official-source-policy--owner-decision-2026-09-28).


## 2026-09-28 — Essay learner-facing Korean and calibrated explanations

Explain achievement before improvement, reasons before scores. Ground criticism
in official criteria; consolidate the same root issue and prioritize concrete next
actions. Friendly concise Korean, no raw English/AI/internal status jargon to students;
technical keys stay stable. Uncertain findings remain qualified.
[Canonical details](essay-lab-hanyang-2024-benchmark.md#student-facing-language-and-evaluation-philosophy--canonical-owner-policy).

## 2026-09-28 — Student revision first; optional AI rewrite example

Students should first revise their own answer after diagnosis. An optional
“첨삭을 반영한 예시 답안” preserves their stance and wording while applying only
confirmed improvements. Its provenance is ai_generated, never university official
or model_answer. Keep official examples distinct; no compulsory early reveal.
[Pilot and private-body boundary](essay-lab-rewrite-pilot-v1.md). No UI/DB approval.

## 2026-09-28 — Essay learning cycle and student-preserving assistance

Owner confirms one credit represents first evaluation plus the first same-question revision
evaluation in a learning cycle, not one AI call. Keep entitlement policy/version/ledger separate
from attempts; no attempt-number pricing constraints. Primary action is direct student revision;
optional on-demand AI example stays collapsed, recommended after second evaluation but not locked.
Students retain their unstated judgments: do not add stance/conclusion; minimally edit only
confirmed problems. Per-criterion integer1–5 levels are educational fulfillment signals, separate
from official nullable weights. Overall sentence/no overall star is the review recommendation.
[Product v1](essay-lab-product-v1.md), [architecture](student-analytics-data-architecture.md).
Design only: no Production apply/UI/payment/AI run authorization from this record.

## 2026-09-28 — History-first Student Analytics

Retain immutable submitted answers, versioned judgments/dimensions, explicit issue observations,
meaningful stage actions, provider attempts and credit movements. Growth/current-strength views
derive from those facts. Do not overwrite issue history with current status, or conflate model
changes with student growth. This does not mean permanent click/autosave retention. Separate
learning/behavior/operations/financial retention; preserve correction evidence without rewriting
original judgment. [Final19-table review](essay-lab-final-schema-review.md); Production gate closed.


## 2026-09-29 — Essay criterion-led scaffolding

[Product contract](essay-lab-product-v1.md) is canonical: prioritize official criteria, normally1–3
core tasks and0–5 grounded sentence observations; review previous tasks before selecting the next.
Preserve student stance, use smaller guidance when unresolved, and derive progression from history.
Never conceal necessary feedback to drive payment. Own-answer quotes and official evidence have
distinct provenance. v1.2/Pilots stay frozen;1.3-review.1 and minimal persistence are review only.

## 2026-09-29 — Learning, Decision and Outcome History

Owner reaffirms the existing [canonical long-term data strategy](longitudinal-learning-admissions-data-strategy.md#learning-decision-and-outcome-history--owner-clarification-2026-09-29).
Preserve meaningful historical facts under one student identity; derive current views/analytics.
Target University and actual Application are separate. Application Result History preserves
initial/waitlist/supplementary/final outcomes instead of overwriting one result. Collect facts
progressively with immediate student value. B2C/B2B share models; membership and individual vs
aggregate permissions remain separate. Evidence-poor predictions stay UNKNOWN. The strategy's
seven review questions apply before future Student/LAB/Admissions/B2B/admin design.
Documentation only: no schema, data collection, UI, AI run or Production authorization.

## 2026-09-29 — Store launch and separate Analytics subscription / Essay credits

Owner adopts [2026–2027 canonical roadmap](roadmap-monetization-and-in-app-learning.md#20262027-roadmap-and-monetization--owner-decision-2026-09-29) as the single calendar/commercial strategy source.
Mid-October App+Essay Store launch target → end-October Essay stabilization → November
Mock/CSAT BETA → 2027 internal-grade/Admissions and Subscription direction supersedes the
prior internal-grade-before-Mock ordering. G1 is deployed; L1/worker/E2E/IAP/Store remain gates.
Essay prices are fixed; Analytics subscription and Essay credits are separate products,
not unlimited Essay. Subscription pricing/periods/benefits and Beta free scope remain undecided.
Learning/Decision/Outcome evidence and privacy gates remain. Strategy only, no implementation.

Owner adopts [School History & Coupon/Voucher design](school-history-and-coupon-design-v1.md)
(2026-09-29): high-school info becomes longitudinal **School History + current projection**
(not overwrite), change policy **2 free corrections + 14-day cooldown** (transfers supported,
server-authoritative); Essay Credit **Coupon/Voucher is Launch P0** as a distribution channel
into the existing G1 ledger (`credit_grants.origin` promotion/b2b_program, no separate coupon
balance), with server-side Campaign/Voucher/Redemption policy, per-user/total/budget limits, no
unlimited master code; **Academic School ≠ verified B2B Organization Membership** (school
selection alone grants no B2B eligibility and no access to student essays). B2B organization/
membership/batch = P1. Design only, no implementation.

## 2026-10-23 — 공통 UX·대학별 평가·문항별 근거 기반 전체 서비스

Owner 최종 지시: 일반계정 공개를 기본으로11대학512문항을 전수분류/입력검증하고 검증된 대학·유형·학년도 묶음을 활성화한다. 기존28프로필/423상속/89보완·엔진·ID·정책·기록 보존. 대표E2E와 전수입력검증을 구분하며 개별SQL/E2E반복을 기본절차로 삼지 않는다. [기존 프로필 전략을 구체화한 범위·분류·보존 검토](essay-batch-service-20261023.md).

## 2026-10-24 — 대학 단위 완성과 오류 격리

기존 [전체 문항 연결 결정](essay-batch-service-20261023.md#2026-10-24--대학-단위-실행-및-오류-일괄-관리)을 대학 단위로 실행한다. 하루1대학 목표(가능하면2), 전체문항 전수입력검증과 대표E2E 재사용, 정상묶음 공개 및 보류별도 기록. 보류가 있으면 대학 전체 완료 아님. 오류A공통은 즉시, B대학/유형·C개별은 정상작업과 분리. 개별오류30분 목표 후 명세와 후속방법을 남기되 Credit/Ledger/인증/개인정보/공통Worker는 예외. 기존정책·ID·기록 보존과 Owner 직접SQL 원칙 유지.

## 2026-10-25 — WEB MY 표시와공유 범위

Owner WEB MY 지시는 [기존 MY 공통 기반](my-shared-foundation.md)과 [학습/지원/결과 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 재사용한다. 사용자 명칭은 크레딧으로 통일하되 내부 API/정산 단위를 바꾸지 않는다. 미입력 프로필은 공란, 목표 대학·학과는 한 번에 저장, 지원기록은 기존 이력 계약 유지. 공유는 대표주소와 개인식별정보·답안·내부근거를 제외한 실제 성장 PNG만 제공한다. 일반 사용자 해설/예시 공개 UI를 제거하며 평가 엔진/원본 자료는 보존한다. [Owner 원문](https://github.com/LC3808/legendstudy-docs/blob/codex/web-app-release-20261024/90_HISTORY/2026-10-25-web-my-owner-directive.md), [구현·검증](phase3-service-20261022.md#2026-10-25-web-my-재설계-운영-반영).

### 2026-10-25 — 성장 그래프 후속 표시 결정

위 WEB MY 결정의 후속 Owner 지시: 성장 변화는 최초·최근 세로 막대로 표시하고 평가 항목1/2 대신 저장된 평가 기준의 정확한 의미를 담은 명칭을 사용한다. 짧은 원래 제목은 보존하고 긴 평가 질문은 근거 있는 표시 별칭으로만 요약한다. 문항별 기준을 획일적인 역량명으로 바꾸거나 원본 평가/점수를 수정하지 않는다. 화면·PNG 동일 규칙.

## 2026-10-25 — 통합 WEB 마무리 범위

기존 회차1Credit·원래 문항 집합 무료재첨삭 정책을 유지한다. MY 목표는 프로필 내부 통합, 공유는 레이아웃을 밀지 않는 패널. 관리자 auth계정/profile·legacy문항/회차·게시플래그/실행승인·TEST/LIVE 지표를 구분한다. 기존 [PHASE3 결정](phase3-service-20261022.md#2026-10-25-web-통합-배포-및-집계-정정)에 연결하며 APP 코드·신규 대학·엔진·결제 변경은 범위 밖. [Owner 통합 지시와 실제 증거](https://github.com/LC3808/legendstudy-lab/blob/codex/web-app-release-20261024/docs/integrated-release-20261025/README.md).

## 2026-10-25 — 사용자 Credit 내역과 내부 정산 분리

Owner확정: APP/WEB 사용자내역에서reserve/release숨김,consume은동일decision별합산한논술첨삭사용으로표시. 구매·지급·실제환불/회수보존,예약반영가용잔액및관리자원장불변. DB계약변경없음. 앱수정완료전빌드/업데이트하지않음. [구현·보존검토](payment-app-foundation.md#2026-10-25-사용자-크레딧-내역-표시-정책).

## 2026-10-25 — APP MY 재설계 철회

Owner가 새 iPhone 앱을 확인한 뒤 MY를 기존 UI/UX로 되돌리도록 지시. APP의 프로필·목표·학습·LAB 카드 구성은 이전 화면 유지. 이는 위 WEB MY 결정의 철회가 아니라 APP 화면에 대한 후속 결정이다. 사용자 Credit 내역 중복 표시 개선과 논술 회차·결과·성장 기능은 유지한다. [복원 범위와 검증](app-release-20261025.md).

## 2026-10-25 — APP 복원 후 1-A 시험 회차 우선

Owner지정중앙·성균·경희의2022이후준비된인문/언어·수리·혼합형전체시험을대상으로한다. APP MY복원후UI/빌드/스토어중단. 첨삭결과UI원인은미확정으로기록하고3대학연결후Native기준일괄개선. 전체문항공식근거/입력을연결한회차를묶음공개하고부분문항성공을전체시험완료로보지않는다. 기존회차1/무료0Credit·기간·횟수·ID·History보존,Production SQL Owner직접실행. [실행명세](essay-group-1a-20261025.md).


### 2026-10-25 — 1-A 작업의 Production SQL 직접 실행 승인

Owner 추가 지시로 이번 1-A 작업은 Codex가 사전검사·격리검증·복구경로를 확보한 후 Production SQL까지 직접 실행한다. 기존 Owner 직접 적용 원칙의 이번 범위 예외이며, ID·Credit·Ledger·History·권한 보존과 APP UI/스토어 중단은 유지. [범위·실행 증거](essay-group-1a-20261025.md).

### 2026-10-25 — Owner 복귀: SQL 개별 승인 복원

위 포괄 SQL 실행 예외는 후속 “SQL은 오너 승인 하에 진행” 지시로 종료. 이번 중단요청 복구 SQL과 같은요청 재개만 추가 승인받아 실행. 예약해제 rollback은 승인대상 밖. 기존1-A전체회차·1/0Credit·APP중단 결정은 유지. [실행과미완료](essay-group-1a-20261025.md).

### 2026-10-25 — Manus 자료의 1-A 구조 대조 활용

[기존1-A 회차범위 및 SQL개별승인](essay-group-1a-20261025.md) 유지. Owner 조사자료는 대학/학년도/회차/대·소문항/실제답안단위/입력방식 대조용이며 채점근거는 공식자료만 사용한다. 조사와Registry 불일치는 자동덮어쓰기·새ID생성 없이 공식자료로 확인한다. 2027안내·모의를 과거 실제기출에 소급하지 않는다. 회차최초1Credit·기존무료0·미제출문항후속신규회차1Credit·History보존.


## 2026-10-25 — 1-A 전체 회차 연결 우선 및 승인된 중앙 묶음

[1-A SQL 승인 원칙](#2026-10-25--owner-복귀-sql-개별-승인-복원)을 유지한다. Owner는 중앙·성균·경희의 준비된2022+ 전체 시험 회차 공개를 유일한 성과 단위로 재확인했다. 문항별 가상답안/Provider 반복/표현 완성도 검수는 중단한다. 기존 공식 근거·전체 답안단위·ID·PDF·Worker입력·Credit/History 계약을 자동 검사하고 정상 회차를 묶음 연결한다. 문항 수 차이는 부모/소문항/답안단위부터 구분한다. APP UI/빌드 중단, 기존 버전 미지원은 호환성 GAP으로 기록한다. 권한 정책 변경은 별도 승인 대상이며 Owner가 인문3회차 및 중앙인문10회차의 정확 문제PDF SELECT 포함 SQL을 각각 승인했다. 삭제·기존 기록 변경·타 대학 확대 승인이 아니다.

## 2026-10-25 — 대학 카드 공개정책과 실행승인 분리

Owner는대학카드의활성표시를기존서버공개정책으로결정하고,평가Worker초기화에의존하지않도록지시했다. 확인중/공개/미공개/조회실패를구분하고실패를미제공으로표시하지않는다. 실제제출의기존권한·실행승인·Credit/History계약은보존한다. 앞선1-A전체회차공개결정을유지하며새시험공개권한추가가아니다. [구현·운영검증](essay-group-1a-20261025.md#2026-10-25-대학-카드-공개-상태-안정화).

## 2026-10-25 — 전체 대학 STANDBY와 Owner QA 분리

기존 회차 연결 결정의 최신 우선 정책: 개발팀은 전체 문항·PDF·입력/저장·공식 근거·Registry·기존 Worker/승인 연결을 완료하고 STANDBY / OWNER QA PENDING으로 보고한다. 실제 평가 호출·가상답안·문항별 품질 검수를 준비 조건에서 제외한다. Owner가 임의 검수하고 지정한 오류만 최소 수정한다. 기존 서버 승인/유료 공개/Credit/History 보존, 강제버튼활성화 금지. 모든 대학/유형 공통이며 실행 순서는 중앙인문→Owner확인→중앙경영경제→경희→성균이다. [공통 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책).

## 2026-10-25 — 경희·성균 연속 STANDBY SQL 사전 승인

기존 [전체 대학 STANDBY 정책](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책)의 실행 순서를 경희인문·체육→경희사회→성균언어로 지정한다. Owner는 해당 범위의 기존자료·필요신규Registry·revision·Worker·정확PDF 접근·공개승인 SQL을 사전검사/적용/사후검사 조건으로 Codex 직접 실행 승인했다. 단계별 재승인 대기 없이 정상회차를 연결한다. 학생데이터삭제·Credit/Ledger/결제변경·광범위권한변경·기존정상실행정책변경은 제외. Provider호출/가상답안/APP빌드0 원칙, 실제평가는Owner QA. [실제 반영·보류](essay-group-1a-20261025.md#경희-신규10회차-운영-연결).

- 2026-10-25 Owner 최종범위: 기존 STANDBY 원칙으로 성균PDF·한양인문/상경만 처리 후 종료. 한양 Registry/공식근거/runtime/정확PDF권한/공개 SQL 제한승인; 학생ID·Credit·History 변경불가. Provider와APP빌드0, 상경수리미연결은보류. [적용결과](essay-group-1a-20261025.md#2026-10-25-최종-범위--성균-pdf-수정한양-standby).


## 2026-10-26 — 상경 정책 분리와 고려 업데이트

Owner는 인문사회/상경/자연의예의 논리적 정책 경계를 구분하되 기존 Essay·Math와 공통 회차1Credit·History를 유지하도록 지시했다. 기존 혼합형 계약 폐기·대규모 재설계는 금지한다. 고려 신규 자료 연결 및 한양·서강 대표 실전검증만 진행하며, 사진 내용은 Owner만 확인한다. 운영 SQL은 기존 승인 범위 밖이면 별도 승인받는다. 진행 직후 UI는 오후 Owner 지시 전 보존한다. [실행 상태·기존 정책 연결](commerce-korea-20261026.md).


## 2026-10-26 — 첨삭 시험 재진입 선택

기존 완료 결과 자동 이동 원칙은 새 요청 완료 시에만 적용한다. 시험 재선택 시 exact exam ID의 기록 확인/독립 새 작성 모달을 제공한다. 새 작성1Credit과 기존 결과의 무료 재작성0Credit은 분리하며 미제출 초안·평가·성장 이력을 보존한다. [구현·보존·복구](essay-web-studio-ui-20261026.md#2026-10-26--기존-첨삭-시험-재진입과-독립-초안).

## 2026-10-26 — 전체 대학 브랜드 색상 근거 구분

기존 화이트 히어로 결정을 42개 Catalog에 확장한다. A공식HEX/B공식RGB환산만 공식 포인트로 적용, C Pantone/D색명/E미확인은 임시 UI 색상과 분리한다. 조사표 충돌 시 공식 원문 우선이며 Manus도 원문 대조한다. 공통 컴포넌트+설정만으로 확장하고 학생 데이터·서비스 승인·APP을 변경하지 않는다. [구현·근거](university-brand-hero-20261026.md).

## 2026-10-26 — WEB 답안 사진 입력 단일화

PC·모바일·태블릿 WEB은 ‘답안 이미지 첨부’만 제공한다. 별도 촬영 버튼은 제거하며 APP의 기존 Native 촬영·첨부는 유지한다. 기존 사진·순서·추출·학생 확인 계약 불변. [기존 입력 UI 결정의 후속 적용](essay-web-studio-ui-20261026.md).

## 2026-10-26 — 논술 성장과 기록의 두 경험

Owner 확정: 개인 LAB은 성장 우선, History는 목록+동일 상세 결과. 기존 결과 URL/ID와 재작성 계약 유지. 비교 가능한 저장 결과만 사용하고 대학 간 평가 단계 합산·가짜 성장 지표 금지. [구현·검증](essay-growth-history-ui-20261026.md).

### 2026-10-27 — 성장 그래프 공통 표시 정책
Owner 최신 지시로 기존 최초·최신 비교를 확장: 1회 막대, 2회 비교 막대, 3회 이상 기본요약+펼침 전체 이력 꺾은선. 같은 기준/척도만 비교, 누락 보간 금지, 하락 보존. 기준ID별 짧은 표시명은 원문과 분리하고 불명확한 명명은 검수대기. 이용 정책 변경 없음. [기존 정책 연계·운영 범위](essay-growth-history-ui-20261026.md#2026-10-27--공통-성장-그래프-이력표시명).

### 2026-10-27 — 자연계열 등록 목록과 실행 승인 분리
등록된 자연계열 시험은 학년도·계열 선택에 노출한다. AI 첨삭은 기존 보류, PDF는 기존 공개 권한 유지. 미등록 시험 생성·버튼만 강제 활성화 금지. [공통 구현·근거](essay-all-university-standby-20261026.md#2026-10-27--자연계열-시험-목록과-첨삭-공개-분리).


## 2026-10-29 — APP 결과·기록·성장 통합 정리

[기존 성장/학습 회차 정책](essay-growth-history-ui-20261026.md)을 유지하며 APP 성장 목록은 무한 스크롤 대신 시험5개 이전/다음 페이지, 페이지별 최신1개 기본 펼침·동시에1개만 펼침으로 변경한다. 전체조회 미확인 시 전체페이지 수를 추정하지 않는다. 결과 펼침 카드는 원문1회 표시, 시험명 중복 제거, 개별 결과 성장공유 제거/PDF 유지. 기록의 유료후속도 학습 회차 기준 재첨삭 필터. Native UI·Credit/History/평가기준 불변. [범위·구현·검증](app-lab-refinement-20261029.md).

### 2026-10-29 — APP LAB 디자인 보완

위 결과/기록/성장 정책을 유지하고 Owner 시안은 시각 참고로만 사용한다. LAB 카드radius14·화이트/연한border·네이비 선택면·#FFAC14 강조. 장문은 왼쪽, 휴대폰 큰 글씨는 세로 그래프, 충분한 가용폭에서만2열. 평가 수치/문구를 시안으로 대체하지 않으며 전역 테마·계약은 불변. [구현 및 시안과의 차이](app-lab-refinement-20261029.md#owner-디자인-addendum--2026-10-29).

## 2026-10-30 — 빌드28 후속: 성장 페이지 펼침 정책 보완

Owner 10/29 실기기 후속 지시로 위 10/29의 “페이지별 최신1개 기본 펼침”을 대체한다. 최초1페이지 진입만 최신1개 펼침, 모든 이전/다음 전환은 전체 접힘, 이후 사용자가 직접 펼친 카드만 펼침. 5개페이지·학습회차·동일기준 비교는 유지. 종합단계는 실제 저장 계약이 있을 때만 표시하며 항목평균으로 만들지 않는다. [원인·검증·기존 정책 연결](app-device-followup-20261030.md).
