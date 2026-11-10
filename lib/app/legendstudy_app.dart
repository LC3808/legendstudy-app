import '../features/learning/invite_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';
import '../features/app_update/app_update_gate.dart';

class LegendStudyApp extends ConsumerWidget {
  const LegendStudyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: '레전드스터디+',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) => AppUpdateGate(
      router: ref.watch(routerProvider),
      child: InviteListener(
        router: ref.watch(routerProvider),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
