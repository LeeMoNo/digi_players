import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 有图时显示头像，没有图时用原来的指纹底。
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    this.url,
    this.bytes,
    this.borderRadius,
    this.onTap,
    this.imageForUrl,
  });

  final double size;
  final String? url;
  final Uint8List? bytes;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  /// 测试可替换网络图片，避免真的去请求。
  final ImageProvider<Object> Function(String url)? imageForUrl;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final image = _provider();
    final avatar = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: image == null
            ? _fallback(context)
            : Image(
                image: image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _fallback(context),
              ),
      ),
    );
    if (onTap == null) return avatar;
    return Semantics(
      button: true,
      label: '更换头像',
      child: GestureDetector(onTap: onTap, child: avatar),
    );
  }

  ImageProvider<Object>? _provider() {
    final local = bytes;
    if (local != null && local.isNotEmpty) return MemoryImage(local);
    final current = url;
    if (current == null || current.isEmpty) return null;
    final custom = imageForUrl;
    if (custom != null) return custom(current);
    return NetworkImage(current);
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
      ),
      child: Icon(Icons.fingerprint, color: Colors.white, size: size * 0.58),
    );
  }
}
