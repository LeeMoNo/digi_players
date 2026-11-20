import 'package:flutter/widgets.dart';

import 'window_layout.dart';
import 'window_layout_host.dart';

/// 有折痕时量一次自身在视图里的位置，再交给 [builder]。
class FoldFrame extends StatefulWidget {
  const FoldFrame({super.key, required this.builder});

  final Widget Function(BuildContext context, Offset origin) builder;

  @override
  State<FoldFrame> createState() => _FoldFrameState();
}

class _FoldFrameState extends State<FoldFrame> {
  Offset? _origin;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
    return widget.builder(context, _origin ?? Offset.zero);
  }

  void _capture() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final next = box.localToGlobal(Offset.zero);
    if (next == _origin) return;
    setState(() => _origin = next);
  }
}

/// 整页放到与折痕不相交的较大一侧。没有缝时原样显示。
class FoldSide extends StatelessWidget {
  const FoldSide({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final seam = WindowLayoutScope.foldOf(context);
    if (seam == null) return child;
    return FoldFrame(
      builder: (context, origin) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            if (!width.isFinite || !height.isFinite) return child;
            final rect = foldFreeRect(
              width: width,
              height: height,
              origin: origin,
              seam: seam,
            );
            if (rect.left == 0 &&
                rect.top == 0 &&
                rect.width == width &&
                rect.height == height) {
              return child;
            }
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [Positioned.fromRect(rect: rect, child: child)],
              ),
            );
          },
        );
      },
    );
  }
}
