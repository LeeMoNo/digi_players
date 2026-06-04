// lib/features/home/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.book_outlined,    activeIcon: Icons.book,    label: '学习',  path: '/learn'),
    (icon: Icons.games_outlined,   activeIcon: Icons.games,   label: '游戏',  path: '/games'),
    (icon: Icons.person_outlined,  activeIcon: Icons.person,  label: '我的',  path: '/profile'),
    (icon: Icons.people_outlined,  activeIcon: Icons.people,  label: '广场',  path: '/square'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((t) => NavigationDestination(
          icon:          Icon(t.icon),
          selectedIcon:  Icon(t.activeIcon),
          label:         t.label,
        )).toList(),
      ),
    );
  }
}