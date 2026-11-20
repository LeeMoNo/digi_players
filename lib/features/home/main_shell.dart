// lib/features/home/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/window_layout_host.dart';

/// 资料、广场、设置在够宽时是列表加详情，再算上侧栏就是三栏。
bool showsSplitPane(String path) {
  return path.startsWith('/learn/library') ||
      path.startsWith('/square') ||
      path.startsWith('/settings');
}

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
  var _railExpanded = false;

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
    final layout = WindowLayoutScope.layoutOf(context);
    final wide = layout.wide;
    final threePane = wide && layout.canSplit && showsSplitPane(path);
    final expandRail = _railExpanded && !threePane;
    final showBottomBar = !wide && showsMainNavigation(path);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        body: wide
            ? Row(
                children: [
                  _SideRail(
                    expanded: expandRail,
                    showMenu: !threePane,
                    selectedIndex: index,
                    onMenu: () => setState(() {
                      _railExpanded = !_railExpanded;
                    }),
                    onSelected: (i) => context.go(_tabs[i].path),
                    tabs: _tabs,
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

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.expanded,
    required this.showMenu,
    required this.selectedIndex,
    required this.onMenu,
    required this.onSelected,
    required this.tabs,
  });

  static const compactWidth = 80.0;
  static const extendedWidth = 200.0;

  final bool expanded;
  final bool showMenu;
  final int selectedIndex;
  final VoidCallback onMenu;
  final ValueChanged<int> onSelected;
  final List<({IconData icon, IconData activeIcon, String label, String path})>
  tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: SizedBox(
          key: const Key('main-rail'),
          width: expanded ? extendedWidth : compactWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMenu)
                IconButton(
                  key: const Key('rail-menu'),
                  alignment: Alignment.centerLeft,
                  tooltip: expanded ? '收起' : '展开',
                  icon: const Icon(Icons.menu),
                  onPressed: onMenu,
                ),
              for (var i = 0; i < tabs.length; i++)
                _RailDestination(
                  icon: tabs[i].icon,
                  activeIcon: tabs[i].activeIcon,
                  label: tabs[i].label,
                  selected: i == selectedIndex,
                  expanded: expanded,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final iconWidget = Icon(selected ? activeIcon : icon, color: color);
    final labelWidget = Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: expanded
                ? Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      labelWidget,
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconWidget,
                      const SizedBox(height: 4),
                      labelWidget,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
