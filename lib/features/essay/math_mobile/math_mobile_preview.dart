import 'package:flutter/material.dart';

import 'academic_purple.dart';
import 'coaching_contract.dart';
import 'math_coaching_screen.dart';
import 'math_recognition_panel.dart';

/// Offline visual fixture only. Never persisted or sent to a Provider.
Map<String, dynamic> mathMobilePreviewSnapshot() => {
  'version': 'math-coaching-v1',
  'evaluation_id': 'preview-only',
  'disclosed': false,
  'university': '한양대학교 · 화면 검수 예제',
  'exam_label': '수리논술 · 문제 1',
  'diagnosis': '풀이 방향은 적절합니다. 계산 과정과 조건의 논리적 연결을 확인해 보세요.',
  'strengths': [
    {
      'title': '문제 조건에 맞는 풀이 전략',
      'description': '미분을 활용해 문제에 접근했습니다.',
      'student_formula': r'f(x)=(3x^2+1)^4',
    },
  ],
  'tasks': [
    {
      'id': 'chain',
      'title': '합성함수 미분의 적용 조건',
      'importance': '중요도 높음',
      'position': 2,
      'student_formula': r"f'(x)=4(3x^2+1)^3",
      'description': '합성함수를 미분할 때 필요한 조건과 인수가 모두 반영되었는지 확인해 보세요.',
      'direction': '내부 함수와 외부 함수를 구분해 보세요.',
    },
    {
      'id': 'boundary',
      'title': '경계 조건과 해의 범위',
      'importance': '중요도 보통',
      'position': 4,
      'student_formula': r"f'(x)=0",
      'description': '계산한 해가 원래 정의역과 조건을 만족하는지 대조해 보세요.',
      'direction': '구한 값을 원래 조건에 대입해 확인하세요.',
    },
    {
      'id': 'conclusion',
      'title': '결론으로 이어지는 논리 연결',
      'importance': '중요도 보통',
      'position': 5,
      'student_formula': r'x=0',
      'description': '계산한 결과와 문제에서 요구한 결론을 연결하는 설명을 점검해 보세요.',
      'direction': '어떤 조건에서 결론이 성립하는지 설명하세요.',
    },
  ],
  'concepts': [
    {
      'id': 'chain',
      'name': '합성함수의 미분법',
      'formula': r'\frac{d}{dx}f(g(x))=f\prime(g(x))g\prime(x)',
      'description': '두 함수를 합성한 함수의 도함수를 구하는 법칙입니다.',
      'condition': '내부 함수와 외부 함수가 해당 점에서 미분 가능해야 합니다.',
      'caution': '내부 함수의 도함수를 빠뜨리지 않도록 확인합니다.',
      'relation': '합성함수의 미분 과정에서 필요한 인수를 확인합니다.',
    },
    {
      'id': 'zero',
      'name': '도함수의 영점과 극값',
      'formula': r'f\prime(c)=0',
      'description': '극값의 후보를 찾는 조건입니다.',
      'condition': '미분 가능한 구간의 내부 점을 확인합니다.',
      'caution': '도함수가 영이라는 사실만으로 극값이 확정되지는 않습니다.',
      'relation': '후보와 최종 결론을 구분합니다.',
    },
  ],
  'rewrite_policy': {
    'eligible': true,
    'included_count': 1,
    'paid_available': false,
  },
};

class MathMobilePreview extends StatefulWidget {
  const MathMobilePreview({super.key});
  @override
  State<MathMobilePreview> createState() => _MathMobilePreviewState();
}

class _MathMobilePreviewState extends State<MathMobilePreview> {
  final data = mathMobilePreviewSnapshot();
  Future<Map<String, dynamic>> request(
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (action == 'history') {
      return {
        'attempts': [
          {
            'resolve_kind': 'INITIAL',
            'completed_at': '화면 검수용 예시',
            'evaluation_state': 'COMPLETED',
            'exposed_hint_levels': [1],
            'solution_revealed': data['disclosed'],
            'credit_label': '검수 예제 · 실제 차감 없음',
          },
        ],
      };
    }
    if (action == 'hint') {
      return {
        'body': payload['level'] == 1
            ? r'합성함수 \(f(g(x))\)에서 내부·외부 함수를 구분해 보세요.'
            : r'일반 공식 \(\frac{d}{dx}f(g(x))=f\prime(g(x))g\prime(x)\)의 각 인수를 원래 풀이와 비교해 보세요.',
      };
    }
    if (action == 'reveal') {
      data['disclosed'] = true;
      data['full_solution'] = {
        'references': [
          {
            'origin': 'VERIFIED_INTERNAL',
            'body': r'화면 검수용 수식 예제입니다. 공식 대학 예시답안이 아닙니다. \[f\prime(x)=4(3x^2+1)^3\cdot6x=24x(3x^2+1)^3\]',
          },
        ],
        'steps': <dynamic>[],
        'paths': <dynamic>[],
      };
    }
    return data;
  }

  @override
  Widget build(BuildContext context) => MathMobileTheme(
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'TASK16-F · 오프라인 화면 검수',
          style: TextStyle(fontSize: 14),
        ),
      ),
      body: MathCoachingScreen(
        snapshot: CoachingSnapshot(data),
        request: request,
        onRewrite: (_) async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => MathMobileTheme(
                child: Scaffold(
                  appBar: AppBar(title: const Text('답안 인식 확인')),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      MathRecognitionPanel(
                        regions: [
                          {
                            'id': 'preview',
                            'reading_order': 1,
                            'raw_text': r"f'(x)=4(3x^2+1)^3",
                            'normalized_math': r"f'(x)=4(3x^2+1)^3",
                            'uncertain': true,
                          },
                        ],
                        onConfirm: (_) async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('검수용 확인 완료 · 서버 저장·실제 평가 없음'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
