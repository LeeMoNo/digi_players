import 'package:digi_players/features/games/antiscam_game/antiscam_screen.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/games/hash_game/hash_game_screen.dart';
import 'package:digi_players/features/home/fraud_screen.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:digi_players/features/learn/chapter_screen.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/quiz_screen.dart';
import 'package:digi_players/features/points/profile_screen.dart';
import 'package:digi_players/features/square/square_screen.dart';
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
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/learn',
            builder: (_, __) => const LearnHomeScreen(),
            routes: [
              GoRoute(
                path: 'fraud',
                builder: (context, state) => fraudScreenFromState(state),
              ),
              GoRoute(
                path: 'chapter/:id',
                builder: (_, s) =>
                    ChapterScreen(chapterId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: 'quiz/:id',
                builder: (_, s) =>
                    QuizScreen(chapterId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/games',
            builder: (_, __) => const GamesHomeScreen(),
            routes: [
              GoRoute(
                path: 'hash',
                builder: (_, __) => const HashGameScreen(),
              ),
              GoRoute(
                path: 'antiscam',
                builder: (_, __) => const AntiscamScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/square',
            builder: (_, __) => const SquareScreen(),
          ),
        ],
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
