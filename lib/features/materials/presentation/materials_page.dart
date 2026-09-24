import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/domain/content_types.dart';
import '../../exams/presentation/exam_labels.dart';
import '../../resources/domain/content_resource.dart';
import '../application/search_controller.dart';
import '../domain/search_models.dart';
import '../../personal/presentation/inline_bookmark_button.dart';

class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({this.initialQuery = '', this.initialType, super.key});
  final String initialQuery;
  final String? initialType;
  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage> {
  final input = TextEditingController();
  Timer? debounce;
  SearchFilters filters = const SearchFilters();
  SearchFacets facets = const SearchFacets();
  bool facetsLoading = true, facetsFailed = false;
  String? validation;
  @override
  void initState() {
    super.initState();
    input.text = widget.initialQuery;
    filters = SearchFilters(
      contentType: contentTypeLabels.containsKey(widget.initialType)
          ? widget.initialType
          : null,
    );
    Future.microtask(() {
      if (mounted) {
        search();
        loadFacets();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MaterialsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialType != widget.initialType) {
      input.text = widget.initialQuery;
      filters = SearchFilters(
        contentType: contentTypeLabels.containsKey(widget.initialType)
            ? widget.initialType
            : null,
      );
      Future.microtask(() {
        if (mounted) search();
      });
    }
  }

  void search() {
    debounce?.cancel();
    try {
      final query = SearchQuery(input.text, filters: filters);
      setState(() => validation = null);
      ref.read(searchControllerProvider.notifier).search(query);
    } on FormatException catch (e) {
      setState(() => validation = e.message);
    }
  }

  Future<void> loadFacets({bool more = false}) async {
    setState(() {
      facetsLoading = true;
      facetsFailed = false;
    });
    try {
      final result = await ref
          .read(searchRepositoryProvider)
          .facets(offset: more ? facets.nextOffset ?? 0 : 0);
      if (mounted) {
        setState(() => facets = more ? facets.merge(result) : result);
      }
    } catch (_) {
      if (mounted) setState(() => facetsFailed = true);
    }
    if (mounted) setState(() => facetsLoading = false);
  }

  void change(String field, Object? value) {
    setState(
      () => filters = SearchFilters(
        grade: field == 'grade' ? value as int? : filters.grade,
        year: field == 'year' ? value as int? : filters.year,
        month: field == 'month' ? value as int? : filters.month,
        examType: field == 'type'
            ? (value == 'csat' ? 'csat' : null)
            : field == 'examType'
            ? value as String?
            : filters.examType,
        subjectId: field == 'subject' ? value as String? : filters.subjectId,
        contentType: field == 'type'
            ? (value == 'csat' ? 'exam' : value as String?)
            : filters.contentType,
      ),
    );
    search();
  }

  Future<void> choose(
    String title,
    Map<Object, String> options,
    Object? selected,
    void Function(Object?) onSelected,
  ) async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<({Object? value})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in <Object?, String>{
                    null: '전체',
                    ...options,
                  }.entries)
                    ListTile(
                      title: Text(entry.value),
                      minVerticalPadding: 12,
                      trailing: selected == entry.key
                          ? const Icon(Icons.check)
                          : null,
                      selected: selected == entry.key,
                      onTap: () => Navigator.pop(context, (value: entry.key)),
                    ),
                  if (options.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('등록된 필터 항목이 없어요.'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) onSelected(result.value);
  }

  Widget filterChip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 4, bottom: 4),
    child: ActionChip(
      label: Text(label),
      avatar: Icon(
        selected ? Icons.check : Icons.expand_more,
        size: 18,
        color: AppTokens.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      backgroundColor: selected ? AppTokens.primarySoft : AppTokens.surface,
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
  );
  @override
  void dispose() {
    debounce?.cancel();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final selectedSubject = facets.subjects
        .where((s) => s.id == filters.subjectId)
        .firstOrNull;
    return ShellPage(
      children: [
        const AppHeader(title: '자료 찾기'),
        LsCard(
          key: const Key('materials-search-surface'),
          padding: const EdgeInsets.all(AppTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: input,
                textInputAction: TextInputAction.search,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    200,
                    maxLengthEnforcement:
                        MaxLengthEnforcement.truncateAfterCompositionEnds,
                  ),
                ],
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                  search();
                },
                onChanged: (_) {
                  setState(() {});
                  debounce?.cancel();
                  if (!input.value.composing.isValid ||
                      input.value.composing.isCollapsed) {
                    debounce = Timer(const Duration(milliseconds: 350), search);
                  }
                },
                decoration: InputDecoration(
                  hintText: '모의고사, 과목, 연도 검색',
                  hintMaxLines: 2,
                  errorText: validation,
                  errorMaxLines: 4,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: input.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '검색어 지우기',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            input.clear();
                            search();
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                children: [
                  filterChip(
                    filters.grade == null ? '학년' : '고${filters.grade}',
                    filters.grade != null,
                    () => choose(
                      '학년',
                      {1: '고1', 2: '고2', 3: '고3'},
                      filters.grade,
                      (v) => change('grade', v),
                    ),
                  ),
                  filterChip(
                    filters.year == null ? '연도' : '${filters.year}년',
                    filters.year != null,
                    () => choose(
                      '연도 · 시행 연도',
                      {for (final y in facets.years) y: '$y년'},
                      filters.year,
                      (v) => change('year', v),
                    ),
                  ),
                  filterChip(
                    filters.month == null ? '시행 월' : '${filters.month}월',
                    filters.month != null,
                    () => choose(
                      '시행 월',
                      {for (final m in facets.months) m: '$m월'},
                      filters.month,
                      (v) => change('month', v),
                    ),
                  ),
                  filterChip(
                    selectedSubject?.name ?? '과목',
                    filters.subjectId != null,
                    () => choose(
                      '과목',
                      {for (final s in facets.subjects) s.id: s.name},
                      filters.subjectId,
                      (v) => change('subject', v),
                    ),
                  ),
                ],
              ),
              if (facetsLoading)
                const Text(
                  '필터를 불러오는 중…',
                  style: TextStyle(color: AppTokens.textSecondary),
                ),
              if (facetsFailed)
                TextButton(
                  onPressed: () => loadFacets(more: facets.nextOffset != null),
                  child: const Text('필터 다시 불러오기'),
                ),
              if (facets.nextOffset != null && !facetsLoading)
                TextButton(
                  onPressed: () => loadFacets(more: true),
                  child: const Text('필터 목록 더 보기'),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in <String?, String>{
                      null: '전체',
                      'csat': '수능',
                      'exam': contentTypeLabels['exam']!,
                      'university_essay':
                          contentTypeLabels['university_essay']!,
                      'study_material': contentTypeLabels['study_material']!,
                      'admissions_info': contentTypeLabels['admissions_info']!,
                    }.entries)
                      if (entry.key != 'other')
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(entry.value),
                            selected: entry.key == 'csat'
                                ? filters.examType == 'csat'
                                : filters.contentType == entry.key &&
                                      filters.examType == null,
                            onSelected: (selected) =>
                                change('type', selected ? entry.key : null),
                          ),
                        ),
                  ],
                ),
              ),
              if (!filters.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => filters = const SearchFilters());
                      search();
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('필터 초기화'),
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader('검색 결과'),
        const SizedBox(height: 8),
        if (validation == null) ...[
          if (state.phase == SearchPhase.loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(semanticsLabel: '자료 검색 중'),
              ),
            ),
          if (state.phase == SearchPhase.empty)
            const EmptyState('아직 등록된 자료가 없어요.'),
          if (state.phase == SearchPhase.noResults) ...[
            const EmptyState('조건에 맞는 자료가 없어요.'),
            Wrap(
              spacing: 8,
              children: [
                if (input.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      input.clear();
                      search();
                    },
                    child: const Text('검색어 지우기'),
                  ),
                if (!filters.isEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => filters = const SearchFilters());
                      search();
                    },
                    child: const Text('선택 조건 해제'),
                  ),
                TextButton(
                  onPressed: () {
                    input.clear();
                    setState(() => filters = const SearchFilters());
                    search();
                  },
                  child: const Text('자료 전체 보기'),
                ),
              ],
            ),
          ],
          if (state.phase == SearchPhase.error)
            ErrorState(
              message: '자료를 불러오지 못했어요. 다시 시도하거나 검색 조건을 좁혀 주세요.',
              onRetry: controller.retry,
            ),
          for (final item in state.items)
            SearchResultTile(key: ValueKey(item.content.id), item: item),
          if (state.moreFailed)
            const Text('다음 자료를 불러오지 못했어요. 조건을 좁히거나 다시 시도해 주세요.'),
          if (state.nextOffset != null)
            TextButton(
              onPressed: state.loadingMore ? null : controller.loadMore,
              child: Text(
                state.loadingMore
                    ? '불러오는 중…'
                    : state.moreFailed
                    ? '다음 자료 다시 시도'
                    : '자료 더 보기',
              ),
            ),
        ],
      ],
    );
  }
}

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({required this.item, super.key});
  final ResourceSearchItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space8),
    child: LsCard(
      level: LsSurfaceLevel.nested,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          context.push('/materials/${Uri.encodeComponent(item.content.slug)}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contentTypeLabels[item.content.contentType] ?? '자료',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTokens.textSecondary,
                      ),
                    ),
                  ),
                  InlineBookmarkButton(contentItemId: item.content.id),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (item.exam != null && examSummary(item.exam!).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(examSummary(item.exam!)),
                ),
              if (item.exam == null &&
                  (item.content.publishedAt ?? item.content.feedUpdatedAt) !=
                      null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${item.content.publishedAt != null ? '게시' : '업데이트'} ${formatDate((item.content.publishedAt ?? item.content.feedUpdatedAt)!)}',
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
                ),
              for (final group in item.groups.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${group.name} · ${group.kinds.isEmpty ? '등록된 첨부 없음' : group.kinds.map((k) => resourceTypeLabels[k]).join(' · ')}',
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
                ),
              if (item.groups.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('외 ${item.groups.length - 3}개 과목 · 상세에서 보기'),
                ),
              if (item.groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '등록된 첨부 없음',
                    style: TextStyle(color: AppTokens.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
