import 'package:flutter/material.dart';

import '../../core/models/badge.dart';

class EarnedBadgeNote extends StatelessWidget {
  const EarnedBadgeNote({
    super.key,
    required this.badges,
    this.onDark = false,
  });

  final List<BadgeItem> badges;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    final titleColor = onDark ? Colors.white : null;
    final bodyColor = onDark ? Colors.white70 : null;
    return Column(
      children: [
        for (final badge in badges) ...[
          const SizedBox(height: 16),
          Icon(badge.icon, color: badge.color, size: 28),
          const SizedBox(height: 6),
          Text(
            '获得「${badge.name}」',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5, color: bodyColor),
          ),
        ],
      ],
    );
  }
}
