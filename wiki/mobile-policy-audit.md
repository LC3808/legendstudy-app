# Owner device policy audit — 2026-09-23

Scope: current App code/tests, canonical Wiki and explicit Owner reports. Historical
logs remain historical. Production was not queried or modified by this task.
PASS below means the stated local contract, not blanket Production acceptance.
Starting baseline fa5ba92 is historical, not a permanent definition of HEAD.

| POLICY | WIKI STATUS | CODE EVIDENCE | TEST EVIDENCE | ACTUAL STATUS | ACTION |
|---|---|---|---|---|---|
| Photo availability after Owner Storage apply | database/current-status still required default-off App define | lib/core/config/app_config.dart; features/profile/avatar.dart | owner_final_ux_test.dart; avatar_test.dart | GAP_FIXED | Remove stale App switch; retain session/owner/path checks; device upload E2E open |
| New login HOME, explicit safe return | auth-recovery claimed direct Home but generic pop also returned MY | auth/presentation/auth_page.dart; app/router.dart; protected callers extra=true | owner_final_ux_test.dart four provider-event cases, invalid return, restore; core_ux_test.dart protected flow | GAP_FIXED | Single signedIn handler goes Home unless trusted stack return requested; no provider SDK change |
| Meal next available D..D+6 | day-10 documented today/tomorrow only; Owner reconfirmed omitted seven-day requirement | school/domain/school.dart nextAvailableHomeMeals; school_providers.dart nextHomeMealsProvider | meal_fallback_test.dart offsets0/1/2/3/6, seven misses, breakfast-only, error, provider boundary | GAP_FIXED | Add bounded traversal; do not misreport old Wiki as already proving seven-day implementation |
| Study chart vertical, proportional, zero, oldest→newest | study-v1 second refinement had bars but list presentation | study/trends/study_bar_chart.dart | owner_final_ux_test.dart proportions/zero/date order; mobile_ia_render_test.dart | GAP_FIXED | Vertical bars, actual-maximum axis and one-screen slots (second Owner review supersedes prior minimum60min/scroll policy) |
| Home breakfast hidden /14/19KST /full expanded meals | day-10 canonical confirmed | school/domain/school.dart; presentation/home_meal_card.dart | meal_owner_policy_test.dart; meal_fallback_test.dart selected Monday detail | PASS | Keep policy; raw next-date breakfast remains detail-only |
| Meal cache/resume/date reevaluation | day-10 implemented | home_meal_card.dart lifecycle/boundary invalidation; school_providers.dart raw queries | meal_owner_policy_test.dart; meal_fallback_test.dart clock invalidation | PASS | New selection invalidated with raw providers; no persisted selection cache |
| Auth provider flows and shared identity | current-status Owner App/LAB all four PASS; Apple/Google shared PASS | auth/auth_email.dart, auth_oauth.dart, native_auth.dart (feature directory); supabase_providers.dart | native_auth_test.dart; auth_oauth_test.dart; kakao_oauth_scope_test.dart | PASS | Preserve Owner evidence; Kakao shared identity NOT VERIFIED; no new device login claim |
| Session restore / owner isolation | Owner Profile restore PASS | core/supabase/supabase_providers.dart; personal/personal_providers.dart; profile/avatar.dart | auth_lifecycle_sdk_test.dart; auth_lifecycle_ui_test.dart; avatar_test.dart | PASS | New login routing ignores initialSession; captured owner prevents late photo cross-account paint |
| Recovery security foundation | code ready; App mailbox matrix pending | auth/auth_recovery.dart; auth presentation recovery routes | auth_recovery_test.dart | GAP_OPEN | Owner recovery expired/reused/cold/warm real-mail acceptance remains; no rewrite |
| Home compact / MY profile / five tabs | first and second IA implemented | home/presentation/home_page.dart; profile/presentation/profile_page.dart; app/router.dart | day5_shell_test.dart; mobile_ia_render_test.dart; owner_final_ux_test.dart | PASS | Keep five tabs; MY Trend first, simple score copy, no email/LAB duplicate |
| School + optional grade / sparse save | implemented, Owner values PASS | profile/presentation/school_page.dart; personal/data/supabase_personal_repositories.dart | my_profile_state_test.dart; day7_profile_test.dart | PASS | No schema/taxonomy/metadata overwrite changes |
| Timer /Mock separation /inclusion | implemented, Owner migration applied | study/application/study_controller.dart; domain/study_models.dart; trends/study_trends.dart | study_core_test.dart; study_ui_test.dart; study_trends_test.dart | PASS | Same union aggregation; excluded Mock raw record preserved |
| Materials guest access / bookmark return | implemented | personal/presentation/inline_bookmark_button.dart; content/presentation/content_detail_page.dart | materials_delivery_journey_test.dart; core_ux_test.dart; day9_c2_personal_test.dart | PASS | Protected login explicitly returns; no automatic save |
| Settings confirmation and destructive flow | implemented | profile/presentation/settings_page.dart; account deletion existing flow | account_ux_test.dart; mobile_ia_render_test.dart | PASS | Profile edit/basic info/study settings; outlined logout before policy/info then deletion |
| LAB independent services | current second-refinement native score + Essay entry | lab/lab_page.dart; lab/score_summary.dart; shared/widgets/legendstudy_lab_entry.dart | day5_shell_test.dart; mobile_ia_render_test.dart; score_summary_test.dart | PASS | Three primary entries; internal grades honestly unavailable, no fake analysis/URL |
| Profile privacy | nickname/avatar own; Community future | profile/avatar.dart; personal model/repository; existing private Storage migration | avatar_test.dart; day7_profile_test.dart | PASS | No social photo import; no public profiles SELECT or Storage policy relaxation |
| Badge /Achievement | roadmap FUTURE, not completed | no Achievement subsystem; ContentTypeBadge is material type only | no Achievement acceptance test, appropriately absent | PASS | Keep future; do not confuse content badges with achievements |
| Notifications | local Mock completion implemented; remote push planned | study/focus/study_focus_controller.dart; study/notifications/mock_notification.dart and native notification bridge | study_focus_test.dart | PASS | Preserve local completion; remote materials/exam push remains planned, not release-verified |
| Account deletion production | foundation, OPEN | supabase/functions/delete-account handler + avatar-cleanup candidate | handler_test.ts; avatar-cleanup_test.ts; account_ux_test.dart | GAP_OPEN | Separate Owner deploy/config/E2E, Apple revoke and retention review; helper existence is not deployed |
| Policy /Store acceptance | OPEN | core/links/service_links.dart; auth support links/settings | lab_entry_test.dart; account_ux_test.dart | GAP_OPEN | Owner final URL/content and Store review; no fabricated URL/ready claim |
| Deep links / callback isolation | foundation and Owner login checkpoint | app/router.dart; AndroidManifest.xml; Info.plist; auth callback handlers | auth_oauth_test.dart; auth_recovery_test.dart; day5_shell_test.dart | PASS | Preserve native files; explicit return never consumes arbitrary URI |
| Older readiness and avatar documentation | auth-recovery says social unverified; ui-ux default avatar/external-only LAB; database pending apply | current code + Owner explicit apply/login report supersede these current claims | current 657-test suite; Owner evidence separately attributed | STALE_WIKI | Correct canonical current claims, retain dated history; server deletion gate still open |
| Community safe launch | Future; moderation mentioned but release coupling incomplete | no Community backend | no backend tests; no live placeholder UI | GAP_OPEN | Canonical platform boundary now requires block/report/filter/admin/support/terms together; no tables created |

