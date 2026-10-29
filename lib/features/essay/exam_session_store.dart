import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'exam_session_status.dart';

/// Owner-scoped, read-only observations shared by progress and History.
/// A failed refresh keeps the last observation; it never invents a new state.
class ExamSessionStore {
  ExamSessionStore(this.read);
  final Future<ExamSessionStatus> Function(String) read;
  final _values = <String, ExamSessionStatus>{};
  final _pending = <String, Future<ExamSessionStatus>>{};
  final _changes = StreamController<String>.broadcast();
  bool _closed = false;
  Stream<ExamSessionStatus> watch(String run) async* {
    if (_values[run] case final value?) yield value;
    yield* _changes.stream.where((id) => id == run).map((_) => _values[run]!);
  }

  Future<ExamSessionStatus> refresh(String run) =>
      _pending[run] ??= _refresh(run).whenComplete(() {
        _pending.remove(run);
      });

  /// A retry acknowledgement must not reuse a read started before that retry.
  Future<ExamSessionStatus> refreshAfterRetry(String run) async {
    final earlier = _pending[run];
    if (earlier != null) {
      try {
        await earlier;
      } catch (_) {
        /* The new read remains authoritative. */
      }
    }
    return refresh(run);
  }

  Future<ExamSessionStatus> _refresh(String run) async {
    final value = await read(run);
    if (_closed) throw StateError('ACCOUNT_CHANGED');
    final previous = _values[run];
    if (previous != null &&
        previous.questions.entries.any(
          (q) =>
              q.value == 'completed' && value.questions[q.key] != 'completed',
        )) {
      // Surface inconsistent reads rather than replacing a reviewed success.
      throw const FormatException('COMPLETED_QUESTION_REGRESSION');
    }
    _values[run] = value;
    _changes.add(run);
    return value;
  }

  void dispose() {
    _closed = true;
    unawaited(_changes.close());
  }
}

final examSessionStoreProvider = Provider.family<ExamSessionStore, String>((
  ref,
  owner,
) {
  ref.listen(authStateProvider, (previous, next) {
    if (previous?.value?.userId == owner &&
        next.hasValue &&
        next.value?.userId != owner) {
      ref.invalidateSelf();
    }
  });
  final client = ref.watch(supabaseClientProvider);
  final store = ExamSessionStore((run) {
    if (client == null) throw StateError('LOGIN_REQUIRED');
    return readExamSessionStatus(client, owner, run);
  });
  ref.onDispose(store.dispose);
  return store;
});
final examSessionObservationProvider = StreamProvider.autoDispose
    .family<ExamSessionStatus, ({String owner, String run})>((ref, scope) {
      return ref.watch(examSessionStoreProvider(scope.owner)).watch(scope.run);
    });
