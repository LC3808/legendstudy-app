"""Exact-identity expected coverage registry; pure offline, no writer import.

Coverage verification and source identity/mapping are independent gates. A
verified profile cannot repair a conflicting source date or merge protected data.
"""
from __future__ import annotations
from copy import deepcopy
from dataclasses import replace
import json
from pathlib import Path
from .exam_canonical import ExpectedCoverage, classify_group, evaluate

REGISTRY = Path(__file__).parent / 'reference' / 'exam-expected-coverage.json'
FIELDS = ('exam_year', 'nominal_month', 'grade', 'exam_family', 'organizer')

class CoverageRegistry:
    def __init__(self, document):
        self.document = deepcopy(document)
        self.entries = {}
        sources = self.document['sources']
        for source in sources.values():
            for field in ('authority','source_title','source_url','accessed_at','evidence_scope','verification_status'):
                if not source.get(field): raise ValueError('Missing provenance: '+field)
            if not source['source_url'].startswith('https://'): raise ValueError('Non-HTTPS evidence')
        ids=set()
        for entry in self.document['entries']:
            key=tuple(entry['identity'][f] for f in FIELDS)
            if key in self.entries or entry['id'] in ids: raise ValueError('Duplicate registry identity')
            ids.add(entry['id'])
            if entry['status'] not in {'VERIFIED','PARTIALLY_VERIFIED','UNVERIFIED'}: raise ValueError('Invalid status')
            if entry['identity']['year_basis']!='calendar': raise ValueError('Ambiguous year basis')
            refs=[e['source'] for e in entry['evidence']]+entry['identity_evidence']
            if any(r not in sources for r in refs): raise ValueError('Unresolved evidence reference')
            if entry['status']!='UNVERIFIED' and not entry['evidence']: raise ValueError('Evidence missing')
            if len(set(entry['required_papers']))!=len(entry['required_papers']): raise ValueError('Duplicate paper')
            if set(entry['required_papers']) & set(entry.get('excluded_papers',[])): raise ValueError('Offered/excluded conflict')
            if entry['status']=='VERIFIED':
                if not entry['required_papers'] or entry['epistemic_status'] not in {'FACT','DERIVED'}: raise ValueError('Unproven coverage')
                facts=[e for e in entry['evidence'] if e['kind']=='FACT' and sources[e['source']]['verification_status']=='VERIFIED']
                if not any('required_papers' in e['proves'] for e in facts): raise ValueError('Coverage fact missing')
            self.entries[key]=entry

    @classmethod
    def load(cls, path=REGISTRY):
        return cls(json.loads(Path(path).read_text()))

    def lookup(self, identity):
        """No fuzzy, nearest-year, organizer or curriculum fallback."""
        entry=self.entries.get(identity.key)
        return deepcopy(entry) if entry else None

    def resolve_identity(self, identity):
        # A unique nominal match may supply a missing organizer from an explicit
        # calendar citation. A known different organizer is never overwritten.
        matches=[e for k,e in self.entries.items() if k[:4]==identity.key[:4]]
        if len(matches)!=1: return identity
        e=matches[0];i=e['identity']
        if not e['identity_evidence']: return identity
        conflict=identity.calendar_conflict
        if identity.organizer and identity.organizer!=i['organizer']: return replace(identity,confidence='unverified')
        reference=i['reference_date']
        date=identity.source_event_date or identity.administered_date
        if date and reference and date!=reference: conflict=True
        if identity.administered_month and reference and identity.administered_month!=int(reference[5:7]): conflict=True
        if identity.academic_year and identity.exam_family in {'csat','evaluation_mock'} and identity.academic_year!=i['academic_year']: conflict=True
        # Calendar citations establish expected event; source evidence is still
        # required to associate the actual resource set with it.
        high=bool(identity.evidence) and not conflict and not e.get('identity_review_required',False)
        return replace(identity,organizer=i['organizer'],confidence='high' if high else 'unverified',
                       calendar_conflict=conflict,evidence=tuple(sorted(set(identity.evidence)|{'registry:'+r for r in e['identity_evidence']})))

    def expected(self, identity):
        e=self.lookup(identity)
        if not e:return None
        return ExpectedCoverage(identity.key,frozenset(e['required_papers']),e['status']=='VERIFIED',
            tuple('registry:'+v['source'] for v in e['evidence']),
            required_variants=tuple((k,tuple(v)) for k,v in sorted(e['required_variants'].items())),
            unresolved_domains=() if e['status']=='VERIFIED' else ('independent_inventory_incomplete',))


def classify_with_registry(candidates):
    """Phase3 stricter partial rule, preserving Phase2 historical reproducibility.

    A broader-but-unverified or tied sibling is not a canonical target. Coverage
    eligibility is separate from protected publication holds; callers report both.
    """
    result=classify_group(candidates)
    for c in candidates:
        r=result[c['id']]
        if r['classification']=='PARTIAL_DUPLICATE' and (not r['canonical_target']
                or not c['expected'] or not c['expected'].verified
                or c['observed'].unknown_keys or c['observed'].unknown_kind_keys
                or c['observed'].duplicate_keys):
            broader=r['broader_siblings'];target=r['canonical_target']
            r=evaluate(c['identity'],c['observed'],c['expected'],source_changed=c.get('source_changed',False))
            r['classification']='REVIEW';r['confidence']='review_required'
            reasons=set(r['reasons'])-{'expected_coverage_satisfied'}
            if not target:reasons.add('canonical_full_sibling_unverified')
            r['reasons']=sorted(reasons)
            r['broader_siblings']=broader
            result[c['id']]=r
    return result
