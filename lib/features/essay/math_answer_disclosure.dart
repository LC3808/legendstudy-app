import 'package:flutter/material.dart';

/// Generated prose may contain complete answers in any field. Default closed.
class MathAnswerDisclosure extends StatefulWidget {
  const MathAnswerDisclosure({required this.child, super.key});
  final Widget child;
  @override
  State<MathAnswerDisclosure> createState() => _MathAnswerDisclosureState();
}
class _MathAnswerDisclosureState extends State<MathAnswerDisclosure> {
  bool requested = false;
  @override
  Widget build(BuildContext context) => requested ? widget.child : Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('상세 평가에는 정답 수치·최종 수식·참고 풀이가 포함될 수 있습니다. 먼저 직접 수정해 보세요.'),
      OutlinedButton(onPressed: () => setState(() => requested = true), child: const Text('정답 포함 상세 평가 공개')),
    ],
  );
}
