import 'dart:io';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/core/router/app_router.dart';
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
    hiveDir = await Directory.systemTemp.createTemp('digi_back_button');
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
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
  });

  testWidgets('单屏从学习进入设置、资料、广场后能返回', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = createAppRouter(initialLocation: '/learn');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => WindowLayoutScope(
            sizeClass: HorizontalSizeClass.unspecified,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await _flush(tester);

    await _openAndBack(tester, router, '/settings', '设置');
    await _openAndBack(tester, router, '/learn/library', '资料');
    await _openAndBack(tester, router, '/square', '数民广场');
    await _openAndBack(tester, router, '/learn/fraud', '警防诈骗');
    await _openAndBack(tester, router, '/settings/nickname', '设置昵称');
    await _openAndBack(tester, router, '/settings/language', '语言');
    await _openAndBack(tester, router, '/settings/theme', '主题');
    await _openAndBack(tester, router, '/settings/avatar', '我的头像');
    await _openAndBack(tester, router, '/settings/mnemonic', '查看助记词');
    await _openAndBack(tester, router, '/settings/privacy', '隐私政策');
    await _openAndBack(tester, router, '/settings/terms', '用户协议');
    await _openAndBack(tester, router, '/games/hash', '哈希碰碰乐  关卡 1/3');
    await _openAndBack(tester, router, '/games/antiscam', '反诈训练营  1/');
    await _openAndBack(tester, router, '/game/p2p', 'P2P 模拟器  关卡 1/3');
    await _openAndBack(tester, router, '/game/block-puzzle', '区块链拼图');
    await _openAndBack(tester, router, '/learn/chapter/ch_001', '章节');
    await _openAndBack(tester, router, '/learn/quiz/ch_001', '测验');
  });
}

Future<void> _openAndBack(
  WidgetTester tester,
  GoRouter router,
  String location,
  String title,
) async {
  router.push(location);
  await _afterNav(tester);
  expect(find.textContaining(title), findsWidgets);
  final back = find.byKey(const Key('app-back'));
  final implied = find.byType(BackButton);
  expect(
    back.evaluate().isNotEmpty || implied.evaluate().isNotEmpty,
    isTrue,
    reason: '$location 没有返回',
  );
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back);
  } else {
    await tester.tap(implied);
  }
  await _afterNav(tester);
  expect(find.text('学习'), findsWidgets);
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(Duration.zero);
  }
}

Future<void> _afterNav(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(Duration.zero);
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return Future.error(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'offline',
      ),
    );
  }
}
