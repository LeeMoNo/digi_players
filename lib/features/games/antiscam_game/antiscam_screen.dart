// lib/features/games/antiscam_game/antiscam_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import 'antiscam_data.dart';

class AntiscamScreen extends StatefulWidget {
  const AntiscamScreen({super.key});
  @override State<AntiscamScreen> createState() => _State();
}

class _State extends State<AntiscamScreen> {
  int     _index    = 0;
  int     _score    = 0;
  bool?   _answered;        // null=未答，true=正确，false=错误
  bool    _finished = false;
  bool    _loading  = false;
  String? _seed;

  static const _passScore = 7; // 10题中至少对7题

  @override
  void initState() { super.initState(); _fetchSeed(); }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post('/game/start',
          data: {'action_key': 'game_antiscam_complete'});
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _answer(bool playerSaysScam) {
    if (_answered != null) return;
    final correct = playerSaysScam == antiscamQuestions[_index].isScam;
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  void _next() {
    if (_index < antiscamQuestions.length - 1) {
      setState(() { _index++; _answered = null; });
    } else {
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    setState(() { _finished = true; _loading = true; });

    final passed = _score >= _passScore;
    if (passed && _seed != null) {
      try {
        final did        = await SecureStorage.getDID() ?? '';
        final resultData = '$_score/${antiscamQuestions.length}';
        final proof      = buildProofHash(
          did:        did,
          actionKey:  'game_antiscam_complete',
          seed:       _seed!,
          resultData: resultData,
        );
        await ApiClient.dio.post('/points/award', data: {
          'action_key':  'game_antiscam_complete',
          'proof_hash':  proof,
          'result_data': resultData,
        });
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult();

    final q = antiscamQuestions[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('反诈训练营  ${_index + 1}/${antiscamQuestions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 进度条
            LinearProgressIndicator(
                value: (_index + 1) / antiscamQuestions.length),
            const SizedBox(height: 8),
            Text('正确：$_score  |  剩余：${antiscamQuestions.length - _index} 题',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),

            // 情景卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(q.scenario,
                  style: const TextStyle(fontSize: 15, height: 1.7)),
            ),
            const SizedBox(height: 24),

            // 判断按钮
            if (_answered == null) ...[
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _answer(true),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded),
                    SizedBox(width: 8),
                    Text('这是诈骗！', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _answer(false),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text('这是正常的', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],

            // 答题后：解析区域
            if (_answered != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _answered! ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _answered! ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        _answered! ? Icons.check_circle : Icons.cancel,
                        color: _answered! ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _answered! ? '判断正确！' : '判断有误',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _answered! ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: q.isScam ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          q.isScam ? '属于诈骗' : '属于正常',
                          style: TextStyle(
                            fontSize: 12,
                            color: q.isScam ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(q.analysis,
                        style: const TextStyle(
                            fontSize: 13, height: 1.6, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _next,
                child: Text(_index < antiscamQuestions.length - 1
                    ? '下一题 →' : '查看结果'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _score >= _passScore;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                passed ? Icons.shield : Icons.shield_outlined,
                size: 80,
                color: passed ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                passed ? '反诈达人！' : '还需加强',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '$_score / ${antiscamQuestions.length} 题正确',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? '你已掌握识别币圈常见诈骗的核心方法'
                    : '建议重玩一次，加深对诈骗手法的认识',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.6),
              ),
              if (_loading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ] else if (passed) ...[
                const SizedBox(height: 8),
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
                  onPressed: () => context.replace('/game/antiscam'),
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