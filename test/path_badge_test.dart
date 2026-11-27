import 'package:digi_players/core/models/badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('走完两节课和四个练习后解锁路径完成', () {
    final ids = unlockedBadgeIdsFromProgress(
      hasDid: true,
      chapter1: true,
      chapter2: true,
      block: true,
      hash: true,
      p2p: true,
      antiscam: true,
    );

    expect(ids, contains(pathCompleteBadgeId));
    expect(
      allBadges.firstWhere((badge) => badge.id == pathCompleteBadgeId).name,
      '路径完成',
    );
  });

  test('没做拼图和 P2P 时不解锁路径完成', () {
    final ids = unlockedBadgeIdsFromProgress(
      hasDid: true,
      chapter1: true,
      chapter2: true,
      block: false,
      hash: true,
      p2p: false,
      antiscam: true,
      hashMaster: true,
    );

    expect(ids, isNot(contains(pathCompleteBadgeId)));
    expect(ids, contains('badge_hash_game'));
    expect(ids, contains('badge_antiscam'));
  });

  test('哈希只过第一关不发挖矿徽章，三关全通才发', () {
    final onlyGate = unlockedBadgeIdsFromProgress(
      hasDid: true,
      chapter1: true,
      chapter2: false,
      block: true,
      hash: true,
      p2p: false,
      antiscam: false,
    );
    expect(onlyGate, isNot(contains('badge_hash_game')));

    final master = unlockedBadgeIdsFromProgress(
      hasDid: true,
      chapter1: true,
      chapter2: false,
      block: true,
      hash: true,
      p2p: false,
      antiscam: false,
      hashMaster: true,
    );
    expect(master, contains('badge_hash_game'));
  });
}
