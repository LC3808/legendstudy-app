"""Pure, evidence-driven exam audit. No network, DB, writer or publication API.

Profiles are exact-identity evidence, never inferred from resource count or a
full-set title. Unknown historical profiles fail closed. Raw provenance is kept.
"""
from __future__ import annotations
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from enum import StrEnum
from .subjects import BY_CODE, map_subject, resolve_legacy_subject, normalize_subject_token

class CanonicalClassification(StrEnum):
    FULL_SET = 'FULL_SET'
    PARTIAL_DUPLICATE = 'PARTIAL_DUPLICATE'
    REVIEW = 'REVIEW'

class CanonicalReason(StrEnum):
    IDENTITY = 'exam_identity_uncertain'
    CALENDAR = 'admin_date_conflict'
    ORGANIZER = 'organizer_uncertain'
    PROFILE = 'expected_coverage_unverified'
    MISSING = 'expected_paper_missing'
    MAPPING = 'resource_subject_mapping_incomplete'
    KIND = 'resource_kind_unknown'
    PAIR = 'question_answer_mapping_incomplete'
    VARIANT = 'elective_bundle_unproven'
    UNUSABLE = 'resource_unusable'
    TIE = 'canonical_rank_tie'
    SUBSET = 'strict_subset_of_sibling'
    HOLD = 'protected_hold'
    DRIFT = 'source_snapshot_changed'
    RESOURCE_IDENTITY = 'resource_identity_ambiguous'
    COLLISION = 'exam_identity_collision'
    COMPLETE = 'expected_coverage_satisfied'
    LOWER_RANK = 'complete_sibling_higher_evidence_rank'

@dataclass(frozen=True)
class ExamIdentity:
    grade: int
    exam_year: int
    nominal_month: int
    exam_family: str
    organizer: str | None
    administered_date: str | None = None
    administered_month: int | None = None
    academic_year: int | None = None
    confidence: str = 'unverified'
    calendar_conflict: bool = False
    evidence: tuple[str, ...] = ()
    event_kind: str = 'exam'
    source_event_date: str | None = None

    @property
    def key(self):
        # Extends the existing identity with organizer; actual date is a
        # consistency guard, not an alternate month that splits delayed exams.
        return (self.exam_year, self.nominal_month, self.grade,
                self.exam_family, self.organizer)

@dataclass(frozen=True)
class ExpectedCoverage:
    identity_key: tuple
    papers: frozenset[str]
    verified: bool
    evidence: tuple[str, ...]
    excluded_domains: tuple[str, ...] = ()
    required_variants: tuple[tuple[str, tuple[str, ...]], ...] = ()
    unresolved_domains: tuple[str, ...] = ()

@dataclass
class ObservedCoverage:
    papers: dict[str, set[str]] = field(default_factory=dict)
    domains: dict[str, set[str]] = field(default_factory=dict)
    resources: list[dict] = field(default_factory=list)
    unknown_keys: list[str] = field(default_factory=list)
    unknown_kind_keys: list[str] = field(default_factory=list)
    variants: dict[str, set[str]] = field(default_factory=dict)
    unpaired: list[str] = field(default_factory=list)
    raw_splits: list[str] = field(default_factory=list)
    unusable: list[str] = field(default_factory=list)
    duplicate_keys: list[str] = field(default_factory=list)

ANSWER = frozenset({'answer', 'answer_explanation'})
PAPER_KINDS = ANSWER | {'question'}
FOREIGN = ('독일어','프랑스어','스페인어','중국어','일본어','러시아어','아랍어','베트남어','한문')
VOCATIONAL = ('성공적인직업생활','농업기초기술','공업일반','상업경제','수산해운산업기초','인간발달')


