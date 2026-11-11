// Reuses actual WEB modules with candidate metadata and Mock transport only.
import {describe,it,expect,vi} from 'vitest';
import {readFileSync,existsSync} from 'node:fs';
vi.mock('__WEB_ROOT__/src/data/essay-beta-expansion.json', async()=>({default:JSON.parse((await import('node:fs')).readFileSync('__CANDIDATE_ROOT__/web-expansion-candidate.json','utf8'))}));
vi.mock('__WEB_ROOT__/src/data/essay-question-inputs.json', async()=>({default:JSON.parse((await import('node:fs')).readFileSync('__CANDIDATE_ROOT__/web-input-candidate.json','utf8'))}));
vi.mock('__WEB_ROOT__/src/data/essay-student-pdf-candidates.json',async()=>{const fs=await import('node:fs');const p='__CANDIDATE_ROOT__/'+(fs.existsSync('__CANDIDATE_ROOT__/web-pdf-existing-reuse.json')?'web-pdf-existing-reuse.json':'web-pdf-candidate.json');return {default:{questions:JSON.parse(fs.readFileSync(p,'utf8'))}};});
vi.mock('__WEB_ROOT__/src/data/essay-source-registry.json', async()=>{
 const fs=await import('node:fs');const original=JSON.parse(fs.readFileSync('__WEB_ROOT__/src/data/essay-source-registry.json','utf8'));
 if(fs.existsSync('__CANDIDATE_ROOT__/web-source-registry-candidate.json'))return {default:JSON.parse(fs.readFileSync('__CANDIDATE_ROOT__/web-source-registry-candidate.json','utf8'))};
 const extra=JSON.parse(fs.readFileSync('__CANDIDATE_ROOT__/web-source-registry-additions.json','utf8'));
 for(const row of extra.exams)if(original.exams.some((e:any)=>e.key===row.key||e.dbExamId===row.dbExamId))throw Error('DUPLICATE_SOURCE_CANDIDATE');
 return {default:{...original,exams:[...original.exams,...extra.exams]}};
});
let catalog:any[]=[];
vi.mock('__WEB_ROOT__/src/lib/math-release/server/transport',()=>({serverTransport:()=>({subject:async()=> 'synthetic-ordinary-user'}),publicMathLeaves:()=>[]}));
vi.mock('__WEB_ROOT__/functions/api/essay/availability',()=>({onRequestGet:async()=>Response.json({checked:true,types:{math:true},mathQuestions:catalog})}));
import {betaExpansionCandidates,expansionMathMatches,betaExpansionFor} from '__WEB_ROOT__/src/lib/essay-runtime/beta-expansion';
import {onRequestPost} from '__WEB_ROOT__/functions/api/essay/exam';
import {questionInputMode} from '__WEB_ROOT__/src/lib/essay-runtime/input-mode';
import {studentPdfForExam,studentPdf} from '__WEB_ROOT__/src/lib/materials/student-asset';
const pdfs=JSON.parse(readFileSync('__CANDIDATE_ROOT__/'+(existsSync('__CANDIDATE_ROOT__/web-pdf-existing-reuse.json')?'web-pdf-existing-reuse.json':'web-pdf-candidate.json'),'utf8'));
const origin='https://lab.legendstudy.com';
for(const e of betaExpansionCandidates){
 describe(`Natural candidate ${e.examId}`,()=>{
  const env={MATH_ORIGIN:origin,MATH_PROJECT_REF:'stlhijzpjfgwwdgunlsd',MATH_SUPABASE_URL:'https://stlhijzpjfgwwdgunlsd.supabase.co',ESSAY_PUBLIC_EXAMS:e.examId,ESSAY_BETA_EXPANSION_EXAMS:e.examId,ESSAY_EXAM_RUNTIME_ENABLED:'true'};
  const request=()=>new Request(origin+'/api/essay/exam',{method:'POST',headers:{Authorization:'Bearer synthetic',Origin:origin},body:JSON.stringify({action:'availability',examId:e.examId})});
  const rows=()=>Object.entries(e.mathQuestions).map(([questionId,leafId])=>({examId:e.examId,questionId,leafId}));
  it('requires explicit scope and exact complete Registry/leaf mapping',async()=>{
   expect(e.questionIds.length).toBeGreaterThan(0);catalog=rows();expect(expansionMathMatches(e,catalog)).toBe(e.completeExam!==false);
   const dto=await (await onRequestPost({request:request(),env})).json();expect(dto.ready).toBe(e.completeExam!==false);if(e.completeExam!==false){expect(dto.questionIds).toEqual(e.questionIds);expect(dto.mathQuestions).toEqual(e.mathQuestions);}
   expect(betaExpansionFor(origin,{},e.examId)).toBeUndefined();
   expect(betaExpansionFor('https://unapproved.example',env,e.examId)).toBeUndefined();
  });
  it('denies missing and duplicate catalog mappings',async()=>{
   for(let i=0;i<rows().length;i++){
    catalog=rows().filter((_,n)=>i!==n);expect(expansionMathMatches(e,catalog)).toBe(false);
    const dto=await (await onRequestPost({request:request(),env})).json();expect(dto.ready).toBe(false);
   }
   catalog=[...rows(),rows()[0]];expect(expansionMathMatches(e,catalog)).toBe(false);
  });
  it('retains native image input and blocks foreign exam identity',()=>{
   for(const q of Object.keys(e.mathQuestions)){expect(questionInputMode(e.examId,q)).toBe('image');expect(questionInputMode('foreign',q)).toBe('unknown');}
  });
  it('preserves existing PDF approval state and exact asset/page bounds',()=>{
   for(const q of Object.keys(e.mathQuestions)){
    const p=pdfs.find((p:any)=>p.questionId===q&&p.examId===e.examId);expect(p).toBeTruthy();
    if(p.studentDisplay==='APPROVED'&&p.verification==='VERIFIED')expect(studentPdfForExam(e.examId,q)).toBeTruthy();else expect(studentPdfForExam(e.examId,q)).toBeNull();
    // Hypothetical isolated DTO only. Does not mutate manifest/storage/public gates.
    const dto={...p,bucket:'essay-student-questions',kind:'student_question',sha256:p.assetId,verification:'VERIFIED',studentDisplay:'APPROVED'};
    expect(studentPdf(dto,q)).toBeTruthy();expect(studentPdf({...dto,startPage:p.pageCount+1},q)).toBeNull();
   }
  });
 });
}

