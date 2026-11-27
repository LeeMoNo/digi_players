// lib/features/games/games_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/chevron_inset.dart';
import '../../core/layout/reading_width.dart';
import '../../core/progress/progress_store.dart';
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

class _Section {
  final String title;
  final List<_GameEntry> games;

  const _Section({required this.title, required this.games});
}

const _sections = [
  _Section(
    title: '机制',
    games: [
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
        id: 'game_hash',
        title: '哈希碰碰乐',
        description: '过第一关即可继续主路径；后两关是升级挑战，拨 Nonce 看前导零',
        route: '/games/hash',
        requiresChapter: 'ch_001',
        icon: Icons.tag,
        color: Colors.teal,
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
    ],
  ),
  _Section(
    title: '用链时',
    games: [
      _GameEntry(
        id: 'game_approve',
        title: '授权雷达',
        description: '分清连接与授权，看额度决定对方能转走多少',
        route: '/games/approve',
        requiresChapter: 'ch_002',
        icon: Icons.radar,
        color: Colors.deepPurple,
      ),
      _GameEntry(
        id: 'game_stablecoin',
        title: '稳定币天平',
        description: '拨储备与赎回压力，分清锚定承诺和兑付能力',
        route: '/games/stablecoin',
        requiresChapter: 'ch_002',
        icon: Icons.balance,
        color: Colors.blueGrey,
      ),
      _GameEntry(
        id: 'game_custody',
        title: '钥匙在谁手里',
        description: '分清柜台余额、自管地址，以及对方要你转去的地址',
        route: '/games/custody',
        requiresChapter: 'ch_002',
        icon: Icons.key,
        color: Colors.brown,
      ),
    ],
  ),
  _Section(
    title: '防骗进阶',
    games: [
      _GameEntry(
        id: 'game_antiscam',
        title: '反诈识别训练营',
        description: '真假判断 +「你会点哪」，练识别币圈常见套路',
        route: '/games/antiscam',
        requiresChapter: 'ch_002',
        icon: Icons.shield,
        color: Colors.orange,
      ),
      _GameEntry(
        id: 'game_multisig',
        title: '多签核对台',
        description: '对照意图与待签摘要，练在设备屏前拒签异常',
        route: '/games/multisig',
        requiresChapter: 'ch_002',
        icon: Icons.fact_check,
        color: Colors.indigo,
      ),
      _GameEntry(
        id: 'game_listing',
        title: '牌照与上下架',
        description: '读宣传与下架公告：法域保护边界，流动性先变差',
        route: '/games/listing',
        requiresChapter: 'ch_002',
        icon: Icons.gavel,
        color: Colors.blueGrey,
      ),
    ],
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
        final approve = await ProgressStore.hasFlag('game_done_game_approve');
        final stablecoin = await ProgressStore.hasFlag(
          'game_done_game_stablecoin',
        );
        final custody = await ProgressStore.hasFlag('game_done_game_custody');
        final multisig = await ProgressStore.hasFlag('game_done_game_multisig');
        final listing = await ProgressStore.hasFlag('game_done_game_listing');
        completed = <String>{
          if (progress.chapter1) 'ch_001',
          if (progress.chapter2) 'ch_002',
        };
        done = <String>{
          if (progress.block) 'game_block',
          if (progress.hash) 'game_hash',
          if (progress.p2p) 'game_p2p',
          if (progress.antiscam) 'game_antiscam',
          if (approve) 'game_approve',
          if (stablecoin) 'game_stablecoin',
          if (custody) 'game_custody',
          if (multisig) 'game_multisig',
          if (listing) 'game_listing',
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
      appBar: AppBar(title: const Text('练习')),
      body: ReadingWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final section in _sections) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final g in section.games) ...[
                _gameTile(g),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gameTile(_GameEntry g) {
    final done = _doneGames.contains(g.id);
    final unlocked = done || _completedChapters.contains(g.requiresChapter);
    return Card(
      child: ListTile(
        contentPadding: chevronPadding(const EdgeInsets.all(16)),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: unlocked ? g.color.withOpacity(0.15) : Colors.grey.shade100,
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
                  const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '完成"${g.requiresChapter == "ch_001" ? "区块链基础" : "密码学入门"}"后解锁',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
  }
}
