import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/features/games/hash_game/hash_game_logic.dart';
import 'package:digi_players/features/games/hash_game/hash_game_progress.dart';
import 'package:digi_players/features/games/hash_game/hash_game_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'offline',
    );
  }
}

void main() {
  late HttpClientAdapter originalAdapter;
  HashGameCheckpoint stored = HashGameCheckpoint.start;

  setUp(() {
    stored = HashGameCheckpoint.start;
    HashGameProgress.debugLoadOverride = () async => stored;
    HashGameProgress.debugSaveOverride = (checkpoint) async {
      stored = checkpoint;
    };
    HashGameProgress.debugClearOverride = () async {
      stored = HashGameCheckpoint.start;
    };
    originalAdapter = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _OfflineAdapter();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  tearDown(() {
    ApiClient.dio.httpClientAdapter = originalAdapter;
    HashGameProgress.debugLoadOverride = null;
    HashGameProgress.debugSaveOverride = null;
    HashGameProgress.debugClearOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  test('Nonce 只接受最多 6 位数字', () {
    expect(HashGameLogic.parseNonce(''), 0);
    expect(HashGameLogic.parseNonce('0'), 0);
    expect(HashGameLogic.parseNonce('42'), 42);
    expect(HashGameLogic.parseNonce('00012'), 12);
    expect(HashGameLogic.parseNonce('999999'), 999999);
    expect(HashGameLogic.parseNonce('1000000'), isNull);
    expect(HashGameLogic.parseNonce('12a'), isNull);
    expect(HashGameLogic.parseNonce('-1'), isNull);
    expect(HashGameLogic.parseNonce('1.5'), isNull);
    expect(HashGameLogic.parseNonce(' 1'), isNull);
  });

  testWidgets('普通高度下，过关按钮完整落在屏幕内', (tester) async {
    const size = Size(360, 640);
    await _showGame(
      tester,
      size,
      padding: const FakeViewPadding(top: 24, bottom: 16),
    );
    expect(find.text('满足条件！'), findsOneWidget);
    expect(
      tester.getRect(find.text('下一关 →')).bottom,
      lessThanOrEqualTo(size.height),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘弹出后页面不溢出，过关按钮仍可点到', (tester) async {
    const size = Size(360, 800);
    const keyboard = 320.0;
    await _showGame(
      tester,
      size,
      keyboard: keyboard,
      padding: const FakeViewPadding(top: 24),
    );
    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.text('下一关 →'));
    expect(button.bottom, lessThanOrEqualTo(size.height - keyboard));

    await tester.tap(find.text('下一关 →'));
    await tester.pump();
    expect(find.textContaining('关卡 2/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏加大字号也不溢出', (tester) async {
    await _showGame(
      tester,
      const Size(320, 480),
      textScale: 1.4,
      padding: const FakeViewPadding(top: 24, bottom: 24),
    );
    expect(find.text('满足条件！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('输入框拒绝非法字符，并限制在 6 位以内', (tester) async {
    await _showGame(tester, const Size(360, 800));
    final field = find.byType(TextField);

    await tester.enterText(field, '12ab3-4.5');
    await tester.pump();
    expect(_nonceText(tester), '12345');
    expect(find.text('Nonce：12345'), findsOneWidget);

    await tester.enterText(field, '123456789');
    await tester.pump();
    expect(_nonceText(tester), '123456');
    expect(find.text('Nonce：123456'), findsOneWidget);

    await tester.enterText(field, '你好99');
    await tester.pump();
    expect(_nonceText(tester), '99');

    await tester.enterText(field, '000012');
    await tester.pump();
    expect(_nonceText(tester), '12');
    expect(find.text('Nonce：12'), findsOneWidget);

    await tester.enterText(field, '');
    await tester.pump();
    expect(_nonceText(tester), isEmpty);
    expect(find.text('Nonce：0'), findsOneWidget);
  });

  testWidgets('已通过第一关后再次进入，直接显示第二关', (tester) async {
    stored = const HashGameCheckpoint(level: 1, solvedNonces: [7]);

    await _showGame(tester, const Size(360, 800));
    await _waitForLevel(tester, 2);

    expect(find.textContaining('关卡 2/3'), findsOneWidget);
    expect(find.textContaining('关卡 1/3'), findsNothing);
  });
}

Future<void> _waitForLevel(WidgetTester tester, int level) async {
  final label = '关卡 $level/3';
  for (var i = 0; i < 40; i++) {
    if (find.textContaining(label).evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail('等待 $label 超时');
}

String _nonceText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!.text;
}

Future<void> _showGame(
  WidgetTester tester,
  Size size, {
  double keyboard = 0,
  double textScale = 1,
  FakeViewPadding padding = const FakeViewPadding(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: const HashGameScreen(),
    ),
  );
  // 种子请求在测试里会立刻失败。pump() 不推进时间，定时器要靠 Duration.zero 清掉。
  for (var i = 0; i < 8; i++) {
    await tester.pump(Duration.zero);
  }
}
