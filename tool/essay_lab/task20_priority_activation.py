"""Prepare (never execute) exact additive release/rollback from inspected functions.

Fails on a different allowlist layout. Existing leaf IDs, ownership, ACL and
runtime/billing functions are untouched. Owner approval is required to apply.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
from .task20_priority_packages import literal


def prepare(root):
    packages=[json.loads(p.read_text()) for p in sorted((root/'packages').glob('*.private.json'))]
    assert len(packages)==6
    baseline=json.loads((root/'functions-before.json').read_text())
    assert {f['proname'] for f in baseline}=={'evaluation_admission','release_catalog'}
    leaves=[p['ids']['leaf'] for p in packages]
    apply=['begin;',"set local lock_timeout='5s';","set local statement_timeout='60s';"]
    rollback=['begin;',"set local lock_timeout='5s';"]
    records=[]
    for f in baseline:
        old=f['definition']
        assert hashlib.md5(old.encode()).hexdigest()==f['definition_md5']
        arrays=list(re.finditer(r"array\[(?:'[0-9a-f-]+'::uuid,?)+\]",old))
        assert len(arrays)==1, 'REVIEW_ALLOWLIST_LAYOUT'
        a=arrays[0];old_ids=re.findall(r"'([0-9a-f-]+)'::uuid",a.group())
        assert len(old_ids)==72 and len(set(old_ids))==72
        assert not set(leaves)&set(old_ids)
        new_array='array['+','.join(literal(i)+'::uuid' for i in sorted(old_ids+leaves))+']'
        new=old[:a.start()]+new_array+old[a.end():]
        sig='math_private.'+f['proname']+('()' if f['proname']=='evaluation_admission' else '(uuid)')
        check=lambda h:"do $drift$ begin if md5(pg_get_functiondef("+literal(sig)+"::regprocedure))<>"+literal(h)+" then raise exception 'TASK20_FUNCTION_DRIFT'; end if; end $drift$;"
        apply.append(check(f['definition_md5']))
        rollback.append(check(hashlib.md5(new.encode()).hexdigest()))
        records.append((new,old))
    # All six complete DRAFT package rows are checked before any activation.
    for p in packages:
        for table,rows in p['existing_schema_rows'].items():
            for row in rows:
                apply.append(f"do $content$ begin if not exists(select 1 from public.{table} t where id={literal(row['id'])} and to_jsonb(t) @> {literal(json.dumps(row,ensure_ascii=False))}::jsonb) then raise exception 'TASK20_PACKAGE_DRIFT'; end if; end $content$;")
    for p in packages:
        for table,key in [('math_problem_sets','set'),('math_problems','problem'),('math_evaluation_profiles','profile'),('math_canonical_solutions','solution')]:
            apply.append(f"update public.{table} set state='ACTIVE' where id={literal(p['ids'][key])} and state='DRAFT';")
    apply.extend(new.rstrip().rstrip(';')+';' for new,_ in records)
    rollback.extend(old.rstrip().rstrip(';')+';' for _,old in records)
    apply.append('commit;')
    rollback.extend(['-- Keep immutable content and all in-flight/completed attempts, results and ledger.',
                     '-- This closes new admission/catalog only. Restore WEB scope separately.','commit;'])
    (root/'activate.private.sql').write_text('\n'.join(apply)+'\n')
    (root/'rollback-release.sql').write_text('\n'.join(rollback)+'\n')
    exams=[]
    for slug,uid in [('konkuk','77fe30b2-f693-4612-a6d3-50e8be5c8f6c'),('kyunghee','b401cc24-dd17-575e-8ac6-0fd8c9c8405d')]:
        selected=[p for p in packages if slug in p['existing_schema_rows']['math_problem_sets'][0]['label']]
        bindings={p['essay_question_id']:p['ids']['leaf'] for p in selected}
        if slug=='konkuk':bindings={'cea40cf3-dc05-507a-a6eb-fd5e1e1847bb':'3bab07d3-c047-53c2-89ad-9fa20ec7b3f3',**bindings}
        exams.append(dict(examId=selected[0]['exam_id'],universityId=uid,questionIds=list(bindings),
            packageDigest=hashlib.sha256(json.dumps(selected,sort_keys=True).encode()).hexdigest(),
            label=f'{slug} 2026 자연 전체 문항',mode='math',mathQuestions=bindings))
    (root/'web-expansion-additions.json').write_text(json.dumps(dict(exams=exams,appendPublicLeaves=leaves),ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(dict(new_packages=6,new_rows=96,existing_leaves=72,after_leaves=78,production_writes=0)))


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('root',type=Path)
    prepare(parser.parse_args().root)
