import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 新用户说明只出现一次。和设置共用 Hive 盒子 `app_settings`。
const introSettingsBox = 'app_settings';
const seenIntroKey = 'seen_intro';

/// 只有服务器认定是新身份、并且本机还没看过时才进入说明页。
bool shouldShowIntro({required bool isNewUser, required bool seenIntro}) {
  return isNewUser && !seenIntro;
}

Future<String> routeAfterAuth(bool isNewUser) async {
  if (!isNewUser) return '/learn';
  final seen = await _readSeenIntro();
  return shouldShowIntro(isNewUser: true, seenIntro: seen) ? '/intro' : '/learn';
}

Future<bool> _readSeenIntro() async {
  try {
    final box = await Hive.openBox(introSettingsBox);
    return box.get(seenIntroKey, defaultValue: false) == true;
  } catch (_) {
    return false;
  }
}

Future<void> markIntroSeen() async {
  final box = await Hive.openBox(introSettingsBox);
  await box.put(seenIntroKey, true);
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const _lines = [
    '这把钥匙只用来标识你的学习进度。它不能收款，不要往这个身份转币。',
    'DigiPlayers 不会向你索要这 12 个词。任何索要助记词的页面或私信都不是我们。',
    '今天只做第一节：读完，再做这一节的练习。',
  ];

  bool _leaving = false;

  Future<void> _start() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await markIntroSeen();
    } catch (_) {}
    if (!mounted) return;
    context.go('/learn');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('开始之前'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _lines.length; i++) ...[
                  Text(
                    '${i + 1}. ${_lines[i]}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 20),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _leaving ? null : _start,
                  child: _leaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('开始第一节'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
