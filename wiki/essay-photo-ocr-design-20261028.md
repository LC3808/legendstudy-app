# 논술 LAB 사진 → TEXT 입력 보조 설계 — 2026-10-28

상태: 이 문서는 초기 설계·macOS 합성 인쇄 PoC 근거다. 이후 Owner 추가 지시로 [APP 온디바이스 OCR 구현·Release 빌드](app-final-integration-20261028.md)를 완료했다. 실제 학생 손글씨·실기기 QA·스토어 출시 검증은 미완료. 아래 ‘설계만/미통합’ 표현은 초기 조사 시점 기록이다.
Owner 10/28 지시를 기존 [TEXT/공유 Gateway](phase3-service-20261022.md),
[입력 축·사진 원본 원칙](roadmap-essay-lab.md),
[Math 사진 추출 검토](math-technical-review-20261026.md),
[학습 이력 보존](longitudinal-learning-admissions-data-strategy.md)에 연결한다.
기존 Math/IMAGE, 평가 엔진, Worker, Credit, History 계약 변경 없음.

## 권장안과 선택 근거

**온디바이스 우선 PoC: iOS Vision + Android ML Kit Korean, 공통 Flutter 확인·편집 화면.**
한국어 손글씨 성능이 확보된 최종 제품 선택이라는 뜻은 아니다. 실필기 기준 미달이면
온디바이스 기능을 손글씨용으로 출시하지 않고, Owner 승인 후 Google Cloud Vision
DOCUMENT_TEXT_DETECTION을 동일 샘플로 비교한다. 외부 서비스 자동 fallback은 없다.
LLM Vision은 원문을 보완·교정해 버릴 위험 때문에 기본 전사 엔진으로 우선 선정하지 않는다.

|비교 항목|iOS Vision|Android ML Kit v2 Korean|Google Cloud Vision|기존 LLM Vision 계열|
|---|---|---|---|---|
|한국어 손글씨|실제 학생 필기 미측정; 언어 지원과 필기 정확도 구분|사진 손글씨 품질 보증 근거 없음, 실측 필수|공식 언어표 Kore handwriting Supported; 정확도 수치는 별도 실측|현재 OCR용 모델/프롬프트별 미측정; 추정·누락·문장교정 위험|
|한국어 인쇄|macOS 합성3장 CER/WER0; iOS 미측정|한국어 모델 지원, 이 프로젝트 미측정|한국어 OCR 지원, 이 프로젝트 미측정|지원 가능 범위와 실제 정확도 별도; 한국어 이미지 한계 문서 존재|
|문단·줄|관측 line/box 활용; 빈 줄 자동보존 안 됨|block/line/element 좌표로 재구성 필요|page/block/paragraph/word와 break 정보 제공, 원래 문단 정답 보증 아님|요청한 형태로 출력 가능하나 임의 줄합침·문단변경 검수 필요|
|숫자·영문·기호|합성 제한 표본 PASS; 수식 미검증|별도 mixed 표본 검증 필요|별도 mixed 표본 검증 필요|기호·수식·공간관계 오류 위험, Math 대체 금지|
|속도|기기/해상도/OS별; 아래 Mac 결과만 실측|기기/모델준비 영향, 미측정|업로드+API+네트워크, 미측정|업로드+모델 출력 길이 영향, 미측정|
|호출 비용|별도 OCR API 과금0|SDK 무상, OCR 호출 과금0|이미지/기능별 과금|모델별 이미지·텍스트 입력 및 출력 토큰 과금|
|개인정보|이미지 인식은 기기 내|입출력 기기 내, SDK 성능/사용 지표 전송은 별도|크롭 이미지 외부 전송; 아래 정책 적용|이미지·전사 지시·출력 외부 처리; 아래 정책 적용|
|오프라인|지원 OS/언어에서 가능|번들 Korean 모델 권장; 다운로드형은 최초 준비 전 불가|불가|불가|
|Flutter 연동|Swift MethodChannel, 중간|Kotlin MethodChannel 또는 커뮤니티 래퍼, 중간|공통 UI + 인증 서버 프록시, 중상|기존 Math API 직접 재사용 불가; 별도 전사 경계 필요, 높음|
|동일 UX|공통 Dart UI 가능; 인식 결과는 OS별 다름|왼쪽과 동일|양 OS 같은 API여도 촬영 차이는 존재|동일 UI 가능, 출력 변동성 검수 필요|

