import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/supabase/supabase_providers.dart';

const avatarBucket = 'profile-avatars';
const avatarMaxBytes = 1024 * 1024;

abstract interface class AvatarRepository {
  Future<Uint8List?> load();
  Future<void> save(Uint8List png);
  Future<void> remove();
}

/// One private object is the canonical reference. No public/signed URL or
/// social metadata is persisted. Captured headers never switch to another user.
class StorageAvatarRepository implements AvatarRepository {
  StorageAvatarRepository(this.api, this.owner);
  final StorageFileApi api;
  final String owner;
  String get path => '$owner/avatar.png';
  @override
  Future<Uint8List?> load() async {
    try {
      return await api.download(path);
    } on StorageException catch (e) {
      // download() uses noResolveJson: even an error body may remain encoded.
      Object? code = e.error;
      var message = e.message;
      try {
        final body = jsonDecode(e.message);
        if (body is Map) {
          code = body['code'] ?? body['error'];
          message = body['message']?.toString() ?? message;
        }
      } catch (_) {
        /* Plain SDK error: never display its contents. */
      }
      if (code == 'NoSuchKey' ||
          code == 'ObjectNotFound' ||
          message == 'Object not found') {
        return null;
      }
      rethrow; // Missing bucket/permissions/network are not an empty avatar.
    }
  }

  @override
  Future<void> save(Uint8List png) async {
    if (png.length > avatarMaxBytes || png.isEmpty) {
      throw const FormatException();
    }
    await api.uploadBinary(
      path,
      png,
      fileOptions: const FileOptions(
        contentType: 'image/png',
        cacheControl: '0',
        upsert: true,
      ),
    );
  }

  @override
  Future<void> remove() async {
    await api.remove([path]);
  }
}

final avatarRepositoryProvider = Provider<AvatarRepository?>((ref) {
  final config = ref.watch(appConfigProvider);
  final owner = ref.watch(authStateProvider).value?.userId;
  final session = ref.watch(supabaseClientProvider)?.auth.currentSession;
  if (!config.profilePhotoEnabled ||
      owner == null ||
      session == null ||
      session.user.id != owner ||
      session.isExpired) {
    return null;
  }
  return StorageAvatarRepository(
    SupabaseStorageClient('${config.supabaseUrl}/storage/v1', {
      'apikey': config.supabasePublishableKey,
      'Authorization': 'Bearer ${session.accessToken}',
    }).from(avatarBucket),
    owner,
  );
});
final avatarProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  return ref.watch(avatarRepositoryProvider)?.load();
});

abstract interface class AvatarPicker {
  Future<Uint8List?> pick();
}

class GalleryAvatarPicker implements AvatarPicker {
  @override
  Future<Uint8List?> pick() async {
    final picker = ImagePicker();
    // Never automatically upload a result restored after Android process death:
    // it may have been selected by a different account. Ask for a fresh choice.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await picker.retrieveLostData();
    }
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length() > 20 * 1024 * 1024) throw const FormatException();
    final codec = await ui.instantiateImageCodec(
      await file.readAsBytes(),
      targetWidth: 512,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final bytes = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (bytes == null || bytes.lengthInBytes > avatarMaxBytes) {
          throw const FormatException();
        }
        // Re-encoding strips source EXIF/location metadata.
        return bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

final avatarPickerProvider = Provider<AvatarPicker>(
  (ref) => GalleryAvatarPicker(),
);

class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({super.key});
  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  bool busy = false;
  Future<void> change() async {
    if (busy) return;
    final owner = ref.read(authStateProvider).value?.userId;
    final repository = ref.read(avatarRepositoryProvider);
    if (owner == null) return;
    if (repository == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('현재 프로필 사진을 변경할 수 없어요.')));
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('사진 선택'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            ListTile(
              title: const Text('기본 이미지로 변경'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted ||
        action == null ||
        ref.read(authStateProvider).value?.userId != owner) {
      return;
    }
    setState(() {
      busy = true;
    });
    try {
      if (action == 'pick') {
        final png = await ref.read(avatarPickerProvider).pick();
        if (!mounted ||
            ref.read(authStateProvider).value?.userId != owner ||
            png == null) {
          return;
        }
        await repository.save(png);
      } else {
        await repository.remove();
      }
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        ref.invalidate(avatarProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('프로필 사진을 변경했어요.')));
      }
    } catch (_) {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진을 변경하지 못했어요. 사진 접근 권한과 연결을 확인한 뒤 다시 시도해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(authStateProvider).value?.userId;
    final avatar = ref.watch(avatarProvider);
    final bytes = avatar.isLoading || avatar.hasError ? null : avatar.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: '프로필 사진 변경',
          onPressed: busy || owner == null ? null : change,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: CircleAvatar(
            backgroundImage: bytes == null ? null : MemoryImage(bytes),
            child: busy || avatar.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  )
                : bytes == null
                ? const Icon(Icons.person_outline)
                : null,
          ),
        ),
        if (avatar.hasError)
          IconButton(
            tooltip: '사진 다시 불러오기',
            onPressed: () => ref.invalidate(avatarProvider),
            icon: const Icon(Icons.refresh),
          ),
      ],
    );
  }
}
