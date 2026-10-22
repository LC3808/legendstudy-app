import '../../core/network/review_read_only_client.dart';
import '../../core/config/app_config.dart';

import 'dart:convert';

import 'university_catalog.dart';

import 'package:http/http.dart' as http;

/// Same source keys as WEB. These are not canonical question UUIDs or billing IDs.
class SourceCatalog {
  SourceCatalog(
    this.universities,
    this.exams, {
    this.browseUnavailable = false,
  });
  final bool browseUnavailable;
  final List<Map<String, dynamic>> universities, exams;
  factory SourceCatalog.parse(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (data['version'] != 'essay-source-registry-v1') {
      throw const FormatException('Unsupported essay catalog');
    }
    final exams = (data['exams'] as List).cast<Map<String, dynamic>>();
    final keys = <String>{};
    for (final e in exams) {
      if (e['verification'] != 'VERIFIED' ||
          !keys.add(e['key'] as String) ||
          (e['questions'] as List).isEmpty) {
        throw const FormatException('Invalid essay catalog');
      }
    }
    return SourceCatalog([
      for (final u in essayUniversityCatalog)
        {
          ...u,
          ...?(data['universities'] as List)
              .cast<Map<String, dynamic>>()
              .where((r) => r['sourceUniversityId'] == u['sourceUniversityId'])
              .firstOrNull,
          // This university-wide URL identifies a 2025 mock essay, not the
          // selected exam. Use the official archive without changing source data.
          if (u['sourceUniversityId'] == 'hanyang') 'officialSourceUrl': 'https://go.hanyang.ac.kr/web/pds/pds_list.do?ct02=ns01&m_type=SUSI',
        },
    ], exams);
  }

  /// Metadata-only projection; never accepts PDF/evidence/answer fields from RPC.
  SourceCatalog withRegistered(String sourceId, dynamic rows) {
    if (rows is! List) throw const FormatException('Invalid browse catalog');
    final university = universities
        .where((u) => u['sourceUniversityId'] == sourceId)
        .single;
    final seen = <String>{};
    final projected = <Map<String, dynamic>>[];
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    for (final raw in rows) {
      if (raw is! Map ||
          raw['examId'] is! String ||
          !uuid.hasMatch(raw['examId'] as String) ||
          !seen.add(raw['examId'] as String) ||
          raw['universityId'] is! String ||
          !uuid.hasMatch(raw['universityId'] as String) ||
          (university['universityId'] != null &&
              raw['universityId'] != university['universityId']) ||
          raw['year'] is! int ||
          !{'admission', 'mock'}.contains(raw['kind']) ||
          raw['questions'] is! List) {
        throw const FormatException('Invalid browse identity');
      }
      final questions = (raw['questions'] as List);
      final questionIds = <String>{};
      if (questions.isEmpty || questions.length != raw['questionCount']) {
        throw const FormatException('Invalid question count');
      }
      for (final q in questions) {
        if (q is! Map ||
            q['id'] is! String ||
            !uuid.hasMatch(q['id'] as String) ||
            q['label'] is! String ||
            !questionIds.add(q['id'] as String)) {
          throw const FormatException('Invalid question identity');
        }
      }
      final existing = exams
          .where((e) => e['dbExamId'] == raw['examId'])
          .firstOrNull;
      // Preserve a reviewed source only on exact canonical identity correspondence.
      if (existing != null &&
          existing['sourceUniversityId'] == sourceId &&
          (existing['questions'] as List).length == questions.length &&
          (existing['questions'] as List).every(
            (q) => questionIds.contains(q['dbQuestionId']),
          )) {
        projected.add(existing);
      } else {
        projected.add({
          'key': 'registered:${raw['examId']}',
          'dbExamId': raw['examId'],
          'universityId': raw['universityId'],
          'sourceUniversityId': sourceId,
          'year': raw['year'],
          'kind': raw['kind'],
          'track': raw['track'] ?? raw['title'],
          'session': raw['title'],
          'verification': 'REVIEW_REQUIRED',
          'evaluationReady': false,
          'questions': questions
              .map(
                (q) => <String, dynamic>{
                  'key': 'registered:${q['id']}',
                  'dbQuestionId': q['id'],
                  'label': q['label'],
                  'accountDraftReady': false,
                },
              )
              .toList(),
        });
      }
    }
    return SourceCatalog(universities, [
      ...exams.where((e) => e['sourceUniversityId'] != sourceId),
      ...projected,
    ]);
  }

  static Future<SourceCatalog> load({
    String? accessToken,
    String? university,
    Future<dynamic> Function(String)? browse,
    http.Client? client,
    AppConfig? config,
  }) async {
    final origin = (config ?? AppConfig.fromEnvironment()).essayApiOrigin;
    final transport = client ?? reviewHttpClient();
    Future<SourceCatalog> connect(SourceCatalog base) async {
      if (university == null || browse == null) return base;
      try {
        return base.withRegistered(university, await browse(university));
      } catch (_) {
        return SourceCatalog(
          base.universities,
          base.exams,
          browseUnavailable: true,
        );
      }
    }

    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final privateResponse = await transport
            .post(
              Uri.parse('$origin/api/essay/catalog'),
              headers: {'Authorization': 'Bearer $accessToken'},
            )
            .timeout(const Duration(seconds: 20));
        if (privateResponse.statusCode == 200) {
          return await connect(
            SourceCatalog.parse(utf8.decode(privateResponse.bodyBytes)),
          );
        }
      }
      final response = await transport
          .get(Uri.parse('$origin/api/essay/catalog'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('Catalog unavailable');
      return await connect(
        SourceCatalog.parse(utf8.decode(response.bodyBytes)),
      );
    } finally {
      if (client == null) transport.close();
    }
  }
}
