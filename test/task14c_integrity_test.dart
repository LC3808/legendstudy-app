import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:legendstudy_app/features/universities/data/university_repository.dart';

import 'device_second_corrections_test.dart' show Saves, Pops, mountEditor;
import 'day7_school_test.dart' show schoolA, Schools;

void main() {
  testWidgets(
    'status/search/empty results and cancellation never write a profile',
    (t) async {
      final repo = Saves()
        ..value = UserProfile(
          id: 'a',
          academicStatus: 'student',
          gradeLevel: 2,
          neisOfficeCode: schoolA.officeCode,
          neisSchoolCode: schoolA.schoolCode,
        );
      final schools = Schools()..results = [];
      await mountEditor(t, const SchoolPage(), repo, Pops(), schools: schools);
      await t.enterText(find.byType(TextField).first, '존재하지 않는 대학');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
      expect(find.text(schoolA.name), findsOneWidget);
      await t.ensureVisible(find.text('N수·검정고시 등'));
      await t.tap(find.text('N수·검정고시 등'));
      await t.pumpAndSettle();
      expect(repo.writes, 0);
      expect(repo.schoolWrites, 0);
      Navigator.of(t.element(find.byType(SchoolPage))).pop();
      await t.pumpAndSettle();
      expect(repo.writes, 0);
    },
  );

  test('interest CRUD payloads are owner scoped and cannot overwrite school; profile cannot overwrite interests', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        requests.add(r);
        return http.Response('', 204, request: r);
      }),
    );
    addTearDown(client.dispose);
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'fixture',
        'refresh_token': 'fixture',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'owner',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    final uni = SupabaseUniversityRepository(client);
    await uni.addInterested('university', source: 'my', priority: 1);
    await uni.editInterested('target', division: '컴퓨터공학과', priority: 2);
    await uni.removeInterested('target');
    expect(requests.length, 3);
    for (final r in requests) {
      expect(r.url.path, '/rest/v1/student_target_universities');
      expect(r.body, isNot(contains('neis_')));
      expect(r.body, isNot(contains('grade_level')));
      expect(r.body, isNot(contains('academic_status')));
    }
    expect(jsonDecode(requests[1].body), {
      'intended_division': '컴퓨터공학과',
      'priority': 2,
    });
    for (final r in requests.skip(1)) {
      expect(r.url.queryParameters['user_id'], 'eq.owner');
      expect(r.url.queryParameters['status'], 'eq.interested');
      expect(r.url.queryParameters['id'], 'eq.target');
    }
    await SupabaseProfileRepository(client)
        .upsertCurrentProfile(gradeLevel: 3, academicStatus: 'student');
    expect(requests.last.url.path, '/rest/v1/profiles');
    expect(jsonDecode(requests.last.body), {
      'id': 'owner',
      'grade_level': 3,
      'academic_status': 'student',
    });
  });
}
