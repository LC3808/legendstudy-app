# Continuous STANDBY connections — 2026-10-25

Owner explicitly approved these scoped Production connections. All four batches are APPLIED; do not rerun. The manifest records exact exam/question IDs, package revisions and student PDF hashes. Official source bodies remain in private local SQL files, not this repository.

- Kyung Hee text: 10 exams, precheck20/postcheck7 true.
- Kyung Hee social: 10 exams, precheck20/postcheck7 true.
- SKKU language A: 7 exams, precheck17/postcheck7 true.
- SKKU language B: 6 exams, precheck16/postcheck7 true.

Each path contains precheck.sql, apply.private.sql, postcheck.sql and scoped rollback.sql. Rollback disables only the added runtime/PDF scope; it does not delete student data. The combined SKKU13 SQL was rejected with HTTP413 and superseded by A/B; never run it. Existing ID/Credit/Ledger/History contracts and successful policies are preserved. No Provider calls or APP build.

Canonical status and deployment evidence: [1-A Wiki](../../../wiki/essay-group-1a-20261025.md#경희-신규10회차-운영-연결).
