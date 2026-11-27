import 'dart:typed_data';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/core/models/chapter.dart';
import 'package:digi_players/features/auth/register_screen.dart';
import 'package:digi_players/features/games/antiscam_game/antiscam_screen.dart';
import 'package:digi_players/features/games/approve_radar/approve_radar_screen.dart';
import 'package:digi_players/features/games/block_puzzle/block_puzzle_screen.dart';
import 'package:digi_players/features/games/hash_game/hash_game_screen.dart';
import 'package:digi_players/features/games/p2p_game/p2p_game_screen.dart';
import 'package:digi_players/features/games/key_custody/key_custody_screen.dart';
import 'package:digi_players/features/games/listing_desk/listing_desk_screen.dart';
import 'package:digi_players/features/games/multisig_desk/multisig_desk_screen.dart';
import 'package:digi_players/features/games/stablecoin_scale/stablecoin_scale_screen.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:digi_players/features/home/widgets/home_widgets.dart';
import 'package:digi_players/features/learn/chapter_screen.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('400 宽时学习首页、章节和注册页不被收窄', (tester) async {
    await _setSurface(tester, const Size(400, 800));

    await tester.pumpWidget(_app(const _LearnHome()));
    await tester.pump();
    final learn = tester.getRect(find.byKey(const Key('learn-home-scroll')));
    expect(learn.width, closeTo(400, 1));
    expect(learn.bottom, closeTo(800, 1));

    await tester.pumpWidget(_app(_chapter()));
    await tester.pump();
    expect(
      tester.getSize(find.byType(LinearProgressIndicator)).width,
      closeTo(400 - 48, 1),
    );

    await tester.pumpWidget(_app(const RegisterScreen()));
    await tester.pump();
    expect(
      tester.getSize(find.byType(FilledButton)).width,
      closeTo(400 - 64, 1),
    );
  });

  testWidgets('1200 宽时学习首页在侧栏右侧居中，注册页不超过 440', (tester) async {
    await _setSurface(tester, const Size(1200, 800));
    final router = GoRouter(
      initialLocation: '/learn',
      routes: [
        ShellRoute(
          builder: (_, __, child) =>
              MainShell(reportDailyLogin: () async {}, child: child),
          routes: [
            GoRoute(path: '/learn', builder: (_, __) => const _LearnHome()),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => WindowLayoutScope(
          sizeClass: HorizontalSizeClass.regular,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    final list = tester.getRect(find.byKey(const Key('learn-home-scroll')));
    final rail = tester.getRect(find.byKey(const Key('main-rail')));
    expect(list.width, closeTo(WindowLayout.readingMaxWidth, 1));
    expect(list.center.dx, closeTo(rail.right + (1200 - rail.right) / 2, 1));
    expect(list.bottom, closeTo(800, 1));

    await tester.pumpWidget(_app(const RegisterScreen()));
    await tester.pump();
    final button = tester.getRect(find.byType(FilledButton));
    expect(button.width, closeTo(WindowLayout.formMaxWidth - 64, 1));
    expect(button.center.dx, closeTo(600, 1));
  });

  testWidgets('1200 宽时四个练习铺满侧栏右侧', (tester) async {
    final adapter = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _FailAdapter();
    addTearDown(() => ApiClient.dio.httpClientAdapter = adapter);
    await _setSurface(tester, const Size(1200, 800));
    final router = _gameRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerApp(router));
    await tester.pump();

    for (final path in [
      '/game/block-puzzle',
      '/games/hash',
      '/game/p2p',
      '/games/antiscam',
      '/games/approve',
      '/games/stablecoin',
      '/games/custody',
      '/games/multisig',
      '/games/listing',
    ]) {
      router.go(path);
      await tester.pump();
      await tester.pump(Duration.zero);
      final rail = tester.getRect(find.byKey(const Key('main-rail')));
      final slot = 1200 - rail.width;
      expect(_widestContent(tester), greaterThan(slot - 48));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('学习地图按父级宽度排两列', (tester) async {
    await _pumpMap(tester, 400);
    expect(tester.getSize(find.byType(Card).first).width, closeTo(196, 1));
    expect(
      tester.getTopLeft(find.byType(Card).at(0)).dy,
      tester.getTopLeft(find.byType(Card).at(1)).dy,
    );

    await _pumpMap(tester, 720);
    expect(tester.getSize(find.byType(Card).first).width, closeTo(356, 1));
    expect(
      tester.getTopLeft(find.byType(Card).at(0)).dy,
      tester.getTopLeft(find.byType(Card).at(1)).dy,
    );
  });
}

class _LearnHome extends StatelessWidget {
  const _LearnHome();

  @override
  Widget build(BuildContext context) {
    return LearnHomeScreen(
      loadProgress: () async => const LearnPathProgress(),
      loadChapters: () async {},
      dailyTask: const SizedBox.shrink(),
    );
  }
}

Widget _chapter() {
  return ChapterScreen(
    chapterId: 'ch_001',
    initialDetail: ChapterDetail(
      chapterId: 'ch_001',
      cards: const [
        CardItem(
          cardId: 'c1',
          order: 1,
          title: {'zh_CN': '共有的账本'},
          body: {'zh_CN': '正文'},
          pointsAction: 'read',
        ),
      ],
      quizQuestions: const [],
      passScore: 1,
      quizPointsAction: 'quiz',
      completionAction: 'done',
    ),
  );
}

GoRouter _gameRouter() {
  return GoRouter(
    initialLocation: '/game/block-puzzle',
    routes: [
      ShellRoute(
        builder: (_, __, child) =>
            MainShell(reportDailyLogin: () async {}, child: child),
        routes: [
          GoRoute(
            path: '/game/block-puzzle',
            builder: (_, __) => const BlockPuzzleScreen(),
          ),
          GoRoute(
            path: '/games/hash',
            builder: (_, __) => const HashGameScreen(),
          ),
          GoRoute(path: '/game/p2p', builder: (_, __) => const P2PGameScreen()),
          GoRoute(
            path: '/games/antiscam',
            builder: (_, __) => const AntiscamScreen(fetchSeed: false),
          ),
          GoRoute(
            path: '/games/approve',
            builder: (_, __) => const ApproveRadarScreen(fetchSeed: false),
          ),
          GoRoute(
            path: '/games/stablecoin',
            builder: (_, __) =>
                const StablecoinScaleScreen(fetchSeed: false),
          ),
          GoRoute(
            path: '/games/custody',
            builder: (_, __) => const KeyCustodyScreen(fetchSeed: false),
          ),
          GoRoute(
            path: '/games/multisig',
            builder: (_, __) => const MultisigDeskScreen(fetchSeed: false),
          ),
          GoRoute(
            path: '/games/listing',
            builder: (_, __) => const ListingDeskScreen(fetchSeed: false),
          ),
        ],
      ),
    ],
  );
}

Widget _app(Widget home) {
  return MaterialApp(home: home);
}

Widget _routerApp(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => WindowLayoutScope(
      sizeClass: HorizontalSizeClass.regular,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpMap(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: const LearnMapSection()),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FailAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return Future.error(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

double _widestContent(WidgetTester tester) {
  var maxWidth = 0.0;
  for (final finder in [
    find.byType(Column),
    find.byType(ListView),
    find.byType(CustomPaint),
  ]) {
    for (final box in tester.renderObjectList<RenderBox>(finder)) {
      if (!box.hasSize) continue;
      if (box.size.width > maxWidth) maxWidth = box.size.width;
    }
  }
  return maxWidth;
}