Counts: PASS 14; GAP_FIXED 4; GAP_OPEN 4; STALE_WIKI 1.
Paths in code/test cells are relative to lib/ or test/ unless explicitly supabase/.
Future features are not promoted to implemented because their contracts exist.

## Verification and Owner handoff

Flutter3.47.5/Dart3.13.4: analyze PASS; full657 PASS/1 existing skip;
iOS simulator/debug Android builds PASS. Mobile IA40 render cases cover360×640 and
428×926 at1×/2×, including chart geometry, MY actions, Settings ordering and LAB.
Selected actual PNGs visually inspected. Existing avatar/delete Deno11 PASS.
Secret/source-readiness/ignore and diff audits recorded in current task log.
Build warnings about future AGP/Kotlin support and CocoaPods migration are existing
maintenance items; no unrequested toolchain change made.

Owner sequence: login→HOME; MY photo select→replace→remove (also Settings, restart,
A/Guest/B ownership); Trends daily/weekly/monthly, zero/time order/proportions;
MY score copy; LAB three entries; Settings logout cancel/confirm; next meal date.
Use natural records; no fake Production data. MOBILE_UI_OWNER_E2E NOT VERIFIED.
Storage SQL PASS is Owner-reported; new App upload/device E2E is not inferred.


## Second final Owner device audit — current supplement

