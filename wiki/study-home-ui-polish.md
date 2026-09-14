# Study/Home UI polish — 2026-09-14

## Scope

- Home meal defaults to a two-line summary. Tapping the meal region expands full
  menus grouped by the NEIS meal type (lunch/dinner only when present); chevron,
  explicit 펼치기/접기 and expanded semantics expose the action. No fixed expanded
  height; Home scrolls. School/date changes reset expansion. At large text the
  school title gets the full row and school settings moves below it.
- Seven-day rows display newest first (today through six days ago), with date and
  duration aligned left/right and wrapping for large values. KST aggregation unchanged.
- Running pause is outlined with pause icon; paused resume is orange-filled with
  play icon. Both retain labels and 48px minimum targets. Applies to Study and mock.
- Modes use selected semantics, dark 2px outline, warm selected background and bold
  text. Entire segment is tappable (minimum 56px); labels can wrap.
- First mock setup is 국어80. Presets in order: 국어80, 수학100, 영어70,
  영어45 · 듣기 제외, 한국사30, 탐구30, 사용자 지정1–720. Listening-excluded
  practice still stores subject 영어; preset labels are local conveniences.
  Restored setup matches by subject/duration or displays 사용자 지정.
- UI says 시험 시간 in setup, errors and elapsed/planned summary. Internal duration
  fields, persistence, scoring, RPC and schema are unchanged.

## Validation

Widget tests cover collapsed/expanded, lunch-only/lunch+dinner, long school/menu,
newest-first dates, running/paused styles, mode state/targets, Korean default,
preset order and English45 actual start/timeUp. Existing preset validation and
full timer/Focus/aggregate/answer/scoring/grade/ownership regressions are retained.
Text contrast against orange, selected cream and white is checked >=4.5:1.

Rendered Flutter screens use Korean and Material icon fonts at 360×640 and
428×926 (iPhone12 Pro Max portrait logical size), each at1×/2× text. The review
caught and corrected narrow school-title wrapping and centered weekly rows.
Full menus remain scroll-accessible; two-line truncation is intentional only
in collapsed mode. Local artifacts: build/polish/*.png (ignored).

Native UI harness: integration_test/study_home_polish_test.dart with
 test_driver/study_home_polish_driver.dart. It only uses memory stores, fake
 repositories, clock, Focus and notification services. No Supabase initialization,
 actual login, real notification or persisted account/session writes. Screenshots
 are saved under build/polish-iphone/ (ignored). This proves presentation only,
 not real lifecycle, Auth/D3 or notification delivery.

- Final local validation: flutter analyze PASS; all257 Flutter tests PASS (14 polish
  tests included); separate Korean-font render run all14 PASS; Android debug and
  iOS simulator builds PASS; git diff --check PASS.
- Physical iPhone12 Pro Max (iOS26.6.1), profile-mode synthetic UI run PASS at native
  portrait resolution and1×/2× text. Reviewed22 final screenshots (428-named files)
  for meal compact/full lunch+dinner, long school/menu, running/paused, setup,
  preset menu and timeUp. No observed overflow; expanded content remains scrollable.
  At2×, the page requires normal vertical scrolling; captures include scrolled states.
- Native harness uses the real device resolution and SafeArea. Early test-only
  viewport/touch-coordinate failures were corrected; final run passed all cases.

The optional blank subject in a restored custom setup is preserved.

The normal application was rebuilt in profile mode with the existing local public
configuration, reinstalled without uninstalling and successfully launched after
the harness. No production schema/data fixture or real account credentials were used
by the UI harness.

UI validation does not include a new VoiceOver walkthrough or every school/OS model.
No remaining blocking UI issue was observed in the reviewed matrix.


## Owner-reported iPhone physical results

Owner reported on2026-09-14, from the earlier profile app:
- profile launch and general Study start PASS;
- screen-lock/background time continuation PASS;
- pause time held PASS;
- mock timeUp PASS;
- actual local notification PASS;
- complete process kill/relaunch restored elapsed time/state PASS.

These are real-iPhone Owner reports, separate from automated Flutter/runtime
or synthetic UI screenshots. iOS Focus guidance remains pending. Android physical
DND/lifecycle, reboot/boot-continuity, and broader OS/device acceptance remain
pending. Day8-B/C and Day8 overall are not newly marked COMPLETE. D3 A/B automated
runtime remains a separate task; none of its preexisting files are part of this commit.
