import 'package:go_router/go_router.dart';

import 'grade_page.dart';
import '../../personal/personal_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../school/domain/school.dart';
import '../../school/school_providers.dart';
import '../../school/presentation/school_search_picker.dart';
import 'academic_status_field.dart';

class SchoolPage extends ConsumerStatefulWidget {
  const SchoolPage({super.key});
  @override
  ConsumerState<SchoolPage> createState() => _SchoolPageState();
}

class _SchoolPageState extends ConsumerState<SchoolPage> {
  bool _saving = false;
  bool _statusEdited = false;
  String? _statusDraft;
  School? _draft;
  bool _edited = false, _completed = false;
  String? _owner;

  void _choose(School? school) {
    setState(() {
      _draft = school;
      _edited = true;
    });
  }

  Future<bool> _saveSchool() async {
    if (!_edited || _draft == null) return true;
    final applied = await ref
        .read(schoolSelectionProvider.notifier)
        .select(_draft);
    if (!mounted || !applied) return false;
    _edited = false;
    return true;
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    if (ModalRoute.of(context)?.isCurrent == true) {
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveGuest() async {
    if (_saving || _completed) return;
    setState(() => _saving = true);
    try {
      if (await _saveSchool()) _finish();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학교 설정을 변경하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final selection = ref.watch(schoolSelectionProvider);
    if (_owner != auth.value?.userId) {
      _owner = auth.value?.userId;
      _saving = false;
      _edited = false;
      _draft = null;
      _completed = false;
      _statusEdited = false;
      _statusDraft = null;
    }
    return ShellPage(
      children: [
        SchoolSearchPicker(
          key: ValueKey('my-school:$_owner'),
          enabled: !_saving,
          onChanged: _choose,
        ),
        const SizedBox(height: 16),
        if (auth.value?.isAuthenticated != true)
          const Text('비회원 선택은 이번 앱 실행 동안만 유지돼요.')
        else
          const Text('학교·학년을 확인한 뒤 저장해 주세요.'),
        if (selection.isLoading || _saving)
          const Center(child: CircularProgressIndicator()),
        if (selection.hasError)
          ErrorState(
            message: '저장한 학교를 불러오지 못했어요.',
            onRetry: () => ref.invalidate(schoolSelectionProvider),
          ),
        if (auth.value?.isAuthenticated == true) ...[
          AcademicStatusField(
            key: ValueKey('academic-status:${auth.value?.userId}'),
            enabled: !_saving && !_completed,
            draftStatus: _statusEdited
                ? _statusDraft
                : _draft != null
                ? 'student'
                : ref.watch(currentProfileProvider).value?.academicStatus,
            onChanged: (value) => setState(() {
              _statusEdited = true;
              _statusDraft = value;
            }),
          ),
          GradePage(
            key: ValueKey(auth.value?.userId),
            enabled:
                !selection.isLoading &&
                !selection.hasError &&
                !_completed &&
                !ref.watch(currentProfileProvider).isLoading &&
                !ref.watch(currentProfileProvider).hasError,
            statusDraft: () => _statusEdited
                ? _statusDraft
                : _draft != null
                ? 'student'
                : ref.read(currentProfileProvider).value?.academicStatus,
            saveLabel: _draft != null ? '이 학교로 설정하기' : '저장',
            beforeSave: _saveSchool,
            onSavingChanged: (value) => setState(() => _saving = value),
            onSaved: _finish,
          ),
        ],
        if (auth.value?.isAuthenticated != true)
          FilledButton(
            onPressed: _saving || selection.isLoading || selection.hasError
                ? null
                : _saveGuest,
            child: Text(_draft != null ? '이 학교로 설정하기' : '저장'),
          ),
      ],
    );
  }
}
