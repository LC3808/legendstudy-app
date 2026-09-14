import 'package:flutter/material.dart';

class PauseResumeButton extends StatelessWidget {
  const PauseResumeButton({
    super.key,
    required this.running,
    required this.onPressed,
  });
  final bool running;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => running
      ? OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.pause),
          label: const Text('일시정지'),
        )
      : FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.play_arrow),
          label: const Text('계속하기'),
        );
}
