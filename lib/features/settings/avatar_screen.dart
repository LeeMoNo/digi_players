import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/avatar_image.dart';
import '../../core/avatar_url.dart';
import '../../core/layout/reading_width.dart';
import '../../core/layout/window_layout.dart';
import '../../core/router/app_back_button.dart';
import '../../core/ui/user_facing_error.dart';
import '../points/profile_repository.dart';
import '../points/user_avatar.dart';
import 'avatar_crop_screen.dart';

const _maxAvatarBytes = 512 * 1024;

Future<Uint8List?> _pickAvatarImage(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 95,
  );
  if (file == null) return null;
  return file.readAsBytes();
}

Future<Uint8List?> _cropAvatar(BuildContext context, Uint8List bytes) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AvatarCropScreen(bytes: bytes),
    ),
  );
}

Future<String?> _loadAvatarUrl() async {
  final res = await ApiClient.dio.get('/user/profile');
  final data = res.data;
  final path = data is Map ? data['avatar_url'] as String? : null;
  return absoluteAvatarUrl(path);
}

Future<String> _uploadAvatarBytes(Uint8List bytes) async {
  final res = await ApiClient.dio.post(
    '/user/avatar',
    data: FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
    }),
  );
  final data = res.data;
  final url = absoluteAvatarUrl(
    data is Map ? data['avatar_url'] as String? : null,
  );
  if (url == null) {
    throw DioException(
      requestOptions: RequestOptions(path: '/user/avatar'),
      message: 'missing avatar_url',
    );
  }
  return url;
}

Future<void> _deleteAvatar() {
  return ApiClient.dio.delete('/user/avatar');
}

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({
    super.key,
    this.loadAvatarUrl,
    this.pickGallery,
    this.pickCamera,
    this.cropAvatar,
    this.uploadAvatar,
    this.deleteAvatar,
    this.imageForUrl,
  });

  final Future<String?> Function()? loadAvatarUrl;
  final Future<Uint8List?> Function()? pickGallery;
  final Future<Uint8List?> Function()? pickCamera;
  final Future<Uint8List?> Function(BuildContext context, Uint8List bytes)?
  cropAvatar;
  final Future<String> Function(Uint8List bytes)? uploadAvatar;
  final Future<void> Function()? deleteAvatar;
  final ImageProvider<Object> Function(String url)? imageForUrl;

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  String? _url;
  Uint8List? _bytes;
  bool _saving = false;
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _url = ProfileCache.latest?.avatarUrl;
    _bytes = ProfileCache.latest?.avatarBytes;
    _load();
  }

  bool get _hasAvatar =>
      (_bytes != null && _bytes!.isNotEmpty) ||
      (_url != null && _url!.isNotEmpty);

  Future<void> _load() async {
    final epoch = _epoch;
    try {
      final url = await (widget.loadAvatarUrl ?? _loadAvatarUrl)();
      if (!mounted || epoch != _epoch) return;
      Uint8List? downloaded;
      if (widget.loadAvatarUrl == null && url != null) {
        downloaded = await fetchAvatarBytes(url);
        if (!mounted || epoch != _epoch) return;
      }
      setState(() {
        _url = url;
        if (downloaded != null) _bytes = downloaded;
      });
      ProfileCache.rememberAvatar(url, bytes: downloaded);
    } catch (_) {}
  }

  Future<void> _submit(Future<Uint8List?> Function() pick) async {
    if (_saving) return;
    final picked = await pick();
    if (picked == null || !mounted) return;
    final bytes = await (widget.cropAvatar ?? _cropAvatar)(context, picked);
    if (bytes == null || !mounted) return;
    if (bytes.isEmpty || bytes.length > _maxAvatarBytes) {
      _snack('图片需要小于 512KB');
      return;
    }

    final previousBytes = _bytes;
    _epoch++;
    setState(() {
      _saving = true;
      _bytes = bytes;
    });
    try {
      final url = await (widget.uploadAvatar ?? _uploadAvatarBytes)(bytes);
      ProfileCache.rememberAvatar(url, bytes: bytes);
      if (!mounted) return;
      setState(() => _url = url);
      _snack('头像已更新');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _bytes = previousBytes);
      _snack(_avatarError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _bytes = previousBytes);
      // 本地裁图/格式错误保留可读原因；网络类走统一短句。
      _snack(
        e is DioException
            ? _avatarError(e)
            : '保存失败：$e',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    if (_saving || !_hasAvatar) return;
    _epoch++;
    setState(() => _saving = true);
    try {
      await (widget.deleteAvatar ?? _deleteAvatar)();
      ProfileCache.rememberAvatar(null);
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _url = null;
      });
      _snack('已恢复默认头像');
    } on DioException catch (e) {
      if (!mounted) return;
      _snack(_avatarError(e));
    } catch (_) {
      if (!mounted) return;
      _snack(UserFacingError.loadFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _avatarError(DioException e) {
    if (e.response?.statusCode == 429) return '换得太频繁，请一小时后再试';
    final data = e.response?.data;
    final raw = data is Map ? data['error']?.toString() : null;
    if (raw == 'Unsupported image type') return '这种图片格式不支持，请换一张';
    return UserFacingError.from(e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: const Text('我的头像'),
      ),
      body: ReadingWidth(
        maxWidth: WindowLayout.formMaxWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '先选一张图，拖动裁剪后点确认才会保存。换设备登录还能看到。',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    UserAvatar(
                      size: 120,
                      url: _url,
                      bytes: _bytes,
                      borderRadius: BorderRadius.circular(60),
                      imageForUrl: widget.imageForUrl,
                    ),
                    if (_saving)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () => _submit(
                        widget.pickGallery ??
                            () => _pickAvatarImage(ImageSource.gallery),
                      ),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('从相册选择'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () => _submit(
                        widget.pickCamera ??
                            () => _pickAvatarImage(ImageSource.camera),
                      ),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('拍照'),
              ),
              if (_hasAvatar) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : _remove,
                  child: Text(
                    '恢复默认',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
