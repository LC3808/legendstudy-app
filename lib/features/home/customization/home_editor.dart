import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_configuration.dart';
import 'home_registry.dart';

Future<void> openHomeEditor(BuildContext context) =>
    Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const HomeEditor()));

/// The onboarding selector shares the registry, without exposing reorder.
class HomeCardSelector extends StatelessWidget {
  const HomeCardSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final HomeConfiguration value;
  final ValueChanged<HomeConfiguration>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final card in homeCards)
        CheckboxListTile(
          secondary: Icon(card.icon),
          title: Text(card.title),
          subtitle: Text(card.description),
          value: value.cards.any((c) => c.id == card.id && c.visible),
          onChanged: onChanged == null
              ? null
              : (v) => onChanged!(value.toggle(card.id, v!)),
        ),
    ],
  );
}

class HomeEditor extends ConsumerStatefulWidget {
  const HomeEditor({super.key});
  @override
  ConsumerState<HomeEditor> createState() => _HomeEditorState();
}

class _HomeEditorState extends ConsumerState<HomeEditor> {
  HomeConfiguration? draft;
  HomeConfigurationRepository? repository;
  int revision = 0;
  bool busy = false;
  String? error;
  Future<void> save() async {
    if (busy || draft == null || repository == null) return;
    final repo = repository!;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await repo.save(draft!, revision);
      if (!mounted || repository != repo) return;
      ref.invalidate(homeConfigurationProvider);
      Navigator.pop(context);
    } catch (_) {
      if (mounted && repository == repo) {
        setState(
          () => error = '저장하지 못했어요. 입력값은 유지됩니다. 다시 저장하거나 최신 설정을 불러와 주세요.',
        );
      }
    } finally {
      if (mounted && repository == repo) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(homeConfigurationRepositoryProvider);
    final state = ref.watch(homeConfigurationProvider);
    if (repository?.owner != repo?.owner ||
        (repo == null && repository != null)) {
      draft = null;
      revision = 0;
      error = null;
      busy = false;
    }
    repository = repo;
    final loaded = state.asData?.value;
    if (draft == null && loaded?.confirmed == true) {
      draft = loaded!.configuration;
      revision = loaded.revision;
    }
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('홈 화면 설정')),
        body: draft == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loaded?.failed == true || state.hasError
                          ? '설정을 불러오지 못했어요. 기본 홈을 사용 중이에요.'
                          : '설정을 불러오는 중이에요.',
                    ),
                    if (loaded?.failed == true || state.hasError)
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(homeConfigurationProvider),
                        child: const Text('다시 불러오기'),
                      ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      repo?.owner == null
                          ? '이 기기에 저장합니다. 로그인 계정의 설정과는 별개예요.'
                          : '저장하면 이 계정의 다른 기기에서도 같은 홈을 사용해요.',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(error!, semanticsLabel: error),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                // Unknown future IDs survive reset; only known choices are reset.
                                draft = HomeConfiguration([
                                  ...HomeConfiguration.defaults().cards,
                                  ...draft!.cards.where(
                                    (c) => !defaultHomeVisibility.containsKey(
                                      c.id,
                                    ),
                                  ),
                                ]);
                              }),
                        child: const Text('기본 구성으로 초기화'),
                      ),
                      if (error != null)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () {
                                  setState(() {
                                    draft = null;
                                    error = null;
                                  });
                                  ref.invalidate(homeConfigurationProvider);
                                },
                          child: const Text('최신 설정 다시 불러오기'),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: draft!.cards.length,
                      onReorderItem: busy
                          ? (_, _) {}
                          : (from, to) => setState(
                              () => draft = draft!.reorder(
                                from,
                                to > from ? to + 1 : to,
                              ),
                            ),
                      itemBuilder: (context, index) {
                        final choice = draft!.cards[index];
                        final matching = homeCards.where(
                          (d) => d.id == choice.id,
                        );
                        final card = matching.isEmpty ? null : matching.first;
                        return ListTile(
                          key: ValueKey(choice.id),
                          leading: Checkbox(
                            value: choice.visible,
                            onChanged: busy || card == null
                                ? null
                                : (v) => setState(
                                    () => draft = draft!.toggle(choice.id, v!),
                                  ),
                          ),
                          title: Text(card?.title ?? '다른 버전의 카드'),
                          subtitle: Text(card?.description ?? '저장된 설정을 유지합니다.'),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            enabled: !busy,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.drag_handle,
                                semanticLabel: '길게 눌러 순서 변경',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : save,
                          child: Text(busy ? '저장 중…' : '저장'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
