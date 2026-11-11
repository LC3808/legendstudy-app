import 'package:legendstudy_app/features/universities/data/university_repository.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/applications/application_repository.dart';
import 'package:legendstudy_app/features/applications/applications_page.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';

class FakeUniversities implements UniversityRepository {
  @override
  Future<List<University>> searchCatalog(String q, {int limit = 20}) async => [
    const University(id: 'university', name: '테스트대학교'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('eligibility is saved high3 or retaker only', () {
    expect(
      canManageApplications(
        const UserProfile(id: 'u', academicStatus: 'student', gradeLevel: 3),
      ),
      isTrue,
    );
    expect(
      canManageApplications(
        const UserProfile(id: 'u', academicStatus: 'retaker'),
      ),
      isTrue,
    );
    for (final status in [null, 'other', 'student']) {
      expect(
        canManageApplications(
          UserProfile(id: 'u', academicStatus: status, gradeLevel: 2),
        ),
        isFalse,
      );
    }
  });
  test('uncertain retry key stable; changed track or year gets new key', () {
    final keys = ApplicationRequestKey();
    final a = keys.forInput({'year': 2027, 'track': '논술'});
    expect(keys.forInput({'year': 2027, 'track': '논술'}), a);
    expect(keys.forInput({'year': 2027, 'track': '학생부'}), isNot(a));
    expect(keys.forInput({'year': 2028, 'track': '논술'}), isNot(a));
  });
  test('pages use existing RPC; never truncate after first page', () async {
    final offsets = <int>[];
    final r = ApplicationRepository(
      (name, args) async {
        expect(name, 'my_applications');
        offsets.add(args['p_offset'] as int);
        return {
          'version': 'applications-v1',
          'has_more': offsets.length == 1,
          'items': List.generate(
            offsets.length == 1 ? 25 : 1,
            (i) => {
              'id': '$i',
              'university_id': 'u',
              'university_name_snapshot': '대학',
              'intended_division': '학과',
              'admission_type': '수시',
              'admission_name': '논술',
              'admission_year': 2027,
              'revision': 1,
              'latest_event': null,
            },
          ),
        };
      },
      () => 'u',
      'u',
    );
    expect(await r.list(), hasLength(26));
    expect(offsets, [0, 25]);
  });
  test(
    'malformed empty continuation fails instead of incomplete success',
    () async {
      final r = ApplicationRepository(
        (_, _) async => {
          'version': 'applications-v1',
          'has_more': true,
          'items': <Map<String, dynamic>>[],
        },
        () => 'u',
        'u',
      );
      await expectLater(r.list(), throwsFormatException);
    },
  );
  test(
    'owner change suppresses stale read and prevents further writes',
    () async {
      String? owner = 'a';
      final pending = Completer<Object?>();
      var calls = 0;
      final r = ApplicationRepository(
        (_, _) {
          calls++;
          return pending.future;
        },
        () => owner,
        'a',
      );
      final future = r.list();
      owner = 'b';
      pending.complete({
        'version': 'applications-v1',
        'has_more': false,
        'items': <Map<String, dynamic>>[],
      });
      await expectLater(future, throwsA(isA<AuthException>()));
      await expectLater(r.delete('x'), throwsA(isA<AuthException>()));
      expect(calls, 1);
    },
  );
  test(
    'status append, correction and delete preserve existing RPC contracts',
    () async {
      final calls = <Map<String, dynamic>>[];
      final r = ApplicationRepository(
        (n, p) async {
          calls.add({'name': n, ...p});
          return 'saved';
        },
        () => 'u',
        'u',
      );
      await r.event('a', 'accepted', null, 'key1');
      await r.event('a', 'registered', null, 'key2');
      await r.event('a', 'rejected', 'accepted-event', 'key3');
      expect(calls[1]['p_supersedes'], isNull);
      expect(calls[2]['p_supersedes'], 'accepted-event');
      expect(calls.every((c) => c['name'] == 'my_application_event'), isTrue);
      expect(calls.every((c) => c['p_occurred_at'] == null), isTrue);
      await expectLater(
        r.event('a', 'waitlisted', null, 'k'),
        throwsFormatException,
      );
      await r.delete('a');
      expect(calls.last, {'name': 'my_application_delete', 'p_id': 'a'});
    },
  );
  test(
    'save carries revision and semantic fields without inventing new RPC',
    () async {
      final input = {
        'p_id': 'a',
        'p_revision': 4,
        'p_year': 2027,
        'p_university': 'u',
        'p_division': '경영',
        'p_admission_type': '수시',
        'p_admission_name': '논술',
      };
      final r = ApplicationRepository(
        (name, args) async {
          expect(name, 'my_application_save');
          expect(args, {...input, 'p_request_key': 'key'});
          return 'a';
        },
        () => 'u',
        'u',
      );
      expect(await r.save(input, 'key'), 'a');
      expect(
        applicationError(
          const PostgrestException(
            message: 'APPLICATION_ALREADY_EXISTS',
            code: '23505',
          ),
        ),
        contains('동일한 지원'),
      );
      expect(
        applicationError(
          const PostgrestException(message: 'revision', code: '40001'),
        ),
        contains('새로고침'),
      );
    },
  );
  for (final status in ['student', 'retaker', 'other']) {
    testWidgets('MY entry $status and native list 200% text', (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final r = ApplicationRepository(
        (_, _) async => {
          'version': 'applications-v1',
          'has_more': false,
          'items': <Map<String, dynamic>>[],
        },
        () => 'u',
        'u',
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            applicationRepositoryProvider.overrideWithValue(r),
            currentProfileProvider.overrideWith(
              (_) async =>
                  UserProfile(id: 'u', academicStatus: status, gradeLevel: 3),
            ),
          ],
          child: MaterialApp(
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: w!,
            ),
            home: const Scaffold(body: ApplicationsEntry()),
          ),
        ),
      );
      await t.pumpAndSettle();
      if (status == 'other') {
        expect(find.text('실제 지원 대학 관리'), findsNothing);
        return;
      }
      await t.tap(find.text('실제 지원 대학 관리'));
      await t.pumpAndSettle();
      expect(find.text('등록된 지원 내역이 없습니다.'), findsOneWidget);
      await t.tap(find.text('지원 대학 등록하기'));
      await t.pumpAndSettle();
      expect(find.text('지원 학년도 · 필수'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'registration partial event failure retries without creating application twice',
    (t) async {
      var saves = 0, events = 0;
      final eventKeys = <String>[];
      final repo = ApplicationRepository(
        (name, p) async {
          if (name == 'my_applications') {
            return {
              'version': 'applications-v1',
              'has_more': false,
              'items': <Map<String, dynamic>>[],
            };
          }
          if (name == 'my_application_save') {
            saves++;
            return 'saved-id';
          }
          if (name == 'my_application_event') {
            events++;
            eventKeys.add(p['p_request_key'] as String);
            if (events == 1) {
              throw Exception('offline');
            }
            return 'event';
          }
          throw Exception('Unexpected RPC');
        },
        () => 'u',
        'u',
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            applicationRepositoryProvider.overrideWithValue(repo),
            universityRepositoryProvider.overrideWithValue(FakeUniversities()),
            currentProfileProvider.overrideWith(
              (_) async =>
                  const UserProfile(id: 'u', academicStatus: 'retaker'),
            ),
          ],
          child: const MaterialApp(home: ApplicationsPage()),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('지원 대학 등록하기'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, '테스트');
      await t.tap(find.byTooltip('검색'));
      await t.pumpAndSettle();
      await t.tap(find.text('테스트대학교'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextFormField, '모집단위·학과'), '경영학과');
      await t.enterText(find.widgetWithText(TextFormField, '전형명'), '논술');
      await t.ensureVisible(find.text('저장'));
      await t.tap(find.text('저장'));
      await t.pumpAndSettle();
      expect(find.text('지원 정보는 저장됐어요. 상태 기록 저장을 다시 시도해 주세요.'), findsOneWidget);
      await t.ensureVisible(find.text('저장'));
      await t.tap(find.text('저장'));
      await t.pumpAndSettle();
      expect(saves, 1);
      expect(events, 2);
      expect(eventKeys[0], eventKeys[1]);
      expect(find.text('지원 대학 등록하기'), findsOneWidget);
    },
  );
}
