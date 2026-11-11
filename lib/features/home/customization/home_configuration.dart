import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_providers.dart';

// Stable persisted IDs. Registry metadata/components use this same ordering.
const defaultHomeVisibility = <String, bool>{
  'dday': true,
  'study_summary': true,
  'school_meals': true,
  'materials_search': true,
  'recent_documents': true,
  'recent_updates': true,
  'school_ranking': false,
  'essay_lab': false,
  'university_news': false,
};

class HomeCardChoice {
  const HomeCardChoice(this.id, this.visible);
  final String id;
  final bool visible;
}

class HomeConfiguration {
  HomeConfiguration(Iterable<HomeCardChoice> cards)
    : cards = List.unmodifiable(cards);
  final List<HomeCardChoice> cards;
  factory HomeConfiguration.defaults() => HomeConfiguration(
    defaultHomeVisibility.entries.map((e) => HomeCardChoice(e.key, e.value)),
  );
  factory HomeConfiguration.fromJson(Object? raw) {
    if (raw is! Map || raw['config_version'] != 1 || raw['cards'] is! List) {
      throw const FormatException('Unsupported home configuration');
    }
    final rows = <(String, bool, int, int)>[];
    var index = 0;
    for (final row in raw['cards'] as List) {
      if (row is! Map || row['card_id'] is! String || row['visible'] is! bool) {
        throw const FormatException('Invalid card');
      }
      rows.add((
        row['card_id'] as String,
        row['visible'] as bool,
        row['display_order'] is int ? row['display_order'] as int : index,
        index++,
      ));
    }
    rows.sort((a, b) {
      final c = a.$3.compareTo(b.$3);
      return c != 0 ? c : a.$4.compareTo(b.$4);
    });
    final seen = <String>{};
    final cards = <HomeCardChoice>[];
    for (final row in rows) {
      if (seen.add(row.$1)) cards.add(HomeCardChoice(row.$1, row.$2));
    }
    // A newly introduced card never overrides an explicit existing configuration.
    for (final id in defaultHomeVisibility.keys) {
      if (seen.add(id)) cards.add(HomeCardChoice(id, false));
    }
    return HomeConfiguration(cards);
  }
  Map<String, dynamic> toJson() => {
    'config_version': 1,
    'cards': [
      for (var i = 0; i < cards.length; i++)
        {
          'card_id': cards[i].id,
          'visible': cards[i].visible,
          'display_order': i,
        },
    ],
  };
  HomeConfiguration toggle(String id, bool visible) => HomeConfiguration(
    cards.map((c) => c.id == id ? HomeCardChoice(id, visible) : c),
  );
  HomeConfiguration reorder(int from, int to) {
    final next = cards.toList();
    if (to > from) to--;
    next.insert(to, next.removeAt(from));
    return HomeConfiguration(next);
  }
}

class HomeConfigurationState {
  const HomeConfigurationState(
    this.configuration, {
    this.revision = 0,
    this.confirmed = false,
    this.exists = false,
    this.failed = false,
  });
  final HomeConfiguration configuration;
  final int revision;
  final bool confirmed, exists, failed;
}

typedef HomeRpc = Future<Object?> Function(String, Map<String, dynamic>);

abstract class HomeCache {
  Future<String?> read(String owner);
  Future<void> write(String owner, String value);
}

class DeviceHomeCache implements HomeCache {
  // Initialize inside guarded IO, not while a provider/widget is building.
  SharedPreferencesAsync? _instance;
  SharedPreferencesAsync get _prefs => _instance ??= SharedPreferencesAsync();
  @override
  Future<String?> read(String owner) => _prefs.getString('home.v1.$owner');
  @override
  Future<void> write(String owner, String value) =>
      _prefs.setString('home.v1.$owner', value);
}

class HomeConfigurationRepository {
  HomeConfigurationRepository({
    required this.owner,
    required this.currentOwner,
    required this.cache,
    this.rpc,
  });
  final String? owner;
  final String? Function() currentOwner;
  final HomeCache cache;
  final HomeRpc? rpc;
  void checkOwner() {
    if (currentOwner() != owner) throw StateError('Account changed');
  }

