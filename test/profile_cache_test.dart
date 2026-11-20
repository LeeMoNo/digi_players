import 'package:digi_players/features/points/profile_repository.dart';
import 'package:digi_players/features/points/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ProfileCache.clear);

  testWidgets('第一次进入我的页面会等待，再次进入先显示上次数据', (tester) async {
    var calls = 0;
    Future<ProfileSnapshot> load(ProfileSnapshot? previous) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return ProfileSnapshot(
        did: 'did:me',
        nickname: calls == 1 ? '第一次' : '第二次',
        points: calls,
        unlocked: const {},
        rankings: const [],
      );
    }

    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(loadProfile: load)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('第一次'), findsNothing);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text('第一次'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(loadProfile: load)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('第一次'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text('第二次'), findsOneWidget);
    expect(find.text('第一次'), findsNothing);
  });
}
