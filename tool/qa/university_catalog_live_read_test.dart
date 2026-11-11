// Explicit read-only production smoke test; never included in the default test/ suite.
// Uses ignored local public-client configuration. No auth session or user writes.
import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/universities/data/university_repository.dart';
import 'package:legendstudy_app/features/universities/application/university_providers.dart';
import 'package:legendstudy_app/features/universities/presentation/interested_universities_field.dart';
import 'package:legendstudy_app/features/applications/application_editor.dart';
import 'package:legendstudy_app/features/applications/application_repository.dart';

class RealHttp extends HttpOverrides {}

void main() {
  testWidgets('78 live catalog rows and both real search widgets, read only', (
    t,
  ) async {
    final config = jsonDecode(
      File('.local/onboarding-device/build-defines.private.json')
          .readAsStringSync(),
    );
    final transport = IOClient(
      HttpOverrides.runWithHttpOverrides(() => HttpClient(), RealHttp()),
    );
    final client = SupabaseClient(
      config['SUPABASE_URL'] as String,
      config['SUPABASE_PUBLISHABLE_KEY'] as String,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: transport,
    );
    final repo = SupabaseUniversityRepository(client);
    final rows =
        File('supabase/candidates/university_catalog_20261112/audit.csv')
            .readAsLinesSync()
            .skip(1)
            .map((s) => s.split(','))
            .where((r) => r[3] == 'CANDIDATE')
            .toList();
    expect(rows.length, 78);
    await t.runAsync(() async {
      for (final row in rows) {
        expect(
          (await repo.searchCatalog(row[0])).any((u) => u.id == row[1]),
          true,
          reason: row[0],
        );
      }
      for (final q in ['한국교원대', ' 한국 교원대 ', 'KNUE']) {
        expect(
          (await repo.searchCatalog(q)).single.id,
          'd8c6085f-eb45-5d6e-82f9-e5033d82963e',
        );
      }
    });
    Future<void> mount(Widget child) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            universityRepositoryProvider.overrideWithValue(repo),
            applicationRepositoryProvider.overrideWithValue(
              ApplicationRepository(
                (_, __) async => throw StateError('NO WRITES ALLOWED'),
                () => 'isolated',
                'isolated',
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    await mount(const InterestedUniversitiesField(source: 'onboarding'));
    await t.enterText(find.byType(TextField).first, '한국교원대');
    await t.pump();
    final container = ProviderScope.containerOf(
      t.element(find.byType(InterestedUniversitiesField)),
    );
    await t.runAsync(() async {
      container.listen(universitySearchProvider('한국교원대'), (_, __) {});
      await container.read(universitySearchProvider('한국교원대').future);
    });
    await t.tap(find.text('검색'));
    await t.pumpAndSettle();
    expect(find.text('한국교원대학교'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await mount(const ApplicationEditor(embedded: true));
    final state = t.state<ApplicationEditorState>(
      find.byType(ApplicationEditor),
    );
    state.query.text = '한국교원대';
    await t.runAsync(state.search);
    await t.pumpAndSettle();
    expect(state.results.single.id, 'd8c6085f-eb45-5d6e-82f9-e5033d82963e');
    expect(find.text('한국교원대학교'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    transport.close();
  });
}
