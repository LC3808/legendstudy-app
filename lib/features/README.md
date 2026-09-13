# Feature boundaries

Each feature owns its `presentation/` widgets and future Riverpod controllers.
Add `domain/` for plain Dart entities and repository contracts when the feature
has real behavior, and `data/` for implementations, DTOs and remote/local sources.
Presentation may depend on domain; data implements domain contracts. Domain must
not import Flutter or backend SDKs. Compose implementations through Riverpod.

Day 4-A content/domain owns ContentItem and ContentRepository; content/data maps
explicit public projections. personal/domain and personal/data own profile, bookmark
and recent-view contracts/implementations. Providers inject dependencies and expose
content AsyncValue states. AuthStatus contains user identity only, never JWTs.
Home/Materials consume those boundaries. Day 5 adds Study idle UI and an Auth-aware
MY shell, reuses Saved under MY and reserves root navigation for material detail.
School, timer persistence, OAuth, ads and purchases remain unconnected.
Shared UI lives in `lib/shared/widgets`; application composition in `lib/app`;
configuration and design tokens in `lib/core`.
