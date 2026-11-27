import 'package:digi_players/core/display_name.dart';
import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('空昵称显示数字游民，有昵称就用昵称', () {
    expect(displayNameOrFallback(null), '数字游民');
    expect(displayNameOrFallback('  '), '数字游民');
    expect(displayNameOrFallback(' 小林 '), '小林');
  });

  testWidgets('底栏只有学习、练习、我的', (tester) async {
    final router = await _pumpShell(
      tester,
      surface: const Size(400, 800),
      sizeClass: HorizontalSizeClass.unspecified,
    );

    expect(find.text('学习'), findsOneWidget);
    expect(find.text('练习'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('游戏'), findsNothing);
    expect(find.text('广场'), findsNothing);
    expect(find.byKey(const Key('main-bottom-bar')), findsOneWidget);
    expect(find.byKey(const Key('main-rail')), findsNothing);
    expect(tester.getTopLeft(find.text('学习')).dy, greaterThan(400));

    router.go('/profile');
    await tester.pump();
    await tester.pump();
    expect(find.text('profile-body'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('我的')).hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );

    router.go('/square');
    await tester.pump();
    await tester.pump();
    expect(find.text('square-body'), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-bar')), findsNothing);
  });

  test('底栏只出现在学习、练习、我的三个主页面', () {
    expect(showsMainNavigation('/learn'), isTrue);
    expect(showsMainNavigation('/games'), isTrue);
    expect(showsMainNavigation('/profile'), isTrue);
    expect(showsMainNavigation('/profile/points'), isFalse);
    expect(showsMainNavigation('/settings'), isFalse);
    expect(showsMainNavigation('/settings/language'), isFalse);
    expect(showsMainNavigation('/square'), isFalse);
    expect(showsMainNavigation('/learn/chapter/ch_001'), isFalse);
    expect(showsMainNavigation('/games/hash'), isFalse);
    expect(showsMainNavigation('/games/approve'), isFalse);
    expect(showsMainNavigation('/games/stablecoin'), isFalse);
    expect(showsMainNavigation('/games/custody'), isFalse);
    expect(showsMainNavigation('/games/multisig'), isFalse);
    expect(showsMainNavigation('/games/listing'), isFalse);
    expect(showsMainNavigation('/game/block-puzzle'), isFalse);
  });

  test('资料、广场、设置宽屏都藏侧栏，只留两栏', () {
    expect(hidesMainRail('/settings'), isTrue);
    expect(hidesMainRail('/settings/nickname'), isTrue);
    expect(hidesMainRail('/learn/library'), isTrue);
    expect(hidesMainRail('/learn/library/ledger'), isTrue);
    expect(hidesMainRail('/square'), isTrue);
    expect(hidesMainRail('/square/chat/blockchain'), isTrue);
    expect(hidesMainRail('/learn'), isFalse);
    expect(hidesMainRail('/games'), isFalse);
    expect(hidesMainRail('/profile'), isFalse);
  });

  testWidgets('外屏横屏宽 678 仍是底栏', (tester) async {
    await _pumpShell(
      tester,
      surface: const Size(678, 466),
      sizeClass: HorizontalSizeClass.compact,
    );

    expect(find.byKey(const Key('main-bottom-bar')), findsOneWidget);
    expect(find.byKey(const Key('main-rail')), findsNothing);
    expect(find.text('学习'), findsOneWidget);
    expect(find.text('练习'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('宽窗口用侧栏，点练习进入练习页', (tester) async {
    await _pumpShell(
      tester,
      surface: const Size(820, 1180),
      sizeClass: HorizontalSizeClass.regular,
    );

    expect(find.byKey(const Key('main-rail')), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-bar')), findsNothing);
    expect(tester.getSize(find.byKey(const Key('main-rail'))).width, 80);

    await tester.tap(find.text('练习'));
    await tester.pump();
    await tester.pump();
    expect(find.text('games-body'), findsOneWidget);
    final selected = tester.widget<Material>(
      find
          .ancestor(of: find.text('练习'), matching: find.byType(Material))
          .first,
    );
    expect(
      selected.color,
      Theme.of(tester.element(find.text('练习'))).colorScheme.primaryContainer,
    );

    final before = tester.getTopLeft(find.byKey(const Key('rail-menu')));
    expect(
      before.dx,
      closeTo(tester.getTopLeft(find.byKey(const Key('main-rail'))).dx, 8),
    );
    await tester.tap(find.byKey(const Key('rail-menu')));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('main-rail'))).width, 200);
    expect(
      tester.getTopLeft(find.byKey(const Key('rail-menu'))).dx,
      closeTo(before.dx, 1),
    );
    expect(find.text('学习'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rail-menu')));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('main-rail'))).width, 80);
  });

  testWidgets('左右安全区垫在底栏和侧栏外侧', (tester) async {
    await _pumpShell(
      tester,
      surface: const Size(400, 800),
      sizeClass: HorizontalSizeClass.unspecified,
      paddingLeft: 40,
    );
    expect(tester.getTopLeft(find.text('学习')).dx, greaterThanOrEqualTo(40));
    expect(
      tester.getTopLeft(find.byKey(const Key('main-bottom-bar'))).dx,
      greaterThanOrEqualTo(40),
    );

    await _pumpShell(
      tester,
      surface: const Size(820, 1180),
      sizeClass: HorizontalSizeClass.regular,
      paddingLeft: 40,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('main-rail'))).dx,
      greaterThanOrEqualTo(40),
    );
  });
}

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  required Size surface,
  required HorizontalSizeClass sizeClass,
  double paddingLeft = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surface;
  tester.view.padding = FakeViewPadding(left: paddingLeft);
  tester.view.viewPadding = FakeViewPadding(left: paddingLeft);
  addTearDown(() {
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    initialLocation: '/learn',
    routes: [
      ShellRoute(
        builder: (_, __, child) =>
            MainShell(reportDailyLogin: () async {}, child: child),
        routes: [
          GoRoute(path: '/learn', builder: (_, __) => const Text('learn-body')),
          GoRoute(path: '/games', builder: (_, __) => const Text('games-body')),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Text('profile-body'),
          ),
          GoRoute(
            path: '/square',
            builder: (_, __) => const Text('square-body'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) {
        return WindowLayoutScope(
          sizeClass: sizeClass,
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
  await tester.pump();
  return router;
}