def paper_code(label: str | None, identity: ExamIdentity):
    """Taxonomy v1 first. Historical/distinct papers are never collapsed."""
    if not label:
        return None, None
    token = normalize_subject_token(label)
    if token in {'수학가형', '수학나형'}:
        return 'historical:' + token, 'MATH'
    if token in {'법과정치','법과사회','국사','한국근현대사','경제지리','윤리'}:
        return 'historical:' + token, 'SOCIAL_STUDIES'
    if token in {'물리1','물리2','생물1','생물2','생물'}:
        return 'historical:' + token, 'SCIENCE'
    for name in FOREIGN:
        if token in {name, name+'1'}:
            return 'foreign:' + name, 'SECOND_FOREIGN_HANMUN'
    if token in VOCATIONAL:
        return 'vocational:' + token, 'VOCATIONAL'
    mapped = map_subject(label, identity.grade)
    code = mapped.code or resolve_legacy_subject(label, year=identity.exam_year,
                                                grade_level=identity.grade).canonical_code
    if not code:
        return None, None
    category = BY_CODE[code].category
    domain = {'사회탐구':'SOCIAL_STUDIES', '과학탐구':'SCIENCE'}.get(category)
    domain = domain or {'integrated_social':'SOCIAL_STUDIES', 'integrated_science':'SCIENCE',
                       'korean':'KOREAN', 'math':'MATH', 'english':'ENGLISH',
                       'korean_history':'KOREAN_HISTORY'}[code]
    return code, domain


def observe(resources: list[dict], identity: ExamIdentity, *, require_active=False) -> ObservedCoverage:
    out = ObservedCoverage()
    papers, domains, variants, raw = (defaultdict(set) for _ in range(4))
    seen=set()
    for r in sorted(resources, key=lambda x: (x['key'], x['label'])):
        if r['key'] in seen:out.duplicate_keys.append(r['key'])
        seen.add(r['key'])
        code, domain = paper_code(r.get('subject'), identity)
        kind = r['kind']
        if kind in PAPER_KINDS and code is None:
            out.unknown_keys.append(r['key'])
        if kind not in PAPER_KINDS | {'audio', 'script', 'listening', 'listening_audio', 'listening_script', 'explanation'}:
            out.unknown_kind_keys.append(r['key'])
        if (require_active and not r.get('active', True)) or not r['key']:
            out.unusable.append(r['key'])
        if code:
            papers[code].add(kind)
            domains[domain].add(code)
            raw[r['subject']].add(kind)
            if kind == 'question' and code in {'korean', 'math'}:
                token = normalize_subject_token(r['subject'])
                for short, full in [('화작','화법과작문'),('언매','언어와매체'),
                                    ('기하','기하'),('미적','미적분'),('확통','확률과통계')]:
                    if short in token or full in token:
                        variants[code].add(short)
        out.resources.append({**r, 'paper_code':code, 'domain':domain,
                              'usability':'metadata_only_not_http_verified'})
    out.papers, out.domains, out.variants = dict(papers), dict(domains), dict(variants)
    out.unpaired = sorted(s for s,k in papers.items() if k & PAPER_KINDS
                          and ('question' not in k or not k & ANSWER))
    out.raw_splits = sorted(s for s,k in raw.items() if k & PAPER_KINDS
                            and ('question' not in k or not k & ANSWER))
    return out


def evaluate(identity: ExamIdentity, observed: ObservedCoverage,
             expected: ExpectedCoverage | None, *, protected=False, source_changed=False):
    reasons = []
    if identity.confidence != 'high' or not identity.evidence:
        reasons.append(CanonicalReason.IDENTITY)
    if not identity.organizer:
        reasons.append(CanonicalReason.ORGANIZER)
    if identity.calendar_conflict:
        reasons.append(CanonicalReason.CALENDAR)
    if (expected is None or not expected.verified or not expected.evidence
            or expected.identity_key != identity.key or not expected.papers
            or expected.unresolved_domains):
        reasons.append(CanonicalReason.PROFILE)
    missing = sorted((expected.papers if expected else set()) -
                     {p for p,k in observed.papers.items() if 'question' in k and k & ANSWER})
    if missing:
        reasons.append(CanonicalReason.MISSING)
    if observed.unknown_keys:
        reasons.append(CanonicalReason.MAPPING)
    if observed.unknown_kind_keys:
        reasons.append(CanonicalReason.KIND)
    if observed.unpaired or observed.raw_splits:
        # Semantic pairing alone does not fix separate App occurrence accordions.
        reasons.append(CanonicalReason.PAIR)
    if expected and any(not set(v) <= observed.variants.get(k,set())
                        for k,v in expected.required_variants):
        reasons.append(CanonicalReason.VARIANT)
    if observed.duplicate_keys:
        reasons.append(CanonicalReason.RESOURCE_IDENTITY)
    if observed.unusable:
        reasons.append(CanonicalReason.UNUSABLE)
    if protected:
        reasons.append(CanonicalReason.HOLD)
    if source_changed:
        reasons.append(CanonicalReason.DRIFT)
    return {'classification':str(CanonicalClassification.REVIEW if reasons else CanonicalClassification.FULL_SET),
            'reasons':sorted(str(r) for r in set(reasons)) or [str(CanonicalReason.COMPLETE)],
            'missing_papers':missing, 'broader_siblings':[], 'canonical_target':None,
            'confidence':'high' if not reasons else 'review_required',
            'automatic_publication_allowed':False}


