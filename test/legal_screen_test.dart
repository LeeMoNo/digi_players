import 'dart:io';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/core/router/app_router.dart';
import 'package:digi_players/features/settings/legal_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  late Directory hiveDir;
  late HttpClientAdapter originalAdapter;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('digi_legal');
    Hive.init(hiveDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async => null);
    originalAdapter = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _OfflineAdapter();
  });

  tearDown(() async {
    ApiClient.dio.httpClientAdapter = originalAdapter;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('隐私政策含 DID、进度、头像与不能转币', () {
    final body = legalSections(LegalDoc.privacy).map((s) => s.body).join();
    expect(body, contains('DID'));
    expect(body, contains('进度'));
    expect(body, contains('头像'));
    expect(body, contains('不能收款'));
    expect(body, contains('不要往这个身份转币'));
    expect(body, contains('助记词'));
    expect(body, contains('当前版本不提供广场聊天'));
    expect(body, isNot(contains('http://')));
  });

  test('用户协议含教育用途、助记词账号与删除账号', () {
    final body = legalSections(LegalDoc.terms).map((s) => s.body).join();
    expect(body, contains('学习'));
    expect(body, contains('助记词'));
    expect(body, contains('删除账号'));
    expect(body, contains('不能用于收款'));
    expect(body, contains('当前版本不提供广场或开放聊天'));
  });

  testWidgets('注册页可打开协议与隐私政策', (tester) async {
    final router = createAppRouter(initialLocation: '/register');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('创建即表示你同意'), findsOneWidget);

    await tester.tap(find.text('《用户协议》'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '用户协议'), findsOneWidget);
    expect(find.textContaining('投资、法律或财务建议'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('《隐私政策》'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '隐私政策'), findsOneWidget);
    expect(find.textContaining('不要往这个身份转币'), findsOneWidget);
  });

  testWidgets('设置路由可打开隐私政策', (tester) async {
    final router = createAppRouter(initialLocation: '/settings/privacy');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '隐私政策'), findsOneWidget);
    expect(find.textContaining('DID'), findsWidgets);
  });
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error":"offline"}',
      503,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
