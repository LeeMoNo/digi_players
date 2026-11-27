/// 稳定币天平：用储备构成与赎回压力，粗看锚定是否站得住。
///
/// 不模拟真实发行或交易，只帮玩家分清「报价接近 1 美元」和「兑得出来」。
enum PegReading {
  /// 报价贴近锚定，且安全储备大致够应付当前赎回。
  anchored,

  /// 报价明显离开 1 美元。
  depegged,

  /// 报价或许还在附近，但安全储备扛不住挤兑——兑付能力先裂。
  redeemStress,
}

class PegSnapshot {
  const PegSnapshot({
    required this.cash,
    required this.treasury,
    required this.risk,
    required this.pressure,
  });

  /// 现金类占比 0–100。三者之和应为 100。
  final double cash;
  final double treasury;
  final double risk;

  /// 赎回压力 0–100。
  final double pressure;

  double get safe => cash + treasury;

  /// 示意市价：主要被风险资产拖累；挤兑对价格影响较轻，却先伤兑付。
  double get impliedPrice {
    final raw = 1.0 - (risk / 100) * 0.25 - (pressure / 100) * 0.02;
    if (raw < 0.5) return 0.5;
    if (raw > 1.05) return 1.05;
    return double.parse(raw.toStringAsFixed(2));
  }

  PegReading get reading {
    final price = impliedPrice;
    final redeemGap = safe + 5 < pressure;
    // 报价尚未崩、但安全垫明显薄于挤兑 → 先读成兑付吃紧。
    if (redeemGap && price >= 0.90) return PegReading.redeemStress;
    if (price < 0.97) return PegReading.depegged;
    return PegReading.anchored;
  }
}

String pegReadingLabel(PegReading reading) {
  switch (reading) {
    case PegReading.anchored:
      return '仍接近锚定，兑付大致撑得住';
    case PegReading.depegged:
      return '已经脱锚';
    case PegReading.redeemStress:
      return '报价或许还在，兑付先撑不住';
  }
}

/// 交互关：把天平拨到「仍锚定」。
bool isHealthyPeg(PegSnapshot snapshot) =>
    snapshot.reading == PegReading.anchored;
