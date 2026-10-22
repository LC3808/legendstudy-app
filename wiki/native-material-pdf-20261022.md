# Native APP material/PDF connection — 2026-10-22

## Scope and Authority
Owner accepted KAU WEB Production `1638d9c` verification and moved to APP. WEB supplements are paused; AI work waits for Owner APP review. Existing Store18(1.0.0), signing/package IDs and Production WEB/DB/Storage remain unchanged.

Reused `essay_browse_catalog` (71701), existing SourceCatalog/SourceCatalogPage, question_pdf.dart/pdfrx, authenticated Storage download, WEB approved student PDF manifest. No new server/schema/storage/PDF pipeline. 71702 not applied.

## Implementation
- Source catalog merges actual Production exam/question UUIDs and attaches only exact exam+question approved PDF mappings. Canonical SWU/KAU UUIDs and reviewed official archive links synced from WEB.
- Combined academic-year/exam selector always names admission/mock; track and question selection retain existing components. Browse-only PDF entry works independently of feedback readiness.
- All 485 approved mappings/153 assets copied from WEB; exact asset hash, pages and question start page validated. SKKU27 questions remain visible, PDF display RIGHTS_HOLD. Existing Hanyang approved exception retained.
- 42 universities preserved; preparing16 last, others Seoul first then Korean alphabetical, matching WEB. Removed misleading static-registry missing-data badge; LAB entry copy distinguishes material access from AI preparation.
- Existing answer writer/Math/evaluator/Credit/History/payment contracts not modified.
- Verification builds set REVIEW_READ_ONLY=true. Existing guard adds only metadata RPC; evaluation/DB mutations/Edge/transactions remain denied. Email login/refresh and authorized reads remain supported.

## Production metadata / WEB identity comparison (read only)
|Source ID|Exams|Questions|Approved PDF questions|ID mismatches|
|---|---:|---:|---:|---:|
|gachon|17|166|166|0|
|konkuk|21|58|58|0|
|kyunghee|10|38|38|0|
|korea|10|30|30|0|
|dongguk|16|48|48|0|
|sogang|24|28|28|0|
|skku|9|27|0|0|
|sookmyung|8|22|22|0|
|soongsil|16|42|42|0|
|swu|11|23|23|0|
|kau|15|30|30|0|

Total157 exams/512 questions,485 approved and27 rights-HOLD. API/mapping parity is not Native render PASS. Originals, answers and evaluation evidence remain private under existing RLS; no permissions changed.

## Verification
- Flutter3.47.6/Dart3.13.4 analyze PASS;35 related tests PASS, including485 exact mappings, tamper rejection, read-only transport, native selection/draft regression,360px/200% text scale and LAB entry.
- Android debug APK and iOS Simulator build PASS,1.0.0+2026102201, no Store upload. Final artifacts are in the private evidence builds directory.
- iOS Simulator manual guest/authenticated: existing login gate, Konkuk2026 natural question1 PDF1/4→2/4, question2 opens2/4, Kyunghee2027 mock natural questionI opens2/3 PASS. iOS Simulator automated integration also PASS for11 universities and10 representative PDF renders/start-page/next-page navigation, with10 screenshots visually inspected. Normal app restored without uninstall after test.
- Android emulator native integration PASS: all11 universities latest-period/track/question selection;10 representative approved PDFs rendered with exact start page and next-page navigation. SKKU rights-HOLD retained. Ten screenshot files visually inspected. Not a claim of512 individual renders or physical-device E2E.
- Test orchestration incidents: initial default version1 downgrade and driver default completion-uninstall each reset emulator-local login. Owner informed and reauthenticated. Fixed test build2026102201, prebuilt binary and `--keep-app-running`; normal APK restored with install-r. No Production data changed. Capture report merge corrected without product-code change.
- Owner physical Android installation/review and iOS device review remain required. Simulator is not an iPhone-installable archive/TestFlight build.

## Follow-up HOLD (not APP blockers)
- Kyunghee:2021 admission;2022 admission;2023/2024/2025 admission+mock;2026 mock.
- Dongguk:2022/2023/2024 admission;2025 mock. Owner filename-year priority retained; existing2026 mock identity overlap must be resolved in a future approved DB correction, not duplicated now.
- No AI work before Owner APP acceptance.

## Evidence and longitudinal preservation
Private evidence: `~/development/legendstudy-materials/essay-validation-2026-10/app-connection-20261022/` (metadata-snapshot/summary, platform screenshots, builds). Do not commit originals/PDF bytes/credentials/student data.
This is a read-only view over canonical IDs: no new history event, learning-event schema, derived DB state, backfill or identity change. Existing saved drafts/history provenance and ownership remain authoritative; browse PDF page state is local to the opened viewer and does not overwrite answer drafts. Recovery is reinstall prior verification build/code; no DB rollback needed.
