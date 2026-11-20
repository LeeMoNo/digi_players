import 'dart:convert';
import 'dart:typed_data';

import 'package:digi_players/features/points/profile_repository.dart';
import 'package:digi_players/features/settings/avatar_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  tearDown(ProfileCache.clear);

  testWidgets('取消选择不会上传', (tester) async {
    var uploads = 0;
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => null,
          pickGallery: () async => null,
          uploadAvatar: (_) async {
            uploads++;
            return 'https://example.com/a.jpg';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('从相册选择'));
    await tester.pump();

    expect(uploads, 0);
    expect(find.text('头像已更新'), findsNothing);
  });

  testWidgets('取消裁剪不会上传', (tester) async {
    var uploads = 0;
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => null,
          pickGallery: () async => png,
          cropAvatar: (_, __) async => null,
          uploadAvatar: (_) async {
            uploads++;
            return 'https://example.com/a.jpg';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('从相册选择'));
    await tester.pump();

    expect(uploads, 0);
    expect(find.text('头像已更新'), findsNothing);
    expect(find.text('从相册选择'), findsOneWidget);
  });

  testWidgets('相册图片上传成功后写入个人页缓存', (tester) async {
    ProfileCache.latest = const ProfileSnapshot(
      did: 'did:me',
      nickname: '小林',
      points: 3,
      unlocked: {},
      rankings: [],
    );
    final ticket = ProfileCache.begin();
    var uploads = 0;
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => null,
          pickGallery: () async => png,
          cropAvatar: (_, bytes) async => bytes,
          uploadAvatar: (bytes) async {
            uploads++;
            expect(bytes, png);
            return 'https://example.com/a.jpg?v=1';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('从相册选择'));
    await tester.pump();
    await tester.pump();

    expect(uploads, 1);
    expect(ProfileCache.isLatest(ticket), isFalse);
    expect(ProfileCache.latest?.avatarUrl, 'https://example.com/a.jpg?v=1');
    expect(ProfileCache.latest?.nickname, '小林');
    expect(find.text('头像已更新'), findsOneWidget);
  });

  testWidgets('超过 512KB 不会上传', (tester) async {
    var uploads = 0;
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => null,
          pickGallery: () async => png,
          cropAvatar: (_, __) async => Uint8List(512 * 1024 + 1),
          uploadAvatar: (_) async {
            uploads++;
            return 'https://example.com/a.jpg';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('从相册选择'));
    await tester.pump();

    expect(uploads, 0);
    expect(find.text('图片需要小于 512KB'), findsOneWidget);
  });

  testWidgets('上传失败时保留原来的头像地址', (tester) async {
    ProfileCache.latest = const ProfileSnapshot(
      did: 'did:me',
      nickname: '小林',
      avatarUrl: 'https://example.com/old.jpg',
      points: 1,
      unlocked: {},
      rankings: [],
    );
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => 'https://example.com/old.jpg',
          imageForUrl: (_) => MemoryImage(png),
          pickGallery: () async => png,
          cropAvatar: (_, bytes) async => bytes,
          uploadAvatar: (_) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/user/avatar'),
              response: Response(
                requestOptions: RequestOptions(path: '/user/avatar'),
                statusCode: 400,
                data: {'error': 'Unsupported image type'},
              ),
              type: DioExceptionType.badResponse,
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('从相册选择'));
    await tester.pump();
    await tester.pump();

    expect(find.text('保存失败：Unsupported image type'), findsOneWidget);
    expect(ProfileCache.latest?.avatarUrl, 'https://example.com/old.jpg');
  });

  testWidgets('恢复默认会清掉缓存里的头像', (tester) async {
    ProfileCache.latest = const ProfileSnapshot(
      did: 'did:me',
      nickname: '小林',
      avatarUrl: 'https://example.com/old.jpg',
      points: 1,
      unlocked: {},
      rankings: [],
    );
    var deleted = 0;
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => 'https://example.com/old.jpg',
          imageForUrl: (_) => MemoryImage(png),
          deleteAvatar: () async {
            deleted++;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('恢复默认'), findsOneWidget);
    await tester.tap(find.text('恢复默认'));
    await tester.pump();
    await tester.pump();

    expect(deleted, 1);
    expect(ProfileCache.latest?.avatarUrl, isNull);
    expect(ProfileCache.latest?.nickname, '小林');
    expect(find.text('已恢复默认头像'), findsOneWidget);
    expect(find.text('恢复默认'), findsNothing);
  });

  testWidgets('选图后先打开裁剪，取消则不上传', (tester) async {
    var uploads = 0;
    await tester.pumpWidget(
      _page(
        AvatarScreen(
          loadAvatarUrl: () async => null,
          pickGallery: () async => png,
          uploadAvatar: (_) async {
            uploads++;
            return 'https://example.com/a.jpg';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('从相册选择'));
    await tester.pump();
    await tester.pump();

    expect(find.text('裁剪头像'), findsOneWidget);
    expect(find.text('使用这张头像'), findsOneWidget);
    expect(uploads, 0);

    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump();

    expect(find.text('从相册选择'), findsOneWidget);
    expect(find.text('裁剪头像'), findsNothing);
    expect(uploads, 0);
  });
}

Widget _page(Widget child) {
  return MaterialApp(home: child);
}
