import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Locally bundled official provider symbols; no runtime asset requests.
class ProviderButton extends StatelessWidget {
  const ProviderButton({
    required this.provider,
    required this.onPressed,
    super.key,
  });
  final OAuthProvider provider;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final label =
        '${switch (provider) {
          OAuthProvider.google => 'Google',
          OAuthProvider.apple => 'Apple',
          _ => 'Kakao',
        }}로 계속하기';
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final height = 52 * scale.clamp(1.0, 2.0);
    final apple = provider == OAuthProvider.apple;
    final kakao = provider == OAuthProvider.kakao;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: apple
            ? Colors.black
            : kakao
            ? const Color(0xFFFEE500)
            : Colors.white,
        foregroundColor: apple ? Colors.white : const Color(0xFF1F1F1F),
        side: BorderSide(
          color: kakao ? const Color(0xFFFEE500) : const Color(0xFF747775),
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: apple
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(
                      painter: AppleLogoPainter(color: Colors.white),
                    ),
                  )
                : Image.asset(
                    'assets/auth/${kakao ? 'kakao' : 'google'}.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, textAlign: TextAlign.center)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