The first audit above records earlier gaps. These rows supersede presentation
contracts subsequently changed by Owner; earlier logs are not current requirements.

| POLICY | WIKI STATUS | CODE EVIDENCE | TEST EVIDENCE | ACTUAL STATUS | ACTION |
|---|---|---|---|---|---|
| Profile success back /failure stay | new Owner convention | profile_edit_page.dart save, avatar operation callbacks | device_second_corrections_test.dart delayed save, failure, photo partial failure/retry | GAP_FIXED | One pop only after success; account change resets transient editor flags |
| School success back /search placement | prior separate immediate school save + grade button | school_page.dart draft/results ordering, grade_page.dart beforeSave/onSaved | device_second_corrections_test.dart success/failure/partial failure/layout; day7_school_test.dart guest | GAP_FIXED | Results directly under input; Save awaits both existing APIs, optional grade; retry after partial failure |
| Chart7day/dynamic max/no horizontal scroll | prior minimum60min and scrolling superseded by Owner | study_trends.dart dates/labels; study_bar_chart.dart | device_second_corrections_test.dart ratios/zero/labels; mobile_ia_render_test.dart viewport geometry | PASS | Current actual max;7 weekday slots,8 compact weeks,6 months; deterministic comments unchanged |
| LAB details independent | old combined detail remained despite separated Hub | app/router.dart; lab/score_summary.dart | device_second_corrections_test.dart both Hub→details and old /lab/scores | GAP_FIXED | Native unsupported internal-grade detail separate, no fake backend; Mock-only old route |
| MY grouping and Settings hierarchy | Owner refined final display | profile_page.dart; settings_page.dart | mobile_ia_render_test.dart outlined CTAs/order/heading absent; account_ux_test.dart confirm | PASS | Compact dividers, no account-management heading |
| Meal7day/time/expanded | previously localPASS/device pending | unchanged school policy/provider/Home widget | meal_fallback_test.dart; meal_owner_policy_test.dart; Owner iPhone report | PASS | MEAL_OWNER_E2E PASS; no new meal policy change |

Existing4 open gates remain: App recovery mailbox/device matrix, account deletion
Production lifecycle, policy/Store acceptance, Community safe backend release.
No new DB/Storage migration or Owner apply required. Photo Storage remains Owner
applied/SQL-verified; new edit UI/photo device acceptance is not inferred.

Final automated evidence:655 Flutter PASS/1 existing skip; analyze; iOS simulator,
Android debug;47 render cases at360×640/428×926 and1×/2×; Deno11; secret/ignore/source
readiness/diff checks. Selected daily/weekly/monthly and MY PNGs inspected.

Owner order: login→Home → MY sections → Profile nickname/photo Save→back → Basic
school search/result/selection/optional grade Save→back → Trend-first CTA → daily7
weekday slots, weekly/monthly compact labels and proportional zero-safe bars → MY
score copy → LAB internal-grade-only/Mock-only/Essay → Settings and logout cancel/
confirm → existing Meal sanity. MOBILE_UI_OWNER_E2E NOT VERIFIED.

## Owner fixes + handoff recovery — after bcb15dd

This task's focused conflict audit (counts apply to these six rows only):

