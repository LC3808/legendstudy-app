import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../feedback_providers.dart';
import '../domain/feedback_models.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});
  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.inquiry;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() {});
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final platform = kIsWeb
        ? 'web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.iOS => 'ios',
            TargetPlatform.android => 'android',
            _ => defaultTargetPlatform.name,
          };
    try {
      await ref
          .read(feedbackRepositoryProvider)
          .submit(
            FeedbackDraft(
              category: _category,
              title: title,
              body: body,
              appVersion: '0.1.0',
              buildNumber: '1',
              platform: platform,
              osVersion: kIsWeb ? 'web' : Platform.operatingSystemVersion,
              locale: Localizations.localeOf(context).toLanguageTag(),
            ),
          );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('문의가 접수되었습니다.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is BackendUnavailable
                  ? error.message
                  : '문의가 접수되지 않았어요. 잠시 후 다시 시도해 주세요.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ShellPage(
    children: [
      const SectionHeader('문의·건의사항'),
      const Text('비밀번호, 주민등록번호 등 민감한 개인정보는 입력하지 마세요.'),
      const SizedBox(height: 16),
      DropdownButtonFormField<FeedbackCategory>(
        initialValue: _category,
        decoration: const InputDecoration(labelText: '유형'),
        items: [
          for (final category in FeedbackCategory.values)
            DropdownMenuItem(value: category, child: Text(category.label)),
        ],
        onChanged: _submitting
            ? null
            : (value) => setState(() => _category = value!),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _title,
        maxLength: 120,
        decoration: InputDecoration(
          labelText: '제목',
          errorText: _title.text.trim().isEmpty && _submitting
              ? '제목을 입력해 주세요.'
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      TextField(
        controller: _body,
        maxLength: 5000,
        minLines: 6,
        maxLines: 12,
        decoration: InputDecoration(
          labelText: '내용',
          alignLabelWithHint: true,
          errorText: _body.text.trim().isEmpty && _submitting
              ? '내용을 입력해 주세요.'
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send_outlined),
        label: const Text('문의 접수'),
      ),
    ],
  );
}
