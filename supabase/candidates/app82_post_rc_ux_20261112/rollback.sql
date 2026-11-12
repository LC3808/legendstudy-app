-- Removes only these additive read RPCs. APP82 v1 fallbacks remain available.
begin;
drop function public.student_school_ranking_page(text,text,text,integer,integer,timestamptz,text);
drop function public.my_study_percentile();
commit;
