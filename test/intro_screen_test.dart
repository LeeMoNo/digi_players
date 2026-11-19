import 'package:digi_players/features/auth/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只有没看过说明的新身份才进入这三句话', () {
    expect(shouldShowIntro(isNewUser: true, seenIntro: false), isTrue);
    expect(shouldShowIntro(isNewUser: true, seenIntro: true), isFalse);
    expect(shouldShowIntro(isNewUser: false, seenIntro: false), isFalse);
    expect(shouldShowIntro(isNewUser: false, seenIntro: true), isFalse);
  });

  testWidgets('说明页使用规定的三句话和一个按钮', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntroScreen()));

    expect(find.textContaining('这把钥匙只用来标识你的学习进度。它不能收款，不要往这个身份转币。'), findsOneWidget);
    expect(find.textContaining('DigiPlayers 不会向你索要这 12 个词。任何索要助记词的页面或私信都不是我们。'), findsOneWidget);
    expect(find.textContaining('今天只做第一节：读完，再做这一节的练习。'), findsOneWidget);
    expect(find.text('开始第一节'), findsOneWidget);
  });
}