| POLICY | WIKI STATUS | CODE EVIDENCE | TEST EVIDENCE | OWNER LATEST DECISION / ACTUAL STATUS | ACTION |
|---|---|---|---|---|---|
| Achievement surface | Advanced Engine FUTURE; roadmap examples not catalogue | no award model/repository/table; ContentTypeBadge unrelated | handoff checker finds decisions/roadmap/scope; no invented award test | MY access direction approved; GAP_OPEN for real collection | FOUNDATION in existing roadmap §9; no menu/award/Level/migration; catalogue needs separate Owner decision |
| Meal | Seven-date/time/expanded policy, Owner PASS | unchanged school policy/provider/Home card | meal_owner_policy_test.dart, meal_fallback_test.dart | PASS | Preserve Owner E2E and code |
| Profile first-write success | private Storage Owner applied, App acceptance pending | avatar.dart previously invalidated without awaiting reload | owner_handoff_fixes_test.dart reproduces premature success; delayed/mismatched read; avatar_test.dart replace/delete/private query | GAP_FIXED locally; device NOT VERIFIED | Await fresh read, byte match and frame; cacheNonce via current SDK; no RLS change or speculative INSERT diagnosis |
| Logout HOME | confirmation existed, Settings stayed | settings_page.dart captures router before signedOut can dispose button | owner_handoff_fixes_test.dart cancel/failure/disposal-before-completion | GAP_FIXED | HOME after successful action, owner guard preserved |
| Global section hierarchy / single deletion action | previous subtle lines insufficient per Owner | shared SectionHeader/SectionDivider; five screen families; one deletion action | mobile_ia_render_test.dart expanded Home/Materials/Timer matrix plus existing MY/Settings | GAP_FIXED | Shared themed surface/rule/header; no layout policy changes |
| Wiki restore | index directory weak routing; current105206B mixes history | AGENTS/index/current + historical evidence; no app behavior dependency | tool/check_wiki_handoff.py, original175 paragraphs all found after normalized link comparison | STALE_WIKI corrected | Current/History/Feature roles, four route self-tests, five broken old anchors repaired |

Counts: PASS1; GAP_FIXED3; GAP_OPEN1 (Achievement catalogue/implementation future);
STALE_WIKI1 corrected. The earlier four release gates remain open; no claim that
this focused audit exhausts all release gates. Production was not queried/mutated.

Handoff self-test: “배지함” routes to decisions → roadmap §9 → scope; “급식 다음
제공일” routes NEIS → Home bounded fallback; “카카오 로그인” routes Auth acceptance
→ recovery/deletion/decisions; “공부 추이” routes Study v1/UI/storage and current
Owner overrides. All required files and anchors are checked by the read-only tool.

Historical preservation: all175 original current-status paragraphs remain in
feature evidence or history (normalizing relocated Markdown links only). Three
exact duplicate paragraphs reference Auth evidence. History is excluded from the
mandatory restore path; no chronology was appended wholesale to log.

Owner order: logout→HOME; login→HOME; empty-avatar first upload→replace→delete;
MY/Home/Materials/Learning/Settings sections; one deletion action. No Badge
Production test requested because collection/award backend is not implemented.
MOBILE_UI_OWNER_E2E: NOT VERIFIED.

Closeout validation: Flutter673 PASS/1 existing skip, analyze PASS, iOS simulator
and Android debug PASS,59 render cases at both requested sizes/scales, selected
five-screen PNGs inspected, Deno11 PASS. Signature/ignore/source audit PASS;
Wiki302 internal links and four routing self-tests PASS. Original Owner iOS
files verified unchanged by SHA1; no DB/Storage/schema/native config edits.

## Design System v2 — Owner approved 2026-09-24

These visual decisions supersede the previous peach-strip and outlined-MY-CTA
policies, not their functional boundaries.

