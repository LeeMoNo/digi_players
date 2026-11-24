import 'package:digi_players/features/points/points_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('展示积分历史，并可点累计积分入口文案映射', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PointsHistoryScreen(
          loadPage: ({int? before}) async {
            expect(before, isNull);
            return PointsHistoryPage(
              items: [
                PointsHistoryItem(
                  id: 2,
                  actionKey: 'totp_enable',
                  points: 3,
                  createdAt: DateTime.utc(2026, 11, 24, 8, 30),
                ),
                PointsHistoryItem(
                  id: 1,
                  actionKey: 'daily_login',
                  points: 1,
                  createdAt: DateTime.utc(2026, 11, 24, 7, 0),
                ),
              ],
              hasMore: false,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('积分记录'), findsOneWidget);
    expect(find.text('开启二次验证'), findsOneWidget);
    expect(find.text('每日登录'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('空列表给出引导', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PointsHistoryScreen(
          loadPage: ({int? before}) async =>
              const PointsHistoryPage(items: [], hasMore: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('还没有积分记录'), findsOneWidget);
  });

  test('action 标题映射', () {
    expect(pointsActionTitle('lesson_read'), '阅读学习卡片');
    expect(pointsActionTitle('unknown_x'), 'unknown_x');
  });
}
