import 'package:digi_players/features/games/antiscam_game/antiscam_screen.dart';
import 'package:digi_players/features/games/block_puzzle/block_puzzle_screen.dart';
import 'package:digi_players/features/games/games_home_screen.dart';
import 'package:digi_players/features/games/hash_game/hash_game_screen.dart';
import 'package:digi_players/features/games/p2p_game/p2p_game_screen.dart';
import 'package:digi_players/features/home/fraud_screen.dart';
import 'package:digi_players/features/home/main_shell.dart';
import 'package:digi_players/features/learn/chapter_screen.dart';
import 'package:digi_players/features/learn/learn_home_screen.dart';
import 'package:digi_players/features/learn/library_screen.dart';
import 'package:digi_players/features/learn/library_split.dart';
import 'package:digi_players/features/learn/quiz_screen.dart';
import 'package:digi_players/features/points/profile_screen.dart';
import 'package:digi_players/features/settings/language_screen.dart';
import 'package:digi_players/features/settings/mnemonic_view_screen.dart';
import 'package:digi_players/features/settings/nickname_screen.dart';
import 'package:digi_players/features/settings/settings_split.dart';
import 'package:digi_players/features/settings/theme_screen.dart';
import 'package:digi_players/features/square/square_chat_screen.dart';
import 'package:digi_players/features/square/square_split.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import '../../features/auth/intro_screen.dart';
import '../../features/auth/mnemonic_screen.dart';
import '../../features/auth/recover_screen.dart';
import '../../features/auth/register_screen.dart';

final initialLocationProvider = Provider<String>((_) => '/learn');

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(
    initialLocation: ref.read(initialLocationProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    observers: [appRouteObserver],
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
      GoRoute(path: '/intro', builder: (context, state) => const IntroScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/learn',
            builder: (_, __) => const LearnHomeScreen(),
            routes: [
              ShellRoute(
                builder: (context, state, child) =>
                    LibrarySplitShell(child: child),
                routes: [
                  GoRoute(
                    path: 'library',
                    builder: (_, __) => const LibraryRoute(),
                  ),
                  GoRoute(
                    path: 'library/:eraId',
                    builder: (_, state) =>
                        EraDetailScreen(eraId: state.pathParameters['eraId']!),
                  ),
                ],
              ),
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
              GoRoute(path: 'hash', builder: (_, __) => const HashGameScreen()),
              GoRoute(
                path: 'antiscam',
                builder: (_, __) => const AntiscamScreen(),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ShellRoute(
            builder: (context, state, child) => SquareSplitShell(child: child),
            routes: [
              GoRoute(
                path: '/square',
                builder: (_, __) => const SquareRoute(),
                routes: [
                  GoRoute(
                    path: 'chat/:room',
                    builder: (_, state) => SquareChatScreen(
                      room: state.pathParameters['room']!,
                      roomName: state.extra as String? ?? '广场',
                    ),
                  ),
                ],
              ),
            ],
          ),
          ShellRoute(
            builder: (context, state, child) =>
                SettingsSplitShell(child: child),
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsRoute(),
                routes: [
                  GoRoute(
                    path: 'language',
                    builder: (_, __) => const LanguageScreen(),
                  ),
                  GoRoute(
                    path: 'theme',
                    builder: (_, __) => const ThemeScreen(),
                  ),
                  GoRoute(
                    path: 'nickname',
                    builder: (_, __) => const NicknameScreen(),
                  ),
                  GoRoute(
                    path: 'mnemonic',
                    builder: (_, __) => const MnemonicViewScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/game/block-puzzle',
            builder: (_, __) => const BlockPuzzleScreen(),
          ),
          GoRoute(path: '/game/p2p', builder: (_, __) => const P2PGameScreen()),
        ],
      ),
    ],
  );
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
