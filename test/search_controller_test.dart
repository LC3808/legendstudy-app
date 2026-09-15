import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';
import 'support/search_fake.dart';

void main() {
  test(
    'loading, data, paging, empty, no-results and retry are distinct',
    () async {
      final repo = FakeSearchRepository();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final control = container.read(searchControllerProvider.notifier);
      final pending = Completer<void>();
      repo.delay = pending.future;
      final search = control.search(SearchQuery(''));
      expect(
        container.read(searchControllerProvider).phase,
        SearchPhase.loading,
      );
      pending.complete();
      await search;
      repo.delay = null;
      expect(container.read(searchControllerProvider).items.length, 3);
      await control.loadMore();
      expect(container.read(searchControllerProvider).items.length, 6);
      repo.fail = true;
      await control.loadMore();
      expect(container.read(searchControllerProvider).moreFailed, isTrue);
      expect(container.read(searchControllerProvider).items.length, 6);
      repo.fail = false;
      await control.loadMore();
      expect(container.read(searchControllerProvider).items.length, 9);
      await control.search(SearchQuery('없는결과'));
      expect(
        container.read(searchControllerProvider).phase,
        SearchPhase.noResults,
      );
      repo.fail = true;
      await control.retry();
      expect(container.read(searchControllerProvider).phase, SearchPhase.error);
      repo.fail = false;
      repo.items.clear();
      await control.search(SearchQuery(''));
      expect(container.read(searchControllerProvider).phase, SearchPhase.empty);
    },
  );
  test('older request cannot replace a newer query or page', () async {
    final repo = FakeSearchRepository();
    final container = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final control = container.read(searchControllerProvider.notifier);
    final pending = Completer<void>();
    repo.delay = pending.future;
    final old = control.search(SearchQuery('국어'));
    repo.delay = null;
    await control.search(SearchQuery('영어'));
    pending.complete();
    await old;
    expect(
      container
          .read(searchControllerProvider)
          .items
          .every((i) => i.groups.single.name == '영어'),
      isTrue,
    );
  });
  test('fixture query semantics and stable ordering across pages', () async {
    final repo = FakeSearchRepository();
    final page = await repo.search(SearchQuery('2026 9 월 고3 영어'));
    expect(page.items.single.content.id, 'fixture-2');
    final first = await repo.search(SearchQuery(''));
    final next = await repo.search(SearchQuery(''), offset: first.nextOffset!);
    expect(first.items.map((i) => i.content.id), [
      'fixture-2',
      'fixture-1',
      'fixture-0',
    ]);
    expect(next.items.first.exam!.year, 2025);
    expect((await repo.search(SearchQuery('수능'))).items, isEmpty);
    expect(
      (await repo.search(
        SearchQuery(
          '',
          filters: const SearchFilters(grade: 2, year: 2025, subjectId: 'math'),
        ),
      )).items.single.content.id,
      'fixture-4',
    );
  });
}
