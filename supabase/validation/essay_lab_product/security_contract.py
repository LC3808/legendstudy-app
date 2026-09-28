"""Offline assertions for the full catalog contract, with narrow managed-role allowance."""
CLIENT = {'essay_open_session','essay_save_draft','essay_submit_attempt','essay_request_evaluation','essay_request_rewrite','essay_erase'}
WORKER = {'essay_claim','essay_timeout','essay_finalize_success','essay_finalize_failure','essay_reconcile'}
HELPERS = {'essay_product_reject_update','essay_product_terminal_guard','essay_product_child_guard','essay_question_identity_guard','essay_product_progress_guard','essay_product_processing_guard','essay_product_draft_guard','essay_credit_account_guard','essay_billing_history_guard'}

def memberships_valid(rows, managed=True):
    if not managed: return rows == []
    return len(rows)==3 and {x['granted_role'] for x in rows}=={'essay_executor','essay_worker','essay_finance'} and all(
        x['member_role']=='postgres' and x['grantor_role']=='supabase_admin' and x['admin_option'] is True
        and all(x[k] is False for k in ('inherit_option','set_option','effective_inherit','effective_set')) for x in rows)

def validate(post, canonical, before_correction=False):
    assert len(post['check_00'])==47 and all(x['definition_matches'] for x in post['check_00'])
    assert post['check_01']==[{'all_19_present':True,'all_rls_enabled':True}]
    assert len(post['check_02'])==4 and all(x['additive_column_present'] for x in post['check_02'])
    assert len(post['check_03'])==19 and all(x['initial_count_should_be_zero']==0 for x in post['check_03'])
    assert len(post['check_04'])==40 and all(x['orphan_count']==0 for x in post['check_04'])
    assert len(post['check_05'])==304
    for x in post['check_05']:
        expected=(x['role']=='anon' and x['name'] in {'essay_questions','essay_question_evidence','essay_evaluation_criteria'} and x['privilege']=='SELECT') or (x['role']=='authenticated' and ((x['privilege']=='SELECT' and x['name']!='essay_ai_processing_runs') or (x['privilege'] in ('INSERT','UPDATE','DELETE') and x['name'] in ('essay_drafts','student_target_universities'))))
        assert x['granted']==expected
    assert len(post['check_06'])==140
    mismatches=[]
    for x in post['check_06']:
        expected=x['nspname']=='public' and ((x['proname'] in CLIENT and x['role']=='authenticated') or (x['proname'] in WORKER and x['role']=='essay_worker') or (x['proname']=='essay_refund' and x['role']=='essay_finance'))
        if x['executable']!=expected: mismatches.append(x)
        assert x['proconfig']==['search_path=""']
        assert x['owner']==('postgres' if x['proname'] in HELPERS or (x['nspname']=='essay_private' and x['proname']=='uid') else 'essay_executor')
        if x['proname'] in CLIENT|WORKER|{'essay_refund'}: assert x['prosecdef']
    if before_correction:
        assert len(mismatches)==9 and {x['proname'] for x in mismatches}==HELPERS and all(x['role']=='service_role' and x['executable'] for x in mismatches)
    else: assert mismatches==[]
    assert len(post['check_07'])==3
    for x in post['check_07']:
        assert not x['rolcanlogin'] and not x['rolsuper'] and x['rolbypassrls']==(x['rolname']=='essay_executor')
    assert memberships_valid(post['check_08'])
    assert post['check_09']==[{'executor_private_create_must_be_false':False,'executor_public_create_must_be_false':False}]
    assert post['check_10']==canonical
    return {'definitions':47,'tables':19,'columns':4,'rpcs':12,'new_rows':0,'membership_contract':'PASS','function_execute_mismatches':len(mismatches),'canonical_preserved':True}
