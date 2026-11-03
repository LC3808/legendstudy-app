/// Versioned APP/WEB response. No fallback to raw Provider output.
typedef MathCoachingRequest = Future<Map<String, dynamic>> Function(
  String action,
  Map<String, dynamic> payload,
);
Map<String, dynamic> object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> objects(dynamic value) =>
    value is List ? value.map(object).toList() : [];

class CoachingSnapshot {
  CoachingSnapshot(Map<String, dynamic> data) : data = Map.unmodifiable(data) {
    if (data['version'] != 'math-coaching-v1' ||
        data['evaluation_id'] is! String ||
        data['tasks'] is! List ||
        data['disclosed'] is! bool) {
      throw const FormatException('COACHING_CONTRACT_REQUIRED');
    }
    if (data['disclosed'] != true && data.containsKey('full_solution')) {
      throw const FormatException('PREMATURE_DISCLOSURE');
    }
    if (objects(data['tasks']).length > 5) {
      throw const FormatException('TASK_LIMIT');
    }
  }
  final Map<String, dynamic> data;
  String get id => data['evaluation_id'] as String;
  String get diagnosis =>
      data['diagnosis'] as String? ?? '답안의 풀이 과정과 조건을 확인해 주세요.';
  List<Map<String, dynamic>> get tasks => objects(data['tasks']);
  List<Map<String, dynamic>> get concepts => objects(data['concepts']);
  bool get disclosed => data['disclosed'] == true;
  Map<String, dynamic> get policy => object(data['rewrite_policy']);
  bool get free => policy['eligible'] == true;
  bool get paid => policy['paid_available'] == true;
  String get chargeLabel => free
      ? '무료 재첨삭 1회 남음'
      : paid
      ? '이용권 1개 사용'
      : '이용 가능 여부 확인 필요';
}
