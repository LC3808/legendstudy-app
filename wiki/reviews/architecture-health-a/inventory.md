# Cross Review A — live inventory appendix

Captured: `2026-09-30T12:48:43.3379+00:00`; `transaction_read_only=on`.

[Main report](../../platform-architecture-health-review-a.md). [Sanitized catalog](catalog.json) includes all columns, constraints, indexes, policies, triggers, ACLs and function signature/body MD5. Full function source was inspected locally and reconciled with migrations; no application rows or secrets are exported. Query sources are read-only catalog queries, **not migrations**.

## All 44 relations — 43 LIVE tables + 1 LIVE view

Usage means a code/RPC reference was found, not proof of production traffic. `NO_REFERENCE_FOUND` is not permission to delete. All tables have RLS enabled; none FORCE RLS. Trusted owner/BYPASSRLS roles remain privileged. View uses `security_invoker=true`.

### `public.admin_users`

- Domain: ADMIN; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: Feedback operator allowlist; global staff roles 아님.
- Write path: operator SQL/service administration.
- History: current membership only.
- RLS: `True`; policies: none (no client policy).
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 2/1; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.answer_key_versions`

- Domain: ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 공식 정답 publication/version/source.
- Write path: ops publication + guards.
- History: versioned source/current constraints.
- RLS: `True`; policies: answer_key_versions_public_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (exam_subject_id, content_item_id) REFERENCES exam_subjects(id, content_item_id) ON DELETE RESTRICT.
- Constraints/indexes: 23/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.bookmarks`

- Domain: CONTENT; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 사용자 자료 저장 선택.
- Write path: OWNER-RLS client.
- History: current unique user/content; deletion allowed.
- RLS: `True`; policies: bookmarks_owner_delete, bookmarks_owner_insert, bookmarks_owner_select.
- Client table ACL: authenticated:DELETE, authenticated:SELECT.
- Relationships: FOREIGN KEY (content_item_id) REFERENCES content_items(id) ON DELETE RESTRICT; FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 4/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.content_items`

- Domain: CONTENT; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 공개 자료의 catalog identity/type.
- Write path: ops ingestion.
- History: source reference + mutable publication metadata.
- RLS: `True`; policies: content_items_public_active_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (merged_into_content_item_id) REFERENCES content_items(id) ON DELETE RESTRICT; FOREIGN KEY (source_post_id) REFERENCES source_posts(id) ON DELETE RESTRICT.
- Constraints/indexes: 13/5; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.credit_accounts`

- Domain: CREDIT; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 사용자 credit account identity; balance 자체 아님.
- Write path: server RPC/trigger.
- History: account retained; owner deletion SET NULL.
- RLS: `True`; policies: credit_accounts_owner_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL.
- Constraints/indexes: 3/2; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.credit_grants`

- Domain: CREDIT; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 수량·origin·expiry를 가진 지급 lot.
- Write path: internal credit_post_grant / finance RPC.
- History: immutable grant; transaction provenance.
- RLS: `True`; policies: credit_grants_owner_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (account_id) REFERENCES credit_accounts(id) ON DELETE RESTRICT.
- Constraints/indexes: 6/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.credit_transactions`

- Domain: CREDIT; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 증감·예약·해제·소비·환불 ledger fact.
- Write path: server-authoritative RPC.
- History: append-only/idempotency/reversal.
- RLS: `True`; policies: credit_transactions_owner_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (account_id) REFERENCES credit_accounts(id) ON DELETE RESTRICT; FOREIGN KEY (decision_id, account_id) REFERENCES essay_billing_decisions(id, account_id) ON DELETE RESTRICT; FOREIGN KEY (grant_id, account_id) REFERENCES credit_grants(id, account_id) ON DELETE RESTRICT; FOREIGN KEY (reversal_of, account_id) REFERENCES credit_transactions(id, account_id) ON DELETE RESTRICT.
- Constraints/indexes: 10/6; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.day_targets`

- Domain: LEARNING; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 복수 일정과 current primary 선택.
- Write path: OWNER-RLS client.
- History: mutable current rows, no event history.
- RLS: `True`; policies: day_targets_owner_delete, day_targets_owner_insert, day_targets_owner_select, day_targets_owner_update.
- Client table ACL: anon:DELETE, anon:INSERT, anon:MAINTAIN, anon:REFERENCES, anon:SELECT, anon:TRIGGER, anon:TRUNCATE, anon:UPDATE, authenticated:DELETE, authenticated:INSERT, authenticated:MAINTAIN, authenticated:REFERENCES, authenticated:SELECT, authenticated:TRIGGER, authenticated:TRUNCATE, authenticated:UPDATE.
- Relationships: FOREIGN KEY (owner_id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 4/3; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.essay_ai_processing_runs`

