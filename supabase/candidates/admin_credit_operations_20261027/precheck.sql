-- READ ONLY: all checks must be true. Do not reapply existing functions.
select md5(pg_get_functiondef('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure))='0df3300b46a557380e30867e061594bf' as preserved_1,
md5(pg_get_functiondef('public.admin_manual_credit_grant(uuid,text,integer,text,uuid)'::regprocedure))='f9d760b2f810c57aa18d7097e5e7f5b3' as preserved_2,
md5(pg_get_functiondef('public.admin_credit_snapshot(uuid)'::regprocedure))='0704946d9d378da925478c39be741795' as preserved_3,
md5(pg_get_functiondef('public.admin_member_credit(uuid,integer,integer)'::regprocedure))='5d23c4ab6c7f94f764175cce6187b7e1' as preserved_4,
md5(pg_get_functiondef('public.admin_operator()'::regprocedure))='5f3367e86e09801ba438438d2fbb5c89' as preserved_5,
to_regprocedure('public.admin_credit_operation_info(uuid,uuid)') is null as new_rpc_1_absent,
to_regprocedure('public.admin_credit_grant_expiring(uuid,text,integer,text,text,date,text,uuid)') is null as new_rpc_2_absent,
to_regprocedure('public.admin_credit_recover(uuid,uuid,integer,text,uuid)') is null as new_rpc_3_absent;
