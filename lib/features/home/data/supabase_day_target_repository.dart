import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/day_target.dart';
import '../domain/day_target_repository.dart';

class SupabaseDayTargetRepository implements DayTargetRepository {
  SupabaseDayTargetRepository(this.client);
  final SupabaseClient? client;
  String? get _owner => client?.auth.currentUser?.id;
  String _requireOwner() => _owner ?? (throw const SignedOutException());
  static const _projection = 'id,target_date,target_label';

  DayTarget? _decode(Map<String, dynamic> row, String owner) {
    if (row['id'] != owner) {
      throw const FormatException('Unexpected profile owner');
    }
    final date = row['target_date'], label = row['target_label'];
    if (date == null && label == null) return null;
    if (date is! String ||
        label is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw const FormatException('Invalid target pair');
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) throw const FormatException('Invalid calendar date');
    final result = DayTarget(date: parsed, label: label);
    if (result.formattedDate.replaceAll('.', '-') != date ||
        result.label != label) {
      throw const FormatException('Invalid target pair');
    }
    return result;
  }

  @override
  Future<DayTarget?> fetchCurrentTarget() async {
    final owner = _owner;
    if (owner == null) return null;
    final row = await client!
        .from('profiles')
        .select(_projection)
        .eq('id', owner)
        .maybeSingle();
    return row == null ? null : _decode(row, owner);
  }

  @override
  Future<DayTarget> saveCurrentTarget(DateTime date, String label) async {
    final owner = _requireOwner();
    final target = DayTarget(date: date, label: label);
    if (date.year < 1 || date.year > 9999) {
      throw const FormatException('Unsupported date');
    }
    final row = await client!
        .from('profiles')
        .upsert({
          'id': owner,
          'target_date': target.formattedDate.replaceAll('.', '-'),
          'target_label': target.label,
        }, onConflict: 'id')
        .select(_projection)
        .single();
    final saved = _decode(row, owner);
    if (saved == null ||
        saved.date != target.date ||
        saved.label != target.label) {
      throw const FormatException('Target save not confirmed');
    }
    return saved;
  }

  @override
  Future<void> clearCurrentTarget() async {
    final owner = _requireOwner();
    final rows = await client!
        .from('profiles')
        .update({'target_date': null, 'target_label': null})
        .eq('id', owner)
        .select(_projection);
    if (rows.length > 1 ||
        (rows.isNotEmpty && _decode(rows.single, owner) != null)) {
      throw const FormatException('Target clear not confirmed');
    }
    // Zero rows is an idempotent clear for a user with no profile.
  }
}
