import 'package:flutter/material.dart';

import 'fold_side.dart';
import 'window_layout.dart';
import 'window_layout_host.dart';

/// 列表-详情。放不下双栏时只显示当前这一页。
class SplitPane extends StatelessWidget {
  const SplitPane({
    super.key,
    required this.showDetail,
    required this.list,
    required this.detail,
    required this.placeholder,
  });

  final bool showDetail;
  final Widget list;
  final Widget detail;

  /// 还没点进下一级时，右栏显示这一页，并让导航器留在树里。
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!splitPaneFits(context, constraints)) {
          return showDetail ? detail : list;
        }
        final seam = WindowLayoutScope.foldOf(context);
        if (seam == null || !seam.vertical) {
          return _panes(null, 0);
        }
        return FoldFrame(
          builder: (context, origin) {
            final plan = resolveFoldSplit(
              rightEdge: origin.dx + constraints.maxWidth,
              contentStart: origin.dx,
              seam: seam,
            );
            if (!plan.split) {
              return _onLargerSide(
                constraints,
                origin,
                seam,
                showDetail ? detail : list,
              );
            }
            return _panes(plan.listWidth, plan.gap);
          },
        );
      },
    );
  }

  Widget _onLargerSide(
    BoxConstraints constraints,
    Offset origin,
    FoldSeam seam,
    Widget page,
  ) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (!width.isFinite || !height.isFinite) return page;
    final rect = foldFreeRect(
      width: width,
      height: height,
      origin: origin,
      seam: seam,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [Positioned.fromRect(rect: rect, child: page)],
      ),
    );
  }

  Widget _panes(double? listWidth, double gap) {
    final detailPane = showDetail
        ? detail
        : Stack(
            children: [
              Offstage(child: detail),
              placeholder,
            ],
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listWidth == null)
          Expanded(child: list)
        else
          SizedBox(width: listWidth, child: list),
        if (gap > 1) SizedBox(width: gap),
        Expanded(child: detailPane),
      ],
    );
  }
}

/// 内容区（侧栏和安全区都已经留出）里是否还放得下列表加详情。
bool splitPaneFits(BuildContext context, BoxConstraints constraints) {
  if (!WindowLayoutScope.layoutOf(context).wide) return false;
  final slot = constraints.maxWidth;
  if (!slot.isFinite) return false;
  return slot - WindowLayout.listWidth >= WindowLayout.detailMinWidth;
}
