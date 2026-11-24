// lib/features/games/block_puzzle/block_puzzle_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/fold_side.dart';
import '../../../core/router/app_back_button.dart';
import '../../../core/models/badge.dart';
import '../../../core/progress/progress_store.dart';
import '../../learn/learn_path.dart';
import '../earned_badge_note.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import 'block_puzzle_data.dart';

class BlockPuzzleScreen extends StatefulWidget {
  const BlockPuzzleScreen({
    super.key,
    this.fetchSeed = true,
    this.initialBlocks,
    this.trackTime = true,
  });

  /// 测试可关掉，避免请求开局接口。
  final bool fetchSeed;

  /// 测试可传入固定顺序。
  final List<PuzzleBlock>? initialBlocks;

  /// 测试可关掉计时，避免周期性刷新。
  final bool trackTime;

  @override
  State<BlockPuzzleScreen> createState() => _State();
}

class _State extends State<BlockPuzzleScreen> {
  late List<PuzzleBlock> _blocks;
  final Set<String> _markedTampered = {}; // 玩家标记为"篡改"的块 id
  bool _gameDone = false;
  LearnPathStep? _next;
  List<BadgeItem> _earned = const [];
  bool _submitted = false;
  bool _saveFailed = false;
  bool _saving = false;
  String? _seed;
  int _seconds = 0;
  Timer? _timer;

  // 判题结果
  bool _orderCorrect = false;
  bool _tamperedCorrect = false;

  @override
  void initState() {
    super.initState();
    _blocks = List<PuzzleBlock>.from(
      widget.initialBlocks ?? buildScrambledBlocks(),
    );
    if (widget.fetchSeed) _fetchSeed();
    if (widget.trackTime) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_block_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _playAgain() {
    _timer?.cancel();
    setState(() {
      _blocks = List<PuzzleBlock>.from(
        widget.initialBlocks ?? buildScrambledBlocks(),
      );
      _markedTampered.clear();
      _gameDone = false;
      _submitted = false;
      _orderCorrect = false;
      _tamperedCorrect = false;
      _saveFailed = false;
      _next = null;
      _earned = const [];
      _seconds = 0;
    });
    if (widget.fetchSeed) _fetchSeed();
    if (widget.trackTime) _startTimer();
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
    final tamperedOk =
        _markedTampered.length == 2 && _markedTampered.containsAll(tamperedIds);

    setState(() {
      _orderCorrect = orderOk;
      _tamperedCorrect = tamperedOk;
      _gameDone = true;
    });

    final passed = orderOk && tamperedOk;
    if (!passed) {
      if (!mounted) return;
      setState(() => _submitted = true);
      return;
    }
    await _recordPass();
  }

  Future<void> _recordPass() async {
    if (_saving) return;
    _saving = true;
    final already = await ProgressStore.hasFlag('game_done_game_block');
    try {
      await ProgressStore.markFlag('game_done_game_block');
    } on ProgressNotSaved {
      _saving = false;
      if (!mounted) return;
      setState(() {
        _saveFailed = true;
        _next = null;
        _earned = const [];
        _submitted = true;
      });
      return;
    }
    if (_seed != null) {
      try {
        final did = await SecureStorage.getDID() ?? '';
        final resultData = 'order:ok,tampered:ok,time:$_seconds';
        final proof = buildProofHash(
          did: did,
          actionKey: 'game_block_complete',
          seed: _seed!,
          resultData: resultData,
        );
        await ApiClient.dio.post(
          '/points/award',
          data: {
            'action_key': 'game_block_complete',
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
      _next = practiceClearDestination(practice: 'block', progress: progress);
      _earned = badgesJustEarned(
        practice: 'block',
        alreadyDone: already,
        pathComplete: progress.isComplete,
      );
      _submitted = true;
    });
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
        leading: appBarLeading(context),
        title: const Text('区块链拼图'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _timeStr(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: FoldSide(
        child: Column(
          children: [
            // 提示栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '按住区块上下拖，或拖左侧手柄。让每一块的「前块」接上上一块。',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '点右侧旗帜，标出和原文不同的 2 笔交易。',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '原文：${correctChain.map((block) => block.correctTxData).join(' · ')}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 可拖拽的区块列表
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(12),
                buildDefaultDragHandles: false,
                itemCount: _blocks.length,
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (newIdx > oldIdx) newIdx--;
                    final b = _blocks.removeAt(oldIdx);
                    _blocks.insert(newIdx, b);
                  });
                },
                itemBuilder: (_, i) {
                  final b = _blocks[i];
                  return _BlockCard(
                    key: ValueKey(b.id),
                    block: b,
                    index: i,
                    marked: _markedTampered.contains(b.id),
                    linked: linksToPrevious(_blocks, i),
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
                  Text(
                    '已标记 ${_markedTampered.length}/2 个篡改区块',
                    style: TextStyle(
                      color: _markedTampered.isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _submit, child: const Text('提交答案')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _orderCorrect && _tamperedCorrect;
    return Scaffold(
      body: FoldSide(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.verified : Icons.replay,
                  size: 80,
                  color: passed ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? '链条修复完成！' : '还需再试',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _ResultRow(label: '区块顺序', ok: _orderCorrect),
                const SizedBox(height: 8),
                _ResultRow(label: '篡改识别', ok: _tamperedCorrect),
                const SizedBox(height: 8),
                Text(
                  '用时 ${_timeStr()}',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (passed && _saveFailed) ...[
                  const SizedBox(height: 12),
                  const Text(
                    progressNotSavedMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ] else if (passed) ...[
                  const SizedBox(height: 12),
                  const Text('进度已记下', style: TextStyle(color: Colors.green)),
                  EarnedBadgeNote(badges: _earned),
                ],
                const SizedBox(height: 32),
                if (passed && _saveFailed)
                  FilledButton(
                    onPressed: _saving ? null : _recordPass,
                    child: const Text('再试一次'),
                  )
                else if (passed && _next != null)
                  FilledButton(
                    onPressed: () => context.go(_next!.route),
                    child: Text(_next!.button),
                  )
                else
                  FilledButton(
                    onPressed: () => context.go('/learn'),
                    child: const Text('返回学习'),
                  ),
                if (!passed) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _playAgain,
                    child: const Text('再来一次'),
                  ),
                ],
              ],
            ),
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
  final bool linked;
  final VoidCallback onMarkToggle;

  const _BlockCard({
    super.key,
    required this.block,
    required this.index,
    required this.marked,
    required this.linked,
    required this.onMarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = marked
        ? Colors.redAccent
        : linked
        ? Theme.of(context).colorScheme.outline
        : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
      decoration: BoxDecoration(
        color: marked
            ? Colors.red.withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const SizedBox(
              width: 40,
              height: 56,
              child: Icon(Icons.drag_handle, color: Colors.grey, size: 28),
            ),
          ),
          Expanded(
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '前块: ${prevHashLabel(block.prevHash)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          linked ? '接上了' : '对不上',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: linked
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      block.txData,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          'Nonce: ${block.nonce}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Hash: ${block.ownHash.substring(0, 8)}…',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: marked ? '取消篡改标记' : '标记为篡改',
            onPressed: onMarkToggle,
            icon: Icon(
              marked ? Icons.warning_amber : Icons.flag_outlined,
              color: marked ? Colors.redAccent : Colors.grey,
            ),
          ),
        ],
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
      Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? Colors.green : Colors.red,
        size: 20,
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: ok ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
