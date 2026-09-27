# Owner device QA follow-up — 2026-09-27

Status: IMPLEMENTED / Owner follow-up PASS for essay CTA, many exam PDFs, Home/meal, school/grade and basic profile/onboarding; remaining device items below.
Started at a549152. Independent onboarding UX commit4379636 arrived during work;
its files were preserved. No Production mutation, migration, schema/title/URL
rewrite, Materials publication, accepted-state write or1710 reconciliation.

## QA findings and fixes

| QA | Finding | Result |
|---|---|---|
|01 D-Day|Tiny text glyph chevrons and36px button|Whole label+24px icon remains tappable, minimum48px; explicit expand_more/less, wrapping at2× text|
|02 year gaps|Partial publication, not dropped query rows|DATA_NOT_YET_PUBLISHED; no publication or query change|
|03 titles|Existing display formatter missed CSAT suffix without hyphen|Reuse display-only formatter; `[2020년 12월 시행] 2021학년도 수능`; raw titles unchanged|
|04 essay CTA|Single canonical answer kind loses integrated-file meaning|Source-label evidence maps integrated problem+answer/explanation to 자료 보기; separate 답안 stays 답안 보기|
|05 profile save|Native maybePop was used within GoRouter shell|Confirmed success synchronously pops router; failed/pending/photo-partial stays; mounted/owner/current-route/completed guards preserved|
|06 school save|Same navigation plus independent academic-status save race|Router pop after school+grade success; pending/failed status blocks final Save until retry succeeds; status disabled during final Save|
|07 iOS relaunch|Owner's Flutter iOS debug-build launch restriction|No code/config change; use existing profile command below|
|08 고3 PDF|Stable cfile source with file_url=NULL cannot enter old direct branch|Narrow stable cfile PDF source fallback; no Production correction needed|

## Read-only Materials evidence

Production active51: exam33, essay8, study5, column5. Active exam calendar years:
2019:1,2020:3,2021:2,2024:1,2025:15,2026:11. Thus2022/2023 are not yet published;
2021 active samples are grade1, so a grade3 filter has further expected gaps.
Remaining193 includes57 exams:2021:13,2022:15,2023:15,2024:14. No next batch selected.

Guest App exam query uses content.is_active, optional exam filters, sort_date DESC
then content_item_id DESC; observed5-row pagination =5/5/5/5/5/5/3,33 distinct IDs.
General non-exam stream follows the exam stream. Recent Updates separately uses
published_at DESC,id DESC. Numeric search/filter uses calendar year, academic_year
is retained as source exam metadata:1447 is year2019/academic2020 (June2019 event),
1453 is year2020/academic2021 (December2020 CSAT). This boundary is not missing data.

Titles: source_posts1453 retains leading arrow/raw blog text; content_items removes
that decoration but retains SEO suffix. Existing materialDisplayTitle already
separates display from stored/search title across shared cards/detail/saved/recent.
Only its narrowly recognized CSAT suffix now accepts optional hyphen; unknown and
non-exam titles remain unchanged. No new display_title column or schema is needed.

1626 경기대 has3 active PDFs with labels `문제,답안.pdf` but resource_type=answer.
Parser picks one resource kind; no integrated kind exists in the current contract.
This is metadata classification loss exposed by literal UI mapping. Preserved
source_label is sufficient for truthful display without a canonical rewrite.
Display purpose uses source_label (title fallback), combines 문제 with 답안/정답/해설
as 자료, and labels a separate answer file containing 답안 as 답안. Group subtitles,
card labels, normal PDF and resolver CTA use the same presentation rule. Resolver
eligibility, canonical kinds, IDs and raw labels are not changed.

1447 resources:9 active PDF cfile links and1 Box audio landing page. The PDFs have
link_kind=file, file_extension=pdf, file_url=NULL, mime_type=NULL; no expiring
quarantine. Example Korean question ID18e30d27-0ad6-523f-b9d4-9be302f7f5e1,
key99FCCF455FBB3A5723; answer/explanation ID3d39fd9d-1c24-58d5-9d77-57c3c677bdea,
key996A023A5FBB3A5725. All9 actual HTTPS t1.daumcdn.net/cfile/tistory/<hex> URLs
returned206, application/pdf and %PDF header, unchanged URL/no redirect/query.
Only first8 bytes were read; no PDF files stored. Prior fallback reason was
missing file_url plus resolverCapable supporting only signed Kakao DNA identity.
1492 younger-grade sample instead has unknown link_kind, Kakao DNA identity and
resource_url_expiring advisory, making it eligible for the existing transient
resolver. This is provider/delivery shape, not a grade restriction.