import {connectPublishedQuestions} from '__WEB_ROOT__/src/lib/essay-runtime/canonical-catalog';
it.skipIf(!existsSync('__CANDIDATE_ROOT__/ten-university-registry.json'))('uses the existing shared Registry connector for the ten-university follow-up without granting evaluation',()=>{
 const live=JSON.parse(readFileSync('__CANDIDATE_ROOT__/ten-university-registry.json','utf8')).rows;
 const source=JSON.parse(readFileSync('__WEB_ROOT__/src/data/essay-source-registry.json','utf8')).exams;
 const universities=new Set(live.map((r:any)=>r.university_id));
 const selected=source.filter((e:any)=>universities.has(e.universityId));
 const rows=live.map((r:any)=>({...r,essay_exam_id:r.exam_id,essay_exams:{university_id:r.university_id,admission_year:r.admission_year,exam_kind:r.exam_kind}}));
 const connected=connectPublishedQuestions(selected,rows,true);
 const complete=connected.filter(e=>e.questions.every(q=>q.dbQuestionId));
 expect(complete).toHaveLength(28);expect(complete.flatMap(e=>e.questions)).toHaveLength(94);
 for(const exam of connected){
  expect(exam.evaluationReady).toBe(false);
  for(const q of exam.questions.filter(q=>q.dbQuestionId)){
   expect(q.accountDraftReady).toBe(false);
   expect(live.some((r:any)=>r.id===q.dbQuestionId&&r.exam_id===exam.dbExamId)).toBe(true);
  }
 }
 const unmatched=connected.filter(e=>!e.questions.every(q=>q.dbQuestionId));
 expect(unmatched).toHaveLength(1);expect(unmatched[0].sourceUniversityId).toBe('yonsei');
});

import {catalogUniversity} from '__WEB_ROOT__/src/lib/essay-runtime/public-discovery';
import {sourceExams} from '__WEB_ROOT__/src/lib/essay-runtime/source-registry';
it('connects university, source exams and exact candidate Registry IDs without publication',()=>{
 const all=JSON.parse(readFileSync('__CANDIDATE_ROOT__/'+(existsSync('__CANDIDATE_ROOT__/web-source-registry-candidate.json')?'web-source-registry-candidate.json':'web-source-registry-additions.json'),'utf8')).exams;
 for(const e of betaExpansionCandidates){
  const row=all.find((s:any)=>s.dbExamId===e.examId)!;expect(row).toBeTruthy();
  expect(catalogUniversity(row.sourceUniversityId)?.universityId).toBe(e.universityId);
  const source=sourceExams(row.sourceUniversityId).find(s=>s.dbExamId===e.examId)!;expect(source).toBeTruthy();
  expect(source.questions.map(q=>q.dbQuestionId)).toEqual(e.questionIds);expect(source.evaluationReady).toBe(false);
  for(const q of source.questions){expect(q.accountDraftReady).toBe(false);}
  for(const q of Object.keys(e.mathQuestions)){expect(questionInputMode(e.examId,q)).toBe('image');}
 }
});
it('keeps incomplete mixed-subject exams outside the expansion gate',()=>{
 const raw=JSON.parse(readFileSync('__CANDIDATE_ROOT__/web-expansion-candidate.json','utf8'));
 for(const e of raw.blockedExams??[]){
  expect(e.questionIds.length).toBeGreaterThan(Object.keys(e.mathQuestions).length);
  expect(betaExpansionCandidates.some(x=>x.examId===e.examId)).toBe(false);
  expect(betaExpansionFor(origin,{MATH_ORIGIN:origin,MATH_PROJECT_REF:'stlhijzpjfgwwdgunlsd',MATH_SUPABASE_URL:'https://stlhijzpjfgwwdgunlsd.supabase.co',ESSAY_PUBLIC_EXAMS:e.examId,ESSAY_BETA_EXPANSION_EXAMS:e.examId},e.examId)).toBeUndefined();
 }
});
