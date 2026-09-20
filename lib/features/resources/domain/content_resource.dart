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
  'listening_audio': '영어 듣기',
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
  // Without a parent there is no original-post fallback.
  Uri? get openUri => resolveResourceDelivery(this, '').uri;
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

/// Delivery is navigation metadata, not a rights or live availability verdict.
enum ResourceDeliveryKind {
  externalFile,
  externalPage,
  sourcePage,
  unavailable,
}

class ResourceDelivery {
  const ResourceDelivery({
    required this.kind,
    required this.uri,
    required this.label,
    required this.description,
    this.sourceFallback,
  });
  final ResourceDeliveryKind kind;
  final Uri? uri, sourceFallback;
  final String label, description;
}

// Public grants omit link_status/last_checked_at and have no auth/expiry fields.
// Fail closed on identifiable transient/auth URLs; do not parse token values,
// infer binary format from a suffix, probe remote files, or invent officialness.
Uri? _pageTarget(String value) {
  final uri = publicWebUri(value);
  if (uri == null) return null;
  try {
    final authPath = uri.pathSegments.any(
      (segment) => const {
        'login',
        'signin',
        'sign-in',
        'oauth',
        'authorize',
        'auth',
      }.contains(segment.toLowerCase()),
    );
    final transient = uri.queryParameters.keys.any((key) {
      final name = key.toLowerCase();
      return name.startsWith('x-amz-') ||
          name.startsWith('x-goog-') ||
          const {
            'token',
            'access_token',
            'refresh_token',
            'auth',
            'authorization',
            'signature',
            'sig',
            'expires',
            'expiry',
            'policy',
            'key-pair-id',
            'awsaccesskeyid',
            'credential',
          }.contains(name);
    });
    if (authPath || transient || uri.hasFragment) return null;
  } on FormatException {
    return null;
  }
  return uri;
}

ResourceDelivery resolveResourceDelivery(
  ContentResource resource,
  String contentSourceUrl,
) {
  final source = _pageTarget(contentSourceUrl);
  final purpose = resourceTypeLabels[resource.resourceType] ?? '자료';
  Uri? target;
  ResourceDeliveryKind? kind;
  if (resource.linkKind == 'file') {
    final candidate = _pageTarget(resource.fileUrl ?? '');
    // Query-bearing file links cannot be verified as durable with today's API.
    if (candidate != null && !candidate.hasQuery) {
      target = candidate;
      kind = ResourceDeliveryKind.externalFile;
    }
  } else if (resource.linkKind == 'landing_page') {
    target = _pageTarget(resource.sourceUrl);
    if (target != null) kind = ResourceDeliveryKind.externalPage;
  }
  if (target != null) {
    return ResourceDelivery(
      kind: kind!,
      uri: target,
      label: kind == ResourceDeliveryKind.externalFile
          ? '$purpose 보기'
          : '$purpose 자료 페이지 보기',
      description: kind == ResourceDeliveryKind.externalFile
          ? '외부 앱에서 자료 링크를 엽니다. 열리지 않으면 원문에서 찾아 주세요.'
          : '외부 자료 페이지에서 확인하세요.',
      sourceFallback: source == target ? null : source,
    );
  }
  if (source != null) {
    return ResourceDelivery(
      kind: ResourceDeliveryKind.sourcePage,
      uri: source,
      label: '원문에서 보기',
      description: '직접 열 수 있는 자료 링크를 확인할 수 없어 원본 게시글로 이동해요.',
    );
  }
  return const ResourceDelivery(
    kind: ResourceDeliveryKind.unavailable,
    uri: null,
    label: '열 수 있는 링크가 없어요.',
    description: '현재 이 자료에 사용할 수 있는 링크가 없어요.',
  );
}

// Compatibility for existing callers; all decisions live in the resolver above.
Uri? resolveResourceOpenUri(
  ContentResource resource,
  String contentSourceUrl,
) => resolveResourceDelivery(resource, contentSourceUrl).uri;
