import '../../core/network/review_read_only_client.dart';
import '../../core/config/app_config.dart';

import 'dart:convert';

import 'university_catalog.dart';

import 'package:http/http.dart' as http;

/// Same source keys as WEB. These are not canonical question UUIDs or billing IDs.
class SourceCatalog {
  SourceCatalog(this.universities, this.exams);
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
        },
    ], exams);
  }
  static Future<SourceCatalog> load({
    String? accessToken,
    http.Client? client,
    AppConfig? config,
  }) async {
    final origin = (config ?? AppConfig.fromEnvironment()).essayApiOrigin;
    final transport = client ?? reviewHttpClient();
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final privateResponse = await transport
            .post(
              Uri.parse('$origin/api/essay/catalog'),
              headers: {'Authorization': 'Bearer $accessToken'},
            )
            .timeout(const Duration(seconds: 20));
        if (privateResponse.statusCode == 200) {
          return SourceCatalog.parse(utf8.decode(privateResponse.bodyBytes));
        }
      }
      final response = await transport
          .get(Uri.parse('$origin/api/essay/catalog'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('Catalog unavailable');
      return SourceCatalog.parse(utf8.decode(response.bodyBytes));
    } finally {
      if (client == null) transport.close();
    }
  }
}
