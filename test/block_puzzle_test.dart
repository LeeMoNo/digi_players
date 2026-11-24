import 'package:digi_players/features/games/block_puzzle/block_puzzle_data.dart';
import 'package:digi_players/features/games/block_puzzle/block_puzzle_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只有创世块开头、且前后哈希相接时顺序才合法', () {
    expect(validateChainOrder(correctChain), isTrue);
    expect(linksToPrevious(correctChain, 0), isTrue);
    expect(linksToPrevious(correctChain, 1), isTrue);

    final scrambled = [
      correctChain[2],
      correctChain[4],
      correctChain[1],
      correctChain[0],
      correctChain[3],
    ];
    expect(validateChainOrder(scrambled), isFalse);
    expect(linksToPrevious(scrambled, 0), isFalse);
    expect(prevHashLabel(scrambled.first.prevHash), '9b2e7f4a…');
    expect(prevHashLabel(correctChain.first.prevHash), '0000…0000（创世块）');
  });

  testWidgets('排错的第一块不再假装是创世块，并标出接不上', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlockPuzzleScreen(
          fetchSeed: false,
          trackTime: false,
          initialBlocks: [
            correctChain[2],
            correctChain[4],
            correctChain[1],
            correctChain[0],
            correctChain[3],
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('0000…0000（创世块）'), findsOneWidget);
    expect(find.textContaining('9b2e7f4a…'), findsWidgets);
    expect(find.text('对不上'), findsNWidgets(5));
    expect(find.textContaining('Charlie → Dave : 0.5 BTC'), findsOneWidget);
    expect(find.text('已标记 0/2 个篡改区块'), findsOneWidget);
    expect(find.byType(ReorderableDragStartListener), findsNWidgets(5));
    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(5));
  });

  testWidgets('长按交易可以拖动排序，点旗帜才标记篡改', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlockPuzzleScreen(
          fetchSeed: false,
          trackTime: false,
          initialBlocks: [
            correctChain[2],
            correctChain[0],
            correctChain[1],
            correctChain[3],
            correctChain[4],
          ],
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Eve → Frank : 2.0 BTC')).dy,
      lessThan(tester.getTopLeft(find.text('Alice → Bob : 1.0 BTC')).dy),
    );

    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(0, 280));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Alice → Bob : 1.0 BTC')).dy,
      lessThan(tester.getTopLeft(find.text('Eve → Frank : 2.0 BTC')).dy),
    );

    await tester.tap(find.byTooltip('标记为篡改').first);
    await tester.pump();
    expect(find.text('已标记 1/2 个篡改区块'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Alice → Bob : 1.0 BTC')).dy,
      lessThan(tester.getTopLeft(find.text('Eve → Frank : 2.0 BTC')).dy),
    );
  });

  testWidgets('长按交易文字也能拖动排序', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlockPuzzleScreen(
          fetchSeed: false,
          trackTime: false,
          initialBlocks: [
            correctChain[2],
            correctChain[0],
            correctChain[1],
            correctChain[3],
            correctChain[4],
          ],
        ),
      ),
    );
    await tester.pump();

    final drag = await tester.startGesture(
      tester.getCenter(find.text('Eve → Frank : 2.0 BTC')),
    );
    await tester.pump(kLongPressTimeout);
    await drag.moveBy(const Offset(0, 80));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Alice → Bob : 1.0 BTC')).dy,
      lessThan(tester.getTopLeft(find.text('Eve → Frank : 2.0 BTC')).dy),
    );
  });

  testWidgets('结算页再来一次会回到新的一局', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlockPuzzleScreen(
          fetchSeed: false,
          trackTime: false,
          initialBlocks: correctChain,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('标记为篡改').first);
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump();

    expect(find.text('还需再试'), findsOneWidget);
    expect(find.text('再来一次'), findsOneWidget);

    await tester.tap(find.text('再来一次'));
    await tester.pump();

    expect(find.text('还需再试'), findsNothing);
    expect(find.text('提交答案'), findsOneWidget);
    expect(find.text('已标记 0/2 个篡改区块'), findsOneWidget);
  });
}
