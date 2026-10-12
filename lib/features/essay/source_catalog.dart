import 'dart:convert';

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
    return SourceCatalog(
      (data['universities'] as List).cast<Map<String, dynamic>>(),
      exams,
    );
  }
  static Future<SourceCatalog> load() async {
    final response = await http
        .get(Uri.parse('https://lab.legendstudy.com/api/essay/catalog'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Catalog unavailable');
    return SourceCatalog.parse(utf8.decode(response.bodyBytes));
  }
}
