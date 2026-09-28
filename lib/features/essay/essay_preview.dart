import 'essay_models.dart';

// Authored synthetic fixtures. No university question, private Pilot answer,
// official answer or AI output is copied into the app bundle.
const essayPreviewQuestions = [
  EssayQuestion(
    id: 'shared-space',
    university: '가람대학교 (가상)',
    exam: '2026 모의논술 · 인문계',
    title: '문항 1 · 공공 공간과 선택',
    prompt: '제시문 (가)와 (나)의 관점을 비교하고, 도서관 공간을 어떻게 배분할지 자신의 견해를 설명하세요.',
    passages: [
      (
        label: '(가)',
        body: '공공 공간은 가능한 한 많은 사람이 이용할 수 있어야 한다. 이용자의 선호와 사용 시간을 살펴 공간을 조정하면 같은 자원으로 더 많은 사람의 필요를 충족할 수 있다.',
      ),
      (
        label: '(나)',
        body: '이용자의 수만으로 공간의 가치를 판단할 수는 없다. 조용한 환경이 꼭 필요한 사람처럼 선택지가 적은 이용자의 필요도 고려해야 한다. 함께 쓰는 공간의 규칙에는 서로 다른 필요를 조정하는 과정이 필요하다.',
      ),
    ],
    origin: CriteriaOrigin.basic,
    availability: EssayAvailability.ready,
    minLength: 270,
    maxLength: 330,
    examMinutes: 60,
  ),
  EssayQuestion(
    id: 'shared-space-2',
    university: '가람대학교 (가상)',
    exam: '2026 모의논술 · 인문계',
    title: '문항 2 · 주장과 근거',
    prompt: '다음 주장이 성립하기 위해 필요한 근거를 설명하세요.',
    passages: [
      (label: '(가)', body: '열람실의 이용 시간이 늘었다고 해서 모든 이용자의 만족도가 높아졌다고 단정할 수는 없다.'),
    ],
    origin: CriteriaOrigin.officialMock,
    availability: EssayAvailability.partial,
  ),
  EssayQuestion(
    id: 'question-only',
    university: '누리대학교 (가상)',
    exam: '2026 정규논술 · 인문계',
    title: '문항 1 · 요약',
    prompt: '주장의 핵심을 자신의 말로 요약하세요.',
    passages: [(label: '(가)', body: '자료를 읽을 때는 관찰한 사실과 그 사실에 대한 해석을 구분해야 한다.')],
    origin: CriteriaOrigin.basic,
  ),
  EssayQuestion(
    id: 'older-exam',
    university: '가람대학교 (가상)',
    exam: '2025 정규논술 · 인문계',
    title: '문항 1 · 비교 기준',
    prompt: '두 대상의 차이를 비교할 때 어떤 기준이 필요한지 설명하세요.',
    passages: [(label: '(가)', body: '서로 다른 대상을 비교하려면 공통으로 적용할 수 있는 기준이 필요하다.')],
    origin: CriteriaOrigin.basic,
  ),
];
const previewAnswer =
    '(가)는 많은 이용자의 필요를 충족하는 것을 중시하고, (나)는 선택지가 적은 이용자도 고려해야 한다고 본다. 나는 조용한 공간과 대화할 수 있는 공간을 나누는 것이 좋다고 생각한다. 이용자가 많다는 이유로 한쪽 공간을 없애기보다 서로 다른 필요를 함께 고려할 수 있기 때문이다.';
const previewExample =
    '(가)는 다수 이용자의 필요 충족을 중시하고, (나)는 선택지가 적은 이용자의 필요도 고려한다. 나는 조용한 공간과 대화 공간을 나누는 방안을 제안한다. 그러면 토론하려는 이용자는 대화를 나눌 수 있고, 집중할 장소가 필요한 이용자도 조용한 환경을 이용할 수 있다.';
