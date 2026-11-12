import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'learning_repository.dart';

class StudyPercentile {
  const StudyPercentile(this.status, this.asOf, this.topPercent);
  final String status, asOf;
  final int? topPercent;

  factory StudyPercentile.parse(Object? raw) {
    final r = object(raw);
    final status = string(r['status']);
    final asOf = string(r['as_of']);
    if (r['version'] != 'study-percentile-v1' ||
        r['source'] != 'completed_synced_sessions' ||
        r['method'] != 'ceil_tie_upper_bound' ||
        !{'ready', 'no_records', 'insufficient_sample'}.contains(status) ||
        DateTime.tryParse(asOf) == null ||
        integer(r['minimum_sample']) < 2) {
      throw const LearningFailure();
    }
    final percent = nullableInteger(r['top_percent']);
    if (status == 'ready') {
      final population = integer(r['population']);
      final rank = integer(r['rank']);
      final ties = integer(r['tie_count']);
      if (population < integer(r['minimum_sample']) ||
          rank < 1 ||
          ties < 1 ||
          rank + ties - 1 > population ||
          percent == null ||
          percent < 1 ||
          percent > 100) {
        throw const LearningFailure();
      }
    } else if (percent != null ||
        r['population'] != null ||
        r['rank'] != null ||
        r['tie_count'] != null) {
      throw const LearningFailure();
    }
    return StudyPercentile(status, asOf, percent);
  }
}

final studyPercentileProvider = FutureProvider.autoDispose<StudyPercentile>(
  (ref) async => StudyPercentile.parse(
    await ref.watch(learningRpcProvider)('my_study_percentile', {}),
  ),
  retry: (_, _) => null,
);

class StudyPercentilePrompt extends StatelessWidget {
  const StudyPercentilePrompt({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('나의 공부시간은 상위 몇 %일까?', style: TextStyle(fontWeight: FontWeight.w700)),
      SizedBox(height: 6),
      Text('공부를 시작하고 나의 학습 순위를 확인해 보세요.'),
    ],
  );
}

/// Only a server-confirmed lifetime total can opt into the percentile request.
/// No local timer, unsynced record, or client-side rank calculation is used.
class StudyPercentileCard extends ConsumerWidget {
  const StudyPercentileCard({required this.allTime, super.key});
  final int? allTime;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (allTime == null) return const SizedBox.shrink();
    if (allTime == 0) return const StudyPercentilePrompt();
    return ref
        .watch(studyPercentileProvider)
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const Text('나의 공부시간 순위를 계산하고 있어요.'),
          error: (error, _) {
            // The additive RPC needs separate operational approval. Keep the
            // existing study experience intact until it is actually deployed.
            if (error is PostgrestException && error.code == 'PGRST202') {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('나의 공부시간 순위를 불러오지 못했어요.'),
                TextButton(
                  onPressed: () => ref.invalidate(studyPercentileProvider),
                  child: const Text('순위 다시 확인'),
                ),
              ],
            );
          },
          data: (p) => switch (p.status) {
            'no_records' => const StudyPercentilePrompt(),
            'insufficient_sample' => const Text(
              '공부 기록이 더 모이면 나의 학습 순위를 알려드릴게요.',
            ),
            _ => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 나의 공부시간은 상위 ${p.topPercent}%',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '유효한 누적 공부시간 기준 · 같은 시간은 같은 순위',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          },
        );
  }
}