- Domain: AI PROCESSING; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 각 physical processing attempt/lease/telemetry.
- Write path: essay_worker RPC.
- History: run_no, selected-result uniqueness, terminal guards.
- RLS: `True`; policies: none (no client policy).
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (evaluation_id) REFERENCES essay_evaluations(id) ON DELETE CASCADE; FOREIGN KEY (rewrite_id) REFERENCES essay_generated_rewrites(id) ON DELETE CASCADE.
- Constraints/indexes: 22/6; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_attempts`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 학생 제출 원문·hash·attempt order·당시 조건.
- Write path: essay_submit_attempt.
- History: immutable submission; session erase cascade.
- RLS: `True`; policies: essay_attempts_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (session_id) REFERENCES essay_practice_sessions(id) ON DELETE CASCADE.
- Constraints/indexes: 17/5; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_billing_decisions`

- Domain: BILLING; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 평가별 paid/included/reserve/settlement 결정.
- Write path: request/finalize/reconcile RPC.
- History: versioned decision, parent paid linkage, ledger retention.
- RLS: `True`; policies: essay_billing_decisions_owner_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (account_id) REFERENCES credit_accounts(id) ON DELETE RESTRICT; FOREIGN KEY (evaluation_id) REFERENCES essay_evaluations(id) ON DELETE SET NULL; FOREIGN KEY (included_by_decision_id, account_id) REFERENCES essay_billing_decisions(id, account_id) ON DELETE RESTRICT.
- Constraints/indexes: 16/6; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_drafts`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 제출 전 editable working copy.
- Write path: essay_save_draft optimistic revision.
- History: current draft revision, not submitted history.
- RLS: `True`; policies: essay_drafts_delete, essay_drafts_insert, essay_drafts_read, essay_drafts_update.
- Client table ACL: authenticated:DELETE, authenticated:INSERT, authenticated:SELECT, authenticated:UPDATE.
- Relationships: FOREIGN KEY (session_id) REFERENCES essay_practice_sessions(id) ON DELETE CASCADE.
- Constraints/indexes: 6/1; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_evaluation_criteria`

- Domain: ESSAY EVIDENCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 문항별 official/derived 기준·weight·근거.
- Write path: ops reviewed publication.
- History: mapping/version/source; official_weight nullable.
- RLS: `True`; policies: essay_evaluation_criteria_read.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: FOREIGN KEY (question_id) REFERENCES essay_questions(id) ON DELETE RESTRICT; FOREIGN KEY (source_evidence_id, question_id) REFERENCES essay_question_evidence(id, question_id).
- Constraints/indexes: 10/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_evaluation_dimensions`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 평가별 criterion 진단/level/explanation.
- Write path: strict finalize RPC.
- History: immutable evaluation child.
- RLS: `True`; policies: essay_evaluation_dimensions_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (criterion_id, question_id) REFERENCES essay_evaluation_criteria(id, question_id) ON DELETE RESTRICT; FOREIGN KEY (evaluation_id, question_id) REFERENCES essay_evaluations(id, question_id) ON DELETE CASCADE.
- Constraints/indexes: 8/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_evaluation_evidence`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 평가 결과가 실제 참조한 evidence relation.
- Write path: strict finalize RPC.
- History: immutable evaluation child, reference integrity.
- RLS: `True`; policies: essay_evaluation_evidence_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (dimension_id, evaluation_id) REFERENCES essay_evaluation_dimensions(id, evaluation_id) ON DELETE CASCADE; FOREIGN KEY (evaluation_id, question_id) REFERENCES essay_evaluations(id, question_id) ON DELETE CASCADE; FOREIGN KEY (evidence_id, question_id) REFERENCES essay_question_evidence(id, question_id) ON DELETE RESTRICT; FOREIGN KEY (improvement_progress_id, evaluation_id) REFERENCES essay_improvement_progress(id, evaluation_id) ON DELETE CASCADE.
- Constraints/indexes: 7/2; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_evaluations`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: logical evaluation request + accepted result.
- Write path: request/claim/finalize/timeout RPC.
- History: terminal immutable result, supersession/invalidation.
- RLS: `True`; policies: essay_evaluations_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (attempt_id, session_id) REFERENCES essay_attempts(id, session_id) ON DELETE CASCADE; FOREIGN KEY (session_id, question_id) REFERENCES essay_practice_sessions(id, question_id) ON DELETE CASCADE; FOREIGN KEY (supersedes_evaluation_id, attempt_id) REFERENCES essay_evaluations(id, attempt_id) ON DELETE SET NULL (supersedes_evaluation_id).
- Constraints/indexes: 23/8; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_exam_resources`

