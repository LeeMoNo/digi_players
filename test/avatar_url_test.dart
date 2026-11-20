import 'package:digi_players/core/avatar_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('相对路径拼上 Worker 根地址', () {
    expect(
      absoluteAvatarUrl('/media/avatars/abc.jpg?v=9'),
      'https://digiplayers-workers.wasai-test.workers.dev/media/avatars/abc.jpg?v=9',
    );
    expect(
      absoluteAvatarUrl('media/avatars/abc.jpg'),
      'https://digiplayers-workers.wasai-test.workers.dev/media/avatars/abc.jpg',
    );
  });

  test('空地址和完整地址保持原样', () {
    expect(absoluteAvatarUrl(null), isNull);
    expect(absoluteAvatarUrl('  '), isNull);
    expect(
      absoluteAvatarUrl('https://cdn.example/a.jpg'),
      'https://cdn.example/a.jpg',
    );
  });
}
