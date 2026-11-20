// lib/core/models/badge.dart
import 'package:flutter/material.dart';

class BadgeItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const pathCompleteBadgeId = 'badge_all_phase1';

/// 路径完成需要两节课和四个练习，不把注册本身算进去。
Set<String> unlockedBadgeIdsFromProgress({
  required bool hasDid,
  required bool chapter1,
  required bool chapter2,
  required bool block,
  required bool hash,
  required bool p2p,
  required bool antiscam,
}) {
  final unlocked = <String>{};
  if (hasDid) unlocked.add('badge_did');
  if (chapter1) unlocked.add('badge_ch001');
  if (chapter2) unlocked.add('badge_ch002');
  if (hash) unlocked.add('badge_hash_game');
  if (antiscam) unlocked.add('badge_antiscam');
  if (block) unlocked.add('badge_block_game');
  if (p2p) unlocked.add('badge_p2p_game');

  const pathSteps = {
    'badge_ch001',
    'badge_ch002',
    'badge_block_game',
    'badge_hash_game',
    'badge_p2p_game',
    'badge_antiscam',
  };
  if (unlocked.containsAll(pathSteps)) {
    unlocked.add(pathCompleteBadgeId);
  }
  return unlocked;
}

// 全部徽章定义
const allBadges = [
  BadgeItem(
    id: 'badge_did',
    name: '数字游民',
    description: '你弄懂了：这把钥匙只标识学习身份，不能收款。',
    icon: Icons.fingerprint,
    color: Colors.purple,
  ),
  BadgeItem(
    id: 'badge_ch001',
    name: '链上新手',
    description: '你弄懂了：多笔交易打包成区块，再按顺序连成账本。',
    icon: Icons.link,
    color: Colors.teal,
  ),
  BadgeItem(
    id: 'badge_ch002',
    name: '密码学者',
    description: '你弄懂了：助记词可以推出私钥，私钥不能交给别人。',
    icon: Icons.lock,
    color: Colors.blue,
  ),
  BadgeItem(
    id: 'badge_hash_game',
    name: '挖矿体验者',
    description: '你弄懂了：哈希前面要出现的零越多，就越难。',
    icon: Icons.hardware,
    color: Colors.orange,
  ),
  BadgeItem(
    id: 'badge_antiscam',
    name: '反诈达人',
    description: '你弄懂了：索要助记词、保本高收益、先转账才处理，都是骗局。',
    icon: Icons.shield,
    color: Colors.green,
  ),
  BadgeItem(
    id: 'badge_all_phase1',
    name: '路径完成',
    description: '你弄懂了账本、算力、广播，也认出了这些骗局。',
    icon: Icons.military_tech,
    color: Colors.amber,
  ),
  BadgeItem(
    id: 'badge_block_game',
    name: '链式思维者',
    description: '你弄懂了：改掉一笔已经入链的交易，后面的链接就对不上。',
    icon: Icons.extension,
    color: Colors.indigo,
  ),
  BadgeItem(
    id: 'badge_p2p_game',
    name: '网络节点',
    description: '你弄懂了：没有中心服务器，消息也能传遍网络。',
    icon: Icons.hub,
    color: Colors.teal,
  ),
];

BadgeItem? badgeById(String id) {
  for (final badge in allBadges) {
    if (badge.id == id) return badge;
  }
  return null;
}

/// 第一次通关才算获得。这一关补齐六步时，同时给出「路径完成」。
List<BadgeItem> badgesJustEarned({
  required String practice,
  required bool alreadyDone,
  required bool pathComplete,
}) {
  if (alreadyDone) return const [];
  final practiceId = switch (practice) {
    'block' => 'badge_block_game',
    'hash' => 'badge_hash_game',
    'p2p' => 'badge_p2p_game',
    'antiscam' => 'badge_antiscam',
    _ => null,
  };
  final earned = <BadgeItem>[];
  final practiceBadge = practiceId == null ? null : badgeById(practiceId);
  if (practiceBadge != null) earned.add(practiceBadge);
  if (pathComplete) {
    final done = badgeById(pathCompleteBadgeId);
    if (done != null) earned.add(done);
  }
  return earned;
}
