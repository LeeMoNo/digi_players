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
import 'key_custody_data.dart';

class KeyCustodyScreen extends StatefulWidget {
  const KeyCustodyScreen({
    super.key,
    this.fetchSeed = true,
    this.initialIndex = 0,
    this.random,
  });

  final bool fetchSeed;
  final int initialIndex;
  final Random? random;

  @override
  State<KeyCustodyScreen> createState() => _KeyCustodyScreenState();
}

class _KeyCustodyScreenState extends State<KeyCustodyScreen> {
  int get _total => keyCustodyCards.length + keyCustodyOutcomes.length;

  int _index = 0;
  int _score = 0;
  bool? _answered;
  bool _finished = false;
  bool _loading = false;
  bool _saveFailed = false;
  List<BadgeItem> _earned = const [];
  String? _seed;
  late ShuffledOptions _choice;
  late List<KeyBucket> _bucketOrder;

  bool get _isOutcome => _index >= keyCustodyCards.length;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _shuffle();
    if (widget.fetchSeed) _fetchSeed();
  }

  void _shuffle() {
    if (_isOutcome) {
      final outcome = keyCustodyOutcomes[_index - keyCustodyCards.length];
      _choice = ShuffledOptions.shuffle(
        outcome.options,
        random: widget.random,
      );
      _bucketOrder = const [];
      return;
    }
    _bucketOrder = List<KeyBucket>.from(KeyBucket.values)
      ..shuffle(widget.random ?? Random());
    _choice = ShuffledOptions(
      texts: [for (final b in _bucketOrder) keyBucketLabel(b)],
      order: List<int>.generate(_bucketOrder.length, (i) => i),
    );
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_custody_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _chooseDisplay(int displayIndex) {
    if (_answered != null) return;
    final bool correct;
    if (_isOutcome) {
      final outcome = keyCustodyOutcomes[_index - keyCustodyCards.length];
      correct = _choice.originalIndex(displayIndex) == outcome.answerIndex;
    } else {
      correct = _bucketOrder[displayIndex] == keyCustodyCards[_index].answer;
    }
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  void _next() {
    if (_index < _total - 1) {
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

    final passed = _score >= keyCustodyPassScore;
    var earned = const <BadgeItem>[];
    if (passed) {
      final already = await ProgressStore.hasFlag('game_done_game_custody');
      try {
        await ProgressStore.markFlag('game_done_game_custody');
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
          final resultData = '$_score/$_total';
          final proof = buildProofHash(
            did: did,
            actionKey: 'game_custody_complete',
            seed: _seed!,
            resultData: resultData,
          );
          await ApiClient.dio.post(
            '/points/award',
            data: {
              'action_key': 'game_custody_complete',
              'proof_hash': proof,
              'result_data': resultData,
            },
          );
        } catch (_) {}
      }
      earned = badgesJustEarned(
        practice: 'custody',
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

  String get _analysis {
    if (_isOutcome) {
      return keyCustodyOutcomes[_index - keyCustodyCards.length].analysis;
    }
    return keyCustodyCards[_index].analysis;
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text('钥匙在谁手里  ${_index + 1}/$_total'),
      ),
      body: FoldSide(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '正确：$_score  ·  把情景归到钥匙真正所在的一侧',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (_index + 1) / _total),
            const SizedBox(height: 16),
            _BucketLegend(scheme: scheme),
            const SizedBox(height: 20),
            Text(
              _isOutcome ? '结局卡' : '这枚「币」的控制权更接近哪一栏？',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _isOutcome
                      ? keyCustodyOutcomes[_index - keyCustodyCards.length]
                            .headline
                      : keyCustodyCards[_index].scene,
                  style: const TextStyle(height: 1.55),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_answered == null)
              for (var i = 0; i < _choice.texts.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: Key('custody-option-$i'),
                    onPressed: () => _chooseDisplay(i),
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
              Text(_analysis, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _next,
                child: Text(_index < _total - 1 ? '下一题 →' : '查看结果'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _score >= keyCustodyPassScore;
    return Scaffold(
      body: FoldSide(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.key : Icons.key_off,
                  size: 72,
                  color: passed ? Colors.brown : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? '钥匙归属分清了' : '再练一轮',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '$_score / $_total 题正确',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? keyCustodyMechanism
                      : '建议重做：分清柜台余额、自管地址、以及对方要你转去的地址。',
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
                      onPressed: () => context.push('/learn/library/custody'),
                      child: const Text('去看资料「把钥匙交给别人」'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          context.push('/learn/library/custody_returns'),
                      child: const Text('也看看「托管又回来了」'),
                    ),
                  ] else ...[
                    FilledButton(
                      onPressed: () => context.replace('/games/custody'),
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

class _BucketLegend extends StatelessWidget {
  const _BucketLegend({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final bucket in KeyBucket.values)
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(
              keyBucketLabel(bucket),
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: scheme.surfaceContainerHighest,
          ),
      ],
    );
  }
}
