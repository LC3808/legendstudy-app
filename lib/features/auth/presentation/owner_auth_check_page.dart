import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../shared_account_check.dart';

const ownerAuthCheckEnabled =
    kDebugMode && bool.fromEnvironment('OWNER_AUTH_CHECK');

/// Debug-only manual comparison; no identity persisted, printed or echoed.
class OwnerAuthCheckPage extends ConsumerStatefulWidget {
  const OwnerAuthCheckPage({super.key});
  @override
  ConsumerState<OwnerAuthCheckPage> createState() => _OwnerAuthCheckPageState();
}

class _OwnerAuthCheckPageState extends ConsumerState<OwnerAuthCheckPage> {
  final expected = TextEditingController();
  bool busy = false;
  String? outcome;
  @override
  void dispose() {
    expected.dispose();
    super.dispose();
  }

  Future<void> compare() async {
    if (busy || !ownerAuthCheckEnabled) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    final owner = ref.read(authStateProvider).value?.userId;
    final input = expected.text;
    expected.clear();
    setState(() {
      busy = true;
      outcome = null;
    });
    try {
      final match = await verifySharedAccount(client, input);
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(
          () => outcome = match ? 'IDENTITY MATCH' : 'IDENTITY NOT MATCHED',
        );
      }
    } catch (_) {
      if (mounted) setState(() => outcome = '확인 실패: 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ownerAuthCheckEnabled) return const SizedBox.shrink();
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.value?.userId != next.value?.userId) {
        expected.clear();
        setState(() => outcome = null);
      }
    });
    final signedIn =
        ref.watch(authStateProvider).value?.isAuthenticated == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Owner identity check')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(signedIn ? 'Authenticated' : 'Guest'),
            if (!signedIn)
              TextButton(
                onPressed: () => context.push('/auth'),
                child: const Text('로그인'),
              ),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('홈으로'),
            ),
            const Text(
              'LAB 로그인으로 확인한 Dashboard 사용자 ID를 임시 입력합니다. 값은 저장·출력하지 않습니다.',
            ),
            TextField(
              controller: expected,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              enabled: signedIn && !busy,
              decoration: const InputDecoration(labelText: '비교할 ID (검증 후 삭제)'),
            ),
            FilledButton(
              onPressed: signedIn && !busy ? compare : null,
              child: const Text('동일 계정 확인'),
            ),
            if (outcome != null) Text(outcome!),
          ],
        ),
      ),
    );
  }
}
