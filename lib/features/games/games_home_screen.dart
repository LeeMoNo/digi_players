// lib/features/games/games_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _GameEntry {
  final String id, title, description, route, requiresChapter;
  final IconData icon;
  final Color color;

  const _GameEntry({
    required this.id, required this.title, required this.description,
    required this.route, required this.requiresChapter,
    required this.icon, required this.color,
  });
}

const _games = [
  _GameEntry(
    id: 'game_hash', title: '哈希碰碰乐',
    description: '拨动 Nonce，让哈希开头出现足够多的零，感受真实挖矿难度',
    route: '/games/hash', requiresChapter: 'ch_001',
    icon: Icons.tag, color: Colors.teal,
  ),
  _GameEntry(
    id: 'game_antiscam', title: '反诈识别训练营',
    description: '10 道真实币圈套路题，测试你的反诈能力',
    route: '/games/antiscam', requiresChapter: 'ch_002',
    icon: Icons.shield, color: Colors.orange,
  ),
];

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key});
  @override State<GamesHomeScreen> createState() => _State();
}

class _State extends State<GamesHomeScreen> {
  Set<String> _completedChapters = {};

  @override
  void initState() { super.initState(); _loadProgress(); }

  Future<void> _loadProgress() async {
    final box = await Hive.openBox('learn_progress');
    final completed = <String>{};
    for (final g in _games) {
      if (box.get('completed_${g.requiresChapter}', defaultValue: false)) {
        completed.add(g.requiresChapter);
      }
    }
    if (mounted) setState(() => _completedChapters = completed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('游戏')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _games.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final g        = _games[i];
          final unlocked = _completedChapters.contains(g.requiresChapter);
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: unlocked ? g.color.withOpacity(0.15) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(g.icon,
                    color: unlocked ? g.color : Colors.grey, size: 26),
              ),
              title: Text(g.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? null : Colors.grey,
                  )),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(g.description,
                      style: TextStyle(
                          color: unlocked ? null : Colors.grey,
                          fontSize: 13)),
                  if (!unlocked) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '完成"${g.requiresChapter == "ch_001" ? "区块链基础" : "密码学入门"}"后解锁',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ]),
                  ],
                ],
              ),
              trailing: unlocked
                  ? const Icon(Icons.chevron_right)
                  : const Icon(Icons.lock_outline, color: Colors.grey),
              onTap: unlocked ? () => context.push(g.route) : null,
            ),
          );
        },
      ),
    );
  }
}