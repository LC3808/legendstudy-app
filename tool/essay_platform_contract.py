"""Offline server-adapter contract. No endpoint, provider, DB, storage or billing call.

`load` is a trusted server catalog adapter, never a deserialized client manifest.
Existing Humanities and Math identities remain typed. This planner cannot enable
runtime: it only validates a future reviewed binding and reports remaining gates.
"""
from dataclasses import dataclass
from typing import Callable
from uuid import UUID
import re

CATEGORIES=frozenset({'humanities_social','business_economics','math','science'})
REQUIREMENTS=frozenset({'humanities_reasoning','data_interpretation','quantitative_reasoning','math_solution','science_reasoning'})

class ContractError(ValueError): pass

@dataclass(frozen=True)
class Binding:
    evaluator: str                 # existing humanities or math only
    subject_id: str                # essay_question UUID or math_subproblem UUID
    rubric_subject_id: str         # must bind to the same typed question/leaf
    rubric_version: str
    covers: frozenset[str]
    exam_id: str = ""

@dataclass(frozen=True)
class ReviewedQuestion:
    question_id: str
    exam_id: str
    university_id: str
    admission_year: int
    category: str
    metadata_version: str
    classification_version: str
    verified_at: str | None
    source_url: str
    source_sha256: str
    requirements: frozenset[str]
    bindings: tuple[Binding,...]

@dataclass(frozen=True)
class Plan:
    category: str
    requirements: tuple[str,...]
    evaluators: tuple[str,...]
    missing_requirements: tuple[str,...]
    classification_version: str
    runtime_enabled: bool = False
    credit_action: str = 'NONE'
    release_gate: str = 'REVIEWED_RUNTIME_INTEGRATION_REQUIRED'

def plan_question(request: dict, load: Callable[[str], ReviewedQuestion]) -> Plan:
    allowed={'question_id','exam_id','university_id','admission_year'}
    if not isinstance(request,dict) or set(request)!=allowed:
        raise ContractError('IDENTITY_ONLY_REQUEST')
    try:
        for field in ['question_id','exam_id','university_id']:UUID(request[field])
    except (TypeError,ValueError,AttributeError):raise ContractError('INVALID_IDENTITY') from None
    if type(request['admission_year']) is not int or not 1900<=request['admission_year']<=2200:
        raise ContractError('INVALID_YEAR')
    q=load(request['question_id'])
    if not isinstance(q,ReviewedQuestion) or any(getattr(q,k)!=request[k] for k in allowed):
        raise ContractError('CONTEXT_MISMATCH')
    if q.category not in CATEGORIES or not q.requirements or not q.requirements<=REQUIREMENTS:
        raise ContractError('INVALID_CLASSIFICATION')
    if not q.metadata_version or not q.classification_version or not q.verified_at or not q.source_url.startswith('https://') or not re.fullmatch('[0-9a-f]{64}',q.source_sha256):
        raise ContractError('UNREVIEWED_METADATA')
    covered=set();evaluators=[]
    for b in q.bindings:
        if b.exam_id!=q.exam_id:raise ContractError("BINDING_EXAM_MISMATCH")
        if b.evaluator not in {'humanities','math'} or not b.rubric_version or b.subject_id!=b.rubric_subject_id:
            raise ContractError('RUBRIC_BINDING_MISMATCH')
        try:UUID(b.subject_id)
        except (ValueError,TypeError,AttributeError):raise ContractError('INVALID_BINDING') from None
        # Humanities uses the canonical essay question. Math is an explicit,
        # reviewed leaf binding; never infer a Math leaf UUID from the essay UUID.
        if b.evaluator=='humanities' and b.subject_id!=q.question_id:
            raise ContractError('QUESTION_BINDING_MISMATCH')
        if not b.covers or not b.covers<=q.requirements or covered.intersection(b.covers):
            raise ContractError('INVALID_CAPABILITY_COVERAGE')
        if 'science_reasoning' in b.covers:
            raise ContractError('SCIENCE_CAPABILITY_NOT_IMPLEMENTED')
        if 'math_solution' in b.covers and b.evaluator!='math' or 'humanities_reasoning' in b.covers and b.evaluator!='humanities':
            raise ContractError('EVALUATOR_MISMATCH')
        covered.update(b.covers);evaluators.append(b.evaluator)
    return Plan(q.category,tuple(sorted(q.requirements)),tuple(evaluators),tuple(sorted(q.requirements-covered)),q.classification_version)