| POLICY | WIKI STATUS | CODE EVIDENCE | TEST EVIDENCE | ACTUAL STATUS | ACTION |
|---|---|---|---|---|---|
| Palette A / cool page + white surface | Owner approval supersedes proposal-pending | app_theme.dart, shell_widgets.dart | design_v2_test.dart contrast/surface/semantics, mobile_ia_render_test.dart | IMPLEMENTED | Orange fill + navy text; accessible orange/danger text roles |
| No peach strips, common sections | prior emphasized guidance historical | SectionHeader plain, LsCard/LsListRow/SettingsGroup | seven-family render matrix and both Guest routes | GAP_FIXED | No emphasized API or Home multi-accent tokens |
| Guest MY/Settings login | source CTA existed; device-missing cause unproven | GuestAccountPrompt, private MY module gating | visible at360/428 and1x/2x; actual Auth route tests | GAP_FIXED | Explicit Login; keep local guest settings |
| Materials10 + load more | prior24 superseded | SupabaseSearchRepository.pageSize10, sentinel11 | search_repository_test.dart parent pagination/general boundary; search UI journeys | IMPLEMENTED | Same query/sort/facet/attachment contracts |
| Settings logout at bottom | former logout-before-policy superseded | settings_page.dart grouped content then logout/deletion | order render assertions; owner_handoff_fixes_test.dart success/cancel/error | IMPLEMENTED | Preserve confirmation and success HOME |
| Auth/Meal/Profile/Study/LAB | established boundaries unchanged | provider flows, photo repository, school policy, Study/Trend models unchanged | full existing regression suite | PASS locally | Owner device review separate; no Production mutation |

Component disposition: KEEP themed Flutter buttons, ShellPage, AppHeader,
SearchEntry, QuickFilterChip, EmptyState/ErrorState. MODIFY SectionHeader,
DailyUtilityCard, CompactUtilityCard, content/result cards. ADD LsCard/LsListRow/
SettingsGroup/GuestAccountPrompt. REMOVE emphasized variant/SectionDivider/accent
painter/Home accent colors. Do not add redundant wrapper names for their own sake.

Old test assertions tied to horizontal D-Day headings, outlined MY buttons,
guest-private menus and logout-before-policy were updated to Owner's v2 contract;
route, auth, touch-target, error, overflow and data-boundary coverage retained.
Original official provider branding remains an explicit palette exception.


V2 closeout: analyze PASS; full Flutter685 PASS/1 existing opt-in skip; iOS simulator
and Android debug builds PASS;67 responsive render cases PASS. Selected PNGs reviewed
for normal/2x typography, Guest Login reachability, white surfaces, Settings bottom
order and Materials result cards. Before PNGs: `/private/tmp/legendstudy-v2-before/`;
after: `/private/tmp/legendstudy-core-ui/` (local review artifacts, not tracked).
Signature scan/source-ignore readiness/diff PASS. No Deno changes; prior11 PASS
is historical, not a rerun. Owner iOS file hashes match the task-start snapshot.
Android build warns about future Kotlin plugin support; no toolchain upgrade was
introduced. DEVICE REVIEW PENDING; no Production mutation or push.

## V2 device follow-up and analytics handoff — 2026-09-24

| POLICY | PREVIOUS STATE | CODE / TEST EVIDENCE | ACTUAL STATUS |
|---|---|---|---|
| Home own identity | static image/name | HomeGreeting; design_v2_test owner/mismatch/guest; mobile_ia_render_test | IMPLEMENTED; no notification backend/count; optional trailing slot only |
| Small daily accents / Meal header | neutral titles / school above meal | DailyUtilityCard icon roles, MealSummary school right; home_compact_test geometry/full menus | IMPLEMENTED; time/fallback providers unchanged |
| Materials5 then10 | pages10 | pageSize5; search_repository_test sentinel6/offset5/boundary; search_ui_test explicit more | IMPLEMENTED |
| Timer recent7days | descending rows | StudyWeekSummary→StudyBarChart, study.week; study_home_polish_test/render | IMPLEMENTED; included-time calculation untouched |
| Mock optional subject | length copy/touching fields | label+spacing only; render focused input360/428 at1x/2x | IMPLEMENTED;40rune validation retained |
| MY snapshot / caller Back | service row context.go replaced caller | score_summary.dart push; day5_shell_test MY/LAB/direct route matrix | GAP_FIXED; native school backend remains absent |
| Analytics research | old two-platform emphasis, report evidence missing | architecture/roadmap/research registry; handoff checker9 routes | CANONICAL DIRECTION; report originals NOT INSPECTED, predictions RESEARCH-GATED |

