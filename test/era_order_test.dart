import 'package:digi_players/features/home/data/home_content.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:digi_players/features/learn/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('资料按出现时间排列，稳定币与近年风险各有专节正文', () {
    final eras = HomeContent.eraSections;
    final ids = eras.map((era) => era.id).toList();
    expect(ids, [
      'ledger',
      'work',
      'broadcast',
      'other_chains',
      'custody',
      'stablecoin',
      'contracts',
      'new_coins',
      'custody_returns',
      'recent_risks',
    ]);
    for (var i = 1; i < eras.length; i++) {
      expect(eras[i].sortYear, greaterThanOrEqualTo(eras[i - 1].sortYear));
    }
    expect(eras.where((era) => era.stablecoin), hasLength(1));
    for (final era in eras) {
      expect(era.paragraphs, isNotEmpty, reason: era.id);
    }
    expect(HomeContent.stablecoinParagraphs.join(), contains('锚定'));
    expect(HomeContent.stablecoinParagraphs.join(), contains('储备'));
    expect(HomeContent.stablecoinParagraphs.join(), contains('脱锚'));
    expect(HomeContent.recentRiskParagraphs.join(), contains('币安'));
    expect(HomeContent.recentRiskParagraphs.join(), contains('63 亿'));
    expect(HomeContent.recentRiskParagraphs.join(), contains('MiCA'));
    expect(HomeContent.recentRiskParagraphs.join(), contains('下架'));
  });

  test('原有年史、术语、流程、骗局和清单都挂进了某一节', () {
    final coveredYears = {
      for (final era in HomeContent.eraSections) ...era.eventYearMonths,
    };
    final coveredTerms = {
      for (final era in HomeContent.eraSections) ...era.glossaryTerms,
    };
    final coveredFlows = {
      for (final era in HomeContent.eraSections) ...era.flowTitles,
    };
    final coveredScams = {
      for (final era in HomeContent.eraSections) ...era.scamIds,
    };
    final coveredChecks = {
      for (final era in HomeContent.eraSections) ...era.checklistIds,
    };

    expect(
      coveredYears,
      HomeContent.timelineEvents.map((event) => event.yearMonth).toSet(),
    );
    expect(
      coveredTerms,
      HomeContent.glossaryTerms.map((term) => term.term).toSet(),
    );
    expect(
      coveredFlows,
      HomeContent.flowOverviews.map((flow) => flow.title).toSet(),
    );
    expect(
      coveredScams,
      HomeContent.fraudScamPatterns.map((scam) => scam.id).toSet(),
    );
    expect(
      coveredChecks,
      HomeContent.fraudChecklist.map((item) => item.id).toSet(),
    );
  });

  test('路径上的相关资料指向对应的时间小节，不改课和练习本身', () {
    final catalog = learnCatalog(const LearnPathProgress());
    expect(catalog.map((item) => item.readingEraId).toList(), [
      'ledger',
      'ledger',
      'work',
      'broadcast',
      'custody',
      'new_coins',
    ]);
    expect(catalog.first.route, '/learn/chapter/ch_001');
    expect(catalog[1].route, '/game/block-puzzle');
  });

  testWidgets('稳定币一节写清锚定、储备和脱锚', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'stablecoin')),
    );
    expect(find.textContaining('锚定是一个承诺'), findsOneWidget);
    expect(find.textContaining('储备是这个承诺'), findsOneWidget);
    expect(find.textContaining('脱锚是这个承诺'), findsOneWidget);
  });

  testWidgets('共有账本一节仍能看到创世块和区块', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'ledger')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('比特币创世块挖出'), findsOneWidget);
    expect(find.textContaining('区块：'), findsOneWidget);
    expect(find.textContaining('不代替那一节课或练习'), findsOneWidget);
    expect(find.textContaining('共有账本'), findsWidgets);
    expect(find.textContaining('前一块哈希'), findsWidgets);
    expect(find.textContaining('前一块哈希。改旧交易'), findsOneWidget);
  });

  testWidgets('2024 年前小节有导读，事件与概念带相关说明', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final id in [
      'work',
      'broadcast',
      'other_chains',
      'custody',
      'contracts',
      'custody_returns',
    ]) {
      final era = HomeContent.eraById(id)!;
      expect(era.paragraphs, isNotEmpty, reason: id);
    }

    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'custody')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Not your keys'), findsOneWidget);
    expect(find.textContaining('Mt.Gox'), findsWidgets);
    expect(
      find.textContaining('账户里显示有币'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'work')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('工作量证明'), findsWidgets);
    expect(find.textContaining('猜哈希'), findsOneWidget);
  });

  testWidgets('2025–2026 节覆盖币安大案、牌照与上下架', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'recent_risks')),
    );
    await tester.pumpAndSettle();

    expect(find.text('最大所、牌照与上下架'), findsOneWidget);
    expect(find.textContaining('Bybit'), findsWidgets);
    expect(find.textContaining('币安'), findsWidgets);
    expect(find.textContaining('63 亿'), findsWidgets);
    expect(find.textContaining('MiCA'), findsWidgets);
    expect(find.textContaining('上新更挑'), findsOneWidget);
    expect(find.textContaining('假招聘'), findsOneWidget);
    expect(find.textContaining('大型交易所被盗后，几件事要分开看'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('选交易所先看牌照与法域'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('山寨币随时可能被下架'), findsOneWidget);
  });
}
