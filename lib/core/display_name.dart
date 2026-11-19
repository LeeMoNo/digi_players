const fallbackDisplayName = '数字游民';

/// 个人页和广场共用。空昵称显示「数字游民」。
String displayNameOrFallback(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return fallbackDisplayName;
  return trimmed;
}
