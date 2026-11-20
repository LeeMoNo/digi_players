// lib/features/games/p2p_game/p2p_game_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/fold_side.dart';
import '../../../core/router/app_back_button.dart';
import '../../../core/layout/window_layout.dart';
import '../../../core/layout/window_layout_host.dart';
import '../../../core/models/badge.dart';
import '../../../core/progress/progress_store.dart';
import '../../learn/learn_path.dart';
import '../earned_badge_note.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import 'p2p_game_data.dart';
import 'p2p_network_painter.dart';

class P2PGameScreen extends StatefulWidget {
  const P2PGameScreen({super.key});
  @override
  State<P2PGameScreen> createState() => _State();
}

class _State extends State<P2PGameScreen> {
  int _levelIndex = 0;
  Set<int> _reached = {0}; // 节点 0 已有消息
  int? _selected; // 当前激活的中继节点
  Set<int> _highlighted = {}; // 可转发的候选节点
  int _steps = 0;
  bool _levelDone = false;
  bool _gameDone = false;
  LearnPathStep? _next;
  List<BadgeItem> _earned = const [];
  bool _saveFailed = false;
  bool _saving = false;
  String? _seed;

  P2PLevel get _level => p2pLevels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _fetchSeed();
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_p2p_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _onNodeTap(int nodeId) {
    final node = _level.nodes[nodeId];
    if (node.isOffline) return;

    if (_selected == null) {
      // 第一次点击：选中"已有消息"的节点作为中继
      if (!_reached.contains(nodeId)) return;
      final neighbors = _level
          .neighborsOf(nodeId)
          .where((n) => !_reached.contains(n))
          .toSet();
      if (neighbors.isEmpty) return;
      setState(() {
        _selected = nodeId;
        _highlighted = neighbors;
      });
    } else {
      // 第二次点击：转发给候选邻居
      if (_highlighted.contains(nodeId)) {
        setState(() {
          _reached.add(nodeId);
          _steps++;
          _selected = null;
          _highlighted = {};

          // 检查本关是否通关
          final onlineNodes = _level.nodes
              .where((n) => !n.isOffline)
              .map((n) => n.id)
              .toSet();
          if (_reached.containsAll(onlineNodes)) {
            _levelDone = true;
          }
        });
      } else if (_reached.contains(nodeId)) {
        // 切换选中的中继节点
        final neighbors = _level
            .neighborsOf(nodeId)
            .where((n) => !_reached.contains(n))
            .toSet();
        setState(() {
          _selected = nodeId;
          _highlighted = neighbors;
        });
      } else {
        // 点击无效区域，取消选中
        setState(() {
          _selected = null;
          _highlighted = {};
        });
      }
    }
  }

