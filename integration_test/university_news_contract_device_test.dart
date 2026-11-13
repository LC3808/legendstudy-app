import 'package:integration_test/integration_test.dart';

import '../test/task04_account_switch_test.dart' as account;
import '../test/university_news_test.dart' as news;
import '../test/catalog_news_test.dart' as catalog;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  account.main();
  news.main();
  catalog.main();
}
