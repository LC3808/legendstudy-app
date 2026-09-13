import 'day_target.dart';

abstract interface class DayTargetRepository {
  Future<DayTarget?> fetchCurrentTarget();
  Future<DayTarget> saveCurrentTarget(DateTime date, String label);
  Future<void> clearCurrentTarget();
}
