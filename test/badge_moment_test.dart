import 'package:digi_players/core/models/badge.dart';
import 'package:digi_players/features/games/earned_badge_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('徽章说明都写成弄懂了哪个机制', () {
    expect(
      allBadges.every((badge) => badge.description.startsWith('你弄懂了')),
      isTrue,
    );
  });

  test('第一次通关才展示练习徽章，补齐六步时连同路径完成', () {
    final first = badgesJustEarned(
      practice: 'block',
      alreadyDone: false,
      pathComplete: false,
    );
    expect(first.map((badge) => badge.name), ['链式思维者']);
    expect(first.single.description, contains('后面的链接就对不上'));

    final again = badgesJustEarned(
      practice: 'block',
      alreadyDone: true,
      pathComplete: true,
    );
    expect(again, isEmpty);

    final finished = badgesJustEarned(
      practice: 'antiscam',
      alreadyDone: false,
      pathComplete: true,
    );
    expect(finished.map((badge) => badge.name), ['反诈达人', '路径完成']);
  });

  testWidgets('结算页能展示刚获得的徽章说明', (tester) async {
    final badges = badgesJustEarned(
      practice: 'hash',
      alreadyDone: false,
      pathComplete: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EarnedBadgeNote(badges: badges)),
      ),
    );
    expect(find.text('获得「挖矿体验者」'), findsOneWidget);
    expect(find.textContaining('零越多，就越难'), findsOneWidget);
  });
}
