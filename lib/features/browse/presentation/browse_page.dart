import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/placeholder_page.dart';
import '../../content/content_providers.dart';
import '../../content/presentation/content_results.dart';

class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});
  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage> {
  final controller = TextEditingController();
  String query = '';
  void search() => setState(() => query = controller.text.trim());
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: '나에게 필요한 학습 자료',
    description: '제목과 요약에서 자료를 검색해 보세요.',
    icon: Icons.search,
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 16),
        if (query.isEmpty)
          const Text('검색어를 입력해 주세요.')
        else
          ContentResults(
            state: ref.watch(contentSearchProvider(query)),
            emptyMessage: '검색 결과가 없어요.',
            onRetry: () => ref.invalidate(contentSearchProvider(query)),
          ),
      ],
    ),
  );
}
