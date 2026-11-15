import 'dart:io';

import 'package:legendstudy_app/features/essay/university_catalog.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/features/home/university_news/catalog_news.dart';

void main() {
  test(
    'operating API captured response parses on APP',
    () {
      final path = Platform.environment['NEWS_LIVE_FIXTURE'];
      if (path == null) return;
      final raw = jsonDecode(File(path).readAsStringSync());
      final n = CatalogNews.parse(raw['universityNews']);
      expect(n.universities.length, 42);
      expect(
        {
          for (final u in essayUniversityCatalog)
            u['sourceUniversityId']: u['universityId'],
        },
        {
          for (final u in n.universities)
            u['sourceUniversityId']: u['universityId'],
        },
      );
      expect(n.universities.where((u) => u['universityId'] != null).length, 42);
    },
    skip: Platform.environment['NEWS_LIVE_FIXTURE'] == null
        ? 'Supply captured operating API response'
        : false,
  );
}
