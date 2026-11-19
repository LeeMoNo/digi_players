import 'package:digi_players/features/home/daily_task_card.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:digi_players/features/learn/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只完成第一节时，下一步是区块链拼图', () {
    const progress = LearnPathProgress(chapter1: true);
    final step = nextLearnStep(progress);

    expect(step.title, '练习 · 区块链拼图');
    expect(step.button, '去做练习');
    expect(step.route, '/game/block-puzzle');
    expect(step.title.contains('密码学'), isFalse);
  });

  test('六步都完成时，下一步去资料', () {
    const progress = LearnPathProgress(
      chapter1: true,
      block: true,
      hash: true,
      p2p: true,
      chapter2: true,
      antiscam: true,
    );
    final step = nextLearnStep(progress);

    expect(step.title, '这条路径走完了');
    expect(step.button, '去资料里看年史和骗局');
    expect(step.route, '/learn/library');
  });

  test('未开始时下一步是第一节', () {
    final step = nextLearnStep(const LearnPathProgress());
    expect(step.title, '第一节 · 共有的账本');
    expect(step.route, '/learn/chapter/ch_001');
  });

  testWidgets('首页第一眼是继续卡，年史和术语不在首页', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LearnHomeScreen(
          loadProgress: () async => const LearnPathProgress(chapter1: true),
          loadChapters: () async {},
          dailyTask: DailyTaskCard(loader: () async => null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('练习 · 区块链拼图'), findsWidgets);
    expect(find.text('去做练习'), findsOneWidget);
    expect(find.text('加密货币发展年史'), findsNothing);
    expect(find.text('概念速查'), findsNothing);
    expect(find.text('今天的题暂时取不到'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('资料'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('learn-home-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('资料'), findsOneWidget);
  });

  testWidgets('章节拉取失败时继续卡可以重试，每日题仍占位', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LearnHomeScreen(
          loadProgress: () async => const LearnPathProgress(),
          loadChapters: () async => throw Exception('offline'),
          dailyTask: DailyTaskCard(loader: () async => null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('章节暂时取不到'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('今天的题暂时取不到'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('资料页按时间列出小节，外链仍在', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 8000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1998–2009 · 共有的账本'), findsOneWidget);
    expect(find.text('2014 · 稳定币为什么看起来像美元'), findsOneWidget);
    expect(find.text('比特币（中文）'), findsOneWidget);
    expect(find.text('加密货币发展年史'), findsNothing);
  });
}
