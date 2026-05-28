import 'package:digi_players/core/storage/secure_storage.dart';
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
            return const _RouteErrorPage(
              message: '助记词参数无效，请重新创建身份。',
            );
          }
          return MnemonicScreen(mnemonic: extra);
        },
      ),
      GoRoute(
        path: '/recover',
        builder: (context, state) => const RecoverScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _HomeScreen(),
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
      body: const Center(
        child: Text('Recover 流程待实现'),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digi Players')),
      body: Center(
        child: Column(
          children: [
            Text('已进入主页面'),
            TextButton(
              onPressed: () async {
                // 临时调试用，确认 DID 已正确存储
                var did = await SecureStorage.getDID();
                debugPrint('MY DID: $did');
                // 输出示例：MY DID: did:key:z6MkhaXgBZDvotDkL5257fai...
              }, 
              child: Text('确认 DID 已正确存储')),
          ],
        ),
      ),
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