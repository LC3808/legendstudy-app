-- Read-only; expected 845 ALLOWED after apply, 845 VIEW_ONLY after rollback.
select p.state,count(*) from material_download_private.permissions p
where p.revision=(select max(x.revision) from material_download_private.permissions x where x.resource_id=p.resource_id)
group by p.state;
select count(*) as policy_allowed from material_download_private.permissions p
where p.owner_decision='owner_download_activation_20261113'
and public.resource_download_policy(p.resource_id)->>'state'='ALLOWED';
