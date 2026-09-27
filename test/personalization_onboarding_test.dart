import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:legendstudy_app/features/onboarding/onboarding_gate.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';

// Mock-transport tests verify client payloads only; not live RLS evidence.
void main() {
  group('onboardingRedirect gate', () {
    const authedIncomplete = AsyncData(UserProfile(id: 'a'));
    final authedDone = AsyncData(
      UserProfile(id: 'a', onboardingCompletedAt: DateTime(2026)),
    );

    test('guests are never redirected', () {
      expect(
        onboardingRedirect(
          authed: false,
          profile: const AsyncData(null),
          location: '/home',
        ),
        isNull,
      );
    });

    test('authenticated user without completed onboarding is sent to flow', () {
      expect(
        onboardingRedirect(
          authed: true,
          profile: authedIncomplete,
          location: '/home',
        ),
        onboardingRoute,
      );
    });

    test('authenticated user with no profile row is sent to flow', () {
      expect(
        onboardingRedirect(
          authed: true,
          profile: const AsyncData(null),
          location: '/materials',
        ),
        onboardingRoute,
      );
    });

    test('completed onboarding stays put', () {
      expect(
        onboardingRedirect(
          authed: true,
          profile: authedDone,
          location: '/home',
        ),
        isNull,
      );
    });

    test('loading or errored profile waits, no redirect', () {
      expect(
        onboardingRedirect(
          authed: true,
          profile: const AsyncLoading(),
          location: '/home',
        ),
        isNull,
      );
      expect(
        onboardingRedirect(
          authed: true,
          profile: AsyncError(StateError('x'), StackTrace.empty),
          location: '/home',
        ),
        isNull,
      );
    });

    test('never intercepts onboarding or auth routes', () {
      for (final location in [
        onboardingRoute,
        '/auth',
        '/auth/new-password',
        '/auth/owner-check',
      ]) {
        expect(
          onboardingRedirect(
            authed: true,
            profile: authedIncomplete,
            location: location,
          ),
          isNull,
          reason: location,
        );
      }
    });
  });

  group('UserProfile decode', () {
    test('maps new canonical fields', () {
      final p = UserProfile.fromJson({
        'id': 'a',
        'academic_status': 'retaker',
        'onboarding_completed_at': '2026-09-27T01:02:03Z',
      });
      expect(p.academicStatus, 'retaker');
      expect(p.hasCompletedOnboarding, isTrue);
      expect(p.onboardingCompletedAt, DateTime.parse('2026-09-27T01:02:03Z'));
    });

    test('null-safe for legacy rows', () {
      final p = UserProfile.fromJson({'id': 'a'});
      expect(p.academicStatus, isNull);
      expect(p.onboardingCompletedAt, isNull);
      expect(p.hasCompletedOnboarding, isFalse);
    });
  });

  group('SupabaseProfileRepository personalization writes', () {
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
            rows[body['id'] as String] = {
              ...?rows[body['id']],
              ...body,
            };
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
          'created_at': '2026-09-27T00:00:00Z',
        },
      }),
    );

    test('academic status upsert sends only that field', () async {
      await session('owner-a');
      await repository.upsertCurrentProfile(academicStatus: 'student');
      expect(jsonDecode(requests.single.body), {
        'id': 'owner-a',
        'academic_status': 'student',
      });
    });

    test('clearAcademicStatus sends explicit null', () async {
      await session('owner-a');
      await repository.upsertCurrentProfile(clearAcademicStatus: true);
      expect(jsonDecode(requests.single.body), {
        'id': 'owner-a',
        'academic_status': null,
      });
    });

    test('invalid academic status is rejected before transport', () async {
      await session('owner-a');
      await expectLater(
        repository.upsertCurrentProfile(academicStatus: 'teacher'),
        throwsFormatException,
      );
      expect(requests, isEmpty);
    });

    test('markOnboardingComplete stamps only the completion field', () async {
      await session('owner-a');
      await repository.markOnboardingComplete();
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body.keys, unorderedEquals(['id', 'onboarding_completed_at']));
      expect(body['id'], 'owner-a');
      expect(
        DateTime.parse(body['onboarding_completed_at'] as String).isUtc,
        isTrue,
      );
    });

    test('finish path preserves prior fields and fetch decodes them', () async {
      await session('owner-a');
      await repository.upsertCurrentProfile(
        academicStatus: 'student',
        gradeLevel: 2,
      );
      await repository.markOnboardingComplete();
      final saved = await repository.fetchCurrentProfile();
      expect(saved!.academicStatus, 'student');
      expect(saved.gradeLevel, 2);
      expect(saved.hasCompletedOnboarding, isTrue);
    });
  });
}
