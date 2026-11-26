import 'dart:convert';

import 'package:digi_players/core/router/app_route_observer.dart';
import 'package:digi_players/features/points/profile_repository.dart';
import 'package:digi_players/features/points/profile_screen.dart';
import 'package:digi_players/features/points/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
    expect(find.text('数民广场'), findsNothing);

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

  test('更新头像后，更早的个人页加载不再是最新的', () {
    ProfileCache.latest = const ProfileSnapshot(
      did: 'did:me',
      nickname: '小林',
      points: 1,
      unlocked: {},
      rankings: [],
    );
    final ticket = ProfileCache.begin();
    ProfileCache.rememberAvatar('https://example.com/a.jpg');
    expect(ProfileCache.isLatest(ticket), isFalse);
    expect(ProfileCache.latest?.avatarUrl, 'https://example.com/a.jpg');
    expect(ProfileCache.latest?.nickname, '小林');
  });

  testWidgets('有头像地址时不再显示指纹图标', (tester) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          loadProfile: (_) async => const ProfileSnapshot(
            did: 'did:me',
            nickname: '小林',
            avatarUrl: 'https://example.com/a.jpg',
            points: 1,
            unlocked: {},
            rankings: [],
          ),
          imageForUrl: (_) => MemoryImage(png),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(UserAvatar),
        matching: find.byIcon(Icons.fingerprint),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(UserAvatar),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<UserAvatar>(find.byType(UserAvatar)).url,
      'https://example.com/a.jpg',
    );
  });

  testWidgets('换过头像再回到我的页面，马上显示新头像', (tester) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    var calls = 0;
    Future<ProfileSnapshot> load(ProfileSnapshot? previous) async {
      calls++;
      if (calls > 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      return ProfileSnapshot(
        did: 'did:me',
        nickname: '小林',
        avatarUrl: previous?.avatarUrl,
        avatarBytes: previous?.avatarBytes,
        points: 1,
        unlocked: const {},
        rankings: const [],
      );
    }

    final router = GoRouter(
      observers: [appRouteObserver],
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => ProfileScreen(
            loadProfile: load,
            imageForUrl: (_) => MemoryImage(png),
          ),
        ),
        GoRoute(
          path: '/settings/avatar',
          builder: (_, __) => const Scaffold(body: Text('头像设置')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();
    expect(find.text('小林'), findsOneWidget);
    expect(ProfileCache.latest?.avatarBytes, isNull);

    router.push('/settings/avatar');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('头像设置'), findsOneWidget);

    ProfileCache.rememberAvatar('https://example.com/new.jpg', bytes: png);
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('小林'), findsOneWidget);
    expect(tester.widget<UserAvatar>(find.byType(UserAvatar)).bytes, png);
  });
}
