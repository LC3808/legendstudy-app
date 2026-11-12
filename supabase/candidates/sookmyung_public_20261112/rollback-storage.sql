-- Revoke only new PDF access; preserve files and all histories.
begin;
drop policy sookmyung_14_official_problem_pdfs_20261112_read on storage.objects;
commit;
