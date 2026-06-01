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
    final box      = await Hive.openBox(_box);
    final did      = await SecureStorage.getDID();
    final unlocked = <String>{};

    // badge_did：有 DID 就算
    if (did != null && did.isNotEmpty) unlocked.add('badge_did');

    // badge_ch001
    if (box.get('completed_ch_001', defaultValue: false)) {
      unlocked.add('badge_ch001');
    }

    // badge_ch002
    if (box.get('completed_ch_002', defaultValue: false)) {
      unlocked.add('badge_ch002');
    }

    // badge_hash_game（游戏完成后写入 Hive）
    if (box.get('game_done_game_hash', defaultValue: false)) {
      unlocked.add('badge_hash_game');
    }

    // badge_antiscam
    if (box.get('game_done_game_antiscam', defaultValue: false)) {
      unlocked.add('badge_antiscam');
    }

    // badge_all_phase1：以上五枚全部解锁
    const phase1Required = {
      'badge_did', 'badge_ch001', 'badge_ch002',
      'badge_hash_game', 'badge_antiscam',
    };
    if (unlocked.containsAll(phase1Required)) {
      unlocked.add('badge_all_phase1');
    }

    return unlocked;
  }
}