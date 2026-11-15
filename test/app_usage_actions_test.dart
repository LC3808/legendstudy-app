import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/features/analytics/usage_actions.dart';
import 'package:legendstudy_app/features/analytics/analytics_providers.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'app_usage_tracking_test.dart' show Recording;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;
import 'support/search_fake.dart';
class BrokenAnalytics implements AnalyticsService {
 @override void logEvent(String name,[Map<String,Object?>? params])=>throw StateError('offline');
 @override void setScreen(String name) {}
 @override void setUserId(String? id) {}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 test('menu clicks are explicit finite actions, transport failure is isolated',(){
  final r=Recording();final a=UsageActions(r);a.menuClick(1);a.menuClick(-1);a.feature('user private input');
  expect(r.events.map((e)=>e.name),['menu_click']);
  expect(r.events.single.params,{'menu_id':'materials','schema_version':2});
  expect(()=>UsageActions(BrokenAnalytics()).feature('pdf_view'),returnsNormally);
 });
 test('search logs completion without query text, paging/browse/retry do not duplicate',()async{
  final r=Recording(),repo=FakeSearchRepository();
  final c=ProviderContainer(overrides:[analyticsServiceProvider.overrideWithValue(r),searchRepositoryProvider.overrideWithValue(repo)]);addTearDown(c.dispose);
  final controller=c.read(searchControllerProvider.notifier);
  await controller.search(SearchQuery(''));
  await controller.search(SearchQuery('private@example.test'));
  await controller.retry();await controller.loadMore();
  repo.fail=true;await controller.search(SearchQuery('국어'));
  expect(r.events.map((e)=>e.name),['material_search']);
  expect(r.events.single.params,{'schema_version':2});
 });
 test('timer events follow durable start and completed local record only',()async{
  final r=Recording(),clock=TestClock(),store=TestStore(),repo=TestRepo('A');
  final c=StudyController(clock,store,()=>repo,ticking:false,usageActions:UsageActions(r));addTearDown(c.dispose);
  c.identity(null,resolved:true);await flush(c);
  store.fail=true;await c.start();expect(r.events,isEmpty);
  store.fail=false;await c.start();await c.start();clock.advance(60000);await c.end();await c.end();await c.sync();
  expect(r.events.map((e)=>e.name),['study_timer_start','study_timer_complete']);
  expect(r.events.last.params['duration_ms'],60000);
 });
}
