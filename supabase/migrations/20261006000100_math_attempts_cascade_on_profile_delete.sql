-- Math erasure fix: math_attempts.student_id RESTRICT -> CASCADE so the ADR-2
-- auth.users -> profiles deletion cascade also erases the student's Math data.
alter table public.math_attempts
  drop constraint math_attempts_student_id_fkey,
  add constraint math_attempts_student_id_fkey
    foreign key (student_id) references public.profiles(id) on delete cascade;
