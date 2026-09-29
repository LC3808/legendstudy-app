"""Server-only payload adapter; no provider calls or credentials.

The caller must obtain local_reviews through a trusted semantic review step independent
of the provider response. Merely setting provider claim_scope is never approval. This
module does not infer prose semantics or authorize a reviewer; the hosting worker must
provide that identity. Unreviewed local claims fail closed before invoking the RPC.
"""
from copy import deepcopy


def finalize_payload(provider_output, *, contract_version, local_reviews=()):
    if contract_version == '1.2':
        return deepcopy(provider_output)  # Old/in-flight path, no coercion of old output.
    if contract_version != '1.3' or provider_output.get('contract_version') != '1.3':
        raise ValueError('UNSUPPORTED_CONTRACT')
    if 'local_reviews' in provider_output:
        raise ValueError('PROVIDER_CANNOT_APPROVE_LOCAL_SCOPE')
    result = deepcopy(provider_output)
    reviewed = list(local_reviews)
    local = [i for i in result['improvements'] if i.get('claim_scope') == 'local_sentence']
    if len(reviewed) != len(local):
        raise ValueError('LOCAL_REVIEW_REQUIRED')
    for item in local:
        sentences = [s for s in result['sentence_feedback'] if s['linked_issue_key'] == item['issue_key']]
        matches = [r for r in reviewed if r.get('issue') == item and r.get('sentences') == sentences
                   and r.get('decision') == 'local_only' and isinstance(r.get('reviewer'), str)
                   and r['reviewer'].strip()]
        if len(matches) != 1:
            raise ValueError('LOCAL_REVIEW_PAYLOAD_MISMATCH')
    result['local_reviews'] = deepcopy(reviewed)
    return result
