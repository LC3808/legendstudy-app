class School {
  const School({
    required this.officeCode,
    required this.schoolCode,
    required this.name,
    required this.schoolType,
    required this.address,
  });
  final String officeCode, schoolCode, name, schoolType, address;
  String get identity => '$officeCode/$schoolCode';
}

class Meal {
  const Meal({
    required this.date,
    required this.mealType,
    required this.menuItems,
  });
  final String date, mealType;
  final List<String> menuItems;
}

abstract interface class SchoolRepository {
  Future<List<School>> search(String query);
  Future<School?> find(String officeCode, String schoolCode);
  Future<List<Meal>> meals(School school, String date);
}

String koreanDate(DateTime instant) {
  final day = instant.toUtc().add(const Duration(hours: 9));
  return '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
}
