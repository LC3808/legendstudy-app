-- Run after closing only the new WEB/DB scope; preserve both stored PDFs and histories.
begin;
drop policy sogang_problem_q2_complete_20261112_read on storage.objects;
commit;
