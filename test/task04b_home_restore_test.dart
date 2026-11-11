import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';

import 'support/home_test_support.dart';

void main() {
  test('fresh cache and repository restore signed-in selection after account changes', () async {
    String? owner = 'a';
    final remote = <String, Map<String, dynamic>>{};
    var reads = 0;
    var writes = 0;
    var cache = MemoryHomeCache();
    HomeConfigurationRepository repository() {
      final capturedOwner = owner;
      return HomeConfigurationRepository(
        owner: capturedOwner,
        currentOwner: () => owner,
        cache: cache,
        rpc: (name, params) async {
          if (name == 'my_home_configuration') {
            reads++;
            return remote[capturedOwner];
          }
          writes++;
          return remote[capturedOwner!] = {
            ...params['p_config'] as Map<String, dynamic>,
            'revision': (params['p_revision'] as int) + 1,
          };
        },
      );
    }

    final selected = HomeConfiguration.defaults()
        .toggle('dday', false)
        .toggle('university_news', true)
        .reorder(8, 0);
    await repository().save(selected, 0);
    // A new process/device has no cached configuration. Server data is authoritative.
    cache = MemoryHomeCache();
    final restored = await repository().load().last;
    expect(restored.confirmed, true);
    expect(restored.configuration.toJson(), selected.toJson());
    expect(restored.revision, 1);

    owner = null;
    final guest = await repository().load().last;
    expect(guest.configuration.toJson(), HomeConfiguration.defaults().toJson());
    owner = 'b';
    final other = await repository().load().last;
    expect(other.exists, false);
    expect(other.configuration.toJson(), HomeConfiguration.defaults().toJson());
    owner = 'a';
    final relogged = await repository().load().last;
    expect(relogged.configuration.toJson(), selected.toJson());
    expect(reads, 3);
    expect(writes, 1);
    expect(remote.keys, ['a']);
  });
}
