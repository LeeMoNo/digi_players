// lib/features/games/hash_game/hash_game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'hash_game_logic.dart';
import 'hash_game_progress.dart';

class HashGameScreen extends StatefulWidget {
  const HashGameScreen({super.key});
  @override
  State<HashGameScreen> createState() => _State();
}

class _State extends State<HashGameScreen> {
  int _level = 0; // 当前关卡 0/1/2
  int _nonce = 0;
  String _hash = '';
  bool _levelDone = false;
  bool _gameDone = false;
  final TextEditingController _nonceCtrl = TextEditingController(text: '0');
  bool _syncingField = false;
  LearnPathStep? _next;
  List<BadgeItem> _earned = const [];
  bool _loading = false;
  bool _saveFailed = false;
  String? _seed; // 服务端签发的 seed

  // 记录每关成功时的 nonce，用于 result_data
  final List<int> _solvedNonces = [];

  @override
  void initState() {
    super.initState();
    _recompute(notify: false);
    _restoreProgress();
    _fetchSeed();
  }

  @override
  void dispose() {
    _nonceCtrl.dispose();
    super.dispose();
  }

  /// 有中途进度就跳到下一关；没有或读失败则留在当前关。
  Future<void> _restoreProgress() async {
    final checkpoint = await HashGameProgress.load();
    if (!mounted || checkpoint.level <= 0) return;
    setState(() {
      _level = checkpoint.level;
      _solvedNonces
        ..clear()
        ..addAll(checkpoint.solvedNonces);
      _nonce = 0;
      _levelDone = false;
    });
    _writeNonceField('0');
    _recompute();
  }

