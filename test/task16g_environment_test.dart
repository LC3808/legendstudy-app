import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/config/app_config.dart';

void main() {
  test(
    'TEST Math gateway requires the exact isolated project and explicit origin',
    () {
      const url = 'https://kpqbedylxlyntrrfybpn.supabase.co';
      const origin = 'https://legendstudy-task16b.pages.dev';
      expect(
        const AppConfig(
          environment: 'test',
          supabaseUrl: url,
          testEssayApiOrigin: origin,
        ).essayApiOrigin,
        origin,
      );
      expect(
        () => const AppConfig(
          environment: 'test',
          supabaseUrl: url,
        ).essayApiOrigin,
        throwsStateError,
      );
      expect(
        () => const AppConfig(
          environment: 'test',
          supabaseUrl: 'https://other.supabase.co',
          testEssayApiOrigin: origin,
        ).essayApiOrigin,
        throwsStateError,
      );
      expect(
        () => const AppConfig(
          environment: 'test',
          supabaseUrl: url,
          testEssayApiOrigin: 'https://lab.legendstudy.com',
        ).essayApiOrigin,
        throwsStateError,
      );
      expect(
        const AppConfig(
          environment: 'production',
          testEssayApiOrigin: origin,
        ).essayApiOrigin,
        'https://lab.legendstudy.com',
      );
    },
  );
}
