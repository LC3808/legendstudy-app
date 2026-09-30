"""L2-C1 offline, question-scoped package validation and blind input assembly.
The reviewed catalog is supplied separately and pinned by its hash. It is trusted
operator input, not provider output. Hash/role checks cannot prove source semantics.
No network, DB, credentials, OCR, or provider dispatch.
"""
from copy import deepcopy
from hashlib import sha256
from .live_worker import digest, require

VERSION = 'official-evidence-vnext-1'
ROLES = {'question','passage','official_intent','scoring_criterion',
         'question_length_rule','scoring_length_rule','explicit_non_criterion',
         'official_example','accepted_example','high_quality_example'}
EXAMPLES = {'official_example','accepted_example','high_quality_example'}
BASE_ROLES = {'question': 'question', 'passage': 'passage', 'official_intent': 'exam_intent',
              'scoring_criterion': 'scoring_criteria','question_length_rule':'question',
              'scoring_length_rule':'scoring_criteria','explicit_non_criterion':'scoring_criteria',
              'official_example':'model_answer','accepted_example':'example_answer',
              'high_quality_example':'high_scoring_answer'}


def catalog_digest(catalog):
    value=deepcopy(catalog)
    for group in ('sources','derivatives'):
        value[group]=sorted([{k:v for k,v in x.items() if k!='path'} for x in value[group]],key=lambda x:x['id'])
    value['allowed_evidence']=sorted(value['allowed_evidence'])
    return digest(value)


def validate(package, catalog, read_blob):
    """read_blob(path) reads local private bytes; catalog must be reviewed and pinned.
    No semantic labels may be supplied independently by an untrusted package.
    """
    require(package['version']==VERSION and package['catalog_hash']==catalog_digest(catalog),'CATALOG_BINDING')
    require(package['question']==catalog['question'],'QUESTION_IDENTITY')
    q=package['question']['id']; sources=catalog['sources']; derivatives=catalog['derivatives']
    require(len({x['id'] for x in sources})==len(sources),'DUPLICATE_SOURCE')
    require(len({x['id'] for x in derivatives})==len(derivatives),'DUPLICATE_DERIVATIVE')
    src={x['id']:x for x in sources}; ds={x['id']:x for x in derivatives}
    for s in sources:
        require(sha256(read_blob(s['path'])).hexdigest()==s['sha256'],'SOURCE_HASH')
        require(s['provenance'] in {'official_university_source','student_submission'},'SOURCE_PROVENANCE')
    current=set()
    for d in derivatives:
        require(d['source_id'] in src,'MISSING_SOURCE')
        require(d['question_id']==q,'CROSS_QUESTION')
        require(isinstance(d['page'],int) and d['page']>0 and bool(d['locator'].strip()),'LOCATOR')
        require(d['version'] and d['review_state']=='reviewed','DERIVATIVE_REVIEW')
        require(sha256(read_blob(d['path'])).hexdigest()==d['sha256'],'DERIVATIVE_HASH')
        key=(d['semantic_role'],d['identity'])
        if d['current']:
            require(key not in current,'CONFLICTING_CURRENT');current.add(key)
        if d['prior_id'] is not None:
            require(d['prior_id'] in ds and not ds[d['prior_id']]['current'],'CORRECTION_PRIOR')
            prior=ds[d['prior_id']]
            require(prior['identity']==d['identity'] and prior['version']!=d['version'] and
                    prior['source_id']==d['source_id'] and d['correction_reason'] and d['reviewer'] and d['reviewed_at'],'CORRECTION_LINEAGE')
    selected=package['evidence']
    require(len(set(selected))==len(selected),'DUPLICATE_EVIDENCE')
    for ident in selected:
        require(ident in ds and ident in catalog['allowed_evidence'],'EVIDENCE_ALLOWLIST')
        d=ds[ident]; role=d['semantic_role']
        require(role in ROLES,'UNKNOWN_ROLE')
        require(d['current'] and src[d['source_id']]['provenance']=='official_university_source','OFFICIAL_ONLY')
        require(d['canonical_role']==BASE_ROLES[role],'ROLE_BINDING')
    require(set(package['criteria'])==set(catalog['criteria']),'CRITERION_MAPPING')
    for ident in package['criteria']:
        c=catalog['criteria'][ident]
        require(c['source_evidence'] in selected and ds[c['source_evidence']]['semantic_role']=='scoring_criterion','CRITERION_SOURCE')
        require(c['origin'] in {'official','legendstudy_derived'},'CRITERION_ORIGIN')
        require(c['official_weight'] is None or (c['origin']=='official' and type(c['official_weight']) in (int,float) and 0<c['official_weight']<=100),'WEIGHT')
    t=package['transcription']
    require(t==catalog['selected_transcription'] and t in ds,'TRANSCRIPTION_VERSION')
    require(ds[t]['semantic_role']=='student_transcription' and ds[t]['current'],'TRANSCRIPTION_ROLE')
    require(src[ds[t]['source_id']]['provenance']=='student_submission','SUBMISSION_SEPARATE')
    require(package['hash']==digest({k:v for k,v in package.items() if k!='hash'}),'PACKAGE_HASH')
    return deepcopy(package)


def blind_input(package, catalog, read_blob):
    validate(package,catalog,read_blob)
    ds={d['id']:d for d in catalog['derivatives']}
    # Explicit projection: never serialize whole catalog/reviewer annotations/old outputs.
    evidence=[]
    for ident in package['evidence']:
        d=ds[ident]
        if d['semantic_role'] in EXAMPLES: continue
        evidence.append({k:d[k] for k in ('id','semantic_role','canonical_role','source_id','page','locator','version','sha256','media_type')})
    t=ds[package['transcription']]
    return {'package_version':VERSION,'package_hash':package['hash'],'question':package['question'],
            'evidence':evidence,'criteria':deepcopy(catalog['criteria']),
            'student_submission':{'transcription_id':t['id'],'sha256':t['sha256'],
                 'text':read_blob(t['path']).decode(),'review_state':t['review_state']}}


def freeze_manifest(catalog):
    p={'version':VERSION,'question':deepcopy(catalog['question']),'catalog_hash':catalog_digest(catalog),
       'evidence':sorted(catalog['allowed_evidence']),'criteria':sorted(catalog['criteria']),
       'transcription':catalog['selected_transcription']}
    p['hash']=digest(p)
    return p
