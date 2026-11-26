import 'dart:async';
import 'dart:io';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/core/providers/app_settings_provider.dart';
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
    hiveDir = await Directory.systemTemp.createTemp('digi_settings_split');
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

  testWidgets('窄窗口昵称和助记词仍是整页', (tester) async {
    await _surface(tester, const Size(400, 800));
    final router = createAppRouter(initialLocation: '/settings');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.unspecified));
    await _flush(tester);

    expect(find.text('选一项'), findsNothing);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(
      find.text('助记词就是这个学习账号。换一台设备用同一组词登录，进度还在。把词交给别人，对方看到的也是这份进度。'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('退出登录'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('删除账号'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('我的昵称'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('我的昵称'));
    await _afterNav(tester);
    expect(find.widgetWithText(AppBar, '设置昵称'), findsOneWidget);
    expect(find.text('我的昵称'), findsNothing);

    await _pop(tester);
    expect(find.text('我的昵称'), findsOneWidget);

    await tester.tap(find.text('我的头像'));
    await _afterNav(tester);
    expect(find.widgetWithText(AppBar, '我的头像'), findsOneWidget);
    expect(find.text('从相册选择'), findsOneWidget);
    expect(find.text('拍照'), findsOneWidget);

    await _pop(tester);
    expect(find.text('我的昵称'), findsOneWidget);

    await tester.tap(find.text('查看助记词'));
    await _afterNav(tester);
    expect(find.widgetWithText(AppBar, '查看助记词'), findsOneWidget);
    expect(find.text('安全'), findsNothing);

    await _pop(tester);
    expect(find.text('安全'), findsOneWidget);
  });

  testWidgets('可双栏时助记词在右栏且不超过 440', (tester) async {
    await _surface(tester, const Size(1200, 800));
    final router = createAppRouter(initialLocation: '/settings');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await _flush(tester);

    expect(find.widgetWithText(AppBar, '设置'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '设置昵称'), findsOneWidget);
    expect(find.text('我的昵称'), findsOneWidget);
    expect(find.byKey(const Key('main-rail')), findsNothing);
    expect(find.byKey(const Key('rail-menu')), findsNothing);
    expect(find.text('版本'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);

    await tester.tap(find.text('查看助记词'));
    await _afterNav(tester);
    expect(find.widgetWithText(AppBar, '查看助记词'), findsOneWidget);
    expect(find.text('选一项'), findsNothing);
    final pane = tester.getSize(
      find
          .ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Center),
          )
          .first,
    );
    expect(pane.width, lessThanOrEqualTo(WindowLayout.formMaxWidth));
    expect(pane.width, greaterThan(400));

    await _pop(tester);
    expect(find.widgetWithText(AppBar, '设置昵称'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '查看助记词'), findsNothing);
  });

  testWidgets('昵称开着时切换语言，左栏更新且右栏不收起', (tester) async {
    await _surface(tester, const Size(1200, 800));
    final router = createAppRouter(initialLocation: '/settings');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await _flush(tester);

    await tester.tap(find.text('我的昵称'));
    await _afterNav(tester);
    expect(find.widgetWithText(AppBar, '设置昵称'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);

    final context = tester.element(find.text('退出登录'));
    unawaited(
      ProviderScope.containerOf(
        context,
      ).read(appSettingsProvider.notifier).setLanguage('en'),
    );
    await tester.pump();

    expect(find.widgetWithText(AppBar, '设置昵称'), findsOneWidget);
    expect(find.text('选一项'), findsNothing);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('简体中文'), findsNothing);

    await tester.tap(find.text('查看助记词'));
    await _afterNav(tester);
    expect(find.widgetWithText(AppBar, '查看助记词'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '设置昵称'), findsNothing);

    await _pop(tester);
    expect(find.widgetWithText(AppBar, '设置昵称'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '查看助记词'), findsNothing);
    expect(find.text('English'), findsOneWidget);
  });
}

Widget _app(GoRouter router, HorizontalSizeClass sizeClass) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => WindowLayoutScope(
        sizeClass: sizeClass,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(Duration.zero);
  }
}

Future<void> _afterNav(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(Duration.zero);
}

Future<void> _pop(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).pop();
  await _afterNav(tester);
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
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'offline',
    );
  }
}
