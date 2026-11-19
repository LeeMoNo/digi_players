// lib/features/profile/profile_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/models/badge.dart';

class ProfileRepository {
  static const _box = 'learn_progress';

  // ── 积分（从服务端拉取） ──────────────────────────
  Future<int> fetchTotalPoints() async {
    try {
      final res = await ApiClient.dio.get('/points/summary');
      return res.data['total_points'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ── 排行榜 ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final res = await ApiClient.dio.get('/leaderboard');
      return List<Map<String, dynamic>>.from(res.data['rankings']);
    } catch (_) {
      return [];
    }
  }

  // ── 已解锁的徽章（本地进度判断） ─────────────────
  Future<Set<String>> getUnlockedBadgeIds() async {
    final box = await Hive.openBox(_box);
    final did = await SecureStorage.getDID();
    bool flag(String key) => box.get(key, defaultValue: false) == true;

    return unlockedBadgeIdsFromProgress(
      hasDid: did != null && did.isNotEmpty,
      chapter1: flag('completed_ch_001'),
      chapter2: flag('completed_ch_002'),
      block: flag('game_done_game_block'),
      hash: flag('game_done_game_hash'),
      p2p: flag('game_done_game_p2p'),
      antiscam: flag('game_done_game_antiscam'),
    );
  }
}