- Domain: ESSAY EVIDENCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 시험에 속한 공식 자료 role/source relation.
- Write path: ops publication.
- History: source/page metadata; canonical resource reuse.
- RLS: `True`; policies: essay_exam_resources_public_select.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: FOREIGN KEY (essay_exam_id) REFERENCES essay_exams(id) ON DELETE RESTRICT; FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE RESTRICT.
- Constraints/indexes: 9/2; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_exams`

- Domain: ESSAY EVIDENCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 대학별 연도/전형/회차 essay exam identity.
- Write path: ops publication.
- History: stable exam key, university FK, metadata version.
- RLS: `True`; policies: essay_exams_public_select.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: FOREIGN KEY (metadata_resource_id) REFERENCES resources(id) ON DELETE RESTRICT; FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE RESTRICT.
- Constraints/indexes: 19/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_generated_rewrites`

- Domain: ESSAY; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: AI 예시 재작성 artifact; 학생 답안 아님.
- Write path: request_rewrite + worker finalize.
- History: evaluation-bound separate result lifecycle.
- RLS: `True`; policies: essay_generated_rewrites_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (evaluation_id) REFERENCES essay_evaluations(id) ON DELETE CASCADE.
- Constraints/indexes: 8/2; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.essay_improvement_items`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 학생 session 내 실제 improvement root.
- Write path: strict finalize RPC.
- History: stable issue identity, immutable roots.
- RLS: `True`; policies: essay_improvement_items_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (session_id) REFERENCES essay_practice_sessions(id) ON DELETE CASCADE.
- Constraints/indexes: 10/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_improvement_progress`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: evaluation 시점별 issue progress + scaffolding observation.
- Write path: strict finalize RPC.
- History: previous_progress chain; retained observations.
- RLS: `True`; policies: essay_improvement_progress_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (evaluation_id, session_id) REFERENCES essay_evaluations(id, session_id) ON DELETE CASCADE; FOREIGN KEY (issue_id, session_id) REFERENCES essay_improvement_items(id, session_id) ON DELETE CASCADE; FOREIGN KEY (previous_progress_id, issue_id) REFERENCES essay_improvement_progress(id, issue_id) ON DELETE SET NULL (previous_progress_id).
- Constraints/indexes: 11/6; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_learning_events`

- Domain: ESSAY EVENTS; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **NO_REFERENCE_FOUND (writer)**.
- Purpose / canonical fact: rewrite-start/example-view/source-open interaction.
- Write path: server/ops grants; production writer not found.
- History: event_key dedupe; not canonical resolution.
- RLS: `True`; policies: essay_learning_events_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (attempt_id, session_id) REFERENCES essay_attempts(id, session_id) ON DELETE CASCADE; FOREIGN KEY (evaluation_id, attempt_id) REFERENCES essay_evaluations(id, attempt_id) ON DELETE CASCADE; FOREIGN KEY (session_id) REFERENCES essay_practice_sessions(id) ON DELETE CASCADE; FOREIGN KEY (stage_attempt_id, session_id) REFERENCES essay_attempts(id, session_id) ON DELETE CASCADE.
- Constraints/indexes: 10/5; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.essay_practice_sessions`

