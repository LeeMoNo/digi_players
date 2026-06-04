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

// 全部徽章定义
const allBadges = [
  BadgeItem(
    id: 'badge_did',
    name: '数字游民',
    description: '完成 DID 注册，拥有去中心化身份',
    icon: Icons.fingerprint,
    color: Colors.purple,
  ),
  BadgeItem(
    id: 'badge_ch001',
    name: '链上新手',
    description: '完成区块链基础章节',
    icon: Icons.link,
    color: Colors.teal,
  ),
  BadgeItem(
    id: 'badge_ch002',
    name: '密码学者',
    description: '完成密码学入门章节',
    icon: Icons.lock,
    color: Colors.blue,
  ),
  BadgeItem(
    id: 'badge_hash_game',
    name: '挖矿体验者',
    description: '通关哈希碰碰乐，感受真实挖矿',
    icon: Icons.hardware,
    color: Colors.orange,
  ),
  BadgeItem(
    id: 'badge_antiscam',
    name: '反诈达人',
    description: '通关反诈识别训练营',
    icon: Icons.shield,
    color: Colors.green,
  ),
  BadgeItem(
    id: 'badge_all_phase1',
    name: 'Phase 1 先锋',
    description: '完成 Phase 1 全部内容',
    icon: Icons.military_tech,
    color: Colors.amber,
  ),
  BadgeItem(
    id: 'badge_block_game',
    name: '链式思维者',
    description: '通关区块链拼图',
    icon: Icons.extension,
    color: Colors.indigo,
  ),
  BadgeItem(
    id: 'badge_p2p_game',
    name: '网络节点',
    description: '通关 P2P 节点模拟器',
    icon: Icons.hub,
    color: Colors.teal,
  ),
];
