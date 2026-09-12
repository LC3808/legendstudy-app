# Feature boundaries

Each feature owns its `presentation/` widgets and future Riverpod controllers.
Add `domain/` for plain Dart entities and repository contracts when the feature
has real behavior, and `data/` for implementations, DTOs and remote/local sources.
Presentation may depend on domain; data implements domain contracts. Domain must
not import Flutter or backend SDKs. Compose implementations through Riverpod.

The Day 1 shell has no data or business rules; empty repositories and speculative
models are intentionally deferred until content requirements are verified.
Shared UI lives in `lib/shared/widgets`; application composition in `lib/app`;
configuration and design tokens in `lib/core`.
