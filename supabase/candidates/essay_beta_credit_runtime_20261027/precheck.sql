select md5(pg_get_functiondef('public.math_session_submit(uuid,uuid,uuid[],uuid)'::regprocedure))='a34c4fe9b65a645e02d0ca61fced2603' as allocator_1,
md5(pg_get_functiondef('essay_private.scaffold_legacy_essay_request_evaluation(uuid,uuid,text)'::regprocedure))='28ffc04b579fe1d174172fb37b13d61c' as allocator_2,
md5(pg_get_functiondef('essay_private.scaffold_request_v13(uuid,uuid,text)'::regprocedure))='c7434fc61c8e952e633d2b915f670853' as allocator_3,
md5(pg_get_functiondef('essay_private.credit_request_v2(uuid,uuid,text)'::regprocedure))='43ba761b2143dcd1187fc6127295e003' as allocator_4,
md5(pg_get_functiondef('math_private.authorize_billing(uuid)'::regprocedure))='0154a967dde40918213692e93cb4f5b0' as allocator_5,
md5(pg_get_functiondef('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))='ddab49ee9a5682389d0e839c058e6cfb' as allocator_6,
to_regnamespace('essay_beta_private') is null as new_schema_absent;