  // 游戏开始时从服务端拿 seed
  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': 'game_hash_complete'},
      );
      if (!mounted) return;
      setState(() => _seed = res.data['seed'] as String);
    } catch (_) {
      // seed 获取失败不阻断游戏，只影响积分上报
    }
  }

  void _recompute({bool notify = true}) {
    final txData = HashGameLogic.levels[_level];
    final hash = HashGameLogic.compute(txData, _nonce);
    final done = HashGameLogic.meetsDifficulty(
      hash,
      HashGameLogic.difficulties[_level],
    );
    final justCleared = done && !_levelDone;
    if (!notify) {
      _hash = hash;
      _levelDone = done;
    } else {
      setState(() {
        _hash = hash;
        _levelDone = done;
      });
    }
    // 本关刚通过：记下下一关，下次进来直接从那里开始。
    // 启动时的首次计算不写进度，避免误把恢复中的关卡再往前推。
    if (justCleared && notify) {
      final nextLevel = _level + 1;
      if (nextLevel < HashGameLogic.levels.length) {
        HashGameProgress.save(
          HashGameCheckpoint(
            level: nextLevel,
            solvedNonces: [..._solvedNonces, _nonce],
          ),
        );
      }
    }
  }

  void _writeNonceField(String text) {
    if (_nonceCtrl.text == text) return;
    _syncingField = true;
    try {
      _nonceCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } finally {
      _syncingField = false;
    }
  }

  void _applyNonce(int value, {required bool fromField}) {
    final next = value.clamp(0, HashGameLogic.maxNonce);
    final changed = next != _nonce;
    _nonce = next;
    if (!fromField) _writeNonceField('$next');
    if (changed) _recompute();
  }

  void _onSlider(double value) {
    _applyNonce(value.toInt(), fromField: false);
  }

  void _onNonceText(String raw) {
    if (_syncingField) return;
    final parsed = HashGameLogic.parseNonce(raw);
    if (parsed == null) return;
    if (raw.isNotEmpty) _writeNonceField('$parsed');
    _applyNonce(parsed, fromField: true);
  }

  void _nextLevel() {
    _solvedNonces.add(_nonce);

    if (_level < HashGameLogic.levels.length - 1) {
      _level++;
      _nonce = 0;
      _writeNonceField('0');
      // 进度已在通关时写入；这里再写一次，保证与当前关卡一致。
      HashGameProgress.save(
        HashGameCheckpoint(level: _level, solvedNonces: List.of(_solvedNonces)),
      );
      _recompute();
    } else {
      // 三关全过，上报积分
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    setState(() {
      _loading = true;
      _gameDone = true;
      _saveFailed = false;
    });

    final already = await ProgressStore.hasFlag('game_done_game_hash');
    try {
      await ProgressStore.markFlag('game_done_game_hash');
      await HashGameProgress.clear();
    } on ProgressNotSaved {
      if (!mounted) return;
      setState(() {
        _saveFailed = true;
        _next = null;
        _earned = const [];
        _loading = false;
      });
      return;
    }

    if (_seed != null) {
      try {
        final did = await SecureStorage.getDID() ?? '';
        final resultData = _solvedNonces.join(',');
        final proof = buildProofHash(
          did: did,
          actionKey: 'game_hash_complete',
          seed: _seed!,
          resultData: resultData,
        );

        await ApiClient.dio.post(
          '/points/award',
          data: {
            'action_key': 'game_hash_complete',
            'proof_hash': proof,
            'result_data': resultData,
          },
        );
      } catch (_) {
        // 积分上报失败不影响进度
      }
    }

    final progress = await readLearnPathProgress();
    if (!mounted) return;
    setState(() {
      _saveFailed = false;
      _next = practiceClearDestination(practice: 'hash', progress: progress);
      _earned = badgesJustEarned(
        practice: 'hash',
        alreadyDone: already,
        pathComplete: progress.isComplete,
      );
      _loading = false;
    });
  }

  /// 给长串插入可断点，避免窄屏把哈希或交易数据撑出屏幕。
  String _breakable(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if (i % 16 == 15 && i != value.length - 1) buffer.write('\u200B');
    }
    return buffer.toString();
  }

  // ── 哈希着色：把开头的零变绿色 ────────────────────
  Widget _coloredHash(String hash, int difficulty) {
    final safe = difficulty.clamp(0, hash.length);
    final zerosOk = _breakable(hash.substring(0, safe));
    final remainder = _breakable(hash.substring(safe));
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.45,
          color: Colors.white70,
        ),
        children: [
          TextSpan(
            text: zerosOk,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: remainder),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gameDone) return _buildResult();

    final difficulty = HashGameLogic.difficulties[_level];
    final txData = HashGameLogic.levels[_level];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text('哈希碰碰乐  关卡 ${_level + 1}/3'),
      ),
      backgroundColor: const Color(0xFF0F1117),
      body: FoldSide(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 目标说明
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '目标：哈希开头出现 $difficulty 个零',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '交易数据：${_breakable(txData)}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.35,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nonce 滑块
                        Text(
                          'Nonce：$_nonce',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Slider(
                          value: _nonce.toDouble(),
                          min: 0,
                          max: HashGameLogic.maxNonce.toDouble(),
                          divisions: HashGameLogic.maxNonce,
                          onChanged: _onSlider,
                        ),

                        // 手动输入 nonce（只接受 0～999999 的整数）
                        TextField(
                          controller: _nonceCtrl,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          enableSuggestions: false,
                          autocorrect: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          maxLength: HashGameLogic.maxNonceLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: '或直接输入 Nonce',
                            hintText: '0～999999',
                            counterText: '',
                            isDense: true,
                            labelStyle: const TextStyle(color: Colors.white54),
                            hintStyle: const TextStyle(color: Colors.white24),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: _onNonceText,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 16),

                        // 哈希结果显示
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _levelDone
                                ? Colors.green.shade900
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _levelDone ? Colors.green : Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SHA-256 结果：',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _coloredHash(_hash, difficulty),
                              if (_levelDone) ...[
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '满足条件！',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 提示文字
                        Text(
                          HashGameLogic.hint(_level),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_levelDone) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _nextLevel,
                    child: Text(_level < 2 ? '下一关 →' : '完成游戏'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: FoldSide(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 64).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.military_tech,
                        color: Colors.amber,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '三关全通！',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '你刚刚体验了真实的挖矿过程。\n'
                        '比特币矿工每秒要做数万亿次这样的计算。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.6),
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ] else if (_saveFailed) ...[
                        const SizedBox(height: 12),
                        const Text(
                          progressNotSavedMessage,
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        const Text(
                          '进度已记下',
                          style: TextStyle(color: Colors.green),
                        ),
                        EarnedBadgeNote(badges: _earned, onDark: true),
                      ],
                      const SizedBox(height: 32),
                      if (_saveFailed)
                        FilledButton(
                          onPressed: _loading ? null : _submitScore,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
