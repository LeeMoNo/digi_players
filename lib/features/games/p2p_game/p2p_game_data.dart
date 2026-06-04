// lib/features/games/p2p_game/p2p_game_data.dart
import 'package:flutter/material.dart';

class P2PNode {
  final int id;
  final Offset position; // 0.0~1.0 的相对坐标
  final bool isOffline;  // 关卡 3 中的宕机节点

  const P2PNode({
    required this.id,
    required this.position,
    this.isOffline = false,
  });
}

class P2PLevel {
  final String title;
  final String description;
  final List<P2PNode> nodes;
  final List<(int, int)> edges; // 双向边

  const P2PLevel({
    required this.title,
    required this.description,
    required this.nodes,
    required this.edges,
  });

  // 获取某节点的所有在线邻居
  List<int> neighborsOf(int nodeId) {
    final neighbors = <int>[];
    for (final e in edges) {
      if (e.$1 == nodeId && !nodes[e.$2].isOffline) {
        neighbors.add(e.$2);
      }
      if (e.$2 == nodeId && !nodes[e.$1].isOffline) {
        neighbors.add(e.$1);
      }
    }
    return neighbors;
  }
}

final p2pLevels = [
  // ── 关卡 1：线性链 ────────────────────────────────
  P2PLevel(
    title: '线性网络',
    description: '最简单的拓扑：消息只能一路向前传',
    nodes: [
      P2PNode(id: 0, position: const Offset(0.10, 0.50)),
      P2PNode(id: 1, position: const Offset(0.25, 0.25)),
      P2PNode(id: 2, position: const Offset(0.42, 0.50)),
      P2PNode(id: 3, position: const Offset(0.58, 0.25)),
      P2PNode(id: 4, position: const Offset(0.75, 0.50)),
      P2PNode(id: 5, position: const Offset(0.90, 0.25)),
      P2PNode(id: 6, position: const Offset(0.58, 0.75)),
      P2PNode(id: 7, position: const Offset(0.75, 0.75)),
    ],
    edges: [
      (0, 1), (1, 2), (2, 3), (3, 4),
      (4, 5), (4, 6), (6, 7),
    ],
  ),

  // ── 关卡 2：网状拓扑 ──────────────────────────────
  P2PLevel(
    title: '网状网络',
    description: '多路径可选，找到最快的广播策略',
    nodes: [
      P2PNode(id: 0, position: const Offset(0.10, 0.50)),
      P2PNode(id: 1, position: const Offset(0.30, 0.20)),
      P2PNode(id: 2, position: const Offset(0.30, 0.80)),
      P2PNode(id: 3, position: const Offset(0.50, 0.50)),
      P2PNode(id: 4, position: const Offset(0.70, 0.20)),
      P2PNode(id: 5, position: const Offset(0.70, 0.80)),
      P2PNode(id: 6, position: const Offset(0.90, 0.35)),
      P2PNode(id: 7, position: const Offset(0.90, 0.65)),
    ],
    edges: [
      (0, 1), (0, 2), (0, 3),
      (1, 3), (1, 4),
      (2, 3), (2, 5),
      (3, 4), (3, 5),
      (4, 6), (5, 7),
      (6, 7),
    ],
  ),

  // ── 关卡 3：节点宕机 ──────────────────────────────
  P2PLevel(
    title: '节点宕机',
    description: '节点 3 离线了，消息必须绕路传播',
    nodes: [
      P2PNode(id: 0, position: const Offset(0.10, 0.50)),
      P2PNode(id: 1, position: const Offset(0.30, 0.20)),
      P2PNode(id: 2, position: const Offset(0.30, 0.80)),
      P2PNode(id: 3, position: const Offset(0.50, 0.50), isOffline: true),
      P2PNode(id: 4, position: const Offset(0.70, 0.20)),
      P2PNode(id: 5, position: const Offset(0.70, 0.80)),
      P2PNode(id: 6, position: const Offset(0.90, 0.35)),
      P2PNode(id: 7, position: const Offset(0.90, 0.65)),
    ],
    edges: [
      (0, 1), (0, 2), (0, 3),
      (1, 3), (1, 4),
      (2, 3), (2, 5),
      (3, 4), (3, 5),
      (4, 6), (5, 7),
      (6, 7),
    ],
  ),
];