begin;
-- Dedicated TASK16-G TEST only. Exact official question PDF; no scoring/answers.
create policy task16g_official_question_read on storage.objects for select to authenticated using (bucket_id='essay-material-originals' and name='2a2e94097d97e3c758927146e0e68a1376d9996f3f474131b443c3ba65bcb7a4.pdf');
commit;
