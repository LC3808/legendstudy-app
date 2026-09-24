import 'package:flutter/material.dart';

import '../application/study_controller.dart';
import '../domain/study_models.dart';

class FreePracticeResults extends StatelessWidget {
  const FreePracticeResults({super.key, required this.study});
  final StudyController study;
  Future<void> edit(BuildContext context, Map<String, dynamic> row) =>
      showDialog<void>(
        context: context,
        builder: (_) => _PracticeScoreDialog(study: study, row: row),
      );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: study,
    builder: (context, _) {
      final rows = study.freePractices.reversed.toList();
      if (rows.isEmpty) return const SizedBox.shrink();
      return ExpansionTile(
        title: const Text('자유 연습 기록'),
        children: [
          for (final row in rows)
            ListTile(
              title: Text(row['title'] as String? ?? '자유 연습'),
              subtitle: Text(
                '${studyDuration(StudyRecord.fromJson(row).activeMs)} · '
                '${row['manual_score'] == null ? '점수 입력' : '직접 입력 ${row['manual_score']}점'}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => edit(context, row),
            ),
        ],
      );
    },
  );
}

class _PracticeScoreDialog extends StatefulWidget {
  const _PracticeScoreDialog({required this.study, required this.row});
  final StudyController study;
  final Map<String, dynamic> row;
  @override
  State<_PracticeScoreDialog> createState() => _PracticeScoreDialogState();
}

class _PracticeScoreDialogState extends State<_PracticeScoreDialog> {
  late final input = TextEditingController(
    text: widget.row['manual_score']?.toString() ?? '',
  );
  late final generation = widget.study.viewGeneration;
  bool saving = false, closing = false;
  String? error;
  @override
  void initState() {
    super.initState();
    widget.study.addListener(ownerChanged);
  }

  void ownerChanged() {
    if (!mounted || generation == widget.study.viewGeneration || closing) {
      return;
    }
    setState(() => closing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).removeRoute(ModalRoute.of(context)!);
    });
  }

  @override
  void dispose() {
    widget.study.removeListener(ownerChanged);
    input.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || closing) return;
    final value = double.tryParse(input.text.trim());
    if (value == null || !value.isFinite || value < 0 || value > 1000) {
      setState(() => error = '0~1000 사이 점수를 입력해 주세요.');
      return;
    }
    setState(() => saving = true);
    final success = await widget.study.savePracticeScore(
      widget.row['id'] as String,
      value,
    );
    if (!mounted || closing) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error = '저장하지 못했어요. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => closing
      ? const SizedBox.shrink()
      : AlertDialog(
          title: const Text('자유 연습 점수'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('직접 입력한 점수는 공식 성적 분석에 포함되지 않아요.'),
                TextField(
                  controller: input,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '점수 (0~1000)',
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: saving ? null : save,
              child: const Text('저장'),
            ),
          ],
        );
}
