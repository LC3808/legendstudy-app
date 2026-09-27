import 'package:legendstudy_app/features/resources/data/trusted_resolver_client.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';
import 'package:legendstudy_app/features/resources/presentation/resource_section.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_edit_page.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/profile/avatar.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/content/presentation/material_display_title.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';

import 'avatar_test.dart' show Photos, Picker;
import 'day7_school_test.dart' show Schools;
import 'device_second_corrections_test.dart' show Saves, Pops, mountEditor;

ContentResource paper({
  String label = '국어 문제.pdf',
  String kind = 'question',
  String url = 'https://t1.daumcdn.net/cfile/tistory/99FCCF455FBB3A5723',
  String link = 'file',
  String? extension = 'pdf',
}) => ContentResource(
  id: 'r',
  contentItemId: 'p',
  resourceType: kind,
  title: label,
  sourceLabel: label,
  sourceUrl: url,
  linkKind: link,
  fileExtension: extension,
);

void main() {
  testWidgets('integrated and separate PDFs use truthful visible CTA labels', (
    t,
  ) async {
    final rows = [
      paper(label: '경기대 문제,답안.pdf', kind: 'answer'),
      paper(label: '논술 문제.pdf'),
      paper(label: '논술 답안.pdf', kind: 'answer'),
    ];
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          contentResourcesProvider('p').overrideWith((ref) async => rows),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResourceSection(
                contentItemId: 'p',
                contentSlug: 'p',
                contentSourceUrl: 'https://legendstudy.com/1626',
                isArticle: false,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('자료 보기'), findsOneWidget);
    expect(find.text('문제 보기'), findsOneWidget);
    expect(find.text('답안 보기'), findsOneWidget);
    expect(find.text('정답 보기'), findsNothing);
  });
  testWidgets('school final save waits for status and failed status retry', (
    t,
  ) async {
    final repo = Saves()..fail = true;
    final pops = Pops();
    await mountEditor(t, const SchoolPage(), repo, pops);
    expect(find.text('출처: 교육부·시도교육청 NEIS'), findsNothing);
    await t.ensureVisible(find.text('N수·검정고시 등'));
    await t.tap(find.text('N수·검정고시 등'));
    await t.pump();
    expect(
      t.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
    repo.pending.complete();
    await t.pumpAndSettle();
    expect(pops.count, 0);
    expect(
      t.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
    repo.fail = false;
    await t.tap(find.text('N수·검정고시 등'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('저장'));
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect(pops.count, 1);
  });
  test('observed CSAT title is display-only and keeps academic year', () {
    const raw = '[2020년 12월 시행] 2021학년도 수능 기출 문제, 답, 해설, 등급, 듣기 : 국어/영어';
    expect(materialDisplayTitle(raw, 'exam'), '[2020년 12월 시행] 2021학년도 수능');
    expect(materialDisplayTitle(raw, 'study_material'), raw);
    expect(materialDisplayTitle('수능 안내', 'exam'), '수능 안내');
  });
  test('guidebook keeps its kind and uses evidence-gated PDF resolver', () {
    final guide = paper(
      label: '2024 부산대 논술가이드북.pdf',
      kind: 'other',
      link: 'unknown',
      url: 'https://blog.kakaocdn.net/dna/cODFT6/btsAzdEyA9A/token/guide.pdf',
    );
    expect(guide.purposeLabel, '자료');
    expect(guide.resourceType, 'other');
    expect(guide.openLabel(isEssay: true), '자료 보기');
    expect(
      paper(
        label: '정답 및 해설.pdf',
        kind: 'answer_explanation',
      ).openLabel(isEssay: true),
      '답안 보기',
    );
    expect(resolverCapable(guide), isTrue);
    expect(
      resolveResourceDelivery(guide, 'https://legendstudy.com/1593').kind,
      ResourceDeliveryKind.sourcePage,
    );
    expect(paper(label: '기타 자료.pdf', kind: 'other').purposeLabel, '자료');
  });
  test('integrated paper CTA does not narrow contents to an answer', () {
    expect(
      paper(label: '2024 경기대 유형A 문제,답안.pdf', kind: 'answer').purposeLabel,
      '자료',
    );
    expect(
      paper(
        label: '모의논술 문제·해설·예시답안.pdf',
        kind: 'answer_explanation',
      ).purposeLabel,
      '자료',
    );
    expect(paper(label: '논술 문제.pdf').purposeLabel, '문제');
    expect(paper(label: '논술 예시답안.pdf', kind: 'answer').purposeLabel, '답안');
    expect(
      paper(label: '국어 정답,해설.pdf', kind: 'answer_explanation').purposeLabel,
      '정답·해설',
    );
  });
  test('legacy cfile PDF metadata permits only exact stable HTTPS CDN', () {
    const source = 'https://legendstudy.com/1447';
    final good = resolveResourceDelivery(paper(), source);
    expect(good.kind, ResourceDeliveryKind.externalFile);
    expect(good.uri.toString(), paper().sourceUrl);
    for (final bad in [
      paper(url: '${paper().sourceUrl}?signature=x'),
      paper(url: '${paper().sourceUrl}#fragment'),
      paper(url: paper().sourceUrl.replaceFirst('https:', 'http:')),
      paper(url: paper().sourceUrl.replaceFirst('t1.daumcdn.net', 'evil.test')),
      paper(url: paper().sourceUrl.replaceFirst('/cfile/tistory/', '/other/')),
      paper(link: 'unknown'),
      paper(extension: null),
    ]) {
      expect(
        resolveResourceDelivery(bad, source).kind,
        ResourceDeliveryKind.sourcePage,
      );
    }
    expect(
      resolveResourceDelivery(paper(link: 'landing_page'), source).kind,
      ResourceDeliveryKind.externalPage,
    );
  });
  for (final page in ['edit', 'school']) {
    for (final fail in [false, true]) {
      testWidgets(
        'real shell $page confirmed save ${fail ? 'stays' : 'returns'}',
        (t) async {
          final repo = Saves()..fail = fail;
          repo.value = UserProfile(
            id: 'a',
            displayName: '학생',
            gradeLevel: 2,
            onboardingCompletedAt: DateTime(2026),
          );
          final c = ProviderContainer(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('a')),
              ),
              profileRepositoryProvider.overrideWithValue(repo),
              schoolRepositoryProvider.overrideWithValue(Schools()),
              avatarRepositoryProvider.overrideWithValue(Photos()),
              avatarPickerProvider.overrideWithValue(Picker()),
            ],
          );
          addTearDown(c.dispose);
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: const LegendStudyApp(),
            ),
          );
          await t.pumpAndSettle();
          final router = c.read(routerProvider);
          router.go('/my/settings');
          await t.pumpAndSettle();
          router.push('/my/$page');
          await t.pumpAndSettle();
          await t.ensureVisible(find.text('저장'));
          await t.tap(find.text('저장'));
          await t.pump();
          expect(repo.writes, 1);
          repo.pending.complete();
          await t.pumpAndSettle();
          expect(
            find.byType(page == 'edit' ? ProfileEditPage : SchoolPage),
            fail ? findsOneWidget : findsNothing,
          );
          if (fail) expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
