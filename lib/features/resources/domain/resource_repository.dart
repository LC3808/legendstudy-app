import 'content_resource.dart';

abstract interface class ResourceRepository {
  Future<List<ContentResource>> fetchForContent(String contentItemId);
}
