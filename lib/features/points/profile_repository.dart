// lib/features/profile/profile_repository.dart
import '../../core/api/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/models/badge.dart';
import '../learn/learn_path.dart';

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.did,
    required this.nickname,
    required this.points,
    required this.unlocked,
    required this.rankings,
  });

  final String? did;
  final String? nickname;
  final int points;
  final Set<String> unlocked;
  final List<Map<String, dynamic>> rankings;
}

/// 这次打开应用期间记住「我的」页，切换回来先显示它。
class ProfileCache {
  static ProfileSnapshot? latest;
  static int _ticket = 0;

  static int begin() => ++_ticket;

  static bool isLatest(int ticket) => ticket == _ticket;

  static void clear() {
    latest = null;
    _ticket++;
  }
}

class ProfileRepository {
  Future<ProfileSnapshot> load({ProfileSnapshot? previous}) async {
    final did = await SecureStorage.getDID();
    final base = previous != null && previous.did == did ? previous : null;

    String? nickname = base?.nickname;
    try {
      final res = await ApiClient.dio.get('/user/profile');
      nickname = res.data['display_name'] as String?;
    } catch (_) {}

    final points = await fetchTotalPoints();
    final rankings = await fetchLeaderboard();
    Set<String> unlocked;
    try {
      unlocked = await getUnlockedBadgeIds();
    } catch (_) {
      unlocked = base?.unlocked ?? {};
    }

    return ProfileSnapshot(
      did: did,
      nickname: nickname,
      points: points ?? base?.points ?? 0,
      unlocked: unlocked,
      rankings: rankings ?? base?.rankings ?? const [],
    );
  }

  // ── 积分（从服务端拉取） ──────────────────────────
  Future<int?> fetchTotalPoints() async {
    try {
      final res = await ApiClient.dio.get('/points/summary');
      return res.data['total_points'] as int? ?? 0;
    } catch (_) {
      return null;
    }
  }

  // ── 排行榜 ────────────────────────────────────────
  Future<List<Map<String, dynamic>>?> fetchLeaderboard() async {
    try {
      final res = await ApiClient.dio.get('/leaderboard');
      return List<Map<String, dynamic>>.from(res.data['rankings']);
    } catch (_) {
      return null;
    }
  }

  // ── 已解锁的徽章（本地进度判断） ─────────────────
  Future<Set<String>> getUnlockedBadgeIds() async {
    final did = await SecureStorage.getDID();
    final progress = await readLearnPathProgress();

    return unlockedBadgeIdsFromProgress(
      hasDid: did != null && did.isNotEmpty,
      chapter1: progress.chapter1,
      chapter2: progress.chapter2,
      block: progress.block,
      hash: progress.hash,
      p2p: progress.p2p,
      antiscam: progress.antiscam,
    );
  }
}
