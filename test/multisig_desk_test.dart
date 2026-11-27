import 'dart:math';

import 'package:digi_players/core/models/badge.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/games/multisig_desk/multisig_desk_data.dart';
import 'package:digi_players/features/games/multisig_desk/multisig_desk_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(GamesHomeCache.clear);

  test('多签核对台五题，至少对四题通关', () {
    expect(multisigDeskScenarios, hasLength(5));
    expect(multisigDeskPassScore, 4);
    expect(multisigDeskMechanism, contains('单点失窃'));
    for (final scenario in multisigDeskScenarios) {
      expect(scenario.rows, isNotEmpty);
      expect(scenario.answerIndex, lessThan(scenario.options.length));
    }
  });

  test('通关徽章不改路径完成', () {
    final earned = badgesJustEarned(
      practice: 'multisig',
      alreadyDone: false,
      pathComplete: false,
    );
    expect(earned.single.id, 'badge_multisig');
    expect(earned.single.description, contains('界面被骗'));
  });

  testWidgets('答对一题后能看到解析', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MultisigDeskScreen(fetchSeed: false, random: Random(4)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('多签核对台'), findsOneWidget);
    final first = multisigDeskScenarios.first;
    await tester.tap(
      find.widgetWithText(OutlinedButton, first.options[first.answerIndex]),
    );
    await tester.pumpAndSettle();
    expect(find.text('判断正确'), findsOneWidget);
    expect(find.textContaining('设备上显示'), findsOneWidget);
  });

  testWidgets('练习页防骗进阶含多签核对台', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
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
    expect(find.text('防骗进阶'), findsOneWidget);
    expect(find.text('多签核对台'), findsOneWidget);
  });

  testWidgets('可从练习列表进入本关', (tester) async {
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
              path: 'multisig',
              builder: (_, __) =>
                  const MultisigDeskScreen(fetchSeed: false),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('多签核对台'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('多签核对台'));
    await tester.pumpAndSettle();
    expect(find.textContaining('待签摘要'), findsOneWidget);
  });
}
