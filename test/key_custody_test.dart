import 'dart:math';

import 'package:digi_players/core/models/badge.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/games/key_custody/key_custody_data.dart';
import 'package:digi_players/features/games/key_custody/key_custody_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(GamesHomeCache.clear);

  test('钥匙归属：六景加一结局，至少对五题通关', () {
    expect(keyCustodyCards, hasLength(6));
    expect(keyCustodyOutcomes, hasLength(1));
    expect(keyCustodyPassScore, 5);
    expect(keyCustodyMechanism, contains('显示有币'));
    final answers = keyCustodyCards.map((c) => c.answer).toSet();
    expect(answers, containsAll(KeyBucket.values));
  });

  test('通关徽章不改路径完成', () {
    final earned = badgesJustEarned(
      practice: 'custody',
      alreadyDone: false,
      pathComplete: false,
    );
    expect(earned.single.id, 'badge_custody');
    expect(earned.single.description, contains('显示有币'));
  });

  testWidgets('答对一题后能看到解析', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: KeyCustodyScreen(fetchSeed: false, random: Random(3)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('钥匙在谁手里'), findsOneWidget);
    final answer = keyCustodyCards.first.answer;
    await tester.tap(
      find.widgetWithText(OutlinedButton, keyBucketLabel(answer)),
    );
    await tester.pumpAndSettle();
    expect(find.text('判断正确'), findsOneWidget);
    expect(find.textContaining('平台账本'), findsOneWidget);
  });

  testWidgets('练习页列出钥匙在谁手里', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2800));
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
    expect(find.text('钥匙在谁手里'), findsOneWidget);
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
              path: 'custody',
              builder: (_, __) =>
                  const KeyCustodyScreen(fetchSeed: false),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('钥匙在谁手里'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('钥匙在谁手里'));
    await tester.pumpAndSettle();
    expect(find.textContaining('控制权更接近哪一栏'), findsOneWidget);
  });
}
