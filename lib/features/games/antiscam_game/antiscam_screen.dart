// lib/features/games/antiscam_game/antiscam_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/fold_side.dart';
import '../../../core/models/badge.dart';
import '../../../core/progress/progress_store.dart';
import '../../learn/learn_path.dart';
import '../earned_badge_note.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import '../../../core/utils/shuffled_options.dart';
import 'antiscam_data.dart';

class AntiscamScreen extends StatefulWidget {
  const AntiscamScreen({
    super.key,
    this.fetchSeed = true,
    this.initialIndex = 0,
    this.random,
  });

  /// 测试可关掉，避免请求开局接口。
  final bool fetchSeed;

  /// 测试可从某一题开始。
  final int initialIndex;

  /// 测试可固定打乱结果。
  final Random? random;

  @override
  State<AntiscamScreen> createState() => _State();
}

class _State extends State<AntiscamScreen> {
  int _index = 0;
  int _score = 0;
  bool? _answered; // null=未答，true=正确，false=错误
  bool _finished = false;
  bool _loading = false;
  bool _saveFailed = false;
  LearnPathStep? _clearStep;
  List<BadgeItem> _earned = const [];
  String? _seed;
  ShuffledOptions? _choice;
  List<int> _judgeOrder = const [0, 1];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _shuffleQuestion();
    if (widget.fetchSeed) _fetchSeed();
  }

  void _shuffleQuestion() {
    final question = antiscamAllQuestions[_index];
    if (question.isChoice) {
      _choice = ShuffledOptions.shuffle(
        question.options,
        random: widget.random,
      );
      return;
    }
    _choice = null;
    _judgeOrder = ShuffledOptions.shuffle(const [
      '这是诈骗！',
      '这是正常的',
    ], random: widget.random).order;
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_antiscam_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _answer(bool playerSaysScam) {
    if (_answered != null) return;
    final correct = playerSaysScam == antiscamAllQuestions[_index].isScam;
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  void _choose(int index) {
    if (_answered != null) return;
    final correct = index == antiscamAllQuestions[_index].answerIndex;
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  Widget _judgeButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required bool saysScam,
  }) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _answer(saysScam),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _next() {
    if (_index < antiscamAllQuestions.length - 1) {
      setState(() {
        _index++;
        _answered = null;
        _shuffleQuestion();
      });
    } else {
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    setState(() {
      _finished = true;
      _loading = true;
      _saveFailed = false;
    });

    final passed = _score >= antiscamPassScore;
    LearnPathStep? next;
    var earned = const <BadgeItem>[];
    if (passed) {
      final already = await ProgressStore.hasFlag('game_done_game_antiscam');
      try {
        await ProgressStore.markFlag('game_done_game_antiscam');
      } on ProgressNotSaved {
        if (!mounted) return;
        setState(() {
          _saveFailed = true;
          _clearStep = null;
          _earned = const [];
          _loading = false;
        });
        return;
      }
      if (_seed != null) {
        try {
          final did = await SecureStorage.getDID() ?? '';
          final resultData = '$_score/${antiscamAllQuestions.length}';
          final proof = buildProofHash(
            did: did,
            actionKey: 'game_antiscam_complete',
            seed: _seed!,
            resultData: resultData,
          );
          await ApiClient.dio.post(
            '/points/award',
            data: {
              'action_key': 'game_antiscam_complete',
              'proof_hash': proof,
              'result_data': resultData,
            },
          );
        } catch (_) {}
      }
      final progress = await readLearnPathProgress();
      next = practiceClearDestination(practice: 'antiscam', progress: progress);
      earned = badgesJustEarned(
        practice: 'antiscam',
        alreadyDone: already,
        pathComplete: progress.isComplete,
      );
    }
    if (!mounted) return;
    setState(() {
      _saveFailed = false;
      _clearStep = next;
      _earned = earned;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult();

    final q = antiscamAllQuestions[_index];
    final pageTitle = scamPageTitle(q);

    return Scaffold(
      appBar: AppBar(
        title: Text('反诈训练营  ${_index + 1}/${antiscamAllQuestions.length}'),
      ),
      body: FoldSide(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / antiscamAllQuestions.length,
            ),
            const SizedBox(height: 8),
            Text(
              '正确：$_score  |  剩余：${antiscamAllQuestions.length - _index} 题',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                q.scenario,
                style: const TextStyle(fontSize: 15, height: 1.7),
              ),
            ),
            const SizedBox(height: 24),

            if (_answered == null && q.isChoice) ...[
              Text('你当时会点哪一个', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (
                var display = 0;
                display < _choice!.texts.length;
                display++
              ) ...[
                OutlinedButton(
                  onPressed: () => _choose(_choice!.originalIndex(display)),
                  child: Text(_choice!.texts[display]),
                ),
                const SizedBox(height: 8),
              ],
            ] else if (_answered == null) ...[
              for (final original in _judgeOrder) ...[
                if (original == 0)
                  _judgeButton(
                    label: '这是诈骗！',
                    icon: Icons.warning_amber_rounded,
                    background: Colors.red.shade50,
                    foreground: Colors.red.shade700,
                    saysScam: true,
                  )
                else
                  _judgeButton(
                    label: '这是正常的',
                    icon: Icons.check_circle_outline,
                    background: Colors.green.shade50,
                    foreground: Colors.green.shade700,
                    saysScam: false,
                  ),
                const SizedBox(height: 12),
              ],
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
                    Row(
                      children: [
                        Icon(
                          _answered! ? Icons.check_circle : Icons.cancel,
                          color: _answered! ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _answered!
                              ? (q.isChoice ? '选择正确' : '判断正确')
                              : (q.isChoice ? '选择有误' : '判断有误'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _answered!
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: q.isScam
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            q.isScam ? '属于诈骗' : '属于正常',
                            style: TextStyle(
                              fontSize: 12,
                              color: q.isScam
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q.analysis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    if (pageTitle != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            context.push('/learn/fraud?scam=${q.scamId}'),
                        child: Text('查看「$pageTitle」'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _next,
                child: Text(
                  _index < antiscamAllQuestions.length - 1 ? '下一题 →' : '查看结果',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _score >= antiscamPassScore;
    return Scaffold(
      body: FoldSide(
        child: Center(
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
                  '$_score / ${antiscamAllQuestions.length} 题正确',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  passed ? '你已掌握识别币圈常见诈骗的核心方法' : '建议重玩一次，加深对诈骗手法的认识',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.6),
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ] else if (passed && _saveFailed) ...[
                  const SizedBox(height: 8),
                  const Text(
                    progressNotSavedMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ] else if (passed) ...[
                  const SizedBox(height: 8),
                  const Text('进度已记下', style: TextStyle(color: Colors.green)),
                  EarnedBadgeNote(badges: _earned),
                ],
                const SizedBox(height: 32),
                if (passed && _saveFailed)
                  FilledButton(
                    onPressed: _loading ? null : _submitScore,
                    child: const Text('再试一次'),
                  )
                else if (passed && _clearStep != null)
                  FilledButton(
                    onPressed: () => context.go(_clearStep!.route),
                    child: Text(_clearStep!.button),
                  )
                else if (!passed)
                  FilledButton(
                    onPressed: () => context.go('/learn'),
                    child: const Text('返回学习'),
                  ),
                if (!passed) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.replace('/games/antiscam'),
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
