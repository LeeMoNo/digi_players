import 'package:hive_flutter/hive_flutter.dart';

import '../api/api_client.dart';
import '../storage/secure_storage.dart';

const progressNotSavedMessage = '没记上，请再试一次';

const progressFlags = [
  'completed_ch_001',
  'completed_ch_002',
  'game_done_game_block',
  'game_done_game_hash',
  'game_done_game_p2p',
  'game_done_game_antiscam',
];

class ProgressNotSaved implements Exception {
  const ProgressNotSaved();
}

class ProgressStore {
  static const _syncedKey = 'synced';
  static const _cardsKey = 'read_cards';

  static String _boxName(String did) => 'progress_$did';

  /// 用服务端结果覆盖这个 DID 的缓存。失败时保留上次拉成功的那一份。
  static Future<bool> pull() async {
    final did = await SecureStorage.getDID();
    if (did == null || did.isEmpty) return false;
    try {
      final res = await ApiClient.dio.get('/user/progress');
      final data = res.data;
      if (data is! Map) return false;
      final rawFlags = data['flags'];
      final rawCards = data['read_cards'];
      if (rawFlags is! Map || rawCards is! List) return false;

      final box = await Hive.openBox(_boxName(did));
      for (final flag in progressFlags) {
        await box.put(flag, rawFlags[flag] == true);
      }
      await box.put(
        _cardsKey,
        rawCards.map((card) => card.toString()).toList(),
      );
      await box.put(_syncedKey, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, bool>> readFlags() async {
    final box = await _syncedBox();
    return {
      for (final flag in progressFlags)
        flag: box?.get(flag, defaultValue: false) == true,
    };
  }

  static Future<bool> hasFlag(String flag) async {
    final box = await _syncedBox();
    if (box == null) return false;
    return box.get(flag, defaultValue: false) == true;
  }

  static Future<Set<String>> readCards() async {
    final box = await _syncedBox();
    if (box == null) return {};
    return Set<String>.from(box.get(_cardsKey, defaultValue: <String>[]));
  }

  static Future<void> markFlag(String flag) async {
    if (!progressFlags.contains(flag)) {
      throw ArgumentError('Unknown progress flag: $flag');
    }
    await _post({'flag': flag});
    if (await pull()) return;
    final box = await _boxForCurrentDid();
    await box.put(flag, true);
    await box.put(_syncedKey, true);
  }

  static Future<void> markCard(String cardId) async {
    await _post({'card_id': cardId});
    if (await pull()) return;
    final box = await _boxForCurrentDid();
    final read = Set<String>.from(box.get(_cardsKey, defaultValue: <String>[]));
    read.add(cardId);
    await box.put(_cardsKey, read.toList());
    await box.put(_syncedKey, true);
  }

  static Future<void> _post(Map<String, String> data) async {
    final did = await SecureStorage.getDID();
    if (did == null || did.isEmpty) throw const ProgressNotSaved();
    try {
      await ApiClient.dio.post('/user/progress', data: data);
    } catch (_) {
      throw const ProgressNotSaved();
    }
  }

  static Future<Box<dynamic>> _boxForCurrentDid() async {
    final did = await SecureStorage.getDID();
    if (did == null || did.isEmpty) throw const ProgressNotSaved();
    return Hive.openBox(_boxName(did));
  }

  /// 这个 DID 还没拉成功过时返回 null，调用方把进度当成空的。
  static Future<Box<dynamic>?> _syncedBox() async {
    final did = await SecureStorage.getDID();
    if (did == null || did.isEmpty) return null;
    final box = await Hive.openBox(_boxName(did));
    if (box.get(_syncedKey, defaultValue: false) != true) return null;
    return box;
  }

  /// 删除账号成功后清掉本机该 DID 的进度缓存，避免同词再登录时短暂看到旧完成态。
  static Future<void> clearLocalCache() async {
    final did = await SecureStorage.getDID();
    if (did == null || did.isEmpty) return;
    await clearLocalCacheFor(did);
  }

  static Future<void> clearLocalCacheFor(String did) async {
    if (did.isEmpty) return;
    final box = await Hive.openBox(_boxName(did));
    await box.clear();
  }
}
