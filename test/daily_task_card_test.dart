import 'package:digi_players/features/home/daily_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('接口失败时仍占位，文案可读并可重试', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyTaskCard(
            loader: () async {
              loads++;
              if (loads == 1) throw Exception('offline');
              return null;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('每日一题'), findsOneWidget);
    expect(find.text('今天的题暂时取不到'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.textContaining('选一个'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.text('今天的题暂时取不到'), findsOneWidget);
  });

  testWidgets('空题与失败同一文案，不出现本地题干', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyTaskCard(loader: () async => null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今天的题暂时取不到'), findsOneWidget);
    expect(find.text('提交'), findsNothing);
  });

  testWidgets('答对后显示今天的题完成了', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyTaskCard(
            loader: () async => {
              'q_id': 'daily-1',
              'question': {'zh_CN': '选一个'},
              'options': {
                'zh_CN': ['甲', '乙'],
              },
            },
            submitAnswer: (_, __) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('甲'));
    await tester.pump();
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    expect(find.text('今天的题完成了'), findsOneWidget);
    expect(find.textContaining('积分'), findsNothing);
  });
}
