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
import 'listing_desk_data.dart';

/// G9：牌照宣传与上下架公告的判断练习（旁路，不计入主路径六步）。
class ListingDeskScreen extends StatefulWidget {
  const ListingDeskScreen({
    super.key,
    this.fetchSeed = true,
    this.initialIndex = 0,
    this.random,
  });

  final bool fetchSeed;
  final int initialIndex;

  /// 测试可固定选项打乱顺序。
  final Random? random;

  @override
  State<ListingDeskScreen> createState() => _ListingDeskScreenState();
}

class _ListingDeskScreenState extends State<ListingDeskScreen> {
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
      listingDeskScenarios[_index].options,
      random: widget.random,
    );
  }

  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        // 与 Workers proof.js / action_types 白名单一致。
        data: {'action_key': 'game_listing_complete'},
      );
      _seed = res.data['seed'] as String;
    } catch (_) {}
  }

  void _choose(int displayIndex) {
    if (_answered != null) return;
    final original = _choice.originalIndex(displayIndex);
    final correct =
        original == listingDeskScenarios[_index].answerIndex;
    if (correct) _score++;
    setState(() => _answered = correct);
  }

  void _next() {
    if (_index < listingDeskScenarios.length - 1) {
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

    final passed = _score >= listingDeskPassScore;
    var earned = const <BadgeItem>[];
    if (passed) {
      // 旁路旗：写入服务端白名单后才能跨设备同步。
      final already = await ProgressStore.hasFlag('game_done_game_listing');
      try {
        await ProgressStore.markFlag('game_done_game_listing');
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
          final resultData = '$_score/${listingDeskScenarios.length}';
          final proof = buildProofHash(
            did: did,
            actionKey: 'game_listing_complete',
            seed: _seed!,
            resultData: resultData,
          );
          await ApiClient.dio.post(
            '/points/award',
            data: {
              'action_key': 'game_listing_complete',
              'proof_hash': proof,
              'result_data': resultData,
            },
          );
        } catch (_) {
          // 积分失败不挡通关；进度以 flag 为准。
        }
      }
      // pathComplete 固定 false：本关不参与「路径完成」六步。
      earned = badgesJustEarned(
        practice: 'listing',
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
    final scenario = listingDeskScenarios[_index];
    final scheme = Theme.of(context).colorScheme;
    final kindLabel = scenario.kind == ListingDeskKind.promo
        ? '宣传语核对'
        : '下架公告判断';

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text(
          '牌照与上下架  ${_index + 1}/${listingDeskScenarios.length}',
        ),
      ),
      body: FoldSide(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '正确：$_score  ·  读宣传与公告时先抓保护边界和流动性',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_index + 1) / listingDeskScenarios.length,
            ),
            const SizedBox(height: 16),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(kindLabel, style: const TextStyle(fontSize: 12)),
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(scenario.prompt, style: const TextStyle(height: 1.55)),
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
                  _index < listingDeskScenarios.length - 1
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
    final passed = _score >= listingDeskPassScore;
    return Scaffold(
      body: FoldSide(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.gavel : Icons.gavel_outlined,
                  size: 72,
                  color: passed ? Colors.blueGrey : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? '牌照与上下架读清楚了' : '再练一轮',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '$_score / ${listingDeskScenarios.length} 题正确',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? listingDeskMechanism
                      : '建议重做：分清牌照法域、价格代币 ≠ 股权，以及下架先砸流动性。',
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
                  ] else ...[
                    FilledButton(
                      onPressed: () => context.replace('/games/listing'),
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
