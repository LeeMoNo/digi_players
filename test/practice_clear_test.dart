import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(GamesHomeCache.clear);

  test('拼图通关后去做哈希碰碰乐', () {
    final step = practiceClearDestination(
      practice: 'block',
      progress: const LearnPathProgress(),
    );
    expect(step.button, '去做哈希碰碰乐');
    expect(step.route, '/games/hash');
  });

  test('哈希通关后去做 P2P', () {
    final step = practiceClearDestination(
      practice: 'hash',
      progress: const LearnPathProgress(),
    );
    expect(step.button, '去做 P2P 节点模拟器');
    expect(step.route, '/game/p2p');
  });

  test('第一节还没完成时，P2P 回到学习页', () {
    final step = practiceClearDestination(
      practice: 'p2p',
      progress: const LearnPathProgress(),
    );
    expect(step.button, '继续');
    expect(step.route, '/learn');
  });

  test('第一节完成且第二节未通过时，P2P 去读第二节', () {
    final step = practiceClearDestination(
      practice: 'p2p',
      progress: const LearnPathProgress(chapter1: true),
    );
    expect(step.button, '去读第二节');
    expect(step.route, '/learn/chapter/ch_002');
  });

  test('第二节已经通过时，P2P 回到学习页', () {
    final step = practiceClearDestination(
      practice: 'p2p',
      progress: const LearnPathProgress(chapter1: true, chapter2: true),
    );
    expect(step.route, '/learn');
  });

  test('反诈通关后回到学习页', () {
    final step = practiceClearDestination(
      practice: 'antiscam',
      progress: const LearnPathProgress(),
    );
    expect(step.button, '继续');
    expect(step.route, '/learn');
  });

  test('四个练习和两节课都完成后，继续卡显示路径走完', () {
    final step = nextLearnStep(
      const LearnPathProgress(
        chapter1: true,
        block: true,
        hash: true,
        p2p: true,
        chapter2: true,
        antiscam: true,
      ),
    );
    expect(step.title, '这条路径走完了');
  });

  testWidgets('已通关的练习显示已完成，未解锁的仍然锁着', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamesHomeScreen(
          loadProgress: () async =>
              (chapters: <String>{}, games: {'game_block'}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final block = find.ancestor(
      of: find.text('区块链拼图'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: block, matching: find.text('已完成')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: block, matching: find.textContaining('后解锁')),
      findsNothing,
    );

    final hash = find.ancestor(
      of: find.text('哈希碰碰乐'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: hash, matching: find.textContaining('后解锁')),
      findsOneWidget,
    );
  });

  testWidgets('再次进入练习页先显示上次解锁状态', (tester) async {
    var calls = 0;
    Future<({Set<String> chapters, Set<String> games})> load() async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (calls == 1) {
        return (chapters: <String>{}, games: {'game_block'});
      }
      return (chapters: <String>{'ch_001'}, games: {'game_block', 'game_hash'});
    }

    Widget page() {
      return MaterialApp(home: GamesHomeScreen(loadProgress: load));
    }

    await tester.pumpWidget(page());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text('已完成'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(page());
    await tester.pump();
    expect(find.text('已完成'), findsOneWidget);

    final hash = find.ancestor(
      of: find.text('哈希碰碰乐'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: hash, matching: find.textContaining('后解锁')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(
      find.descendant(of: hash, matching: find.textContaining('后解锁')),
      findsNothing,
    );
  });
}
