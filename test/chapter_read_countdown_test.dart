import 'package:digi_players/core/models/chapter.dart';
import 'package:digi_players/features/learn/chapter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('倒计时期间按钮不可点，结束后才能已读下一张', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChapterScreen(
          chapterId: 'ch_001',
          countdownSeconds: 3,
          initialDetail: _detail(),
          initialRead: const {'c1', 'c2'},
        ),
      ),
    );

    expect(find.text('请阅读 3s'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('请阅读 2s'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('已读，下一张'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('已读，下一张'));
    await tester.pump();

    // 下一张重新开始倒计时
    expect(find.text('第二张'), findsOneWidget);
    expect(find.text('请阅读 3s'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('倒计时未结束时连点不会翻页', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChapterScreen(
          chapterId: 'ch_001',
          countdownSeconds: 5,
          initialDetail: _detail(),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('第一张'), findsOneWidget);
    expect(find.text('第二张'), findsNothing);
  });
}

ChapterDetail _detail() {
  return ChapterDetail(
    chapterId: 'ch_001',
    cards: const [
      CardItem(
        cardId: 'c1',
        order: 1,
        title: {'zh_CN': '第一张'},
        body: {'zh_CN': '正文一'},
        pointsAction: 'read',
      ),
      CardItem(
        cardId: 'c2',
        order: 2,
        title: {'zh_CN': '第二张'},
        body: {'zh_CN': '正文二'},
        pointsAction: 'read',
      ),
    ],
    quizQuestions: const [],
    passScore: 1,
    quizPointsAction: 'quiz',
    completionAction: 'done',
  );
}
