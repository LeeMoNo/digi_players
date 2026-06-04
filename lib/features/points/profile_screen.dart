// lib/features/profile/profile_screen.dart
import 'package:digi_players/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/badge.dart';
import '../../core/storage/secure_storage.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _State();
}

class _State extends State<ProfileScreen> {
  final _repo = ProfileRepository();

  String?  _did;
  int      _points       = 0;
  Set<String> _unlocked  = {};
  List<Map<String, dynamic>> _rankings = [];
  bool     _loading      = true;
  String? _nickname;

  @override
  void initState() { super.initState(); _load(); }

  // 在 _load() 中，fetchTotalPoints 之前追加：
  Future<void> _load() async {
    final did = await SecureStorage.getDID();

    // 拉取服务端档案（包含昵称）
    String? nickname;
    try {
      final res = await ApiClient.dio.get('/user/profile');
      nickname = res.data['display_name'] as String?;
    } catch (_) {}

    final points   = await _repo.fetchTotalPoints();
    final unlocked = await _repo.getUnlockedBadgeIds();
    final rankings = await _repo.fetchLeaderboard();

    if (mounted) setState(() {
      _did      = did;
      _nickname = nickname;   // 新增 State 变量
      _points   = points;
      _unlocked = unlocked;
      _rankings = rankings;
      _loading  = false;
    });
  }

  String _shortDID(String did) {
    if (did.length <= 20) return did;
    return '${did.substring(0, 16)}...${did.substring(did.length - 6)}';
  }

  // 找到自己在排行榜的名次
  int? _myRank() {
    for (final r in _rankings) {
      if (r['did'] == _did) return r['rank'] as int;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final myRank = _myRank();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async { setState(() => _loading = true); await _load(); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 身份卡片 ──────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.fingerprint,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _nickname?.isNotEmpty == true ? _nickname! : '数字游民',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _did ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('DID 已复制')),
                                );
                              },
                              child: Row(children: [
                                Text(
                                  _shortDID(_did ?? ''),
                                  style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme.primary),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.copy,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme.primary),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 积分 + 排名 ───────────────────────────
              Row(children: [
                Expanded(
                  child: _StatCard(
                    label: '累计积分',
                    value: '$_points',
                    icon: Icons.stars_rounded,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: '全球排名',
                    value: myRank != null ? '#$myRank' : '—',
                    icon: Icons.leaderboard,
                    color: Colors.blue,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 徽章墙 ────────────────────────────────
              Text('徽章',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: allBadges.length,
                itemBuilder: (_, i) {
                  final b      = allBadges[i];
                  final earned = _unlocked.contains(b.id);
                  return _BadgeTile(badge: b, earned: earned);
                },
              ),
              const SizedBox(height: 20),

              // ── 排行榜 ────────────────────────────────
              Text('排行榜 Top 20',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_rankings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                _SectionCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < _rankings.length; i++) ...[
                        _RankRow(
                          rank:        _rankings[i]['rank'] as int,
                          displayName: _rankings[i]['display_name'] as String,
                          points:      _rankings[i]['total_points'] as int,
                          isMe:        _rankings[i]['did'] == _did,
                        ),
                        if (i < _rankings.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 子组件 ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    ),
  );
}

class _BadgeTile extends StatelessWidget {
  final BadgeItem badge;
  final bool earned;
  const _BadgeTile({required this.badge, required this.earned});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: badge.description,
    child: Container(
      decoration: BoxDecoration(
        color: earned
            ? badge.color.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned ? badge.color.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.icon,
            size: 32,
            color: earned ? badge.color : Colors.grey.shade300,
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: earned ? badge.color : Colors.grey.shade400,
            ),
          ),
          if (!earned)
            const Text('未解锁',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    ),
  );
}

class _RankRow extends StatelessWidget {
  final int rank, points;
  final String displayName;
  final bool isMe;
  const _RankRow({
    required this.rank, required this.displayName,
    required this.points, required this.isMe,
  });
  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1 ? Colors.amber
        : rank == 2 ? Colors.grey.shade400
        : rank == 3 ? const Color(0xFFCD7F32)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      color: isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
          : null,
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text(
            '#$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rankColor ?? Colors.grey,
              fontSize: rankColor != null ? 15 : 13,
            ),
          ),
        ),
        Expanded(
          child: Row(children: [
            Text(displayName,
                style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('我',
                    style: TextStyle(
                        color: Colors.white, fontSize: 10)),
              ),
            ],
          ]),
        ),
        Text('$points 分',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}