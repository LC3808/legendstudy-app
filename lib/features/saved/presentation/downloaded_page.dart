import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../resources/data/download_history.dart';

class DownloadedPage extends ConsumerWidget {
  const DownloadedPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(authStateProvider).value?.userId;
    return ShellPage(
      children: [
        const Text(
          '이 기기에서 다운로드한 최근 100개 자료예요. 실제 파일은 파일 앱이나 선택한 저장 위치에서 확인하세요.',
        ),
        if (owner == null)
          const EmptyState('로그인한 상태에서 다운로드한 자료를 확인할 수 있어요.')
        else
          ref
              .watch(downloadedMaterialsProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => ErrorState(
                  message: '다운로드 기록을 불러오지 못했어요.',
                  onRetry: () => ref.invalidate(downloadedMaterialsProvider),
                ),
                data: (rows) => Column(
                  children: [
                    if (rows.isEmpty) const EmptyState('다운로드한 자료가 아직 없어요.'),
                    for (final row in rows)
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: Text(row.filename),
                        subtitle: const Text('자료 페이지 다시 보기'),
                        onTap: () => context.push(
                          '/materials/${Uri.encodeComponent(row.slug)}',
                        ),
                      ),
                    if (rows.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(downloadHistoryProvider)
                                .clear(owner);
                            if (context.mounted) {
                              ref.invalidate(downloadedMaterialsProvider);
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('기록을 지우지 못했어요. 다시 시도해 주세요.'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('목록 지우기 (파일은 유지)'),
                      ),
                  ],
                ),
              ),
      ],
    );
  }
}