- Domain: ESSAY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 학생·문항 learning cycle identity.
- Write path: essay_open_session/erase.
- History: parent of drafts/attempts/evaluations.
- RLS: `True`; policies: essay_practice_sessions_read.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (question_id) REFERENCES essay_questions(id) ON DELETE RESTRICT; FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE.
- Constraints/indexes: 5/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_question_evidence`

- Domain: ESSAY EVIDENCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 문항 범위 evidence role/locator/source/version.
- Write path: ops reviewed publication.
- History: hash/mapping version, composite FK boundaries.
- RLS: `True`; policies: essay_question_evidence_read.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: FOREIGN KEY (essay_exam_id, resource_id, role) REFERENCES essay_exam_resources(essay_exam_id, resource_id, role) ON DELETE RESTRICT; FOREIGN KEY (question_id, essay_exam_id) REFERENCES essay_questions(id, essay_exam_id) ON DELETE RESTRICT.
- Constraints/indexes: 7/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.essay_questions`

- Domain: ESSAY EVIDENCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 시험 내 문항 identity/requirements/publication.
- Write path: ops publication.
- History: metadata version/identity guards.
- RLS: `True`; policies: essay_questions_read.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: FOREIGN KEY (essay_exam_id) REFERENCES essay_exams(id) ON DELETE RESTRICT.
- Constraints/indexes: 11/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.exam_questions`

- Domain: ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 정답 version별 문항·배점.
- Write path: ops publication guards.
- History: version-scoped immutable published key.
- RLS: `True`; policies: exam_questions_public_select.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: FOREIGN KEY (answer_key_version_id) REFERENCES answer_key_versions(id) ON DELETE RESTRICT.
- Constraints/indexes: 6/1; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.exam_subjects`

- Domain: CONTENT / ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 시험 과목/variant 및 raw→normalized mapping.
- Write path: ops ingestion/publication.
- History: raw label, taxonomy/rule version preserved.
- RLS: `True`; policies: exam_subjects_public_active_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (content_item_id) REFERENCES exams(content_item_id) ON DELETE RESTRICT; FOREIGN KEY (subject_id, taxonomy_version) REFERENCES subjects(id, taxonomy_version) MATCH FULL ON DELETE RESTRICT.
- Constraints/indexes: 10/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.exams`

- Domain: CONTENT / ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 모의고사/수능 시험 identity/year/date/grade.
- Write path: ops ingestion.
- History: calendar/academic year and raw labels separated.
- RLS: `True`; policies: exams_public_active_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (content_item_id, content_type) REFERENCES content_items(id, content_type) ON DELETE RESTRICT.
- Constraints/indexes: 8/2; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.feedback_notifications`

- Domain: OPERATIONS; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: feedback notification delivery job/lease.
- Write path: trigger + service_role worker RPC.
- History: delivery attempt/terminal/error history fields.
- RLS: `True`; policies: none (no client policy).
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (feedback_id) REFERENCES feedback_submissions(id) ON DELETE CASCADE.
- Constraints/indexes: 10/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.feedback_submissions`

- Domain: OPERATIONS; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 사용자 feedback/moderation record.
- Write path: owner client insert / admin RLS.
- History: current moderation state; not general audit log.
- RLS: `True`; policies: feedback_admin_select, feedback_admin_status, feedback_insert_guest, feedback_insert_owner, feedback_owner_select.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL.
- Constraints/indexes: 11/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.grade_cutoff_versions`

