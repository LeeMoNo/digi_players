import 'package:flutter/painting.dart';

/// 列表右箭头比默认右边距再近 5。
const chevronTilePadding = EdgeInsets.fromLTRB(16, 0, 11, 0);

EdgeInsets chevronPadding(EdgeInsets padding) {
  return padding.copyWith(right: padding.right - 5);
}
