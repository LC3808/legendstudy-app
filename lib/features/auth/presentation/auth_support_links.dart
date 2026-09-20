import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/links/external_link.dart';
import '../../resources/domain/content_resource.dart';

/// No identity lookup: only the existing Guest-accessible support route.
class AuthSupportLinks extends ConsumerWidget {
  const AuthSupportLinks({required this.enabled, super.key});
  final bool enabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: !enabled
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  final contact = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      scrollable: true,
                      title: const Text('가입한 이메일을 잊으셨나요?'),
                      content: const Text(
                        'Google·Apple·Kakao로 가입했다면 가입할 때 사용한 계정과 로그인 방식을 확인해 주세요.\n\n이메일 계정이 기억나지 않으면 문의를 남겨 주세요. 비밀번호나 인증 코드는 보내지 마세요.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('닫기'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('문의하기'),
                        ),
                      ],
                    ),
                  );
                  if (contact == true && context.mounted) {
                    context.push('/auth/support');
                  }
                },
          child: const Text('가입한 이메일을 잊으셨나요?'),
        ),
        // Match MY: only configured, safe web targets become links.
        for (final entry in {
          '개인정보처리방침': config.privacyUrl,
          '이용약관': config.termsUrl,
        }.entries)
          if (publicWebUri(entry.value) case final uri?)
            ExternalLinkButton(uri: enabled ? uri : null, label: entry.key),
      ],
    );
  }
}
