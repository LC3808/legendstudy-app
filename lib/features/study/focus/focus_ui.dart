import 'package:flutter/material.dart';
import 'focus_service.dart';
import 'study_focus_controller.dart';

Future<FocusChoice> chooseStudyFocus(
  BuildContext context,
  FocusCapability capability,
) async {
  final android = capability == FocusCapability.ownedRule;
  return await showDialog<FocusChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(android ? '집중 모드를 사용할까요?' : '집중 모드 안내'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  android
                      ? '공부하는 동안 알림 방해를 줄일 수 있어요. 권한 설정 중에도 타이머는 시작돼요.'
                      : capability == FocusCapability.manualAndroid
                      ? '기기의 빠른 설정에서 방해 금지를 직접 선택해 주세요. 이 Android 버전에서는 앱의 자동 집중 연동을 지원하지 않아요.'
                      : '제어 센터에서 집중 모드를 선택하면 알림을 줄일 수 있어요. 설정 > 집중 모드에서 허용할 알림을 정할 수 있어요. 앱이 집중 모드를 자동으로 켜거나 끄지는 않아요.',
                ),
                const SizedBox(height: 16),
                if (android) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context, FocusChoice.always),
                    child: const Text('항상 사용'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, FocusChoice.once),
                    child: const Text('이번만'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, FocusChoice.disabled),
                    child: const Text('사용하지 않음'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context, FocusChoice.skip),
                    child: const Text('안내 건너뛰고 시작'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, FocusChoice.disabled),
                    child: const Text('다시 안내하지 않고 시작'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ) ??
      FocusChoice.skip;
}

Future<void> showStudyFocusSettings(
  BuildContext context,
  StudyFocusController focus,
) async {
  await focus.load();
  if (!context.mounted) return;
  final android = focus.capability == FocusCapability.ownedRule;
  final value = await showDialog<FocusPreference>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('집중 설정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              android
                  ? '다음 공부부터 적용돼요. 기기 알림 설정과 권한이 우선해요. 앱을 강제로 종료한 뒤에는 기기의 방해 금지 상태를 확인해 주세요.'
                  : '집중 모드는 기기에서 직접 선택해 주세요. 앱에서 자동 적용하지 않아요.',
            ),
            const SizedBox(height: 12),
            for (final p in [
              FocusPreference.ask,
              if (android) FocusPreference.always,
              FocusPreference.disabled,
            ])
              TextButton(
                onPressed: () => Navigator.pop(context, p),
                child: Text(
                  '${p == focus.preference ? '선택됨 · ' : ''}${p == FocusPreference.ask
                      ? (android ? '매번 물어보기' : '시작할 때 안내')
                      : p == FocusPreference.always
                      ? '항상 사용'
                      : android
                      ? '사용하지 않음'
                      : '안내하지 않음'}',
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (android)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              focus.openPermissionSettings();
            },
            child: const Text('알림 권한 설정'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
  if (value != null) await focus.setPreference(value);
}
