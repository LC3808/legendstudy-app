import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application_editor.dart';
import 'application_repository.dart';

/// Inline composition; never pushes the MY route or creates another repository.
class OnboardingApplications extends ConsumerStatefulWidget {
  const OnboardingApplications({super.key});
  @override
  ConsumerState<OnboardingApplications> createState() =>
      OnboardingApplicationsState();
}

class OnboardingApplicationsState
    extends ConsumerState<OnboardingApplications> {
  GlobalKey<ApplicationEditorState> editor = GlobalKey();
  String? owner;
  ApplicationRecord? editing;
  bool open = false, deleting = false;
  String? notice, error;

  Future<bool> confirmLeave() async {
    if (deleting) return false;
    return await editor.currentState?.confirmLeave() ?? true;
  }

  Future<void> remove(ApplicationRecord row) async {
    final repo = ref.read(applicationRepositoryProvider);
    if (repo == null || deleting) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('지원 내역을 삭제할까요?'),
        content: const Text('이 지원 내역과 기록한 이력이 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes != true ||
        !mounted ||
        ref.read(applicationRepositoryProvider)?.owner != repo.owner) {
      return;
    }
    setState(() {
      deleting = true;
      error = null;
    });
    try {
      await repo.delete(row.id);
      if (!mounted ||
          ref.read(applicationRepositoryProvider)?.owner != repo.owner) {
        return;
      }
      ref.invalidate(applicationsProvider);
      setState(() => notice = '지원 내역을 삭제했어요.');
    } catch (e) {
      if (mounted && owner == repo.owner) {
        setState(() => error = applicationError(e));
      }
    } finally {
      if (mounted && owner == repo.owner) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(applicationRepositoryProvider);
    if (owner != repo?.owner) {
      owner = repo?.owner;
      editor = GlobalKey();
      editing = null;
      open = deleting = false;
      notice = error = null;
    }
    final rows = ref.watch(applicationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              notice!,
              style: const TextStyle(
                color: Color(0xFF1C2B4B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (open) ...[
          ApplicationEditor(
            key: editor,
            embedded: true,
            record: editing,
            onSaved: () {
              setState(() {
                open = false;
                editing = null;
                notice = '지원 내역을 저장했어요.';
              });
            },
          ),
          TextButton(
            onPressed: () async {
              if (await confirmLeave() && mounted) {
                setState(() {
                  open = false;
                  editing = null;
                });
              }
            },
            child: const Text('입력 닫기'),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: repo == null || deleting
                ? null
                : () => setState(() {
                    open = true;
                    editing = null;
                    notice = null;
                  }),
            icon: const Icon(Icons.add),
            label: const Text('지원 대학 추가하기'),
          ),
          const SizedBox(height: 14),
          rows.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(applicationsProvider),
              child: const Text('지원 내역을 불러오지 못했어요. 다시 시도'),
            ),
            data: (items) => Column(
              children: [
                for (final row in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ApplicationSection(
                      title: row.university,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${row.year}학년도 · ${row.type}'),
                          const SizedBox(height: 6),
                          Text('${row.division} · ${row.track}'),
                          const SizedBox(height: 12),
                          Text(
                            row.status,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: deleting
                                    ? null
                                    : () => setState(() {
                                        editing = row;
                                        open = true;
                                        notice = null;
                                      }),
                                child: const Text('수정'),
                              ),
                              TextButton(
                                onPressed: deleting ? null : () => remove(row),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
