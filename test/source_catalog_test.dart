import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'reviewed web pages override stale registry PDF links without changing IDs',
    () {
      final catalog = SourceCatalog.parse(
        jsonEncode({
          'version': 'essay-source-registry-v1',
          'universities': [
            {
              'sourceUniversityId': 'kau',
              'officialSourceUrl': 'https://example.com/old.pdf',
            },
          ],
          'exams': <Map<String, dynamic>>[],
        }),
      );
      expect(catalog.universities.length, 42);
      expect(
        catalog.universities.singleWhere(
          (u) => u['sourceUniversityId'] == 'kau',
        )['officialSourceUrl'],
        'https://ibhak.kau.ac.kr/admission/html/rolling/previous_in_exam.asp',
      );
      expect(
        catalog.universities.singleWhere(
          (u) => u['sourceUniversityId'] == 'sogang',
        )['officialSourceUrl'],
        isNull,
      );
    },
  );

  test('registered metadata preserves IDs, rejects private fields and never enables evaluation', () {
    const uid = '77fe30b2-f693-4612-a6d3-50e8be5c8f6c';
    const eid = '00000000-0000-4000-8000-000000000001';
    const qid = '00000000-0000-4000-8000-000000000002';
    final base = SourceCatalog([
      {'sourceUniversityId': 'konkuk', 'universityId': uid},
    ], []);
    final row = {
      'examId': eid,
      'universityId': uid,
      'year': 2026,
      'kind': 'admission',
      'track': '자연',
      'title': '수시',
      'questionCount': 1,
      'questions': [
        {'id': qid, 'label': '1번', 'solution': 'PRIVATE'},
      ],
      'evidence': 'PRIVATE',
    };
    final result = base.withRegistered('konkuk', [row]);
    expect(result.exams.single['dbExamId'], eid);
    expect(result.exams.single['evaluationReady'], false);
    expect(result.exams.single['verification'], 'REVIEW_REQUIRED');
    expect(jsonEncode(result.exams), isNot(contains('PRIVATE')));
    expect(
      () => base.withRegistered('konkuk', [row, row]),
      throwsFormatException,
    );
    expect(
      () => base.withRegistered('konkuk', [
        {...row, 'universityId': eid},
      ]),
      throwsFormatException,
    );
    expect(result.withRegistered('konkuk', [row]).exams.length, 1);
  });
  test('Hanyang archive fallback preserves catalog identities and exams', () {
    final raw = {
      'version': 'essay-source-registry-v1',
      'universities': [
        {
          'sourceUniversityId': 'hanyang',
          'officialSourceUrl': 'https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=14860&m_type=SUSI',
        },
      ],
      'exams': <Object>[],
    };
    final catalog = SourceCatalog.parse(jsonEncode(raw));
    expect(catalog.universities.length, 42);
    final hanyang = catalog.universities.singleWhere(
      (u) => u['sourceUniversityId'] == 'hanyang',
    );
    expect(
      hanyang['officialSourceUrl'],
      'https://go.hanyang.ac.kr/web/pds/pds_list.do?ct02=ns01&m_type=SUSI',
    );
    expect(hanyang['universityId'], '1090e1be-174e-5042-abd3-ca929c6e26f8');
    expect(
      (raw['universities'] as List).single['officialSourceUrl'],
      contains('bn=14860'),
    );
  });
  test('server source keys are preserved; duplicates cannot merge exams', () {
    final exam = {
      'key': 'source:shared',
      'verification': 'VERIFIED',
      'questions': [
        {'key': 'source:shared:1'},
      ],
    };
    final data = {
      'version': 'essay-source-registry-v1',
      'universities': <Object>[],
      'exams': [exam],
    };
    expect(
      SourceCatalog.parse(jsonEncode(data)).exams.single['key'],
      'source:shared',
    );
    data['exams'] = [exam, exam];
    expect(() => SourceCatalog.parse(jsonEncode(data)), throwsFormatException);
  });
  test(
    'draft restore, owner isolation, stale revisions and disabled evaluation',
    () async {
      final disk = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
            if (call.method == 'read') return disk[call.arguments];
            if (call.method == 'write') {
              final a = call.arguments as Map;
              disk[a['key'] as String] = a['value'] as String;
              return null;
            }
            return null;
          });
      final a = SourceDraftGateway('owner-a', 'source:question');
      await a.saveDraft('내 답안', 0);
      expect(
        (await SourceDraftGateway(
          'owner-a',
          'source:question',
        ).loadDraft()).body,
        '내 답안',
      );
      expect(
        (await SourceDraftGateway(
          'owner-b',
          'source:question',
        ).loadDraft()).body,
        '',
      );
      expect(
        (await SourceDraftGateway('owner-a', 'source:other').loadDraft()).body,
        '',
      );
      await expectLater(a.saveDraft('stale', 0), throwsA(isA<EssayConflict>()));
      await expectLater(a.submit('answer', 1, 'k'), throwsStateError);
    },
  );
}
