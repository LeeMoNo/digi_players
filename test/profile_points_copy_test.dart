import 'package:digi_players/features/points/profile_repository.dart';
import 'package:digi_players/features/points/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(ProfileCache.clear);

  testWidgets('我的页积分说明中性，不含兑换空投提现 DP', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ProfileScreen(
            loadProfile: (_) async => const ProfileSnapshot(
              did: 'did:me',
              nickname: '小林',
              points: 3,
              unlocked: {},
              rankings: [],
            ),
          ),
        ),
        GoRoute(
          path: '/profile/points',
          builder: (_, __) => const Scaffold(
            body: Text('积分历史页'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('完成内容会记一笔，点此查看记录'), findsOneWidget);
    expect(find.text('按完成记录排序'), findsOneWidget);
    expect(find.text('路径完成'), findsOneWidget);

    for (final banned in ['兑换', '空投', '提现', 'DP', '代币', '奖励']) {
      expect(find.textContaining(banned), findsNothing);
    }

    await tester.tap(find.text('累计积分'));
    await tester.pumpAndSettle();
    expect(find.text('积分历史页'), findsOneWidget);
  });
}