def classify_group(candidates: list[dict]) -> dict[str, dict]:
    """Rank only evidence-complete candidates. Ties never break by ID/count.

    A broader sibling need not be complete: a confirmed subset is held, but no
    unsafe replacement target is invented. Conflicting dates/organizers cannot
    establish a subset relation automatically.
    """
    if len({c['id'] for c in candidates}) != len(candidates):
        raise ValueError('duplicate source identity')
    result = {c['id']:evaluate(c['identity'],c['observed'],c['expected'],
                              protected=c.get('protected',False),
                              source_changed=c.get('source_changed',False)) for c in candidates}
    date_groups=defaultdict(set)
    for c in candidates:
        if c['identity'].administered_date:
            date_groups[c['identity'].key].add(c['identity'].administered_date)
    collisions={k for k,v in date_groups.items() if len(v)>1}
    for c in candidates:
        if c['identity'].key in collisions:
            r=result[c['id']];r['classification']='REVIEW'
            r['reasons']=sorted(set(r['reasons'])|{str(CanonicalReason.COLLISION)})
            r['confidence']='review_required'
    def certain(c):
        i=c['identity']
        return i.confidence=='high' and bool(i.organizer and i.evidence) and not i.calendar_conflict and i.key not in collisions
    for c in candidates:
        if not certain(c):
            continue
        papers={s for s,k in c['observed'].papers.items() if 'question' in k}
        for sibling in candidates:
            if sibling['id']==c['id'] or not certain(sibling):
                continue
            a,b=c['identity'],sibling['identity']
            if a.key!=b.key or (a.administered_date and b.administered_date
                               and a.administered_date!=b.administered_date):
                continue
            other={s for s,k in sibling['observed'].papers.items() if 'question' in k}
            if papers and papers < other and not c['observed'].unknown_keys:
                result[c['id']]['broader_siblings'].append(sibling['id'])
        r=result[c['id']]
        if r['broader_siblings']:
            r['broader_siblings'].sort(key=int)
            r['classification']=str(CanonicalClassification.PARTIAL_DUPLICATE)
            r['reasons']=sorted(set(r['reasons'])|{str(CanonicalReason.SUBSET)})
            r['confidence']='high_subset_not_full_target'
    # Never rank different identities together, even when caller passes all rows.
    groups=defaultdict(list)
    for c in candidates:
        if result[c['id']]['classification']=='FULL_SET':
            groups[c['identity'].key].append(c)
    for group in groups.values():
        if len(group)>1:
            # Identity and full coverage are hard prerequisites. Optional ranks
            # must be supplied with evidence, never derived from attachment count.
            def rank(c):
                if not c.get('ranking_evidence'):
                    return (0, 0)
                return (c.get('usability_rank',0), c.get('metadata_rank',0))
            best=max(rank(c) for c in group)
            winners=[c for c in group if rank(c)==best]
            for c in group:
                if len(winners)==1 and c is winners[0]:continue
                r=result[c['id']];r['classification']='REVIEW'
                r['reasons']=[str(CanonicalReason.TIE if len(winners)>1 else CanonicalReason.LOWER_RANK)]
                r['confidence']='review_required'
                if len(winners)==1:r['canonical_target']=winners[0]['id']
    for c in candidates:
        r=result[c['id']]
        full=[i for i in r['broader_siblings'] if result[i]['classification']=='FULL_SET']
        if len(full)==1:r['canonical_target']=full[0]
    return dict(sorted(result.items(),key=lambda kv:int(kv[0])))


def serializable(value):
    if hasattr(value,'__dataclass_fields__'):return serializable(asdict(value))
    if isinstance(value,dict):return {k:serializable(v) for k,v in sorted(value.items())}
    if isinstance(value,(set,frozenset)):return sorted(value)
    if isinstance(value,(list,tuple)):return [serializable(v) for v in value]
    return value
