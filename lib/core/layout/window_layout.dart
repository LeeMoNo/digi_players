import 'dart:ui';

/// 窗口宽窄与能否双栏。纯函数，测试直接调用 [WindowLayout.resolve]。
class WindowLayout {
  const WindowLayout({required this.wide, required this.canSplit});

  /// 高窗口的最小高度。外屏横屏 466 高，停在窄窗口。
  static const minHeight = 480.0;

  /// 还没拿到 iOS size class 时，可用宽度达到这个值才算宽窗口。
  static const minUsableWidth = 600.0;

  /// 侧栏预留。图标在上、文字在下，不是展开的侧栏。
  static const railWidth = 80.0;

  /// 判断能不能分栏时，按这个宽度估算列表。排出来的两栏是对半，不固定用这个值。
  static const listWidth = 240.0;

  /// 双栏右侧至少要有这么宽。
  static const detailMinWidth = 320.0;

  static const readingMaxWidth = 720.0;

  static const formMaxWidth = 440.0;

  static const sizeClassChannel = 'digi_players/size_class';

  static const sizeClassMethod = 'getHorizontalSizeClass';

  static const foldMethod = 'getFoldDivision';

  /// 短边达到这个厚度，或者姿态是半折，才算要让开的缝。
  static const foldMinThickness = 8.0;

  /// 竖缝左侧去掉侧栏后，窄于这个宽度就不再双栏。
  static const foldMinList = 200.0;

  /// 竖缝右侧窄于这个宽度就不再双栏。
  static const foldMinDetail = 280.0;

  /// 横缝一侧矮于这个高度时，P2P 不再上下切开。
  static const foldMinSide = 160.0;

  /// 宽窗口用侧栏。窄窗口用底栏。
  final bool wide;

  /// 宽窗口里，扣掉侧栏和列表后详情仍放得下。
  final bool canSplit;

  /// [horizontalPadding] 是左右安全区之和，调用方分开量完再传入。
  /// 高度用窗口高度，不减上下安全区。
  static WindowLayout resolve({
    required double width,
    required double height,
    required double horizontalPadding,
    required HorizontalSizeClass sizeClass,
  }) {
    final rawUsable = width - horizontalPadding;
    final usable = rawUsable < 0 ? 0.0 : rawUsable;
    final tall = height >= minHeight;
    final wide = switch (sizeClass) {
      HorizontalSizeClass.compact => false,
      HorizontalSizeClass.regular => tall,
      HorizontalSizeClass.unspecified => tall && usable >= minUsableWidth,
    };
    final canSplit = wide && usable - railWidth - listWidth >= detailMinWidth;
    return WindowLayout(wide: wide, canSplit: canSplit);
  }

  /// 三栏时中栏和右栏对半。
  static double evenPaneWidth(double slot) {
    if (!slot.isFinite || slot <= 0) return 0;
    return slot / 2;
  }
}

enum HorizontalSizeClass {
  compact,
  regular,
  unspecified;

  static HorizontalSizeClass fromChannel(String? value) {
    return switch (value) {
      'compact' => HorizontalSizeClass.compact,
      'regular' => HorizontalSizeClass.regular,
      _ => HorizontalSizeClass.unspecified,
    };
  }
}