  void _nextLevel() {
    if (_levelIndex < p2pLevels.length - 1) {
      setState(() {
        _levelIndex++;
        _reached = {0};
        _selected = null;
        _highlighted = {};
        _levelDone = false;
      });
    } else {
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    if (_saving) return;
    _saving = true;
    setState(() {
      _gameDone = true;
      _saveFailed = false;
    });
    final already = await ProgressStore.hasFlag('game_done_game_p2p');
    try {
      await ProgressStore.markFlag('game_done_game_p2p');
    } on ProgressNotSaved {
      _saving = false;
      if (!mounted) return;
      setState(() {
        _saveFailed = true;
        _next = null;
        _earned = const [];
      });
      return;
    }
    if (_seed != null) {
      try {
        final did = await SecureStorage.getDID() ?? '';
        final resultData = 'steps:$_steps';
        final proof = buildProofHash(
          did: did,
          actionKey: 'game_p2p_complete',
          seed: _seed!,
          resultData: resultData,
        );
        await ApiClient.dio.post(
          '/points/award',
          data: {
            'action_key': 'game_p2p_complete',
            'proof_hash': proof,
            'result_data': resultData,
          },
        );
      } catch (_) {}
    }
    final progress = await readLearnPathProgress();
    _saving = false;
    if (!mounted) return;
    setState(() {
      _saveFailed = false;
      _next = practiceClearDestination(practice: 'p2p', progress: progress);
      _earned = badgesJustEarned(
        practice: 'p2p',
        alreadyDone: already,
        pathComplete: progress.isComplete,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameDone) return _buildResult();

    final level = _level;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        leading: appBarLeading(context),
        backgroundColor: const Color(0xFF1A1D2E),
        foregroundColor: Colors.white,
        title: Text(
          'P2P 模拟器  关卡 ${_levelIndex + 1}/3',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _playBody(level),
    );
  }

  Widget _playBody(P2PLevel level) {
    final seam = WindowLayoutScope.foldOf(context);
    if (seam == null || !seam.horizontal) return _playColumn(level);
    return FoldFrame(
      builder: (context, origin) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final band = resolveHorizontalFold(
              height: constraints.maxHeight,
              originY: origin.dy,
              seam: seam,
            );
            if (!band.intersects) return _playColumn(level);
            if (!band.split) {
              final rect = band.anchorStart
                  ? Rect.fromLTWH(0, 0, constraints.maxWidth, band.top)
                  : Rect.fromLTWH(
                      0,
                      band.top + band.gap,
                      constraints.maxWidth,
                      band.bottom,
                    );
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fromRect(rect: rect, child: _playColumn(level)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                SizedBox(
                  height: band.top,
                  child: Column(
                    children: [
                      _description(level),
                      Expanded(child: _canvas(level)),
                    ],
                  ),
                ),
                SizedBox(height: band.gap),
                SizedBox(
                  height: band.bottom,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _legend(level),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _playColumn(P2PLevel level) {
    return Column(
      children: [
        _description(level),
        Expanded(child: _canvas(level)),
        _legend(level),
      ],
    );
  }

  Widget _description(P2PLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              level.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvas(P2PLevel level) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget paintIn(Rect canvas) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: canvas,
                  child: GestureDetector(
                    onTapUp: (details) {
                      final tap = details.localPosition;
                      int? tapped;
                      var minDist = 36.0;
                      for (final node in level.nodes) {
                        final center = Offset(
                          node.position.dx * canvas.width,
                          node.position.dy * canvas.height,
                        );
                        final dist = (tap - center).distance;
                        if (dist < minDist) {
                          minDist = dist;
                          tapped = node.id;
                        }
                      }
                      if (tapped != null) _onNodeTap(tapped);
                    },
                    child: CustomPaint(
                      size: Size(canvas.width, canvas.height),
                      painter: P2PNetworkPainter(
                        level: level,
                        reached: _reached,
                        selected: _selected,
                        highlighted: _highlighted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final seam = WindowLayoutScope.foldOf(context);
        final full = Rect.fromLTWH(
          0,
          0,
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (seam == null || !seam.vertical) return paintIn(full);
        return FoldFrame(
          builder: (context, origin) {
            return paintIn(
              foldFreeRect(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                origin: origin,
                seam: seam,
              ),
            );
          },
        );
      },
    );
  }

  Widget _legend(P2PLevel level) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.white.withOpacity(0.04),
      child: Column(
        children: [
          Text(
            _selected == null ? '点击绿色节点选为中继' : '点击蓝色节点转发消息',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Legend(color: Colors.green, label: '已收到'),
              _Legend(color: Colors.yellow, label: '中继中'),
              _Legend(color: Colors.blue, label: '可转发'),
              _Legend(color: Color(0xFF2D3250), label: '未收到'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '步数：$_steps  已到达：${_reached.length}/'
                '${level.nodes.where((n) => !n.isOffline).length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (_levelDone)
                FilledButton(
                  onPressed: _nextLevel,
                  child: Text(
                    _levelIndex < p2pLevels.length - 1 ? '下一关 →' : '完成！',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() => Scaffold(
    body: FoldSide(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hub, size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                '全网传播完成！',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text('共用 $_steps 步完成传播', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                '真实比特币网络中，一笔新交易\n平均 2 秒内传播到全球 90% 的节点。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.6),
              ),
              const SizedBox(height: 12),
              if (_saveFailed)
                const Text(
                  progressNotSavedMessage,
                  style: TextStyle(color: Colors.red),
                )
              else ...[
                const Text('进度已记下', style: TextStyle(color: Colors.green)),
                EarnedBadgeNote(badges: _earned),
              ],
              const SizedBox(height: 32),
              if (_saveFailed)
                FilledButton(
                  onPressed: _saving ? null : _submitScore,
                  child: const Text('再试一次'),
                )
              else if (_next != null)
                FilledButton(
                  onPressed: () => context.go(_next!.route),
                  child: Text(_next!.button),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ],
  );
}
