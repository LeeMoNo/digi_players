import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/split_pane.dart';
import 'square_chat_screen.dart';
import 'square_screen.dart';

/// `/square/chat/` 后面的房间 id。停在列表时没有。
String? squareRoomId(String path) {
  const prefix = '/square/chat/';
  if (!path.startsWith(prefix)) return null;
  final id = path.substring(prefix.length);
  if (id.isEmpty || id.contains('/')) return null;
  return id;
}

/// 壳正在分栏时，列表路由不要再画一份广场。
class SquareSplitScope extends InheritedWidget {
  const SquareSplitScope({
    super.key,
    required this.splitting,
    required super.child,
  });

  final bool splitting;

  static bool splittingOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SquareSplitScope>();
    return scope?.splitting ?? false;
  }

  @override
  bool updateShouldNotify(SquareSplitScope oldWidget) =>
      splitting != oldWidget.splitting;
}

/// 窄窗口直接显示当前路由。可双栏时左边是房间，右边是聊天或空状态。
class SquareSplitShell extends StatelessWidget {
  const SquareSplitShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitting = splitPaneFits(context, constraints);
        final roomId = squareRoomId(GoRouterState.of(context).uri.path);
        return SquareSplitScope(
          splitting: splitting,
          child: splitting
              ? SplitPane(
                  showDetail: roomId != null,
                  placeholder: const SquareChatScreen(
                    room: squareDefaultRoomId,
                    roomName: squareDefaultRoomName,
                  ),
                  list: SquareScreen(
                    selectedRoomId: roomId ?? squareDefaultRoomId,
                  ),
                  detail: child,
                )
              : child,
        );
      },
    );
  }
}

/// 可双栏时列表路由不再建一份广场，避免再请求一次个人资料。
class SquareRoute extends StatelessWidget {
  const SquareRoute({super.key});

  @override
  Widget build(BuildContext context) {
    if (SquareSplitScope.splittingOf(context)) {
      return const SizedBox.shrink();
    }
    return const SquareScreen();
  }
}
