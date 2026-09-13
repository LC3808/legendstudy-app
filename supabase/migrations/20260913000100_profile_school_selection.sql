begin;

alter table public.profiles
  add column neis_office_code text,
  add column neis_school_code text,
  add constraint profiles_neis_school_pair check (
    (neis_office_code is null) = (neis_school_code is null)
    and (
      neis_office_code is null or (
        neis_office_code = btrim(neis_office_code, E' \t\n\r\f\013')
        and char_length(neis_office_code) between 1 and 32
      )
    )
    and (
      neis_school_code is null or (
        neis_school_code = btrim(neis_school_code, E' \t\n\r\f\013')
        and char_length(neis_school_code) between 1 and 32
      )
    )
  );

grant insert (neis_office_code, neis_school_code),
      update (neis_office_code, neis_school_code)
  on public.profiles to authenticated;

notify pgrst, 'reload schema';
commit;