- Domain: ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 공식/예상 cutoff source/version/certainty.
- Write path: ops publication.
- History: versioned with provenance.
- RLS: `True`; policies: grade_cutoff_versions_public_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (exam_subject_id, content_item_id) REFERENCES exam_subjects(id, content_item_id) ON DELETE RESTRICT.
- Constraints/indexes: 24/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.ingestion_quarantine`

- Domain: CONTENT OPS; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 검증 실패 source/material candidate.
- Write path: ops importer.
- History: raw payload/reason/review status; not analytics.
- RLS: `True`; policies: none (no client policy).
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (source_post_id) REFERENCES source_posts(id) ON DELETE RESTRICT.
- Constraints/indexes: 6/1; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.mock_exam_answers`

- Domain: ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 자기채점 제출 선택지 + correctness snapshot.
- Write path: submit_mock_attempt RPC.
- History: immutable attempt child with source key version.
- RLS: `True`; policies: mock_exam_answers_owner_select.
- Client table ACL: authenticated:SELECT.
- Relationships: FOREIGN KEY (attempt_id, answer_key_version_id) REFERENCES mock_exam_attempts(id, answer_key_version_id) ON DELETE CASCADE; FOREIGN KEY (answer_key_version_id, question_number) REFERENCES exam_questions(answer_key_version_id, question_number) ON DELETE RESTRICT.
- Constraints/indexes: 7/1; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.mock_exam_attempts`

- Domain: ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 자기채점 제출/결과/정답·등급기준 binding.
- Write path: submit_mock_attempt RPC.
- History: raw answers + derived score/version, owner history.
- RLS: `True`; policies: mock_exam_attempts_owner_delete, mock_exam_attempts_owner_select.
- Client table ACL: authenticated:DELETE.
- Relationships: FOREIGN KEY (grade_cutoff_version_id, exam_subject_id, paper_variant, max_score) REFERENCES grade_cutoff_versions(id, exam_subject_id, paper_variant, max_score) ON DELETE RESTRICT; FOREIGN KEY (answer_key_version_id, exam_subject_id, paper_variant, max_score) REFERENCES answer_key_versions(id, exam_subject_id, paper_variant, max_score) ON DELETE RESTRICT; FOREIGN KEY (study_session_id, user_id) REFERENCES study_sessions(id, user_id) ON DELETE SET NULL (study_session_id); FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 21/6; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.mock_exam_scoring_availability`

- Domain: ACADEMIC; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 현재 채점 가능한 source version projection.
- Write path: VIEW, no independent write.
- History: derived current availability, security_invoker.
- RLS: `False`; policies: none (no client policy).
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: no FK; identity/derived relation documented above.
- Constraints/indexes: 0/0; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.profiles`

- Domain: IDENTITY / PREFERENCES; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: auth identity extension and current personal/school setting.
- Write path: owner RLS constrained columns / signup trigger.
- History: current projection; school/context history missing.
- RLS: `True`; policies: profiles_owner_delete, profiles_owner_insert, profiles_owner_select, profiles_owner_update.
- Client table ACL: authenticated:DELETE, authenticated:SELECT.
- Relationships: FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 7/1; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.recent_views`

- Domain: CONTENT; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 사용자의 최근 자료 열람 시각.
- Write path: OWNER-RLS client upsert.
- History: latest projection, not full reading event history.
- RLS: `True`; policies: recent_views_owner_delete, recent_views_owner_insert, recent_views_owner_select, recent_views_owner_update.
- Client table ACL: authenticated:DELETE, authenticated:SELECT.
- Relationships: FOREIGN KEY (content_item_id) REFERENCES content_items(id) ON DELETE RESTRICT; FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 4/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.resource_resolver_quota`

- Domain: OPERATIONS; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: resource resolver abuse/rate quota counter.
- Write path: service_role quota RPC.
- History: bounded operational counter, not learning metric.
- RLS: `True`; policies: none (no client policy).
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: no FK; identity/derived relation documented above.
- Constraints/indexes: 3/2; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.resources`