  HomeConfigurationState decode(Object? raw, {required bool confirmed}) {
    if (raw == null) {
      return HomeConfigurationState(
        HomeConfiguration.defaults(),
        confirmed: confirmed,
      );
    }
    if (raw is! Map ||
        raw['revision'] is! int ||
        (raw['revision'] as int) < 1) {
      throw const FormatException('Invalid revision');
    }
    return HomeConfigurationState(
      HomeConfiguration.fromJson(raw),
      revision: raw['revision'] as int,
      exists: true,
      confirmed: confirmed,
    );
  }

  Stream<HomeConfigurationState> load() async* {
    checkOwner();
    try {
      final local = await cache.read(owner ?? 'guest');
      checkOwner();
      if (local != null) {
        yield decode(jsonDecode(local), confirmed: owner == null);
      } else if (owner == null) {
        yield decode(null, confirmed: true);
      }
    } catch (_) {
      checkOwner();
      if (owner == null) yield decode(null, confirmed: true);
    }
    if (owner == null) return;
    try {
      if (rpc == null) throw StateError('Unavailable');
      final raw = await rpc!(
        'my_home_configuration',
        {},
      ).timeout(const Duration(seconds: 8));
      checkOwner();
      final result = decode(raw, confirmed: true);
      try {
        await cache.write(owner!, jsonEncode(raw));
      } catch (_) {
        /* Cache is not authoritative. */
      }
      checkOwner();
      yield result;
    } catch (_) {
      checkOwner();
      // Read failures cannot authorize a write or turn cache into confirmed data.
      yield HomeConfigurationState(HomeConfiguration.defaults(), failed: true);
    }
  }

  Future<HomeConfigurationState> save(
    HomeConfiguration config,
    int revision,
  ) async {
    checkOwner();
    Object? raw;
    if (owner == null) {
      raw = {...config.toJson(), 'revision': revision + 1};
      await cache.write('guest', jsonEncode(raw));
    } else {
      if (rpc == null) throw StateError('Unavailable');
      raw = await rpc!('save_my_home_configuration', {
        'p_config': config.toJson(),
        'p_revision': revision,
      });
      checkOwner();
    }
    final result = decode(raw, confirmed: true);
    if (!result.exists ||
        jsonEncode(result.configuration.toJson()) !=
            jsonEncode(HomeConfiguration.fromJson(config.toJson()).toJson())) {
      throw StateError('Save was not confirmed');
    }
    if (owner != null) {
      try {
        await cache.write(owner!, jsonEncode(raw));
      } catch (_) {
        /* Saved on server. */
      }
    }
    checkOwner();
    return result;
  }
}

final homeCacheProvider = Provider<HomeCache>((ref) => DeviceHomeCache());
final homeConfigurationRepositoryProvider =
    Provider<HomeConfigurationRepository?>((ref) {
      final auth = ref.watch(
        authStateProvider.select(
          (value) =>
              (value.isLoading, value.hasError, value.asData?.value.userId),
        ),
      );
      if (auth.$1 || auth.$2) return null;
      final owner = auth.$3;
      final client = ref.watch(supabaseClientProvider);
      return HomeConfigurationRepository(
        owner: owner,
        currentOwner: () {
          final current = ref.read(authStateProvider);
          if (current.isLoading || current.hasError) return '\$auth-pending';
          return current.asData?.value.userId;
        },
        cache: ref.watch(homeCacheProvider),
        rpc: client == null
            ? null
            : (name, params) async => client.rpc(name, params: params),
      );
    });
final homeConfigurationProvider =
    StreamProvider.autoDispose<HomeConfigurationState>((ref) async* {
      // Auth is the invalidation source. Defer repository construction until after
      // the frame; a paused Home route can resume during TickerMode's build phase.
      ref.watch(
        authStateProvider.select(
          (value) =>
              (value.isLoading, value.hasError, value.asData?.value.userId),
        ),
      );
      await Future<void>.value();
      if (!ref.mounted) return;
      final repo = ref.read(homeConfigurationRepositoryProvider);
      if (repo == null) {
        yield HomeConfigurationState(HomeConfiguration.defaults());
      } else {
        yield* repo.load();
      }
    }, retry: (_, _) => null);
