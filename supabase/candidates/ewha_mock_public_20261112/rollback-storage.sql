-- Revoke only new PDF access; preserve files and all histories.
begin;
drop policy ewha_mock_8_problem_pdfs_20261112_read on storage.objects;
commit;
