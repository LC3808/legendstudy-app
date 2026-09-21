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

String koreanDateOffset(DateTime instant, int days) {
  final day = instant.toUtc().add(const Duration(hours: 9));
  final shifted = day.add(Duration(days: days));
  return '${shifted.year}${shifted.month.toString().padLeft(2, '0')}${shifted.day.toString().padLeft(2, '0')}';
}

DateTime koreanLocalTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 9));

class MealDisplayPlan {
  const MealDisplayPlan({
    required this.primary,
    required this.secondary,
    required this.primaryIsTomorrow,
  });
  final List<Meal> primary;
  // Full raw meals for the selected date, including breakfast, for detail only.
  final List<Meal> secondary;
  final bool primaryIsTomorrow;
  bool get isEmpty => primary.isEmpty;
  bool get canExpand => secondary.isNotEmpty;
}

MealDisplayPlan mealDisplayPlan({
  required DateTime now,
  required List<Meal> today,
  required List<Meal> tomorrow,
}) {
  final hour = koreanLocalTime(now).hour;
  Meal? first(List<Meal> meals, String type) =>
      meals.where((m) => m.mealType == type).firstOrNull;
  final current = hour < 14
      ? first(today, '중식')
      : hour < 19
      ? first(today, '석식')
      : null;
  if (current != null) {
    return MealDisplayPlan(
      primary: [current],
      secondary: today,
      primaryIsTomorrow: false,
    );
  }
  final next = first(tomorrow, '중식') ?? first(tomorrow, '석식');
  return MealDisplayPlan(
    primary: next == null ? [] : [next],
    secondary: tomorrow,
    primaryIsTomorrow: true,
  );
}

// UTC instant for the next meaningful Korean-local policy/date boundary.
DateTime nextMealBoundary(DateTime now) {
  final kst = koreanLocalTime(now);
  final hour = kst.hour < 14
      ? 14
      : kst.hour < 19
      ? 19
      : 24;
  return DateTime.utc(
    kst.year,
    kst.month,
    kst.day,
    hour,
  ).subtract(const Duration(hours: 9));
}
