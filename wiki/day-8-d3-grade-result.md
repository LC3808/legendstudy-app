# Day 8-D3 — Grade + Result UX

Status: implementation complete; local checks and Guest native runtime PASS.
D3 is NOT COMPLETE until its actual A/B runtime gate is accepted. D2 remains COMPLETE; Day 8 overall NOT COMPLETE.

## Display and trust contract

Raw/max score is primary; grade is smaller. confirmed + verified raw_absolute source
shows `n등급` / `확정 등급 기준`; estimated + raw_estimate shows `예상 n등급` /
`예상 등급컷 기준`; unavailable shows `등급 정보 준비 중` with the raw score intact.
No standard score, percentile, subject threshold or guessed grade is introduced.
Malformed grade/null/status/basis combinations fail validation. A reviewed confirmed
rule is not an officially issued score report; source details make this distinction.

Summary includes correct/total, incorrect and unanswered counts. Separate number
lists jump to corresponding answer rows; answer review spells out own choice, correct
choice, points and correct/incorrect/unanswered text with equivalent screen-reader
semantics. No color-only status. Long titles and 100 rows scroll; controls retain
48px targets and 360×640 at 1×/2× coverage. Results offer answer/source actions, return
to Study and Home where the app router exists. No new submit action or running state.

## Provenance, restore and history

Auth consumes key_source/cutoff_source and submitted_at from the existing RPC and
canonical fetch-own response. Result validation compares both responses before save.
Guest computes through the existing Dart engine and reads source rows for the exact
pinned versions, using existing public grants and no cloud writes. Provenance is
serialized inside ScoreResult in the native v3 document. Sources show name, KST
verified date and an optional external action; UUID/version values are not shown.
ExternalLinkButton applies the existing safe opener in addition to model HTTP(S),
host, userinfo and control-character validation. No WebView or source network fetch
on restore. New current v2 does not change stored v1 grades, answers or provenance.
Mutable publication status is not treated as part of the immutable source snapshot.

Old D2 cached results lack source fields. Optional deserialization preserves scores,
grades and answers without rewriting or deleting them. UI shows a missing-basis notice
and withholds the grade label until provenance exists; it never borrows current source.
There is no automatic legacy cache hydration or Guest regrade. New D3 results persist
identical grade labels and metadata across controller/native-file restoration.

ScoringAttempt adds optional subject and local logical completedAt; authenticated
ScoreResult retains server submittedAt. Together with id/title/raw/max/grade/status/
correctCount/questionCount these support future history projection without schema
changes. No full history screen, deletion feature, subscription gate or data cap.
Future Entitlement/Free/Basic/Pro ideas are recorded in architecture.md only.

## Runtime boundary and execution

`integration_test/grade_result_smoke_test.dart` uses native clock/atomic storage and
the real Guest repository with synthetic MockClient HTTP. It covers all three grade
statuses, source/review UI and native restore after synthetic current version change;
the original whole local file is restored in finally. It makes no production request.

The existing `integration_test/mock_scoring_auth_smoke_test.dart` now additionally
asserts confirmed basis, grade text and source retention. The existing safe-output
runner and approved cleanup contract are unchanged. D2 PASS does not establish D3
runtime PASS. Do not run `tool/run_mock_scoring_flutter_smoke.py` under this request:
it creates temporary production fixtures, while the D3 instruction forbids production
scoring data input. Owner must separately authorize/run that fixture workflow; use the
existing hidden-input command documented in D2 only after that authorization. Never
put credentials in command arguments or documentation. No production fixture cleanup,
trigger restoration or baseline restoration is newly claimed by D3 local tests.

Physical background/lock/Focus/notification/kill/reboot remains an independent B/C gate;
native controller reconstruction is not OS process-kill/reboot validation.

## Validation

- flutter analyze: PASS, no issues.
- Full flutter test: 242 PASS (228 existing +14 D3); includes all37 shared engine vectors.
- Grade1/9, boundary90/89, estimated/unavailable, null/malformed grade/basis, all correct,
  wrong/blank/mixed, URL rejection, Guest/Auth transport mapping parity, exact historic
  retry/source snapshot, JSON restoration and legacy-cache preservation: PASS.
- 360×640 at1×/2×, long title/source, 100 answers, 48px number actions, source dialog
  and injected safe opener, wrong/blank semantics and Study/Home navigation: PASS.
- Android debug build and iOS simulator app build: PASS. Android x86 deprecation
  notice is non-fatal. No platform/dependency/build configuration changes.
- iOS native Guest smoke: PASS for confirmed/estimated/unavailable, answer review,
  source dialog, historical restore without network requests, whole-file cleanup.
- Auth smoke iOS simulator integration-target build: PASS. Actual A/B D3 runtime
  and production version/fixture cleanup/trigger/baseline acceptance: NOT RUN.
- git diff --check: PASS; all production migration/RPC files unchanged. No production
  connection, fixture, schema change, Push, PR or Merge.

Safe native markers:

```text
D3_GUEST PASS confirmed
D3_GUEST PASS confirmed_review_source
D3_GUEST PASS confirmed_historical_restore
D3_GUEST PASS estimated
D3_GUEST PASS estimated_review_source
D3_GUEST PASS estimated_historical_restore
D3_GUEST PASS unavailable
D3_GUEST PASS unavailable_review_source
D3_GUEST PASS unavailable_historical_restore
D3_GUEST PASS local_fixture_cleanup
```

Next: separately authorized Owner-run A/B D3 acceptance using the prepared runner;
then record the actual result. Retain the independent B/C physical-device gates.
