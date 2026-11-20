import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/split_pane.dart';
import '../home/data/home_content.dart';
import 'library_screen.dart';

/// `/learn/library` 后面的那一段年代 id。停在目录时没有。
String? libraryEraId(String path) {
  const prefix = '/learn/library/';
  if (!path.startsWith(prefix)) return null;
  final id = path.substring(prefix.length);
  if (id.isEmpty || id.contains('/')) return null;
  return id;
}

/// 壳正在分栏时，目录路由不要再画一份列表。
class LibrarySplitScope extends InheritedWidget {
  const LibrarySplitScope({
    super.key,
    required this.splitting,
    required super.child,
  });

  final bool splitting;

  static bool splittingOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LibrarySplitScope>();
    return scope?.splitting ?? false;
  }

  @override
  bool updateShouldNotify(LibrarySplitScope oldWidget) =>
      splitting != oldWidget.splitting;
}

/// 窄窗口直接显示当前路由。可双栏时左边是目录，右边是年代或空状态。
class LibrarySplitShell extends StatelessWidget {
  const LibrarySplitShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitting = splitPaneFits(context, constraints);
        final eraId = libraryEraId(GoRouterState.of(context).uri.path);
        final firstId = HomeContent.eraSections.first.id;
        return LibrarySplitScope(
          splitting: splitting,
          child: splitting
              ? SplitPane(
                  showDetail: eraId != null,
                  placeholder: EraDetailScreen(eraId: firstId),
                  list: LibraryScreen(selectedEraId: eraId ?? firstId),
                  detail: child,
                )
              : child,
        );
      },
    );
  }
}

/// 可双栏时目录路由不再建一份列表，避免和壳里的目录叠在一起。
class LibraryRoute extends StatelessWidget {
  const LibraryRoute({super.key});

  @override
  Widget build(BuildContext context) {
    if (LibrarySplitScope.splittingOf(context)) {
      return const SizedBox.shrink();
    }
    return const LibraryScreen();
  }
}