No full advanced-analysis/notification/Badge/Community/backend added. Original report
metadata/content gaps remain open rather than fabricated. Existing Auth/Meal/Storage
Owner acceptance preserved; new mobile UI Owner E2E NOT VERIFIED.


Closeout evidence: Flutter695 PASS/1 existing opt-in skip; analyze PASS; iOS simulator
and Android debug PASS;71 responsive render cases at360×640/428×926,1x/2x, selected
Home/Meal/Timer chart/Mock focused field/MY/LAB PNGs inspected. Test-only Home font
correction rerun4 PASS. Local PNGs `/private/tmp/legendstudy-core-ui/` (not tracked).
Secret signatures422 text files/0 hits, source-ignore readiness and diff PASS;
Wiki359 links and9 routes PASS. No Deno changes or Production queries/mutations.
Owner iOS files match start hashes. Android existing Kotlin future-support warning
remains; no SDK/dependency/native configuration change in this task.

Owner review: Home greeting + semantic icons + Meal school alignment → Materials5
then explicit more10 → Timer7day chart/detail → Mock subject at large text → MY
snapshot→each LAB detail→Back MY → LAB→each detail→Back LAB. New mobile UI device
acceptance NOT VERIFIED. Internal-grade backend remains unavailable; no fake input.

## Owner device follow-up2 — 2026-09-24

| POLICY | WIKI / OWNER LATEST | CODE + TEST EVIDENCE | ACTUAL / ACTION |
|---|---|---|---|
| Compact Home / planned bell | smaller own+Guest header, visible slot | HomeGreeting; design_v2_test owner/guest/font/non-action; mobile_ia_render_test | GAP_FIXED; planned no alerts/count/backend |
| D-Day metadata / study row | name·date + Settings, D-n; label+duration | DayTargetCard, HomePage; day_target_test + mobile_ia_render_test11minute fixture | GAP_FIXED; long metadata3line bound and2× wrap tested |
| Meal trailing school/date chips | latest Owner presentation, existing time/data | MealSummary; home_compact_test edge geometry; meal_fallback_test chronological selected chips/full date | GAP_FIXED UI; policy/providers unchanged |
| Daily values + average | actual7day totals, mean neutral dashed | StudyBarChart/StudyWeekSummary/StudyTrendPage; device_followup_two_test zeros/one/mixed/equal/hours and2width×2scale | GAP_FIXED; zero/dynamicmax and inclusion retained |
| Mock context / refresh | actual supported subject selection, audit reset control | ScoringRepository joins exam_subject metadata; MockExamPanel automatic load/error retry; device_followup_two_test, existing scoring suites | GAP_FIXED supported-key path; full catalogue remains PARTIAL |
| MY structured comment / Back | Owner MY→LAB→Back PASS | score_summary.dart actual completed answers; score_summary_test, navigation/UI tests | PASS; no admission/growth inference |
| Materials5/more / Meal policy | Owner PASS | unchanged content/search and meal providers; full regression suite | PASS; no unrelated edits |
| Full exam-key catalogue/cross-device analysis | existing limited scoring foundation | bounded100 available-key query, local known result history | GAP_OPEN; no key publication/import or fake results |
| Requested product-operations synthesis | requested filename absent | filename search; existing research-registry.md provenance | GAP_OPEN documentation source; no claim original reports inspected |

Fresh validation:719 Flutter PASS/1 existing skip, analyze and both native debug
builds PASS;85 responsive/render-suite tests PASS plus23 new contract/chart cases
(in full suite). Selected1×/2× PNGs inspected; Timer duration typography adjusted
so0분 stays together at360px/2×. Signature scan423 text files0hits, source/ignore,
Wiki10route/internal links and diff PASS. Owner iOS raw SHA1 values match task-start
snapshot; untracked files preserved. No DB/Storage/Deno changes or Production mutation.
New MOBILE_UI_OWNER_E2E remains NOT VERIFIED. Canonical workflow details in
[Mock handoff](day-8-d2-answer-scoring.md#current-exam-selection-and-scoring-handoff--2026-09-24).
