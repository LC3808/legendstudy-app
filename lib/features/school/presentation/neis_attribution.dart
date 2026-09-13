import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NeisAttribution extends StatelessWidget {
  const NeisAttribution({this.label = '출처: NEIS', super.key});
  final String label;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: AppTokens.textSecondary,
      textStyle: Theme.of(context).textTheme.labelMedium,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정보 출처'),
        content: const Text('학교·급식 정보는 교육부 및 시·도교육청의 NEIS 데이터를 이용합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    ),
    child: Text(label, textAlign: TextAlign.end),
  );
}
