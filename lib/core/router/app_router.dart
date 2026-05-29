import 'package:digi_players/core/storage/secure_storage.dart';
import 'package:digi_players/features/HomeScreen.dart';
import 'package:digi_players/features/learn/chapter_screen.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/mnemonic_screen.dart';
import '../../features/auth/register_screen.dart';

GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/mnemonic',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! List<String> || extra.length != 12) {
            return const _RouteErrorPage(message: '助记词参数无效，请重新创建身份。');
          }
          return MnemonicScreen(mnemonic: extra);
        },
      ),
      GoRoute(
        path: '/recover',
        builder: (context, state) => const RecoverScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/learn', builder: (_, __) => const LearnHomeScreen()),
      GoRoute(
        path: '/chapter/:id',
        builder: (_, s) => ChapterScreen(chapterId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (_, s) => QuizScreen(chapterId: s.pathParameters['id']!),
      ),
    ],
  );
}

class RecoverScreen extends StatelessWidget {
  const RecoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('恢复身份')),
      body: const Center(child: Text('Recover 流程待实现')),
    );
  }
}


class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('路由参数错误')),
      body: Center(child: Text(message)),
    );
  }
}
