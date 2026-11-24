import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/features/points/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );
  late HttpClientAdapter original;
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('avatar_fetch');
    Hive.init(hiveDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          if (call.method == 'read' && call.arguments['key'] == 'dp_did') {
            return 'did:me';
          }
          return null;
        });
    original = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _AvatarAdapter(png);
  });

  tearDown(() async {
    ApiClient.dio.httpClientAdapter = original;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    ProfileCache.clear();
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('重新进入我的页面时，会按档案里的地址把已上传的头像拉下来', () async {
    final snapshot = await ProfileRepository().load();

    expect(snapshot.did, 'did:me');
    expect(snapshot.nickname, 'San phone');
    expect(
      snapshot.avatarUrl,
      'https://digiplayers-workers.wasai-test.workers.dev/media/avatars/${'a' * 32}.jpg?v=9',
    );
    expect(snapshot.avatarBytes, png);
  });
}

class _AvatarAdapter implements HttpClientAdapter {
  _AvatarAdapter(this.bytes);

  final Uint8List bytes;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path == '/user/profile') {
      return ResponseBody.fromString(
        jsonEncode({
          'display_name': 'San phone',
          'avatar_url': '/media/avatars/${'a' * 32}.jpg?v=9',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (path.startsWith('/media/avatars/')) {
      return ResponseBody.fromBytes(
        bytes,
        200,
        headers: {
          Headers.contentTypeHeader: ['image/jpeg'],
        },
      );
    }
    return ResponseBody.fromString(
      '{}',
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
