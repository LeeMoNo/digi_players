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
import 'stablecoin_scale_data.dart';
import 'stablecoin_scale_logic.dart';

class StablecoinScaleScreen extends StatefulWidget {
  const StablecoinScaleScreen({
    super.key,
    this.fetchSeed = true,
    this.startInQuiz = false,
    this.initialQuizIndex = 0,
    this.random,
  });

  final bool fetchSeed;

  /// 测试可跳过天平实验，直接进入问答。
  final bool startInQuiz;

  final int initialQuizIndex;
  final Random? random;

  @override
  State<StablecoinScaleScreen> createState() => _StablecoinScaleScreenState();
}

class _StablecoinScaleScreenState extends State<StablecoinScaleScreen> {
  /// false = 天平实验；true = 诊断/新闻。
  late bool _inQuiz;
  int _quizIndex = 0;
  int _score = 0;
  bool? _answered;
  bool _finished = false;
  bool _loading = false;
  bool _saveFailed = false;
  bool _labHint = false;
  List<BadgeItem> _earned = const [];
  String? _seed;
  ShuffledOptions? _choice;

  // 故意从偏风险的盘面开始，让玩家往安全储备拨。
  double _cash = 20;
  double _treasury = 20;
  double _pressure = 75;

  static const _quizCount = 5; // 3 盘面 + 2 新闻卡

  double get _risk => 100 - _cash - _treasury;

  PegSnapshot get _labSnapshot => PegSnapshot(
    cash: _cash,
    treasury: _treasury,
    risk: _risk,
    pressure: _pressure,
  );

  @override
  void initState() {
    super.initState();
    _inQuiz = widget.startInQuiz;
    _quizIndex = widget.initialQuizIndex;
    if (_inQuiz) _shuffle();
    if (widget.fetchSeed) _fetchSeed();
  }

