import 'package:flutter/widgets.dart';

import 'fold_side.dart';
import 'window_layout.dart';
import 'window_layout_host.dart';

/// 把正文或表单限在 [maxWidth] 内并水平居中。高度跟父级走，不把页面收成一块卡片。
class ReadingWidth extends StatelessWidget {
  const ReadingWidth({
    super.key,
    required this.child,
    this.maxWidth = WindowLayout.readingMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final seam = WindowLayoutScope.foldOf(context);
    if (seam == null || !seam.vertical) return _centered(null);
    return FoldFrame(
      builder: (context, origin) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final shift = shiftOffVerticalFold(
              width: constraints.maxWidth,
              maxWidth: maxWidth,
              originX: origin.dx,
              seam: seam,
            );
            return _box(constraints.maxHeight, shift);
          },
        );
      },
    );
  }

  Widget _centered(double? height) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _box(height ?? constraints.maxHeight, null),
    );
  }

  Widget _box(double height, FoldShift? shift) {
    final bounded = height.isFinite;
    final box = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: shift?.width ?? 0,
        maxWidth: shift?.width ?? maxWidth,
        minHeight: bounded ? height : 0,
        maxHeight: bounded ? height : double.infinity,
      ),
      child: child,
    );
    if (shift == null) {
      return Align(alignment: Alignment.topCenter, child: box);
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: shift.left),
        child: box,
      ),
    );
  }
}
