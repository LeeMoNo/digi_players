// lib/features/home/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/window_layout_host.dart';

/// 底栏只留在三个主页面。设置、章节、练习关卡这些子页面不再垫一层导航。
bool showsMainNavigation(String path) {
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path == '/learn' || path == '/games' || path == '/profile';
}

class MainShell extends StatefulWidget {
  final Widget child;

  /// 测试可替换，避免启动时请求每日登录接口。
  final Future<void> Function()? reportDailyLogin;

  const MainShell({super.key, required this.child, this.reportDailyLogin});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tabs = [
    (
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: '学习',
      path: '/learn',
    ),
    (
      icon: Icons.games_outlined,
      activeIcon: Icons.games,
      label: '练习',
      path: '/games',
    ),
    (
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
      label: '我的',
      path: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    (widget.reportDailyLogin ?? _reportDailyLogin)();
  }

  /// 每日登录积分；daily_cap=1 由服务端防重复，429 可忽略
  Future<void> _reportDailyLogin() async {
    try {
      await ApiClient.dio.post(
        '/points/award',
        data: {'action_key': 'daily_login'},
      );
    } catch (_) {}
  }

  int _currentIndex(String location) {
    if (location.startsWith('/game')) return 1;
    if (location.startsWith('/profile') ||
        location.startsWith('/square') ||
        location.startsWith('/settings')) {
      return 2;
    }
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _currentIndex(path);
    final wide = WindowLayoutScope.layoutOf(context).wide;
    final showBottomBar = !wide && showsMainNavigation(path);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        body: wide
            ? Row(
                children: [
                  NavigationRail(
                    backgroundColor: scheme.surface,
                    indicatorColor: scheme.primaryContainer,
                    labelType: NavigationRailLabelType.all,
                    selectedIndex: index,
                    onDestinationSelected: (i) => context.go(_tabs[i].path),
                    destinations: [
                      for (final tab in _tabs)
                        NavigationRailDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.activeIcon),
                          label: Text(tab.label),
                        ),
                    ],
                  ),
                  Expanded(child: widget.child),
                ],
              )
            : widget.child,
        bottomNavigationBar: showBottomBar
            ? NavigationBar(
                backgroundColor: scheme.surface,
                indicatorColor: scheme.primaryContainer,
                selectedIndex: index,
                onDestinationSelected: (i) => context.go(_tabs[i].path),
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.activeIcon),
                      label: tab.label,
                    ),
                ],
              )
            : null,
      ),
    );
  }
}