  void _shuffle() {
    final options = _quizIndex < stablecoinBoards.length
        ? stablecoinBoards[_quizIndex].options
        : stablecoinNewsCards[_quizIndex - stablecoinBoards.length].options;
    _choice = ShuffledOptions.shuffle(options, random: widget.random);
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_stablecoin_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _rebalanceCash(double value) {
    final cash = value.clamp(0, 100 - _treasury);
    setState(() {
      _cash = cash.toDouble();
      _labHint = false;
    });
  }

  void _rebalanceTreasury(double value) {
    final treasury = value.clamp(0, 100 - _cash);
    setState(() {
      _treasury = treasury.toDouble();
      _labHint = false;
    });
  }

  void _tryLeaveLab() {
    if (!isHealthyPeg(_labSnapshot)) {
      setState(() => _labHint = true);
      return;
    }
    setState(() {
      _inQuiz = true;
      _quizIndex = 0;
      _answered = null;
      _labHint = false;
      _shuffle();
    });
  }

  void _choose(int displayIndex) {
    if (_answered != null || _choice == null) return;
    final original = _choice!.originalIndex(displayIndex);
    final correctIndex = _quizIndex < stablecoinBoards.length
        ? stablecoinBoards[_quizIndex].answerIndex
        : stablecoinNewsCards[_quizIndex - stablecoinBoards.length]
              .answerIndex;
    final correct = original == correctIndex;
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  void _next() {
    if (_quizIndex < _quizCount - 1) {
      setState(() {
        _quizIndex++;
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

    final passed = _score >= stablecoinScalePassScore;
    var earned = const <BadgeItem>[];
    if (passed) {
      final already = await ProgressStore.hasFlag(
        'game_done_game_stablecoin',
      );
      try {
        await ProgressStore.markFlag('game_done_game_stablecoin');
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
          final resultData = '$_score/$_quizCount';
          final proof = buildProofHash(
            did: did,
            actionKey: 'game_stablecoin_complete',
            seed: _seed!,
            resultData: resultData,
          );
          await ApiClient.dio.post(
            '/points/award',
            data: {
              'action_key': 'game_stablecoin_complete',
              'proof_hash': proof,
              'result_data': resultData,
            },
          );
        } catch (_) {}
      }
      earned = badgesJustEarned(
        practice: 'stablecoin',
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
    if (!_inQuiz) return _buildLab();
    return _buildQuiz();
  }

  Widget _buildLab() {
    final snap = _labSnapshot;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: const Text('稳定币天平  实验'),
      ),
      body: FoldSide(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '先把天平拨到「仍接近锚定」。现金与国债是安全垫，风险资产和赎回压力会把它压歪。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _PegPanel(snapshot: snap),
            const SizedBox(height: 20),
            Text('现金 ${(snap.cash).round()}%', style: _sliderLabel(context)),
            Slider(
              value: _cash,
              max: 100,
              divisions: 20,
              label: '${_cash.round()}%',
              onChanged: _rebalanceCash,
            ),
            Text(
              '国债 ${(snap.treasury).round()}%',
              style: _sliderLabel(context),
            ),
            Slider(
              value: _treasury,
              max: 100,
              divisions: 20,
              label: '${_treasury.round()}%',
              onChanged: _rebalanceTreasury,
            ),
            Text(
              '风险资产自动为 ${_risk.round()}%（三者合计 100%）',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              '赎回压力 ${_pressure.round()}',
              style: _sliderLabel(context),
            ),
            Slider(
              value: _pressure,
              max: 100,
              divisions: 20,
              label: '${_pressure.round()}',
              onChanged: (v) => setState(() {
                _pressure = v;
                _labHint = false;
              }),
            ),
            if (_labHint) ...[
              const SizedBox(height: 8),
              Text(
                '还没稳住：提高现金/国债，或降低赎回压力，让示意价格回到约 0.97 以上，且安全垫盖得住挤兑。',
                style: TextStyle(color: scheme.error, height: 1.5),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _tryLeaveLab,
              child: const Text('我认为能守住锚定 →'),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _sliderLabel(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall;

  Widget _buildQuiz() {
    final isBoard = _quizIndex < stablecoinBoards.length;
    final board = isBoard ? stablecoinBoards[_quizIndex] : null;
    final news = isBoard
        ? null
        : stablecoinNewsCards[_quizIndex - stablecoinBoards.length];
    final analysis = isBoard ? board!.analysis : news!.analysis;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text('稳定币天平  ${_quizIndex + 1}/$_quizCount'),
      ),
      body: FoldSide(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '正确：$_score  ·  分清锚定、储备与兑付',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (_quizIndex + 1) / _quizCount),
            const SizedBox(height: 20),
            if (isBoard) ...[
              Text(board!.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '看这盘储备与压力，你的判断是？',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _PegPanel(snapshot: board.snapshot),
            ] else ...[
              Text('新闻卡', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(news!.headline, style: const TextStyle(height: 1.55)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_answered == null && _choice != null)
              for (var i = 0; i < _choice!.texts.length; i++) ...[
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
                      _choice!.texts[i],
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ),
              ]
            else if (_answered != null) ...[
              Text(
                _answered! ? '判断正确' : '这一题不太对',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _answered! ? Colors.green : scheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(analysis, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _next,
                child: Text(
                  _quizIndex < _quizCount - 1 ? '下一题 →' : '查看结果',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _score >= stablecoinScalePassScore;
    return Scaffold(
      body: FoldSide(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.balance : Icons.balance_outlined,
                  size: 72,
                  color: passed ? Colors.blueGrey : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? '天平读数清楚了' : '再练一轮',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '$_score / $_quizCount 题正确',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? stablecoinScaleMechanism
                      : '建议重做：先稳住实验天平，再分清脱锚与兑付压力。',
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
                          context.push('/learn/library/stablecoin'),
                      child: const Text('去看资料「稳定币为什么看起来像美元」'),
                    ),
                  ] else ...[
                    FilledButton(
                      onPressed: () => context.replace('/games/stablecoin'),
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

class _PegPanel extends StatelessWidget {
  const _PegPanel({required this.snapshot});

  final PegSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reading = snapshot.reading;
    final color = switch (reading) {
      PegReading.anchored => Colors.green,
      PegReading.depegged => scheme.error,
      PegReading.redeemStress => Colors.orange,
    };

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '示意价格 ≈ \$${snapshot.impliedPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              pegReadingLabel(reading),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _Bar(
              label: '现金 ${snapshot.cash.round()}%',
              value: snapshot.cash / 100,
              color: Colors.teal,
            ),
            _Bar(
              label: '国债 ${snapshot.treasury.round()}%',
              value: snapshot.treasury / 100,
              color: Colors.blue,
            ),
            _Bar(
              label: '风险资产 ${snapshot.risk.round()}%',
              value: snapshot.risk / 100,
              color: Colors.deepOrange,
            ),
            _Bar(
              label: '赎回压力 ${snapshot.pressure.round()}',
              value: snapshot.pressure / 100,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            Text(
              '安全垫（现金+国债） ${snapshot.safe.round()}%',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
