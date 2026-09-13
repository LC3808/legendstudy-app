Uri? publicWebUri(String? value) {
  if (value == null ||
      value.trim().isEmpty ||
      RegExp(r'[\x00-\x20]').hasMatch(value)) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

const resourceTypeLabels = {
  'question': '문제',
  'answer': '정답',
  'explanation': '해설',
  'answer_explanation': '정답·해설',
  'listening_audio': '듣기',
  'listening_script': '듣기 대본',
  'grade_cut': '등급컷',
  'reference': '참고자료',
  'other': '기타',
};

class ContentResource {
  const ContentResource({
    required this.id,
    required this.contentItemId,
    required this.resourceType,
    required this.title,
    required this.sourceUrl,
    required this.linkKind,
    this.examSubjectId,
    this.sourceLabel,
    this.fileUrl,
    this.mimeType,
    this.fileExtension,
    this.fileSize,
    this.displayOrder = 0,
    this.groupLabel = '일반 자료',
  });
  final String id,
      contentItemId,
      resourceType,
      title,
      sourceUrl,
      linkKind,
      groupLabel;
  final String? examSubjectId, sourceLabel, fileUrl, mimeType, fileExtension;
  final int? fileSize;
  final int displayOrder;
  String get displayTitle => title.trim().isNotEmpty
      ? title
      : sourceLabel?.trim().isNotEmpty == true
      ? sourceLabel!
      : resourceTypeLabels[resourceType] ?? '기타';
  // file_url is populated only from verified file evidence by the ingestion contract.
  // Link health is NOT exposed by the public grant; no availability claim is made.
  Uri? get openUri => linkKind == 'landing_page'
      ? publicWebUri(sourceUrl)
      : publicWebUri(fileUrl) ?? publicWebUri(sourceUrl);
  factory ContentResource.fromJson(Map<String, dynamic> json) {
    final occurrence = json['occurrence'] as Map<String, dynamic>?;
    final subject = occurrence?['subject'] as Map<String, dynamic>?;
    final mapped = subject?['is_active'] == true
        ? (subject?['name'] as String?)
        : null;
    final raw = occurrence?['raw_subject_label'] as String?;
    final label = mapped?.trim().isNotEmpty == true
        ? mapped!
        : raw?.trim().isNotEmpty == true
        ? raw!
        : '일반 자료';
    return ContentResource(
      id: json['id'] as String,
      contentItemId: json['content_item_id'] as String,
      examSubjectId: json['exam_subject_id'] as String?,
      resourceType: json['resource_type'] as String,
      title: json['title'] as String,
      sourceLabel: json['source_label'] as String?,
      sourceUrl: json['source_url'] as String,
      linkKind: json['link_kind'] as String,
      fileUrl: json['file_url'] as String?,
      mimeType: json['mime_type'] as String?,
      fileExtension: json['file_extension'] as String?,
      fileSize: json['file_size'] as int?,
      displayOrder: json['display_order'] as int,
      groupLabel: label,
    );
  }
}
