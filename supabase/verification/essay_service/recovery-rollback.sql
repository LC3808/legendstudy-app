-- Remove only the new scheduler entry point; retain original RPC, evaluations and ledger.
begin;
drop function public.math_recover_expired_evaluations(integer);
commit;
