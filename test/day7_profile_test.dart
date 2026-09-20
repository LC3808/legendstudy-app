import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';

// Mock transport tests verify client payloads/preservation. They are NOT live RLS evidence.
void main() {
  late SupabaseClient client;
  late SupabaseProfileRepository repository;
  late List<http.Request> requests;
  late Map<String, Map<String, dynamic>> rows;
  setUp(() {
    requests = [];
    rows = {};
    client = SupabaseClient(
      'https://example.invalid',
      'test-public-client',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path != '/rest/v1/profiles') {
          return http.Response('{}', 200, request: request);
        }
        requests.add(request);
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final id = body['id'] as String;
          rows[id] = {...?rows[id], ...body};
          return http.Response('', 201, request: request);
        }
        final id = request.url.queryParameters['id']!.substring(3);
        return http.Response(
          jsonEncode(rows[id]),
          200,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    repository = SupabaseProfileRepository(client);
  });
  tearDown(() => client.dispose());
  Future<void> session(String owner) => client.auth.setInitialSession(
    jsonEncode({
      'access_token': 'unit-test-token',
      'refresh_token': 'unit-test-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': owner,
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-09-13T00:00:00Z',
      },
    }),
  );
  test('legacy upsert retains the exact existing payload', () async {
    await session('owner-a');
    await repository.upsertCurrentProfile(displayName: '학생', gradeLevel: 2);
    expect(jsonDecode(requests.single.body), {
      'id': 'owner-a',
      'display_name': '학생',
      'grade_level': 2,
    });
    expect(requests.single.url.queryParameters['on_conflict'], 'id');
  });
  test('school pair saves and fetch selects both fields', () async {
    await session('owner-a');
    await repository.updateSchoolSelection(
      officeCode: 'J10',
      schoolCode: '7530932',
    );
    final saved = await repository.fetchCurrentProfile();
    expect(saved!.neisOfficeCode, 'J10');
    expect(saved.neisSchoolCode, '7530932');
    expect(
      requests.last.url.queryParameters['select'],
      'id,display_name,grade_level,neis_office_code,neis_school_code',
    );
    expect(requests.last.url.queryParameters['id'], 'eq.owner-a');
  });
  test('clear sends two explicit nulls, not profile deletion', () async {
    await session('owner-a');
    await repository.updateSchoolSelection();
    expect(jsonDecode(requests.single.body), {
      'id': 'owner-a',
      'neis_office_code': null,
      'neis_school_code': null,
    });
    expect(requests.single.method, 'POST');
  });
  test('partial pair and invalid values rejected before transport', () async {
    await session('owner-a');
    await expectLater(
      repository.updateSchoolSelection(officeCode: 'J10'),
      throwsFormatException,
    );
    await expectLater(
      repository.updateSchoolSelection(schoolCode: '7530932'),
      throwsFormatException,
    );
    for (final office in ['', ' J10', 'J10\n', 'a' * 33]) {
      await expectLater(
        repository.updateSchoolSelection(
          officeCode: office,
          schoolCode: '7530932',
        ),
        throwsFormatException,
      );
    }
    expect(requests, isEmpty);
  });
  test(
    'school save and clear preserve name/grade via omitted fields',
    () async {
      await session('owner-a');
      await repository.upsertCurrentProfile(displayName: '학생', gradeLevel: 2);
      await repository.updateSchoolSelection(
        officeCode: 'J10',
        schoolCode: '7530932',
      );
      expect(rows['owner-a']!['display_name'], '학생');
      expect(rows['owner-a']!['grade_level'], 2);
      expect(
        (jsonDecode(requests.last.body) as Map).containsKey('display_name'),
        isFalse,
      );
      await repository.updateSchoolSelection();
      expect(rows['owner-a']!['display_name'], '학생');
      expect(rows['owner-a']!['grade_level'], 2);
    },
  );
  test(
    'grade-only and login upserts preserve existing name, grade and school',
    () async {
      await session('owner-a');
      await repository.upsertCurrentProfile(displayName: '학생', gradeLevel: 2);
      await repository.updateSchoolSelection(
        officeCode: 'J10',
        schoolCode: '7530932',
      );
      await repository.upsertCurrentProfile(gradeLevel: 3);
      expect(jsonDecode(requests.last.body), {
        'id': 'owner-a',
        'grade_level': 3,
      });
      await repository.upsertCurrentProfile();
      expect(jsonDecode(requests.last.body), {'id': 'owner-a'});
      final saved = await repository.fetchCurrentProfile();
      expect(saved!.displayName, '학생');
      expect(saved.gradeLevel, 3);
      expect(saved.neisSchoolCode, '7530932');
      final count = requests.length;
      await expectLater(
        repository.upsertCurrentProfile(gradeLevel: 4),
        throwsFormatException,
      );
      expect(requests.length, count);
    },
  );
  test('profile editing omits and preserves school pair', () async {
    await session('owner-a');
    await repository.updateSchoolSelection(
      officeCode: 'J10',
      schoolCode: '7530932',
    );
    await repository.upsertCurrentProfile(displayName: '변경', gradeLevel: 3);
    final saved = await repository.fetchCurrentProfile();
    expect(saved!.neisSchoolCode, '7530932');
    expect(saved.displayName, '변경');
  });
  test(
    'repository derives current owner for every call after account change',
    () async {
      await session('owner-a');
      await repository.updateSchoolSelection(
        officeCode: 'J10',
        schoolCode: '7530932',
      );
      await session('owner-b');
      await repository.updateSchoolSelection(
        officeCode: 'B10',
        schoolCode: '7010001',
      );
      expect(jsonDecode(requests.last.body)['id'], 'owner-b');
      expect(rows['owner-a']!['neis_office_code'], 'J10');
      expect((await repository.fetchCurrentProfile())!.id, 'owner-b');
    },
  );
  test(
    'signed-out reads safe null and writes require login with zero requests',
    () async {
      expect(await repository.fetchCurrentProfile(), isNull);
      await expectLater(
        repository.updateSchoolSelection(
          officeCode: 'J10',
          schoolCode: '7530932',
        ),
        throwsA(isA<SignedOutException>()),
      );
      await expectLater(
        repository.updateSchoolSelection(),
        throwsA(isA<SignedOutException>()),
      );
      expect(requests, isEmpty);
    },
  );
}
