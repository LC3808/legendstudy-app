# Day 7 School + NEIS Meals — COMPLETE

## Final acceptance (2026-09-13)

Product Owner reports School + NEIS Meals complete: school selection migration
20260913000100_profile_school_selection.sql applied to LegendStudy; actual JWT/RLS
legacy upsert, school pair save/select/clear, name/grade preservation and A/B ownership
isolation PASS. Profile fixtures cleaned; Auth users retained.

NEIS_API_KEY registered server-side and neis deployed to stlhijzpjfgwwdgunlsd.
Actual deployed proxy: 진접고등학교 J10/7530932 search PASS; 2026-09-11 meal 1 row
PASS; 2026-09-13 normal empty PASS. Actual Flutter guest search, school selection,
Home school name and meal empty state PASS. These are owner-run results recorded
at closeout, not a new production execution by Codex.

Home refinement is complete: school name/action share a row, no Home attribution;
school setup retains compact meta attribution with an information dialog. The final
D-Day runtime also confirms profile/school fields preserved and fixtures cleaned.
Day 7 = COMPLETE; next stage = Day 8 Study. Release quota/abuse controls and OAuth
runtime remain separate follow-up work, not uncompleted Day 7 implementation.

## Official contract and key decision (2026-09-13)

- [NEIS terms](https://open.neis.go.kr/portal/userAgreementPage.do), Article 7:
  an issued key must not be disclosed/shared with others. We choose server-side
  storage (option B). Flutter defines/bundles are extractable and cannot hold it.
- [School API](https://open.neis.go.kr/portal/data/service/selectServicePage.do?infId=OPEN17020190531110010104913&infSeq=2):
  /hub/schoolInfo, SCHUL_NM or ATPT_OFCDC_SC_CODE + SD_SCHUL_CODE;
  output SCHUL_NM, SCHUL_KND_SC_NM, ORG_RDNMA plus those identifiers.
- [Meal API](https://open.neis.go.kr/portal/data/service/selectServicePage.do?infId=OPEN17320190722180924242823&infSeq=2):
  /hub/mealServiceDietInfo, the identifier pair + MLSV_YMD (yyyyMMdd);
  output MMEAL_SC_NM, MLSV_YMD, DDISH_NM. INFO-200 is normal empty;
  INFO-000 is success. Other/error/malformed responses fail safely.
- During initial contract research, no-key access was limited
  to five sample rows. Read-only samples confirmed J10/7530932 (진접고등학교),
  one 20260911 lunch, and 20260913 INFO-200. That initial sample check used no key;
  keyed deployed proxy and guest acceptance subsequently passed as recorded above.
- Source attribution is shown only in school setup UI, not Home. Menu parsing only splits br
  variants/newlines and trims whitespace; it does not invent allergy/nutrition data.

## Deployed server function

Files: supabase/functions/neis/{index.ts,handler.ts,handler_test.ts} and
supabase/config.toml. Public GET endpoint, no login prerequisite, fixed upstream
host/path, allowlisted query parameters, <=100 rows, search <=100 characters,
identifier 1..32 trimmed characters, validated calendar date and 10s upstream
network timeout. Only required fields are returned. No upstream URL/key/error
logging, redirects, arbitrary proxy targets, DB access or service-role use.
Client timeout is 15s. Missing server key is 503, never sample fallback.

Production path: https://stlhijzpjfgwwdgunlsd.supabase.co/functions/v1/neis

- action=search&q=<school name>
- action=school&office=<office code>&school=<school code>
- action=meals&office=<office code>&school=<school code>&date=<yyyyMMdd>

Response is {"rows": [...]} containing the allowlisted NEIS field names; the
Flutter data adapter maps these into School/Meal, never exposing transport JSON
in presentation. Each search shows at most the first 100; refine the query when
that limit is reached. No unbounded pagination or persistent catalogue/cache.

## Deployment procedure and release follow-up reference

Secret/deployment/runtime steps are completed; release quota/throttling assessment
remains follow-up work. The steps below are retained as an operational reference.

1. Review public read-only scope and register an issued NEIS key for this service.
2. In the dedicated project's Edge Function secrets, set NEIS_API_KEY. Never put
   it in Flutter config, source, screenshots, shell arguments, logs or Git.
3. Deploy function `neis` with index.ts/handler.ts and verify_jwt=false as in
   config.toml. This is required for guests; the publishable apikey is not a user
   JWT and is not a secret or abuse-prevention boundary. Function returns public
   school/meal data only. No SQL or additional DB grants are required.
4. Owner should assess NEIS quota and gateway-wide throttling before public
   release. Bounded request size/timeouts do not provide global rate limiting.
   No Redis/schema/provider account is provisioned by this implementation.
5. Return deployment status without any key. Then run keyed school/meal/empty
   smoke through the deployed function and actual Flutter guest flow. Retry/errors
   must remain local to the card, and name/type/address disambiguation must work.

Reference: [Supabase public functions](https://supabase.com/docs/guides/functions/auth)
and [server secrets](https://supabase.com/docs/guides/functions/secrets).
Deployment is confirmed by owner CLI/proxy results, not inferred from file presence.

## Actual school JWT acceptance — PASS

Owner executed the real login JWT acceptance, confirming legacy profile upsert,
NEIS pair save/select/clear, name/grade preservation, profile updates preserving
school selection, partial-pair CHECK violation and A/B ownership isolation.
Cleanup PASS; Auth users retained. The harness remains tool/verify_school_jwt.py
for repeat checks using owner-controlled external account configuration.

Mock payload tests and SQL Editor SET ROLE are not the live acceptance evidence;
the actual JWT/REST and deployed proxy results above close these gates. Code,
server secret and schema were not changed in this documentation closeout.
