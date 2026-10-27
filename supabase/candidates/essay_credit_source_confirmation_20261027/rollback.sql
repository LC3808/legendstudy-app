-- Safe stop only: preserve source-consent guard and all reservations.
begin;update essay_beta_private.campaigns set enabled=false where enabled;commit;
