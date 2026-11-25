import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'domain/day_event.dart';
import 'domain/day_event_repository.dart';
import 'domain/admission_day_event.dart';
import 'data/supabase_day_event_repository.dart';

final dayEventRepositoryProvider = Provider<DayEventRepository>(
  (ref) => SupabaseDayEventRepository(ref.watch(supabaseClientProvider)),
);

final dayEventsProvider =
    AsyncNotifierProvider<DayEventsController, List<DayEvent>>(
      DayEventsController.new,
    );

/// Owns the D-Day collection state. Authenticated users persist through the
/// repository (confirmed writes, then refetch). Guests keep a session-only list
/// that is never sent to the backend and never merged into an account.
class DayEventsController extends AsyncNotifier<List<DayEvent>> {
  int _generation = 0;
  bool _saving = false;
  int _localSeq = 0;
  List<DayEvent> _guest = const [];
  List<AdmissionDayEvent> _admissions = const [];
  bool _admissionSyncUnavailable = false;

  List<AdmissionDayEvent> get admissionEvents => _admissions;
  bool get admissionSyncUnavailable => _admissionSyncUnavailable;

  @override
  Future<List<DayEvent>> build() async {
    _generation++;
    _saving = false;
    _admissions = const [];
    _admissionSyncUnavailable = false;
    final identity = ref.watch(
      authStateProvider.select(
        (auth) => (auth.isLoading, auth.hasError, auth.value?.userId),
      ),
    );
    if (identity.$1) return const [];
    if (identity.$2) {
      throw const BackendUnavailable('Authentication unavailable');
    }
    if (identity.$3 == null) {
      return [..._guest]..sort(compareEvents);
    }
    // A new authenticated session must not inherit guest session events.
    _guest = const [];
    return _fetchRepository(
      ref.watch(dayEventRepositoryProvider),
      identity.$3!,
      _generation,
    );
  }

  bool _current(String? owner, int generation) =>
      ref.mounted &&
      generation == _generation &&
      ref.read(authStateProvider).value?.userId == owner;

  Future<List<DayEvent>> _fetchRepository(
    DayEventRepository repository,
    String owner,
    int generation,
  ) async {
    if (repository is AdmissionDayEventRepository) {
      final snapshot = await (repository as AdmissionDayEventRepository)
          .fetchAdmissionSnapshot();
      if (_current(owner, generation)) {
        _admissions = snapshot.admissions;
        _admissionSyncUnavailable = !snapshot.syncAvailable;
      }
      return snapshot.events;
    }
    return repository.fetchEvents();
  }

  bool get _busy =>
      _saving ||
      state.isLoading ||
      state.hasError ||
      ref.read(authStateProvider).isLoading ||
      ref.read(authStateProvider).hasError;

  Future<bool> _run(Future<void> Function(String? owner) apply) async {
    if (_busy) throw const BackendUnavailable('D-Day not ready');
    final owner = ref.read(authStateProvider).value?.userId;
    final generation = _generation;
    _saving = true;
    try {
      await apply(owner);
      if (!_current(owner, generation)) return false;
      if (owner != null) {
        final events = await _fetchRepository(
          ref.read(dayEventRepositoryProvider),
          owner,
          generation,
        );
        // Auth can change while the post-write refetch is in flight too.
        if (!_current(owner, generation)) return false;
        state = AsyncData(events);
      } else {
        state = AsyncData([..._guest]..sort(compareEvents));
      }
      return true;
    } finally {
      if (ref.mounted && generation == _generation) _saving = false;
    }
  }

  Future<bool> refresh() => _run((_) async {});

  Future<bool> restoreAdmissionEvent(AdmissionDayEvent event) =>
      _run((owner) async {
        final repository = ref.read(dayEventRepositoryProvider);
        if (owner == null ||
            !event.canRestore ||
            repository is! AdmissionDayEventRepository) {
          throw const BackendUnavailable('Admission event cannot be restored');
        }
        await (repository as AdmissionDayEventRepository)
            .changeAdmissionVisibility(event, restore: true);
      });

  Future<bool> addEvent(DateTime date, String label, {bool primary = false}) =>
      _run((owner) async {
        if (owner != null) {
          await ref
              .read(dayEventRepositoryProvider)
              .addEvent(date, label, primary: primary);
          return;
        }
        // Guest, session-only. A new primary clears any previous guest primary.
        final existing = primary
            ? [for (final e in _guest) e.copyWith(isPrimary: false)]
            : [..._guest];
        _guest = [
          ...existing,
          DayEvent(
            id: 'local-${_localSeq++}',
            date: date,
            label: label,
            isPrimary: primary,
          ),
        ];
      });

  Future<bool> editEvent(String id, DateTime date, String label) => _run((
    owner,
  ) async {
    if ((state.value ?? const <DayEvent>[]).any(
      (e) => e.id == id && e.admission != null,
    )) {
      throw const BackendUnavailable('Official event cannot be edited');
    }
    if (owner != null) {
      await ref.read(dayEventRepositoryProvider).updateEvent(id, date, label);
      return;
    }
    _guest = [
      for (final e in _guest)
        if (e.id == id) e.copyWith(date: date, label: label) else e,
    ];
  });

  Future<bool> deleteEvent(String id) => _run((owner) async {
    if (owner != null) {
      await ref.read(dayEventRepositoryProvider).deleteEvent(id);
      return;
    }
    _guest = [
      for (final e in _guest)
        if (e.id != id) e,
    ];
  });

  Future<bool> setPrimary(String id) => _run((owner) async {
    if (owner != null) {
      await ref.read(dayEventRepositoryProvider).setPrimary(id);
      return;
    }
    _guest = [for (final e in _guest) e.copyWith(isPrimary: e.id == id)];
  });
}
