import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../customization/home_configuration.dart';
import '../customization/home_registry.dart';
import '../customization/home_editor.dart';
import 'home_components.dart';
export 'home_components.dart' show HomeGreeting, HomeRecentUpdates;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configurationState = ref.watch(homeConfigurationProvider);
    final loading =
        configurationState.isLoading || ref.watch(authStateProvider).isLoading;
    final state = configurationState.asData?.value;
    final config = state?.configuration ?? HomeConfiguration.defaults();
    final visible = config.cards
        .where((c) => c.visible && homeCards.any((d) => d.id == c.id))
        .toList();
    return ShellPage(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        HomeGreeting(
          editEntry: IconButton(
            key: const ValueKey('home-edit-action'),
            tooltip: '홈 편집',
            onPressed: () => openHomeEditor(context),
            icon: const Icon(Icons.tune),
          ),
        ),
        if (loading)
          Semantics(liveRegion: true, child: const Text('홈 설정을 확인하고 있어요.')),
        if (!loading && visible.isEmpty) ...[
          const Text('홈에 표시할 카드를 선택해 주세요.'),
          TextButton(
            onPressed: () => openHomeEditor(context),
            child: const Text('홈 화면 편집'),
          ),
        ],
        if (!loading)
          for (final (index, card) in visible.indexed) ...[
            if (index > 0) const SizedBox(height: AppTokens.space16),
            KeyedSubtree(
              key: ValueKey(card.id),
              child: homeCards
                  .firstWhere((d) => d.id == card.id)
                  .component(context),
            ),
          ],
      ],
    );
  }
}
