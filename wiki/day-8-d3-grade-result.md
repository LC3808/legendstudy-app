# Day 8-D3 — Grade + Result UX

Status: **Day 8-D3 COMPLETE**, Owner-reported actual A/B Flutter runtime and full
cleanup/retention PASS on2026-09-15. D1/D2 remain COMPLETE; Day8 overall NOT COMPLETE.
Earlier preparation/pending checkpoints below are historical and superseded by this closeout.

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

The Owner-run D3 runner is `tool/run_mock_grade_flutter_smoke.py`, targeting
`integration_test/mock_grade_auth_smoke_test.dart`. It uses actual A/B SDK login,
registered Study/scoring repositories, server RPC/read-back, native atomic storage,
and the production router/Study/history/Home screens. Unrelated providers remain
unconfigured; this does not test OAuth UI or OS-process restart authentication.

Run in an interactive terminal (hidden account/DB password prompts):

```sh
./tool/run_mock_grade_flutter_smoke.sh /Users/woojinchang/legendstudy-local.json
```

`--preflight-only` checks identity/baseline without creating fixtures; `--device`
selects a booted simulator. Administrator credentials never reach Flutter. A one-use,
random loopback URL delivers account inputs in memory. Only exact allowlisted markers and typed diagnostic fields
are forwarded (including the native `flutter:` prefix); raw Flutter/HTTP/DB output
and exception messages are never printed. Missing stages, nonzero
exit, bridge errors or absent local cleanup prevent overall PASS. The runner stops
the native test/app before administrator cleanup.

Fixture scope includes the existing D1 synthetic parent/common v1-v2 definitions,
one estimated/raw_estimate variant and one cutoff-free variant. No real exam data.
At most three A Study IDs and three A attempt IDs are collision-checked and registered
before dispatch. All new definition IDs are included in preflight and cleanup scope.
After all three results, the common key/cutoff switch to v2, with distinct v2 source
metadata; old v1 results must retain their grade, answers, sources and exact retries.
No attempt from B is created: B must see none of A's local history, RPC or answer rows.

Cleanup directly reuses D1's single transaction, full baseline table locks, exact
run UUID count/digest checks, owner guards, FK cascades and only the three approved
USER triggers. It restores trigger state and public-table baseline before commit.
Partial fixture creation/failure still runs guarded cleanup; no permanent production
fixture, migration or RPC change. Existing rows and Auth users are retained.

Runtime checks cover confirmed/estimated/unavailable text, raw/max/counts, correct/
wrong/blank review, no pre-submit answers, historical source name/date/safe HTTP(S)
metadata, no UUID/version UI, native controller restoration and history reopening,
account isolation, identical RPC retry, legacy source-less cache fallback, malformed
null-grade rejection and Study/Home navigation without new submission. Legacy cache
mutation is local/run-only and restored in finally; the original whole device file
is separately restored. The displayed source links are inspected, not actually opened.

Required native markers use `D3_FLUTTER PASS`: login_preflight, confirmed_grade,
estimated_grade, unavailable_grade, result_summary, answer_review, provenance,
auth_restore, historical_version, account_isolation, retry, legacy_fallback,
navigation, local_fixture_cleanup. Cleanup/retention additionally require
fixture_scope_verified, fixture_cleanup, cleanup_triggers_restored,
scoring_baseline_restored, existing_data_preserved, auth_users_retained. Final success
is `Flutter grade result smoke: PASS` only after every gate passes.

Runner preparation is authorized; Product Owner performs its actual execution.
D2 PASS and local preparation checks do not establish D3 A/B runtime PASS.

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


## D3 A/B runner preparation verification

- 11 new Python runner safety tests PASS, including all three actual local PostgreSQL
  scoring modes, historical retry, bounded registration/collision rejection, partial
  creation cleanup, wrong-owner rejection, rollback at every cleanup step and redaction.
- Combined D3/D2 runner plus D1/Study/D-Day offline suite: 65 tests PASS. All PostgreSQL
  execution uses an isolated local Unix-socket cluster, never production JWT evidence.
