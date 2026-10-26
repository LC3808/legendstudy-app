"""Logical policy families over the existing engines; no billing or persistence.

The server's pinned runtime policy and official exam identity choose the family.
A track name, student answer, or image never promotes a question to Math.
"""
from .live_worker import require


BUSINESS_TRACKS = frozenset(('상경계열', '경영경제', '경영경제계열',
                             '인문계열(경제경영)', '인문계열(경영경제)'))


def policy_family(evaluation_type, exam_identity):
    """Classify trusted material metadata without replacing pinned evidence."""
    if evaluation_type == 'business' or (evaluation_type == 'humanities' and
            exam_identity.get('track') in BUSINESS_TRACKS):
        return 'business'
    return evaluation_type


def question_engine(evaluation_type, approved_engine='essay'):
    if evaluation_type == 'business':
        return business_question_engine(approved_engine)
    # Preserve the existing humanities path, including already pinned children.
    require(evaluation_type == 'humanities', 'USE_EXISTING_MATH_OR_SCIENCE_RUNTIME')
    require(approved_engine in ('essay', 'math'), 'UNKNOWN_QUESTION_ENGINE')
    return approved_engine


def business_question_engine(approved_engine):
    """Business may be language-only or mixed; use each official binding.

    Essay feedback and math solution feedback retain their original contracts.
    The existing exam parent alone reserves/finalizes Credit and saves History.
    Photo input still requires the student's confirmed extraction identifier.
    """
    require(approved_engine in ('essay', 'math'), 'UNKNOWN_BUSINESS_QUESTION_ENGINE')
    return approved_engine
