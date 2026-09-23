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
| Study chart vertical, proportional, zero, oldest→newest | study-v1 second refinement had bars but list presentation | study/trends/study_bar_chart.dart | owner_final_ux_test.dart proportions/zero/date order; mobile_ia_render_test.dart | GAP_FIXED | Vertical bars, minimum60min axis, horizontal overflow scroll |
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
| Older readiness and avatar documentation | auth-recovery says social unverified; ui-ux default avatar/external-only LAB; database pending apply | current code + Owner explicit apply/login report supersede these current claims | current 647-test suite; Owner evidence separately attributed | STALE_WIKI | Correct canonical current claims, retain dated history; server deletion gate still open |
| Community safe launch | Future; moderation mentioned but release coupling incomplete | no Community backend | no backend tests; no live placeholder UI | GAP_OPEN | Canonical platform boundary now requires block/report/filter/admin/support/terms together; no tables created |

Counts: PASS 14; GAP_FIXED 4; GAP_OPEN 4; STALE_WIKI 1.
Paths in code/test cells are relative to lib/ or test/ unless explicitly supabase/.
Future features are not promoted to implemented because their contracts exist.

## Verification and Owner handoff

Flutter3.47.5/Dart3.13.4: analyze PASS; full647 PASS/1 existing skip;
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
