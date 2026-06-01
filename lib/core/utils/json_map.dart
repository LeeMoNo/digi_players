/// Hive / Dio 反序列化后嵌套 Map 常为 `Map<dynamic, dynamic>`，需递归转为 `Map<String, dynamic>`。
Map<String, dynamic> deepJsonMap(dynamic value) {
  if (value is! Map) {
    throw ArgumentError('Expected JSON object, got ${value.runtimeType}');
  }
  return value.map(
    (k, v) => MapEntry(k.toString(), _deepJsonValue(v)),
  );
}

dynamic _deepJsonValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k.toString(), _deepJsonValue(v)),
    );
  }
  if (value is List) {
    return value.map(_deepJsonValue).toList();
  }
  return value;
}
