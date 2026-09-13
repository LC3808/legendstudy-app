import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/content_providers.dart';
import '../../content/domain/content_types.dart';
import '../../content/presentation/content_results.dart';

class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({this.initialQuery = '', this.initialType, super.key});
  final String? initialType;
  final String initialQuery;
  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage> {
  final controller = TextEditingController();
  String query = '';
  String? contentType;
  String? validType(String? value) =>
      contentTypeLabels.containsKey(value) ? value : null;
  ContentFilter get filter => (query: query, contentType: contentType);
  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    contentType = validType(widget.initialType);
    controller.text = query;
  }

  @override
  void didUpdateWidget(covariant MaterialsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery ||
        widget.initialType != oldWidget.initialType) {
      query = widget.initialQuery;
      contentType = validType(widget.initialType);
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
        inputFormatters: [
          LengthLimitingTextInputFormatter(
            200,
            maxLengthEnforcement:
                MaxLengthEnforcement.truncateAfterCompositionEnds,
          ),
        ],
        onSubmitted: (_) => search(),
        onChanged: (value) {
          setState(() {
            if (value.trim().isEmpty) query = '';
          });
        },
        decoration: InputDecoration(
          hintText: '모의고사, 논술, 학습자료 검색',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTokens.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTokens.cardBorder, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '검색어 지우기',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    controller.clear();
                    query = '';
                  }),
                ),
        ),
      ),
      const SectionHeader('자료 모아보기'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in <String?, String>{
              null: '전체',
              ...contentTypeLabels,
            }.entries)
              if (entry.key != 'other')
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: contentType == entry.key,
                    onSelected: (selected) => setState(
                      () => contentType = selected ? entry.key : null,
                    ),
                  ),
                ),
          ],
        ),
      ),
      const SectionHeader('검색 결과'),
      if (query.isEmpty && contentType == null)
        const Text('검색어를 입력해 주세요.')
      else
        ContentResults(
          state: ref.watch(filteredContentProvider(filter)),
          emptyMessage: '검색 결과가 없어요.',
          onRetry: () => ref.invalidate(filteredContentProvider(filter)),
        ),
    ],
  );
}
