import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/core/router/app_router.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:digi_players/features/learn/library_screen.dart';
import 'package:digi_players/features/learn/library_split.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _ledger = '1998–2009 · 共有的账本';
const _work = '2009 · 为什么要花算力';

void main() {
  testWidgets('单独打开资料页仍是目录', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    await tester.pump();

    expect(find.text(_ledger), findsOneWidget);
    expect(find.text('选一节资料'), findsNothing);
    expect(find.byKey(const Key('main-rail')), findsNothing);
  });

  testWidgets('窄窗口整页进入资料，相关资料返回学习首页', (tester) async {
    await _surface(tester, const Size(400, 800));
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.unspecified));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_ledger));
    await tester.pumpAndSettle();
    expect(find.text(_ledger), findsNothing);
    expect(find.text('共有的账本'), findsOneWidget);
    expect(find.text('选一节资料'), findsNothing);

    await _pop(tester);
    expect(find.text(_ledger), findsOneWidget);
    expect(find.text('按概念出现的时间'), findsOneWidget);

    router.go('/learn');
    await tester.pumpAndSettle();
    final related = find.text('相关资料 · 共有的账本').at(0);
    await tester.ensureVisible(related);
    await tester.pumpAndSettle();
    await tester.tap(related);
    await tester.pumpAndSettle();
    expect(find.text('共有的账本'), findsOneWidget);
    expect(find.text('按概念出现的时间'), findsNothing);

    await _pop(tester);
    expect(router.routeInformationProvider.value.uri.path, '/learn');
    expect(find.text('第一节 · 共有的账本'), findsWidgets);
    expect(find.text('按概念出现的时间'), findsNothing);
  });

  testWidgets('可双栏时左目录右正文，返回只退一层', (tester) async {
    await _surface(tester, const Size(820, 1180));
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-rail')), findsNothing);
    expect(find.text('共有的账本'), findsOneWidget);
    expect(find.text(_ledger), findsOneWidget);
    expect(_tile(tester, _ledger).selected, isTrue);
    final listWidth = tester
        .getSize(find.byKey(const Key('library-scroll')))
        .width;
    expect(listWidth, closeTo(WindowLayout.evenPaneWidth(820), 1));

    await tester.tap(find.text(_work));
    await tester.pumpAndSettle();
    expect(find.text('为什么要花算力'), findsOneWidget);
    expect(_tile(tester, _work).selected, isTrue);
    expect(_tile(tester, _ledger).selected, isFalse);

    await _pop(tester);
    expect(find.text('为什么要花算力'), findsNothing);
    expect(find.text('共有的账本'), findsOneWidget);
    expect(_tile(tester, _ledger).selected, isTrue);
  });

  testWidgets('669 宽且没有安全区时仍是左右栏', (tester) async {
    await _surface(tester, const Size(669, 951));
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-rail')), findsNothing);
    expect(find.text('共有的账本'), findsOneWidget);
    expect(find.text(_ledger), findsOneWidget);
    expect(_tile(tester, _ledger).selected, isTrue);
  });

  testWidgets('安全区扣掉后不够宽时只有单栏', (tester) async {
    // 无侧栏时：可用宽 − 240 < 320 才退回单栏（669 − 120 = 549）。
    await _surface(tester, const Size(669, 951), left: 60, right: 60);
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-rail')), findsNothing);
    expect(find.text('选一节资料'), findsNothing);
    await tester.tap(find.text(_ledger));
    await tester.pumpAndSettle();
    expect(find.text(_ledger), findsNothing);
    expect(find.text('共有的账本'), findsOneWidget);
  });

  testWidgets('外屏横屏整页进入资料', (tester) async {
    await _surface(tester, const Size(678, 466));
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.compact));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('选一节资料'), findsNothing);
    await tester.tap(find.text(_ledger));
    await tester.pumpAndSettle();
    expect(find.text(_ledger), findsNothing);
    expect(find.text('共有的账本'), findsOneWidget);
  });

  testWidgets('警防诈骗仍是独立一页', (tester) async {
    await _surface(tester, const Size(820, 1180));
    final router = createAppRouter(initialLocation: '/learn/library');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, HorizontalSizeClass.regular));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('警防诈骗全文'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('library-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('警防诈骗全文'));
    await tester.pumpAndSettle();

    expect(find.text('安全清单'), findsOneWidget);
    expect(find.text('按概念出现的时间'), findsNothing);
    expect(find.text('选一节资料'), findsNothing);
  });
}

ListTile _tile(WidgetTester tester, String title) {
  return tester.widget<ListTile>(find.widgetWithText(ListTile, title));
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/learn/library',
    routes: [
      ShellRoute(
        builder: (_, __, child) =>
            MainShell(reportDailyLogin: () async {}, child: child),
        routes: [
          GoRoute(
            path: '/learn',
            builder: (_, __) => LearnHomeScreen(
              loadProgress: () async => const LearnPathProgress(),
              loadChapters: () async {},
              dailyTask: const SizedBox.shrink(),
            ),
            routes: [
              ShellRoute(
                builder: (_, __, child) => LibrarySplitShell(child: child),
                routes: [
                  GoRoute(
                    path: 'library',
                    builder: (_, __) => const LibraryRoute(),
                  ),
                  GoRoute(
                    path: 'library/:eraId',
                    builder: (_, state) =>
                        EraDetailScreen(eraId: state.pathParameters['eraId']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _app(GoRouter router, HorizontalSizeClass sizeClass) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => WindowLayoutScope(
      sizeClass: sizeClass,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

Future<void> _surface(
  WidgetTester tester,
  Size size, {
  double left = 0,
  double right = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(left: left, right: right);
  tester.view.viewPadding = FakeViewPadding(left: left, right: right);
  addTearDown(() {
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pop(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).pop();
  await tester.pumpAndSettle();
}
