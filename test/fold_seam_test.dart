import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/core/router/app_router.dart';
import 'package:digi_players/features/auth/mnemonic_screen.dart';
import 'package:digi_players/features/games/p2p_game/p2p_game_data.dart';
import 'package:digi_players/features/games/p2p_game/p2p_game_screen.dart';
import 'package:digi_players/features/games/p2p_game/p2p_network_painter.dart';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('平坦且短边为 0 时双栏分界仍是 240', () {
    final seam = foldSeamFromFeature(
      type: 'hinge',
      posture: 'flat',
      left: 360,
      top: 0,
      width: 0,
      height: 800,
    );
    expect(seam, isNull);

    final plan = resolveFoldSplit(
      rightEdge: 800,
      contentStart: WindowLayout.railWidth,
      seam: seam,
    );
    expect(plan.split, isTrue);
    expect(plan.listWidth, WindowLayout.listWidth);
    expect(plan.gap, 1);
  });

  test('半折竖缝把分界移到折痕，一侧不够宽则单栏', () {
    final seam = foldSeamFromFeature(
      type: 'hinge',
      posture: 'halfOpened',
      left: 360,
      top: 0,
      width: 16,
      height: 800,
    );
    expect(seam, isNotNull);

    final plan = resolveFoldSplit(
      rightEdge: 800,
      contentStart: WindowLayout.railWidth,
      seam: seam,
    );
    expect(plan.split, isTrue);
    expect(plan.gap, 16);
    expect(plan.listWidth, 360 - WindowLayout.railWidth);
    expect(WindowLayout.railWidth + plan.listWidth, 360);

    final squeezed = resolveFoldSplit(
      rightEdge: 900,
      contentStart: WindowLayout.railWidth,
      seam: foldSeamFromFeature(
        type: 'fold',
        posture: 'halfOpened',
        left: 150,
        top: 0,
        width: 16,
        height: 800,
      ),
    );
    expect(squeezed.split, isFalse);
  });

  test('折痕识别：刘海不算，平坦薄缝不算，半折薄缝算', () {
    expect(
      foldSeamFromFeature(
        type: 'cutout',
        posture: 'unknown',
        left: 0,
        top: 0,
        width: 40,
        height: 20,
      ),
      isNull,
    );
    expect(
      foldSeamFromFeature(
        type: 'fold',
        posture: 'flat',
        left: 360,
        top: 0,
        width: 4,
        height: 800,
      ),
      isNull,
    );
    expect(
      foldSeamFromFeature(
        type: 'fold',
        posture: 'halfOpened',
        left: 360,
        top: 0,
        width: 4,
        height: 800,
      ),
      isNotNull,
    );
    expect(
      foldSeamFromChannel({
        'active': false,
        'left': 10,
        'top': 0,
        'width': 16,
        'height': 800,
      }),
      isNull,
    );
    expect(foldSeamFromChannel(null), isNull);
    final ios = foldSeamFromChannel({
      'active': true,
      'left': 360,
      'top': 0,
      'width': 16,
      'height': 800,
    });
    expect(ios?.left, 360);
    expect(ios?.vertical, isTrue);
  });

  test('横缝一侧不足 160 时不切开', () {
    final open = resolveHorizontalFold(
      height: 700,
      originY: 0,
      seam: const FoldSeam(left: 0, top: 300, width: 800, height: 16),
    );
    expect(open.split, isTrue);
    expect(open.top, 300);
    expect(open.gap, 16);

    final closed = resolveHorizontalFold(
      height: 400,
      originY: 0,
      seam: const FoldSeam(left: 0, top: 40, width: 800, height: 16),
    );
    expect(closed.intersects, isTrue);
    expect(closed.split, isFalse);
  });

  testWidgets('缝宽为 0 时资料双栏仍以 240 分隔', (tester) async {
    await _surface(tester, const Size(820, 1180));
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _app(
        router,
        fold: const FoldSeam(left: 360, top: 0, width: 0, height: 1180),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('选一节资料'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('library-scroll'))).width,
      closeTo(WindowLayout.listWidth, 1),
    );
    expect(
      tester.widget<VerticalDivider>(find.byType(VerticalDivider)).width,
      1,
    );
    expect(_gapWidth(tester, WindowLayout.listWidth), 1);
  });

  testWidgets('竖缝把资料分界移到折痕', (tester) async {
    await _surface(tester, const Size(820, 1180));
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    const seam = FoldSeam(left: 360, top: 0, width: 16, height: 1180);
    await tester.pumpWidget(_app(router, fold: seam));
    await tester.pumpAndSettle();

    final scroll = tester.getRect(find.byKey(const Key('library-scroll')));
    expect(scroll.right, closeTo(seam.left, 1));
    expect(_gapWidth(tester, scroll.width), seam.width);
    expect(
      tester.getRect(find.text('选一节资料')).left,
      greaterThanOrEqualTo(seam.right),
    );
  });

  testWidgets('竖缝穿过画布时节点中心让开，点缝不会选中', (tester) async {
    await _surface(tester, const Size(800, 800));
    final original = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _OfflineAdapter();
    addTearDown(() {
      ApiClient.dio.httpClientAdapter = original;
    });
    const storage = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      storage,
      (call) async => null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        storage,
        null,
      );
    });

    const seam = FoldSeam(left: 328, top: 0, width: 16, height: 800);
    await tester.pumpWidget(
      const MaterialApp(
        home: WindowLayoutScope(
          sizeClass: HorizontalSizeClass.regular,
          fold: seam,
          child: P2PGameScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final paint = tester.renderObject<RenderBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is P2PNetworkPainter,
      ),
    );
    final origin = paint.localToGlobal(Offset.zero);
    for (final node in p2pLevels.first.nodes) {
      final center =
          origin +
          Offset(
            node.position.dx * paint.size.width,
            node.position.dy * paint.size.height,
          );
      expect(
        seam.overlaps(Rect.fromCircle(center: center, radius: 0.5)),
        isFalse,
        reason: 'node ${node.id} center $center paint ${paint.size} at $origin',
      );
    }
    final uncorrected = Offset(0.42 * 800, 0);
    expect(seam.rect.contains(uncorrected), isTrue);

    await tester.tapAt(
      Offset(seam.left + seam.width / 2, origin.dy + paint.size.height / 2),
    );
    await tester.pump();
    expect(find.text('点击绿色节点选为中继'), findsOneWidget);

    final first = p2pLevels.first.nodes.first;
    await tester.tapAt(
      origin +
          Offset(
            first.position.dx * paint.size.width,
            first.position.dy * paint.size.height,
          ),
    );
    await tester.pump();
    expect(find.text('点击蓝色节点转发消息'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('助记词词卡不跨竖缝', (tester) async {
    await _surface(tester, const Size(800, 900));
    const seam = FoldSeam(left: 392, top: 0, width: 16, height: 900);
    await tester.pumpWidget(
      MaterialApp(
        home: WindowLayoutScope(
          sizeClass: HorizontalSizeClass.regular,
          fold: seam,
          child: MnemonicScreen(mnemonic: List.generate(12, (i) => 'word$i')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final grid = tester.getRect(find.byType(GridView));
    expect(seam.overlaps(grid), isFalse);
    expect(grid.right <= seam.left || grid.left >= seam.right, isTrue);
    expect(grid.width, lessThanOrEqualTo(WindowLayout.formMaxWidth));
  });

  testWidgets('折痕通道失败时页面仍在', (tester) async {
    const channel = MethodChannel(WindowLayout.sizeClassChannel);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == WindowLayout.foldMethod) {
        throw PlatformException(code: 'missing');
      }
      return 'regular';
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(home: WindowLayoutHost(child: Text('还在'))),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('还在'), findsOneWidget);
    final context = tester.element(find.text('还在'));
    expect(WindowLayoutScope.foldOf(context), isNull);
    expect(WindowLayoutScope.sizeClassOf(context), HorizontalSizeClass.regular);
  });

  testWidgets('Android 半折铰链进入折痕，平坦零宽不进入', (tester) async {
    await _surface(tester, const Size(800, 800));
    tester.view.displayFeatures = const [
      DisplayFeature(
        bounds: Rect.fromLTWH(360, 0, 16, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ];
    addTearDown(tester.view.resetDisplayFeatures);

    await tester.pumpWidget(
      const MaterialApp(home: WindowLayoutHost(child: _FoldLabel())),
    );
    await tester.pump();
    expect(find.text('360x16'), findsOneWidget);

    tester.view.displayFeatures = const [
      DisplayFeature(
        bounds: Rect.fromLTWH(360, 0, 0, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
    ];
    await tester.pump();
    expect(find.text('none'), findsOneWidget);
  });
}

double _gapWidth(WidgetTester tester, double listWidth) {
  for (final row in tester.renderObjectList<RenderFlex>(find.byType(Row))) {
    if (row.direction != Axis.horizontal || row.childCount < 3) continue;
    final first = row.firstChild!;
    final second = row.childAfter(first)!;
    if ((first.size.width - listWidth).abs() < 1) return second.size.width;
  }
  return -1;
}

Widget _app(GoRouter router, {FoldSeam? fold}) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => WindowLayoutScope(
      sizeClass: HorizontalSizeClass.regular,
      fold: fold,
      child: child ?? const SizedBox.shrink(),
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

class _FoldLabel extends StatelessWidget {
  const _FoldLabel();

  @override
  Widget build(BuildContext context) {
    final fold = WindowLayoutScope.foldOf(context);
    if (fold == null) return const Text('none');
    return Text('${fold.left.round()}x${fold.width.round()}');
  }
}
