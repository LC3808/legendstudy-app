import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../domain/school.dart';

class SchoolServiceException implements Exception {
  const SchoolServiceException();
}

/// NEIS key remains server-side. Only the dedicated project's bounded proxy is used.
class NeisSchoolRepository implements SchoolRepository {
  NeisSchoolRepository(this.client, this.config);
  final http.Client client;
  final AppConfig config;

  Future<List<Map<String, dynamic>>> _rows(Map<String, String> query) async {
    if (config.validationErrors.isNotEmpty) {
      throw const SchoolServiceException();
    }
    try {
      final uri = Uri.parse(
        '${config.supabaseUrl.replaceAll(RegExp(r'/+$'), '')}/functions/v1/neis',
      ).replace(queryParameters: query);
      final response = await client
          .get(uri, headers: {'apikey': config.supabasePublishableKey})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw const SchoolServiceException();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['rows'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // Never expose transport URLs, headers, credentials or upstream errors to UI.
      throw const SchoolServiceException();
    }
  }

  School _school(Map<String, dynamic> row) => School(
    officeCode: row['ATPT_OFCDC_SC_CODE'] as String,
    schoolCode: row['SD_SCHUL_CODE'] as String,
    name: row['SCHUL_NM'] as String,
    schoolType: row['SCHUL_KND_SC_NM'] as String? ?? '',
    address: row['ORG_RDNMA'] as String? ?? '',
  );

  @override
  Future<List<School>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    if (q.length > 100) throw const FormatException('Search is too long.');
    return (await _rows({'action': 'search', 'q': q})).map(_school).toList();
  }

  @override
  Future<School?> find(String officeCode, String schoolCode) async {
    final rows = await _rows({
      'action': 'school',
      'office': officeCode,
      'school': schoolCode,
    });
    final matches = rows
        .map(_school)
        .where((s) => s.officeCode == officeCode && s.schoolCode == schoolCode);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<Meal>> meals(School school, String date) async {
    final rows = await _rows({
      'action': 'meals',
      'office': school.officeCode,
      'school': school.schoolCode,
      'date': date,
    });
    return rows
        .where(
          (r) =>
              r['ATPT_OFCDC_SC_CODE'] == school.officeCode &&
              r['SD_SCHUL_CODE'] == school.schoolCode &&
              r['MLSV_YMD'] == date,
        )
        .map(
          (row) => Meal(
            date: row['MLSV_YMD'] as String,
            mealType: row['MMEAL_SC_NM'] as String,
            menuItems: (row['DDISH_NM'] as String)
                .split(RegExp(r'<br\s*/?>|[\r\n]+', caseSensitive: false))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }
}
