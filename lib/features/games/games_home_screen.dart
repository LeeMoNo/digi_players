// lib/features/games/games_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/chevron_inset.dart';
import '../../core/layout/reading_width.dart';
import '../learn/learn_path.dart';

class _GameEntry {
  final String id, title, description, route, requiresChapter;
  final IconData icon;
  final Color color;

  const _GameEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.requiresChapter,
    required this.icon,
    required this.color,
  });
}

const _games = [
  _GameEntry(
    id: 'game_hash',
    title: '哈希碰碰乐',
    description: '拨动 Nonce，让哈希开头出现足够多的零，感受真实挖矿难度',
    route: '/games/hash',
    requiresChapter: 'ch_001',
    icon: Icons.tag,
    color: Colors.teal,
  ),
  _GameEntry(
    id: 'game_antiscam',
    title: '反诈识别训练营',
    description: '10 道真实币圈套路题，测试你的反诈能力',
    route: '/games/antiscam',
    requiresChapter: 'ch_002',
    icon: Icons.shield,
    color: Colors.orange,
  ),
  _GameEntry(
    id: 'game_block',
    title: '区块链拼图',
    description: '排列被打乱的区块，修复被篡改的交易数据',
    route: '/game/block-puzzle',
    requiresChapter: 'ch_001',
    icon: Icons.extension,
    color: Colors.indigo,
  ),
  _GameEntry(
    id: 'game_p2p',
    title: 'P2P 节点模拟器',
    description: '扮演网络节点，把消息传遍整个 P2P 网络',
    route: '/game/p2p',
    requiresChapter: 'ch_001',
    icon: Icons.hub,
    color: Colors.teal,
  ),
];

/// 这次打开应用期间记住练习页的解锁状态，再次进入先显示，再在后台更新。
class GamesHomeCache {
  static Set<String>? chapters;
  static Set<String>? games;
  static int _ticket = 0;

  static bool get hasData => chapters != null && games != null;

  static int begin() => ++_ticket;

  static bool isLatest(int ticket) => ticket == _ticket;

  static void clear() {
    chapters = null;
    games = null;
    _ticket++;
  }
}

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key, this.loadProgress});

  /// 测试可替换。返回已完成章节和已通关练习 id。
  final Future<({Set<String> chapters, Set<String> games})> Function()?
  loadProgress;

  @override
  State<GamesHomeScreen> createState() => _State();
}

class _State extends State<GamesHomeScreen> {
  Set<String> _completedChapters = {};
  Set<String> _doneGames = {};

  @override
  void initState() {
    super.initState();
    if (GamesHomeCache.hasData) {
      _completedChapters = GamesHomeCache.chapters!;
      _doneGames = GamesHomeCache.games!;
    }
    _loadProgress();
  }

  void _remember(Set<String> chapters, Set<String> games) {
    GamesHomeCache.chapters = chapters;
    GamesHomeCache.games = games;
    _completedChapters = chapters;
    _doneGames = games;
  }

  Future<void> _loadProgress() async {
    final ticket = GamesHomeCache.begin();
    try {
      final injected = widget.loadProgress;
      late final Set<String> completed;
      late final Set<String> done;
      if (injected != null) {
        final progress = await injected();
        completed = progress.chapters;
        done = progress.games;
      } else {
        final progress = await readLearnPathProgress();
        completed = <String>{
          if (progress.chapter1) 'ch_001',
          if (progress.chapter2) 'ch_002',
        };
        done = <String>{
          if (progress.block) 'game_block',
          if (progress.hash) 'game_hash',
          if (progress.p2p) 'game_p2p',
          if (progress.antiscam) 'game_antiscam',
        };
      }
      if (!GamesHomeCache.isLatest(ticket)) return;
      if (!mounted) {
        GamesHomeCache.chapters = completed;
        GamesHomeCache.games = done;
        return;
      }
      setState(() => _remember(completed, done));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('游戏')),
      body: ReadingWidth(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _games.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final g = _games[i];
            final done = _doneGames.contains(g.id);
            final unlocked =
                done || _completedChapters.contains(g.requiresChapter);
            return Card(
              child: ListTile(
                contentPadding: chevronPadding(const EdgeInsets.all(16)),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? g.color.withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    g.icon,
                    color: unlocked ? g.color : Colors.grey,
                    size: 26,
                  ),
                ),
                title: Text(
                  g.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      g.description,
                      style: TextStyle(
                        color: unlocked ? null : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '已完成',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ] else if (!unlocked) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '完成"${g.requiresChapter == "ch_001" ? "区块链基础" : "密码学入门"}"后解锁',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: done
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : unlocked
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.lock_outline, color: Colors.grey),
                onTap: unlocked ? () => context.push(g.route) : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
