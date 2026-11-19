import 'package:digi_players/features/home/data/home_content.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:digi_players/features/learn/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('资料按出现时间排列，且只新写了稳定币', () {
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
    ]);
    for (var i = 1; i < eras.length; i++) {
      expect(eras[i].sortYear, greaterThanOrEqualTo(eras[i - 1].sortYear));
    }
    expect(eras.where((era) => era.stablecoin), hasLength(1));
    expect(HomeContent.stablecoinParagraphs.join(), contains('锚定'));
    expect(HomeContent.stablecoinParagraphs.join(), contains('储备'));
    expect(HomeContent.stablecoinParagraphs.join(), contains('脱锚'));
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
    await tester.pumpWidget(
      const MaterialApp(home: EraDetailScreen(eraId: 'ledger')),
    );
    expect(find.textContaining('比特币创世块挖出'), findsOneWidget);
    expect(find.textContaining('区块：'), findsOneWidget);
    expect(find.textContaining('不代替那一节课或练习'), findsOneWidget);
  });
}