/// 一条要让开的折痕。坐标是当前视图的逻辑像素，不写回 [MediaQuery]。
class FoldSeam {
  const FoldSeam({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get shortSide => width < height ? width : height;

  /// 短边沿水平方向，是竖缝。
  bool get vertical => width <= height && width > 0 && height > 0;

  /// 短边沿垂直方向，是横缝。
  bool get horizontal => height < width && width > 0 && height > 0;

  Rect get rect => Rect.fromLTWH(left, top, width, height);

  bool overlaps(Rect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  @override
  bool operator ==(Object other) =>
      other is FoldSeam &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// Android 的 fold / hinge。平坦且短边小于 8 没有缝。刘海不算。
FoldSeam? foldSeamFromFeature({
  required String type,
  required String posture,
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  if (type != 'fold' && type != 'hinge') return null;
  final short = width < height ? width : height;
  final halfOpened = posture == 'halfOpened';
  if (posture == 'flat' && short < WindowLayout.foldMinThickness) return null;
  if (!halfOpened && short < WindowLayout.foldMinThickness) return null;
  if (short <= 0 || width <= 0 || height <= 0) return null;
  return FoldSeam(left: left, top: top, width: width, height: height);
}

/// iOS `getFoldDivision`。只有 active 为 true 才有缝。通道缺失时调用方当作没有缝。
FoldSeam? foldSeamFromChannel(Object? value) {
  if (value is! Map) return null;
  if (value['active'] != true) return null;
  final width = (value['width'] as num?)?.toDouble() ?? 0;
  final height = (value['height'] as num?)?.toDouble() ?? 0;
  if (width <= 0 || height <= 0) return null;
  return FoldSeam(
    left: (value['left'] as num?)?.toDouble() ?? 0,
    top: (value['top'] as num?)?.toDouble() ?? 0,
    width: width,
    height: height,
  );
}

/// 正在双栏时，竖缝把分界移到折痕上。一侧不够宽则退回单栏。
class FoldSplit {
  const FoldSplit({
    required this.split,
    required this.listWidth,
    required this.gap,
    required this.anchorStart,
  });

  final bool split;
  final double listWidth;
  final double gap;

  /// 单栏时整页放在折痕起点一侧。
  final bool anchorStart;
}

FoldSplit resolveFoldSplit({
  required double rightEdge,
  required double contentStart,
  FoldSeam? seam,
}) {
  final plain = FoldSplit(
    split: true,
    listWidth: WindowLayout.evenPaneWidth(rightEdge - contentStart),
    gap: 1,
    anchorStart: true,
  );
  if (seam == null || !seam.vertical) return plain;
  final left = seam.left - contentStart;
  final right = rightEdge - seam.right;
  if (left < WindowLayout.foldMinList || right < WindowLayout.foldMinDetail) {
    return FoldSplit(
      split: false,
      listWidth: WindowLayout.listWidth,
      gap: 1,
      anchorStart: left >= right,
    );
  }
  return FoldSplit(
    split: true,
    listWidth: left,
    gap: seam.width,
    anchorStart: true,
  );
}

/// 正文会穿过竖缝时，整段挪到较宽且不相交的一侧。返回 null 表示保持居中。
class FoldShift {
  const FoldShift({required this.left, required this.width});

  final double left;
  final double width;
}

FoldShift? shiftOffVerticalFold({
  required double width,
  required double maxWidth,
  required double originX,
  FoldSeam? seam,
}) {
  if (seam == null || !seam.vertical || !width.isFinite || width <= 0) {
    return null;
  }
  final localLeft = seam.left - originX;
  final localRight = seam.right - originX;
  if (localRight <= 0 || localLeft >= width) return null;

  final contentWidth = width < maxWidth ? width : maxWidth;
  final contentLeft = (width - contentWidth) / 2;
  final contentRight = contentLeft + contentWidth;
  final crosses = contentLeft < localRight && contentRight > localLeft;
  if (!crosses) return null;

  final leftSpace = localLeft.clamp(0.0, width);
  final rightSpace = (width - localRight).clamp(0.0, width);
  final useLeft = leftSpace >= rightSpace;
  final side = useLeft ? leftSpace : rightSpace;
  if (side <= 0) return null;
  final used = side < maxWidth ? side : maxWidth;
  final sideStart = useLeft ? 0.0 : localRight.clamp(0.0, width);
  return FoldShift(left: sideStart + (side - used) / 2, width: used);
}

/// 缝穿过这块区域时，返回不相交的较大一侧。没穿过就返回整块。
Rect foldFreeRect({
  required double width,
  required double height,
  required Offset origin,
  required FoldSeam seam,
}) {
  final full = Rect.fromLTWH(0, 0, width, height);
  if (seam.vertical) {
    final localLeft = seam.left - origin.dx;
    final localRight = seam.right - origin.dx;
    if (localRight <= 0 || localLeft >= width) return full;
    final leftSpace = localLeft.clamp(0.0, width);
    final rightSpace = (width - localRight).clamp(0.0, width);
    if (leftSpace >= rightSpace) {
      return Rect.fromLTWH(0, 0, leftSpace, height);
    }
    final start = localRight.clamp(0.0, width);
    return Rect.fromLTWH(start, 0, rightSpace, height);
  }
  if (!seam.horizontal) return full;
  final localTop = seam.top - origin.dy;
  final localBottom = seam.bottom - origin.dy;
  if (localBottom <= 0 || localTop >= height) return full;
  final above = localTop.clamp(0.0, height);
  final below = (height - localBottom).clamp(0.0, height);
  if (above >= below) return Rect.fromLTWH(0, 0, width, above);
  final start = localBottom.clamp(0.0, height);
  return Rect.fromLTWH(0, start, width, below);
}

/// P2P 横缝：以上是说明和画布，以下是图例和操作。一侧不足 160 则不切。
class HorizontalFold {
  const HorizontalFold({
    required this.intersects,
    required this.split,
    required this.top,
    required this.gap,
    required this.bottom,
    required this.anchorStart,
  });

  final bool intersects;
  final bool split;
  final double top;
  final double gap;
  final double bottom;
  final bool anchorStart;

  static const none = HorizontalFold(
    intersects: false,
    split: false,
    top: 0,
    gap: 0,
    bottom: 0,
    anchorStart: true,
  );
}

HorizontalFold resolveHorizontalFold({
  required double height,
  required double originY,
  FoldSeam? seam,
}) {
  if (seam == null || !seam.horizontal || !height.isFinite) {
    return HorizontalFold.none;
  }
  final localTop = seam.top - originY;
  final localBottom = seam.bottom - originY;
  if (localBottom <= 0 || localTop >= height) return HorizontalFold.none;
  final above = localTop.clamp(0.0, height);
  final below = (height - localBottom).clamp(0.0, height);
  final gap = (localBottom - localTop).clamp(0.0, height);
  if (above < WindowLayout.foldMinSide || below < WindowLayout.foldMinSide) {
    return HorizontalFold(
      intersects: true,
      split: false,
      top: above,
      gap: gap,
      bottom: below,
      anchorStart: above >= below,
    );
  }
  return HorizontalFold(
    intersects: true,
    split: true,
    top: above,
    gap: gap,
    bottom: below,
    anchorStart: true,
  );
}
