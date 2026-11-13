import 'package:flutter_test/flutter_test.dart';
import '../lib/features/home/university_news/catalog_news.dart';
void main() {
 Map<String,dynamic> university(String id)=>{'universityId':id,'sourceUniversityId':id,'name':id,'offerings':<dynamic>[]};
 test('applications first, deduplicated, other account excluded',(){
  final news=CatalogNews.parse({'version':'university-news-catalog-v1','universities':[university('a'),university('b'),university('c')]});
  expect(news.select({'b'},{'a','b'}).map((u)=>u['universityId']),['b','a']);
  expect(news.select({'b'},{'b'}).single['isApplication'],true);
  expect(news.select({'c'},{}).single['universityId'],'c');
  expect(news.select({},{}),isEmpty);
 });
 test('malformed response is error, not empty schedules',(){expect(()=>CatalogNews.parse({}),throwsFormatException);});
 test('duplicate UUID rejected',(){expect(()=>CatalogNews.parse({'version':'university-news-catalog-v1','universities':[university('a'),university('a')]}),throwsFormatException);});
 test('unknown identity is never guessed from names',(){final u=university('a')..['universityId']=null;final n=CatalogNews.parse({'version':'university-news-catalog-v1','universities':[u]});expect(n.select({'a'},{}),isEmpty);});
}
