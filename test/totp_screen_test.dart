import 'package:digi_players/features/settings/totp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('说明三种做法，确认动态码后才展示备用码', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TotpScreen(
          loadEnabled: () async => false,
          startSetup: () async => TotpSetup(
            secret: 'ABCDEFGHJKLMNOPQ',
            otpauthUrl: 'otpauth://totp/DigiPlayers:me?secret=ABCDEFGHJKLMNOPQ',
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          ),
          enable: (code) async {
            expect(code, '123456');
            return const TotpEnableResult(
              backupCodes: ['AB12-CD34'],
              pointsAwarded: 3,
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('谷歌验证器'), findsWidgets);
    expect(find.textContaining('通行密钥'), findsOneWidget);
    expect(find.textContaining('邮箱或短信'), findsOneWidget);
    expect(find.text('开启验证器动态码'), findsOneWidget);

    await tester.tap(find.text('开启验证器动态码'));
    await tester.pump();
    expect(find.text('确认开启'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('确认开启'));
    await tester.pump();

    expect(find.text('AB12-CD34'), findsOneWidget);
    expect(find.textContaining('获得 3 积分'), findsOneWidget);
    final done = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '完成'),
    );
    expect(done.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pump();

    expect(find.text('关闭二次验证'), findsOneWidget);
    expect(find.text('AB12-CD34'), findsNothing);
  });

  testWidgets('二维码过期后提示重新生成，不能再确认', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TotpScreen(
          loadEnabled: () async => false,
          startSetup: () async => TotpSetup(
            secret: 'ABCDEFGHJKLMNOPQ',
            otpauthUrl: 'otpauth://totp/DigiPlayers:me?secret=ABCDEFGHJKLMNOPQ',
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
          enable: (_) async =>
              const TotpEnableResult(backupCodes: ['AB12-CD34']),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('开启验证器动态码'));
    await tester.pump();

    expect(find.textContaining('二维码已过期'), findsWidgets);
    expect(find.text('二维码已过期，重新生成'), findsOneWidget);

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '确认开启'),
    );
    expect(confirm.onPressed, isNull);
  });
}
