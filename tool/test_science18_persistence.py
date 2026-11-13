"""Real isolated common Ledger/History flow with explicit science binding and fake transport."""
import inspect,json,sys
from pathlib import Path
import test_essay_exam_credit as harness
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from essay_lab import exam_surface_validation as surface
ORIGINAL=surface.cases

def science_cases(sql,root,*args):
    source=inspect.getsource(ORIGINAL).replace("evaluation_type='humanities'","evaluation_type='science'")
    anchor="    sql(f\"create function public.essay_material_runtime_package"
    insert="""    pkg['questions'][0].update(evaluation_engine='science',science_context=dict(contract='science-reasoning-v1',capability='SCIENCE_REASONING',subject='physics',question_id=question,source_sha256='a'*64,criteria_basis='OFFICIAL_WITH_EXPLICIT_SERVICE_GUIDANCE'))
"""
    assert anchor in source;source=source.replace(anchor,insert+anchor)
    namespace=dict(surface.__dict__);exec(source,namespace)
    def patched(query,error=None):
        if 'create function public.essay_exam_preflight' in query or 'create or replace function public.essay_exam_submit' in query or 'create function public.essay_exam_submit' in query:
            query=query.replace("not in ('humanities','business')","not in ('humanities','business','science')")
        return sql(query,error)
    namespace['cases'](patched,root,*args)

if __name__=='__main__':
    surface.cases=science_cases
    if '--surface-only' not in sys.argv:sys.argv.append('--surface-only')
    harness.main()