New legacy route requires file kind, explicit PDF metadata, HTTPS/443 exact
`t1.daumcdn.net` host, exact `/cfile/tistory/<16–64 hex>` path, no query/fragment,
and absent file_url. It uses the existing URI/viewer/failure fallback. Arbitrary,
HTTP, signed, unknown and landing sources are not promoted; Box audio and Kakao
resolver remain unchanged. No button is fabricated for unsupported links.

## Navigation and validation

Confirmed means existing repository write Future succeeded; no new write/read-back
API or transaction was invented. Failed school/grade/status writes stay; final
status/save operations cannot overlap. Status editor is keyed separately per owner.
Standalone Navigator test surfaces retain pop support. Onboarding has its own
surface/navigation and unchanged shared repository; its independently authored
UX commit was not edited by this task.

Analyze PASS. Final focused50 PASS (QA9 plus D-Day/profile/school/onboarding
regressions). Full suite run848 PASS/1 pre-existing opt-in skip/3 failures.
Those same3 reproduce on a clean a549152 temporary baseline: day5_shell badge
expectation and materials_delivery_journey at1×/2× (outdated load-more expectations).
They are not new QA regressions. New2× D-Day overflow and duplicate widget key found
during development were fixed; final focused run has no failures. Full suite also
covers guest/auth, bookmarks/recent and includes concurrent onboarding tests.
No new regression observed; do not call the whole suite green. No iOS build run.

## Owner retest and profile launch

Retest D-Day label/icon tap and2× text; nickname success returns/failure stays;
school/status/grade success returns, status failure/retry stays safe; onboarding
still finishes through its own flow; CSAT short title; 경기대 integrated 자료 보기
and separate 문제/답안 buttons;1447 Korean question/answer PDFs and error fallback.
These changes need Owner device acceptance, distinct from prior Pilot PASS.

From the repository, existing verified wrapper/profile configuration:

```bash
./tool/flutterw run --profile \
  -d 00008101-001C39E02E61001E \
  --dart-define-from-file=/Users/woojinchang/legendstudy-local.json
```

Wrapper forwards arguments to pinned Flutter3.47.5. Keep local config private;
no Info.plist/project edits for debug relaunch. Stop here: no further Materials
batch, Production correction or reconciliation is authorized by this QA task.


## Owner follow-up: attribution and 부산대 guidebook

Owner reports most essay materials, integrated/separate CTA, many exam PDFs,
Home/NEIS meals, school/grade and basic profile/onboarding PASS. This does not
claim every PDF or every previous retest scenario passed.

Removed only the school/grade screen's `출처: 교육부·시도교육청 NEIS` footer.
NEIS identity, API response, repositories and reusable attribution widget remain.
No Info.plist/project setting change. Previous D-Day/title/CTA/navigation/cfile
fixes remain in this QA change set.

부산대 post1593 has one resource1b74fa0a-6de7-5f53-9385-2497db7d1305:
`2024학년도 부산대 논술가이드북(22-24기출 수록).pdf`, type=other,
link_kind=unknown, extension=pdf, file_url=NULL, signed Kakao DNA identity
`cODFT6/btsAzdEyA9A`. It is a guidebook, not a question/answer kind.

- Display: explicit 가이드북/guidebook label now displays 가이드북; other generic
  resources display 자료. If a valid direct target already exists, its CTA is
  가이드북 보기/자료 보기. This does not manufacture an openable target.
- Openability: fresh original-page attachment returned206, octet-stream and
  `%PDF-` first bytes. It is expiring/signed, not a stable URL eligible for cfile
  fallback. No signature/file was persisted, no quota-mutating resolver invoked.
- Contract: both client resolverCapable and server PDF_RESOURCE_TYPES currently
  accept question/answer/explanation/answer_explanation only. Thus type=other
  fails eligibility before refresh. Changing only the client would not fix it.
- Fallback: original https://legendstudy.com/1593 returned200 and contains the
  attachment. The App keeps its existing original-source fallback. Direct App
  opening remains blocked pending separate reviewed resolver-contract expansion
  and deployment; no backend deployment or Production metadata correction here.

Validation: analyze PASS;72 focused PASS. Full suite850 PASS/1 skip/3 failures:
unchanged day5_shell badge and materials_delivery_journey1×/2× expectations,
previously reproduced on a549152. The obsolete NEIS-footer dialog expectations
were updated to absence at1×/2×. Guest save test waits for its temporary login
Snackbar to expire before tapping Save; the removed footer changed its overlap,
not persistence semantics. No suppressed tap warning or app spacer workaround.
Owner retest: school footer absent; 부산대 guidebook caption and source fallback.
Previous unverified D-Day/edge navigation/profile-launch scenarios remain pending.