- Domain: CONTENT / SOURCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 자료 file/link identity, source label/status.
- Write path: ops ingestion/resolver.
- History: source reference + raw label; derivative provenance via package.
- RLS: `True`; policies: resources_public_active_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (content_item_id) REFERENCES content_items(id) ON DELETE RESTRICT; FOREIGN KEY (source_post_id) REFERENCES source_posts(id) ON DELETE RESTRICT; FOREIGN KEY (exam_subject_id, content_item_id) REFERENCES exam_subjects(id, content_item_id) ON DELETE RESTRICT.
- Constraints/indexes: 14/4; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.source_posts`

- Domain: CONTENT SOURCE; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 수집한 원래 게시물/source/parser provenance.
- Write path: ops ingestion.
- History: content hash/parser version/source metadata.
- RLS: `True`; policies: none (no client policy).
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: no FK; identity/derived relation documented above.
- Constraints/indexes: 10/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.student_target_universities`

- Domain: ADMISSION PREFERENCE; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **LIKELY_USED**.
- Purpose / canonical fact: 학생의 현재 관심 대학/연도.
- Write path: OWNER-RLS client.
- History: current preference, not application/outcome ledger.
- RLS: `True`; policies: student_target_universities_delete, student_target_universities_insert, student_target_universities_read, student_target_universities_update.
- Client table ACL: authenticated:DELETE, authenticated:INSERT, authenticated:SELECT, authenticated:UPDATE.
- Relationships: FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE RESTRICT; FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE.
- Constraints/indexes: 8/2; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.study_sessions`

- Domain: LEARNING; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 실제 study/mock session segments·duration·inclusion.
- Write path: OWNER-RLS insert/select/delete + validation.
- History: raw segments and derived duration; no silent update.
- RLS: `True`; policies: study_sessions_owner_delete, study_sessions_owner_insert, study_sessions_owner_select.
- Client table ACL: authenticated:DELETE, authenticated:SELECT.
- Relationships: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE.
- Constraints/indexes: 10/3; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

### `public.subjects`

- Domain: CONTENT TAXONOMY; state: **LIVE**; health: **KEEP_BUT_CLARIFY**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 과목 영역/master/raw mapping destination.
- Write path: ops ingestion.
- History: taxonomy version/parent/curriculum fields.
- RLS: `True`; policies: subjects_public_active_select.
- Client table ACL: none; inspect column ACL / RPC path in catalog.
- Relationships: FOREIGN KEY (parent_id, taxonomy_version) REFERENCES subjects(id, taxonomy_version) ON DELETE RESTRICT.
- Constraints/indexes: 9/4; details in catalog.
- Reason: necessary object; semantic or current/history boundary requires main-report clarification.

### `public.universities`

- Domain: UNIVERSITY IDENTITY; state: **LIVE**; health: **KEEP**; usage: **CONFIRMED_USED**.
- Purpose / canonical fact: 연도 독립 university UUID/slug/name master.
- Write path: ops ingestion.
- History: current master, no full alias/source revision history.
- RLS: `True`; policies: universities_public_select.
- Client table ACL: anon:SELECT, authenticated:SELECT.
- Relationships: no FK; identity/derived relation documented above.
- Constraints/indexes: 4/2; details in catalog.
- Reason: distinct canonical fact/history; no duplicate owner found.

## All 67 live functions / RPCs

`definer=yes`: all40 use empty `search_path`. The query expands NULL ACL through acldefault and excludes the function owner from the displayed EXECUTE list. Schema USAGE and role memberships must also permit invocation; an empty list means no non-owner EXECUTE grant found. Internal trigger/helpers are not client business endpoints.

| Function(args) | Definer / owner | EXECUTE roles in catalog | Purpose / write boundary |
|---|---|---|---|
| `essay_private.clock()` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.credit_post_grant(p_user uuid, p_quantity integer, p_origin text, p_key text, p_reason text, p_actor text, p_expires timestamp with time zone)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.credit_profile_signup()` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.credit_request_v2(p_attempt uuid, p_key uuid, p_regime text)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.credit_signup_eligible(p_user uuid)` | yes / postgres | essay_executor | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.fence(p_evaluation uuid, p_run uuid, p_token uuid, p_rewrite uuid)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.hash(p_text text)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.lock_job(p_evaluation uuid)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.owner(p_session uuid)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.release(p_evaluation uuid)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_claim_v13(p_evaluation uuid, p_rewrite uuid)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_context(p_attempt uuid, p_regime text, p_criteria jsonb, p_evidence jsonb)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_envelope_valid(v jsonb)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_finalize_v13(p_evaluation uuid, p_run uuid, p_token uuid, p_output jsonb, p_rewrite uuid)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_legacy_essay_claim(p_evaluation uuid, p_rewrite uuid)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_legacy_essay_finalize_success(p_evaluation uuid, p_run uuid, p_token uuid, p_output jsonb, p_rewrite uuid)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_legacy_essay_request_evaluation(p_attempt uuid, p_key uuid, p_regime text)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_request_v13(p_attempt uuid, p_key uuid, p_regime text)` | yes / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.scaffold_validate(p_evaluation uuid, o jsonb)` | no / essay_executor | (no explicit callable client role) | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `essay_private.uid()` | yes / postgres | essay_executor | Essay internal validation/locking/provenance/credit helper; essay_private schema restricted; delegated via public owner/worker/finance RPC |
| `public.claim_feedback_notifications(p_batch_size integer)` | yes / postgres | service_role | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.complete_feedback_notification(p_notification_id uuid, p_claim_token uuid)` | yes / postgres | service_role | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.consume_resource_resolver_quota(p_resource_id uuid)` | yes / postgres | service_role | service-only resource resolver rate-limit counter |
| `public.enqueue_feedback_notification()` | yes / postgres | (no explicit callable client role) | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.essay_admin_grant(p_user uuid, p_quantity integer, p_origin text, p_key uuid, p_reason text, p_expires timestamp with time zone)` | yes / essay_executor | essay_finance | finance-only ledger mutation; reason/idempotency checks |
| `public.essay_billing_history_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_claim(p_evaluation uuid, p_rewrite uuid)` | yes / essay_executor | essay_worker | worker fenced transaction; run/evaluation/ledger finalization |
| `public.essay_claim_signup_credit()` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_credit_account_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_erase(p_session uuid)` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_evaluation_status(p_evaluation uuid)` | yes / essay_executor | authenticated | READ ONLY owner lifecycle/credit projection; NOT Human Quality Review |
| `public.essay_finalize_failure(p_evaluation uuid, p_run uuid, p_token uuid, p_rewrite uuid)` | yes / essay_executor | essay_worker | worker fenced transaction; run/evaluation/ledger finalization |
| `public.essay_finalize_success(p_evaluation uuid, p_run uuid, p_token uuid, p_output jsonb, p_rewrite uuid)` | yes / essay_executor | essay_worker | worker fenced transaction; run/evaluation/ledger finalization |
| `public.essay_open_session(p_id uuid, p_question uuid)` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_product_child_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_product_draft_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_product_processing_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_product_progress_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_product_reject_update()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_product_terminal_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_question_identity_guard()` | no / postgres | (no explicit callable client role) | trigger invariant/history/terminal guard; not a client write API |
| `public.essay_reconcile(p_evaluation uuid, p_rewrite uuid)` | yes / essay_executor | essay_worker | worker fenced transaction; run/evaluation/ledger finalization |
| `public.essay_refund(p_consume uuid, p_key text, p_amount integer)` | yes / essay_executor | essay_finance | finance-only ledger mutation; reason/idempotency checks |
| `public.essay_request_evaluation(p_attempt uuid, p_key uuid, p_regime text)` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_request_rewrite(p_evaluation uuid)` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_save_draft(p_session uuid, p_revision bigint, p_body text, p_device text, p_mode text, p_active_seconds integer)` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_submit_attempt(p_session uuid, p_revision bigint, p_key uuid, p_body_hash text)` | yes / essay_executor | authenticated | authenticated owner RPC; auth/session ownership checked directly or through restricted helper; server-authoritative transaction |
| `public.essay_timeout(p_evaluation uuid, p_run uuid, p_token uuid, p_rewrite uuid)` | yes / essay_executor | essay_worker | worker fenced transaction; run/evaluation/ledger finalization |
| `public.fail_feedback_notification(p_notification_id uuid, p_claim_token uuid, p_error_code text, p_retryable boolean)` | yes / postgres | service_role | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.feedback_updated_at()` | no / postgres | (no explicit callable client role) | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.fetch_own_mock_attempt(p_attempt_id uuid)` | yes / postgres | authenticated | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.is_feedback_admin()` | yes / postgres | authenticated | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.reclaim_feedback_notification_leases(p_lease_seconds integer)` | yes / postgres | service_role | feedback moderation/delivery; owner/admin gate or service-role claim token; not global platform role |
| `public.scoring_answer_guard()` | yes / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_attempt_consistency()` | yes / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_attempt_guard()` | yes / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_cutoffs_valid(p_values smallint[], p_max integer)` | no / postgres | service_role | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_mcq5(p_questions jsonb, p_answers jsonb, p_cutoffs smallint[], p_certainty text)` | no / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_normalize_answers(p_answers jsonb, p_count integer)` | no / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_publication_guard()` | yes / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_question_guard()` | yes / postgres | (no explicit callable client role) | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_source_url(p_value text)` | no / postgres | service_role | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.scoring_text(p_value text, p_max integer)` | no / postgres | service_role | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |
| `public.set_updated_at()` | no / postgres | service_role | timestamp trigger utility; not a standalone business capability |
| `public.set_viewed_at()` | no / postgres | service_role | timestamp trigger utility; not a standalone business capability |
| `public.study_active_milliseconds(p_segments jsonb, p_span_ms numeric)` | no / postgres | service_role,authenticated | pure bounded study segment duration validation/calculation |
| `public.submit_mock_attempt(p_attempt_id uuid, p_study_session_id uuid, p_answer_key_version_id uuid, p_grade_cutoff_version_id uuid, p_scoring_version text, p_answers jsonb)` | yes / postgres | authenticated | mock scoring/publication validation; submit/fetch owner checked; internal helpers and source guards |

## Migration correspondence

AST comparison ignores parser location offsets only; function bodies remain compared. All21 remote entries match their local SQL. No remote-only migration, duplicate version or missing local file found. This does not certify that future manual DDL is impossible. Fresh relation/function metadata was also inspected.

| Remote version | Name | Local SQL AST |
|---|---|---|
| 20260912000100 | initial_content_schema | MATCH |
| 20260913000100 | profile_school_selection | MATCH |
| 20260913000200 | profile_day_target | MATCH |
| 20260914000100 | study_sessions | MATCH |
| 20260914000200 | mock_exam_scoring | MATCH |
| 20260917000100 | feedback_operations | MATCH |
| 20260917000200 | feedback_notification_worker | MATCH |
| 20260923000100 | study_total_inclusion | MATCH |
| 20260923000200 | private_profile_avatars | MATCH |
| 20260925000100 | resource_resolver_quota | MATCH |
| 20260926000100 | day_targets | MATCH |
| 20260927000100 | profile_personalization | MATCH |
| 20260927000200 | essay_lab_foundation | MATCH |
| 20260928000100 | student_essay_product | MATCH |
| 20260928000200 | essay_entitlements | MATCH |
| 20260928000300 | essay_server_operations | MATCH |
| 20260928000400 | essay_helper_execute_boundary | MATCH |
| 20260929000100 | essay_scaffolding_persistence | MATCH |
| 20260929000200 | essay_submit_timing_correction | MATCH |
| 20260929000300 | essay_credit_commercial_core | MATCH |
| 20260929000400 | essay_owner_evaluation_status | MATCH |

Local-only **DRAFT / NOT APPLIED**: `20260929000500_essay_provider_provenance_telemetry.sql`. No provider-policy registry/live model registration inferred. No SQL restoration or application performed.

## Edge deployment metadata

Management API listing found only `neis` v5, `process-feedback-notifications` v3, `resource-resolver` v4, all ACTIVE. `delete-account` is absent. Listing verifies presence/version only, not deployed bundle equivalence or end-to-end execution. All three report verify_jwt=false; gateway JWT disabled does not itself prove missing authorization: individual handler trust/secret/quota checks must be considered.
