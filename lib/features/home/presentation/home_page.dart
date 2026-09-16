import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/content_providers.dart';
import 'day_target_card.dart';
import '../../study/study_providers.dart';
import '../../school/presentation/home_meal_card.dart';
import '../../content/domain/content_types.dart';
import '../../content/presentation/content_results.dart';
import '../../personal/personal_list_providers.dart';
import '../../personal/presentation/personal_material_list.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShellPage(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    children: [
      const AppHeader(title: '레전드스터디', branded: true),
      const DayTargetCard(),
      const SizedBox(height: 8),
      const HomeMealCard(),
      const SizedBox(height: 8),
      const _HomeSearch(),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Semantics(
          header: true,
          child: const Text('빠르게 찾기', style: AppTokens.sectionTitle),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final type in [
            'exam',
            'study_material',
            'university_essay',
            'admissions_info',
          ])
            QuickFilterChip(
              contentTypeLabels[type]!,
              onTap: () => context.go(
                Uri(
                  path: '/materials',
                  queryParameters: {'type': type},
                ).toString(),
              ),
            ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Semantics(
          header: true,
          child: const Text('오늘의 공부', style: AppTokens.sectionTitle),
        ),
      ),
      DailyUtilityCard(
        title: '나의 공부 시간',
        body: Text(ref.watch(studyControllerProvider).summary),
        action: TextButton(
          onPressed: () => context.go('/study'),
          child: const Text('학습으로 이동'),
        ),
      ),
      const SectionHeader('최근 업데이트'),
      const HomeRecentUpdates(),
      const SectionHeader('최근 본 자료'),
      const PersonalMaterialList(
        kind: PersonalListKind.recentViews,
        homeMode: true,
      ),
    ],
  );
}

class HomeRecentUpdates extends ConsumerStatefulWidget {
  const HomeRecentUpdates({super.key});

  @override
  ConsumerState<HomeRecentUpdates> createState() => _HomeRecentUpdatesState();
}

class _HomeRecentUpdatesState extends ConsumerState<HomeRecentUpdates> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeRecentContentProvider);
    final visibleState = state.whenData(
      (items) => items.take(expanded ? 6 : 2).toList(),
    );
    final count = state.asData?.value.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentResults(
          state: visibleState,
          onRetry: () => ref.invalidate(homeRecentContentProvider),
        ),
        if (count > 2)
          Semantics(
            button: true,
            label: expanded ? '최근 업데이트 접기' : '최근 업데이트 더보기',
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => expanded = !expanded),
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(expanded ? '접기' : '더보기'),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeSearch extends StatefulWidget {
  const _HomeSearch();
  @override
  State<_HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends State<_HomeSearch> {
  final input = TextEditingController();
  void submit() {
    FocusScope.of(context).unfocus();
    context.go(
      Uri(path: '/materials', queryParameters: {'q': input.text}).toString(),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: input,
    maxLength: 200,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => submit(),
    decoration: InputDecoration(
      hintText: '모의고사, 과목, 연도 검색',
      hintMaxLines: 2,
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: IconButton(
        tooltip: '자료 검색',
        onPressed: submit,
        icon: const Icon(Icons.search),
      ),
    ),
  );
}