const firstPreviewEvaluation = EssayEvaluation(
  summary: '두 관점의 차이를 구분하고 공간을 나누자는 입장을 제시했어요. 그 선택이 서로 다른 필요를 어떻게 충족하는지 한 단계 더 설명해 보세요.',
  strengths: ['두 제시문이 중요하게 보는 기준을 구분했어요.', '자신의 견해를 제시문의 내용과 연결했어요.'],
  dimensions: [
    EssayDimension(
      'understanding',
      '제시문 이해',
      4,
      '이용자 수와 선택지가 적은 사람의 필요를 각각 짚었어요.',
    ),
    EssayDimension(
      'reasoning',
      '논리와 구성',
      3,
      '공간을 나누는 방안과 기대하는 효과의 연결을 보충해 보세요.',
    ),
    EssayDimension('expression', '문장과 표현', 4, '문장이 간결하고 두 관점의 차이가 드러나요.'),
  ],
  improvements: ['공간을 나눴을 때 각 이용자가 얻는 이점을 한 문장씩 설명해 보세요.'],
  priorities: ['자신이 제시한 방안이 두 관점의 요구를 어떻게 충족하는지 연결해 보세요.'],
  checklist: [
    '두 관점을 같은 기준으로 비교했나요?',
    '내 방안의 효과를 구체적으로 설명했나요?',
    '안내된 분량을 확인했나요?',
  ],
  example: '(가)는 다수 이용자의 필요 충족을 중시하고, (나)는 선택지가 적은 이용자의 필요도 고려한다. 나는 조용한 공간과 대화 공간을 나누는 방안을 제안한다. 그러면 토론하려는 이용자는 대화를 나눌 수 있고, 집중할 장소가 필요한 이용자도 조용한 환경을 이용할 수 있다.',
  changes: {},
  includedRevision: true,
);
const secondPreviewEvaluation = EssayEvaluation(
  summary:
      '공간을 나누는 방안이 이용자에게 주는 이점을 더 구체적으로 연결했어요. 표현이 길어진 부분은 한 번 더 읽으며 다듬어 보세요.',
  strengths: ['기존 입장을 유지하면서 방안과 효과를 연결했어요.'],
  dimensions: [
    EssayDimension(
      'understanding',
      '제시문 이해',
      4,
      '두 관점을 정확하게 구분한 장점을 유지했어요.',
      previousLevel: 4,
    ),
    EssayDimension(
      'reasoning',
      '논리와 구성',
      4,
      '각 공간이 이용자의 필요를 충족하는 과정을 설명했어요.',
      previousLevel: 3,
    ),
    EssayDimension(
      'expression',
      '문장과 표현',
      3,
      '길어진 문장은 두 문장으로 나누면 더 읽기 편해요.',
      previousLevel: 4,
    ),
  ],
  improvements: ['한 문장에 담긴 내용을 나누어 표현해 보세요.'],
  priorities: ['가장 긴 문장부터 다시 읽어 보세요.'],
  checklist: ['기존 입장을 유지했나요?', '방안과 효과를 연결했나요?', '한 문장에 너무 많은 내용을 넣지는 않았나요?'],
  example: previewExample,
  changes: {
    '좋아진 부분': ['방안과 이용자의 필요를 연결하는 설명이 더 분명해졌어요.'],
    '좋아지고 있는 부분': ['두 관점의 차이를 바탕으로 자신의 견해를 전개하고 있어요.'],
    '아직 확인할 부분': ['길어진 문장을 나누어 읽기 쉽게 다듬어 보세요.'],
    '다시 나타난 부분': ['이번 표시 예시에서는 없어요.'],
  },
);

/// In-memory only, scoped to one preview page; never persists or contacts a server.
class PreviewEssayGateway implements EssayGateway {
  EssayDraft draft = const EssayDraft(previewAnswer, 0);
  final Map<String, ({String body, int revision, String id})> _requests = {};
  final List<String> submitted = [];
  bool failEvaluation = false;
  bool failSave = false;
  @override
  Future<EssayDraft> loadDraft() async => draft;
  @override
  Future<EssayDraft> saveDraft(String body, int expectedRevision) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (failSave) throw StateError('synthetic save failure');
    if (draft.revision != expectedRevision) throw EssayConflict();
    return draft = EssayDraft(body, expectedRevision + 1);
  }

  @override
  Future<String> submit(
    String body,
    int expectedRevision,
    String requestKey,
  ) async {
    final prior = _requests[requestKey];
    if (prior != null) {
      if (prior.body != body || prior.revision != expectedRevision) {
        throw EssayConflict();
      }
      return prior.id;
    }
    if (draft.revision != expectedRevision || draft.body != body) {
      throw EssayConflict();
    }
    final id = 'preview-${submitted.length + 1}';
    submitted.add(body);
    _requests[requestKey] = (body: body, revision: expectedRevision, id: id);
    return id;
  }

  @override
  Future<EssayEvaluation> requestEvaluation(String attemptId) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (failEvaluation) throw StateError('synthetic evaluation failure');
    // Fixture selection only. No pricing or eligibility determination here.
    return attemptId == 'preview-1'
        ? firstPreviewEvaluation
        : secondPreviewEvaluation;
  }
}
