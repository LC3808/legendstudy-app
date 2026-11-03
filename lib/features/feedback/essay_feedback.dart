import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/config/app_information.dart';

const essayFeedbackEnabled = bool.fromEnvironment('ESSAY_FEEDBACK_V1_ENABLED');
const qualityCategories = <String, String>{
  'helpful': '첨삭 내용이 도움이 되었어요',
  'inaccurate': '첨삭 내용이 부정확해요',
  'rubric': '평가기준이 잘못 적용된 것 같아요',
  'score': '점수 또는 평가 결과가 이상해요',
  'unclear': '설명이 이해하기 어려워요',
  'function': '기능이 정상적으로 작동하지 않아요',
  'other': '기타 의견',
};
const bugCategories = <String, String>{
  'submission': '답안 제출 오류',
  'ocr': 'OCR 인식 오류',
  'evaluation': '평가 실패',
  'result': '평가 결과 오류',
  'rewrite': '재첨삭 오류',
  'credit': '이용권 오류',
  'display': '화면 표시 오류',
  'other': '기타',
};
const feedbackThanks = '의견을 보내주셔서 감사합니다.\n더 나은 논술 LAB을 만드는 데 활용하겠습니다.';

/// Only canonical exam result references are linked; never send report content.
String? essayFeedbackReference(String? value) =>
    value != null &&
        RegExp(
          r'^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}/[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$',
        ).hasMatch(value)
    ? value
    : null;

class EssayFeedback extends StatelessWidget {
  const EssayFeedback({super.key, this.evaluationRef, this.bugOnly = false});
  final String? evaluationRef;
  final bool bugOnly;
  @override
  Widget build(BuildContext context) => !essayFeedbackEnabled
      ? const SizedBox.shrink()
      : _ConnectedFeedback(
          key: ValueKey(evaluationRef),
          evaluationRef: evaluationRef,
          bugOnly: bugOnly,
        );
}

class _ConnectedFeedback extends ConsumerWidget {
  const _ConnectedFeedback({
    super.key,
    this.evaluationRef,
    required this.bugOnly,
  });
  final String? evaluationRef;
  final bool bugOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.value?.userId;
    if (user == null || auth.isLoading || auth.hasError) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('로그인 후 논술 LAB 의견·오류 신고를 보낼 수 있어요.'),
      );
    }
    return EssayFeedbackForm(
      key: ValueKey('$user/$evaluationRef'),
      bugOnly: bugOnly,
      evaluationRef: evaluationRef,
      submit: (payload) async {
        final client = ref.read(supabaseClientProvider);
        if (client == null || client.auth.currentUser?.id != user) {
          throw StateError('signed out');
        }
        final version = await ref
            .read(appVersionProvider.future)
            .catchError((_) => 'unknown');
        await client.rpc<dynamic>(
          'essay_feedback_submit',
          params: {
            'p': {
              ...payload,
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
              'app_version': version,
            },
          },
        );
      },
    );
  }
}

class EssayFeedbackForm extends StatefulWidget {
  const EssayFeedbackForm({
    super.key,
    required this.submit,
    this.evaluationRef,
    this.bugOnly = false,
  });
  final Future<void> Function(Map<String, dynamic>) submit;
  final String? evaluationRef;
  final bool bugOnly;
  @override
  State<EssayFeedbackForm> createState() => _EssayFeedbackFormState();
}

class _EssayFeedbackFormState extends State<EssayFeedbackForm> {
  final message = TextEditingController();
  late bool bug = widget.bugOnly;
  String? satisfaction, category;
  bool busy = false, sent = false;
  String? error;
  Map<String, dynamic>? pending;
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  void edited() {
    pending = null;
  }

  Future<void> send() async {
    if (busy || sent) return;
    if (bug
        ? category == null || message.text.trim().isEmpty
        : satisfaction == null) {
      setState(() => error = bug ? '오류 유형과 설명을 입력해 주세요.' : '만족도를 선택해 주세요.');
      return;
    }
    final reference = essayFeedbackReference(widget.evaluationRef);
    pending ??= {
      'request_key': const Uuid().v4(),
      'kind': bug ? 'bug' : 'quality',
      if (!bug) 'satisfaction': satisfaction,
      if (category != null) 'category': category,
      'message': message.text.trim(),
      if (reference != null) 'evaluation_ref': reference,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    };
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.submit(pending!);
      if (mounted) setState(() => sent = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = '접수를 확인하지 못했어요. 입력은 보존됩니다. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: sent
        ? const Text(feedbackThanks)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bug ? '논술 LAB 오류 신고' : '이번 첨삭이 도움이 되었나요?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!widget.bugOnly)
                SwitchListTile(
                  title: const Text('오류 신고하기'),
                  value: bug,
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          bug = v;
                          category = null;
                          edited();
                        }),
                ),
              if (!bug)
                Wrap(
                  spacing: 12,
                  children: [
                    for (final entry in {
                      'helpful': '도움이 되었어요',
                      'unhelpful': '아쉬워요',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: satisfaction == entry.key,
                        onSelected: busy
                            ? null
                            : (_) => setState(() {
                                satisfaction = entry.key;
                                edited();
                              }),
                      ),
                  ],
                ),
              DropdownButtonFormField<String>(
                key: ValueKey(bug),
                initialValue: category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: bug ? '오류 유형' : '세부 유형 (선택)',
                ),
                items: [
                  for (final e
                      in (bug ? bugCategories : qualityCategories).entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        category = v;
                        edited();
                      }),
              ),
              TextField(
                controller: message,
                enabled: !busy,
                minLines: 2,
                maxLines: 6,
                maxLength: 5000,
                decoration: InputDecoration(
                  labelText: bug ? '오류 설명' : '첨삭 결과에 대한 의견을 자유롭게 남겨주세요.',
                ),
                onChanged: (_) => edited(),
              ),
              const Text('답안 원문과 민감정보는 자동 첨부하지 않습니다. 비밀번호 등은 입력하지 마세요.'),
              if (error != null) Text(error!),
              FilledButton(
                onPressed: busy ? null : send,
                child: Text(busy ? '보내는 중…' : '제출하기'),
              ),
            ],
          ),
  );
}
