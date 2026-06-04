// lib/features/games/block_puzzle/block_puzzle_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import 'block_puzzle_data.dart';

class BlockPuzzleScreen extends StatefulWidget {
  const BlockPuzzleScreen({super.key});
  @override State<BlockPuzzleScreen> createState() => _State();
}

class _State extends State<BlockPuzzleScreen> {
  late List<PuzzleBlock> _blocks;
  final Set<String> _markedTampered = {}; // 玩家标记为"篡改"的块 id
  bool _gameDone  = false;
  bool _submitted = false;
  String? _seed;
  int _seconds = 0;
  Timer? _timer;

  // 判题结果
  bool _orderCorrect   = false;
  bool _tamperedCorrect = false;

  @override
  void initState() {
    super.initState();
    _blocks = buildScrambledBlocks();
    _fetchSeed();
    _startTimer();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post('/game/start',
          data: {'action_key': 'game_block_complete'});
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _toggleMark(String id) {
    setState(() {
      if (_markedTampered.contains(id)) {
        _markedTampered.remove(id);
      } else {
        _markedTampered.add(id);
      }
    });
  }

  Future<void> _submit() async {
    _timer?.cancel();
    final orderOk = validateChainOrder(_blocks);
    final tamperedIds = correctChain
        .where((b) => b.isTampered)
        .map((b) => b.id)
        .toSet();
    final tamperedOk = _markedTampered.length == 2 &&
        _markedTampered.containsAll(tamperedIds);

    setState(() {
      _orderCorrect    = orderOk;
      _tamperedCorrect = tamperedOk;
      _gameDone = true;
    });

    final passed = orderOk && tamperedOk;
    if (passed && _seed != null) {
      try {
        final did        = await SecureStorage.getDID() ?? '';
        final resultData = 'order:ok,tampered:ok,time:$_seconds';
        final proof      = buildProofHash(
          did:        did,
          actionKey:  'game_block_complete',
          seed:       _seed!,
          resultData: resultData,
        );
        await ApiClient.dio.post('/points/award', data: {
          'action_key':  'game_block_complete',
          'proof_hash':  proof,
          'result_data': resultData,
        });
        final box = await Hive.openBox('learn_progress');
        await box.put('game_done_game_block', true);
      } catch (_) {}
    }
    setState(() => _submitted = true);
  }

  String _timeStr() {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_gameDone && _submitted) return _buildResult();

    return Scaffold(
      appBar: AppBar(
        title: const Text('区块链拼图'),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(_timeStr(),
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 16)),
          )),
        ],
      ),
      body: Column(
        children: [
          // 提示栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            color: Theme.of(context)
                .colorScheme.primary.withOpacity(0.08),
            child: const Text(
              '拖拽排列区块，使链条合法。长按红色区块标记"篡改"。',
              style: TextStyle(fontSize: 13),
            ),
          ),

          // 可拖拽的区块列表
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _blocks.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final b = _blocks.removeAt(oldIdx);
                  _blocks.insert(newIdx, b);
                });
              },
              itemBuilder: (_, i) {
                final b       = _blocks[i];
                final marked  = _markedTampered.contains(b.id);
                final isFirst = i == 0;

                return _BlockCard(
                  key:     ValueKey(b.id),
                  block:   b,
                  index:   i,
                  marked:  marked,
                  isFirst: isFirst,
                  onMarkToggle: () => _toggleMark(b.id),
                );
              },
            ),
          ),

          // 底部操作栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_markedTampered.isNotEmpty)
                  Text(
                    '已标记 ${_markedTampered.length}/2 个篡改区块',
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('提交答案'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final passed = _orderCorrect && _tamperedCorrect;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(passed ? Icons.verified : Icons.replay,
                  size: 80,
                  color: passed ? Colors.green : Colors.orange),
              const SizedBox(height: 24),
              Text(passed ? '链条修复完成！' : '还需再试',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              _ResultRow(
                  label: '区块顺序', ok: _orderCorrect),
              const SizedBox(height: 8),
              _ResultRow(
                  label: '篡改识别', ok: _tamperedCorrect),
              const SizedBox(height: 8),
              Text('用时 ${_timeStr()}',
                  style: const TextStyle(color: Colors.grey)),
              if (passed) ...[
                const SizedBox(height: 12),
                const Text('积分已到账 🎉',
                    style: TextStyle(color: Colors.green)),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/games'),
                child: const Text('返回游戏列表'),
              ),
              if (!passed) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      context.replace('/game/block-puzzle'),
                  child: const Text('再来一次'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 子组件 ─────────────────────────────────────────────

class _BlockCard extends StatelessWidget {
  final PuzzleBlock block;
  final int index;
  final bool marked;
  final bool isFirst;
  final VoidCallback onMarkToggle;

  const _BlockCard({
    super.key,
    required this.block,
    required this.index,
    required this.marked,
    required this.isFirst,
    required this.onMarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = marked
        ? Colors.red
        : Theme.of(context).colorScheme.outline;

    return GestureDetector(
      onLongPress: onMarkToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: marked
              ? Colors.red.withOpacity(0.06)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // 拖拽手柄
            const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 前块哈希
                  Row(children: [
                    const Text('前块: ',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),
                    Text(
                      isFirst
                          ? '0000…0000 (创世块)'
                          : '${block.prevHash.substring(0, 8)}…',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                    ),
                  ]),
                  const SizedBox(height: 4),

                  // 交易数据
                  Text(block.txData,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),

                  // Nonce + 本块哈希
                  Row(children: [
                    Text('Nonce: ${block.nonce}  ',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                    Text('Hash: ${block.ownHash.substring(0, 8)}…',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey)),
                  ]),
                ],
              ),
            ),

            // 篡改标记指示
            if (marked)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.warning_amber,
                    color: Colors.red, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final bool ok;
  const _ResultRow({required this.label, required this.ok});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(ok ? Icons.check_circle : Icons.cancel,
          color: ok ? Colors.green : Colors.red, size: 20),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              color: ok ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600)),
    ],
  );
}