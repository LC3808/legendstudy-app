# Day 10-B — Home Polish v2

Status: original Day 10 evidence below is historical. Current meal policy and
Owner acceptance follow-up are recorded at the end of this document.

Current interaction: Home inline expansion (2026-09-22 below) supersedes the
2026-09-21 standalone detail navigation. Meal time policy is unchanged.

Meal policy and previous device acceptance: see [2026-09-21 Owner Profile
follow-up](#owner-profile-follow-up--2026-09-21). The original 17:00 policy below
is retained as historical evidence only.

## Historical scope (superseded meal policy below)

Home now supports:

- today/tomorrow meals using KST (`Asia/Seoul` UTC+9 semantics)
- 17:00 KST dinner/tomorrow priority
- automatic re-evaluation at the next 17:00 or 00:00 boundary and on app resume
- recent updates fetched with a Home-only limit of 6, collapsed to 2 and
  expandable to 6
- recent views fetched with an account-scoped limit of 6, collapsed to 2 and
  expandable to 6

The Materials full search/list and MY full recent list contracts remain
unchanged. Guest recent-view behavior and C3 account isolation are preserved.

## Meal policy

- Before 17:00 KST, today’s available meals are primary; tomorrow is available
  from the existing expand interaction when present.
- From 17:00 KST, today’s dinner is primary when it exists. Tomorrow follows
  through expansion.
- From 17:00 KST without dinner, tomorrow becomes primary when available.
- If neither primary nor tomorrow data exists, the existing minimal empty state
  remains; no empty tomorrow section is created.
- `Meal` meal types remain open-ended. The v2 priority rule specifically uses
  `석식`; other types continue to render under the existing model contract.
- The lifecycle-owned timer schedules only the next meaningful boundary, never a
  1-second polling loop. Resume invalidates the clock and both meal queries.

## Recent sections

Both Home sections use independent expansion state and the same `더보기` /
`접기` affordance. The initial query/hydration is bounded to six items, so
expansion does not issue another request. Full exploration remains in 자료
찾기 and MY → 최근 본 자료.

## Validation

- Day 10-B widget/policy tests cover meal 16:59, 17:00, dinner/no-dinner,
  tomorrow/no-tomorrow, KST midnight/device-timezone independence, recent
  updates 0/1/2/3/6/7+, recent views 0/1/2/3/6/7+, and guest read safety.
- Existing Day 7 school, Day Target, NEIS attribution and C2/C3 tests pass.
- Full Flutter suite: 335 passed, 1 opt-in read-only network test skipped.
- Flutter analyze: No issues found.
- Android `flutter build apk --debug`: PASS with dependency validation.
- iOS simulator build/run: PASS without external xcconfig; Home rendered on
  iPhone 16 Pro simulator. The existing AppLinks plugin lifecycle warning
  remains informational.
- iPhone Profile build: PASS, but Xcode/CoreDevice automated install/launch
  timed out before interactive Home verification. No Production data was
  changed.

## Owner Profile follow-up — 2026-09-21

Owner iPhone Profile reports Email App Auth/session restore/MY school/MY grade PASS.
Owner also reproduced lunch-only today menu after 14:00. Actual source confirmed:
mealDisplayPlan used 17:00, selected all today meals beforehand, and retained dinner
indefinitely afterward. Timer only handled 17:00/midnight. This was a policy bug,
not a failed school save or inferred timezone/network problem. Older 17:00 tests
encoded that policy and therefore did not detect the 14:00 requirement.

Trace: profiles NEIS pair → schoolSelectionProvider → SchoolRepository.find;
NeisSchoolRepository.meals queries exact school/date; proxy forwards MLSV_YMD,
returns MMEAL_SC_NM and DDISH_NM without Home time filtering. Client verifies
school/date and parses menu line breaks. Neither inspected repository nor proxy
has a persistent meal cache; Riverpod retains raw today/tomorrow results. Production
proxy was not changed/redeployed. No upstream meal data or breakfast was deleted.

Canonical Home policy (supersedes earlier 17:00 rules):

| KST | Home selection |
|---|---|
| 00:00–13:59 | Today's lunch |
| 14:00–18:59 | Today's dinner when available, otherwise next available day |
| 19:00 onward | Next available day, even if today's dinner remains in raw data |
| Forward priority | First lunch/dinner date within next day D through D+6 |

Breakfast never becomes Home representative, including 07:59/08:00 or a tomorrow
breakfast-only response. Missing eligible today meal searches next day D through D+6; breakfast-only dates
are skipped, lunch precedes dinner. No date found means 예정된 급식이 없어요.
Network failure stays an error, never a holiday. This 2026-09-23 correction adds
the previously missing traversal to the former today/tomorrow implementation;
never pretend expired lunch/dinner is current. Tap preview (also empty preview)
opens selected-date detail with real breakfast/lunch/dinner only, full untruncated
menus and a second date action to inspect today's food after Home moves forward.
Date heading is explicit; no empty cards for absent meal types.

Pure policy and nextMealBoundary operate on UTC instants converted to KST.
mealNowProvider is the sole injectable now source. All candidate query dates derive from
koreanMealClockProvider. Boundary timer handles 14:00/19:00/midnight; resume and
Home TickerMode reactivation refresh clock/date/raw requests. Selection is recomputed
from raw responses, not a cached preview. Both async responses must resolve;
load failure is retryable rather than disguised as an empty menu.

Validation: four school combinations at 07:59/08:00/13:59/14:00/18:59/19:00;
Owner lunch-only 14:00 regression; tomorrow lunch/dinner/breakfast-only/empty;
UTC/KST dates, boundary timer, midnight requests, resume and Home revisit;
tomorrow loading/error; full breakfast detail and today access; Settings navigation.
Focused new tests 31 PASS. Full 545 PASS / 1 existing skip; analyze and Android
debug/iOS simulator builds PASS. Existing long-menu 360/428px 1×/2× renders now
verify preview → detail → back (old expansion expectations intentionally updated).
These are local fixture tests, not new Production NEIS/device E2E.

Owner subsequently confirmed the updated meal Home/detail experience on iPhone:
`MEAL_TIME_AWARE_DEVICE_E2E: PASS`. The Home LAB promotional banner is removed;
LAB itself remains available through MY. MY Settings gear/IA was also checked on
iPhone: `MY_SETTINGS_DEVICE_E2E: PASS`. These UX checks do not close any release
gate for deletion, policies or store submission.

## Home inline follow-up — 2026-09-22

Owner requests Home expansion rather than a new detail route. MealSummary now owns
only ephemeral expanded/date-selection state; canonical school/raw meal providers
and pure time selection remain unchanged. Tapping preview opens actual meals of
that date in-place. Chevron/header tap collapses; date action switches today/tomorrow
inside expanded content. Re-expansion starts at the current policy-selected date.
Breakfast remains excluded from preview but available expanded; absent types produce
no section, empty day has explicit copy. Boundary/school identity key resets the
summary so stale selected-date UI does not outlive clock changes.

Removed MealDetailsPage only after lib/test search confirmed Home was its only
caller and there was no registered/deep-link route. Home route and navigation tabs
remain. Configured school loses setup button/semantics; loading/error do not flash
an unset-school action. Resolved unset still exposes a >=48px setup CTA.

Shared DailyUtilityCard now allows absent action without a reserved action row.
Vertical padding 8→4, Home daily-card gaps 8→6, warm border #C8C3BB; global content
card border unchanged. Meal heading/date/preview form one >=48px tap area, eliminating
the former padded 48px label row plus separate date spacing. Menus remain scrollable
and untruncated when expanded. No fixed height or text-scale clamp.

Evidence: full 556 PASS/1 existing skip; analyze, Android debug/iOS simulator builds,
secret signature/log inspection and diff check PASS. Four full-Home route/tab tests
at 360×640/428×926 and 1×/2×; existing meal matrix/boundary/cache, loading/error and
Settings tests retained. Long meal raster reviewed including last menu; Home raster
shows stronger borders, compact heading gap and retained tabs. Examples generated
under build/polish and /private/tmp/legendstudy-core-ui (ignored/local only).
No actual new iPhone render/Apple login was run. Owner to review compact cards and
inline interaction on the new Profile device; earlier meal policy device PASS remains.


Owner iPhone second review after d7008bd: MEAL_OWNER_E2E PASS, including current
seven-day fallback/time/Home-expanded behavior. Subsequent edit/chart/LAB UX work
leaves meal implementation unchanged; regression suite retained.

## V2 device follow-up — 2026-09-24

Home greeting uses canonical owner-matching LegendStudy displayName, no social
metadata/email fallback; guest copy and generic authenticated fallback. Existing
brand assets preserved but Home wordmark/caption removed. Optional header trailing
slot prepares future notifications with no visible fake bell/count or backend.
Neutral daily cards add small semantic icons (D-Day orange, Study blue, Meal green).
Configured MealSummary puts selected meal label left and school secondary right,
wrapping within bounded columns for long text. Date/menu below; no policy/provider
changes. Prior Owner Meal PASS retained; new visual acceptance pending.
