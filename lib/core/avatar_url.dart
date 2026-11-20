import 'config/app_config.dart';

/// 服务端返回的头像地址是 `/media/avatars/...`。拼上当前 Worker 根地址。
String? absoluteAvatarUrl(String? path) {
  final raw = path?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('https://') || raw.startsWith('http://')) return raw;
  final base = AppConfig.workersBaseUrl.replaceFirst(RegExp(r'/+$'), '');
  final suffix = raw.startsWith('/') ? raw : '/$raw';
  return '$base$suffix';
}
