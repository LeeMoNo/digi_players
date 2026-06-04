// lib/features/games/p2p_game/p2p_game_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import 'p2p_game_data.dart';
import 'p2p_network_painter.dart';

class P2PGameScreen extends StatefulWidget {
  const P2PGameScreen({super.key});
  @override State<P2PGameScreen> createState() => _State();
}

class _State extends State<P2PGameScreen> {
  int         _levelIndex = 0;
  Set<int>    _reached    = {0}; // 节点 0 已有消息
  int?        _selected;         // 当前激活的中继节点
  Set<int>    _highlighted = {}; // 可转发的候选节点
  int         _steps      = 0;
  bool        _levelDone  = false;
  bool        _gameDone   = false;
  String?     _seed;

  P2PLevel get _level => p2pLevels[_levelIndex];

  @override
  void initState() { super.initState(); _fetchSeed(); }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post('/game/start',
          data: {'action_key': 'game_p2p_complete'});
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _onNodeTap(int nodeId) {
    final node = _level.nodes[nodeId];
    if (node.isOffline) return;

    if (_selected == null) {
      // 第一次点击：选中"已有消息"的节点作为中继
      if (!_reached.contains(nodeId)) return;
      final neighbors = _level.neighborsOf(nodeId)
          .where((n) => !_reached.contains(n))
          .toSet();
      if (neighbors.isEmpty) return;
      setState(() {
        _selected    = nodeId;
        _highlighted = neighbors;
      });
    } else {
      // 第二次点击：转发给候选邻居
      if (_highlighted.contains(nodeId)) {
        setState(() {
          _reached.add(nodeId);
          _steps++;
          _selected    = null;
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
        final neighbors = _level.neighborsOf(nodeId)
            .where((n) => !_reached.contains(n))
            .toSet();
        setState(() {
          _selected    = nodeId;
          _highlighted = neighbors;
        });
      } else {
        // 点击无效区域，取消选中
        setState(() { _selected = null; _highlighted = {}; });
      }
    }
  }

  void _nextLevel() {
    if (_levelIndex < p2pLevels.length - 1) {
      setState(() {
        _levelIndex++;
        _reached     = {0};
        _selected    = null;
        _highlighted = {};
        _levelDone   = false;
      });
    } else {
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    setState(() => _gameDone = true);
    if (_seed != null) {
      try {
        final did        = await SecureStorage.getDID() ?? '';
        final resultData = 'steps:$_steps';
        final proof      = buildProofHash(
          did:        did,
          actionKey:  'game_p2p_complete',
          seed:       _seed!,
          resultData: resultData,
        );
        await ApiClient.dio.post('/points/award', data: {
          'action_key':  'game_p2p_complete',
          'proof_hash':  proof,
          'result_data': resultData,
        });
        final box = await Hive.openBox('learn_progress');
        await box.put('game_done_game_p2p', true);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameDone) return _buildResult();

    final level = _level;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        foregroundColor: Colors.white,
        title: Text('P2P 模拟器  关卡 ${_levelIndex + 1}/3',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // 关卡说明
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            color: Colors.white.withOpacity(0.05),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(level.description,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ),
            ]),
          ),

          // 网络画布
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) => GestureDetector(
                onTapUp: (details) {
                  // 把点击坐标转换为节点 id
                  final tap    = details.localPosition;
                  final width  = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  int? tapped;
                  double minDist = 36;
                  for (final node in level.nodes) {
                    final center = Offset(
                        node.position.dx * width,
                        node.position.dy * height);
                    final dist = (tap - center).distance;
                    if (dist < minDist) {
                      minDist = dist;
                      tapped  = node.id;
                    }
                  }
                  if (tapped != null) _onNodeTap(tapped);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth,
                      constraints.maxHeight),
                  painter: P2PNetworkPainter(
                    level:       level,
                    reached:     _reached,
                    selected:    _selected,
                    highlighted: _highlighted,
                  ),
                ),
              ),
            ),
          ),

          // 图例 + 状态栏
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white.withOpacity(0.04),
            child: Column(
              children: [
                // 操作提示
                Text(
                  _selected == null
                      ? '点击绿色节点选为中继'
                      : '点击蓝色节点转发消息',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),

                // 图例
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _Legend(color: Colors.green,  label: '已收到'),
                    _Legend(color: Colors.yellow, label: '中继中'),
                    _Legend(color: Colors.blue,   label: '可转发'),
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
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    if (_levelDone)
                      FilledButton(
                        onPressed: _nextLevel,
                        child: Text(
                            _levelIndex < p2pLevels.length - 1
                                ? '下一关 →'
                                : '完成！'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hub, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            Text('全网传播完成！',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text('共用 $_steps 步完成传播',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              '真实比特币网络中，一笔新交易\n平均 2 秒内传播到全球 90% 的节点。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.6),
            ),
            const SizedBox(height: 12),
            const Text('积分已到账 🎉',
                style: TextStyle(color: Colors.green)),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/games'),
              child: const Text('返回游戏列表'),
            ),
          ],
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
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: Colors.white54, fontSize: 11)),
    ],
  );
}