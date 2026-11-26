import 'package:digi_players/features/home/data/home_content.dart';
import 'package:digi_players/features/learn/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('稳赚、内幕、保本同时是两种话术', () {
    expect(HomeContent.rhetoricPhrases, ['稳赚', '内幕', '保本']);
    expect(HomeContent.rhetoricLabels, ['赌博话术', '诈骗话术']);
    expect(
      HomeContent.fraudChecklist
          .firstWhere((item) => item.id == 'investment')
          .detail,
      contains('既是赌博话术，也是诈骗话术'),
    );
  });

  test('山寨币高峰写明间歇性奖励和追涨', () {
    final peak = HomeContent.shitcoinLifecycleSteps
        .firstWhere((step) => step.startsWith('高峰'));
    expect(peak, contains('间歇性奖励'));
    expect(peak, contains('追涨'));
    expect(HomeContent.anotherBetLine, '再来一笔改变不了已经发生的亏损');
    expect(HomeContent.anotherBetLine.contains('治愈'), isFalse);
  });

  testWidgets('提醒只出现在新币一节，其他资料没有', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'new_coins')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('间歇性奖励'), findsOneWidget);
    expect(find.text('「稳赚」：赌博话术 · 诈骗话术'), findsOneWidget);
    expect(find.text('「内幕」：赌博话术 · 诈骗话术'), findsOneWidget);
    expect(find.text('「保本」：赌博话术 · 诈骗话术'), findsOneWidget);
    expect(find.textContaining('治愈赌瘾'), findsNothing);

    final note = find.text(HomeContent.anotherBetLine);
    await tester.scrollUntilVisible(note, 200);
    await tester.pumpAndSettle();
    expect(note, findsOneWidget);
    expect(find.textContaining('回到「'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'stablecoin')),
    );
    await tester.pumpAndSettle();
    expect(find.text(HomeContent.anotherBetLine), findsNothing);
  });
}
