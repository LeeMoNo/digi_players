// lib/features/games/hash_game/hash_game_progress.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/secure_storage.dart';
import 'hash_game_logic.dart';

/// 哈希碰碰乐的中途进度：下次进来从这一关继续。
class HashGameCheckpoint {
  const HashGameCheckpoint({
    required this.level,
    required this.solvedNonces,
  });

  static const start = HashGameCheckpoint(level: 0, solvedNonces: []);

  /// 下次应展示的关卡下标（0/1/2）。
  final int level;

  /// 已通关卡对应的 nonce，供最终积分上报。
  final List<int> solvedNonces;

  @override
  bool operator ==(Object other) =>
      other is HashGameCheckpoint &&
      other.level == level &&
      _listEquals(other.solvedNonces, solvedNonces);

  @override
  int get hashCode => Object.hash(level, Object.hashAll(solvedNonces));

  static bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class HashGameProgress {
  static const boxName = 'hash_game_progress';
  static const _levelSuffix = '_level';
  static const _noncesSuffix = '_nonces';

  /// 测试可注入，避免 widget 测试依赖 Hive 时序。
  @visibleForTesting
  static Future<HashGameCheckpoint> Function()? debugLoadOverride;

  @visibleForTesting
  static Future<void> Function(HashGameCheckpoint checkpoint)? debugSaveOverride;

  @visibleForTesting
  static Future<void> Function()? debugClearOverride;

  /// 读取中途进度。无 DID、未存过或数据异常时回到第一关。
  static Future<HashGameCheckpoint> load() async {
    final override = debugLoadOverride;
    if (override != null) return override();
    try {
      final key = await _storageKey();
      final box = await Hive.openBox(boxName);
      final rawLevel = box.get('$key$_levelSuffix', defaultValue: 0);
      final rawNonces = box.get('$key$_noncesSuffix', defaultValue: const <dynamic>[]);
      return normalize(
        level: rawLevel is int ? rawLevel : 0,
        solvedNonces: _asIntList(rawNonces),
      );
    } catch (_) {
      return HashGameCheckpoint.start;
    }
  }

  /// 记下「下一关」和下一步要用的已解 nonce。
  static Future<void> save(HashGameCheckpoint checkpoint) async {
    final normalized = normalize(
      level: checkpoint.level,
      solvedNonces: checkpoint.solvedNonces,
    );
    final override = debugSaveOverride;
    if (override != null) {
      await override(normalized);
      return;
    }
    try {
      final key = await _storageKey();
      final box = await Hive.openBox(boxName);
      await box.put('$key$_levelSuffix', normalized.level);
      await box.put('$key$_noncesSuffix', normalized.solvedNonces);
    } catch (_) {
      // 本地记不住不阻断游戏
    }
  }

  static Future<void> clear() async {
    final override = debugClearOverride;
    if (override != null) {
      await override();
      return;
    }
    try {
      final key = await _storageKey();
      final box = await Hive.openBox(boxName);
      await box.delete('$key$_levelSuffix');
      await box.delete('$key$_noncesSuffix');
    } catch (_) {}
  }

  /// 校正关卡与 nonce 列表长度；非法则回到第一关。
  static HashGameCheckpoint normalize({
    required int level,
    required List<int> solvedNonces,
  }) {
    final maxLevel = HashGameLogic.levels.length;
    if (level <= 0 || level >= maxLevel) {
      return HashGameCheckpoint.start;
    }
    if (solvedNonces.length < level) {
      return HashGameCheckpoint.start;
    }
    return HashGameCheckpoint(
      level: level,
      solvedNonces: List<int>.unmodifiable(solvedNonces.take(level)),
    );
  }

  static Future<String> _storageKey() async {
    final did = await SecureStorage.getDID();
    if (did == null || did.isEmpty) return 'local';
    return did;
  }

  static List<int> _asIntList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <int>[];
    for (final item in raw) {
      if (item is int) {
        out.add(item);
      } else if (item is num) {
        out.add(item.toInt());
      } else {
        return const [];
      }
    }
    return out;
  }
}
