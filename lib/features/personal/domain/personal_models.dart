class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.gradeLevel,
    this.neisOfficeCode,
    this.neisSchoolCode,
  });
  final String id;
  final String? displayName;
  final int? gradeLevel;
  final String? neisOfficeCode, neisSchoolCode;
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    gradeLevel: json['grade_level'] as int?,
    neisOfficeCode: json['neis_office_code'] as String?,
    neisSchoolCode: json['neis_school_code'] as String?,
  );
}

class PersonalContentEntry {
  const PersonalContentEntry({
    required this.id,
    required this.contentItemId,
    required this.timestamp,
  });
  final String id, contentItemId;
  final DateTime timestamp;
  factory PersonalContentEntry.fromJson(
    Map<String, dynamic> json,
    String clock,
  ) => PersonalContentEntry(
    id: json['id'] as String,
    contentItemId: json['content_item_id'] as String,
    timestamp: DateTime.parse(json[clock] as String),
  );
}
