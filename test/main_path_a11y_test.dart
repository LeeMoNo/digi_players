import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:digi_players/features/auth/mnemonic_screen.dart';
import 'package:digi_players/features/auth/register_screen.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/learn_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('继续卡主按钮有语义名称，大字号下不省略', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
        child: MaterialApp(
          home: LearnHomeScreen(
            loadProgress: () async => const LearnPathProgress(),
            loadChapters: () async {},
            dailyTask: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('continue-button'));
    expect(button, findsOneWidget);
    expect(find.descendant(of: button, matching: find.text('继续阅读')), findsOneWidget);

    final semantics = tester.getSemantics(button);
    expect(semantics.label, contains('继续阅读'));
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);

    final text = tester.widget<Text>(
      find.descendant(of: button, matching: find.byType(Text)),
    );
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(text.softWrap, isTrue);
  });

  testWidgets('底栏三项大字号完整可读', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/learn',
      routes: [
        ShellRoute(
          builder: (_, __, child) =>
              MainShell(reportDailyLogin: () async {}, child: child),
          routes: [
            GoRoute(path: '/learn', builder: (_, __) => const Text('learn')),
            GoRoute(path: '/games', builder: (_, __) => const Text('games')),
            GoRoute(path: '/profile', builder: (_, __) => const Text('profile')),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => WindowLayoutScope(
            sizeClass: HorizontalSizeClass.unspecified,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-bottom-bar')), findsOneWidget);
    for (final label in ['学习', '练习', '我的']) {
      final widget = tester.widget<Text>(find.text(label));
      expect(widget.overflow, TextOverflow.clip);
      expect(widget.maxLines, 2);
      expect(widget.softWrap, isTrue);
    }
  });

  testWidgets('注册与助记词主按钮有语义名称', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('创建我的数字身份')).label,
      contains('创建我的数字身份'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MnemonicScreen(
          mnemonic: List.generate(12, (i) => 'word$i'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('我已抄写完毕，进入应用')).label,
      contains('我已抄写完毕，进入应用'),
    );
  });
}
