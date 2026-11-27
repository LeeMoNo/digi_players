import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/layout/fold_side.dart';
import '../../../core/models/badge.dart';
import '../../../core/progress/progress_store.dart';
import '../../../core/router/app_back_button.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import '../../../core/utils/shuffled_options.dart';
import '../earned_badge_note.dart';
import 'multisig_desk_data.dart';

class MultisigDeskScreen extends StatefulWidget {
  const MultisigDeskScreen({
    super.key,
    this.fetchSeed = true,
    this.initialIndex = 0,
    this.random,
  });

  final bool fetchSeed;
  final int initialIndex;
  final Random? random;

  @override
  State<MultisigDeskScreen> createState() => _MultisigDeskScreenState();
}

class _MultisigDeskScreenState extends State<MultisigDeskScreen> {
  int _index = 0;
  int _score = 0;
  bool? _answered;
  bool _finished = false;
  bool _loading = false;
  bool _saveFailed = false;
  List<BadgeItem> _earned = const [];
  String? _seed;
  late ShuffledOptions _choice;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _shuffle();
    if (widget.fetchSeed) _fetchSeed();
  }

  void _shuffle() {
    _choice = ShuffledOptions.shuffle(
      multisigDeskScenarios[_index].options,
      random: widget.random,
    );
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_multisig_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _choose(int displayIndex) {
    if (_answered != null) return;
    final original = _choice.originalIndex(displayIndex);
    final correct =
        original == multisigDeskScenarios[_index].answerIndex;
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  void _next() {
    if (_index < multisigDeskScenarios.length - 1) {
      setState(() {
        _index++;
        _answered = null;
        _shuffle();
      });
      return;
    }
    _submitScore();
  }

  Future<void> _submitScore() async {
    setState(() {
      _finished = true;
      _loading = true;
      _saveFailed = false;
    });

    final passed = _score >= multisigDeskPassScore;
    var earned = const <BadgeItem>[];
    if (passed) {
      final already = await ProgressStore.hasFlag('game_done_game_multisig');
      try {
        await ProgressStore.markFlag('game_done_game_multisig');
      } on ProgressNotSaved {
        if (!mounted) return;
        setState(() {
          _saveFailed = true;
          _earned = const [];
          _loading = false;
        });
        return;
      }
      if (_seed != null) {
        try {
          final did = await SecureStorage.getDID() ?? '';
          final resultData = '$_score/${multisigDeskScenarios.length}';
          final proof = buildProofHash(
            did: did,
            actionKey: 'game_multisig_complete',
            seed: _seed!,
            resultData: resultData,
          );
          await ApiClient.dio.post(
            '/points/award',
            data: {
              'action_key': 'game_multisig_complete',
              'proof_hash': proof,
              'result_data': resultData,
            },
          );
        } catch (_) {}
      }
      earned = badgesJustEarned(
        practice: 'multisig',
        alreadyDone: already,
        pathComplete: false,
      );
    }
    if (!mounted) return;
    setState(() {
      _saveFailed = false;
      _earned = earned;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult();
    final scenario = multisigDeskScenarios[_index];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text(
          '多签核对台  ${_index + 1}/${multisigDeskScenarios.length}',
        ),
      ),
      body: FoldSide(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '正确：$_score  ·  先找可疑点，再决定签不签',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_index + 1) / multisigDeskScenarios.length,
            ),
            const SizedBox(height: 16),
            Text('你的意图', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(scenario.intent, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            Text('待签摘要（网页所见）', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.site,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final row in scenario.rows) ...[
                      Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(row.value, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_answered == null)
              for (var i = 0; i < _choice.texts.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => _choose(i),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      _choice.texts[i],
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ),
              ]
            else ...[
              Text(
                _answered! ? '判断正确' : '这一题不太对',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _answered! ? Colors.green : scheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(scenario.analysis, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _next,
                child: Text(
                  _index < multisigDeskScenarios.length - 1
                      ? '下一题 →'
                      : '查看结果',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _score >= multisigDeskPassScore;
    return Scaffold(
      body: FoldSide(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.fact_check : Icons.fact_check_outlined,
                  size: 72,
                  color: passed ? Colors.indigo : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? '核对习惯立住了' : '再练一轮',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '$_score / ${multisigDeskScenarios.length} 题正确',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? multisigDeskMechanism
                      : '建议重做：对照意图、域名、地址、金额，并养成看设备屏的习惯。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.6, color: Colors.grey),
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
                if (!_loading) ...[
                  const SizedBox(height: 24),
                  if (passed && _saveFailed)
                    FilledButton(
                      onPressed: _submitScore,
                      child: const Text('再试一次'),
                    )
                  else if (passed) ...[
                    FilledButton(
                      onPressed: () => context.go('/games'),
                      child: const Text('回练习列表'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          context.push('/learn/library/recent_risks'),
                      child: const Text('去看资料「最大所、牌照与上下架」'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          context.push('/learn/fraud?scam=masked_signing'),
                      child: const Text('复习「界面骗签」说明'),
                    ),
                  ] else ...[
                    FilledButton(
                      onPressed: () => context.replace('/games/multisig'),
                      child: const Text('再来一次'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/games'),
                      child: const Text('回练习列表'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
