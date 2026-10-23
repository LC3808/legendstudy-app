create policy skku_2026_language1_problem_read on storage.objects
for select to authenticated
using ((select public.account_service_allowed())
  and bucket_id='essay-material-originals'
  and name='582f370e73f3d4b96e374f0596e4ae204e6f79e750ca07ff2c752244826fd7eb.pdf');
