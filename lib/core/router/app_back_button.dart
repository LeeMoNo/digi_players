import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 嵌套壳的第一页，最近的 Navigator 不能 pop，但路由栈还能回到进来之前的页面。
Widget? appBarLeading(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null || !router.canPop()) return null;
  final route = ModalRoute.of(context);
  if (route?.canPop ?? false) return null;
  return IconButton(
    key: const Key('app-back'),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const BackButtonIcon(),
    onPressed: () => context.pop(),
  );
}
