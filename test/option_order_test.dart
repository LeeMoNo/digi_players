import 'dart:math';

import 'package:digi_players/core/models/chapter.dart';
import 'package:digi_players/core/utils/shuffled_options.dart';
import 'package:digi_players/features/games/antiscam_game/antiscam_data.dart';
import 'package:digi_players/features/games/antiscam_game/antiscam_screen.dart';
import 'package:digi_players/features/home/daily_task_card.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:digi_players/features/learn/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(DailyQuizCache.clear);
  tearDown(DailyQuizCache.clear);

  test('两项会随机换位，不会永远对调', () {
    final seen = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      final shuffled = ShuffledOptions.shuffle(const [
        '甲',
        '乙',
      ], random: Random(seed));
      seen.add(shuffled.texts.join('|'));
    }
    expect(seen, {'甲|乙', '乙|甲'});
  });

  test('三项及以上洗成原稿顺序时，对调前两项', () {
    final shuffled = ShuffledOptions.shuffle(const [
      '甲',
      '乙',
      '丙',
    ], random: _HighRandom());
    expect(shuffled.texts, ['乙', '甲', '丙']);
    expect(shuffled.originalIndex(0), 1);
    expect(shuffled.originalIndex(1), 0);
    expect(shuffled.originalIndex(2), 2);
  });

  testWidgets('章节测验打乱后仍按原始答案判分', (tester) async {
    var recorded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          chapterId: 'ch_001',
          random: ScriptedRandom([0]),
          initialDetail: ChapterDetail(
            chapterId: 'ch_001',
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
          ),
          recordPass: () async {
            recorded = true;
          },
          loadProgress: () async => const LearnPathProgress(),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('错误选项')).dy,
      lessThan(tester.getTopLeft(find.text('正确选项')).dy),
    );

    await tester.tap(find.text('正确选项'));
    await tester.pump();
    await tester.tap(find.text('查看结果'));
    await tester.pumpAndSettle();

    expect(recorded, isTrue);
    expect(find.text('通过！'), findsOneWidget);
  });

  testWidgets('每日一题提交原始下标，重新选择会再打乱', (tester) async {
    final submitted = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyTaskCard(
            random: ScriptedRandom([0, 1]),
            loader: () async => {
              'q_id': 'daily-1',
              'question': {'zh_CN': '选一个'},
              'options': {
                'zh_CN': ['正确', '错误'],
              },
            },
            submitAnswer: (qId, index) async {
              expect(qId, 'daily-1');
              submitted.add(index);
              return false;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('错误')).dy,
      lessThan(tester.getTopLeft(find.text('正确')).dy),
    );

    await tester.tap(find.text('错误'));
    await tester.pump();
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    expect(submitted, [1]);
    expect(find.text('回答错误，再想想看'), findsOneWidget);

    await tester.tap(find.text('重新选择'));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('正确')).dy,
      lessThan(tester.getTopLeft(find.text('错误')).dy),
    );
  });

  testWidgets('反诈判断题的两个按钮会交换上下位置', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AntiscamScreen(fetchSeed: false, random: ScriptedRandom([0])),
      ),
    );

    expect(
      tester.getTopLeft(find.text('这是正常的')).dy,
      lessThan(tester.getTopLeft(find.text('这是诈骗！')).dy),
    );
  });

  testWidgets('反诈选择题里「以上都不点」可以排在前面，点它仍然算对', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AntiscamScreen(
          fetchSeed: false,
          initialIndex: antiscamQuestions.length,
          random: ScriptedRandom([0, 2, 1]),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('以上都不点')).dy,
      lessThan(tester.getTopLeft(find.text('要求输入助记词')).dy),
    );

    await tester.tap(find.text('以上都不点'));
    await tester.pump();
    expect(find.text('选择正确'), findsOneWidget);
  });
}

class ScriptedRandom implements Random {
  ScriptedRandom(this.values);

  final List<int> values;
  var _index = 0;

  @override
  int nextInt(int max) {
    final value = values[_index];
    _index++;
    if (value < 0 || value >= max) {
      throw StateError('scripted $value is outside 0..$max');
    }
    return value;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

class _HighRandom implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
