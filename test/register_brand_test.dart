import 'package:digi_players/features/auth/register_screen.dart';
import 'package:digi_players/features/settings/legal_screen.dart';
import 'package:digi_players/features/settings/legal_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('注册页用应用图标，不是指纹占位；协议与恢复仍在', (tester) async {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/recover',
          builder: (_, __) => const Scaffold(body: Text('恢复页')),
        ),
        GoRoute(
          path: '/privacy',
          builder: (_, __) => const LegalScreen(doc: LegalDoc.privacy),
        ),
        GoRoute(
          path: '/terms',
          builder: (_, __) => const LegalScreen(doc: LegalDoc.terms),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.byKey(const Key('register-logo')), findsOneWidget);
    expect(find.text('DigiPlayers'), findsOneWidget);
    expect(find.text('创建我的数字身份'), findsOneWidget);
    expect(find.text('用助记词恢复'), findsOneWidget);
    expect(find.textContaining('资产'), findsNothing);
    expect(find.textContaining('收款'), findsNothing);

    await tester.tap(find.text('《隐私政策》'));
    await tester.pumpAndSettle();
    expect(find.text('隐私政策'), findsWidgets);

    router.go('/register');
    await tester.pumpAndSettle();
    await tester.tap(find.text('《用户协议》'));
    await tester.pumpAndSettle();
    expect(find.text('用户协议'), findsWidgets);

    router.go('/register');
    await tester.pumpAndSettle();
    await tester.tap(find.text('用助记词恢复'));
    await tester.pumpAndSettle();
    expect(find.text('恢复页'), findsOneWidget);
  });
}
