/// First-run personalization — interested universities.
///
/// IMPORTANT semantics: these are **관심 대학 (interest)**, not application
/// records. They are stored in `student_target_universities` with
/// `status = 'interested'` and are deliberately distinct from any future
/// `지원 예정 대학` ('planned') or actual-application model. Nothing here is an
/// application history entry.

/// A row from the public `universities` catalog (search result).
class University {
  const University({required this.id, required this.name, this.slug});
  final String id;
  final String name;
  final String? slug;

  factory University.fromJson(Map<String, dynamic> json) => University(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    slug: json['slug'] as String?,
  );
}

/// A user's interested-university selection (a `student_target_universities`
/// row with `status='interested'`), joined to its catalog entry.
class InterestedUniversity {
  const InterestedUniversity({
    required this.id,
    required this.universityId,
    required this.name,
    this.slug,
    this.priority,
  });

  /// `student_target_universities.id` (the selection row, not the catalog id).
  final String id;
  final String universityId;
  final String name;
  final String? slug;
  final int? priority;

  factory InterestedUniversity.fromJson(Map<String, dynamic> json) {
    final uni = json['universities'];
    final embedded = uni is Map ? uni.cast<String, dynamic>() : const {};
    return InterestedUniversity(
      id: json['id'] as String,
      universityId: json['university_id'] as String,
      name: (embedded['name'] as String?) ?? '',
      slug: embedded['slug'] as String?,
      priority: (json['priority'] as num?)?.toInt(),
    );
  }

  University get university =>
      University(id: universityId, name: name, slug: slug);
}

/// Interest selection policy (authority: AI_CONTEXT §15 / handoff). 1–5 with ~3
/// recommended; the UI caps at [maxInterested].
const int minInterested = 1;
const int maxInterested = 5;
const int recommendedInterested = 3;
