import 'package:digi_players/core/models/chapter.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:digi_players/features/learn/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChapterDetail _detail(String chapterId) {
  return ChapterDetail(
    chapterId: chapterId,
    cards: const [],
    quizQuestions: const [
      QuizQuestion(
        qId: 'q1',
        question: {'zh_CN': '哪一项是正确的？'},
        options: {
          'zh_CN': ['正确选项', '错误选项'],
        },
        answer: 0,
      ),
    ],
    passScore: 1,
    quizPointsAction: 'quiz',
    completionAction: 'done',
  );
}

void main() {
  test('第一节通过且拼图未完成时，去区块链拼图', () {
    final step = quizPassDestination(
      chapterId: 'ch_001',
      progress: const LearnPathProgress(),
    );
    expect(step.button, '去做区块链拼图');
    expect(step.route, '/game/block-puzzle');
  });

  test('拼图已经完成时，回到学习页', () {
    final step = quizPassDestination(
      chapterId: 'ch_001',
      progress: const LearnPathProgress(block: true),
    );
    expect(step.button, '继续');
    expect(step.route, '/learn');
  });

  test('第二节通过且反诈未完成时，去反诈练习', () {
    final step = quizPassDestination(
      chapterId: 'ch_002',
      progress: const LearnPathProgress(chapter1: true, block: true),
    );
    expect(step.button, '去做反诈练习');
    expect(step.route, '/games/antiscam');
  });

  test('反诈已经完成时，回到学习页', () {
    final step = quizPassDestination(
      chapterId: 'ch_002',
      progress: const LearnPathProgress(antiscam: true),
    );
    expect(step.button, '继续');
    expect(step.route, '/learn');
  });

  testWidgets('通过第一节后主按钮进入拼图，不出现积分标题', (tester) async {
    var recorded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          chapterId: 'ch_001',
          initialDetail: _detail('ch_001'),
          recordPass: () async {
            recorded = true;
          },
          loadProgress: () async => const LearnPathProgress(),
        ),
      ),
    );

    await tester.tap(find.text('正确选项'));
    await tester.pump();
    await tester.tap(find.text('查看结果'));
    await tester.pumpAndSettle();

    expect(recorded, isTrue);
    expect(find.text('去做区块链拼图'), findsOneWidget);
    expect(find.textContaining('积分'), findsNothing);
    expect(find.text('返回章节列表'), findsNothing);
  });

  testWidgets('未通过时不记完成，主按钮是重新测验', (tester) async {
    var recorded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          chapterId: 'ch_001',
          initialDetail: _detail('ch_001'),
          recordPass: () async {
            recorded = true;
          },
          loadProgress: () async => const LearnPathProgress(),
        ),
      ),
    );

    await tester.tap(find.text('错误选项'));
    await tester.pump();
    await tester.tap(find.text('查看结果'));
    await tester.pumpAndSettle();

    expect(recorded, isFalse);
    expect(find.text('重新测验'), findsOneWidget);
    expect(find.text('去做区块链拼图'), findsNothing);
    expect(find.textContaining('积分'), findsNothing);
  });
}