- New offline actual-router/controller test PASS: answer page, completed result,
  history restore, Study/Home return and no new submission. Full243 Flutter tests
  PASS (242 previous +1 runner-route test). Analyze PASS and iOS simulator integration-target
  build PASS. No D3 feature code changed.
- Production A/B runtime, production fixture cleanup/trigger/baseline acceptance remain
  NOT RUN pending Owner execution. D3 and Day8 overall remain NOT COMPLETE.

## 2026-09-15 — Runner diagnosis prepared; Owner rerun pending

Start checkout verified: branch codex/day-7-school-neis, HEAD88c4a60. Existing D3
runner/integration/navigation tests remained untracked, with the four earlier Wiki
changes intact. Local checkout is canonical; no reset/overwrite/commit/push/PR/merge.

Owner reported only `D3_FLUTTER FAIL runner` and `Flutter grade result smoke: FAIL`.
The original generic catch discarded exception type and stage; the exact original
failure cannot be established from this output. Offline injected failures reproduce
that loss and now produce a bounded diagnostic. No real credential rerun was made.
Today's absent /private/tmp Python venv and shutdown simulator were observed and
prepared separately; they are not asserted as yesterday's root cause.

Diagnostics now report only fixed stage/kind, allowlisted guard/DB codes, numeric
HTTP status and subprocess exit code. Native TestFailure/Auth/PostgREST/timeout/
network/format/state categories are surfaced without their messages. Missing PASS
stages and bridge failures are explicit. Response bodies, URLs, commands, account
passwords, JWTs, publishable keys, DB passwords and connection URIs remain hidden.
Python bridge/finalizer errors also cannot escape as raw tracebacks. Native review
and provenance failures carry their actual substage instead of result_summary.
Simulator readiness is checked before hidden inputs and fixture creation; it does
not auto-select another device or run the A/B test during preparation.

- D3 offline20 tests PASS, including redaction canaries, stage/exit/missing-marker,
  simulator gates, bridge/finalizer failures, all three scoring modes and cleanup.
- Existing D1/D2 scoring25 tests PASS; isolated Unix-socket PostgreSQL17 only.
- Python syntax, credential literal scan, tracked and new-file diff checks PASS.
- Integration-test analyze and15 relevant Flutter grade/navigation tests PASS.
- D1 cleanup implementation and SQL unchanged: run UUIDs only, exactly the three
  approved USER triggers in one transaction, baseline/owner/digest/rollback checks,
  no Auth deletion or global/FK/constraint-trigger disabling.
- Temporary execution venv restored with psycopg[binary]3.2.10; default simulator
  verified Booted. PostgreSQL package is test-only, outside Git.

STOP before actual credential execution. Owner uses the command above, supplying
A/B passwords and DB password through getpass and the Session pooler host at its
prompt. Actual production cleanup cannot be declared PASS until that run reports it.
D3 remains implemented / A/B runtime pending, NOT COMPLETE. Existing iPhone
profile/Study/lock/pause/timeUp/notification/kill-restore PASS and UI polish88c4a60
remain accepted. Remaining physical work is iOS Focus details, reboot edges and
Android actual DND/notification/restore. No D3 feature/UI/schema/migration/RPC edits.

## Shared optional pooler host — 2026-09-15

D1, D2 and D3 reuse `admin_host_from_config` from verify_mock_scoring_jwt.py.
Add `SUPABASE_SESSION_POOLER_HOST` to the existing repository-external local JSON
using the Owner's Session pooler host. Present valid values are used automatically;
only an absent key prompts for host (blank still chooses direct DB). Present empty,
non-string, URL/port/option-bearing or invalid host values fail with ADMIN_HOST.
The existing project-pinned username, port5432, SSL and DB identity preflight remain.
Host configuration is not passed to the Flutter credential bridge. All three
password prompts remain getpass; do not add passwords to JSON. No actual host value
is newly duplicated in repository configuration and the external file was not edited.

Offline49 tests PASS: shared-loader/three-entrypoint coverage plus existing D1/D2
and D3 fixture/diagnostic tests. Python syntax, credential scan and diff checks PASS.
No Flutter feature, production DB/schema/RPC or cleanup SQL changes; no new commit.