근거: [Apple Vision](https://developer.apple.com/documentation/vision/recognizing-text-in-images),
[한국어 추가 WWDC22](https://developer.apple.com/videos/play/wwdc2022/10024/),
[ML Kit Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android),
[언어 지원](https://developers.google.com/ml-kit/vision/text-recognition/v2/languages),
[Cloud handwriting](https://docs.cloud.google.com/vision/docs/handwriting),
[Cloud 언어/필기 지원표](https://docs.cloud.google.com/vision/docs/languages),
[LLM 이미지 한계](https://developers.openai.com/api/docs/guides/images-vision).
Digital Ink는 펜 stroke 입력용이므로 촬영 사진 OCR의 대체 기술이 아니다.

## 실제 코드 확인 및 Claude 연결 지점

Codex 작업트리 `codex/material-service-app-20261022`, HEAD d5714b8 기준 기존 미커밋
변경 포함 읽기 전용 확인. 이를 실제 배포 APP으로 단정하지 않는다. Claude 폴더도 읽기만 했다.

- `lib/features/essay/answer_image.dart`: `answerImageType`, `_AnswerImageInputState.pick`,
  `AnswerImagesInput`. image_picker, JPEG/PNG/WebP20MB, 기존 첨부 최대6장.
- Codex 폴더에는 `answer_image_crop.dart`가 없다. Claude 폴더
  `/Users/woojinchang/development/legendstudy-app-claude-20261028/lib/features/essay/answer_image_crop.dart`의
  `cropAnswerImage`, `AnswerCropOutcome(bytes,retake)` 및 `answer_image.dart`의 연결만 참조했다.
  dart:ui 로컬 크롭·PNG 반환·취소 시 기존값 유지. 이를 머지/수정하지 않았다.
  사각 크롭은 원근 보정/회전/흐림 개선을 보장하지 않으며 해당 기능 추가는 별도 범위다.
- `source_catalog_page.dart`: 답안 편집 상태의 `importPrevious()`는 덮어쓰기 확인 후
  `editor.text` → `controller.edit()` → `save()`를 사용한다. 같은 전달 패턴 재사용.
- `essay_controller.dart`: `EssayController.edit`의650ms 자동저장, `save`의 저장 직렬화·충돌 상태 재사용.
- `source_draft.dart`: `SourceDraftGateway.saveLocalDraft`30,000자, `sync`20,000자,
  local revision 충돌 검사와 remote conflict 안내. 임의 절단 금지; 초과 시 기존 저장 경계를
  그대로 표시하고 학생이 편집하도록 한다. controller.save가 원격 저장도 호출할 수 있으므로
  ‘OCR 로컬 처리’가 ‘적용된 답안도 영구 오프라인’이라는 뜻은 아니다.
- **중요:** `_ExamSubmitState.submit()`는 `images.isNotEmpty`이면 TEXT 제출을 차단한다.
  OCR 사진을 `SourceDraftGateway.saveImages()`의 기존 평가 첨부에 자동 추가하면 안 된다.
  기존 사진 첨부를 숨기거나 삭제하거나 제출 가드를 우회해서도 안 된다.

제안 인터페이스(미구현): `AnswerOcrEngine.recognize(croppedImage, operationId)` →
`OcrDraft(text, lines/boxes, engineRevision, language, warnings)`.
`onApplyConfirmedText(String)`만 기존 작성 위젯으로 넘긴다. 평가 payload에 OCR 객체,
이미지, 엔진 confidence, 새로운 입력 유형을 추가하지 않는다.

```text
TEXT 작성 화면의 [사진으로 답안 입력]
 → 기존 촬영/갤러리 및 크롭 UI 재사용(Claude 확정 인터페이스 기준)
 → OCR 전용 로컬 작업 사진(평가 첨부 목록과 별도)
 → 기기 내 인식 → 원본/크롭 보기 + 편집 가능한 전사 미리보기
 → 학생 확인 → [답안에 적용] → 기존 내용 있으면 교체 확인
 → editor/controller.edit → 기존 자동저장·수동저장·충돌 안내
 → 학생이 별도로 기존 첨삭 버튼 → 기존 TEXT body/revision 제출
```

- OCR 시작 당시 owner/question/rewrite draft key/body revision/hash를 캡처한다.
  인식 중 문항/계정 이동·텍스트 수정·새 사진 선택 시 오래된 결과를 자동 적용하지 않는다.
  적용 시 현재값 재확인, 충돌이면 두 텍스트 보존하고 재확인한다. 적용 버튼 중복 탭 방지.
- 인식 실패/빈 결과/취소는 기존 답안을 건드리지 않는다. 실패 시 작업 사진과 기존 첨부는
  유지하고 재시도·재촬영·직접 입력 제공. 재촬영 성공 전 이전 사진을 제거하지 않는다.
- 초기안은 1장씩 검토·적용, 여러 장은 학생이 순서를 확인하며 반복한다. 이어붙이기는
  명시 선택과 구분 줄바꿈을 사용하고 기본 교체를 몰래 append로 바꾸지 않는다.
- 줄바꿈·문단은 좌표에 근거한 후보일 뿐. 원문 철자/기호를 보정·요약하거나 정답으로
  채우지 않는다. 엔진 confidence가 없는 경우 가짜 확률 표시 금지, 엔진 간 숫자 비교 금지.
- OCR 전용 사진은 세션 작업공간에 유지, 실패 시 유지, 명시 취소/닫기 확인 또는 로그아웃 시
  작업 복사본 정리. 갤러리 원본과 기존 평가 첨부는 삭제하지 않는다. 앱 강제종료 후 OCR
  미적용 내용 복원은 초기안 보장 밖이며 자동 저장 완료된 기존 TEXT는 기존 계약대로 복원.
- 이미지 바이트20MB와 디코딩 메모리는 별개다. 픽셀 수/메모리 상한, EXIF 방향,
  회전·한글 최소 글자 해상도, HEIC 입력 현재 거절 여부를 실기기에서 확인한다.
  긴 변 무조건 축소 대신 읽을 수 있는 해상도를 유지하고 oversized는 재촬영 안내한다.

## 플랫폼·패키지 계획

- iOS: Swift `VNRecognizeTextRequest` accurate, `supportedRecognitionLanguages()`로 ko-KR
  가용성 확인, ko-KR/en-US 후보, 원문 보존을 위해 language correction off부터 검증.
  기존 deployment target15.0이므로 한국어 지원을 모든 설치기기에 가정하지 않는다.
  미지원 OS는 기능 안내·직접입력 유지, 강제 OS 상향/클라우드 전송 없이 종료한다.
- Android: `com.google.mlkit:text-recognition-korean` 번들 모델 + KoreanTextRecognizerOptions.
  공식 문서의 현재 예시는16.0.1. 실제 구현 승인 시 Flutter/Gradle/minSdk/SDK 라이선스
  호환 확인 후 버전 고정. 현 minSdk는 flutter.minSdkVersion 참조라 실효값 재확인 필요.
- Flutter: 기존 image_picker ^1.2.3와 Claude 크롭 재사용. 공통 Dart UI + 플랫폼 channel을
  우선안으로 하여 의존성 추가를 제한. `google_mlkit_text_recognition`은 대안 커뮤니티
  래퍼로 SDK와 별도 유지보수/최소 OS/한국어 의존성을 검토해야 한다. 이번 설치0.
- Cloud 선택 시 APP에 비밀키를 넣지 않는다. 추후 승인된 인증/용량/중복요청/비용 제한을
  가진 OCR 전용 프록시가 필요하며 현재 평가 Worker/Math 추출/첨삭 Credit을 호출하지 않는다.
- LLM은 기존 Math artifact→추출→confirm 계약을 TEXT OCR에 몰래 재사용하지 않는다.
  현재 승인된 평가 모델이 OCR 전사에도 승인됐다고 간주하지 않는다.

## 로컬 PoC 결과와 미검증 범위

실제 학생 필기 + 정답 전사 + 사용 범위가 검증된 세트를 확보하지 못했다. 기존 Wiki의
Math 합성 인쇄 성공이나 공식 답안 PDF를 실제 필기 성능으로 재사용하지 않았다.
검사 범위는 관련 fixture/운영 기록이며 다른 학생 DB·비공개 저장소를 뒤지지 않았다.

신규 격리 산출물: [실행 코드](../tool/poc/essay_ocr_20261028/vision_printed.swift),
[측정 코드](../tool/poc/essay_ocr_20261028/measure.py),
[원본 관측](../tool/poc/essay_ocr_20261028/raw.json),
[측정 결과](../tool/poc/essay_ocr_20261028/results.json).
학생 데이터 없음. AppKit으로 직접 만든 인쇄 문장 PNG3장, AppleSDGothicNeo46px,
1800×900, macOS26.6.1 arm64, Vision revision3, accurate/ko-KR+en-US/correction off.
3회씩 총9회 로컬 실행, 외부 API/Provider0, API 비용0. 생성 이미지의 문단/잘림도 시각 확인.

|합성 유형|정답 문자/어절 수|CER|WER|인식시간3회(초)|구조|
|---|---:|---:|---:|---|---|
|인쇄 한국어2줄|53/13|0%|0%|0.491/0.113/0.105|2줄 보존|
|문단 구분4줄|110/29|0%|0%|0.126/0.122/0.122|4줄 보존, 빈 문단 경계는 단순 join에서 유실|
|숫자·영문·기호3줄|92/23|0%|0%|0.100/0.094/0.102|3줄 보존|

CER=(대체+삭제+삽입)/정답 문자수, WER는 같은 편집거리/공백 구분 어절수.
NFC 후 연속 공백·줄바꿈을 단일 공백으로 접고 대소문자·문장부호 유지. 문단 검사는 별도라
CER0이 문단 완전 보존을 뜻하지 않는다. 반복 출력은 유형별3회 동일했다.
측정 구간은 Vision perform이며 사진 촬영/디코딩/Flutter/UI·학생 검토 시간은 제외한다.
페이지마다 첫 trial은 해당 이미지 첫 호출이며 앱 cold start는 첫 이미지 첫 trial만 해당한다.
합성 총255자에 불과하다. **예상 실제 정확도 수치, 모바일 처리시간, 손글씨 우열을 산출할 수 없다.**
또박 필기/일반 필기/장문/그림자·기울기·조명은 미검증이며 인쇄 PoC로 대체하지 않는다.

재현(네트워크/자격증명 불필요):
```sh
xcrun swift tool/poc/essay_ocr_20261028/vision_printed.swift /tmp/legendstudy-ocr-printed-20261028
python3 tool/poc/essay_ocr_20261028/measure.py /tmp/legendstudy-ocr-printed-20261028/raw.json
```

후속 실제 표본 계획(미실행): 동의·비식별화된 최소60페이지/10명 이상, Owner 제시6유형별
최소10장(필기자 다양성과 조명 변형은 동일 원본 묶음으로 관리). 원본을 사람이 두 번
전사·불일치 조정하고 페이지·문단 경계를 정답에 기록. 실제 장문800–2000자 및 수정흔적 포함.
같은 크롭·해상도·정답으로 엔진 비교, 작성자별 검증 세트 분리. CER 공백포함/제외,
어절 WER, 문단 boundary precision/recall/F1, 줄순서 오류, 인식 실패율, 학생 수정 시간,
기기/OS별 cold/warm p50/p95, 이미지 크기·호출수·실비를 기록한다.
현재9회로 p95 SLA를 주장하지 않는다. 각 인쇄/필기/열화 유형을 따로 보고하며 쉬운
인쇄 표본으로 필기 평균을 가리지 않는다. 채택 기준은 수동 입력 대비 수정시간 감소와
누락 위험을 포함해 표본 결과 후 Owner가 확정한다.

## 보안·보관·비용

- 기기 내 OCR API 호출비0. 카메라 권한/로컬 사진 복사본 보안, 앱 백업 포함 여부,
  로그아웃 정리와 crash log 원문 제외는 통합 검증 대상이다. ML Kit 입출력은 Google로
  전송하지 않지만 성능/사용 지표 및 모델 업데이트 통신이 있으므로 무통신 SDK로 광고하지 않는다.
  [ML Kit 정책](https://developers.google.com/ml-kit/terms), [무상 SDK](https://developers.google.com/ml-kit/guides).
- Cloud Vision은 동기 이미지 OCR 사용을 우선 비교: 크롭 이미지와 언어 hint만 전송,
  이름·학생ID·시험이력 불필요. 공식 FAQ상 동기 이미지는 메모리 처리·디스크 비저장,
  비동기는 보통 완료 직후 삭제/최대 수시간 TTL; 일부 요청 metadata 일시 로그, 구체 기간
  FAQ 미명시. 학습 개선에 사용하지 않음. 우리가 쓰는 프록시 로그·Storage 보관은 별도라
  원문 로그 금지/저장 안 함 원칙을 검증해야 한다. 국내 리전 처리라고 가정하지 않는다.
  [데이터 정책](https://docs.cloud.google.com/vision/docs/data-usage).
- Cloud DOCUMENT_TEXT_DETECTION 가격: 월 첫1000단위 무료, 이후500만까지 $1.50/1000단위,
  그 이상 $0.60/1000단위. 1이미지×1기능=1단위; 재시도도 청구 가능.
  예: 월10000페이지 약$13.50, 월100000페이지 약$148.50(해당 무료구간 전체 사용 가능 가정).
  일반 유료구간2장/답안=$0.003, 6장=$0.009. 세금/환율/서버·저장·전송비 별도.
  [가격](https://cloud.google.com/vision/pricing). 이번 도입/호출0.
- OpenAI 계열 LLM API는 기본적으로 opt-in 없으면 학습 사용하지 않지만 abuse logs
  통상 최대30일, Responses 저장 상태/캐시/이미지 안전 검토 예외는 별도다.
  store=false만으로 모든 보관0을 보장하지 않는다. 현 계정의 ZDR·리전·프로젝트 설정은
  확인하지 않았으므로 미확인. 학습/보관 승인을 기존 평가 계약에서 확장 추정하지 않는다.
  [데이터 제어](https://developers.openai.com/api/docs/guides/your-data).
- LLM 비용=(이미지+지시 입력토큰×입력단가 + 전사 출력토큰×출력단가)/1,000,000.
  모델/해상도/출력량 미선정이라 실비 추정 불가. 도입 판단에는 승인된 모델의
  공식 단가·샘플 사용량이 필요하며 기존 평가 비용을 OCR 비용으로 가져오지 않는다.
- 외부 OCR은 추가 명시 동의/전송 설명/Owner 유료API 승인 후만 검증한다. 대량 업로드,
  개인정보 없는 척한 원본 전송, 평가 목적 외 학습/analytics 수집을 하지 않는다.

## 일곱 보존 검토와 구현 완료 조건

1. 발생 fact: 사진 입력·인식 후보·학생 적용은 서로 다르다. 최종 학생 작성 TEXT만 기존
   draft revision/제출 snapshot이 담당; OCR 성공을 평가완료로 기록하지 않는다.
2. 복원: 최종 제출 텍스트는 기존 snapshot으로 재현. 세션 종료 후 OCR 후보/사진 복원은
   보장하지 않으며 원본 보존 기능이 있는 것처럼 주장하지 않는다. 기존 첨부는 그대로다.
3. 덮어쓰기: 적용 전 명시 확인, 현재 revision 검증, 실패 시 기존 body 유지. draft는 기존
   mutable 정책; 제출된 답안/History는 수정하지 않는다. 영구 OCR 감사저장은 이번 범위 밖.
4. identity: owner/question/rewrite key에 작업을 묶고 계정 변경 시 적용 차단·임시 복사 정리.
5. 영역: Learning 입력 보조이며 능력/성장/성적/입시 Outcome 데이터가 아니다.
6. 개인정보: 온디바이스 우선·원문 로그 금지·세션 사진 수명 명시. 외부 전송은 별도 승인,
   사용자 설명/동의·처리지역/보관 설정 검증 후. 타 학생 공유/집계 없음.
7. derived: OCR 후보는 추정 전사이며 원문 사실이 아니다. 학생 확인 전 draft body/평가에
   쓰지 않는다. 엔진 revision·경고는 세션 진단용으로만 두고 기존 제출 payload에 추가하지 않는다.

난이도: 온디바이스 공통 UX **중간**, 실필기 품질 확보·양 OS/저사양 QA **중상**,
외부 OCR의 개인정보·인증·비용 통제 **중상**. 계획 추정으로 온디바이스 기술 PoC2–3일,
승인 후 UI/저장 연결3–5일, 기기·필기 QA3–5일(1명 개발자, 표본 준비/Claude 확정·리뷰 대기 제외).
측정된 개발 일정이나 출시 약속은 아니다.

Owner 승인 후 순서: 실제 표본 확보 → 양 OS 인식 비교/문단 복원 → 결과 채택 판단 →
Claude 인터페이스 확정 → 공통 확인 UI/안전한 text callback → 저장/취소/충돌/기존 첨부 회귀 →
실기기 승인. 외부서비스 필요 시 별도 승인. 이번에는 APP/Claude/DB/Worker/Credit/History
변경0, 유료API 설치0, Provider0. 기존 운영 성공 사례나 이번 인쇄 PoC를 손글씨 출시 PASS로 쓰지 않는다.
