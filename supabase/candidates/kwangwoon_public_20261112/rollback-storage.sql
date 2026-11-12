-- Revoke only new PDF access; preserve files and all histories.
begin;
drop policy kwangwoon_21_official_problem_pdfs_20261112_read on storage.objects;
commit;
