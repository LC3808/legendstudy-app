# Personalization Motion UX — "Living Personalization" (Phase 1.2 design)

Status: **DESIGN ONLY. Not implemented.** Phase 1.1 shipped the static visual
polish (see [personalization-onboarding.md](personalization-onboarding.md)); the
moving background is a separate, later gate opened only after Owner device
review. This document is the canonical design so Phase 1.2 can be built without
re-deciding it.

## The core metaphor

Onboarding should feel less like "filling a form" and more like "the app is
getting to know me, one piece at a time." A single spatial language expresses
that across every personalization screen (school, then interested universities,
and later majors / subjects / goals):

- **BACKGROUND** = information not yet related to me (many school/university
  names drifting faintly).
- **SELECTION** = my action (I tap one).
- **FOREGROUND** = it has become *my* information (the chosen item rises out of
  the field, slows, grows, gains opacity, and settles into a foreground
  confirmation).

This is why the motion is meaning, not decoration: choosing my school out of
hundreds is personalization made visible.

## School screen (Phase 1.2)

- Background: many high-school names drift very slowly (loose word-cloud or gentle
  left↔right drift with subtle floating/breathing). Very low opacity; never
  competes with the foreground question or the search field; must not impede
  typing.
- On selection: the chosen name separates from the field → motion slows → scale
  up → opacity up → lifts to the foreground layer → connects to the selected-
  school confirmation card that Phase 1.1 already renders (`_SelectedSchoolCard`).

## Interested-university screen (future; not Phase 1.1/1.2 scope to persist)

Same language with university names and/or marks.

- **visual pool ≠ the universe of supported universities.** The background shows a
  *representative* set (~30–50) purely to signal "this is an admissions product"
  and spark discovery — not the full DB.
- Selection reaction: the chosen university's background visual reacts — moves
  toward foreground slightly faster than ambient motion, opacity ↑, scale ↑,
  rises to the foreground selection layer, then stabilizes as selected. The felt
  meaning: "out of many universities, I chose the one I care about."

### Multi-selection layout (future)

Interested universities may be multiple. Owner's spatial rule: selected items sit
top-center, responsive to phone width.

```
1: [A]      2: [A][B]      3: [A][B][C]
```

Foreground selections are clearly above the background. As count grows, item size
adjusts down naturally. Don't stack too many in the foreground early; when many:
**~3 representative in foreground + the rest as a compact indicator.**

## Motion architecture (proposed component tree)

Foreground form/question and background motion are **loosely** coupled; the
background is a **reusable** component reused by school / university / major /
subject / goal screens.

```
PersonalizationBackground        (reusable; decorative; ExcludeSemantics)
 ├─ BackgroundField
 │   ├─ MovingWord
 │   ├─ MovingMark
 │   └─ AmbientParticle (optional)
 ├─ SelectionReactionLayer
 │   └─ SelectedIdentity
 └─ ForegroundQuestionLayer       (the existing onboarding step content)
```

Phase 1.1 already reserves the slot: `OnboardingPage` renders a `Stack` whose
first child is `_OnboardingBackdrop` (currently a subtle gradient). Phase 1.2
swaps that for `PersonalizationBackground` without touching the foreground.

## Performance principles (hard constraints for Phase 1.2)

Onboarding must stay light on low-end devices; target stable 60fps on ordinary
iPhone/Android.

- Do **not** spawn dozens of `AnimationController`s. Prefer one (or a few)
  controllers driving many elements' position/opacity/scale via computation.
- No per-frame full-screen rebuilds; no unnecessary rebuilds.
- No blur/filter or GPU-heavy shader abuse.
- Cap background object count; minimize off-screen objects.

## Accessibility / Reduce Motion (required)

- When Reduce Motion is on: minimize or stop continuous movement; shrink the
  selection reaction to a fade/scale. Information delivery is unaffected — the
  whole flow works with no motion at all.
- Background visuals are decorative: exclude from the semantics tree so a screen
  reader never reads every school/university name. Phase 1.1's backdrop already
  uses `ExcludeSemantics`.

## University logo / mark asset strategy (before any logo use)

Owner prefers real university marks, but we will **not** scrape or commit logo
files. Before Phase 1.2 logo work, review: official identity-asset acquisition
path, usage terms, file formats, light/dark handling, naming convention, and
caching/bundle strategy. The architecture must **not depend on logos** — the same
UX must work with name typography alone, so logo delay never blocks it.

## Product-philosophy tie-in

Personalization is for user value (more fitting materials, schedules, records,
score trends, goal universities, later essay-feedback history all connecting into
one continuous "my admissions journey"), never a conversion trick. No monetization
UI here. If the accumulated continuity delivers enough value, any future paid
features stay opt-in, not a forced paywall.
