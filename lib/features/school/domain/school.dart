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
  final List<Meal> secondary;
  final bool primaryIsTomorrow;

  bool get isEmpty => primary.isEmpty && secondary.isEmpty;
  bool get canExpand => secondary.isNotEmpty;
}

MealDisplayPlan mealDisplayPlan({
  required DateTime now,
  required List<Meal> today,
  required List<Meal> tomorrow,
}) {
  final afterDinner = koreanLocalTime(now).hour >= 17;
  final dinner = today.where((meal) => meal.mealType == '석식').toList();

  if (!afterDinner) {
    if (today.isNotEmpty) {
      return MealDisplayPlan(
        primary: today,
        secondary: tomorrow,
        primaryIsTomorrow: false,
      );
    }
    return MealDisplayPlan(
      primary: tomorrow,
      secondary: const [],
      primaryIsTomorrow: tomorrow.isNotEmpty,
    );
  }

  if (dinner.isNotEmpty) {
    return MealDisplayPlan(
      primary: dinner,
      secondary: tomorrow,
      primaryIsTomorrow: false,
    );
  }
  return MealDisplayPlan(
    primary: tomorrow,
    secondary: const [],
    primaryIsTomorrow: tomorrow.isNotEmpty,
  );
}
