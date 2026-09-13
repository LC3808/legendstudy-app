class ContentItem {
  const ContentItem({
    required this.id,
    required this.slug,
    required this.contentType,
    required this.title,
    required this.sourceUrl,
    required this.isActive,
    this.summary,
    this.publishedAt,
    this.sourceUpdatedAt,
    this.feedUpdatedAt,
    this.thumbnailUrl,
  });
  final String id, slug, contentType, title, sourceUrl;
  final String? summary, thumbnailUrl;
  final DateTime? publishedAt, sourceUpdatedAt, feedUpdatedAt;
  final bool isActive;
  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'] as String,
    slug: json['slug'] as String,
    contentType: json['content_type'] as String,
    title: json['title'] as String,
    sourceUrl: json['source_url'] as String,
    isActive: json['is_active'] as bool,
    summary: json['summary'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
    publishedAt: _date(json['published_at']),
    sourceUpdatedAt: _date(json['source_updated_at']),
    feedUpdatedAt: _date(json['feed_updated_at']),
  );
  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);
}
