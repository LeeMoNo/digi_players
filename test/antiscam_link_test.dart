import 'package:digi_players/features/games/antiscam_game/antiscam_data.dart';
import 'package:digi_players/features/games/antiscam_game/antiscam_screen.dart';
import 'package:digi_players/features/home/data/home_content.dart';
import 'package:digi_players/features/home/fraud_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('判断题里的诈骗能链到已有骗局，正常公告不链', () {
    final linked = antiscamQuestions.where((q) => q.isScam);
    expect(linked.every((q) => scamPageTitle(q) != null), isTrue);
    expect(
      antiscamQuestions.where((q) => !q.isScam).every((q) => q.scamId == null),
      isTrue,
    );
    expect(scamPageTitle(antiscamQuestions.first), '冒充官方 / 名人');
  });

  test('三道选择用假空投、杀猪盘和付费解冻的原有条目', () {
    expect(antiscamChoiceQuestions.map((q) => q.scamId).toList(), [
      'fake_airdrop',
      'pig_butchering',
      'impersonation',
    ]);
    expect(antiscamChoiceQuestions.every((q) => q.isChoice), isTrue);
    expect(antiscamChoiceQuestions.last.scenario, contains('付费解冻'));
    expect(scamPageTitle(antiscamChoiceQuestions.last), '付费解冻');

    for (final question in antiscamChoiceQuestions) {
      final scam = HomeContent.scamById(question.scamId!)!;
      expect(question.answerIndex, question.options.length - 1);
      expect(question.options.last, '以上都不点');
      expect(question.options.take(scam.signals.length), scam.signals);
      expect(question.analysis, scam.detail);
    }

    expect(antiscamAllQuestions.length, 13);
    expect(antiscamPassScore, 9);
  });

  test('结算页复习入口覆盖三则不同骗局', () {
    expect(antiscamReviewLinks.map((l) => l.scamId).toList(), [
      'fake_airdrop',
      'pig_butchering',
      'impersonation',
    ]);
    expect(antiscamReviewLinks.map((l) => l.label).toList(), [
      '假空投',
      '杀猪盘',
      '付费解冻',
    ]);
    for (final link in antiscamReviewLinks) {
      expect(HomeContent.scamById(link.scamId), isNotNull);
    }
  });

  testWidgets('答完诈骗判断题后出现对应骗局入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AntiscamScreen(fetchSeed: false)),
    );

    await tester.tap(find.text('这是诈骗！'));
    await tester.pump();

    expect(find.text('查看「冒充官方 / 名人」'), findsOneWidget);
  });

  testWidgets('链到骗局页再返回，答题进度还在', (tester) async {
    final router = GoRouter(
      initialLocation: '/games/antiscam',
      routes: [
        GoRoute(
          path: '/games/antiscam',
          builder: (_, __) => const AntiscamScreen(fetchSeed: false),
        ),
        GoRoute(
          path: '/learn/fraud',
          builder: (context, state) => fraudScreenFromState(state),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('这是诈骗！'));
    await tester.pump();
    expect(find.text('判断正确'), findsOneWidget);

    await tester.tap(find.text('查看「冒充官方 / 名人」'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '警防诈骗'), findsOneWidget);
    expect(find.text('冒充官方 / 名人'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('判断正确'), findsOneWidget);
    expect(find.text('正确：1  |  剩余：13 题'), findsOneWidget);
    expect(find.text('下一题 →'), findsOneWidget);
  });

  testWidgets('结算页能打开三则不同骗局说明', (tester) async {
    final router = GoRouter(
      initialLocation: '/games/antiscam',
      routes: [
        GoRoute(
          path: '/games/antiscam',
          builder: (_, __) => AntiscamScreen(
            fetchSeed: false,
            initialIndex: antiscamAllQuestions.length - 1,
          ),
        ),
        GoRoute(
          path: '/learn/fraud',
          builder: (context, state) => fraudScreenFromState(state),
        ),
        GoRoute(path: '/learn', builder: (_, __) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // 最后一题是付费解冻选择，点「以上都不点」
    await tester.tap(find.text('以上都不点'));
    await tester.pump();
    await tester.tap(find.text('查看结果'));
    await tester.pumpAndSettle();

    expect(find.text('复习这些骗局说明'), findsOneWidget);

    for (final link in antiscamReviewLinks) {
      await tester.tap(find.byKey(Key('review-scam-${link.scamId}')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, '警防诈骗'), findsOneWidget);
      final scam = HomeContent.scamById(link.scamId)!;
      expect(find.text(scam.title), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('复习这些骗局说明'), findsOneWidget);
    }
  });
}
