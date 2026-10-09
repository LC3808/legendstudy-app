import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';

void main() {
  test(
    'Math and Essay history preserves lineage, invalidation and source dates',
    () {
      final rows = parseSharedHistory(
        {
          'attempts': [
            {
              'attempt_id': 'math',
              'created_at': '2026-10-09T01:00:00Z',
              'predecessor_id': 'first',
              'evaluations': [
                {'evaluation_id': 'me', 'state': 'COMPLETED'},
              ],
            },
          ],
        },
        [
          {
            'id': 'essay',
            'submitted_at': '2026-10-08T01:00:00Z',
            'attempt_no': 1,
            'essay_evaluations': [
              {
                'id': 'old',
                'status': 'completed',
                'invalidated_at': '2026-10-09',
              },
              {'id': 'valid', 'status': 'completed', 'invalidated_at': null},
            ],
          },
        ],
      );
      expect(rows.map((r) => r.id), ['math', 'essay']);
      expect(rows.first.math, true);
      expect(rows.first.rewrite, true);
      expect(rows.last.evaluations.single['id'], 'valid');
      expect(rows.last.evaluations.single['state'], 'COMPLETED');
    },
  );
  test('empty is distinct from broken Math response', () {
    expect(parseSharedHistory({'attempts': <dynamic>[]}, <dynamic>[]), isEmpty);
    expect(() => parseSharedHistory({}, <dynamic>[]), throwsFormatException);
  });
}
