# Day 7 NEIS transport and remaining acceptance

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
- Official pages require an issued key for actual use; no-key access is limited
  to five sample rows. Read-only samples confirmed J10/7530932 (진접고등학교),
  one 20260911 lunch, and 20260913 INFO-200. No issued key was used.
- Source attribution is shown in school and meal UI. Menu parsing only splits br
  variants/newlines and trims whitespace; it does not invent allergy/nutrition data.

## Prepared server function — NOT deployed

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

## Owner deployment steps

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
Function files and tests are prepared; their presence does NOT imply deployment.

## Actual JWT acceptance — NOT run yet

The owner authorized temporary client fixtures but has not supplied existing A/B
account credentials for this run. Use external JSON files, never committed fixtures:

- Public config: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY (existing owner file).
- Separate external account config: TEST_A_EMAIL, TEST_A_PASSWORD,
  TEST_B_EMAIL, TEST_B_PASSWORD. Do not add these to Dart defines.

Run `python3 tool/verify_school_jwt.py <external-public-config> <external-accounts>`.
The harness restricts the target project, signs into existing A/B accounts, refuses
pre-existing own profile rows, checks legacy upsert, pair save/select/clear,
name/grade and pair preservation, SQLSTATE 23514 for a partial pair and actual
JWT A/B read/update isolation. It never executes SQL or uses admin credentials.
Only this run's profile rows are deleted in finally, including uncertain-write
cleanup; auth users are retained. Failures print no credential/error details.
A cleanup failure requires owner follow-up. Use disposable test accounts only and
avoid concurrent use of their profiles during the acceptance run.

No production fixtures were written in the present implementation task. Mock HTTP
payload and provider account-switch tests are NOT evidence of production RLS.
SQL Editor SET ROLE alone is also insufficient. Do not mark Day 7 live acceptance
or Day 8 readiness complete until actual proxy and JWT results are recorded.
