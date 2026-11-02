import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../math_gateway.dart';
import 'academic_purple.dart';
import 'coaching_contract.dart';
import 'math_coaching_screen.dart';

class MathCoachingPage extends ConsumerStatefulWidget {
  const MathCoachingPage({
    required this.evaluationId,
    this.onRewrite,
    this.sources = const {},
    super.key,
  });
  final String evaluationId;
  final Map<String, Uint8List> sources;
  final Future<void> Function(bool paid)? onRewrite;
  @override
  ConsumerState<MathCoachingPage> createState() => _MathCoachingPageState();
}

class _MathCoachingPageState extends ConsumerState<MathCoachingPage> {
  String? owner;
  Future<CoachingSnapshot>? future;
  final keys = <String, String>{};
  Future<Map<String, dynamic>> request(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final identity = ref.read(authStateProvider).value?.userId;
    if (identity == null || identity != owner) {
      throw StateError('ACCOUNT_CHANGED');
    }
    final gateway = ref.read(mathGatewayProvider(identity));
    if (gateway == null) throw StateError('UNAVAILABLE');
    final result = await gateway.call('math_coaching', action, {
      ...payload,
      if (action == 'reveal' || action == 'hint')
        'client_submission_id': keys.putIfAbsent(
          '$action/${payload['task_id']}/${payload['level']}',
          mathRequestId,
        ),
    });
    if (!mounted || ref.read(authStateProvider).value?.userId != identity) {
      throw StateError('ACCOUNT_CHANGED');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.userId;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인 후 확인할 수 있습니다.')));
    }
    if (owner != user) {
      owner = user;
      keys.clear();
      future = request('read', {
        'evaluation_id': widget.evaluationId,
      }).then(CoachingSnapshot.new);
    }
    return FutureBuilder<CoachingSnapshot>(
      key: ValueKey(user),
      future: future,
      builder: (context, state) {
        if (state.hasData) {
          return MathCoachingScreen(
            key: ValueKey('$owner/${widget.evaluationId}'),
            snapshot: state.data!,
            sources: widget.sources,
            request: request,
            onRewrite:
                widget.onRewrite ??
                (_) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('시험 선택 화면에서 기존 회차의 수정 답안을 열어 주세요.'),
                    ),
                  );
                },
          );
        }
        return MathMobileTheme(
          child: Scaffold(
            appBar: AppBar(title: const Text('수리논술 LAB')),
            body: Center(
              child: state.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '안전한 첨삭 결과를 확인하지 못했습니다. 서버 공개 계약이 준비되면 다시 확인할 수 있습니다.',
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => future = request('read', {
                                'evaluation_id': widget.evaluationId,
                              }).then(CoachingSnapshot.new),
                            ),
                            child: const Text('다시 확인'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
