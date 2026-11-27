import 'dart:math';

import 'package:digi_players/core/models/badge.dart';
import 'package:digi_players/features/games/approve_radar/approve_radar_data.dart';
import 'package:digi_players/features/games/approve_radar/approve_radar_screen.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(GamesHomeCache.clear);

  test('授权雷达五题，至少对四题通关', () {
    expect(approveRadarScenarios, hasLength(5));
    expect(approveRadarPassScore, 4);
    expect(approveRadarMechanism, contains('连接'));
    expect(approveRadarMechanism, contains('授权'));
    for (final scenario in approveRadarScenarios) {
      expect(scenario.options.length, greaterThanOrEqualTo(3));
      expect(scenario.answerIndex, lessThan(scenario.options.length));
      expect(scenario.analysis, isNotEmpty);
    }
  });

  test('第一次通关给出授权守门人徽章，不改路径完成', () {
    final earned = badgesJustEarned(
      practice: 'approve',
      alreadyDone: false,
      pathComplete: false,
    );
    expect(earned.map((b) => b.id), ['badge_approve']);
    expect(earned.single.description, contains('连接不等于授权'));

    final ids = unlockedBadgeIdsFromProgress(
      hasDid: true,
      chapter1: true,
      chapter2: true,
      block: true,
      hash: true,
      p2p: true,
      antiscam: true,
      approve: true,
    );
    expect(ids, contains('badge_approve'));
    expect(ids, contains(pathCompleteBadgeId));
  });

  testWidgets('答对一题后能看到解析与机制句', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ApproveRadarScreen(
          fetchSeed: false,
          random: Random(1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('授权雷达'), findsOneWidget);
    expect(find.text('app.uniswap.org'), findsOneWidget);

    final first = approveRadarScenarios.first;
    await tester.tap(find.text(first.options[first.answerIndex]));
    await tester.pumpAndSettle();
    expect(find.text('判断正确'), findsOneWidget);
    expect(find.textContaining('连接'), findsWidgets);
  });

  testWidgets('练习页分区含授权雷达，需第二节解锁', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GamesHomeScreen(
          loadProgress: () async => (
            chapters: <String>{'ch_001'},
            games: <String>{},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('机制'), findsOneWidget);
    expect(find.text('用链时'), findsOneWidget);
    expect(find.text('防骗进阶'), findsOneWidget);
    expect(find.text('授权雷达'), findsOneWidget);

    final approve = find.ancestor(
      of: find.text('授权雷达'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: approve, matching: find.textContaining('后解锁')),
      findsOneWidget,
    );
  });

  testWidgets('第二节完成后可进入授权雷达', (tester) async {
    final router = GoRouter(
      initialLocation: '/games',
      routes: [
        GoRoute(
          path: '/games',
          builder: (_, __) => GamesHomeScreen(
            loadProgress: () async => (
              chapters: <String>{'ch_001', 'ch_002'},
              games: <String>{},
            ),
          ),
          routes: [
            GoRoute(
              path: 'approve',
              builder: (_, __) => const ApproveRadarScreen(fetchSeed: false),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('授权雷达'));
    await tester.pumpAndSettle();
    expect(find.textContaining('钱包弹出了'), findsOneWidget);
  });
}
