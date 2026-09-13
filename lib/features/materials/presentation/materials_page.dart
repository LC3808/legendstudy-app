import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/content_providers.dart';
import '../../content/presentation/content_results.dart';

class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({this.initialQuery = '', super.key});
  final String initialQuery;
  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage> {
  final controller = TextEditingController();
  String query = '';
  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    controller.text = query;
  }

  @override
  void didUpdateWidget(covariant MaterialsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      query = widget.initialQuery;
      controller.text = query;
    }
  }

  void search() => setState(() => query = controller.text.trim());
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShellPage(
    children: [
      const AppHeader(title: '자료', subtitle: '나에게 필요한 학습 자료'),
      TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        maxLength: 200,
        onSubmitted: (_) => search(),
        onChanged: (value) {
          if (value.trim().isEmpty) setState(() => query = '');
        },
        decoration: const InputDecoration(
          labelText: '검색어',
          hintText: '예: 영어 모의고사',
        ),
      ),
      TextButton(onPressed: search, child: const Text('검색')),
      const SectionHeader('자료 모아보기'),
      Wrap(
        spacing: 8,
        children: [
          for (final label in ['기출문제', '영어', '논술', '학습 자료'])
            QuickFilterChip(
              label,
              onTap: () {
                controller.text = label;
                search();
              },
            ),
        ],
      ),
      const SectionHeader('검색 결과'),
      if (query.isEmpty)
        const Text('검색어를 입력해 주세요.')
      else
        ContentResults(
          state: ref.watch(contentSearchProvider(query)),
          emptyMessage: '검색 결과가 없어요.',
          onRetry: () => ref.invalidate(contentSearchProvider(query)),
        ),
    ],
  );
}
