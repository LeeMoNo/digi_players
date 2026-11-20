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

void main() {
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  late _ProfileAdapter adapter;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async => null);
    adapter = _ProfileAdapter();
    ApiClient.dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    ApiClient.dio.httpClientAdapter = adapter.previous;
  });

  testWidgets('窄窗口整页进入聊天，返回房间列表', (tester) async {
    await _surface(tester, const Size(400, 800));
    final router = createAppRouter(initialLocation: '/square');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.unspecified));
    await _flush(tester);

    expect(find.text('选择话题'), findsOneWidget);
    expect(find.text('选一个话题'), findsNothing);
    await tester.tap(find.text('区块链技术'));
    await _afterNav(tester);

    expect(find.text('选择话题'), findsNothing);
    expect(find.text('区块链技术'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await _pop(tester);
    expect(find.text('选择话题'), findsOneWidget);
    expect(find.text('数民广场'), findsOneWidget);
  });

  testWidgets('可双栏时左房间右聊天，返回只退一层', (tester) async {
    await _surface(tester, const Size(1200, 800));
    final router = createAppRouter(initialLocation: '/square');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await _flush(tester);

    expect(find.text('选一个话题'), findsOneWidget);
    expect(find.text('区块链技术'), findsOneWidget);
    expect(find.text('密码学讨论'), findsOneWidget);
    expect(find.text('DID 与 Web3 身份'), findsOneWidget);
    expect(find.text('反诈经验交流'), findsOneWidget);

    await tester.tap(find.text('区块链技术'));
    await _afterNav(tester);
    expect(_tile(tester, '区块链技术').selected, isTrue);
    expect(find.widgetWithText(AppBar, '区块链技术'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextField)).width,
      greaterThan(WindowLayout.readingMaxWidth),
    );

    await tester.enterText(find.byType(TextField), '你好');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    await tester.tap(find.text('密码学讨论'));
    await _afterNav(tester);
    expect(_tile(tester, '密码学讨论').selected, isTrue);
    expect(_tile(tester, '区块链技术').selected, isFalse);
    expect(find.widgetWithText(AppBar, '密码学讨论'), findsOneWidget);

    await _pop(tester);
    expect(find.text('选一个话题'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '密码学讨论'), findsNothing);
    expect(find.text('区块链技术'), findsOneWidget);
  });

  testWidgets('宽窗口广场列表只请求一次个人资料', (tester) async {
    await _surface(tester, const Size(1200, 800));
    final router = createAppRouter(initialLocation: '/square');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await _flush(tester);
    expect(adapter.profileGets, 1);

    await tester.tap(find.text('区块链技术'));
    await _afterNav(tester);
    // 聊天页仍会读一次显示名。多出来的那次来自聊天页，不是第二份广场列表。
    expect(adapter.profileGets, 2);

    await tester.tap(find.text('密码学讨论'));
    await _afterNav(tester);
    expect(adapter.profileGets, 3);
  });
}

ListTile _tile(WidgetTester tester, String title) {
  return tester.widget<ListTile>(find.widgetWithText(ListTile, title));
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
  await tester.pump();
  await tester.pump(Duration.zero);
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

class _ProfileAdapter implements HttpClientAdapter {
  _ProfileAdapter() : previous = ApiClient.dio.httpClientAdapter;

  final HttpClientAdapter previous;
  int profileGets = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/user/profile')) profileGets++;
    return ResponseBody.fromString(
      '{"display_name":"小林"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
