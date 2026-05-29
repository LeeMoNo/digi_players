// lib/features/games/hash_game/hash_game_logic.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashGameLogic {
  /// 给定交易数据和 nonce，计算 SHA-256
  static String compute(String txData, int nonce) {
    final input  = '$txData:$nonce';
    final digest = sha256.convert(utf8.encode(input));
    return digest.toString();
  }

  /// 检查哈希是否满足难度要求（开头有 n 个零）
  static bool meetsDifficulty(String hash, int difficulty) {
    return hash.startsWith('0' * difficulty);
  }

  /// 三个难度关卡的交易数据（固定，保证可复现）
  static const List<String> levels = [
    'Alice->Bob:1BTC:2024-01-01',
    'Charlie->Dave:0.5ETH:2024-01-02',
    'Eve->Frank:100USDT:2024-01-03',
  ];

  /// 每关对应的难度
  static const List<int> difficulties = [1, 2, 3];

  /// 每关的提示：这个 nonce 附近一定有解（降低挫败感）
  /// 实际上就是预算好的参考答案区间
  static String hint(int levelIndex) {
    switch (levelIndex) {
      case 0: return '提示：Nonce 在 0 ~ 100 之间就能找到';
      case 1: return '提示：Nonce 在 100 ~ 2000 之间';
      case 2: return '提示：Nonce 在 1000 ~ 50000 之间，耐心找';
      default: return '';
    }
  }
}