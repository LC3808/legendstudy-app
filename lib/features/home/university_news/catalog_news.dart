import 'dart:convert';

import 'package:http/http.dart' as http;

class CatalogNews {
  CatalogNews(this.universities);
  final List<Map<String, dynamic>> universities;
  factory CatalogNews.parse(Object? raw) {
    if (raw is! Map ||
        raw['version'] != 'university-news-catalog-v1' ||
        raw['universities'] is! List) {
      throw const FormatException('Invalid university news catalog');
    }
    final rows = (raw['universities'] as List)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();
    final ids = <String>{};
    for (final u in rows) {
      if (u['name'] is! String ||
          u['offerings'] is! List ||
          u['sourceUniversityId'] is! String) {
        throw const FormatException('Invalid university');
      }
      final id = u['universityId'];
      if (id != null && (id is! String || !ids.add(id))) {
        throw const FormatException('Duplicate university');
      }
      for (final o in u['offerings'] as List) {
        if (o is! Map ||
            o['academicYear'] is! int ||
            o['admissionName'] is! String ||
            o['divisions'] is! List) {
          throw const FormatException('Invalid offering');
        }
        for (final key in ['examDateText', 'examTimeText', 'sourceUrl']) {
          if (o[key] != null && o[key] is! String) {
            throw const FormatException('Invalid source field');
          }
        }
      }
    }
    return CatalogNews(rows);
  }
  static Future<CatalogNews> load() async {
    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse('https://lab.legendstudy.com/api/essay/catalog'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('Catalog unavailable');
      final raw = jsonDecode(response.body);
      if (raw is! Map) throw const FormatException('Invalid catalog');
      return CatalogNews.parse(raw['universityNews']);
    } finally {
      client.close();
    }
  }

  List<Map<String, dynamic>> select(
    Set<String> applications,
    Set<String> interests,
  ) {
    final byId = {
      for (final u in universities)
        if (u['universityId'] is String) u['universityId'] as String: u,
    };
    return [
      for (final id in {...applications, ...interests})
        if (byId[id] != null)
          {...byId[id]!, 'isApplication': applications.contains(id)},
    ];
  }
}
