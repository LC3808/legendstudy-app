// The canonical admissions-lifecycle bucket. `student` uses grade_level 1..3;
// `retaker` (N수·검정고시 등) and `other` carry no grade.
const academicStatusValues = {'student', 'retaker', 'other'};

class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.gradeLevel,
    this.neisOfficeCode,
    this.neisSchoolCode,
    this.academicStatus,
    this.onboardingCompletedAt,
  });
  final String id;
  final String? displayName;
  final int? gradeLevel;
  final String? neisOfficeCode, neisSchoolCode;
  final String? academicStatus;
  // Set once, on onboarding finish OR skip. Null means the first-login
  // personalization flow has not been completed for this user.
  final DateTime? onboardingCompletedAt;
  bool get hasCompletedOnboarding => onboardingCompletedAt != null;
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    gradeLevel: json['grade_level'] as int?,
    neisOfficeCode: json['neis_office_code'] as String?,
    neisSchoolCode: json['neis_school_code'] as String?,
    academicStatus: json['academic_status'] as String?,
    onboardingCompletedAt: json['onboarding_completed_at'] == null
        ? null
        : DateTime.parse(json['onboarding_completed_at'] as String),
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
