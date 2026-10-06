# Migration ledger — versions applied outside this repository

The Supabase project's `supabase_migrations.schema_migrations` is the real ledger.
Some versions in it were applied directly to Production and have **no file in this
repository**, so reading the repository alone does not tell you which versions are
taken. This file records them.

## Rule

Before choosing a version for a new migration, check:

1. the highest version present in `supabase/migrations/`, and
2. the table below.

Pick a version strictly above both. Never replay or overwrite a version that is
already applied: Supabase records it as applied and will skip a changed file, so a
silent divergence is the failure mode, not an error.

## Reserved / externally applied

| Version | Name | State | Notes |
| --- | --- | --- | --- |
| `20261005000100` | `account_provider_revocation` | applied in Production | present in this repository (`claude/app-release-blocker-closeout-1`) |
| `20261005000200` | `account_ops_sink` | applied in Production | **no file in this repository** — applied by the account-lifecycle workstream |
| `20261006000100` | `math_attempts_cascade_on_profile_delete` | ready, not applied | present in this repository (`claude/app-release-blocker-closeout-1`) |

## The admin console block

The admin console work was originally written at `20261005000200`. That version is
now `account_ops_sink` in Production, so the admin migrations were moved to a cleared
block:

| Version | Name |
| --- | --- |
| `20261007000100` | `admin_console_read` |
| `20261007000200` | `admin_console_p0b` |
| `20261007000300` | `user_notification_center` |
| `20261007000400` | `admin_console_p0c` |

`20261007000100`–`20261007009900` is the admin/notification console block. Reserve
versions inside it for this workstream instead of starting a new one.
