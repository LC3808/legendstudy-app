# APP Release Finalization — 2026-10-09

**APP_RELEASE_FINALIZATION: PARTIAL (agent gates COMPLETE; Owner signing/submission gates remain).**
No new features; existing implementation preserved. Verification-and-audit pass on
the release branch; **no code change was required** — the RC was already finalized.

## Authority
- APP base: `claude/final-store-release-2026-10-08 @ a3cc3b3` (contains Codex
  closeout `0570099` +16; RC-1 `7d1c036` +3; canonical icon correction).
- Codex candidate `23d4555` = `codex/essay-web-runtime` (separate, in-flight Essay
  runtime) — **not merged, not touched.**
- LAB Production `main` and DOCS `legendstudy-docs` read for authority.

## Canonical icon
- Master `assets/brand/source/legendstudy_app_icon_master.png` SHA-256
  **`e37afa18ceaf9e27ab275c1cb460b512697baa3d745689ed741c871ce079abfe` — EXACT
  MATCH.** Orange rounded-square + white note + white pencil, original ratio.
  **Not regenerated or reinterpreted.** CHANGED: NO.

## Splash
- White background + orange symbol (`ic_brand_symbol` / bundled
  `legendstudy_symbol.png`); the app-icon orange background is **not** applied to
  splash; no extra copy/decoration. Native launch = symbol only; Flutter cold-start
  brand frame adds name + tagline (cold-start-only, parallel timing). STATUS:
  preserved/verified.

## CTA hierarchy (audit — already Owner-approved 2026-10-08, no change)
Centralized in `lib/core/theme/app_theme.dart` with a documented convention:
- **Primary (FilledButton)** = reserved for strong final actions only (form submit/
  save, auth submit, destructive confirm, essay submit, onboarding completion,
  payment).
- **Secondary (OutlinedButton)** = general/navigational CTAs (orange outline,
  transparent fill, navy label, light-orange press tint).
- **Tertiary (TextButton)** = cancel/secondary (navy).
- Usage: FilledButton ×32 (all legitimate strong actions), OutlinedButton ×23,
  TextButton ×110, **ElevatedButton ×0**. Min touch target 48×48 across all three.
- **Verdict: coherent and Owner-approved → no sweeping refactor** (per "no refactor
  unless release-blocking"; a broad change would risk the green test suite).

## UI (existing screens, preserved; not re-rendered on device this pass)
onboarding · login (orange-outline entry prompts) · home · materials (active +
`published_at DESC`, not modified-date) · PDF/resource · saved/recent · Study Timer
(start/pause/resume/stop + 7-day chart oldest→newest, average line/avg/max; shared
`my_study_summary` contract with Web — unchanged) · D-Day (representative +2,
more/collapse, `YYYY.MM.DD.(요일)`, 360px/200%) · MY · settings. No feature added,
no aggregation/sort semantics changed. LAB entry keeps the four Essay types GATED
(not shown as usable).

## Tests / builds (this branch, 2026-10-09)
- `flutter analyze`: **No issues found.**
- `flutter test`: **967 passed, 2 skipped — All tests passed.**
- iOS `flutter build ios --release --no-codesign`: **PASS** (`Runner.app` 32.1 MB,
  bundle `com.legendstudy.app`).
- Android `flutter build apk --debug`: **PASS** (`app-debug.apk`). Android **release
  AAB signing is BLOCKED** on the Owner upload keystore (`android/key.properties`
  absent; no debug-key fallback by design).
- Version `0.1.0+1`.

## Boundary (unchanged)
ESSAY_RUNTIME_CHANGED: NO · DB_CHANGED: NO · PAYMENT_CHANGED: NO · TOSS_CHANGED: NO ·
IAP_CHANGED: NO · TARGET_005: HOLD. Manus and Codex work preserved; Codex
`essay-web-runtime` untouched.

## Owner action required (remaining Store gates)
1. Android upload keystore + `android/key.properties` → signed AAB (release build is
   agent-blocked without it).
2. iOS signing/team/provisioning + archive/export via Xcode or `tool/store-release`.
3. Build number bump for submission, reviewer account, device smoke, App Store
   Connect / Play Console inputs (screenshots, content rating, export compliance,
   external-link/payment policy answers), recovery-redirect verification.

## Next
Owner provides signing → signed builds via `tool/store-release` → device smoke →
Console submission. The code RC is green and finalized on `a3cc3b3`+.
