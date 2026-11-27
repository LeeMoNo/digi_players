import 'dart:math';

import 'package:digi_players/core/models/badge.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/games/stablecoin_scale/stablecoin_scale_data.dart';
import 'package:digi_players/features/games/stablecoin_scale/stablecoin_scale_logic.dart';
import 'package:digi_players/features/games/stablecoin_scale/stablecoin_scale_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(GamesHomeCache.clear);

  test('天平读数：安全垫够且压力低为锚定，风险过重脱锚，挤兑先伤兑付', () {
    expect(
      const PegSnapshot(
        cash: 50,
        treasury: 40,
        risk: 10,
        pressure: 20,
      ).reading,
      PegReading.anchored,
    );
    expect(
      const PegSnapshot(
        cash: 10,
        treasury: 10,
        risk: 80,
        pressure: 70,
      ).reading,
      PegReading.depegged,
    );
    expect(
      const PegSnapshot(
        cash: 40,
        treasury: 40,
        risk: 20,
        pressure: 90,
      ).reading,
      PegReading.redeemStress,
    );
    expect(stablecoinBoards, hasLength(3));
    expect(stablecoinNewsCards, hasLength(2));
    expect(stablecoinScalePassScore, 4);
    expect(stablecoinScaleMechanism, contains('锚定'));
  });

  test('通关徽章不改路径完成', () {
    final earned = badgesJustEarned(
      practice: 'stablecoin',
      alreadyDone: false,
      pathComplete: false,
    );
    expect(earned.single.id, 'badge_stablecoin');
    expect(earned.single.description, contains('储备'));
  });

  testWidgets('实验未稳住时点提交会提示', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: StablecoinScaleScreen(fetchSeed: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('稳定币天平'), findsOneWidget);
    await tester.tap(find.text('我认为能守住锚定 →'));
    await tester.pumpAndSettle();
    expect(find.textContaining('还没稳住'), findsOneWidget);
  });

  testWidgets('拨稳天平后进入问答，答对可见解析', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: StablecoinScaleScreen(
          fetchSeed: false,
          startInQuiz: true,
          random: Random(2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('盘面 A'), findsOneWidget);
    final board = stablecoinBoards.first;
    await tester.tap(
      find.widgetWithText(OutlinedButton, board.options[board.answerIndex]),
    );
    await tester.pumpAndSettle();
    expect(find.text('判断正确'), findsOneWidget);
    expect(find.textContaining('安全储备'), findsOneWidget);
  });

  testWidgets('练习页列出稳定币天平', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GamesHomeScreen(
          loadProgress: () async => (
            chapters: <String>{'ch_002'},
            games: <String>{},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('稳定币天平'), findsOneWidget);
  });

  testWidgets('可从练习列表进入稳定币天平', (tester) async {
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
              path: 'stablecoin',
              builder: (_, __) =>
                  const StablecoinScaleScreen(fetchSeed: false),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('稳定币天平'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('稳定币天平'));
    await tester.pumpAndSettle();
    expect(find.textContaining('实验'), findsWidgets);
  });
}
