# 이화여대 63문항 운영 연결·공개 · 2026-11-12

현재 단계: 사전 검증 PASS, 운영 DB 적용·공개 대기. Owner의 63문항 연결·공개 승인을 근거로 진행한다. 기준 APP 3caadae / WEB aaeb700. 별도 모의 24문항은 기준 미확보로 보류하며 기존 운영 모의 1시험3문항을 보존한다.

## 확정 범위와 검증

21시험63문항 = Math9시험27 + Essay12시험36. 신규 Registry84행, Math403행, Essay48행으로 총535행. Math 내부2허용목록과 Essay runtime_policy의12CASE만 추가한다. 새RPC0, 기존 엔진·prompt·Provider·Credit 정책은 유지한다. 기존 레거시 is_active/is_published flags는 변경하지 않고 기존 Math public catalog와 whole-exam runtime·WEB scope 계약으로 공개한다.

Math 격리 제출·결과·재작성·재첨삭297 계약검사, 사전50·사후116 PASS. Essay36/공식이미지200개,72 mock 결과·재작성cycle,4종변조거부 PASS. 기존 adapter가 공식 의도·채점표 이미지를 거부하는2조건만 수정하며 기존 Worker73파일 중71파일 바이트불변. 비활성 버전의 binding 상속과 컴파일 검증 완료, 활성화는 사후 DB 검증 후 진행한다.

문제원본21PDF만 학생 뷰어에 연결. 원본58개는 변경·이동하지 않는다.42문제·해설PDF에 명시적 제한 문구를 발견하지 않았으나 독립적인 법적 허락 판정을 뜻하지 않는다. Owner 공개 승인 범위를 적용하며해설21PDF는공개목록·Storage에서제외. 신규 정책은21개 정확SHA 이름+authenticated+account_service_allowed 조건으로만허용. 기존272정책 변경0. 격리 정상/탈퇴대기/삭제중/알수없는계정/UID없음/anon 검증과접근회수원복PASS.

WEB1965PASS/10FAIL/5SKIP.10FAIL은기준aaeb700에서도동일재현(관리자6·Credit4),신규FAIL0. TypeScript·Next webpack·Functions빌드PASS. APP3PASS. 실제브라우저·기기·로그인후제출·AI품질NOT TESTED. Provider 호출0.

## 적용·원복

1. 원본21문제PDF를새SHA객체로업로드·재다운로드SHA확인. 기존객체덮어쓰기0.
2. Registry→Math→Essay→Storage를하나의REPEATABLE READ트랜잭션으로실행. 사전/사후검사와기존데이터·함수/ACL·RLS보존비교실패시전체ROLLBACK. 검증된SQLSHA는production-sql-plan.json.
3. 기존Worker바인딩·큐·Secret을상속한비활성버전을활성화.자료Registry와adapter만변경.이후실제DB package와배포source를Provider없이재검증.
4. WEB essay경로만배포. 기존정적2195자산·API소스·라우팅·Preview·Secret을보존. public시험334→355/beta164→185/Math393→420.
5. 장애시새WEB scope를닫고이전Pages배포를복원,Worker이전version d03763e8-dcf7-4644-ac59-b7440cee87d7복원,신규Math27·Essay12허용목록과신규PDF정책만회수. Registry·자료·학생답안/결과/이력·PDF객체삭제금지.다른배포가끼면자동과거전체함수복원금지;새scope만제거한다.

## 보존 원칙

시험학년도/자료기록일/정정일을구분한다. 원본SHA·이력불변,기존학생식별자·답안·결과계보보존.학습사실·평가·진학결과를섞지않고공식원문과모델출력을분리한다.개인정보수집·접근목적·보존기간·Credit정책변경0.

Canonical 후보: [ewha_public_20261112](../supabase/candidates/ewha_public_20261112/). 원문payload는ignored .local에보관하고Git에는메타데이터·검증·SQL범위/SHA만기록한다.운영실행결과는후속영수증과이문서에갱신한다.자연계열잔여43개와이화모의24개는별도분모로관리한다.
