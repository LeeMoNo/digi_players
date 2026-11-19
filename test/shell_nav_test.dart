import 'package:digi_players/core/display_name.dart';
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
    final router = GoRouter(
      initialLocation: '/learn',
      routes: [
        ShellRoute(
          builder: (_, __, child) => MainShell(
            reportDailyLogin: () async {},
            child: child,
          ),
          routes: [
            GoRoute(path: '/learn', builder: (_, __) => const Text('learn-body')),
            GoRoute(path: '/games', builder: (_, __) => const Text('games-body')),
            GoRoute(path: '/profile', builder: (_, __) => const Text('profile-body')),
            GoRoute(path: '/square', builder: (_, __) => const Text('square-body')),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('学习'), findsOneWidget);
    expect(find.text('练习'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('游戏'), findsNothing);
    expect(find.text('广场'), findsNothing);

    router.go('/square');
    await tester.pump();
    await tester.pump();
    expect(find.text('square-body'), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });
}
