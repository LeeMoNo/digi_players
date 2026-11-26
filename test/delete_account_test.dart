import 'dart:io';

import 'package:digi_players/core/api/api_client.dart';
import 'package:digi_players/core/progress/progress_store.dart';
import 'package:digi_players/core/router/app_router.dart';
import 'package:digi_players/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory hiveDir;
  late HttpClientAdapter originalAdapter;
  var deleteCalls = 0;
  var deleteShouldFail = false;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('digi_delete_account');
    Hive.init(hiveDir.path);
    deleteCalls = 0;
    deleteShouldFail = false;
    FlutterSecureStorage.setMockInitialValues({
      'dp_did': 'did:key:zTest',
      'dp_jwt': 'token',
    });
    originalAdapter = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _Adapter(
      onDeleteAccount: () {
        deleteCalls++;
        if (deleteShouldFail) {
          throw DioException(
            requestOptions: RequestOptions(path: '/user/account'),
            type: DioExceptionType.connectionError,
          );
        }
        return ResponseBody.fromString(
          '{"deleted":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      },
    );
  });

  tearDown(() async {
    ApiClient.dio.httpClientAdapter = originalAdapter;
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  testWidgets('未输入「删除」时不能确认', (tester) async {
    await _openSettings(tester);
    await tester.tap(find.text('删除账号'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认删除'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '删除');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认删除'))
          .onPressed,
      isNotNull,
    );
  });

  test('SecureStorage.clearAll 能清掉 mock 身份', () async {
    FlutterSecureStorage.setMockInitialValues({'dp_did': 'did:key:zClear'});
    expect(await SecureStorage.getDID(), 'did:key:zClear');
    await SecureStorage.clearAll();
    expect(await SecureStorage.getDID(), isNull);
  });

  testWidgets('删除成功后回到注册页且调过删除接口', (tester) async {
    final router = await _openSettings(tester);

    await tester.tap(find.text('删除账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '删除');
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(deleteCalls, 1);
    expect(find.text('没删成，请检查网络后重试'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/register');
    expect(find.text('创建我的数字身份'), findsOneWidget);
    expect(await SecureStorage.getDID(), isNull);
  });

  testWidgets('删除失败时不清理本机钥匙', (tester) async {
    deleteShouldFail = true;
    final router = await _openSettings(tester);

    await tester.tap(find.text('删除账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '删除');
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(deleteCalls, 1);
    expect(await SecureStorage.getDID(), 'did:key:zTest');
    expect(find.text('没删成，请检查网络后重试'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/settings');
    expect(find.text('删除账号'), findsOneWidget);
  });

  test('clearLocalCacheFor 清空进度标记', () async {
    final box = await Hive.openBox('progress_did:key:zProg');
    await box.put('completed_ch_001', true);
    await box.put('synced', true);

    await ProgressStore.clearLocalCacheFor('did:key:zProg');
    expect(box.get('completed_ch_001'), isNull);
    expect(box.get('synced'), isNull);
  });
}

Future<GoRouter> _openSettings(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = createAppRouter(initialLocation: '/settings');
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('删除账号'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  return router;
}

class _Adapter implements HttpClientAdapter {
  _Adapter({required this.onDeleteAccount});

  final ResponseBody Function() onDeleteAccount;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'DELETE' && options.path.contains('/user/account')) {
      return onDeleteAccount();
    }
    return ResponseBody.fromString(
      '{"error":"offline"}',
      503,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