TODO for a separately approved step: assess macOS Keychain for TEST_A_PASSWORD,
TEST_B_PASSWORD and DB password, including access controls and safe failure behavior.
This entry is planning only; no Keychain reads/writes or password persistence added.

## 2026-09-15 — Owner actual A/B acceptance COMPLETE

Owner executed the real runner and supplied all of the following markers:

```text
D3_FLUTTER PASS login_preflight
D3_FLUTTER PASS confirmed_grade
D3_FLUTTER PASS estimated_grade
D3_FLUTTER PASS unavailable_grade
D3_FLUTTER PASS result_summary
D3_FLUTTER PASS answer_review
D3_FLUTTER PASS provenance
D3_FLUTTER PASS auth_restore
D3_FLUTTER PASS historical_version
D3_FLUTTER PASS retry
D3_FLUTTER PASS account_isolation
D3_FLUTTER PASS legacy_fallback
D3_FLUTTER PASS navigation
D3_FLUTTER PASS local_fixture_cleanup
D3_FLUTTER DIAG stage=flutter_runtime kind=state exit_code=0
D3_FLUTTER DIAG stage=flutter_runtime kind=app_stop exit_code=3
D3_FLUTTER PASS fixture_scope_verified
D3_FLUTTER PASS fixture_cleanup
D3_FLUTTER PASS cleanup_triggers_restored
D3_FLUTTER PASS scoring_baseline_restored
D3_FLUTTER PASS existing_data_preserved
D3_FLUTTER PASS auth_users_retained
Flutter grade result smoke: PASS
```

These are Owner-reported production A/B acceptance results, not an agent rerun.
All required application and cleanup gates passed; Day8-D3 = COMPLETE.
The earlier generic runner failure is superseded by successful acceptance. No need
to rerun already accepted behavior merely to close documentation.

`app_stop exit_code=3` belongs to the additional `simctl terminate` after Flutter
exits, not to the Flutter test. An independent call against an absent diagnostic
bundle on the same simulator returned3 with “found nothing to terminate”/no-process
semantics. The accepted run's exit0, local cleanup and complete DB cleanup PASS are
consistent with the test app already having exited. The original raw terminate
stderr was intentionally not retained; exit3 alone is not a universal success code.
Do not relabel this accepted run as failed or weaken the other acceptance gates.

### Verifier launch UX

From the repository root use the short shell command above. The wrapper first uses
LEGENDSTUDY_VERIFIER_VENV if explicitly set, otherwise the stable user venv at
`~/Library/Application Support/LegendStudy/verifier-venv`, otherwise the existing
`/private/tmp/legendstudy-scoring-verifier-venv`. It verifies a dedicated venv with
psycopg before dispatching and preserves arguments, exit code and interactive stdin.
The Python runner must still run in an interactive terminal.

If no prepared venv exists, run `./tool/run_mock_grade_flutter_smoke.sh --setup`
once, then rerun the short command. Setup explicitly uses Python3 venv and pinned
psycopg[binary]3.2.10 in the stable external directory. No global pip install,
repository-vendored dependencies, automatic bootstrap on ordinary execution or
credential logs. A setup failure gives a safe, fixed explanation. The optional
venv override should be unset if it points to an obsolete environment.

Owner's later `python3 ...` ModuleNotFoundError for psycopg is a system-Python
execution-environment problem and does not invalidate D3 acceptance. Use the wrapper.
SUPABASE_SESSION_POOLER_HOST continues to load from external local JSON; only its
absence prompts for host. A/B and DB passwords remain getpass-only; Keychain is TODO.

Verification: six offline wrapper tests cover argument/exit preservation, missing
and broken environments, stable selection, explicit external setup and redaction.
Earlier49 Python fixture/config/diagnostic and15 Flutter regression PASS retained.
Shell/Python syntax, credential scan and diff checks PASS. No production call,
DB/schema/RPC/cleanup SQL or app/UI change in this closeout/tooling update.
