import 'dart:io';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/features/settings/language_screen.dart';
import 'package:digi_players/features/settings/settings_screen.dart';
import 'package:digi_players/features/settings/theme_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory hiveDir;
  late HttpClientAdapter originalAdapter;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('digi_settings_test');
    Hive.init(hiveDir.path);
    originalAdapter = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _OfflineAdapter();
  });

  tearDown(() async {
    ApiClient.dio.httpClientAdapter = originalAdapter;
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  testWidgets('语言和主题进入独立页面，选中后回到设置列表', (tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/settings/language',
          builder: (_, __) => const LanguageScreen(),
        ),
        GoRoute(
          path: '/settings/theme',
          builder: (_, __) => const ThemeScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await _flush(tester);

    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.byType(DropdownButton<ThemeMode>), findsNothing);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('学习内容、练习和每日题仍是简体中文'), findsOneWidget);

    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();
    expect(find.text('繁體中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await _flush(tester);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('简体中文'), findsNothing);

    await tester.tap(find.text('主题'));
    await tester.pumpAndSettle();
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await _flush(tester);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('深色'), findsOneWidget);
    expect(find.text('跟随系统'), findsNothing);
  });
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(Duration.zero);
  }
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'offline',
    );
  }
}
