# AGENTS.md — LegendStudy

This file defines the operating rules for all AI agents working on LegendStudy.

## 1. Project boundary

LegendStudy is a standalone project. It must remain completely separate from Muselry in code, database, Supabase project, OAuth configuration, bundle identifiers, secrets, wiki, CI/CD, and deployment.

A simple WebView wrapper is not allowed. The app must be implemented as a real native mobile application experience.

## 2. Canonical reading order

Before changing code, database schema, ingestion, build configuration, or product behavior, read in this order:

1. `AGENTS.md`
2. `wiki/index.md`
3. `wiki/current-status.md`
4. Relevant task-specific wiki documents
5. Actual repository code, Git state, and current DB/Supabase state

Wiki is not authoritative when contradicted by verified runtime/code/database state. If a mismatch is found, verify the actual state and update the wiki.

## 3. Agent roles

### Codex — main coder
- Primary implementation agent.
- Owns feature coding, refactoring, tests, and implementation-level fixes.
- Should prefer small, reviewable changes over broad speculative rewrites.

### Claude — support coder / code reviewer
- Supports implementation when needed.
- Reviews Codex changes when requested or when risk is high.
- Focuses on correctness, regression risk, architecture consistency, and alternative solutions.

### ChatGPT — planning / architecture / review
- Owns product planning, requirements clarification, architecture review, DB/API design review, task decomposition, QA strategy, and cross-agent coordination.
- May provide code or patches when useful, but is not the default main implementation agent.

### Manus — execution / operations support
- Supports repository edits, command execution, Git operations, builds, release/deployment operations, and other execution-heavy tasks.
- Supabase direct work is not the default.
- Direct Supabase work by Manus is allowed only when explicitly judged useful for a specific task.

### User — product owner / Supabase executor
- Final product and scope decisions belong to the user.
- By default, the user directly executes Supabase SQL/migrations/commits because this is faster and easier to verify.
- Agents should provide exact SQL, migration instructions, validation queries, and rollback notes when Supabase changes are required.

## 4. Supabase policy

Default flow:

1. Agent designs the change.
2. Agent provides exact SQL/migration and validation steps.
3. User applies the Supabase change directly.
4. Agent verifies reported results against expected outcomes.
5. Repository migration files and wiki are updated accordingly.

Never assume a migration is deployed because a file exists in Git.
Never assume production schema matches migration history without verification.

## 5. Security

Never commit secrets or credentials.

Forbidden examples:
- service-role keys
- OAuth client secrets
- Apple private keys
- keystores and signing files
- private API keys
- production passwords

Public client identifiers and publishable/anon keys may only be committed when their exposure model has been explicitly verified.

## 6. Wiki discipline

The official long-term knowledge base is the repository-local `wiki/` directory.

Do not create competing canonical status documents elsewhere.

`wiki/current-status.md` must describe current implementation status and next actions. Do not hard-code a commit hash as a permanent definition of current HEAD.

`wiki/decisions.md` is for durable architectural/product decisions only, not routine task logs.

`wiki/log.md` is chronological and concise.

## 7. Work completion rule

A development task is not complete until all applicable items are done:

- implementation complete
- tests/checks executed where possible
- actual code/DB state verified
- `wiki/current-status.md` updated
- `wiki/log.md` updated
- affected wiki documents updated
- unresolved risks or manual steps explicitly recorded

## 8. Current product principles

- `legendstudy.com` remains the existing public content source.
- Mobile app UX is native, not a WebView clone.
- Public learning materials should be accessible without forcing login where possible.
- Login is primarily for personalization such as saved items, history, profile, and sync.
- Initial ingestion should normalize existing LegendStudy content into app-friendly structured data instead of scraping the website during normal app runtime.
