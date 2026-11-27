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
  /// 结算页：第一关解锁主路径，或打完可选挑战。
  _ResultKind? _resultKind;
  final TextEditingController _nonceCtrl = TextEditingController(text: '0');
  bool _syncingField = false;
  LearnPathStep? _next;
  List<BadgeItem> _earned = const [];
  bool _loading = false;
  bool _saveFailed = false;
  bool _pathAlreadyCleared = false;
  int? _lastAwardedPoints;

  // 记录每关成功时的 nonce，用于 result_data
  final List<int> _solvedNonces = [];

  @override
  void initState() {
    super.initState();
    _recompute(notify: false);
    _restoreProgress();
  }

  @override
  void dispose() {
    _nonceCtrl.dispose();
    super.dispose();
  }

  /// 有中途进度就跳到对应关；没有或读失败则留在当前关。
  Future<void> _restoreProgress() async {
    final already = await ProgressStore.hasFlag('game_done_game_hash');
    final checkpoint = await HashGameProgress.load();
    if (!mounted) return;
    setState(() {
      _pathAlreadyCleared = already;
      if (checkpoint.level > 0) {
        _level = checkpoint.level;
        _solvedNonces
          ..clear()
          ..addAll(checkpoint.solvedNonces);
        _nonce = 0;
        _levelDone = false;
      }
    });
    if (checkpoint.level > 0) {
      _writeNonceField('0');
      _recompute();
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

  void _recordCurrentNonce() {
    if (_solvedNonces.length == _level) {
      _solvedNonces.add(_nonce);
    } else if (_solvedNonces.length > _level) {
      _solvedNonces[_level] = _nonce;
    }
  }

  /// 第一关：记下主路径进度，并进入结算（可再去挑战）。
  Future<void> _clearPathGate() async {
    _recordCurrentNonce();
    await _persistPathClear(showResult: true);
  }

  /// 第一关后直接进入升级挑战（同样尽量先放行主路径）。
  Future<void> _goChallengeAfterGate() async {
    _recordCurrentNonce();
    if (!_pathAlreadyCleared) {
      // 记进度失败也不挡挑战；主路径要靠「解锁下一步」再试
      await _persistPathClear(showResult: false);
    }
    if (!mounted) return;
    setState(() {
      _level = 1;
      _nonce = 0;
      _levelDone = false;
      _resultKind = null;
    });
    _writeNonceField('0');
    HashGameProgress.save(
      HashGameCheckpoint(level: 1, solvedNonces: List.of(_solvedNonces)),
    );
    _recompute();
  }

  Future<void> _nextChallenge() async {
    _recordCurrentNonce();
    final cleared = _level;
    setState(() => _loading = true);

    final alreadyMaster = await ProgressStore.hasFlag(
      HashGameLogic.progressFlagForLevel(2),
    );
    try {
      await _awardLevel(cleared);
    } on ProgressNotSaved {
      if (!mounted) return;
      if (cleared >= HashGameLogic.levels.length - 1) {
        setState(() {
          _loading = false;
          _saveFailed = true;
          _resultKind = _ResultKind.challengeComplete;
          _earned = const [];
          _next = null;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(progressNotSavedMessage)),
        );
      }
      return;
    }

    if (!mounted) return;

    if (cleared < HashGameLogic.levels.length - 1) {
      setState(() {
        _level = cleared + 1;
        _nonce = 0;
        _levelDone = false;
        _loading = false;
        _saveFailed = false;
      });
      _writeNonceField('0');
      HashGameProgress.save(
        HashGameCheckpoint(level: _level, solvedNonces: List.of(_solvedNonces)),
      );
      _recompute();
      return;
    }

    await HashGameProgress.clear();
    if (!mounted) return;
    setState(() {
      _resultKind = _ResultKind.challengeComplete;
      _next = null;
      _earned = badgesJustEarned(
        practice: 'hash',
        alreadyDone: alreadyMaster,
        pathComplete: false,
      );
      _loading = false;
      _saveFailed = false;
      _lastAwardedPoints = HashGameLogic.pointsForLevel(cleared);
    });
  }

  /// 记下本关进度并发对应积分。已记过则跳过。
  Future<void> _awardLevel(int levelIndex) async {
    final flag = HashGameLogic.progressFlagForLevel(levelIndex);
    final already = await ProgressStore.hasFlag(flag);
    if (!already) {
      await ProgressStore.markFlag(flag);
    }

    if (levelIndex == 0) {
      await HashGameProgress.save(
        HashGameCheckpoint(level: 1, solvedNonces: List.of(_solvedNonces)),
      );
    }

    if (already) {
      _lastAwardedPoints = null;
      return;
    }

    final points = HashGameLogic.pointsForLevel(levelIndex);
    _lastAwardedPoints = points;
    final actionKey = HashGameLogic.pointsActionKey(levelIndex);
    try {
      final start = await ApiClient.dio.post(
        '/game/start',
        data: {'action_key': actionKey},
      );
      final seed = start.data['seed'] as String?;
      if (seed == null || seed.isEmpty) return;

      final did = await SecureStorage.getDID() ?? '';
      final resultData = _solvedNonces.length > levelIndex
          ? '${_solvedNonces[levelIndex]}'
          : '$_nonce';
      final proof = buildProofHash(
        did: did,
        actionKey: actionKey,
        seed: seed,
        resultData: resultData,
      );
      await ApiClient.dio.post(
        '/points/award',
        data: {
          'action_key': actionKey,
          'proof_hash': proof,
          'result_data': resultData,
        },
      );
    } catch (_) {
      // 积分上报失败不影响进度
    }
  }

  Future<bool> _persistPathClear({required bool showResult}) async {
    if (showResult) {
      setState(() {
        _loading = true;
        _resultKind = _ResultKind.pathGate;
        _saveFailed = false;
        _lastAwardedPoints = null;
      });
    }

    final already = await ProgressStore.hasFlag(
      HashGameLogic.progressFlagForLevel(0),
    );
    try {
      await _awardLevel(0);
    } on ProgressNotSaved {
      if (!mounted) return false;
      if (showResult) {
        setState(() {
          _saveFailed = true;
          _next = null;
          _earned = const [];
          _loading = false;
        });
      }
      return false;
    }

    final progress = await readLearnPathProgress();
    if (!mounted) return false;
    setState(() {
      _pathAlreadyCleared = true;
      if (showResult) {
        _saveFailed = false;
        _next = practiceClearDestination(practice: 'hash', progress: progress);
        // 第一关不发挖矿徽章；若因此走完六步，仍可亮「路径完成」
        _earned = badgesJustEarned(
          practice: '',
          alreadyDone: already,
          pathComplete: progress.isComplete,
        );
        _loading = false;
      }
    });
    return true;
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
    if (_resultKind != null) return _buildResult();

    final difficulty = HashGameLogic.difficulties[_level];
    final txData = HashGameLogic.levels[_level];
    final challenge = HashGameLogic.isChallengeLevel(_level);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text(
          challenge
              ? '升级挑战  ${_level + 1}/3'
              : '哈希碰碰乐  通关关 1/3',
        ),
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
                                challenge
                                    ? '升级挑战：哈希开头出现 $difficulty 个零'
                                    : '通关目标：哈希开头出现 $difficulty 个零',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge
                                    ? '不影响主路径，想刷再来。'
                                    : '过这一关即可继续主路径；后两关是可选升级挑战。',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.35,
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
                  if (_level == HashGameLogic.pathClearLevel) ...[
                    FilledButton(
                      onPressed: _loading ? null : _clearPathGate,
                      child: const Text('解锁下一步'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loading ? null : _goChallengeAfterGate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('继续挑战升级关 →'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: _loading ? null : _nextChallenge,
                      child: Text(
                        _loading
                            ? '正在记下…'
                            : _level < HashGameLogic.levels.length - 1
                            ? '下一挑战 →'
                            : '完成挑战',
                      ),
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
    final isPath = _resultKind == _ResultKind.pathGate;
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
                      Icon(
                        isPath ? Icons.check_circle : Icons.military_tech,
                        color: isPath ? Colors.greenAccent : Colors.amber,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isPath ? '第一关过了' : '升级挑战全通！',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPath
                            ? '主路径可以继续了。\n后两关是升级挑战，想刷随时回来。'
                            : '你刚刚体验了更高难度的挖矿计算。\n比特币矿工每秒要做数万亿次这样的运算。',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.6,
                        ),
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
                        Text(
                          isPath
                              ? (_lastAwardedPoints == null
                                    ? '进度已记下'
                                    : '进度已记下 · +$_lastAwardedPoints 积分')
                              : (_lastAwardedPoints == null
                                    ? '挑战进度已记下'
                                    : '挑战完成 · +$_lastAwardedPoints 积分'),
                          style: const TextStyle(color: Colors.green),
                        ),
                        EarnedBadgeNote(badges: _earned, onDark: true),
                      ],
                      const SizedBox(height: 32),
                      if (_saveFailed)
                        FilledButton(
                          onPressed: _loading
                              ? null
                              : isPath
                              ? () => _persistPathClear(showResult: true)
                              : _nextChallenge,
                          child: const Text('再试一次'),
                        )
                      else if (isPath) ...[
                        if (_next != null)
                          FilledButton(
                            onPressed: () => context.go(_next!.route),
                            child: Text(_next!.button),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _resultKind = null;
                              _level = 1;
                              _nonce = 0;
                              _levelDone = false;
                            });
                            _writeNonceField('0');
                            _recompute();
                          },
                          child: const Text('继续挑战升级关'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: () => context.go('/learn'),
                          child: const Text('回到学习'),
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

enum _ResultKind { pathGate, challengeComplete }
