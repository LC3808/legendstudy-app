import 'package:flutter/material.dart';

import '../avatar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});
  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final name = TextEditingController();
  bool busy = false, photoBusy = false, photoFailed = false, completed = false;
  String? error;
  String? hydratedOwner;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final owner = ref.read(authStateProvider).value?.userId;
    if (busy ||
        photoBusy ||
        photoFailed ||
        completed ||
        owner == null ||
        owner != hydratedOwner) {
      return;
    }
    final value = name.text.trim();
    if (value.isEmpty ||
        value.runes.length > 80 ||
        value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      setState(() => error = '닉네임은 공백을 제외한 1~80자로 입력해 주세요.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .upsertCurrentProfile(displayName: value);
      if (!mounted || ref.read(authStateProvider).value?.userId != owner) {
        return;
      }
      ref.invalidate(currentProfileProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 저장했어요.')));
      completed = true;
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() => error = '저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(currentProfileProvider);
    if (auth.isLoading || profile.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (auth.hasError || profile.hasError) {
      return ErrorState(
        message: '프로필을 불러오지 못했어요.',
        onRetry: () {
          ref.invalidate(authStateProvider);
          ref.invalidate(currentProfileProvider);
        },
      );
    }
    final owner = auth.value?.userId;
    if (owner == null) {
      hydratedOwner = null;
      name.clear();
      return const ShellPage(children: [Text('프로필을 편집하려면 로그인해 주세요.')]);
    }
    if (hydratedOwner != owner) {
      hydratedOwner = owner;
      busy = false;
      photoBusy = false;
      photoFailed = false;
      completed = false;
      name.text = profile.value?.displayName ?? '';
      error = null;
    }
    return ShellPage(
      children: [
        ProfileAvatar(
          key: ValueKey(owner),
          enabled: !busy,
          onBusyChanged: (value) => setState(() => photoBusy = value),
          onResult: (success) => setState(() => photoFailed = !success),
        ),
        if (photoFailed) const Text('사진 변경을 완료한 뒤 저장해 주세요. 사진 변경을 다시 시도해 주세요.'),
        const SizedBox(height: 16),
        TextField(
          controller: name,
          maxLength: 80,
          enabled: !busy,
          decoration: const InputDecoration(
            labelText: '닉네임',
            hintText: '닉네임 설정',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => save(),
        ),
        if (error != null) Semantics(liveRegion: true, child: Text(error!)),
        FilledButton(
          onPressed: busy || photoBusy || photoFailed || completed
              ? null
              : save,
          child: Text(busy ? '저장 중…' : '저장'),
        ),
      ],
    );
  }
}
