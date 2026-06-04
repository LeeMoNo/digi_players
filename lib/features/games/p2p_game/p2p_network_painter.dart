// lib/features/games/p2p_game/p2p_network_painter.dart
import 'package:flutter/material.dart';
import 'p2p_game_data.dart';

class P2PNetworkPainter extends CustomPainter {
  final P2PLevel level;
  final Set<int> reached;      // 已收到消息的节点
  final int? selected;         // 当前选中（准备转发）的节点
  final Set<int> highlighted;  // 可以被转发到的候选节点

  const P2PNetworkPainter({
    required this.level,
    required this.reached,
    this.selected,
    required this.highlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas, size);
    _drawNodes(canvas, size);
  }

  void _drawEdges(Canvas canvas, Size size) {
    for (final edge in level.edges) {
      final n1 = level.nodes[edge.$1];
      final n2 = level.nodes[edge.$2];

      final p1 = Offset(n1.position.dx * size.width,
          n1.position.dy * size.height);
      final p2 = Offset(n2.position.dx * size.width,
          n2.position.dy * size.height);

      final isOfflineEdge = n1.isOffline || n2.isOffline;

      final paint = Paint()
        ..color = isOfflineEdge
            ? Colors.grey.withOpacity(0.3)
            : Colors.white.withOpacity(0.25)
        ..strokeWidth = isOfflineEdge ? 1.0 : 1.5
        ..style = PaintingStyle.stroke;

      if (isOfflineEdge) {
        // 宕机边：虚线
        _drawDashedLine(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 6.0;
    const gapLen  = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = (p2 - p1).distance;
    final steps = dist / (dashLen + gapLen);
    for (int i = 0; i < steps; i++) {
      final t1 = i * (dashLen + gapLen) / dist;
      final t2 = (i * (dashLen + gapLen) + dashLen) / dist;
      canvas.drawLine(
        Offset(p1.dx + dx * t1, p1.dy + dy * t1),
        Offset(p1.dx + dx * t2.clamp(0, 1),
            p1.dy + dy * t2.clamp(0, 1)),
        paint,
      );
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    for (final node in level.nodes) {
      final center = Offset(
          node.position.dx * size.width,
          node.position.dy * size.height);

      // 节点颜色
      Color fillColor;
      if (node.isOffline) {
        fillColor = Colors.grey.shade800;
      } else if (node.id == selected) {
        fillColor = Colors.yellow.shade700;
      } else if (reached.contains(node.id)) {
        fillColor = Colors.green.shade600;
      } else if (highlighted.contains(node.id)) {
        fillColor = Colors.blue.shade400;
      } else {
        fillColor = const Color(0xFF2D3250);
      }

      // 外环（选中或候选时）
      if (node.id == selected || highlighted.contains(node.id)) {
        canvas.drawCircle(
          center, 26,
          Paint()
            ..color = (node.id == selected
                    ? Colors.yellow
                    : Colors.blue)
                .withOpacity(0.3)
            ..style = PaintingStyle.fill,
        );
      }

      // 节点圆
      canvas.drawCircle(
        center, 20,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );

      // 边框
      canvas.drawCircle(
        center, 20,
        Paint()
          ..color = node.isOffline
              ? Colors.grey.shade600
              : Colors.white.withOpacity(0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      // 节点编号
      final tp = TextPainter(
        text: TextSpan(
          text: node.isOffline ? '✗' : '${node.id}',
          style: TextStyle(
            color: node.isOffline ? Colors.grey : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(P2PNetworkPainter old) =>
      old.reached != reached ||
      old.selected != selected ||
      old.highlighted != highlighted;
}