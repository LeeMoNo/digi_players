import 'dart:math';

import 'package:digi_players/core/models/badge.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/games/listing_desk/listing_desk_data.dart';
import 'package:digi_players/features/games/listing_desk/listing_desk_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(GamesHomeCache.clear);

  test('牌照与上下架五题，含宣传与下架两类，至少对四题通关', () {
    expect(listingDeskScenarios, hasLength(5));
    expect(listingDeskPassScore, 4);
    expect(listingDeskMechanism, contains('流动性'));
    expect(
      listingDeskScenarios.where((s) => s.kind == ListingDeskKind.promo),
      hasLength(4),
    );
    expect(
      listingDeskScenarios.where((s) => s.kind == ListingDeskKind.action),
      hasLength(1),
    );
  });

  test('通关徽章不改路径完成', () {
    final earned = badgesJustEarned(
      practice: 'listing',
      alreadyDone: false,
      pathComplete: false,
    );
    expect(earned.single.id, 'badge_listing');
    expect(earned.single.description, contains('所在地法'));
  });

  testWidgets('答对一题后能看到解析', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ListingDeskScreen(fetchSeed: false, random: Random(5)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('牌照与上下架'), findsOneWidget);
    expect(find.text('宣传语核对'), findsOneWidget);
    final first = listingDeskScenarios.first;
    await tester.tap(
      find.widgetWithText(OutlinedButton, first.options[first.answerIndex]),
    );
    await tester.pumpAndSettle();
    expect(find.text('判断正确'), findsOneWidget);
    expect(find.textContaining('持牌'), findsOneWidget);
    expect(find.textContaining('所在地'), findsOneWidget);
  });

  testWidgets('练习页防骗进阶含本关', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3600));
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
    expect(find.text('牌照与上下架'), findsOneWidget);
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
              path: 'listing',
              builder: (_, __) =>
                  const ListingDeskScreen(fetchSeed: false),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('牌照与上下架'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('牌照与上下架'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MiCA'), findsOneWidget);
  });
}
