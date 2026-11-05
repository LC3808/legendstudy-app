# APP Analytics release preparation — 2026-11-05

Owner requested implementation and release preparation; existing Firebase service/collection gate reused. Isolated branch codex/app-ga4-usage-20261105, base142d0d5. Do not overwrite the active candidate's unrelated changes; merge this reviewed commit into the coordinated release candidate. Store upload/submission remains Owner-owned.

## Contract

Committed finite menu navigation: screen_view + menu_view(menu_id,schema_version1). Same path/query rebuilds do not count; actual return visits do. Real GoRouter push/pop integration is tested. Successful material detail: material_open(content_item_id canonical Registry UUID,entry_source,schema_version1), once per navigation instance; no failed-load event. Entry source materials distinguishes the library tab. No raw path/query/email/answers/search text is added. Existing analytics identity policy stays unchanged.

`Firebase.initializeApp` uses public platform-specific Dart defines. Missing config or initialization failure retains the existing no-op behavior. Native automatic screen reporting disabled so manual finite screens own the definition. Collection is enabled once after successful configured bootstrap, never in each event call.

## Live configuration and evidence

- Firebase legendstudyplus, project323039160298.
- GA property562560908, timezoneAsia/Seoul. Existing WEB property396674471 untouched.
- iOS com.legendstudy.app stream16278486227; Android same package stream16278789792.
- Event-scoped menu_id/content_item_id/entry_source dimensions registered.
- Existing server reader received approved Viewer with cost/revenue excluded; no email notification.
- 21:46 KST isolated iOS simulator received screen_view2/menu_view2/material_open1 in GA DebugView. Synthetic Registry00000000-0000-4000-8000-000000000001, source materials. Debug-only tool/analytics_smoke.dart never calls Supabase, submits evaluations or executes transactions.
- Actual WEB implementation read GA metadata and batch reports successfully at21:55. All dimensions registered; regular reports empty (수집 대기), separate from DebugView. No claims of AppStore production event receipt.

## Release configuration

Ignored config/analytics-ios.local.json and analytics-android.local.json contain only five public analytics settings. Never commit local config or service credential. Prepare a NEW merged complete release config:

```
python3 tool/prepare_analytics_config.py ios --base config/store-rc.local.json --analytics config/analytics-ios.local.json --output config/store-analytics-ios.local.json
python3 tool/store-release ios --config config/store-analytics-ios.local.json --check
```

Use android for Android. Script rejects wrong project/platform and overwriting output, preserves unrelated flags. The existing Store tool builds lib/main.dart; never use the smoke target in release. Complete final signing, production-config review, privacy declaration/consent review and latest release integration before upload. A build does not install or submit.

WEB server settings: GA4_APP_PROPERTY_ID=562560908, GA4_APP_STREAM_IDS=16278486227,16278789792; reuse existing credential. Backend keeps operator authorization, platform filters and Registry RLS. UI shows activeUsers rolling1/7/30; menusTOP10 totalUsers/eventCount separately; materialsTOP20 eventCount from materials source. Missing connection/dimensions, collection pending and errors are distinguished. Existing Supabase member-based rankings remain separately labelled. No SQL/RPC change.

## Seven preservation answers

1. GA timestamps retain behavioral occurrence; report retrieval time is separate.
2. GA retention limits reconstruction; telemetry is not immutable academic evidence.
3. No existing rows/history are updated.
4. Canonical auth/student identity unchanged; GA users are not asserted to be members.
5. Navigation is service behavior, not admission decisions or learning outcomes.
6. Finite keys/public RegistryID; existing collection gate, least-privilege access and operator gate retained. No new PII/user-ID collection. No retention expansion.
7. Counts/rankings are derived metrics with source/date/timezone and threshold/sampling warnings, not academic raw facts.

## Verification and limitations

- Flutter targeted analytics/navigation/material tests26PASS; scoped analyzerPASS.
- iOS simulator debug build and actual Firebase transportPASS.
- WEB production build163pages previouslyPASS, targeted report/UI tests and real API contractPASS.
- Device Release build first failed from disk exhaustion; temporary QA simulator/build outputs were removed, preserving APP58 and other task artifacts. Final build result recorded at handoff.
- No production DB/evaluation/credit/payment/refund actions. No Store change. Android actual receipt and signed Store artifacts require separate evidence.

22:07 KST main lib/main.dart iOS Release build PASS (unsigned compile artifact43.4MB). Compiled defines verified ANALYTICS_ENABLED=true/projectlegendstudyplus/iOSapp identity; automatic screen reporting false. Version0.1.0+1 is repository-default compile verification, NOT a Store upload artifact. Final release version/signing must come from the coordinated candidate. Local complete config preserved existing12 fields and passed store-release --check. Android Kotlin daemon encountered disk-full logging deadlock; recovery tracked separately.

Android arm64 debug smoke buildPASS after recovering the disk-full Kotlin daemon. Build warnings about existing Flutter/AGP/Kotlin versions are not source regressions; versions unchanged. Android device/DebugView receipt has not been observed. WEB Functions compilePASS.

Final Android lib/main.dart arm64 debug APK buildPASS (23.8s). APK kernel verified project and menu/material/Registry event markers. This is QA debug signing, not Store AAB. iOS unsigned Release and Android debug are compile artifacts only. No device install/upload was performed after isolated iOS transport QA.
