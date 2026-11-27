// lib/features/profile/profile_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/avatar_image.dart';
import '../../core/avatar_url.dart';
import '../../core/models/badge.dart';
import '../../core/progress/progress_store.dart';
import '../../core/storage/secure_storage.dart';
import '../learn/learn_path.dart';

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.did,
    required this.nickname,
    this.avatarUrl,
    this.avatarBytes,
    required this.points,
    required this.unlocked,
    required this.rankings,
  });

  final String? did;
  final String? nickname;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final int points;
  final Set<String> unlocked;
  final List<Map<String, dynamic>> rankings;
}

/// 这次打开应用期间记住「我的」页，切换回来先显示它。
class ProfileCache {
  static ProfileSnapshot? latest;
  static int _ticket = 0;
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  static int begin() => ++_ticket;

  static bool isLatest(int ticket) => ticket == _ticket;

  static void clear() {
    latest = null;
    _ticket++;
  }

  /// 换头像后立刻改缓存，并作废还在飞的那次个人页加载。
  static void rememberAvatar(String? url, {Uint8List? bytes}) {
    final current = latest;
    if (current == null) return;
    final Uint8List? nextBytes;
    if (url == null) {
      nextBytes = null;
    } else if (bytes != null) {
      nextBytes = bytes;
    } else if (url == current.avatarUrl) {
      nextBytes = current.avatarBytes;
    } else {
      nextBytes = null;
    }
    _ticket++;
    latest = ProfileSnapshot(
      did: current.did,
      nickname: current.nickname,
      avatarUrl: url,
      avatarBytes: nextBytes,
      points: current.points,
      unlocked: current.unlocked,
      rankings: current.rankings,
    );
    _notify();
  }
}

class ProfileRepository {
  Future<ProfileSnapshot> load({ProfileSnapshot? previous}) async {
    final did = await SecureStorage.getDID();
    final base = previous != null && previous.did == did ? previous : null;

    String? nickname = base?.nickname;
    String? avatarUrl = base?.avatarUrl;
    Uint8List? avatarBytes = base?.avatarBytes;
    try {
      final res = await ApiClient.dio.get('/user/profile');
      final data = res.data;
      if (data is Map) {
        nickname = data['display_name'] as String?;
        final nextUrl = absoluteAvatarUrl(data['avatar_url'] as String?);
        avatarBytes = nextUrl == avatarUrl ? avatarBytes : null;
        avatarUrl = nextUrl;
      }
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      debugPrint('[档案] 拉取失败 status=$status $e');
    }

    if (avatarUrl != null && avatarBytes == null) {
      avatarBytes = await fetchAvatarBytes(avatarUrl);
    }
    debugPrint(
      '[档案] 昵称=${nickname ?? '空'} 头像=${avatarUrl == null ? '无' : '有'} 图片字节=${avatarBytes?.length ?? 0}',
    );

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
      avatarUrl: avatarUrl,
      avatarBytes: avatarBytes,
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
    final approve = await ProgressStore.hasFlag('game_done_game_approve');
    final stablecoin = await ProgressStore.hasFlag(
      'game_done_game_stablecoin',
    );
    final custody = await ProgressStore.hasFlag('game_done_game_custody');
    final multisig = await ProgressStore.hasFlag('game_done_game_multisig');
    final listing = await ProgressStore.hasFlag('game_done_game_listing');

    final hashMaster = await ProgressStore.hasFlag('game_done_game_hash_l3');
    return unlockedBadgeIdsFromProgress(
      hasDid: did != null && did.isNotEmpty,
      chapter1: progress.chapter1,
      chapter2: progress.chapter2,
      block: progress.block,
      hash: progress.hash,
      p2p: progress.p2p,
      antiscam: progress.antiscam,
      hashMaster: hashMaster,
      approve: approve,
      stablecoin: stablecoin,
      custody: custody,
      multisig: multisig,
      listing: listing,
    );
  }
}
