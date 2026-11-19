import 'package:digi_players/features/auth/recover_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('词数不足时停在恢复页', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RecoverScreen()));

    await tester.enterText(find.byType(TextField), 'abandon abandon');
    await tester.tap(find.text('恢复并进入'));
    await tester.pump();

    expect(find.text('请输入 12 个单词，用空格分开'), findsOneWidget);
    expect(find.text('恢复身份'), findsOneWidget);
  });

  testWidgets('12 个词但校验和不对时停在恢复页', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RecoverScreen()));

    await tester.enterText(
      find.byType(TextField),
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
    );
    await tester.tap(find.text('恢复并进入'));
    await tester.pump();

    expect(find.text('助记词无效，请检查单词拼写'), findsOneWidget);
    expect(find.text('恢复并进入'), findsOneWidget);
  });
}
