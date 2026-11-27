// lib/features/home/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/window_layout_host.dart';

/// 列表-详情页宽屏只留两栏，不带主导航侧栏（资料、广场、设置）。
bool hidesMainRail(String path) {
  return path.startsWith('/settings') ||
      path.startsWith('/learn/library') ||
      path.startsWith('/square');
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
    final hideRail = wide && hidesMainRail(path);
    final showBottomBar = !wide && showsMainNavigation(path);

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        body: wide && !hideRail
            ? Row(
                children: [
                  _SideRail(
                    expanded: _railExpanded,
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
            ? _MainBottomBar(
                selectedIndex: index,
                tabs: _tabs,
                onSelected: (i) => context.go(_tabs[i].path),
              )
            : null,
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.expanded,
    required this.selectedIndex,
    required this.onMenu,
    required this.onSelected,
    required this.tabs,
  });

  static const compactWidth = 80.0;
  static const extendedWidth = 200.0;

  final bool expanded;
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
      textAlign: TextAlign.center,
      softWrap: true,
      maxLines: 2,
      overflow: TextOverflow.clip,
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
                      Flexible(child: labelWidget),
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

/// 底栏三项：大字号下允许换行，不裁成「…」。
class _MainBottomBar extends StatelessWidget {
  const _MainBottomBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<({IconData icon, IconData activeIcon, String label, String path})>
  tabs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final minHeight = 64.0 + (scale - 1).clamp(0.0, 1.2) * 28;

    return Material(
      key: const Key('main-bottom-bar'),
      color: scheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _BottomDestination(
                      icon: tabs[i].icon,
                      activeIcon: tabs[i].activeIcon,
                      label: tabs[i].label,
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomDestination extends StatelessWidget {
  const _BottomDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? scheme.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Icon(selected ? activeIcon : icon, color: color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
