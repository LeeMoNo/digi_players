import 'package:digi_players/features/games/antiscam_game/antiscam_data.dart';
import 'package:digi_players/features/games/antiscam_game/antiscam_screen.dart';
import 'package:digi_players/features/home/data/home_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('答完诈骗判断题后出现对应骗局入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AntiscamScreen(fetchSeed: false)),
    );

    await tester.tap(find.text('这是诈骗！'));
    await tester.pump();

    expect(find.text('查看「冒充官方 / 名人」'), findsOneWidget);
  });
}
