set "fixture.user"='00000000-0000-0000-0000-000000000001';
do $$declare page jsonb; next jsonb; total int=0; seen uuid[]='{}'; row jsonb;begin
 loop
 page=public.essay_exam_history_page((next->>'at')::timestamptz,(next->>'id')::uuid,50);
 for row in select * from jsonb_array_elements(page->'runs') loop
  if row ? 'answers' or row ? 'result' or (row->>'id')::uuid=any(seen) or row->>'id'='ffffffff-ffff-ffff-ffff-ffffffffffff' then raise exception 'LEAK_OR_DUPLICATE';end if;
  seen=array_append(seen,(row->>'id')::uuid); total=total+1;
 end loop;
 next=page->'next';exit when next='null'::jsonb;
 end loop;
 if total<>123 then raise exception 'MISSING_HISTORY %',total; end if;
 raise notice 'PASS 123 records, stable tied timestamps, no duplicates, other owner excluded, bodies/results redacted';
end$$;
set "fixture.user"='';
do $$begin
 begin perform public.essay_exam_history_page();raise exception 'ANON_ALLOWED'; exception when others then if sqlerrm='ANON_ALLOWED' then raise;end if;end;
 if has_function_privilege('anon','public.essay_exam_history_page(timestamptz,uuid,integer)','execute') then raise exception 'ANON_GRANT';end if;
 raise notice 'PASS unauthenticated denial and grants';
end$$;
