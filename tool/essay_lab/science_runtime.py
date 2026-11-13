"""Science-specific binding over the existing reviewed 1.3 evaluator and result UX.
No alternative Provider, billing, persistence, numerical university scoring or UI.
"""
from copy import deepcopy
from .live_worker import require
SUBJECTS={'physics','chemistry','biology','earth_science','integrated_science'}

def science_context(entry):
    value=entry.get('science_context')
    require(entry.get('evaluation_engine')=='science' and type(value) is dict,'SCIENCE_BINDING_REQUIRED')
    require(set(value)=={'contract','capability','subject','question_id','source_sha256','criteria_basis'},'SCIENCE_BINDING_SHAPE')
    require(value['contract']=='science-reasoning-v1' and value['capability']=='SCIENCE_REASONING','SCIENCE_CAPABILITY_REQUIRED')
    require(value['subject'] in SUBJECTS and value['question_id']==entry['question_id'],'SCIENCE_IDENTITY_MISMATCH')
    require(value['criteria_basis']=='OFFICIAL_WITH_EXPLICIT_SERVICE_GUIDANCE','SCIENCE_CRITERIA_BASIS_REQUIRED')
    sources={r['sourceHash'] for r in entry['source_page_references'] if r['role']=='question'}
    require(sources=={value['source_sha256']},'SCIENCE_SOURCE_MISMATCH')
    require(any(r['role']=='criteria' and r.get('evidenceText','').strip() for r in entry['source_page_references']),'SCIENCE_CRITERIA_REQUIRED')
    require(not entry.get('math_context'),'SCIENCE_MATH_ALIAS_FORBIDDEN')
    return deepcopy(value)
