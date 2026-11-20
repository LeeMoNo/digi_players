import 'dart:math';

/// 一次出题用的选项顺序。`order[展示下标]` 是数据里的原始下标。
class ShuffledOptions {
  const ShuffledOptions({required this.texts, required this.order});

  final List<String> texts;
  final List<int> order;

  int originalIndex(int displayIndex) => order[displayIndex];

  /// 打乱展示顺序。
  ///
  /// 两项保持真随机。若洗完总是对调，位置会再次固定。
  /// 三项及以上如果结果仍是原稿顺序，就对调前两项。
  factory ShuffledOptions.shuffle(List<String> options, {Random? random}) {
    final order = List<int>.generate(options.length, (index) => index);
    if (order.length > 1) {
      order.shuffle(random);
      if (order.length > 2 && _isOriginalOrder(order)) {
        final first = order[0];
        order[0] = order[1];
        order[1] = first;
      }
    }
    return ShuffledOptions(
      texts: [for (final index in order) options[index]],
      order: List<int>.unmodifiable(order),
    );
  }

  static bool _isOriginalOrder(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }
}
