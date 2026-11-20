import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/split_pane.dart';
import 'settings_screen.dart';

/// `/settings/` 后面的子页。停在设置列表时没有。
String? settingsDetailId(String path) {
  const prefix = '/settings/';
  if (!path.startsWith(prefix)) return null;
  final id = path.substring(prefix.length);
  if (id.isEmpty || id.contains('/')) return null;
  return id;
}

/// 壳正在分栏时，列表路由不要再画一份设置。
class SettingsSplitScope extends InheritedWidget {
  const SettingsSplitScope({
    super.key,
    required this.splitting,
    required super.child,
  });

  final bool splitting;

  static bool splittingOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SettingsSplitScope>();
    return scope?.splitting ?? false;
  }

  @override
  bool updateShouldNotify(SettingsSplitScope oldWidget) =>
      splitting != oldWidget.splitting;
}

/// 窄窗口直接显示当前路由。可双栏时左边是设置，右边是子页或空状态。
class SettingsSplitShell extends StatelessWidget {
  const SettingsSplitShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitting = splitPaneFits(context, constraints);
        final detailId = settingsDetailId(GoRouterState.of(context).uri.path);
        return SettingsSplitScope(
          splitting: splitting,
          child: splitting
              ? SplitPane(
                  showDetail: detailId != null,
                  emptyText: '选一项',
                  list: SettingsScreen(selectedDetail: detailId),
                  detail: child,
                )
              : child,
        );
      },
    );
  }
}

/// 可双栏时列表路由不再建一份设置。
class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    if (SettingsSplitScope.splittingOf(context)) {
      return const SizedBox.shrink();
    }
    return const SettingsScreen();
  }
}
