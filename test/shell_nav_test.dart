import 'package:digi_players/core/display_name.dart';
import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:flutter/material.dart';
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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.getTopLeft(find.text('学习')).dy, greaterThan(400));

    router.go('/profile');
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    router.go('/square');
    await tester.pump();
    await tester.pump();
    expect(find.text('square-body'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('底栏只出现在学习、练习、我的三个主页面', () {
    expect(showsMainNavigation('/learn'), isTrue);
    expect(showsMainNavigation('/games'), isTrue);
    expect(showsMainNavigation('/profile'), isTrue);
    expect(showsMainNavigation('/settings'), isFalse);
    expect(showsMainNavigation('/settings/language'), isFalse);
    expect(showsMainNavigation('/square'), isFalse);
    expect(showsMainNavigation('/learn/chapter/ch_001'), isFalse);
    expect(showsMainNavigation('/games/hash'), isFalse);
    expect(showsMainNavigation('/game/block-puzzle'), isFalse);
  });

  testWidgets('外屏横屏宽 678 仍是底栏', (tester) async {
    await _pumpShell(
      tester,
      surface: const Size(678, 466),
      sizeClass: HorizontalSizeClass.compact,
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
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

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);

    await tester.tap(find.text('练习'));
    await tester.pump();
    await tester.pump();
    expect(find.text('games-body'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
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
      tester.getTopLeft(find.byType(NavigationBar)).dx,
      greaterThanOrEqualTo(40),
    );

    await _pumpShell(
      tester,
      surface: const Size(820, 1180),
      sizeClass: HorizontalSizeClass.regular,
      paddingLeft: 40,
    );
    expect(
      tester.getTopLeft(find.byType(NavigationRail)).dx,
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
